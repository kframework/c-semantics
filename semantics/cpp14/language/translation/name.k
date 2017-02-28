module CPP-TRANSLATION-NAME-SYNTAX
     imports BOOL
     imports CPP-SORTS
     imports COMMON-SORTS

     syntax Expr ::= nameLookupInNamespace(CId, Namespace, Tag, isnns: Bool)
     syntax Expr ::= nameLookup(CId, Tag, isnns: Bool)
endmodule

module CPP-TRANSLATION-NAME
     imports CPP-TRANSLATION-NAME-SYNTAX
     imports COLLECTIONS
     imports COMPAT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DECL-CLASS-SYNTAX
     imports CPP-DECL-TEMPLATE-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports C-CONFIGURATION
     imports CPP-TYPING-SYNTAX
     imports K-EQUAL

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
     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), false) => cSet(M) ...</k>
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

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), false) => cSet(T |-> I M) ...</k>
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
     rule <k> lookupNameInBlock(X::CId, NoTag(), false) => cSet(S) ...</k>
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

     rule CallExpr(Name(NoNNS(), X::CId), Args::StrictList) => argDependentNameLookup(X, Args, Args, nameLookup(X, NoTag(), false))
     rule <k> CallExpr((ExprLoc(L::CabsLoc, E::Expr) => E), Args::StrictList) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
     context CallExpr(Name(HOLE:NNS, _), _)
             requires HOLE =/=K NoNNS()
             [result(NNSVal)]
     rule (.K => qualifiedNameLookup(X, N, false)) ~> CallExpr(Name(N:NNSVal, X::CId), _)
     rule cSet(Y::Map) ~> CallExpr(Name(N:Namespace, X::CId), Args::StrictList)
          => resolveOverload(cSet(Y), Args, Args, Args, X, operator())

     rule (.K => qualifiedNameLookup(X, C, false)) ~> CallExpr(le(_, _, t(... st: classType(C::Class))) . no-template Name(NoNNS(), X::CId), _)
     rule classSet(C::Class, X::CId, Y::Map) ~> CallExpr(Obj::Expr . no-template _, list(Args::List))
          => resolveOverload(cSet(Y),
               list(ListItem(impliedObjArg(Obj)) Args),
               list(ListItem(impliedObjArg(Obj)) Args),
               list(ListItem(impliedObjArg(Obj)) Args),
               X, operator())

     rule <k> classSet(C::Class, X::CId, Y::Map) ~> CallExpr(Name(_, _), list(Args::List))
          => resolveOverload(cSet(Y),
               list(ListItem(impliedObjArg(Obj)) Args),
               list(ListItem(impliedObjArg(Obj)) Args),
               list(ListItem(impliedObjArg(Obj)) Args),
               X, operator())
          ...</k>
          <this> Obj:Expr </this>
          requires isOfDerivedClassOf(Obj, C)

     rule <k> classSet(C::Class, X::CId, Y::Map) ~> CallExpr(Name(_, _), list(Args::List))
          => resolveOverload(cSet(Y),
               list(ListItem(impliedObjArg(contrivedObject(type(classType(C))))) Args),
               list(ListItem(impliedObjArg(contrivedObject(type(classType(C))))) Args),
               list(ListItem(impliedObjArg(contrivedObject(type(classType(C))))) Args),
               X, operator())
          ...</k>
          <this> Obj::Expr </this>
          requires Obj ==K .K
            orBool notBool isOfDerivedClassOf(Obj, C)

     rule (.K => qualifiedNameLookup(X, C, false)) ~> le(_, _, t(_, _, classType(C::Class))) . no-template Name(NoNNS(), X::CId)
     rule (classSet(C::Class, _, _) => .K) ~> _ . no-template Name(NoNNS() => C, _)

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

     syntax Expr ::= argDependentNameLookup(CId, StrictList, StrictList, Expr) [strict(4)]
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
     context argDependentNameLookup(_, _, (HOLE:StrictList => types(HOLE)), _)

     rule <k> (.K => isDependentName(X, Args, Types)) ~> argDependentNameLookup(X::CId, list(Args::List), krlist(Types::List), cSet(_)) ...</k>
          <curr-template-context> templateInfo(...) </curr-template-context>
     rule <k> (.K => false) ~> argDependentNameLookup(X::CId, list(Args::List), krlist(Types::List), cSet(_)) ...</k>
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
     rule cSet((T::CPPTypeExpr |-> _ => .Map) _) ~> isTypeDependent(Name(NoNNS(), _), _)
          requires notBool isDependentInScope(T)
     rule cSet(.Map) ~> isTypeDependent(Name(NoNNS(), _), _) => false

     rule <k> false ~> argDependentNameLookup(X::CId, Args::StrictList, Types::StrictList, cSet(Y::Map)) => resolveOverload(cSet(Y), Args, Types, Args, X, operator()) ...</k>
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
              ~> false ~> argDependentNameLookup(X::CId, list(Args::List), krlist(Types::List), cSet(Y::Map)) ...</k>
          <env> Env::Map </env>
          requires notBool hasSpecialDeclInArgLookup(X, Y, Env)

     // if the argument is the name or address of a set of overloaded functions
     // and/or function templates, its associated classes and namespaces are 
     // the union of those associated with each of the members of the set,
     // i.e., the classes and namespaces associated with its parameter types
     // and return type
     syntax KItem ::= getFunctionAddressTypes(List)
     rule (.K => nameLookup(X, NoTag(), false)) ~> getFunctionAddressTypes((ListItem(Name(NoNNS(), X::CId)) => .List) _)
     rule (cSet(M::Map) => .K) ~> getFunctionAddressTypes(_) ~> false ~> argDependentNameLookup(_, _, krlist(_::List (.List => filterList(keys_list(M), #klabel(`isCPPFunctionType`)))), _)
     rule getFunctionAddressTypes((ListItem(N::Init) => .List) _)
          requires notBool isName(N) andBool notBool isAddressOfName(N)

     syntax Bool ::= isAddressOfName(Init) [function]
     rule isAddressOfName(& N:Name) => true
     rule isAddressOfName(_) => false [owise]

     rule <k> getFunctionAddressTypes(.List) ~> false ~> argDependentNameLookup(X::CId, Args::StrictList, krlist(Types::List), cSet(Y::Map)) => #argDependentNameLookup(X, Args, Types, getAssociatedNamespaces(Types, <namespaces> B </namespaces>), cSet(Y)) ...</k>
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
     rule getAssociatedNamespaces(ListItem(t(Q::Quals, Mods::Set, classType(N::Namespace :: Class(Tag::Tag, X::CId, Args::TemplateParams)))) L::List, B::NamespacesCell)
          => getAssociatedNamespaces(getTemplateArgTypes(Args) L, B) #getAssociatedNamespaces(List2Set(mapList(getAssociatedClasses(t(Q, Mods, classType(N :: Class(Tag, X, Args)))), #klabel(`getInnermostNamespace1`))), B)
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
     rule #getAssociatedClasses(t(_, _, classType(N:Namespace :: C::ClassSpecifier)), #incomplete) => ListItem(classScope(N :: C))

     rule getTemplateArgTypes(t(Q::Quals, Mods::Set, T::CPPSimpleTypeExpr), Ps::TemplateParams) => ListItem(t(Q, Mods, T)) getTemplateArgTypes(Ps)
     rule getTemplateArgTypes(.TemplateParams) => .List

     rule #argDependentNameLookup(X::CId, Args::StrictList, Types::List, .Set, cSet(Y::Map)) => resolveOverload(cSet(Y), Args, krlist(Types), Args, X, operator())
     rule (.K => qualifiedNameLookup(X, N, false)) ~> #argDependentNameLookup(X::CId, _, _, (SetItem(N::Namespace) => .Set) _, _)
     rule (cSet(M::Map) => .K) ~> #argDependentNameLookup(_, _, _, _, cSet(_::Map (.Map => M)))

     // elaborated type specifiers
     rule resolveElabSpecifier(_, T:CPPTypeExpr) => T
     rule resolveElabSpecifier(T:ClassKey, notFound(X::CId)) => declareClassName(T, X, false)

     rule resolveElabSpecifier(templateRef(Q::QualId, T::CPPClassType), krlist(Args::List)) => specializeTypeTemplate(Q, T, Args)
     rule <k> specializeTypeTemplate(X::QualId, t(Q::Quals, Mods::Set, classType(N::Namespace :: Class(Tag::Tag, C::CId, .TemplateArgs))), Args::List) => t(Q, Mods, classType(N :: Class(Tag, C, toTemplateArgs(Args)))) ...</k>

endmodule
