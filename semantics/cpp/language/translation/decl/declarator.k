module CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports LIST
     imports SET
     imports COMMON-SORTS
     imports SYMLOC-SORTS
     imports CPP-ABSTRACT-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax Decl ::= DeclaratorAndSpecifiers(Declarator, Set)
                    | declareObject(NNSVal, NNSVal, CId, CId, CPPType, Init, DeclarationType, Linkage, Duration, Set)
                    | defineObject(NNSVal, CId, CId, CPPType, Init, DeclarationType, Set)
                    | initializeObject(NNSVal, CId, CPPType, init: KItem, DeclarationType) [strict(c; 4)]

     syntax Declarator ::= NormalizedDecl(nns: NNS, id: CId, mangled: CId, type: AType, init: Init, dtype: DeclarationType)

     syntax DeclState ::= "declared" | "completed" | "defined" | "initialized"

     syntax DeclarationType ::= makeFunctionDeclarationType(NNSVal, CPPTypes) [function]

     syntax KItem ::= declState(SymBase, DeclState)

     syntax KItem ::= processFunDef(SymBase, QualId, CPPType, List, Stmt)

     syntax KItem ::= "calculateGotoMap"

     syntax KItem ::= addParam(CId)
endmodule

module CPP-TRANSLATION-DECL-DECLARATOR
     imports CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports OPTIONS-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-TRANSLATION-ENV-SYNTAX
     imports CPP-TRANSLATION-ODR-SYNTAX
     imports CPP-TRANSLATION-PROCESS-LABEL-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX
     imports CPP-TRANSLATION-CONSTANT-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-DESTRUCTOR

     rule FunctionDecl(N::NNSVal, X::CId, Mangled::CId, T::CPPType, Params::List)
          => NormalizedDecl(N, X, Mangled, T, NoInit(), Function(Params)) [anywhere]

     rule VarDecl(N::NNSVal, X::CId, Mangled::CId, T::CPPType, Init::Init, IsDirect:Bool)
          => NormalizedDecl(N, X, Mangled, T, Init, Var(#if IsDirect #then DirectInit() #else CopyInit() #fi)) [anywhere]

     rule FunctionDefinition(N::NNSVal, X::CId, Mangled::CId, T::CPPType, Params::List, Body::Stmt)
          => NormalizedDecl(N, X, Mangled, T, Body, Function(Params)) [anywhere]

     rule DeclStmt(L::List) => listToK(L)

     rule Specifier(S::Specifier, D:Declarator) => DeclaratorAndSpecifiers(D, SetItem(S))
          requires S =/=K Auto() [anywhere]

     // Auto is a type specifier in C++ so it is handled elsewhere by AutoType
     rule Specifier(Auto(), D::Decl) => D [anywhere]

     rule Specifier(Spec::Specifier, DeclaratorAndSpecifiers(D::Declarator, S::Set)) => DeclaratorAndSpecifiers(D, S SetItem(Spec)) [anywhere]

     rule NormalizedDecl(N::NNSVal, X::CId, Mangled::CId, T::AType, Init::Init, Type::DeclarationType)
          => DeclaratorAndSpecifiers(NormalizedDecl(N, X, Mangled, T, Init, Type), .Set)

     context DeclaratorAndSpecifiers(NormalizedDecl(... nns: HOLE:NNS), _)
             requires HOLE =/=K NoNNS()
             [result(NNSVal)]

     rule <k> DeclaratorAndSpecifiers(NormalizedDecl((NoNNS() => N), _, _, _, _, _), _) ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>

     rule <k> DeclaratorAndSpecifiers(NormalizedDecl((NoNNS() => NoNamespace()), _, _, _, _, _), _) ...</k>
          <curr-tr-scope> _:BlockScope </curr-tr-scope>

     rule <k> DeclaratorAndSpecifiers(NormalizedDecl((NoNNS() => C), _, _, _, _, _), _) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>

     context DeclaratorAndSpecifiers(NormalizedDecl(_, _, _, HOLE:AType, _, _), _) [result(CPPType)]

     rule <k> DeclaratorAndSpecifiers(NormalizedDecl(N:NNSVal, X::CId, Mangled::CId, t(Q::Quals, _, _) #as T::CPPType, Body::Init, Type::DeclarationType), S::Set)
               => declareObject(N, getInnermostNamespace(N, Scope), X, Mangled, T, Body, Type, getLinkage(S, N, Scope, Q, getPreviousLinkage(getInnermostNamespace(N, Scope) :: X, T, Exts, Ints), Type), getDuration(S, Scope), S)
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <curr-tr-scope> Scope::Scope </curr-tr-scope>
          <externals> Exts:Map </externals>
          <internals> Ints:Map </internals>
          <curr-extern> IsExtern:Bool </curr-extern>
          requires ((notBool IsExtern) orBool Extern() in S)
               andBool (notBool isCPPFunctionType(T) orBool isAdjustedType(T))

     rule <k> DeclaratorAndSpecifiers(_, (S::Set => SetItem(Extern()) S)) ...</k>
          <curr-extern> true </curr-extern>
          requires notBool (Extern() in S)

     syntax Linkage ::= getLinkage(Set, NNSVal, Scope, Quals, K, DeclarationType) [function]
                      | getNamespaceLinkage(Namespace, DeclarationType) [function]
                      | getNamespaceLinkage(Namespace) [function, klabel(getNamespaceLinkage1)]
                      | getClassLinkage(Class) [function]

     syntax K ::= getPreviousLinkage(QualId, CPPType, Map, Map) [function]

     syntax Duration ::= getDuration(Set, Scope) [function]

     syntax Namespace ::= getInnermostNamespace(NNSVal, Scope) [function]

     rule getPreviousLinkage(X::QualId, T::CPPType, X |-> (stripType(T) |-> _ _::Map) _::Map, _) => ExternalLinkage

     rule getPreviousLinkage(X::QualId, T::CPPType, _, X |-> (stripType(T) |-> _ _::Map) _::Map) => InternalLinkage

     rule getPreviousLinkage(_, _, _, _) => .K [owise]

     // @ref n4296 3.5:3.1
     rule getLinkage(S::Set, _, _:NamespaceScope, _::Quals, _, _) => InternalLinkage
          requires Static() in S

     // @ref n4296 3.5:3.2
     rule getLinkage(S::Set, _, _:NamespaceScope, Q::Quals, L::Linkage, _) => InternalLinkage
          requires notBool Volatile() inQuals Q andBool Const() inQuals Q andBool notBool Extern() in S andBool notBool L ==K ExternalLinkage

     //TODO(dwightguth): 3.5:3.3

     rule getLinkage(_, DeclNamespace:Namespace, _:NamespaceScope, _, _, Type::DeclarationType) => getNamespaceLinkage(DeclNamespace, Type) [owise]

     // @ref n4296 9.4.2:5 with revision http://www.open-std.org/jtc1/sc22/wg21/docs/cwg_defects.html#1603
     rule getLinkage(S::Set, C:Class, _, _, _, Type::DeclarationType) => getClassLinkage(C)
          requires Static() in S
            orBool isFunctionDeclarationType(Type)

     rule getLinkage(_, _:Class, _, _, L:Linkage, _) => L

     // @ref n4296 3.5:4
     rule getClassLinkage(Parent:Namespace :: _) => getNamespaceLinkage(Parent)

     // @ref n4296 3.5:5 with revision http://www.open-std.org/jtc1/sc22/wg21/docs/cwg_defects.html#1603
     rule getClassLinkage(Parent:Class :: _) => getClassLinkage(Parent)

     rule getClassLinkage(_:LocalQualifier :: _) => NoLinkage

     // @ref n4296 3.5:4
     rule getNamespaceLinkage(_:UnnamedNamespace) => InternalLinkage

     rule getNamespaceLinkage(GlobalNamespace()) => ExternalLinkage

     rule getNamespaceLinkage(Parent::Namespace :: _) => getNamespaceLinkage(Parent) [owise]

     // @ref n4296 3.5:4.1
     rule getNamespaceLinkage(N::Namespace, Var(_)) => getNamespaceLinkage(N)

     // @ref n4296 3.5:4.2
     rule getNamespaceLinkage(N::Namespace, Function(_)) => getNamespaceLinkage(N)

     // @ref n4296 3.5:6
     rule getLinkage(S::Set, _, _:BlockScope, _, L::Linkage, Type::DeclarationType) => #if L ==K .K #then ExternalLinkage #else L #fi
          requires isFunctionDeclarationType(Type) orBool (isVarDeclarationType(Type) andBool Extern() in S)

     rule getLinkage(S::Set, _, _:BlockScope, _, _, Type::DeclarationType) => NoLinkage
          requires isVarDeclarationType(Type) andBool notBool (Extern() in S)

     rule getDuration(S::Set, _) => ThreadStorage
          requires ThreadLocal() in S

     rule getDuration(S::Set, _:BlockScope) => AutoStorage
          requires notBool Static() in S andBool notBool Extern() in S

     rule getDuration(_, _) => StaticStorage [owise]

     rule getInnermostNamespace(NoNamespace(), blockScope(N:Namespace :: _, _, _)) => N

     rule getInnermostNamespace(NoNamespace(), blockScope((N:Namespace :: _:ClassSpecifier) :: _, _, _)) => N

     rule getInnermostNamespace(NoNamespace(), blockScope((C:Class :: _:ClassSpecifier => C) :: _, _, _))

     rule getInnermostNamespace(NoNamespace(), blockScope((localQual(Scope::BlockScope) :: _:ClassSpecifier) :: _, _, _) => Scope)

     rule getInnermostNamespace(N::Namespace, _) => N
          requires N =/=K NoNamespace()

     /* After everything is computed */

     syntax Map ::= addOdrDecl(Map, CId, K) [function]

     rule addOdrDecl(ET::Map, Identifier(_) #as X::CId, V::KItem) => ET[X <- V]

     rule addOdrDecl(ET::Map, _, _) => ET [owise]

     syntax CId ::= getCName(CPPType, CId, CId, LanguageLinkage, Set) [function]

     rule getCName(_::CPPType, X::CId, _, CLinkage, _) => X

     rule getCName(t(... st: functionType(...)), X::CId, Mangled::CId, LangLinkage::LanguageLinkage, Opts::Set) => Mangled
          requires (LangLinkage =/=K CLinkage) andBool (X =/=K Mangled)
               andBool notBool (NoNativeFallback() in Opts)

     rule getCName(_, _, _, _, _) => #NoName [owise]

     syntax CId ::= getInternalCName(CPPType, CId, CId, String, LanguageLinkage, Set) [function]

     rule getInternalCName(t(... st: functionType(...)) #as T::CPPType, X::CId, Identifier(S::String), Uuid::String, LangLinkage::LanguageLinkage, Opts::Set)
          => getCName(T, X, Identifier(S +String Uuid), LangLinkage, Opts)

     rule getInternalCName(_, _, _, _, _, _) => #NoName [owise]

     syntax CId ::= getGoodCName(CPPType, CId, CId, String, LanguageLinkage, Set, Linkage) [function]

     rule getGoodCName(T::CPPType, X::CId, Mangled::CId, Uuid::String, LangLinkage::LanguageLinkage, Opts::Set, InternalLinkage)
          => getInternalCName(T, X, Mangled, Uuid, LangLinkage, Opts)

     rule getGoodCName(T::CPPType, X::CId, Mangled::CId, _, LangLinkage::LanguageLinkage, Opts::Set, ExternalLinkage)
          => getCName(T, X, Mangled, LangLinkage, Opts)

     syntax KItem ::= "Declare.potentiallyInvokeDestructor" "(" CPPType ")"

     rule Declare.potentiallyInvokeDestructor(T::CPPType)
          => #if isCPPClassType(T) #then
               Class.potentiallyInvokeDestructor(classFromType(T)) 
             #else .K #fi

     rule <k> declareObject(N1::NNSVal, N2::NNSVal, X::CId, Mangled::CId, T:CPPType,
                              Init::Init, DT::DeclarationType, Lnk::Linkage, D::Duration, S::Set)
              => declareObjectWithLinkage(N1, N2, X, T, Init, DT, D, S,
                              getGoodCName(T, X, Mangled, Uuid, LangLinkage, Opts, Lnk), Lnk)
              ~> #if Extern() in S #then .K #else Declare.potentiallyInvokeDestructor(T) #fi
          ...</k>
          <curr-lang-linkage> LangLinkage::LanguageLinkage </curr-lang-linkage>
          <options> Opts::Set </options>
          <uuid> Uuid::String </uuid>
          <curr-template-context> noTemplate </curr-template-context>
          requires Lnk =/=K NoLinkage andBool completeDeclaration(T, Init) ==K T

     syntax Decl ::= declareObjectWithLinkage(NNSVal, NNSVal, CId, CPPType, Init, DeclarationType, Duration, Set, cname: CId, Linkage)

     // ExternalLinkage, StaticStorage, not previously declared
     rule <k> declareObjectWithLinkage(N:Namespace, LN::Namespace, X::CId, T::CPPType, Init::Init, Type::DeclarationType, StaticStorage, S::Set, CName::CId, ExternalLinkage)
                   => declareNewObject(N, LN, X, T, Init, Type, S, CName, bnew(!I:Int, T, S, link(Tu)), ExternalLinkage)
               ...</k>
               <curr-tr-tu> Tu::String </curr-tr-tu>
               <tu-id> Tu </tu-id>
               <externals> Exts::Map </externals>
               <curr-template-context> noTemplate </curr-template-context>
               requires notBool LN :: X, T in_keys(Exts)

          // InternalLinkage, StaticStorage, not previously declared
          rule <k> declareObjectWithLinkage(N:Namespace, LN::Namespace, X::CId, T::CPPType, Init::Init, Type::DeclarationType, StaticStorage, S::Set, CName::CId, InternalLinkage)
                   => declareNewObject(N, LN, X, T, Init, Type, S, CName, bnew(!I:Int, T, S, link(Tu)), InternalLinkage)
               ...</k>
               <curr-tr-tu> Tu::String </curr-tr-tu>
               <tu-id> Tu </tu-id>
               <internals> Ints::Map </internals>
               <curr-template-context> noTemplate </curr-template-context>
               requires notBool LN :: X, T in_keys(Ints)

          syntax KItem ::= declareNewObject(Namespace, Namespace, CId, CPPType, Init, DeclarationType, Set, CId, SymBase, Linkage)

          rule declareNewObject(N::Namespace, LN::Namespace, X::CId, T::CPPType, Init::Init,
                    Type::DeclarationType, S::Set, CName::CId, Base::SymBase, Lnk::Linkage)
                   => newState(LN :: X, T, Base, Lnk)
                   ~> newExternalType(CName, T)
                   ~> newExternalDecl(CName)
                   ~> Odr.newDecl(CName, LN :: X, T, Base)
                   ~> addToEnv(N :: X, T, Base, false)
                   ~> markAsConstexpr(Base, S)
                   ~> updateDefaultArguments(N :: X, T, computeDefaultArgs(T, Type))
                   ~> lazyDefineObject(N, X, CName, T, Init, Type, S, Base)

          // ExternalLinkage, StaticStorage, redeclare incomplete array
          rule <k> declareObjectWithLinkage(_::Namespace, LN::Namespace, X::CId, t(... st: _:CPPSimpleArrayType) #as T::CPPType, _::Init, _::DeclarationType, StaticStorage, _::Set, _, ExternalLinkage) ...</k>
               <curr-tr-tu> Tu::String </curr-tr-tu>
               <tu-id> Tu </tu-id>
               <externals>... LN :: X |-> ((_::CPPType => stripType(T)) |-> (T'::CPPType => T, declState(_::SymBase, _))) ...</externals>
               requires isCPPArrayType(T') andBool notBool isCompleteType(T') andBool innerType(T) ==Type innerType(T') andBool getQuals(T) ==K getQuals(T')

          // ExternalLinkage, StaticStorage, redeclare complete type
          rule <k> declareObjectWithLinkage(N:Namespace, LN::Namespace, X::CId, T::CPPType, Init::Init, Type::DeclarationType, StaticStorage, S::Set, CName::CId, ExternalLinkage)
                   => redeclareCompleteType(N, LN, X, T, Init, Type, S, CName, Base)
               ...</k>
               <curr-tr-tu> Tu::String </curr-tr-tu>
               <tu-id> Tu </tu-id>
               <externals>... LN :: X |-> (stripType(T) |-> (_, declState(Base::SymBase, _)) _::Map) ...</externals>
               <curr-template-context> noTemplate </curr-template-context>

          // InternalLinkage, StaticStorage, redeclare complete type
          rule <k> declareObjectWithLinkage(N:Namespace, LN::Namespace, X::CId, T::CPPType, Init::Init, Type::DeclarationType, StaticStorage, S::Set, CName::CId, InternalLinkage)
                   => redeclareCompleteType(N, LN, X, T, Init, Type, S, CName, Base)
               ...</k>
               <curr-tr-tu> Tu::String </curr-tr-tu>
               <tu-id> Tu </tu-id>
               <internals>... LN :: X |-> (stripType(T::CPPType) |-> (_, declState(Base::SymBase, _)) _::Map) ...</internals>
               <curr-template-context> noTemplate </curr-template-context>

          syntax KItem ::= redeclareCompleteType(Namespace, Namespace, CId, CPPType, Init, DeclarationType, Set, CId, SymBase)

          rule <k> redeclareCompleteType(N::Namespace, LN::Namespace, X::CId, T::CPPType,
                         Init::Init, Type::DeclarationType, S::Set, CName::CId, Base::SymBase)
                   => addToEnv(N :: X, T, Base, false)
                   ~> Odr.newDecl(CName, LN :: X, T, Base)
                   ~> newExternalType(CName, T)
                   ~> newExternalDecl(CName)
                   ~> updateDefaultArguments(N :: X, T, computeDefaultArgs(T, Type))
                   ~> lazyDefineObject(N, X, CName, T, Init, Type, S, Base)
               ...</k>
               <curr-tr-scope> Scope::Scope </curr-tr-scope>
               <elab>... .K => #if isBlockScope(Scope) #then declareLocalStaticObject(X, Base, T) #else .K #fi </elab>

          context declareNonStaticObject(... init: HOLE:Expr)

          // NoLinkage, AutoStorage, not previously declared
          rule <k> declareObject(NoNamespace(), _, X::CId, _, T::CPPType, Init::Init, Var(Type::InitType), NoLinkage, AutoStorage, S::Set) ~> Next:KItem
                   => addToEnv(NoNamespace() :: X, T, nonStatic, false)
                   ~> prepareDeclareNonStaticObject(X, T, Init, Type, S)
                   ~> Declare.potentiallyInvokeDestructor(T)
                   ~> Next
               ...</k>
               <curr-tr-scope> _:BlockScope </curr-tr-scope>
               <curr-template-context> noTemplate </curr-template-context>
               requires completeDeclaration(T, Init) ==K T
                    andBool dummyBind(...) :/=K Next

          syntax KItem ::= prepareDeclareNonStaticObject(CId, CPPType, init: Init, InitType, s: Set)

          context prepareDeclareNonStaticObject(...init: HOLE:Expr => evalCoreConstantExpressionUntil(HOLE, isEvalVal), s: S::Set)
               requires Constexpr() in S

          rule prepareDeclareNonStaticObject(X::CId, T::CPPType, Init::Init, Type::InitType, S::Set)
               => declareNonStaticObject(X, T, figureInit(le(ExecName(NoNNS(), X), hasTrace(Name(NoNNS(), X)), T), T, Init, Type, AutoStorage), Var(Type), AutoStorage, S)

          // NoLinkage, StaticStorage, not previously declared
          rule <k> declareObject(NoNamespace(), _, X::CId, _, T::CPPType, Init::Init, Type::DeclarationType, NoLinkage, StaticStorage, Set::Set)
                   => defineLocalStaticObject(X, bnew(!I:Int, T, Set, static(Tu)), T, Init, Type, Set)
                   ~> Declare.potentiallyInvokeDestructor(T)
               ...</k>

          <curr-tr-scope> S::Scope </curr-tr-scope>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <local-statics> LocalStatics::Map (.Map => kpair(X, S) |-> kpair(bnew(!I, T, Set, static(Tu)), T)) </local-statics>
          <elab>... .K => declareLocalStaticObject(X, bnew(!I, T, Set, static(Tu)), T) </elab>
          requires notBool (kpair(X, S) in_keys(LocalStatics))
               andBool completeDeclaration(T, Init) ==K T

     rule declareObject(_, _, _, _, (T::CPPType => completeDeclaration(T, Init)), Init::Init, _, _, _, _)
          requires T =/=K completeDeclaration(T, Init)

     // Declare static data member inside class (no definition)
     rule <k> declareObjectWithLinkage(C:Class, C, X::CId, T::CPPType, NoInit(), Var(_), StaticStorage, S::Set, CName::CId, ExternalLinkage)
              => addToEnv(C :: X, T, bnew(!I:Int, T, S, link(Tu)), false)
              ~> Odr.newDecl(CName, C :: X, T, bnew(!I, T, S, link(Tu)))
              ~> newExternalType(CName, T)
              ~> newExternalDecl(CName)
              ~> newExternalState(C :: X, T, bnew(!I:Int, T, S, link(Tu)))
          ...</k>
          <curr-tr-scope> classScope(C, _) </curr-tr-scope>
          <class-id> C </class-id>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>

     // Declare function member inside class
     rule <k> declareObjectWithLinkage(C:Class, C, X::CId, t(... st: functionType(...)) #as T::CPPType, Init::Init, Type::DeclarationType, StaticStorage, S::Set, CName::CId, ExternalLinkage)
              => addToEnv(C :: X, T, bnew(!I, T, S, link(Tu)), false)
              ~> Odr.newDecl(CName, C :: X, T, bnew(!I, T, S, link(Tu)))
              ~> newExternalType(CName, T)
              ~> newExternalDecl(CName)
              ~> newExternalState(C :: X, T, bnew(!I:Int, T, S, link(Tu)))
              ~> markAsConstexpr(bnew(!I, T, S, link(Tu)), S)
              ~> lazyDefineObject(C, X, CName, T, Init, Type, S, bnew(!I:Int, T, S, link(Tu)))
          ...</k>

          // pure functions need to have a dummy functionObject in order for virtual call semantics to know their QualId if they have no definition
          <functions> Funcs::Map => #if isMethodPure(T) #then Funcs bnew(!I, T, S, link(Tu)) |-> functionObject(C :: X, T, .List, .K) #else Funcs #fi </functions>
          <deferred-class-actions> _ |> _ |> (K:K => updateDefaultArguments(C :: X, T, computeDefaultArgs(T, Type)) ~> K) |> .Ordering </deferred-class-actions>
          <curr-tr-scope> classScope(C, _) </curr-tr-scope>
          <class-id> C </class-id>
          <function-members>... .List => ListItem(Class.FunctionMember(X, T)) </function-members>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          requires notBool isVarDeclarationType(Type)

     // Static member declaration/definition, in the enclosing namespace.
     // Note that static member are not allowed in local classes
     rule <k> declareObjectWithLinkage((CQ::ClassQualifier :: _::ClassSpecifier) #as C:Class, C, X::CId, T::CPPType, Init::Expr, Type::DeclarationType, StaticStorage, S::Set, CName::CId, ExternalLinkage)
               => updateDefaultArguments(C :: X, T, computeDefaultArgs(T, Type))
               ~> defineObject(C, X, CName, T, Init, Type, S)
          ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>
          requires getClassNamespace(C) ==K N andBool notBool isLocalQualifier(CQ)

     syntax KItem ::= "stripAuto"

     rule <k> stripAuto => .K ...</k>
          <template-arguments>... auto |-> _ => .Map ...</template-arguments>

    rule declareNonStaticObject(ID::CId, T::CPPType, Init:KResult, DT::DeclarationType, DU::Duration, S::Set)
          =>  declareNonStaticObject2(declareNonStaticObjectExec(ID, T, Init, DT, DU, S), Constexpr() in S)

     syntax KItem ::= declareNonStaticObject2(K, Bool)

     syntax K ::= stripLater(K)

     rule toExecution(stripLater(K::K)) => K

     rule <k> declareNonStaticObject2(K::K, ConstExpr:Bool) =>
              elaborateThen(stripLater(K)) ~> #if ConstExpr #then compileTimeEval(K) #else .K #fi ... </k>

     syntax CPPType ::= completeDeclaration(CPPType, Init) [function]

     rule completeDeclaration(_::CPPType, (ExprLoc(_, I:Init) => I))

     // @ref n4296 8.5.4:3.2 (char x[] = {"foo"})
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, T:CPPSimpleCharType))), BraceInit(ListItem(StringLiteral(Narrow::CharKind, S::String)))) => t(Q, Mods, arrayType(t(Q', Mods', T), lengthString(S) +Int 1))
          requires Narrow ==K Ascii() orBool Narrow ==K UTF8()

     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, wchar_t))), BraceInit(ListItem(StringLiteral(Wide(), S::String)))) => t(Q, Mods, arrayType(t(Q', Mods', wchar_t), lengthString(S) +Int 1))

     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, char16_t))), BraceInit(ListItem(StringLiteral(UTF16(), S::String)))) => t(Q, Mods, arrayType(t(Q', Mods', char16_t), lengthString(S) +Int 1))

     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, char32_t))), BraceInit(ListItem(StringLiteral(UTF32(), S::String)))) => t(Q, Mods, arrayType(t(Q', Mods', char32_t), lengthString(S) +Int 1))

     // @ref n4296 8.5:17.3 (char x[] = "foo")
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, T:CPPSimpleCharType))), StringLiteral(Narrow::CharKind, S::String)) => t(Q, Mods, arrayType(t(Q', Mods', T), lengthString(S) +Int 1))
          requires Narrow ==K Ascii() orBool Narrow ==K UTF8()

     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, wchar_t))), StringLiteral(Wide(), S::String)) => t(Q, Mods, arrayType(t(Q', Mods', wchar_t), lengthString(S) +Int 1))

     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, char16_t))), StringLiteral(UTF16(), S::String)) => t(Q, Mods, arrayType(t(Q', Mods', char16_t), lengthString(S) +Int 1))

     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(Q'::Quals, Mods'::Set, char32_t))), StringLiteral(UTF32(), S::String)) => t(Q, Mods, arrayType(t(Q', Mods', char32_t), lengthString(S) +Int 1))

     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType)), BraceInit(ListItem(Init::Init) L::List)) => t(Q, Mods, arrayType(T, size(L) +Int 1))
          requires (size(L) =/=Int 0 orBool StringLiteral(...) :/=K Init)
               andBool (notBool isAggregateType(T) orBool #isBraceInit(Init))

     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(t(... st: classType(...)) #as T::CPPType)), BraceInit((ListItem(Init::Init) _) #as L::List)) => t(Q, Mods, arrayType(T, computeAggArraySize(getClassInfo(T), L)))
          requires isAggregateType(T)
               andBool notBool #isBraceInit(Init)

     rule completeDeclaration(T::CPPType, _) => T [owise]

     syntax Int ::= computeAggArraySize(ClassInfo, List) [function]
                  | #computeAggArraySize(fields: List, types: Map, initList: List, callStack: List, size: Int, agg: ClassInfo) [function]

     rule computeAggArraySize(CI::ClassInfo, L::List) => #computeAggArraySize(.List, .Map, L, .List, 0, CI)

     rule #computeAggArraySize((.List => Class.getNonStaticDataMembers(CI)), (_ => Class.getDataMembersInitializers(CI)), ListItem(_) _, .List, (N::Int => N +Int 1), CI::ClassInfo)

     rule #computeAggArraySize(... fields: (.List => Fields), types: (_ => Types), callStack: (ListItem(kpair(Fields::List, Types::Map)) => .List) _)

     rule #computeAggArraySize(... initList: .List, size: N::Int) => N

     rule #computeAggArraySize(...
                           fields: (ListItem(Class.DataMember(F:CId, _)) => .List) _,
                           types: (F |-> (_::CPPType |-> (T::CPPType, _))) _,
                           initList: (ListItem(Init::Expr) => .List) _
                           )
          requires (notBool isAggregateType(T) orBool #isBraceInit(Init))

     rule #computeAggArraySize(...
                           fields: (ListItem(Class.DataMember(F:CId, _)) Fields::List => Class.getNonStaticDataMembers(getClassInfo(T))),
                           types: (((F |-> (_::CPPType |-> (T::CPPType, _))) _) #as Types::Map => Class.getDataMembersInitializers(getClassInfo(T))),
                           initList: ListItem(Init::Expr) _,
                           callStack: (.List => ListItem(kpair(Fields, Types))) _
                           )
          requires isAggregateType(T)
               andBool notBool #isBraceInit(Init)

     syntax Decl ::= lazyDefineObject(NNSVal, CId, CId, CPPType, Init, DeclarationType, Set, SymBase)

     rule lazyDefineObject(N::NNSVal, X::CId, CName::CId, T::CPPType, Init::Init, Type::DeclarationType, S::Set, _::SymBase)
          => defineObject(N, X, CName, T, Init, Type, S)
          requires notBool isInitOnlyIfOdrUsed(Init)

     rule <k> lazyDefineObject(
               N::NNSVal, X::CId, CName::CId,
               T::CPPType, OnlyIfOdrUsed(Init::Init),
               Type::DeclarationType, S::Set, Base::SymBase
              )
              => Odr.doWhenUsed(
                    Base,
                    scope(namespaceScope(GlobalNamespace()), clearScope() ~> defineObject(N, X, CName, T, Init, Type, S))
                 )
          ...</k>
          <curr-tr-scope> _::Scope </curr-tr-scope>

     rule defineObject(_, _, _, _, NoInit(), Function(_), _) => .K

     rule defineObject(_, _, _, _, NoInit(), _, S::Set) => .K
          requires Extern() in S

     rule defineObject(N::NNSVal, X::CId, CName::CId, T::CPPType, Init::Init, Type::DeclarationType, S::Set)
          => defineObject2(N, X, CName, T, Init, Type, S)
          requires notBool (Init ==K NoInit() andBool (Extern() in S orBool isCPPFunctionType(T))) andBool isCompleteType(T)

     syntax Decl ::= defineObject2(NNSVal, CId, CId, CPPType, Init, DeclarationType, Set)

     rule defineObject2(N:Namespace, X::CId, CName::CId, T::CPPType, Init::Init, Type::DeclarationType, S::Set)
          => defineObject3(N, X, CName, T, Type, S, Init, getInitType(Type))

     // Static data member definition
     rule defineObject2(C:Class, X::CId, CName::CId, T::CPPType, Init::Expr, Var(IType::InitType) #as Type::DeclarationType, S::Set)
          => defineObject3(C, X, CName, T, Type, S, evalBraceOrEqualInitializer(C, noObject(), Init), IType)
          requires Init =/=K NoInit()

     // Function member definition
     rule defineObject2(C:Class, X::CId, CName::CId, T::CPPType, Init::Init, Type:FunctionDeclarationType, S::Set)
          => defineObject3(C, X, CName, T, Type, S, Init, CopyInit())
          requires Init =/=K NoInit()

     syntax Decl ::= defineObject3(NNSVal, CId, CId, CPPType, DeclarationType, Set, init: Init, type: InitType)

     rule defineObject3(N::NNSVal, X::CId, CName::CId, T::CPPType, Type::DeclarationType, S::Set, Init::Init, InitType::InitType)
          => initializeObject(N, X, T, figureInit(allocateDecl(N :: X, CName, T, S), T, Init, InitType, StaticStorage), Type)


     syntax InitType ::= getInitType(DeclarationType) [function]

     rule getInitType(Var(Type::InitType)) => Type

     rule getInitType(_) => CopyInit() [owise]

     syntax KItem ::= allocNrObject(SymBase, CPPType)

     rule allocNrObject(Base::SymBase, T::CPPType)
          => #if notBool isCPPRefType(T) #then allocObject(Base, T, byteSizeofType(T)) #else .K #fi


     syntax Decl ::= defineLocalStaticObject(CId, SymBase, CPPType, Init, DeclarationType, Set)

     rule defineLocalStaticObject(X::CId, Base::SymBase, T::CPPType, Init::Init, Var(Type::InitType), _::Set)
          => addToEnv(NoNamespace() :: X, T, Base, false)
          ~> Odr.newDef(NoNamespace() :: X, T, Base)
          ~> Odr.newDecl(#NoName, NoNamespace() :: X, T, Base)
          ~> allocNrObject(Base, T)
          ~> initializeObject(NoNamespace(), X, T, figureInit(
               lv(lnew(Base), noTrace, T),
               T, Init, Type, StaticStorage), Var(Type))

     syntax Expr ::= allocateDecl(QualId, CId, CPPType, Set)

     rule allocateDecl(Q::QualId, CName::CId, T::CPPType, S::Set)
          => allocateDecl2(Q, CName, T, S, findLinkBase(Q, T))

     syntax Expr ::= allocateDecl2(QualId, CId, CPPType, Set, linkBase: KItem) [strict(5)]

     syntax KItem ::= findLinkBase(QualId, CPPType)

     // this is quite an univerzal construction
     syntax Result ::= r(K)

     syntax KItem ::= Result

     syntax KResult ::= Result

     rule <k> findLinkBase(N:Namespace :: X::CId, T::CPPType) => r(Base) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (_::Map stripType(T) |-> (_, envEntry(... base: Base:LinkBase))) ...</nenv>

     rule <k> findLinkBase(C:Class :: X::CId, T::CPPType) => r(Base) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... X |-> (_::Map stripType(T) |-> (_, envEntry(... base: Base:LinkBase))) ...</cenv>

     rule <k> allocateDecl2(Q::QualId, CName::CId, T::CPPType, S::Set, r(LBase:LinkBase))
              => allocateDecl3(Q, CName, T, S, LBase, bnew(!I:Int, T, S, static(Tu))) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>

     syntax Expr ::= allocateDecl3(QualId, CId, CPPType, Set, LinkBase, SymBase)

     rule allocateDecl3(Q::QualId, CName::CId, T::CPPType, S::Set, LBase::LinkBase, SBase::SymBase)
          => addToEnv(Q, T, SBase, false)
          ~> makeLink(LBase, SBase)
          ~> newExternalType(CName, T)
          ~> newExternalDecl(CName)
          ~> Odr.newDecl(CName, Q, T, SBase)
          ~> Odr.newDef(Q, T, SBase)
          ~> allocNrObject(SBase, T)
          ~> markAsConstexpr(SBase, S)
          ~> lv(lnew(SBase), noTrace, T)


     syntax KItem ::= newState(QualId, CPPType, SymBase, Linkage)

     rule newState(Q::QualId, T::CPPType, B::SymBase, ExternalLinkage)
          => newExternalState(Q, T, B)

     rule newState(Q::QualId, T::CPPType, B::SymBase, InternalLinkage)
          => newInternalState(Q, T, B)

     syntax KItem ::= newInternalState(QualId, CPPType, SymBase)

     rule <k> newInternalState(Q::QualId, T::CPPType, Base::SymBase) => .K ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <internals> Ints::Map => Ints[Q, T <- declState(Base, declared)] </internals>

     syntax KItem ::= newExternalState(QualId, CPPType, SymBase)

     rule <k> newExternalState(Q::QualId, T::CPPType, Base::SymBase) => .K ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <externals> Exts::Map => Exts[Q, T <- declState(Base, declared)] </externals>

     syntax KItem ::= newExternalDecl(cname: CId)

     rule <k> newExternalDecl(CName::CId) => .K ...</k>
          <curr-tr-program-loc> Loc::CabsLoc </curr-tr-program-loc>
          <external-decls-loc> DeclsLoc::Map => addOdrDecl(DeclsLoc, CName, Loc) </external-decls-loc>

     syntax NewExternalType ::= newExternalType(cname: CId, type: CPPType)

     rule <k> newExternalType(CName::CId, T::CPPType) => .K ...</k>
          <external-types> ET::Map => addOdrDecl(ET, CName, convertTypeToC(T)) </external-types>

     syntax KItem ::= makeLink(from: LinkBase, to: SymBase)

     rule <k> makeLink(From::LinkBase, To::SymBase) => .K ...</k>
          <linkings>... .Map => From |-> To ...</linkings>

     syntax KItem ::= markAsConstexpr(SymBase, Set)

     rule <k> markAsConstexpr(B::SymBase, S::Set) => . ...</k>
          <constexpr-symbase> CS::Set => CS SetItem(B)</constexpr-symbase>
          requires Constexpr() in S

     rule markAsConstexpr(_, S::Set) => .
          requires notBool Constexpr() in S

     rule <k> initializeObject(N::NNSVal, X::CId, T::CPPType, functionDef(Base::SymBase, Body::Stmt), Function(Params::List))
              => initFunction(Base, functionObject(N :: X, T, .List, GotoStmt(funLabel(X))))
              ~> processFunDef(Base, N :: X, T, Params, Body) ...</k>
          <curr-tr-scope> S::Scope </curr-tr-scope>
          requires notBool isClassScope(S)

     rule <k> initializeObject(N::NNSVal, X::CId, T::CPPType, functionDef(Base::SymBase, Body::Stmt), Function(Params::List))
              => initFunction(Base, functionObject(N :: X, T, .List, GotoStmt(funLabel(X)))) ...</k>
          <deferred-class-actions> _ |> _ |> (K:K => K ~> processFunDef(Base, N :: X, T, Params, Body)) |> .Ordering </deferred-class-actions>
          <curr-tr-scope> classScope(...) </curr-tr-scope>

     syntax KItem ::= initFunction(SymBase, K)

     rule <k> initFunction(Base::SymBase, Val:KItem) => .K ...</k>
          <functions> F::Map => F[Base <- Val] </functions>

     syntax KItem ::= preserveThreadLocal(K)
                    | restoreThreadLocal1(K)
                    | restoreThreadLocal2(K)


     rule <k> preserveThreadLocal(Comp::K)
              => Comp ~> restoreThreadLocal1(TL)
          ...</k> <thread-local> TL::Bag </thread-local>

     rule restoreThreadLocal1(TL::K) => popBlock(false) ~> restoreThreadLocal2(TL)

     rule <k> restoreThreadLocal2(TL:Bag) => .K  ... </k>
          <thread-local> _ => TL </thread-local>

     syntax KItem ::= "prepareExecutionEnvironment"

     rule <k> prepareExecutionEnvironment => .K ...</k>
          <curr-tr-scope> Sc::Scope </curr-tr-scope>
          <curr-scope> _ => Sc </curr-scope>
          <curr-tr-tu> TU::String </curr-tr-tu>
          <curr-tu> _ => TU </curr-tu>


     rule <k> processFunDef(Base::SymBase, QX::QualId, t(... st: functionType(... methodInfo: MI::MethodInfo)) #as T::CPPType, Params::List, Body::Stmt)
              => preserveThreadLocal(scope(blockScope(QX, Base, 0),
                   prepareExecutionEnvironment ~> pushBlock(!I:Int) ~> elaborateTemplateBody(dummyBind(Params) ~> #if hasThis(MI) #then setTrThis(QX, MI) #else .K #fi ~> getFunDefBody(I, QX, T, Body))
                   ~> calculateGotoMap))
          ...</k>
          <curr-function> _ => Base </curr-function>
          <curr-template-context> I::TemplateInfo </curr-template-context>
          requires I =/=K noTemplate orBool isCPPFunctionType(T)

     syntax Stmt ::= getFunDefBody(TemplateInfo, QualId, CPPType, Stmt) [function]

     rule getFunDefBody(noTemplate, QX::QualId, T::CPPType, Body::Stmt)
          =>
          TLabelStmt(funLabel(getId(QX)),
               #if isDestructorId(getId(QX)) #then ListItem(Destructor()) #else .List #fi
               ListItem(Body)
               ListItem(TReturnOp(
                    getDefaultReturnOp(!I:Int, QX, getReturnType(T)),
                    temp(!I:Int, type(int))))
          )

     rule getFunDefBody(_, _, _, Body::Stmt) => Body [owise]

     syntax Bool ::= hasThis(MethodInfo) [function]

     rule hasThis(methodInfo(... static: false)) => true

     rule hasThis(_) => false [owise]

     syntax KItem ::= setTrThis(QualId, MethodInfo)

     rule <k> setTrThis(C:Class :: _, methodInfo(... cvQuals: Q::Quals)) => .K ...</k>
          <tr-this> _ => pre(This(), hasTrace(This()), type(pointerType(t(Q::Quals, .Set, classType(C))))) </tr-this>

     syntax Expr ::= getDefaultReturnOp(Int, QualId, CPPType) [function]

     rule getDefaultReturnOp(I::Int, GlobalNamespace() :: Identifier("main"), T::CPPType)
          => le(temp(I, type(int)), noTrace, T) :=init prv(0, noTrace, type(int))

     rule getDefaultReturnOp(_, _, _) => prv(voidVal, noTrace, type(void)) [owise]

     syntax KItem ::= dummyBind(List)

     rule (.K => K) ~> dummyBind((ListItem(K:KItem) => .List) _)

     rule dummyBind(.List) => .K

     // as functions can have default arguments we allow any initializers here
     rule (declareObject(NoNamespace(), _, X::CId, _, T::CPPType, _, _, NoLinkage, AutoStorage, _)
              => addToEnv(NoNamespace() :: X, T, nonStatic, false) ~> addParam(X)) ~> dummyBind(_)

     rule <k> addParam(X::CId) => .K ...</k>
          <curr-function> Base::SymBase </curr-function>
          <functions>... Base |-> functionObject(_, _, _::List (.List => ListItem(X)), _) ...</functions>

     rule <k> elaborateDone(K:K) ~> calculateGotoMap
          => calculateGotoMap(K) ...</k>
          <curr-template-context> noTemplate </curr-template-context>


     rule <k> initializeObject(... init: Init:Val)
              => runInit(stripInitHolds(Init))
          ...</k>
          requires isStaticInitialization(Init)

     rule <k> initializeObject(... init: Init:Val) => .K ...</k>
          <dynamic-init>... .K => ExpressionStmt(Init) </dynamic-init>
          requires notBool isStaticInitialization(Init)

     syntax Bool ::= isStaticInitialization(K) [function]

     rule isStaticInitialization(pre(BuiltinCallOp(...), _, _)) => false

     rule isStaticInitialization(le(beginConstruction(...), _, _)) => true

     rule isStaticInitialization(le(endConstruction(...), _, _)) => true

     rule isStaticInitialization(le(finishConstruction(...), _, _)) => true

     rule isStaticInitialization(le(saveLocallyConstructed(E::Expr) => E , _, _))

     rule isStaticInitialization(le(_ :=init V::Expr, _, _)) => isEvalVal(V)

     rule isStaticInitialization(le(bindReferenceExec(_, V::Expr), _, _)) => isEvalVal(V)

     rule isStaticInitialization(compoundInit(E1::Expr, E2::Expr)) => isStaticInitialization(E1) andBool isStaticInitialization(E2)

     rule isStaticInitialization(le(compoundInit(E1::Expr, E2::Expr), _, _) => compoundInit(E1, E2))

     rule isStaticInitialization(pre(compoundInit(E1::Expr, E2::Expr), _, _) => compoundInit(E1, E2))

     rule isStaticInitialization(xe(compoundInit(E1::Expr, E2::Expr), _, _) => compoundInit(E1, E2))


     rule isStaticInitialization(lv(_, _, _)) => true

     syntax Expr ::= stripInitHolds(K) [function]

     rule stripInitHolds(le(compoundInit(E1::Expr, E2::Expr), _, _)) => stripInitHolds(compoundInit(E1, E2))

     rule stripInitHolds(compoundInit(E1::Expr, E2::Expr)) => compoundInit(stripInitHolds(E1), stripInitHolds(E2))

     rule stripInitHolds(le(saveLocallyConstructed(E::Expr), _, _)) => saveLocallyConstructed(stripInitHolds(E))

     rule stripInitHolds(le(E::Expr, _, _)) => E [owise]

     rule stripInitHolds(V::Val) => V
          requires isEvalVal(V)

     context defArgs(_, (HOLE:StrictList => types(HOLE)), _)

     context defArgs(_, _, (HOLE:StrictList => cats(HOLE)))

     syntax DefaultArguments ::= computeDefaultArgs(CPPType, DeclarationType)

     rule computeDefaultArgs(t(... st: functionType(...)) #as T::CPPType, Function(Params::List))
          => #fun((DI::List => defArgs(list(#computeDefaultArgs(getRealParams(T), DI, hasImplicitParameter(T))), list(DI), list(DI))))(getDefArgsInitializers(Params))

     rule computeDefaultArgs(T::CPPType, _) => krlist(.List)
          requires notBool isCPPFunctionType(T)

     syntax List ::= getDefArgsInitializers(List) [function]

     rule getDefArgsInitializers(ListItem(DeclLoc(_, D::Decl) => D) _)

     rule getDefArgsInitializers(ListItem(NormalizedDecl(... init: Init::Init)) A::List)
          => ListItem(Init) getDefArgsInitializers(A)

     rule getDefArgsInitializers(.List) => .List

     syntax List ::= #computeDefaultArgs(types: List, defaultArgs: List, hasImplicitParam: Bool) [function]

     rule #computeDefaultArgs(ListItem(_) Types::List, Args::List, true) => #computeDefaultArgs(Types, Args, false)

     // This part is very similar to bindParams
     rule #computeDefaultArgs(ListItem(T:CPPType) P::List, ListItem(Init::Init) A::List, false)
          => ListItem(figureInit(le(temp(!I:Int, T), noTrace, T), T, Init, CopyInit(), AutoStorage)) #computeDefaultArgs(P, A, false)
          requires notBool (isCPPRefType(T) andBool isExpr(Init))
           andBool Init =/=K NoInit()

     rule #computeDefaultArgs(ListItem(cppRefType) P::List, ListItem(Init::Init) A::List, false)
          => ListItem(Init) #computeDefaultArgs(P, A, false)
          requires Init =/=K NoInit()

     rule #computeDefaultArgs(ListItem(_) P::List, ListItem(NoInit()) A::List, false)
          => ListItem(NoArg()) #computeDefaultArgs(P, A, false)

     rule #computeDefaultArgs(.List, .List, _) => .List

     rule makeFunctionDeclarationType(N::NNSVal, Types::CPPTypes)
       => Function(#makeFunctionDeclarationType(N, toList(Types)))

     syntax List ::= #makeFunctionDeclarationType(NNSVal, List) [function]

     rule #makeFunctionDeclarationType(N::Namespace, ListItem(T::CPPType) Types::List)
          => ListItem(VarDecl(N, #NoName, #NoName, T, NoInit(), false)) #makeFunctionDeclarationType(N, Types)

     rule #makeFunctionDeclarationType(_, .List) => .List

     rule emptyDefaultArguments(t(... st: functionType(...)) #as T::CPPType)
       => #emptyDefaultArguments(#if hasImplicitParameter(T) #then size(getRealParams(T)) -Int 1 #else size(getRealParams(T)) #fi, defArgs(krlist(.List), krlist(.List), krlist(.List)))

     rule emptyDefaultArguments(_) => NoDefArgs() [owise]

     syntax DefaultArgumentsResult ::= #emptyDefaultArguments(Int, DefaultArgumentsResult) [function]

     rule #emptyDefaultArguments(0, DA::DefaultArgumentsResult) => DA

     rule #emptyDefaultArguments(N::Int => N -Int 1,
            defArgs(krlist(_::List (.List => ListItem(NoArg()))),
                    krlist(_::List (.List => ListItem(NoInitType()))),
                    krlist(_::List (.List => ListItem(NoInitCat()))))) [owise]
endmodule
