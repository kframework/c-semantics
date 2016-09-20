module CPP-DECL-DECLARATOR-SYNTAX
     imports LIST
     imports SET
     imports COMMON-SORTS
     imports SYMLOC-SORTS
     imports CPP-ABSTRACT-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax Decl ::= DeclaratorAndSpecifiers(Declarator, Set)
                    | declareObject(Namespace, CId, CPPTypeExpr, Init, DeclarationType, Linkage, Duration, Set)
                    | defineObject(Namespace, CId, CPPType, Init, DeclarationType, Duration, Set)
                    | initializeObject(Namespace, CId, CPPType, K, DeclarationType) [strict(4)]
     syntax Declarator ::= NormalizedDecl(NNS, CId, AType, Init, DeclarationType)

     syntax DeclState ::= "declared" | "completed" | "defined" | "initialized"
 
     syntax KItem ::= declState(SymBase, DeclState)
     syntax KItem ::= processFunDef(SymBase, QualId, CPPTypeExpr, List, Stmt)
     syntax KItem ::= "calculateGotoMap"
     syntax KItem ::= addParam(CId)
endmodule

module CPP-DECL-DECLARATOR
     imports CPP-DECL-DECLARATOR-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports STRING
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-PROCESS-LABEL-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TEMPLATE-DEDUCTION-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule FunctionDecl(N::Namespace, X::CId, T::CPPFunctionType, Params::List) => NormalizedDecl(N, X, T, NoInit(), Function(Params)) [anywhere]
     rule VarDecl(N::Namespace, X::CId, T::CPPType, Init::Expr) => NormalizedDecl(N, X, T, Init, Var) [anywhere]
     rule FunctionDefinition(N::Namespace, X::CId, T::CPPFunctionType, Params::List, Body::Stmt) => NormalizedDecl(N, X, T, Body, Function(Params)) [anywhere]

     rule DeclStmt(L::List) => listToK(L)

     rule Specifier(S::Specifier, D:Declarator) => DeclaratorAndSpecifiers(D, SetItem(S))
          requires S =/=K Auto() [anywhere]
     // Auto is a type specifier in C++ so it is handled elsewhere by AutoType
     rule Specifier(Auto(), D::Decl) => D [anywhere]
     rule Specifier(Spec::Specifier, DeclaratorAndSpecifiers(D::Declarator, S::Set)) => DeclaratorAndSpecifiers(D, S SetItem(Spec)) [anywhere]

     rule NormalizedDecl(N::Namespace, X::CId, T::AType, Init::Init, Type::DeclarationType) => DeclaratorAndSpecifiers(NormalizedDecl(N, X, T, Init, Type), .Set)

     rule <k> DeclaratorAndSpecifiers(NormalizedDecl((NoNNS() => N), _, _, _, _), _) ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
     rule <k> DeclaratorAndSpecifiers(NormalizedDecl((NoNNS() => NoNamespace()), _, _, _, _), _) ...</k>
          <curr-scope> _:BlockScope </curr-scope>

     context DeclaratorAndSpecifiers(NormalizedDecl(_, _, HOLE:AType, _, _), _) [result(CPPTypeExpr)]
     context DeclaratorAndSpecifiers(NormalizedDecl(_, _, HOLE:CPPTypeExpr, _, _), _)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     rule <k> DeclaratorAndSpecifiers(NormalizedDecl(N:Namespace, X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType), Body::Init, Type::DeclarationType), S::Set) => declareObject(N, X, t(Q, Mods, T), Body, Type, getLinkage(S, N, Scope, Q, getPreviousLinkage(getInnermostNamespace(N, Scope) :: X, t(Q, Mods, T), Exts, Ints), Type), getDuration(S, Scope), S) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <curr-scope> Scope::Scope </curr-scope>
          <externals> Exts:Map </externals>
          <internals> Ints:Map </internals>
          <curr-extern> IsExtern:Bool </curr-extern>
          requires ((notBool IsExtern) orBool Extern() in S)
               andBool (notBool isCPPFunctionType(t(Q, Mods, T)) orBool isAdjustedType(t(Q, Mods, {T}:>CPPSimpleFunctionType)))

     rule <k> DeclaratorAndSpecifiers(_, (S::Set => SetItem(Extern()) S)) ...</k>
          <curr-extern> true </curr-extern>
          requires notBool (Extern() in S)

     syntax Linkage ::= getLinkage(Set, Namespace, Scope, Quals, K, DeclarationType) [function]
                      | getNamespaceLinkage(Namespace, DeclarationType) [function]
                      | getNamespaceLinkage(Namespace) [function, klabel(getNamespaceLinkage1)]
     syntax KItem ::= getPreviousLinkage(QualId, CPPType, Map, Map) [function]
     syntax Duration ::= getDuration(Set, Scope) [function]
     syntax Namespace ::= getInnermostNamespace(Namespace, Scope) [function]

     rule getPreviousLinkage(X::QualId, T::CPPType, X |-> (T |-> _ _::Map) _::Map, _) => ExternalLinkage
     rule getPreviousLinkage(X::QualId, T::CPPType, _, X |-> (T |-> _ _::Map) _::Map) => InternalLinkage
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
     rule getNamespaceLinkage(N::Namespace, Function(_)) => getNamespaceLinkage(N)

     // 3.5:6
     rule getLinkage(S::Set, _, _:BlockScope, _, L::Linkage, Type::DeclarationType) => #if L ==K .K #then ExternalLinkage #else L #fi
          requires isFunctionDeclarationType(Type) orBool (Type ==K Var andBool Extern() in S)
     rule getLinkage(S::Set, _, _:BlockScope, _, _, Type::DeclarationType) => NoLinkage
          requires Type ==K Var andBool notBool (Extern() in S)

     rule getDuration(S::Set, _) => ThreadStorage
          requires ThreadLocal() in S
     rule getDuration(S::Set, Scope:BlockScope) => AutoStorage
          requires notBool Static() in S andBool notBool Extern() in S
     rule getDuration(_, _) => StaticStorage [owise]

     rule getInnermostNamespace(NoNamespace(), blockScope(N:Namespace :: _, _, _)) => N
     rule getInnermostNamespace(N::Namespace, _) => N
          requires N =/=K NoNamespace()

     /* After everything is computed */

     context declareObject(_, _, HOLE:CPPTypeExpr, _, _, _, _, _)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     // ExternalLinkage, StaticStorage, not previously declared
     rule <k> declareObject(N::Namespace, X::CId, T:CPPType, Init::Init, Type::DeclarationType, ExternalLinkage, StaticStorage, S::Set)
              => addToEnv(N :: X, T, Base, false)
              ~> defineObject(N, X, T, Init, Type, StaticStorage, S) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> 
              Exts::Map
              => Exts[N :: X, T <- declState(Base, declared)]
          </externals>
          <odr-decls> Decls::Map => Decls[Base += ktriple(Tu, N :: X, T)] </odr-decls>
          <next-link-loc> Base::SymBase => linc(Base) </next-link-loc>
          <curr-template-context> noTemplate </curr-template-context>
          requires notBool N :: X in_keys(Exts)
               andBool completeDeclaration(T, Init) ==K T

     // InternalLinkage, StaticStorage, not previously declared
     rule <k> declareObject(N::Namespace, X::CId, T:CPPType, Init::Init, Type::DeclarationType, InternalLinkage, StaticStorage, S::Set)
              => addToEnv(N :: X, T, Base, false)
              ~> defineObject(N, X, T, Init, Type, StaticStorage, S) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <internals> 
              Ints::Map
              => Ints[N :: X, T <- declState(Base, declared)]
          </internals>
          <odr-decls> Decls::Map => Decls[Base += ktriple(Tu, N :: X, T)] </odr-decls>
          <next-link-loc> Base::SymBase => linc(Base) </next-link-loc>
          <curr-template-context> noTemplate </curr-template-context>
          requires notBool N :: X in_keys(Ints)
               andBool completeDeclaration(T, Init) ==K T

     // ExternalLinkage, StaticStorage, redeclare incomplete array
     rule <k> declareObject(N::Namespace, X::CId, T:CPPArrayType, Init::Init, Type::DeclarationType, ExternalLinkage, StaticStorage, S::Set)
              => addToEnv(N :: X, T, Base, false)
              ~> defineObject(N, X, T, Init, Type, StaticStorage, S) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... N :: X |-> ((T':CPPArrayType => T) |-> declState(Base::SymBase, _)) ...</externals>
          <odr-decls> Decls::Map => Decls[Base += ktriple(Tu, N :: X, T)] </odr-decls>
          <curr-template-context> noTemplate </curr-template-context>
          requires completeDeclaration(T, Init) ==K T
              andBool notBool isCompleteType(T') andBool innerType(T) ==Type innerType(T') andBool getQuals(T) ==K getQuals(T')

     context declareNonStaticObject(_, _, HOLE:KItem, _, _, _)

     // NoLinkage, AutoStorage, not previously declared
     rule <k> declareObject(NoNamespace(), X::CId, T::CPPType, Init::Init, Type::DeclarationType, NoLinkage, AutoStorage, S::Set) ~> Next:KItem
              => addToEnv(NoNamespace() :: X, T, nonStatic, false)
              ~> declareNonStaticObject(X, T, figureInit(le(Name(NoNNS(), X), hasTrace(Name(NoNNS(), X)), T), T, AutoStorage, Init, Init), Type, AutoStorage, S)
              ~> Next
          ...</k>
          <curr-scope> _:BlockScope </curr-scope>
          <curr-template-context> noTemplate </curr-template-context>
          requires completeDeclaration(T, Init) ==K T
               andBool getKLabel(Next) =/=K #klabel(`dummyBind`)

     rule declareObject(_, _, (T::CPPType => completeDeclaration(T, Init)), Init::Init, _, _, _, _)
          requires T =/=K completeDeclaration(T, Init)

     rule <k> (.K => deduceAuto(T, Init)) 
              ~> declareObject(_, _, T::CPPTypeExpr, Init::Init, _, _, _, _) ...</k>
          <template-deduction> _ => .Map </template-deduction>
          requires isDependentInScope(T) andBool isAuto(T)

     rule <k> (finishAutoDeduction => .K) ~> declareObject(_, _, _, _, _, _, _, _) ~> (.K => stripAuto) ...</k>
          <template-deduction>... auto |-> T::CPPType ...</template-deduction> //don't substitute any other variables that may have arisen during template deduction
          <template-arguments>... .Map => auto |-> T ...</template-arguments>

     syntax KItem ::= "stripAuto"
     rule <k> stripAuto => .K ...</k>
          <template-arguments>... auto |-> _ => .Map ...</template-arguments>

     rule <k> declareNonStaticObject(X::CId, T::CPPType, Init:KResult, Type::DeclarationType, D::Duration, S::Set) => .K ...</k>
          <elab>... .K => declareNonStaticObject(X, T, Init, Type, D, S) </elab>

     syntax CPPType ::= completeDeclaration(CPPType, Init) [function]
     // 8.5.4:3.2 (char x[] = {"foo"})
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, T:CPPSimpleCharType))), BraceInit(ListItem(StringLiteral(Narrow::CharKind, S::String)))) => t(Q, Mods, arrayType(t(Q', Mods', T), lengthString(S) +Int 1))
          requires Narrow ==K Ascii() orBool Narrow ==K UTF8()
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, wchar_t))), BraceInit(ListItem(StringLiteral(Wide(), S::String)))) => t(Q, Mods, arrayType(t(Q', Mods', wchar_t), lengthString(S) +Int 1))
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, char16_t))), BraceInit(ListItem(StringLiteral(UTF16(), S::String)))) => t(Q, Mods, arrayType(t(Q', Mods', char16_t), lengthString(S) +Int 1))
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, char32_t))), BraceInit(ListItem(StringLiteral(UTF32(), S::String)))) => t(Q, Mods, arrayType(t(Q', Mods', char32_t), lengthString(S) +Int 1))
     // 8.5:17.3 (char x[] = "foo")
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, T:CPPSimpleCharType))), StringLiteral(Narrow::CharKind, S::String)) => t(Q, Mods, arrayType(t(Q', Mods', T), lengthString(S) +Int 1))
          requires Narrow ==K Ascii() orBool Narrow ==K UTF8()
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, wchar_t))), StringLiteral(Wide(), S::String)) => t(Q, Mods, arrayType(t(Q', Mods', wchar_t), lengthString(S) +Int 1))
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, char16_t))), StringLiteral(UTF16(), S::String)) => t(Q, Mods, arrayType(t(Q', Mods', char16_t), lengthString(S) +Int 1))
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, char32_t))), StringLiteral(UTF32(), S::String)) => t(Q, Mods, arrayType(t(Q', Mods', char32_t), lengthString(S) +Int 1))
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType)), BraceInit(L::List)) => t(Q, Mods, arrayType(T, size(L)))
         requires size(L) =/=Int 1 orBool getKLabel(L[0]) =/=K #klabel(`StringLiteral`)
     rule completeDeclaration(T::CPPType, _) => T [owise]


     rule defineObject(_, _, _, NoInit(), Function(_), _, _) => .K
     rule defineObject(_, _, _, NoInit(), _, _, S::Set) => .K
          requires Extern() in S

     rule <k> defineObject(N::Namespace, X::CId, T::CPPType, Init::Init, Type::DeclarationType, StaticStorage, S::Set)
              => initializeObject(N, X, T, figureInit(
                   allocateDecl(N :: X, T, StaticStorage, byteSizeofType(T)),
                   T, StaticStorage, Init, Init), Type) ...</k>
          requires notBool (Init ==K NoInit() andBool (Extern() in S orBool isCPPFunctionType(T))) andBool isCompleteType(T)
               andBool notBool isCPPRefType(T)

     syntax Expr ::= allocateDecl(QualId, CPPType, Duration, Int)

     rule <k> allocateDecl(N::Namespace :: X::CId, T::CPPType, StaticStorage, Size:Int) 
              => addToEnv(N :: X, T, Base', false)
              ~> allocObject(Base', T, Size)
              ~> lv(lnew(Base', T), noTrace, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (_ T |-> kpair(_, Base::SymBase)) ...</nenv>
          <next-static-loc> Base'::SymBase => linc(Base') </next-static-loc>
          <linkings>... .Map => Base |-> Base' ...</linkings>
          <odr-decls> Decls::Map => Decls[Base' += ktriple(Tu, N :: X, T)] </odr-decls>
          <odr-defs> Defs::Map => Defs[N :: X, T <- Base'] </odr-defs>
          requires isLinkerLoc(Base)

     rule <k> initializeObject(N::Namespace, X::CId, T::CPPType, initValue(lv(loc(Base::SymBase, _, _), _, _), T, initializer(Body::Stmt)), Function(Params::List))
              => initFunction(Base, functionObject(N :: X, T, .List, GotoStmt(funLabel(X))))
              ~> processFunDef(Base, N :: X, T, Params, Body) ...</k>

     syntax KItem ::= initFunction(SymBase, K)

     rule <k> initFunction(Base::SymBase, Val:K) => .K ...</k>
          <functions> F::Map => F[Base <- Val] </functions>

     rule <k> processFunDef(Base::SymBase, N::Namespace :: X::CId, T::CPPFunctionTypeExpr, Params::List, Body::Stmt)
              => scope(blockScope(N :: X, Base, 0),
                   elaborateTemplateBody(dummyBind(Params) ~> getFunDefBody(I, N :: X, T, Body))
                   ~> calculateGotoMap)
          ...</k>
          <curr-function> _ => Base </curr-function>
          <curr-template-context> I::TemplateInfo </curr-template-context>
          requires I =/=K noTemplate orBool isCPPFunctionType(T)
     syntax Stmt ::= getFunDefBody(TemplateInfo, QualId, CPPFunctionTypeExpr, Stmt) [function]
     rule getFunDefBody(noTemplate, N::Namespace :: X::CId, T::CPPFunctionTypeExpr, Body::Stmt)
          => LabelStmt(funLabel(X), ListItem(Body) ListItem(ReturnOp(getDefaultReturnOp(N :: X, getReturnType(T)))))
     rule getFunDefBody(_, _, _, Body::Stmt) => Body [owise]

     syntax K ::= getDefaultReturnOp(QualId, CPPTypeExpr) [function]
     rule getDefaultReturnOp(GlobalNamespace() :: Identifier("main"), T::CPPTypeExpr)
          => ExpressionStmt(le(Name(NoNNS(), ret), noTrace, T) := prv(0, noTrace, type(int)))
     rule getDefaultReturnOp(_, _) => .K [owise]

     syntax KItem ::= dummyBind(List)
     rule (.K => K) ~> dummyBind((ListItem(K:K) => .List) _)
     rule dummyBind(.List) => .K
     rule (declareObject(NoNamespace(), X::CId, T::CPPType, NoInit(), Type::DeclarationType, NoLinkage, AutoStorage, S::Set)
              => addToEnv(NoNamespace() :: X, T, nonStatic, false) ~> addParam(X)) ~> dummyBind(_)

     rule <k> addParam(X::CId) => .K ...</k>
          <curr-function> Base::SymBase </curr-function>
          <functions>... Base |-> functionObject(_, _, _::List (.List => ListItem(X)), _) ...</functions>

     rule <k> elaborateDone(K:K) ~> calculateGotoMap
          => calculateGotoMap(K) ...</k>
          <curr-template-context> noTemplate </curr-template-context>


     rule <k> initializeObject(N::Namespace, X::CId, T::CPPType, initValue(_, T, Init:K), Var)
              => runInit(stripInitHolds(Init))
          ...</k>
          requires isStaticInitialization(Init)

     syntax Bool ::= isStaticInitialization(K) [function]
     rule isStaticInitialization(ExpressionStmt(le(_ := V::Expr, _, _)) ~> K:K) => false
          requires notBool (isVal(V) andBool notBool isTExpr(V))
     rule isStaticInitialization((ExpressionStmt(le(_ := _, _, _)) => .K) ~> _:K)
     rule isStaticInitialization(.K) => true

     syntax K ::= stripInitHolds(K) [function]
     rule stripInitHolds(ExpressionStmt(Init::Expr) ~> K:K)
          => ExpressionStmt(stripHold(Init)) ~> stripInitHolds(K)
     rule stripInitHolds(L:CabsLoc ~> K:K)
          => L ~> stripInitHolds(K)
     rule stripInitHolds(.K) => .K

endmodule
