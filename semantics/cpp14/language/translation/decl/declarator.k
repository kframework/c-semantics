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
                    | declareObject(NNSVal, NNSVal, CId, CId, CPPTypeExpr, Init, DeclarationType, Linkage, Duration, Set)
                    | defineObject(NNSVal, CId, CId, CPPType, Init, DeclarationType, Duration, Set)
                    | initializeObject(NNSVal, CId, CPPType, init: K, DeclarationType) [strict(4)]
     syntax Declarator ::= NormalizedDecl(nns: NNS, id: CId, mangled: CId, type: AType, init: Init, dtype: DeclarationType)

     syntax DeclState ::= "declared" | "completed" | "defined" | "initialized"
     syntax DeclarationType ::= makeFunctionDeclarationType(NNSVal, CPPTypes) [function]

     syntax KItem ::= declState(SymBase, DeclState)
     syntax KItem ::= processFunDef(SymBase, QualId, CPPTypeExpr, List, Stmt)
     syntax KItem ::= "calculateGotoMap"
     syntax KItem ::= addParam(CId)
endmodule

module CPP-TRANSLATION-DECL-DECLARATOR
     imports CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports STRING
     imports C-LINKING-RESOLUTION-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-TRANSLATION-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-TRANSLATION-PROCESS-LABEL-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-TEMPLATE-DEDUCTION-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX
     imports CPP-TRANSLATION-CONSTANT-SYNTAX

     rule FunctionDecl(N::NNSVal, X::CId, Mangled::CId, T::CPPFunctionType, Params::List) => NormalizedDecl(N, X, Mangled, T, NoInit(), Function(Params)) [anywhere]
     rule VarDecl(N::NNSVal, X::CId, Mangled::CId, T::CPPType, Init::Expr, IsDirect:Bool) => NormalizedDecl(N, X, Mangled, T, Init, Var(#if IsDirect #then DirectInit() #else CopyInit() #fi)) [anywhere]
     rule FunctionDefinition(N::NNSVal, X::CId, Mangled::CId, T::CPPFunctionType, Params::List, Body::Stmt) => NormalizedDecl(N, X, Mangled, T, Body, Function(Params)) [anywhere]

     rule DeclStmt(L::List) => listToK(L)

     rule Specifier(S::Specifier, D:Declarator) => DeclaratorAndSpecifiers(D, SetItem(S))
          requires S =/=K Auto() [anywhere]
     // Auto is a type specifier in C++ so it is handled elsewhere by AutoType
     rule Specifier(Auto(), D::Decl) => D [anywhere]
     rule Specifier(Spec::Specifier, DeclaratorAndSpecifiers(D::Declarator, S::Set)) => DeclaratorAndSpecifiers(D, S SetItem(Spec)) [anywhere]

     rule NormalizedDecl(N::NNSVal, X::CId, Mangled::CId, T::AType, Init::Init, Type::DeclarationType) => DeclaratorAndSpecifiers(NormalizedDecl(N, X, Mangled, T, Init, Type), .Set)

     context DeclaratorAndSpecifiers(NormalizedDecl(... nns: HOLE:NNS), _)
             requires HOLE =/=K NoNNS()
             [result(NNSVal)]

     rule <k> DeclaratorAndSpecifiers(NormalizedDecl((NoNNS() => N), _, _, _, _, _), _) ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>
     rule <k> DeclaratorAndSpecifiers(NormalizedDecl((NoNNS() => NoNamespace()), _, _, _, _, _), _) ...</k>
          <curr-tr-scope> _:BlockScope </curr-tr-scope>
     rule <k> DeclaratorAndSpecifiers(NormalizedDecl((NoNNS() => C), _, _, _, _, _), _) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>

     context DeclaratorAndSpecifiers(NormalizedDecl(_, _, _, HOLE:AType, _, _), _) [result(CPPTypeExpr)]
     context DeclaratorAndSpecifiers(NormalizedDecl(_, _, _, HOLE:CPPTypeExpr, _, _), _)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

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
               andBool (notBool isCPPFunctionType(T) orBool isAdjustedType({T}:>CPPFunctionType))

     rule <k> DeclaratorAndSpecifiers(_, (S::Set => SetItem(Extern()) S)) ...</k>
          <curr-extern> true </curr-extern>
          requires notBool (Extern() in S)

     syntax Linkage ::= getLinkage(Set, NNSVal, Scope, Quals, K, DeclarationType) [function]
                      | getNamespaceLinkage(Namespace, DeclarationType) [function]
                      | getNamespaceLinkage(Namespace) [function, klabel(getNamespaceLinkage1)]
                      | getClassLinkage(Class) [function]
     syntax KItem ::= getPreviousLinkage(QualId, CPPType, Map, Map) [function]
     syntax Duration ::= getDuration(Set, Scope) [function]
     syntax Namespace ::= getInnermostNamespace(NNSVal, Scope) [function]

     rule getPreviousLinkage(X::QualId, T::CPPType, X |-> (T |-> _ _::TypeMap) _::Map, _) => ExternalLinkage
     rule getPreviousLinkage(X::QualId, T::CPPType, _, X |-> (T |-> _ _::TypeMap) _::Map) => InternalLinkage
     rule getPreviousLinkage(_, _, _, _) => .K [owise]

     // 3.5:3.1
     rule getLinkage(S::Set, _, _:NamespaceScope, Q::Quals, _, _) => InternalLinkage
          requires Static() in S
     // 3.5:3.2
     rule getLinkage(S::Set, _, _:NamespaceScope, Q::Quals, L::Linkage, _) => InternalLinkage
          requires notBool Volatile() inQuals Q andBool Const() inQuals Q andBool notBool Extern() in S andBool notBool L ==K ExternalLinkage
     //TODO(dwightguth): 3.5:3.3

     rule getLinkage(_, DeclNamespace:Namespace, _:NamespaceScope, _, _, Type::DeclarationType) => getNamespaceLinkage(DeclNamespace, Type) [owise]

     // 9.4.2:5 with revision http://www.open-std.org/jtc1/sc22/wg21/docs/cwg_defects.html#1603
     rule getLinkage(S::Set, C:Class, _, _, _, Type::DeclarationType) => getClassLinkage(C)
          requires Static() in S
            orBool isFunctionDeclarationType(Type)
     rule getLinkage(_, C:Class, _, _, L:Linkage, _) => L

     // 3.5:4
     rule getClassLinkage(Parent:Namespace :: _) => getNamespaceLinkage(Parent)
     // 3.5:5 with revision http://www.open-std.org/jtc1/sc22/wg21/docs/cwg_defects.html#1603
     rule getClassLinkage(Parent:Class :: _) => getClassLinkage(Parent)
     rule getClassLinkage(_:LocalQualifier :: _) => NoLinkage

     // 3.5:4
     rule getNamespaceLinkage(N:UnnamedNamespace) => InternalLinkage
     rule getNamespaceLinkage(GlobalNamespace()) => ExternalLinkage
     rule getNamespaceLinkage(Parent::Namespace :: _) => getNamespaceLinkage(Parent) [owise]

     // 3.5:4.1
     rule getNamespaceLinkage(N::Namespace, Var(_)) => getNamespaceLinkage(N)
     // 3.5:4.2
     rule getNamespaceLinkage(N::Namespace, Function(_)) => getNamespaceLinkage(N)

     // 3.5:6
     rule getLinkage(S::Set, _, _:BlockScope, _, L::Linkage, Type::DeclarationType) => #if L ==K .K #then ExternalLinkage #else L #fi
          requires isFunctionDeclarationType(Type) orBool (isVarDeclarationType(Type) andBool Extern() in S)
     rule getLinkage(S::Set, _, _:BlockScope, _, _, Type::DeclarationType) => NoLinkage
          requires isVarDeclarationType(Type) andBool notBool (Extern() in S)

     rule getDuration(S::Set, _) => ThreadStorage
          requires ThreadLocal() in S
     rule getDuration(S::Set, Scope:BlockScope) => AutoStorage
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
     rule addOdrDecl(ET::Map, #NoName, _) => ET
     rule addOdrDecl(ET::Map, X::CId, V::K) => ET[X <- V] [owise]

     syntax CId ::= getCName(CPPType, CId, CId, Set) [function]
     rule getCName(T::CPPType, X::CId, _, _) => X
          requires isCLinkage(T)
     rule getCName(T::CPPType, X::CId, _, Opts::Set) => X
          requires notBool isCLinkage(T) andBool notBool isCPPFunctionType(T)
               andBool notBool (NoNativeFallback() in Opts)
     rule getCName(T::CPPType, X::CId, Mangled::CId, Opts::Set) => Mangled
          requires notBool isCLinkage(T) andBool isCPPFunctionType(T)
               andBool (X =/=K Mangled)
               andBool notBool (NoNativeFallback() in Opts)
     rule getCName(_, _, _, _) => #NoName [owise]

     syntax CId ::= getInternalCName(CPPType, CId, CId, String, Set) [function]
     rule getInternalCName(T::CPPType, X::CId, Identifier(S::String), Uuid::String, Opts::Set)
          => #if isCPPFunctionType(T)
               #then getCName(T, X, Identifier(S +String Uuid), Opts)
               #else #NoName #fi
     rule getInternalCName(T::CPPType, X::CId, Mangled::CId, _, Opts::Set)
          => getCName(T, X, Mangled, Opts) [owise]

     context declareObject(_, _, _, _, HOLE:CPPTypeExpr, _, _, _, _, _)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     // ExternalLinkage, StaticStorage, not previously declared
     rule <k> declareObject(N:Namespace, LN::Namespace, X::CId, Mangled::CId, T:CPPType, Init::Init, Type::DeclarationType, ExternalLinkage, StaticStorage, S::Set)
              => addToEnv(N :: X, T, bnew(!I:Int, T, S, link(Tu)), false)
              ~> markAsConstexpr(bnew(!I, T, S, link(Tu)), S)
              ~> updateDefaultArguments(N :: X, T, computeDefaultArgs(T, Type))
              ~> defineObject(N, X, getCName(T, X, Mangled, Opts), T, Init, Type, StaticStorage, S)
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <externals>
              Exts::Map
              => Exts[LN :: X, T <- declState(bnew(!I, T, S, link(Tu)), declared)]
          </externals>
          <odr-decls> Decls::Map => Decls[bnew(!I, T, S, link(Tu)) += odrDecl(Tu, LN :: X, getCName(T, X, Mangled, Opts), T)] </odr-decls>
          <external-types> ET::Map => addOdrDecl(ET, getCName(T, X, Mangled, Opts), convertTypeToC(T)) </external-types>
          <external-decls-loc> DeclsLoc::Map => addOdrDecl(DeclsLoc, getCName(T, X, Mangled, Opts), Loc) </external-decls-loc>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-program-loc> Loc::CabsLoc </curr-tr-program-loc>
          <options> Opts::Set </options>
          requires notBool LN :: X, T in_keys(Exts)
               andBool completeDeclaration(T, Init) ==K T

     // InternalLinkage, StaticStorage, not previously declared
     rule <k> declareObject(N:Namespace, LN::Namespace, X::CId, Mangled::CId, T:CPPType, Init::Init, Type::DeclarationType, InternalLinkage, StaticStorage, S::Set)
              => addToEnv(N :: X, T, bnew(!I:Int, T, S, link(Tu)), false)
              ~> markAsConstexpr(bnew(!I, T, S, link(Tu)), S)
              ~> updateDefaultArguments(N :: X, T, computeDefaultArgs(T, Type))
              ~> defineObject(N, X, getInternalCName(T, X, Mangled, Uuid, Opts), T, Init, Type, StaticStorage, S)
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <uuid> Uuid::String </uuid>
          <internals>
              Ints::Map
              => Ints[LN :: X, T <- declState(bnew(!I, T, S, link(Tu)), declared)]
          </internals>
          <odr-decls> Decls::Map => Decls[bnew(!I, T, S, link(Tu)) += odrDecl(Tu, LN :: X, getInternalCName(T, X, Mangled, Uuid, Opts), T)] </odr-decls>
          <external-types> ET::Map => addOdrDecl(ET, getInternalCName(T, X, Mangled, Uuid, Opts), convertTypeToC(T)) </external-types>
          <external-decls-loc> DeclsLoc::Map => addOdrDecl(DeclsLoc, getInternalCName(T, X, Mangled, Uuid, Opts), Loc) </external-decls-loc>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-scope> Scope::Scope </curr-tr-scope>
          <curr-tr-program-loc> Loc::CabsLoc </curr-tr-program-loc>
          <options> Opts::Set </options>
          requires notBool LN :: X, T in_keys(Ints)
               andBool completeDeclaration(T, Init) ==K T

     // ExternalLinkage, StaticStorage, redeclare incomplete array
     rule <k> declareObject(N::Namespace, LN::Namespace, X::CId, _, T:CPPArrayType, Init::Init, Type::DeclarationType, ExternalLinkage, StaticStorage, S::Set) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <externals>... LN :: X |-> ((T':CPPArrayType => T) |-> declState(Base::SymBase, _)) ...</externals>
          requires completeDeclaration(T, Init) ==K T
              andBool notBool isCompleteType(T') andBool innerType(T) ==Type innerType(T') andBool getQuals(T) ==K getQuals(T')

     // ExternalLinkage, StaticStorage, redeclare complete type
     rule <k> declareObject(N:Namespace, LN::Namespace, X::CId, Mangled::CId, T:CPPType, Init::Init, Type::DeclarationType, ExternalLinkage, StaticStorage, S::Set)
              => addToEnv(N :: X, T, Base, false)
              ~> updateDefaultArguments(N :: X, T, computeDefaultArgs(T, Type))
              ~> defineObject(N, X, getCName(T, X, Mangled, Opts), T, Init, Type, StaticStorage, S)
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <externals>... LN :: X |-> (T |-> declState(Base::SymBase, _) _::TypeMap) ...</externals>
          <odr-decls> Decls::Map => Decls[Base += odrDecl(Tu, LN :: X, getCName(T, X, Mangled, Opts), T)] </odr-decls>
          <external-types> ET::Map => addOdrDecl(ET, getCName(T, X, Mangled, Opts), convertTypeToC(T)) </external-types>
          <external-decls-loc> DeclsLoc::Map => addOdrDecl(DeclsLoc, getCName(T, X, Mangled, Opts), Loc) </external-decls-loc>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-scope> Scope::Scope </curr-tr-scope>
          <curr-tr-program-loc> Loc::CabsLoc </curr-tr-program-loc>
          <elab>... .K => #if isBlockScope(Scope) #then declareLocalStaticObject(X, Base, T) #else .K #fi </elab>
          <options> Opts::Set </options>
          requires completeDeclaration(T, Init) ==K T

     // InternalLinkage, StaticStorage, redeclare complete type
     rule <k> declareObject(N:Namespace, LN::Namespace, X::CId, Mangled::CId, T:CPPType, Init::Init, Type::DeclarationType, InternalLinkage, StaticStorage, S::Set)
              => addToEnv(N :: X, T, Base, false)
              ~> updateDefaultArguments(N :: X, T, computeDefaultArgs(T, Type))
              ~> defineObject(N, X, getInternalCName(T, X, Mangled, Uuid, Opts), T, Init, Type, StaticStorage, S) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <uuid> Uuid::String </uuid>
          <internals>... LN :: X |-> (T::CPPType |-> declState(Base::SymBase, _) _::TypeMap) ...</internals>
          <odr-decls> Decls::Map => Decls[Base += odrDecl(Tu, LN :: X, getInternalCName(T, X, Mangled, Uuid, Opts), T)] </odr-decls>
          <external-types> ET::Map => addOdrDecl(ET, getInternalCName(T, X, Mangled, Uuid, Opts), convertTypeToC(T)) </external-types>
          <external-decls-loc> DeclsLoc::Map => addOdrDecl(DeclsLoc, getInternalCName(T, X, Mangled, Uuid, Opts), Loc) </external-decls-loc>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-scope> Scope::Scope </curr-tr-scope>
          <curr-tr-program-loc> Loc::CabsLoc </curr-tr-program-loc>
          <elab>... .K => #if isBlockScope(Scope) #then declareLocalStaticObject(X, Base, T) #else .K #fi </elab>
          <options> Opts::Set </options>
          requires completeDeclaration(T, Init) ==K T

     context declareNonStaticObject(... init: HOLE:Expr)

     // NoLinkage, AutoStorage, not previously declared
     rule <k> declareObject(NoNamespace(), _, X::CId, _, T::CPPType, Init::Init, Var(Type::InitType), NoLinkage, AutoStorage, S::Set) ~> Next:KItem
              => addToEnv(NoNamespace() :: X, T, nonStatic, false)
              ~> prepareDeclareNonStaticObject(X, T, Init, Type, S)
              ~> Next
          ...</k>
          <curr-tr-scope> _:BlockScope </curr-tr-scope>
          <curr-template-context> noTemplate </curr-template-context>
          requires completeDeclaration(T, Init) ==K T
               andBool getKLabel(Next) =/=K #klabel(`dummyBind`)

     syntax KItem ::= prepareDeclareNonStaticObject(CId, CPPType, init: Init, InitType, s: Set)

     context prepareDeclareNonStaticObject(...init: HOLE:Expr => evalCoreConstantExpressionUntil(HOLE, #klabel(`isEvalVal`)), s: S::Set)
          requires Constexpr() in S

     rule prepareDeclareNonStaticObject(X::CId, T::CPPType, Init::Init, Type::InitType, S::Set)
          => declareNonStaticObject(X, T, figureInit(le(ExecName(NoNNS(), X), hasTrace(Name(NoNNS(), X)), T), T, Init, Type), Var(Type), AutoStorage, S)

     // NoLinkage, StaticStorage, not previously declared
     rule <k> declareObject(NoNamespace(), _, X::CId, Mangled::CId, T::CPPType, Init::Init, Type::DeclarationType, NoLinkage, StaticStorage, Set::Set)
              => defineLocalStaticObject(X, bnew(!I:Int, T, Set, static(Tu)), T, Init, Type, Set) ...</k>
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
     rule <k> declareObject(C:Class, C, X::CId, Mangled::CId, T:CPPType, NoInit(), Var(_), ExternalLinkage, StaticStorage, S::Set)
              => addToEnv(C :: X, T, bnew(!I:Int, T, S, link(Tu)), false)
          ...</k>
          <curr-tr-scope> classScope(C, _) </curr-tr-scope>
          <class-id> C </class-id>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <externals>
              Exts::Map
              => Exts[C :: X, T <- declState(bnew(!I:Int, T, S, link(Tu)), declared)]
          </externals>
          <odr-decls> Decls::Map => Decls[bnew(!I, T, S, link(Tu)) += odrDecl(Tu, C :: X, getCName(T, X, Mangled, Opts), T)] </odr-decls>
          <external-types> ET::Map => addOdrDecl(ET, getCName(T, X, Mangled, Opts), convertTypeToC(T)) </external-types>
          <external-decls-loc> DeclsLoc::Map => addOdrDecl(DeclsLoc, getCName(T, X, Mangled, Opts), Loc) </external-decls-loc>
          <curr-tr-program-loc> Loc::CabsLoc </curr-tr-program-loc>
          <options> Opts::Set </options>

     // Declare function member inside class
     rule <k> declareObject(C:Class, C, X::CId, Mangled::CId, T:CPPFunctionType, Init::Init, Type::DeclarationType, ExternalLinkage, StaticStorage, S::Set)
              => addToEnv(C :: X, T, bnew(!I, T, S, link(Tu)), false)
              ~> markAsConstexpr(bnew(!I, T, S, link(Tu)), S)
              ~> defineObject(C, X, getCName(T, X, Mangled, Opts), T, Init, Type, StaticStorage, S)
          ...</k>
          // pure functions need to have a dummy functionObject in order for virtual call semantics to know their QualId if they have no definition
          <functions> Funcs::Map => #if isMethodPure(T) #then Funcs bnew(!I, T, S, link(Tu)) |-> functionObject(C :: X, T, .List, .K) #else Funcs #fi </functions>
          <deferred-class-actions> _ |> _ |> (K:K => updateDefaultArguments(C :: X, T, computeDefaultArgs(T, Type)) ~> K) |> .Ordering </deferred-class-actions>
          <curr-tr-scope> classScope(C, _) </curr-tr-scope>
          <class-id> C </class-id>
          <function-members>... .List => ListItem(kpair(X, T)) </function-members>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <externals>
              Exts::Map
              => Exts[C :: X, T <- declState(bnew(!I:Int, T, S, link(Tu)), declared)]
          </externals>
          <odr-decls> Decls::Map => Decls[bnew(!I, T, S, link(Tu)) += odrDecl(Tu, C :: X, getCName(T, X, Mangled, Opts), T)] </odr-decls>
          <external-types> ET::Map => addOdrDecl(ET, getCName(T, X, Mangled, Opts), convertTypeToC(T)) </external-types>
          <external-decls-loc> DeclsLoc::Map => addOdrDecl(DeclsLoc, getCName(T, X, Mangled, Opts), Loc) </external-decls-loc>
          <curr-tr-program-loc> Loc::CabsLoc </curr-tr-program-loc>
          <options> Opts::Set </options>
          requires notBool isVarDeclarationType(Type)

     // Static member declaration/definition, in the enclosing namespace.
     // Note that static member are not allowed in local classes
     rule <k> declareObject((CQ::ClassQualifier :: _::ClassSpecifier) #as C:Class, C, X::CId, Mangled::CId, T:CPPType, Init::Expr, Type::DeclarationType, ExternalLinkage, StaticStorage, S::Set)
               => updateDefaultArguments(C :: X, T, computeDefaultArgs(T, Type))
               ~> defineObject(C, X, getCName(T, X, Mangled, Opts), T, Init, Type, StaticStorage, S)
          ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>
          <options> Opts::Set </options>
          requires completeDeclaration(T, Init) ==K T andBool getClassNamespace(C) ==K N andBool notBool isLocalQualifier(CQ)

     rule <k> (.K => deduceAuto(T, Init))
              ~> declareObject(_, _, _, _, T::CPPTypeExpr, Init::Init, _, _, _, _) ...</k>
          <template-deduction> _ => .Map </template-deduction>
          requires isDependentInScope(T) andBool isAuto(T)

     rule <k> (finishAutoDeduction => .K) ~> declareObject(_, _, _, _, _, _, _, _, _, _) ~> (.K => stripAuto) ...</k>
          <template-deduction>... auto |-> T::CPPType ...</template-deduction> //don't substitute any other variables that may have arisen during template deduction
          <template-arguments>... .Map => auto |-> T ...</template-arguments>

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
     rule completeDeclaration(T::CPPType, (ExprLoc(_, I::Init) => I))
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
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType)), BraceInit(ListItem(Init::Init) L::List)) => t(Q, Mods, arrayType(T, size(L) +Int 1))
          requires (size(L) =/=Int 0 orBool getKLabel(Init) =/=K #klabel(`StringLiteral`))
               andBool (notBool isAggregateType(T) orBool isBraceInit(Init))
     rule completeDeclaration(t(Q::Quals, Mods::Set, incompleteArrayType(T:CPPClassType)), BraceInit((ListItem(Init::Init) _) #as L::List)) => t(Q, Mods, arrayType(T, computeAggArraySize(getClassInfo(T), L)))
          requires isAggregateType(T)
               andBool notBool isBraceInit(Init)
     rule completeDeclaration(T::CPPType, _) => T [owise]

     syntax Int ::= computeAggArraySize(ClassInfo, List) [function]
                  | #computeAggArraySize(fields: List, types: Map, initList: List, callStack: List, size: Int, agg: ClassInfo) [function]

     rule computeAggArraySize(CI::ClassInfo, L::List) => #computeAggArraySize(.List, .Map, L, .List, 0, CI)
     rule #computeAggArraySize((.List => getNonStaticDataMembers(CI)), (_ => getDataMembersInitializers(CI)), ListItem(_) _, .List, (N::Int => N +Int 1), CI::ClassInfo)
     rule #computeAggArraySize(... fields: (.List => Fields), types: (_ => Types), callStack: (ListItem(kpair(Fields::List, Types::Map)) => .List) _)
     rule #computeAggArraySize(... initList: .List, size: N::Int) => N
     rule #computeAggArraySize(...
                           fields: (ListItem(kpair(F:CId, _)) => .List) _,
                           types: (F |-> (T::CPPType |-> _)) _,
                           initList: (ListItem(Init::Expr) => .List) _
                           )
          requires (notBool isAggregateType(T) orBool isBraceInit(Init))
     rule #computeAggArraySize(...
                           fields: (ListItem(kpair(F:CId, _)) Fields::List => getNonStaticDataMembers(getClassInfo(T))),
                           types: (((F |-> (T::CPPClassType |-> _)) _) #as Types::Map => getDataMembersInitializers(getClassInfo(T))),
                           initList: ListItem(Init::Expr) _,
                           callStack: (.List => ListItem(kpair(Fields, Types))) _
                           )
          requires isAggregateType(T)
               andBool notBool isBraceInit(Init)

     rule defineObject(_, _, _, _, NoInit(), Function(_), _, _) => .K
     rule defineObject(_, _, _, _, NoInit(), _, _, S::Set) => .K
          requires Extern() in S
     rule defineObject(N:Namespace, X::CId, CName::CId, T::CPPType, Init::Init, Type::DeclarationType, StaticStorage, S::Set)
              => initializeObject(N, X, T, figureInit(
                   allocateDecl(N :: X, CName, T, StaticStorage, S, Type),
                   T, Init, getInitType(Type)), Type)
          requires notBool (Init ==K NoInit() andBool (Extern() in S orBool isCPPFunctionType(T))) andBool isCompleteType(T)
     // Static data member definition
     rule defineObject(C:Class, X::CId, CName::CId, T::CPPType, Init::Expr, Var(Type::InitType), StaticStorage, S::Set)
          => initializeObject(C, X, T, figureInit(
                   allocateDecl(C :: X, CName, T, StaticStorage, S, Var(Type)),
                   T, evalBraceOrEqualInitializer(C, noObject(), Init), Type), Var(Type))
          requires Init =/=K NoInit()
               andBool isCompleteType(T)
     // Function member definition
     rule defineObject(C:Class, X::CId, CName::CId, T::CPPType, Init::Init, Type:FunctionDeclarationType, StaticStorage, S::Set)
          => initializeObject(C, X, T, figureInit(
                   allocateDecl(C :: X, CName, T, StaticStorage, S, Type),
                   T, Init, CopyInit()), Type)
          requires Init =/=K NoInit()
               andBool isCompleteType(T)

     syntax InitType ::= getInitType(DeclarationType) [function]
     rule getInitType(Var(Type::InitType)) => Type
     rule getInitType(_) => CopyInit() [owise]

     syntax Decl ::= defineLocalStaticObject(CId, SymBase, CPPType, Init, DeclarationType, Set)
     rule <k> defineLocalStaticObject(X::CId, Base::SymBase, T::CPPType, Init::Init, Var(Type::InitType), S::Set)
               => addToEnv(NoNamespace() :: X, T, Base, false)
               ~> #if notBool isCPPRefType(T) #then allocObject(Base, T, byteSizeofType(T)) #else .K #fi
               ~> initializeObject(NoNamespace(), X, T, figureInit(
                    lv(lnew(Base), noTrace, T),
                    T, Init, Type), Var(Type)) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <odr-decls> Decls::Map => Decls[Base += odrDecl(Tu, NoNamespace() :: X, #NoName, T)] </odr-decls>
          <odr-defs> Defs::Map => Defs[NoNamespace() :: X, T <- Base] </odr-defs>

     syntax Expr ::= allocateDecl(QualId, CId, CPPType, Duration, Set, DeclarationType)
     rule <k> allocateDecl(N:Namespace :: X::CId, CName::CId, T::CPPType, StaticStorage, S::Set, Type::DeclarationType)
              => addToEnv(N :: X, T, bnew(!I:Int, T, S, static(Tu)), false)
              ~> #if notBool isCPPRefType(T) #then allocObject(bnew(!I, T, S, static(Tu)), T, byteSizeofType(T)) #else .K #fi
              ~> markAsConstexpr(bnew(!I:Int, T, S, static(Tu)), S)
              ~> lv(lnew(bnew(!I, T, S, static(Tu))), noTrace, T) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (_::TypeMap T |-> envEntry(... base: Base:LinkBase)) ...</nenv>
          <linkings>... .Map => Base |-> bnew(!I, T, S, static(Tu)) ...</linkings>
          <odr-decls> Decls::Map => Decls[bnew(!I, T, S, static(Tu)) += odrDecl(Tu, N :: X, CName, T)] </odr-decls>
          <external-types> ET::Map => addOdrDecl(ET, CName, convertTypeToC(T)) </external-types>
          <external-decls-loc> DeclsLoc::Map => addOdrDecl(DeclsLoc, CName, Loc) </external-decls-loc>
          <odr-defs> Defs::Map => Defs[N :: X, T <- bnew(!I, T, S, static(Tu))] </odr-defs>
          <curr-tr-program-loc> Loc::CabsLoc </curr-tr-program-loc>
     rule <k> allocateDecl(C:Class :: X::CId, CName::CId, T::CPPType, StaticStorage, S::Set, Type::DeclarationType)
              => addToEnv(C :: X, T, bnew(!I:Int, T, S, static(Tu)), false)
              ~> #if notBool isCPPRefType(T) #then allocObject(bnew(!I, T, S, static(Tu)), T, byteSizeofType(T)) #else .K #fi
              ~> markAsConstexpr(bnew(!I:Int, T, S, static(Tu)), S)
              ~> lv(lnew(bnew(!I, T, S, static(Tu))), noTrace, T) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... X |-> (_::TypeMap T |-> envEntry(... base: Base:LinkBase)) ...</cenv>
          <linkings>... .Map => Base |-> bnew(!I, T, S, static(Tu)) ...</linkings>
          <odr-decls> Decls::Map => Decls[bnew(!I, T, S, static(Tu)) += odrDecl(Tu, C :: X, CName, T)] </odr-decls>
          <odr-defs> Defs::Map => Defs[C :: X, T <- bnew(!I, T, S, static(Tu))] </odr-defs>
          <external-types> ET::Map => addOdrDecl(ET, CName, convertTypeToC(T)) </external-types>
          <external-decls-loc> DeclsLoc::Map => addOdrDecl(DeclsLoc, CName, Loc) </external-decls-loc>
          <curr-tr-program-loc> Loc::CabsLoc </curr-tr-program-loc>

     syntax KItem ::= markAsConstexpr(SymBase, Set)
     rule <k> markAsConstexpr(B::SymBase, S::Set) => . ...</k>
          <constexpr-symbase> CS::Set => CS SetItem(B)</constexpr-symbase>
          requires Constexpr() in S

     rule markAsConstexpr(_, S::Set) => .
          requires notBool Constexpr() in S

     rule <k> initializeObject(N::NNSVal, X::CId, T::CPPFunctionType, functionDef(Base::SymBase, Body::Stmt), Function(Params::List))
              => initFunction(Base, functionObject(N :: X, T, .List, GotoStmt(funLabel(X))))
              ~> processFunDef(Base, N :: X, T, Params, Body) ...</k>
          <curr-tr-scope> S::Scope </curr-tr-scope>
          requires notBool isClassScope(S)

     rule <k> initializeObject(N::NNSVal, X::CId, T::CPPFunctionType, functionDef(Base::SymBase, Body::Stmt), Function(Params::List))
              => initFunction(Base, functionObject(N :: X, T, .List, GotoStmt(funLabel(X)))) ...</k>
          <deferred-class-actions> _ |> _ |> (K:K => K ~> processFunDef(Base, N :: X, T, Params, Body)) |> .Ordering </deferred-class-actions>
          <curr-tr-scope> classScope(...) </curr-tr-scope>

     syntax KItem ::= initFunction(SymBase, K)

     rule <k> initFunction(Base::SymBase, Val:K) => .K ...</k>
          <functions> F::Map => F[Base <- Val] </functions>

     syntax KItem ::= preserveThreadLocal(K)
                    | restoreThreadLocal1(K)
                    | restoreThreadLocal2(K)


     rule <k> preserveThreadLocal(Computation::K)
              => Computation ~> restoreThreadLocal1(TL)
          ...</k> <thread-local> TL::Bag </thread-local>

     rule restoreThreadLocal1(TL::K) => popBlock ~> restoreThreadLocal2(TL)

     rule <k> restoreThreadLocal2(TL:Bag) => .K  ... </k>
          <thread-local> _ => TL </thread-local>

     syntax KItem ::= "prepareExecutionEnvironment"
     rule <k> prepareExecutionEnvironment => .K ...</k>
          <curr-tr-scope> Sc::Scope </curr-tr-scope>
          <curr-scope> _ => Sc </curr-scope>
          <curr-tr-tu> TU::String </curr-tr-tu>
          <curr-tu> _ => TU </curr-tu>


     rule <k> processFunDef(Base::SymBase, QX::QualId, t(... st: functionType(... methodInfo: MI::MethodInfo)) #as T::CPPFunctionTypeExpr, Params::List, Body::Stmt)
              => preserveThreadLocal(scope(blockScope(QX, Base, 0),
                   prepareExecutionEnvironment ~> pushBlock(!I:Int) ~> elaborateTemplateBody(dummyBind(Params) ~> #if hasThis(MI) #then setTrThis(QX, MI) #else .K #fi ~> getFunDefBody(I, QX, T, Body))
                   ~> calculateGotoMap))
          ...</k>
          <curr-function> _ => Base </curr-function>
          <curr-template-context> I::TemplateInfo </curr-template-context>
          requires I =/=K noTemplate orBool isCPPFunctionType(T)
     syntax Stmt ::= getFunDefBody(TemplateInfo, QualId, CPPFunctionTypeExpr, Stmt) [function]
     rule getFunDefBody(noTemplate, QX::QualId, T::CPPFunctionTypeExpr, Body::Stmt)
          => TLabelStmt(funLabel(getId(QX)), #if isDestructorId(getId(QX)) #then ListItem(Destructor()) #else .List #fi ListItem(Body) ListItem(TReturnOp(getDefaultReturnOp(QX, getReturnType(T)))))
     rule getFunDefBody(_, _, _, Body::Stmt) => Body [owise]

     syntax Bool ::= hasThis(MethodInfo) [function]
     rule hasThis(methodInfo(... static: false)) => true
     rule hasThis(_) => false [owise]
     syntax KItem ::= setTrThis(QualId, MethodInfo)
     rule <k> setTrThis(C:Class :: _, methodInfo(... cvQuals: Q::Quals)) => .K ...</k>
          <tr-this> _ => pre(This(), hasTrace(This()), type(pointerType(t(Q::Quals, .Set, classType(C))))) </tr-this>

     syntax Expr ::= getDefaultReturnOp(QualId, CPPTypeExpr) [function]
     rule getDefaultReturnOp(GlobalNamespace() :: Identifier("main"), T::CPPTypeExpr)
          => le(temp(!I:Int, type(int)), noTrace, T) :=init prv(0, noTrace, type(int))
     rule getDefaultReturnOp(_, _) => prv(voidVal, noTrace, type(void)) [owise]

     syntax KItem ::= dummyBind(List)
     rule (.K => K) ~> dummyBind((ListItem(K:K) => .List) _)
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
     rule isStaticInitialization(le(_ :=init V::Expr, _, _)) => isEvalVal(V)
     rule isStaticInitialization(le(bindReference(_, V::Expr), _, _)) => isEvalVal(V)
     rule isStaticInitialization(compoundInit(E1::Expr, E2::Expr)) => isStaticInitialization(E1) andBool isStaticInitialization(E2)
     rule isStaticInitialization(le(compoundInit(E1::Expr, E2::Expr), _, _) => compoundInit(E1, E2))
     rule isStaticInitialization(pre(compoundInit(E1::Expr, E2::Expr), _, _) => compoundInit(E1, E2))
     rule isStaticInitialization(xe(compoundInit(E1::Expr, E2::Expr), _, _) => compoundInit(E1, E2))


     rule isStaticInitialization(lv(_, _, _)) => true

     syntax Expr ::= stripInitHolds(K) [function]
     rule stripInitHolds(le(compoundInit(E1::Expr, E2::Expr), _, _)) => stripInitHolds(compoundInit(E1, E2))
     rule stripInitHolds(compoundInit(E1::Expr, E2::Expr)) => compoundInit(stripInitHolds(E1), stripInitHolds(E2))
     rule stripInitHolds(le(E::Expr, _, _)) => E [owise]
     rule stripInitHolds(V::Val) => V
          requires isEvalVal(V)

     context defArgs(_, (HOLE:StrictList => types(HOLE)), _)
     context defArgs(_, _, (HOLE:StrictList => cats(HOLE)))

     syntax DefaultArguments ::= computeDefaultArgs(CPPType, DeclarationType)
     rule computeDefaultArgs(T:CPPFunctionType, Function(Params::List))
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
          => ListItem(figureInit(le(temp(!I:Int, T), noTrace, T), T, Init, CopyInit())) #computeDefaultArgs(P, A, false)
          requires notBool (isCPPRefType(T) andBool isExpr(Init))
           andBool Init =/=K NoInit()
     rule #computeDefaultArgs(ListItem(T:CPPRefType) P::List, ListItem(Init::Init) A::List, false)
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

     rule emptyDefaultArguments(T:CPPFunctionType)
       => #emptyDefaultArguments(#if hasImplicitParameter(T) #then size(getRealParams(T)) -Int 1 #else size(getRealParams(T)) #fi, defArgs(krlist(.List), krlist(.List), krlist(.List)))
     rule emptyDefaultArguments(_) => NoDefArgs() [owise]

     syntax DefaultArgumentsResult ::= #emptyDefaultArguments(Int, DefaultArgumentsResult) [function]
     rule #emptyDefaultArguments(0, DA::DefaultArgumentsResult) => DA
     rule #emptyDefaultArguments(N::Int => N -Int 1,
            defArgs(krlist(_::List (.List => ListItem(NoArg()))),
                    krlist(_::List (.List => ListItem(NoInitCat()))),
                    krlist(_::List (.List => ListItem(NoInitType()))))) [owise]
endmodule
