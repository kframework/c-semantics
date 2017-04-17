module CPP-TRANSLATION-NAME-SYNTAX
     import SET
     imports CPP-SORTS
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-EXPR-SORTS

     syntax Expr ::= nameLookupInNamespace(CId, Namespace, Tag, mask: Set)
     syntax Expr ::= nameLookup(CId, Tag, mask: Set)
                   | qualifiedNameLookup(CId, NNS, mask: Set)
     syntax Expr ::= resolveOverloadedOperator(OpId, Expr, TypeExpr)
                   | resolveOverloadedOperator(OpId, Expr, TypeExpr, Init, K)

      syntax Set ::= "defaultMask" [function]
                   | "namespaceMask" [function]
                   | "nnsMask" [function]
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

     syntax LookupCategory ::= "type" | "namespace" | "variable" | "function"

     rule defaultMask => SetItem(type) SetItem(namespace) SetItem(variable) SetItem(function)
     rule namespaceMask => SetItem(namespace)
     rule nnsMask => SetItem(type) SetItem(namespace)

     syntax Expr ::= lookupNameInFullClass(id: CId, class: Class, isblock: Bool, tag: Tag, mask: Set)
                   | lookupNameInBlock(CId, Tag, mask: Set)
                   | lookupMember(CId, Class, Tag, mask: Set)
                   | lookupMemberInBaseClasses(CId, baseClasses: List, Tag, mask: Set)
                   | lookupOuterMember(CId, outerClass: MaybeNNS, Tag, mask: Set)
                   | lookupLocalBeforeClass(CId, Class, Tag, mask: Set)
                   | nameLookupInFullNamespace(CId, MaybeNNS, Tag, mask: Set, usingDirectives: Set)
                   | nameLookupInNamespaceScope(CId, NNS, Tag, mask: Set)
                   | nameLookupInUsingDirectives(CId, set: Set, Tag, Set, usingS: Set, result: Expr)
                   | nameLookupInNamespaces(CId, set: Set, Tag, mask: Set, result: Expr)
                   | nameLookupInEnumScope(CId, Tag, mask: Set, EnumScope)
                   | nameLookupInScope(CId, Tag, mask: Set, scope: Scope)
                   | lookupEnumerator(CId, Enum, mask: Set)

     syntax Namespace ::= getInnermostNamespace(Scope) [function, klabel(getInnermostNamespace1)]
     rule getInnermostNamespace(blockScope(N:Namespace :: _, _, _)) => N
     rule getInnermostNamespace(classScope(N:Namespace :: _)) => N
     rule getInnermostNamespace(namespaceScope(N::Namespace)) => N
     rule getInnermostNamespace(enumScope(enumId(N:Namespace :: _))) => N

     syntax Scope ::= getRestOfScope(EnumScope) [function]
     rule getRestOfScope(enumScope(enumId(N:Namespace :: _))) => namespaceScope(N)

     // name lookup in namespace scope
     rule <k> nameLookupInNamespaceScope(X::CId, N::Namespace, Tag::Tag, Mask::Set)
          => nameLookupInNamespaces(X, SetItem(N) InlineS, Tag, Mask, notFound(X))
          orIfNotFound nameLookupInUsingDirectives(X, SetItem(N) InlineS, Tag, Mask, .Set, notFound(X))
          ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <inline-namespaces> InlineS::Set </inline-namespaces>
          <nusing-namespaces> UsingS::Set </nusing-namespaces>

     rule <k> nameLookupInUsingDirectives(... set: (SetItem(N::Namespace) => .Set) _, 
                   usingS: (.Set => UsingS) _)
          ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nusing-namespaces> UsingS::Set </nusing-namespaces>
     rule nameLookupInUsingDirectives(X::CId, .Set, Tag::Tag, Mask::Set, 
               (SetItem(N::Namespace) => .Set ) _, 
               R::Expr => cSetUnion(nameLookupInNamespaceScope(X, N, Tag, Mask), R))
     rule nameLookupInUsingDirectives(... set: .Set, usingS: .Set, result: R::Expr) => R

     rule nameLookupInNamespaces(... set: .Set, result: R::Expr) => R
     rule nameLookupInNamespaces(X::CId,
            (SetItem(N::Namespace) => .Set) _::Set,
            Tag::Tag,
            Mask::Set,
            R::Expr => cSetUnion(nameLookupInNamespace(X, N, Tag, Mask), R))

     // name lookup in a single namespace
     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => lookupEnumerator(X, E, Mask)  ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <unscoped-enumerators>... X |-> E::Enum ...</unscoped-enumerators>
          <templates> T::Map </templates>
          requires notBool N :: X in_keys(T)
               andBool variable in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => cSet(M, N :: X, .K) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> M::Map ...</nenv>
          <templates> T::Map </templates>
          <unscoped-enumerators> UE::Map </unscoped-enumerators>
          requires notBool N :: X in_keys(T) andBool notBool X in_keys(UE)
               andBool envMask(X |-> M, X, Mask)

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => nsRef(NS) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nested-namespaces>... X |-> NS::Namespace ...</nested-namespaces>
          requires namespace in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, Tag::Tag, Mask::Set) => T ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes>... X |-> (_ Tag |-> T::CPPType) ...</ntypes>
          requires type in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => T ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes>... X |-> (_ |-> T::CPPType) ...</ntypes>
          requires type in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => templateRef(N :: X, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <templates>... N :: X |-> (_ T:CPPClassTypeExpr |-> _) ...</templates>
          requires type in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, Tag::Tag, Mask::Set) => templateRef(N :: X, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <templates>... N :: X |-> (_ T:CPPClassTypeExpr |-> _) ...</templates>
          requires getTag(T) ==K Tag andBool type in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => cSet(T |-> I M, N :: X, .K) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <nenv> NE::Map </nenv>
          <templates>... N :: X |-> (T:CPPFunctionTypeExpr |-> I::TemplateInfo M::Map) ...</templates>
          requires notBool X in_keys(NE)
               andBool function in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, _, Mask::Set) => notFound(X) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv> NE::Map </nenv>
          <ntypes> NT::Map </ntypes>
          <nested-namespaces> NN::Map </nested-namespaces>
          <templates> T::Map </templates>
          requires (notBool X in_keys(NE) orBool notBool envMask(NE, X, Mask)) andBool (notBool X in_keys(NT) orBool notBool type in Mask) andBool (notBool X in_keys(NN) orBool notBool namespace in Mask)
               andBool (notBool N :: X in_keys(T) orBool notBool templateMask(T, N :: X, Mask))

     syntax Bool ::= templateMask(Map, QualId, Set) [function]
                   | envMask(Map, CId, Set) [function]
     rule templateMask((N :: X |-> ((T:CPPFunctionTypeExpr |-> _) _)) _, N::NNSVal :: X::CId, Mask::Set)
          => function in Mask
     rule templateMask((N :: X |-> ((T:CPPClassTypeExpr |-> _) _)) _, N::NNSVal :: X::CId, Mask::Set)
          => type in Mask
     rule templateMask((N :: X |-> _) _, N::NNSVal :: X::CId, Mask::Set)
          => variable in Mask [owise]
     rule envMask((X |-> ((T:CPPFunctionType |-> _) _)) _, X::CId, Mask::Set)
          => function in Mask
     rule envMask((X |-> _) _, X::CId, Mask::Set)
          => variable in Mask

     rule <k> nameLookupInFullNamespace(X::CId, N::Namespace, T::Tag, Mask::Set, OldUsingDirectives::Set)
          =>                                                  nameLookupInNamespaces(X, SetItem(N) getUsingNamespaces(BlockUsingDirectives NewUsingDirectives OldUsingDirectives, N), T, Mask, notFound(X))
          orIfNotFound guardedFind(X, hasParentNamespace(N),  nameLookupInFullNamespace(X, getParentNamespace(N), T, Mask, (OldUsingDirectives NewUsingDirectives) -Set getUsingNamespaces(BlockUsingDirectives NewUsingDirectives OldUsingDirectives, N)))
          ...</k>
          <using-namespaces> BlockUsingDirectives::Set </using-namespaces>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id> 
          <nusing-namespaces> NewUsingDirectives::Set </nusing-namespaces> 

     syntax Set ::= getUsingNamespaces(Set, Namespace) [function]
     rule getUsingNamespaces(SetItem(Using::Namespace) S::Set, N::Namespace) => SetItem(Using) getUsingNamespaces(S, N)
          requires enclosesNamespace(N, Using)
     rule getUsingNamespaces(.Set, _) => .Set
     rule getUsingNamespaces(SetItem(_) S::Set, N::Namespace) => getUsingNamespaces(S, N) [owise]

     // unqualified name lookup
     rule <k> lookupNameInBlock(X::CId, NoTag(), Mask::Set) => cSet(S, NoNamespace() :: X, .K) ...</k>
          <curr-scope> Scope:BlockScope </curr-scope>
          <env>... X |-> S::Map ...</env>
          requires envMask(X |-> S, X, Mask)

     rule <k> lookupNameInBlock(X::CId, NoTag(), Mask::Set) => T ...</k>
          <types>... X |-> (_ |-> T::CPPType) ...</types>
          requires type in Mask

     rule <k> lookupNameInBlock(X::CId, Tag::Tag, Mask::Set) => T ...</k>
          <types>... X |-> (_ Tag |-> T::CPPType) ...</types>
          requires type in Mask

     rule <k> lookupNameInBlock(X::CId, _, Mask::Set) => notFound(X) ...</k>
          <env> Env::Map </env>
          <types> Types::Map </types>
          requires (notBool X in_keys(Env) orBool notBool envMask(Env, X, Mask))
           andBool (notBool X in_keys(Types) orBool notBool type in Mask)

     rule <k> lookupEnumerator(X::CId, E::Enum, Mask::Set) => V ... </k>
          <curr-scope> enumScope(enumId(E)) </curr-scope>
          <enum-id> enumId(E) </enum-id>
          <enumerators>... X |-> V::PRVal </enumerators>
          requires variable in Mask

     rule <k> lookupEnumerator(X::CId, E::Enum, Mask::Set) => prv(V, Tr, ET) ... </k>
          <curr-scope> Sc::Scope </curr-scope>
          <enum-id> enumId(E) </enum-id>
          <enum-type> ET::CPPType </enum-type>
          <enumerators>... X |-> prv(V::CPPValue, Tr::Trace, _) </enumerators>
          requires Sc =/=K enumScope(enumId(E))
               andBool variable in Mask

     rule <k> lookupEnumerator(X::CId, E::Enum, Mask::Set) => notFound(X) ...</k>
          <enum-id> enumId(E) </enum-id>
          <enumerators> Enumerators::Map </enumerators>
          requires notBool X in_keys(Enumerators) orBool notBool variable in Mask

     // lookup member in class (and base-classes)
     rule <k> lookupMember(X::CId, C::Class, NoTag(), Mask::Set) => classSet(C, X, S) ...</k>
          <class-id> C </class-id>
          <cenv>... X |-> S::Map ...</cenv>
          requires envMask(X |-> S, X, Mask)

     rule <k> lookupMember(X::CId, C::Class, NoTag(), Mask::Set) => T ...</k>
          <class-id> C </class-id>
          <ctypes>... X |-> (_ |-> T::CPPType) ...</ctypes>
          requires type in Mask

     rule <k> lookupMember(X::CId, C::Class, Tag::Tag, Mask::Set) => T ...</k>
          <class-id> C </class-id>
          <ctypes>... X |-> (_ Tag |-> T::CPPType) ...</ctypes>
          requires type in Mask

     rule <k> lookupMember(X::CId, C::Class, T::Tag, Mask::Set) => lookupMemberInBaseClasses(X, BaseClasses, T, Mask) ...</k>
          <class-id> C </class-id>
          <base-classes> BaseClasses::List </base-classes>
          <cenv> Env::Map </cenv>
          <ctypes> Types::Map </ctypes>
          requires (notBool X in_keys(Env) orBool notBool envMask(Env, X, Mask))
           andBool (notBool X in_keys(Types) orBool notBool type in Mask)

     // TODO(traiansf): Define name lookup in base classes
     rule lookupMemberInBaseClasses(X::CId, .List, _, _) => notFound(X)

     // lookup in inner classes
     rule lookupOuterMember(X::CId, C::Class, Tag::Tag, Mask::Set) => lookupMember(X, C, Tag, Mask)
          orIfNotFound guardedFind(X, isInnerClass(C),     lookupOuterMember(X, getOuterClass(C), Tag, Mask))

     // 3.4.1:8
     rule lookupNameInFullClass(X::CId, C::Class, BlockScope::Bool, Tag::Tag, Mask::Set)
       => guardedFind(X, BlockScope,                        lookupNameInBlock(X, Tag, Mask))                            // 3.4.1:8.1
          orIfNotFound                          wrapInThis( lookupMember(X, C, Tag, Mask) )                             // 3.4.1:8.2
          orIfNotFound guardedFind(X, isInnerClass(C),      lookupOuterMember(X, getOuterClass(C), Tag, Mask))          // 3.4.1:8.3
          orIfNotFound guardedFind(X, isLocalInnerClass(C), lookupLocalBeforeClass(X, C, Tag, Mask))                    // 3.4.1:8.4
          orIfNotFound                                      nameLookupInFullNamespace(X, getClassNamespace(C), Tag, Mask, .Set)   // 3.4.1:8.5

     rule (.K => argDependentNameLookup(X, Args)) ~> CallExpr(Name(NoNNS(), X::CId), Args::StrictList, krlist(.List))
     rule <k> CallExpr((ExprLoc(L::CabsLoc, E::Expr) => E), Args::StrictList, krlist(.List)) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
     context CallExpr(Name(HOLE:NNS, _), _, _)
             requires HOLE =/=K NoNNS()
             [result(NNSVal)]
     rule (.K => qualifiedNameLookup(X, N, defaultMask)) ~> CallExpr(Name(N:NNSVal, X::CId), _, krlist(.List))
     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> CallExpr(le(_, _, t(... st: classType(C::Class))) . no-template Name(NoNNS(), X::CId), _, krlist(.List))
     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> CallExpr(lv(_, _, t(... st: classType(C::Class))) . no-template Name(NoNNS(), X::CId), _, krlist(.List))
     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> CallExpr(xe(_, _, t(... st: classType(C::Class))) . no-template Name(NoNNS(), X::CId), _, krlist(.List))
     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> CallExpr(xv(_, _, t(... st: classType(C::Class))) . no-template Name(NoNNS(), X::CId), _, krlist(.List))

     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> CallExpr(V:Val . no-template Name(C:NNSVal, X::CId), _, _)

     rule cSet(Y::Map, X::QualId, .K) ~> CallExpr(E::Expr, Args::StrictList, krlist(.List))
          => resolveOverload(cSet(Y, X, .K), Args, E)
     rule cSet(Y::Map, X::QualId, This()) ~> CallExpr(N:Name, Args::StrictList, krlist(.List))
          => resolveOverload(cSet(Y, X, This()), Args, (* This()) . no-template N)

     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> le(_, _, t(... st: classType(C::Class))) . no-template Name(NoNNS(), X::CId)
     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> lv(_, _, t(... st: classType(C::Class))) . no-template Name(NoNNS(), X::CId)

     rule (cSet(_, C:Class :: _, _) => .K) ~> _ . no-template Name(NoNNS() => C, _)

     syntax Bool ::= isQualifiedName(Expr)
     rule isQualifiedName(Name(N::NNS, _)) => true
          requires N =/=K NoNNS()
     rule isQualifiedName(_) => false [owise]

     rule qualifiedNameLookup(X::CId, N:Namespace, Mask::Set) => nameLookupInNamespaceScope(X, N, NoTag(), Mask)
     rule qualifiedNameLookup(X::CId, C:Class, Mask::Set) => lookupMember(X, C, NoTag(), Mask)
     rule qualifiedNameLookup(X::CId, E:Enum, Mask::Set) => lookupEnumerator(X::CId, E, Mask)

     rule Name(N::NNS, X::CId)
       => resolveUniqueDecl(#if N ==K NoNNS()
                            #then nameLookup(X, NoTag(), defaultMask)
                            #else qualifiedNameLookup(X, N, defaultMask)
                            #fi, Name(N, X))

     rule ElaboratedTypeSpecifier(T::Tag, X::CId, NoNNS()) => resolveElabSpecifier(T, nameLookup(X, T, SetItem(type)))
     requires T =/=K NoTag()
     rule ElaboratedTypeSpecifier(T::Tag, X::CId, NoNNS(), Args::List) => resolveElabSpecifier(nameLookup(X, T, SetItem(type)), list(Args))
     requires T =/=K NoTag()

     context qualifiedNameLookup(_, (HOLE:NNS), _) [result(NNSVal)]

     rule <k> NoNNS() => N ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
     rule <k> NoNNS() => NoNamespace() ...</k>
          <curr-scope> _:BlockScope </curr-scope>

     rule NNS(X:CId) => extractNNS(nameLookup(X, NoTag(), nnsMask))
     rule NNS(Name(N::NNS, X::CId)) => extractNNS(qualifiedNameLookup(X, N, nnsMask))
          requires N =/=K NoNNS()
     rule NNS(Name(NoNNS(), X::CId)) => NNS(X)

     syntax KItem ::= extractNNS(K) [strict]
     rule extractNNS(nsRef(N::Namespace)) => N
     rule extractNNS(t(_, _, classType(C::Class))) => C
     rule extractNNS(t(_, _, scopedEnum(enumId(E::Enum), _))) => E
     rule extractNNS(t(_, _, unscopedEnum(enumId(E::Enum), _, _))) => E

     syntax Expr ::= argDependentNameLookup(CId, StrictList)
                   | argDependentNameLookup(CId, StrictList, StrictList, Expr) [strict(4)]
                   | #argDependentNameLookup(CId, StrictList, List, Set, CandidateSet)
     syntax AType ::= resolveElabSpecifier(Tag, K) [strict(2)]
                    | resolveElabSpecifier(K, StrictList) [strict(1, 2), klabel(resolveElabSpecifier2)]
                    | specializeTypeTemplate(QualId, CPPType, List)

     rule <k> nameLookup(X::CId, Tag::Tag, Mask::Set) => nameLookupInScope(X, Tag, Mask, Scope) ...</k>
          <curr-scope> Scope::Scope </curr-scope>

     rule nameLookupInScope(X::CId, Tag::Tag, Mask::Set, Scope::Scope) => lookupNameInFullClass(X, classFromScope(Scope), isBlockScope(Scope), Tag, Mask)
          requires inClassScope(Scope)

     rule nameLookupInScope(X::CId, Tag::Tag, Mask::Set, enumScope(E::EnumId)) => nameLookupInEnumScope(X, Tag, Mask, enumScope(E))

     // 3.4.1: 6
     rule nameLookupInScope(X::CId, Tag::Tag, Mask::Set, Scope::Scope) => lookupNameInBlock(X, Tag, Mask)
                                 orIfNotFound nameLookupInFullNamespace(X, getInnermostNamespace(Scope), Tag, Mask, .Set)
          requires notBool inClassScope(Scope) andBool notBool isEnumScope(Scope)

     rule <k> nameLookupInEnumScope(X::CId, _, _, enumScope(E::EnumId)) => V ... </k>
          <enum-id> E </enum-id>
          <enumerators>... X |-> V::PRVal ...</enumerators>

     rule <k> nameLookupInEnumScope(X::CId, Tag::Tag, Mask::Set, enumScope(E::EnumId)) => nameLookupInScope(X, Tag, Mask, getRestOfScope(enumScope(E))) ... </k>
          <enum-id> E </enum-id>
          <enumerators> Enumerators::Map </enumerators>
          requires notBool X in_keys(Enumerators) orBool notBool variable in Mask


     // arg dependent name lookup
     rule argDependentNameLookup(X::CId, Args::StrictList) => argDependentNameLookup(X, Args, Args, nameLookup(X, NoTag(), defaultMask))

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
     rule (.K => nameLookup(X, NoTag(), defaultMask)) ~> isTypeDependent(Name(NoNNS(), X::CId), _)
     rule cSet(... candidates: (T::CPPTypeExpr |-> _ => .Map) _) ~> isTypeDependent(Name(NoNNS(), _), _)
          requires notBool isDependentInScope(T)
     rule cSet(... candidates: .Map) ~> isTypeDependent(Name(NoNNS(), _), _) => false

     rule <k> false ~> argDependentNameLookup(X::CId, Args::StrictList, Types::StrictList, cSet(Y::Map, QX::QualId, Obj:K)) => cSet(Y, QX, Obj) ...</k>
           <env> Env::Map </env>
           requires hasSpecialDeclInArgLookup(X, Y, Env)

     syntax Bool ::= hasSpecialDeclInArgLookup(CId, Map, Map) [function]
     // 3.4.2:3.2
     rule hasSpecialDeclInArgLookup(X::CId, _, _::Map (X |-> ((T:CPPFunctionTypeExpr |-> envEntry(... using: false)) _))) => true
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
     rule (.K => nameLookup(X, NoTag(), defaultMask)) ~> getFunctionAddressTypes((ListItem(Name(NoNNS(), X::CId)) => .List) _)
     rule (cSet(... candidates: M::Map) => .K) ~> getFunctionAddressTypes(_) ~> false ~> argDependentNameLookup(_, _, krlist(_::List (.List => filterList(keys_list(M), #klabel(`isCPPFunctionType`)))), _)
     rule getFunctionAddressTypes((ListItem(N::Init) => .List) _)
          requires notBool isName(N) andBool notBool isAddressOfName(N)

     syntax Bool ::= isAddressOfName(Init) [function]
     rule isAddressOfName(& N:Name) => true
     rule isAddressOfName(UnaryOperator(operator&, N:Name)) => true
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
     // 3.4.2:2.3
     rule getAssociatedNamespaces(ListItem(t(_, _, scopedEnum(enumId(N::Namespace :: _), _))) L::List, B::NamespacesCell)
          => getAssociatedNamespaces(L, B) #getAssociatedNamespaces(SetItem(N), B)
     rule getAssociatedNamespaces(ListItem(t(_, _, unscopedEnum(enumId(N::Namespace :: _), _, _))) L::List, B::NamespacesCell)
          => getAssociatedNamespaces(L, B) #getAssociatedNamespaces(SetItem(N), B)

     // 3.4.2:2.4
     rule getAssociatedNamespaces(ListItem(T::CPPType => innerType(T)) _, _)
          requires isCPPPointerType(T) orBool isCPPArrayType(T)
     rule getAssociatedNamespaces((ListItem(initListType(_)) => .List) _, _)
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
     rule (.K => qualifiedNameLookup(X, N, SetItem(function))) ~> #argDependentNameLookup(X::CId, _, _, (SetItem(N::Namespace) => .Set) _, _)
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

     rule memberCandidates(O::OpId, t(... st: classType(C::Class)) #as T::CPPType) => qualifiedNameLookup(O, C, defaultMask)
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
          => resolveEmptyOverload(cSetUnion2(C1, C2), list(ListItem(E1) ListItem(E2)), Comma(E1, E2), BinaryOperator(operator,, E1, E2))
     rule addBuiltinCandidates(operator&, E1::Expr, _, _, C1:CandidateSet, C2:CandidateSet)
          => resolveEmptyOverload(cSetUnion2(C1, C2), list(ListItem(E1)), & E1, UnaryOperator(operator&, E1))
     rule addBuiltinCandidates(operator->, E1::Expr, _, _, E2::Name, _, _, C1:CandidateSet, C2:CandidateSet)
          => resolveEmptyOverload(cSetUnion2(C1, C2), list(ListItem(E1) ListItem(E2)), E1 -> no-template E2, BinaryOperator(operator->, E1, E2))

     syntax Expr ::= resolveEmptyOverload(K, StrictList, Expr, Expr) [strict(1)]
                   | #resolveEmptyOverload(Expr, Expr)
     rule resolveEmptyOverload(C::CandidateSet, Args::StrictList, Builtin::Expr, E::Expr)
          => #resolveEmptyOverload(resolveOverload(C, Args, E), Builtin)
     context #resolveEmptyOverload(HOLE:Expr, _) [result(ResolvedExpr), structural]
     rule #resolveEmptyOverload(E:ResolvedExpr, _) => E
          requires notBool isNotFoundNameRef(E)
     // no viable candidates
     rule #resolveEmptyOverload(notFound(_), E::Expr) => E
     

endmodule
