module CPP-TRANSLATION-NAME-SYNTAX
     imports BOOL
     imports CPP-SORTS
     imports COMMON-SORTS
     imports CPP-TYPING-EXPR-SORTS

     syntax Expr ::= nameLookupInNamespace(CId, Namespace, Tag, isnns: Bool)
     syntax Expr ::= nameLookup(CId, Tag, isnns: Bool)
     syntax Expr ::= resolveOverloadedOperator(OpId, Expr, TypeExpr)
                   | resolveOverloadedOperator(OpId, Expr, TypeExpr, Init, K)
endmodule

module CPP-TRANSLATION-NAME
     imports CPP-TRANSLATION-NAME-SYNTAX
     imports C-CONFIGURATION
     imports COLLECTIONS
     imports K-EQUAL
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DECL-CLASS-SYNTAX
     imports CPP-DECL-TEMPLATE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX
     
     syntax Expr ::= wrapInThis(TypeExpr) [strict]
     rule wrapInThis(cSet(M::Map, QX::QualId, .K)) => cSet(M, QX, This())
     rule wrapInThis(T:CPPType) => T
     rule wrapInThis(notFound(X::CId)) => notFound(X)

     syntax CandidateSet ::= classSet(Class, CId, Map) [function]
     rule classSet(C::Class, X::CId, M::Map) => cSet(M, C :: X, .K)

     syntax KItem ::= K "orIfNotFound" K [right, strict(1)]
                   | guardedFind(CId, Bool, K)
     rule notFound(_) orIfNotFound E::K => E
     rule R:KResult orIfNotFound _ => R
          requires notBool isNotFoundNameRef(R)
     rule guardedFind(X::CId, false, _) => notFound(X)
     rule guardedFind(_, true, E::K) => E

     syntax Expr ::= lookupNameInFullClass(id: CId, class: Class, isblock: Bool, tag: Tag, isnns: Bool)
                   | lookupNameInBlock(CId, Tag, isnns: Bool)
                   | lookupMember(CId, Class, Tag, isnns: Bool)
                   | lookupMemberInBaseClasses(CId, baseClasses: List, Tag, isnns: Bool)
                   | lookupOuterMember(CId, outerClass: MaybeNNS, Tag, isnns: Bool)
                   | lookupLocalBeforeClass(CId, Class, Tag, isnns: Bool)
                   | nameLookupInFullNamespace(CId, MaybeNNS, Tag, isnns: Bool)
                   | nameLookupInNamespaceScope(CId, NNS, Tag, isnns: Bool)
                   | nameLookupInNamespaces(CId, set: Set, Tag, isnns: Bool, result: Expr)

     syntax Namespace ::= getInnermostNamespace(Scope) [function, klabel(getInnermostNamespace1)]
     rule getInnermostNamespace(blockScope(N:Namespace :: _, _, _)) => N
     rule getInnermostNamespace(classScope(N:Namespace :: _)) => N
     rule getInnermostNamespace(namespaceScope(N::Namespace)) => N

     // name lookup in namespace scope
     rule <k> nameLookupInNamespaceScope(X::CId, N::Namespace, Tag::Tag, IsNNS::Bool)
          => nameLookupInNamespaces(X, SetItem(N) InlineS, Tag, IsNNS, notFound(X))
          orIfNotFound nameLookupInNamespaces(X, SetItem(N) UsingS, Tag, IsNNS, notFound(X))
          ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <inline-namespaces> InlineS::Set </inline-namespaces>
          <using-namespaces> UsingS::Set </using-namespaces>

     rule nameLookupInNamespaces(... set: .Set, result: R::Expr) => R
     rule nameLookupInNamespaces(X::CId,
            (SetItem(N::Namespace) => .Set) _::Set,
            Tag::Tag,
            IsNNS::Bool,
            R::Expr => cSetUnion(nameLookupInNamespace(X, N, Tag, IsNNS), R))

     // name lookup in a single namespace
     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), false) => cSet(M, N :: X, .K) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> M::Map ...</nenv>
          <templates> T::Map </templates>
          requires notBool N :: X in_keys(T)

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), _) => nsRef(NS) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nested-namespaces>... X |-> NS::Namespace ...</nested-namespaces>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, Tag::Tag, _) => T ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes>... X |-> (_ Tag |-> T::CPPType) ...</ntypes>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), _) => T ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes>... X |-> (_ |-> T::CPPType) ...</ntypes>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), _) => templateRef(N :: X, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <templates>... N :: X |-> (_ T:CPPClassTypeExpr |-> _) ...</templates>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, Tag::Tag, _) => templateRef(N :: X, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <templates>... N :: X |-> (_ T:CPPClassTypeExpr |-> _) ...</templates>
          requires getTag(T) ==K Tag

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), false) => cSet(T |-> I M, N :: X, .K) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <nenv> NE::Map </nenv>
          <templates>... N :: X |-> (T:CPPFunctionTypeExpr |-> I::TemplateInfo M::Map) ...</templates>
          requires notBool X in_keys(NE)

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, _, IsNNS:Bool) => notFound(X) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv> NE::Map </nenv>
          <ntypes> NT::Map </ntypes>
          <nested-namespaces> NN::Map </nested-namespaces>
          <templates> T::Map </templates>
          requires (notBool X in_keys(NE) orBool IsNNS) andBool notBool X in_keys(NT) andBool notBool X in_keys(NN)
               andBool notBool N :: X in_keys(T)

     rule nameLookupInFullNamespace(X::CId, N::Namespace, T::Tag, IsNNS::Bool)
          =>                                                  nameLookupInNamespaceScope(X, N, T, IsNNS)
          orIfNotFound guardedFind(X, hasParentNamespace(N),  nameLookupInFullNamespace(X, getParentNamespace(N), T, IsNNS))

     // unqualified name lookup
     rule <k> lookupNameInBlock(X::CId, NoTag(), false) => cSet(S, NoNamespace() :: X, .K) ...</k>
          <env>... X |-> S::Map ...</env>

     rule <k> lookupNameInBlock(X::CId, NoTag(), _) => T ...</k>
          <types>... X |-> (_ |-> T::CPPType) ...</types>

     rule <k> lookupNameInBlock(X::CId, Tag::Tag, _) => T ...</k>
          <types>... X |-> (_ Tag |-> T::CPPType) ...</types>

     rule <k> lookupNameInBlock(X::CId, _, IsNNS:Bool) => notFound(X) ...</k>
          <env> Env::Map </env>
          <types> Types::Map </types>
          requires (notBool X in_keys(Env) orBool IsNNS)
           andBool notBool X in_keys(Types)

     // lookup member in class (and base-classes)
     rule <k> lookupMember(X::CId, C::Class, NoTag(), false) => classSet(C, X, S) ...</k>
          <class-id> C </class-id>
          <cenv>... X |-> S::Map ...</cenv>

     rule <k> lookupMember(X::CId, C::Class, NoTag(), _) => T ...</k>
          <class-id> C </class-id>
          <ctypes>... X |-> (_ |-> T::CPPType) ...</ctypes>

     rule <k> lookupMember(X::CId, C::Class, Tag::Tag, _) => T ...</k>
          <class-id> C </class-id>
          <ctypes>... X |-> (_ Tag |-> T::CPPType) ...</ctypes>

     rule <k> lookupMember(X::CId, C::Class, T::Tag, IsNNS:Bool) => lookupMemberInBaseClasses(X, BaseClasses, T, IsNNS) ...</k>
          <class-id> C </class-id>
          <base-classes> BaseClasses::List </base-classes>
          <cenv> Env::Map </cenv>
          <ctypes> Types::Map </ctypes>
          requires (notBool X in_keys(Env) orBool IsNNS)
           andBool notBool X in_keys(Types)

     // TODO(traiansf): Define name lookup in base classes
     rule lookupMemberInBaseClasses(X::CId, .List, _, _) => notFound(X)

     // lookup in inner classes
     rule lookupOuterMember(X::CId, C::Class, Tag::Tag, IsNNS::Bool) => lookupMember(X, C, Tag, IsNNS)
          orIfNotFound guardedFind(X, isInnerClass(C),     lookupOuterMember(X, getOuterClass(C), Tag, IsNNS))

     // 3.4.1:8
     rule lookupNameInFullClass(X::CId, C::Class, BlockScope::Bool, Tag::Tag, IsNNS::Bool)
       => guardedFind(X, BlockScope,                        lookupNameInBlock(X, Tag, IsNNS))                            // 3.4.1:8.1
          orIfNotFound                          wrapInThis( lookupMember(X, C, Tag, IsNNS) )                             // 3.4.1:8.2
          orIfNotFound guardedFind(X, isInnerClass(C),      lookupOuterMember(X, getOuterClass(C), Tag, IsNNS))          // 3.4.1:8.3
          orIfNotFound guardedFind(X, isLocalInnerClass(C), lookupLocalBeforeClass(X, C, Tag, IsNNS))                    // 3.4.1:8.4
          orIfNotFound                                      nameLookupInFullNamespace(X, getClassNamespace(C), Tag, IsNNS)   // 3.4.1:8.5

     rule (.K => argDependentNameLookup(X, Args)) ~> CallExpr(Name(NoNNS(), X::CId), Args::StrictList)
     rule <k> CallExpr((ExprLoc(L::CabsLoc, E::Expr) => E), Args::StrictList) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
     context CallExpr(Name(HOLE:NNS, _), _)
             requires HOLE =/=K NoNNS()
             [result(NNSVal)]
     rule (.K => qualifiedNameLookup(X, N, false)) ~> CallExpr(Name(N:NNSVal, X::CId), _)
     rule (.K => qualifiedNameLookup(X, C, false)) ~> CallExpr(le(_, _, t(... st: classType(C::Class))) . no-template Name(NoNNS(), X::CId), _)

     rule cSet(Y::Map, X::QualId, .K) ~> CallExpr(E::Expr, Args::StrictList)
          => resolveOverload(cSet(Y, X, .K), Args, E)

     rule (.K => qualifiedNameLookup(X, C, false)) ~> le(_, _, t(_, _, classType(C::Class))) . no-template Name(NoNNS(), X::CId)

     rule (cSet(_, C:Class :: _, _) => .K) ~> _ . no-template Name(NoNNS() => C, _)

     syntax Bool ::= isQualifiedName(Expr)
     rule isQualifiedName(Name(N::NNS, _)) => true
          requires N =/=K NoNNS()
     rule isQualifiedName(_) => false [owise]

     rule qualifiedNameLookup(X::CId, N:Namespace, IsNNS::Bool) => nameLookupInNamespaceScope(X, N, NoTag(), IsNNS)
     rule qualifiedNameLookup(X::CId, C:Class, IsNNS::Bool) => lookupMember(X, C, NoTag(), IsNNS)

     rule Name(N::NNS, X::CId)
       => resolveUniqueDecl(#if N ==K NoNNS()
                            #then nameLookup(X, NoTag(), false)
                            #else qualifiedNameLookup(X, N, false)
                            #fi, Name(N, X))

     rule ElaboratedTypeSpecifier(T::Tag, X::CId, NoNNS()) => resolveElabSpecifier(T, nameLookup(X, T, false))
     requires T =/=K NoTag()
     rule ElaboratedTypeSpecifier(T::Tag, X::CId, NoNNS(), Args::List) => resolveElabSpecifier(nameLookup(X, T, false), list(Args))
     requires T =/=K NoTag()

     context qualifiedNameLookup(_, (HOLE:NNS), _) [result(NNSVal)]

     rule <k> NoNNS() => N ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
     rule <k> NoNNS() => NoNamespace() ...</k>
          <curr-scope> _:BlockScope </curr-scope>

     rule NNS(X:CId) => extractNNS(nameLookup(X, NoTag(), true))
     rule NNS(Name(N::NNS, X::CId)) => extractNNS(qualifiedNameLookup(X, N, true))
          requires N =/=K NoNNS()
     rule NNS(Name(NoNNS(), X::CId)) => NNS(X)

     syntax KItem ::= extractNNS(K) [strict]
     rule extractNNS(nsRef(N::Namespace)) => N
     rule extractNNS(t(_, _, classType(C::Class))) => C

     syntax Expr ::= argDependentNameLookup(CId, StrictList)
                   | argDependentNameLookup(CId, StrictList, StrictList, Expr) [strict(4)]
                   | #argDependentNameLookup(CId, StrictList, List, Set, CandidateSet)
                   | qualifiedNameLookup(CId, NNS, isnns: Bool)
     syntax AType ::= resolveElabSpecifier(Tag, K) [strict(2)]
                    | resolveElabSpecifier(K, StrictList) [strict(1, 2), klabel(resolveElabSpecifier2)]
                    | specializeTypeTemplate(QualId, CPPType, List)

     rule <k> nameLookup(X::CId, Tag::Tag, IsNNS::Bool) => lookupNameInFullClass(X, classFromScope(Scope), isBlockScope(Scope), Tag, IsNNS) ...</k>
          <curr-scope> Scope::Scope </curr-scope>
          requires inClassScope(Scope)

     // 3.4.1: 6
     rule <k> nameLookup(X::CId, Tag::Tag, IsNNS::Bool) => lookupNameInBlock(X, Tag, IsNNS)
                                 orIfNotFound nameLookupInFullNamespace(X, getInnermostNamespace(Scope), Tag, IsNNS)
          ...</k>
          <curr-scope> Scope::Scope </curr-scope>
          requires notBool inClassScope(Scope)

     // arg dependent name lookup
     rule argDependentNameLookup(X::CId, Args::StrictList) => argDependentNameLookup(X, Args, Args, nameLookup(X, NoTag(), false))

     context argDependentNameLookup(_, _, (HOLE:StrictList => types(HOLE)), _)

     rule <k> (.K => isDependentName(X, Args, Types)) ~> argDependentNameLookup(X::CId, list(Args::List), krlist(Types::List), _:CandidateSet) ...</k>
          <curr-template-context> templateInfo(...) </curr-template-context>
     rule <k> (.K => false) ~> argDependentNameLookup(X::CId, list(Args::List), krlist(Types::List), _:CandidateSet) ...</k>
          <curr-template-context> noTemplate </curr-template-context>

     // TODO(dwightguth): class member stuff
     syntax KItem ::= isDependentName(CId, List, List)
     rule isDependentName(_, ListItem(PackExpansionExpr(_)) _, _) => true
     rule (.K => isTypeDependent(Arg, Type)) ~> isDependentName(_, (ListItem(Arg::Expr) => .List) _, (ListItem(Type::CPPTypeExpr) => .List) _)
     rule true ~> isDependentName(_, _, _) => true
     rule (false => .K) ~> isDependentName(_, _, _)
     rule isDependentName(_, .List, .List) => false
     syntax KItem ::= isTypeDependent(Expr, CPPTypeExpr)
     rule isTypeDependent(StringLiteral(_, _), _) => false
     rule (.K => nameLookup(X, NoTag(), false)) ~> isTypeDependent(Name(NoNNS(), X::CId), _)
     rule cSet(... candidates: (T::CPPTypeExpr |-> _ => .Map) _) ~> isTypeDependent(Name(NoNNS(), _), _)
          requires notBool isDependentInScope(T)
     rule cSet(... candidates: .Map) ~> isTypeDependent(Name(NoNNS(), _), _) => false

     rule <k> false ~> argDependentNameLookup(X::CId, Args::StrictList, Types::StrictList, cSet(Y::Map, QX::QualId, Obj:K)) => cSet(Y, QX, Obj) ...</k>
           <env> Env::Map </env>
           requires hasSpecialDeclInArgLookup(X, Y, Env)

     syntax Bool ::= hasSpecialDeclInArgLookup(CId, Map, Map) [function]
     // 3.4.2:3.2
     rule hasSpecialDeclInArgLookup(X::CId, _, _::Map (X |-> ((T:CPPFunctionTypeExpr |-> kpair(false, _)) _))) => true
     rule hasSpecialDeclInArgLookup(_, T::CPPType |-> _, _) => true
          requires notBool isCPPFunctionType(T)
     rule hasSpecialDeclInArgLookup(_, _, _) => false [owise]

     // associated namespaces
     rule <k> (.K => getFunctionAddressTypes(Args)) 
              ~> false ~> argDependentNameLookup(X::CId, list(Args::List), krlist(Types::List), cSet(... candidates: Y::Map)) ...</k>
          <env> Env::Map </env>
          requires notBool hasSpecialDeclInArgLookup(X, Y, Env)
     rule <k> (.K => getFunctionAddressTypes(Args)) 
              ~> false ~> argDependentNameLookup(X::CId, list(Args::List), krlist(Types::List), notFound(_)) ...</k>
          <env> Env::Map </env>

     // if the argument is the name or address of a set of overloaded functions
     // and/or function templates, its associated classes and namespaces are 
     // the union of those associated with each of the members of the set,
     // i.e., the classes and namespaces associated with its parameter types
     // and return type
     syntax KItem ::= getFunctionAddressTypes(List)
     rule (.K => nameLookup(X, NoTag(), false)) ~> getFunctionAddressTypes((ListItem(Name(NoNNS(), X::CId)) => .List) _)
     rule (cSet(... candidates: M::Map) => .K) ~> getFunctionAddressTypes(_) ~> false ~> argDependentNameLookup(_, _, krlist(_::List (.List => filterList(keys_list(M), #klabel(`isCPPFunctionType`)))), _)
     rule getFunctionAddressTypes((ListItem(N::Init) => .List) _)
          requires notBool isName(N) andBool notBool isAddressOfName(N)

     syntax Bool ::= isAddressOfName(Init) [function]
     rule isAddressOfName(& N:Name) => true
     rule isAddressOfName(_) => false [owise]

     rule <k> getFunctionAddressTypes(.List) ~> false ~> argDependentNameLookup(X::CId, Args::StrictList, krlist(Types::List), Y:CandidateSet) => #argDependentNameLookup(X, Args, Types, getAssociatedNamespaces(Types, <namespaces> B </namespaces>), Y) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <namespaces> B::Bag </namespaces>

     syntax Set ::= getAssociatedNamespaces(List, NamespacesCell) [function]
                   | #getAssociatedNamespaces(Set, NamespacesCell) [function]
     syntax List ::= getAssociatedClasses(CPPTypeExpr) [function]
                   | #getAssociatedClasses(CPPTypeExpr, ClassInfo) [function]
                   | getTemplateArgTypes(TemplateParams) [function]

     // 3.4.2:2.1
     rule getAssociatedNamespaces((ListItem(T:CPPFundamentalType) => .List) _, _)
     rule getAssociatedNamespaces((ListItem(t(_, _, no-type)) => .List) _, _)
     // 3.4.2:2.2
     rule getAssociatedNamespaces(ListItem(t(... st: classType(_ :: Class(_, _, Args::TemplateParams))) #as T::CPPClassType) L::List, B::NamespacesCell)
          => getAssociatedNamespaces(getTemplateArgTypes(Args) L, B) #getAssociatedNamespaces(List2Set(mapList(getAssociatedClasses(T), #klabel(`getInnermostNamespace1`))), B)
     // 3.4.2:2.4
     rule getAssociatedNamespaces(ListItem(T::CPPType => innerType(T)) _, _)
          requires isCPPPointerType(T) orBool isCPPArrayType(T)
     rule getAssociatedNamespaces(.List, _) => .Set

     // If an associated namespace is an inline namespace (7.3.1), its enclosing
     // namespace is also included in the set.
     // If an associated namespace directly contains inline namespaces, those
     // inline namespaces are also included in the set
     rule #getAssociatedNamespaces(SetItem(N::Namespace :: S::NamespaceSpecifier) _::Set (.Set => #if B #then SetItem(N) #else .Set #fi Set), 
          <namespaces>... 
            (<ns>... 
               <ns-id> N :: S </ns-id>
               <is-inline> B:Bool </is-inline>
               <inline-namespaces> Set::Set </inline-namespaces>
            ...</ns>)
            => .Bag
          ...</namespaces>)
     rule #getAssociatedNamespaces(S::Set, _) => S [owise]

     rule getAssociatedClasses(T::CPPClassType) => #getAssociatedClasses(T, getClassInfo(T))
     rule #getAssociatedClasses(t(... st: classType(N:Namespace :: C::ClassSpecifier)), #incomplete) => ListItem(classScope(N :: C))
     rule #getAssociatedClasses(t(... st: classType(N:Namespace :: C::ClassSpecifier)), <class>... <base-classes> Bases::List </base-classes> ...</class>) => ListItem(classScope(N :: C)) mapList(mapList(mapList(Bases, #klabel(`classType`)), #klabel(`cppType`)), #klabel(`getAssociatedClasses`))

     rule getTemplateArgTypes(t(Q::Quals, Mods::Set, T::CPPSimpleTypeExpr), Ps::TemplateParams) => ListItem(t(Q, Mods, T)) getTemplateArgTypes(Ps)
     rule getTemplateArgTypes(.TemplateParams) => .List

     rule #argDependentNameLookup(X::CId, Args::StrictList, Types::List, .Set, Y:CandidateSet) => Y
     rule (.K => qualifiedNameLookup(X, N, false)) ~> #argDependentNameLookup(X::CId, _, _, (SetItem(N::Namespace) => .Set) _, _)
     rule (M:CandidateSet => .K) ~> #argDependentNameLookup(_, _, _, _, Y:CandidateSet => cSetUnion2(M, Y))

     // elaborated type specifiers
     rule resolveElabSpecifier(_, T:CPPTypeExpr) => T
     rule resolveElabSpecifier(T:ClassKey, notFound(X::CId)) => declareClassName(T, X, false)

     rule resolveElabSpecifier(templateRef(Q::QualId, T::CPPClassType), krlist(Args::List)) => specializeTypeTemplate(Q, T, Args)
     rule <k> specializeTypeTemplate(X::QualId, t(Q::Quals, Mods::Set, classType(N::Namespace :: Class(Tag::Tag, C::CId, .TemplateArgs))), Args::List) => t(Q, Mods, classType(N :: Class(Tag, C, toTemplateArgs(Args)))) ...</k>

     // lookup of operator functions for overloading
     rule resolveOverloadedOperator(O::OpId, E1::Expr, T1::CPPType)
          => addBuiltinCandidates(O, E1, T1, E1, memberCandidates(O, T1), nonMemberCandidates(O, E1, utype(T1)))
     rule resolveOverloadedOperator(O::OpId, E1::Expr, T1::CPPType, E2::Init, T2::CPPType)
          => addBuiltinCandidates(O, E1, T1, E1, E2, T2, E2, memberCandidates(O, T1), nonMemberCandidates(O, E1, utype(T1), E2, utype(T2)))

     syntax Expr ::= memberCandidates(OpId, CPPType) [function]
                   | nonMemberCandidates(OpId, Expr, CPPType)
                   | nonMemberCandidates(OpId, Expr, CPPType, Init, CPPType)
                   | addBuiltinCandidates(OpId, Expr, CPPType, cat: CatExpr, Expr, Expr) [strict(5, 6)]
                   | addBuiltinCandidates(OpId, Expr, CPPType, cat1: CatExpr, Init, CPPType, cat2: K, Expr, Expr) [strict(8, 9)]
                   | filterNonMemberLookupSet(Expr, CPPType) [strict(1)]
                   | filterNonMemberLookupSet(Expr, CPPType, CPPType) [strict(1)]
     context addBuiltinCandidates(... cat: HOLE:CatExpr => catof(HOLE)) [result(ValueCategory)]
     context addBuiltinCandidates(... cat1: HOLE:CatExpr => catof(HOLE)) [result(ValueCategory)]
     context addBuiltinCandidates(... cat2: HOLE:CatExpr => catof(HOLE)) [result(ValueCategory)]

     rule memberCandidates(O::OpId, t(... st: classType(C::Class)) #as T::CPPType) => qualifiedNameLookup(O, C, false)
          requires isCompleteType(T)
     rule memberCandidates(O::OpId, _) => notFound(O) [owise]
         
     rule nonMemberCandidates(O::OpId, E1::Expr, T1::CPPType)
          => filterNonMemberLookupSet(argDependentNameLookup(O, list(ListItem(E1))), T1)
     rule nonMemberCandidates(O::OpId, E1::Expr, T1::CPPType, E2::Expr, T2::CPPType)
          => filterNonMemberLookupSet(argDependentNameLookup(O, list(ListItem(E1) ListItem(E2))), T1, T2)
     rule filterNonMemberLookupSet(notFound(_) #as C::CandidateSet, _) => C
     rule filterNonMemberLookupSet(notFound(_) #as C::CandidateSet, _, _) => C
     rule filterNonMemberLookupSet(cSet(M::Map, Q::QualId, Obj:K), T::CPPType)
          => #if isCPPClassType(T) #then cSet(stripMemberFunctions(M), Q, Obj) #else cSet(stripEnum1(stripMemberFunctions(M), T), Q, Obj) #fi
     rule filterNonMemberLookupSet(cSet(M::Map, Q::QualId, Obj:K), T1::CPPType, T2::CPPType)
          => #if isCPPClassType(T1) orBool isCPPClassType(T2) #then cSet(stripMemberFunctions(M), Q, Obj) #else cSet(stripEnum1(stripEnum2(stripMemberFunctions(M), T2), T1), Q, Obj) #fi

     syntax Map ::= stripMemberFunctions(Map) [function]
     rule stripMemberFunctions(M::Map T:CPPFunctionType |-> _) => stripMemberFunctions(M)
          requires isFunctionMember(T)
     rule stripMemberFunctions(.Map) => .Map
     rule stripMemberFunctions(M::Map T::CPPType |-> K:K) => T |-> K stripMemberFunctions(M) [owise]
     syntax Map ::= stripEnum1(Map, CPPType) [function]
                  | stripEnum2(Map, CPPType) [function]
     syntax Bool ::= stripEnum(Int, List, CPPType) [function]
     rule stripEnum1(M::Map T:CPPFunctionType |-> K:K, T1:CPPEnumType)
          => #if stripEnum(0, getParams(T), T1) #then .Map #else T |-> K #fi stripEnum1(M, T1)
     rule stripEnum2(M::Map T:CPPFunctionType |-> K:K, T2:CPPEnumType)
          => #if stripEnum(1, getParams(T), T2) #then .Map #else T |-> K #fi stripEnum1(M, T2)

     rule stripEnum(I::Int, L::List, T::CPPType)
          => size(L) <=Int I orBool ({L[I]}:>CPPType =/=Type T andBool notBool (isCPPRefType(L[I]) andBool utype(innerType({L[I]}:>CPPType)) ==Type T))

     rule stripEnum1(.Map, _) => .Map
     rule stripEnum2(.Map, _) => .Map
     rule stripEnum1(M::Map T::CPPType |-> K:K, T1::CPPType) => T |-> K stripEnum1(M, T1) [owise]
     rule stripEnum2(M::Map T::CPPType |-> K:K, T2::CPPType) => T |-> K stripEnum2(M, T2) [owise]

     rule addBuiltinCandidates(operator,, E1::Expr, _, _, E2::Expr, _, _, C1:CandidateSet, C2:CandidateSet) 
          => resolveEmptyOverload(cSetUnion(C1, C2), list(ListItem(E1) ListItem(E2)), Comma(E1, E2), BinaryOperator(operator,, E1, E2))
     rule addBuiltinCandidates(operator&, E1::Expr, _, _, C1:CandidateSet, C2:CandidateSet)
          => resolveEmptyOverload(cSetUnion(C1, C2), list(ListItem(E1)), & E1, UnaryOperator(operator&, E1))
     rule addBuiltinCandidates(operator->, E1::Expr, _, _, E2::Name, _, _, C1:CandidateSet, C2:CandidateSet)
          => resolveEmptyOverload(cSetUnion(C1, C2), list(ListItem(E1) ListItem(E2)), E1 -> no-template E2, BinaryOperator(operator->, E1, E2))

     syntax Expr ::= resolveEmptyOverload(K, StrictList, Expr, Expr) [strict(1)]
     rule resolveEmptyOverload(notFound(_), _, E::Expr, _) => E
     rule resolveEmptyOverload(cSet(...) #as C::CandidateSet, Args::StrictList, _, E::Expr)
          => resolveOverload(C, Args, E)

endmodule
