module CPP-DECL-DECLARATOR-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports SYMLOC-SYNTAX

     syntax Decl ::= DeclaratorAndSpecifiers(Declarator, Set)
                    | declareObject(Namespace, CId, CPPType, Init, DeclarationType, Linkage, Duration, Set)
                    | completeObject(Namespace, CId, CPPType, Init, DeclarationType, Linkage, Duration)
                    | defineObject(Namespace, CId, CPPType, Init, DeclarationType, Duration)
                    | initializeObject(Namespace, CId, CPPType, K, DeclarationType) [strict(4)]
     syntax Declarator ::= NormalizedDecl(Namespace, CId, AType, Init, DeclarationType)
     syntax DeclarationType ::= "Function" | "Var"

     syntax DeclState ::= "declared" | "completed" | "defined" | "initialized"
 
     syntax KItem ::= declState(SymBase, CPPType, DeclState)
endmodule

module CPP-DECL-DECLARATOR
     imports CPP-DECL-DECLARATOR-SYNTAX

     imports C-CONFIGURATION
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-PROCESS-LABEL-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule FunctionDecl(N::Namespace, X::CId, T::CPPType) => NormalizedDecl(N, X, T, NoInit, Function) [anywhere]
     rule VarDecl(N::Namespace, X::CId, T::CPPType, Init::Expr) => NormalizedDecl(N, X, T, Init, Var) [anywhere]
     rule FunctionDefinition(N::Namespace, X::CId, T::CPPType, Body::Stmt) => NormalizedDecl(N, X, T, Body, Function) [anywhere]

     rule Specifier(S::Specifier, D:Declarator) => DeclaratorAndSpecifiers(D, SetItem(S)) [anywhere]
     rule Specifier(Spec::Specifier, DeclaratorAndSpecifiers(D::Declarator, S::Set)) => DeclaratorAndSpecifiers(D, S SetItem(Spec)) [anywhere]

     rule NormalizedDecl(N::Namespace, X::CId, T::AType, Init::Init, Type::DeclarationType) => DeclaratorAndSpecifiers(NormalizedDecl(N, X, T, Init, Type), .Set)

     rule <k> DeclaratorAndSpecifiers(NormalizedDecl((NoNamespace() => N), _, _, _, _), _) ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>

     rule <k> DeclaratorAndSpecifiers(NormalizedDecl(N:NormalizedNamespace, X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType), Body::Init, Type::DeclarationType), S::Set) => declareObject(N, X, t(Q, Mods, T), Body, Type, getLinkage(S, N, Scope, Q, getPreviousLinkage(N :: X, t(Q, Mods, T), Exts, Ints), Type), getDuration(S, Scope), S) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <curr-scope> Scope::Scope </curr-scope>
          <externals> Exts:Map </externals>
          <internals> Ints:Map </internals>
          <curr-lang-linkage> Lang::LanguageLinkage </curr-lang-linkage>
          requires Lang ==K DefaultLinkage orBool Extern() in S

     rule <k> DeclaratorAndSpecifiers(_, (S::Set => SetItem(Extern()) S)) ...</k>
          <curr-lang-linkage> Lang::LanguageLinkage </curr-lang-linkage>
          requires (Lang ==K CPPLinkage)
               andBool notBool (Extern() in S)
     rule <k> DeclaratorAndSpecifiers(NormalizedDecl(_, _, t(_, _, functionType(_, _, _, (_ => Lang))), _, Function), (S::Set => SetItem(Extern()) S)) ...</k>
          <curr-lang-linkage> Lang::LanguageLinkage </curr-lang-linkage>
          requires (Lang ==K CLinkage)
               andBool notBool (Extern() in S)

     syntax Linkage ::= getLinkage(Set, Namespace, Scope, Quals, K, DeclarationType) [function]
                      | getNamespaceLinkage(Namespace, DeclarationType) [function]
                      | getNamespaceLinkage(Namespace) [function, klabel(getNamespaceLinkage1)]
     syntax KItem ::= getPreviousLinkage(QualId, CPPType, Map, Map) [function]
     syntax Duration ::= getDuration(Set, Scope) [function]

     rule getPreviousLinkage(X::QualId, T::CPPType, kpair(X, T) |-> _ _::Map, _) => ExternalLinkage
     rule getPreviousLinkage(X::QualId, T::CPPType, _, kpair(X, T) |-> _ _::Map) => InternalLinkage
     rule getPreviousLinkage(_, _, _, _) => .K [owise]

     // 3.5:3.1
     rule getLinkage(S::Set, _, _:NamespaceScope, Q::Quals, _, _) => InternalLinkage
          requires Static() in S
     // 3.5:3.2
     rule getLinkage(S::Set, _, _:NamespaceScope, Q::Quals, L::Linkage, _) => InternalLinkage
          requires notBool Volatile() inQuals Q andBool Const() inQuals Q andBool notBool Extern() in S andBool notBool L ==K ExternalLinkage
     //TODO(dwightguth): 3.5:3.3

     rule getLinkage(_, DeclNamespace::Namespace, _:NamespaceScope, _, _, Type::DeclarationType) => getNamespaceLinkage(DeclNamespace, Type) [owise]

     // 3.5:4
     rule getNamespaceLinkage(N:UnnamedNamespace) => InternalLinkage 
     rule getNamespaceLinkage(GlobalNamespace()) => ExternalLinkage
     rule getNamespaceLinkage(Parent::Namespace :: _) => getNamespaceLinkage(Parent) [owise]

     // 3.5:4.1
     rule getNamespaceLinkage(N::Namespace, Var) => getNamespaceLinkage(N)
     // 3.5:4.2
     rule getNamespaceLinkage(N::Namespace, Function) => getNamespaceLinkage(N)

     rule getDuration(S::Set, _) => ThreadStorage
          requires ThreadLocal() in S
     rule getDuration(S::Set, Scope:BlockScope) => AutoStorage
          requires notBool Static() in S andBool notBool Extern() in S
     rule getDuration(_, _) => StaticStorage [owise]

     /* After everything is computed */

     // external, not previously declared
     rule <k> declareObject(N::NormalizedNamespace, X:CId, T::CPPType, Init::Init, Type::DeclarationType, ExternalLinkage, StaticStorage, _)
              => addToEnv(N :: X, T, Base, false)
              ~> completeObject(N, X, T, Init, Type, ExternalLinkage, StaticStorage) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> 
              Exts::Map
              (.Map => kpair(N :: X, T) |-> declState(Base, T, declared))
          </externals>
          <next-link-loc> Base::SymBase => linc(Base) </next-link-loc>
          requires notBool X in_keys(Exts)

     rule <k> completeObject(N::NormalizedNamespace, X:CId, T:CPPCompleteType, Init::Init, Type::DeclarationType, ExternalLinkage, StaticStorage) 
              => defineObject(N, X, T, Init, Type, StaticStorage)
          ...</k>
          <externals>... kpair(N :: X, T) |-> declState(Base::SymBase, _, (_ => completed)) ...</externals>

     rule defineObject(N::NormalizedNamespace, X::CId, _, NoInit, Function, _) => .K

     rule <k> defineObject(N::NormalizedNamespace, X::CId, T::CPPType, Init::Init, Type::DeclarationType, StaticStorage)
              => initializeObject(N, X, T, figureInit(
                   allocateDecl(N :: X, T, StaticStorage, byteSizeofType(T)),
                   T, Init, Init), Type) ...</k>
          requires Init =/=K NoInit

     syntax Expr ::= allocateDecl(QualId, CPPType, Duration, Int)

     rule <k> allocateDecl(N::NormalizedNamespace :: X::CId, T::CPPType, StaticStorage, Size:Int) 
              => addToEnv(N :: X, T, Base', false)
              ~> allocObject(Base', T, Size)
              ~> lv(lnew(Base', T), T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (_ T |-> kpair(_, Base::SymBase)) ...</nenv>
          <next-static-loc> Base'::SymBase => linc(Base') </next-static-loc>
          <linkings>... .Map => Base |-> Base' ...</linkings>
          requires isLinkerLoc(Base)

     rule <k> initializeObject(N::NormalizedNamespace, X::CId, T::CPPType, initValue(lv(loc(Base::SymBase, _, _), _), T, initializer(Body::Stmt)), Function)
              => initFunction(Base, functionObject(X, T, .List, GotoStmt(funLabel(X))))
              ~> processFunDef(Base, N :: X, T, Body) ...</k>

     syntax KItem ::= initFunction(SymBase, K)

     rule <k> initFunction(Base::SymBase, Val:K) => .K ...</k>
          <functions> F::Map => F[Base <- Val] </functions>

     syntax KItem ::= processFunDef(SymBase, QualId, CPPType, Stmt)
     rule <k> processFunDef(Base::SymBase, N::NormalizedNamespace :: X::CId, T:CPPFunctionType, Body::Stmt)
          => scope(blockScope(N :: X, 0),
               elaborate(dummyBind(getParams(T)) ~> LabelStmt(funLabel(X), ListItem(BlockStmt(!BlockNum:Int, ListItem(Body))) ListItem(ReturnOp(.K))))
               ~> calculateGotoMap)
          ...</k>
          <curr-function> _ => Base </curr-function>

     syntax KItem ::= dummyBind(List)
     rule dummyBind(.List) => .K

     syntax KItem ::= "calculateGotoMap"
     rule elaborateDone(K:K) ~> calculateGotoMap
          => calculateGotoMap(K)


     rule <k> initializeObject(N::NormalizedNamespace, X::CId, T::CPPType, initValue(_, T, Init:K), Var)
              => runInit(stripInitHolds(Init))
          ...</k>

     syntax K ::= stripInitHolds(K) [function]
     rule stripInitHolds(ExpressionStmt(Init::Expr) ~> K:K)
          => ExpressionStmt(stripHold(Init)) ~> stripInitHolds(K)
     rule stripInitHolds(L:CabsLoc ~> K:K)
          => L ~> stripInitHolds(K)
     rule stripInitHolds(.K) => .K

endmodule
