module CPP-TRANSLATION-NAME-SYNTAX
     imports SET
     imports CPP-SORTS
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TRANSLATION-TYPING-EXPR-SORTS

     syntax Expr ::= nameLookupInNamespace(CId, Namespace, Tag, mask: Set)

     syntax Expr ::= nameLookup(CId, Tag, mask: Set)
                   | qualifiedNameLookup(CId, NNS, mask: Set)

     // evaluates to `resolveOverloadResult(_)`
     syntax Expr ::= resolveOverloadedOperator(OpId, Expr, TypeExpr)
                   | resolveOverloadedOperator(OpId, Expr, TypeExpr, Init, K)

     syntax KItem ::= KItem "orIfNotFound" K [right, strict(1)]
                    | guardedFind(CId, Bool, K)

     syntax Set ::= "defaultMask" [function]
                  | "namespaceMask" [function]
                  | "nnsMask" [function]
                  | "typeMask" [function]

endmodule

module CPP-TRANSLATION-NAME
     imports CPP-TRANSLATION-NAME-SYNTAX
     imports C-CONFIGURATION
     imports COLLECTIONS
     imports K-EQUAL
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-SYNTAX
     imports CPP-TRANSLATION-DECL-TEMPLATE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-OPERATORS-SYNTAX
     imports CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX

     syntax CandidateSet ::= classSet(K, QualId, Set)

     rule notFound(_) orIfNotFound E::K => E

     rule R:KResult orIfNotFound _ => R
          requires notBool isNotFoundNameRef(R)

     rule guardedFind(X::CId, false, _) => notFound(X)

     rule guardedFind(_, true, E::K) => E

     syntax LookupCategory ::= "type" | "namespace" | "variable" | "function"

     rule defaultMask => SetItem(type) SetItem(namespace) SetItem(variable) SetItem(function)

     rule namespaceMask => SetItem(namespace)

     rule nnsMask => SetItem(type) SetItem(namespace)

     rule typeMask => SetItem(type)

     syntax Expr ::= lookupNameInFullClass(id: CId, class: Class, isbody: Bool, isblock: Bool, tag: Tag, mask: Set)
                   | lookupNameInBlock(CId, Tag, mask: Set)
                   | lookupMember(CId, Class, isbody: Bool, Tag, mask: Set)
                   | #lookupMember(CId, Class, isbody: Bool, Tag, mask: Set)
                   | lookupMemberInBaseClasses(CId, baseClasses: List, Tag, mask: Set, result: Expr)
                   | lookupOuterMember(CId, outerClass: MaybeNNS, isbody: Bool, Tag, mask: Set)
                   | lookupLocalBeforeClass(CId, Class, Tag, mask: Set)
                   | nameLookupInFullNamespace(CId, MaybeNNS, Tag, mask: Set, usingDirectives: Set)
                   | nameLookupInNamespaceScope(CId, NNS, Tag, mask: Set)
                   | nameLookupInUsingDirectives(CId, set: Set, Tag, Set, usingS: Set, result: Expr)
                   | nameLookupInNamespaces(CId, set: Set, Tag, mask: Set, result: Expr)
                   | nameLookupInEnumScope(CId, Tag, mask: Set, EnumScope)
                   | nameLookupInScope(CId, Tag, mask: Set, scope: Scope)
                   | lookupEnumerator(CId, Enum, mask: Set, class: K)

     syntax Namespace ::= getInnermostNamespace(Scope) [function, klabel(getInnermostNamespace1)]
     syntax List ::= getInnermostNamespaces(List) [function]

     rule getInnermostNamespaces(.List) => .List
     rule getInnermostNamespaces(ListItem(S::Scope) L::List) => ListItem(getInnermostNamespace(S)) getInnermostNamespaces(L)

     rule getInnermostNamespace(blockScope(N:Namespace :: _, _, _)) => N

     rule getInnermostNamespace(classScope(N:Namespace :: _, _)) => N

     rule getInnermostNamespace(namespaceScope(N::Namespace)) => N

     rule getInnermostNamespace(enumScope(N:Namespace :: _)) => N

     syntax Scope ::= getRestOfScope(EnumScope) [function]

     rule getRestOfScope(enumScope(N:Namespace :: _)) => namespaceScope(N)

     rule getRestOfScope(enumScope(localQual(B::BlockScope) :: _)) => B

     // TODO with class

     // name lookup in namespace scope
     rule <k> nameLookupInNamespaceScope(X::CId, N::Namespace, Tag::Tag, Mask::Set)
          => nameLookupInNamespaces(X, SetItem(N) InlineS, Tag, Mask, notFound(X))
          orIfNotFound nameLookupInUsingDirectives(X, SetItem(N) InlineS, Tag, Mask, .Set, notFound(X))
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <inline-namespaces> InlineS::Set </inline-namespaces>

     rule <k> nameLookupInUsingDirectives(... set: (SetItem(N::Namespace) => .Set) _,
                   usingS: (.Set => UsingS) _)
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
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
     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => lookupEnumerator(X, E, Mask, .K)  ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenums>... X |-> E::Enum ...</nenums>
          requires variable in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => cSet(M, N :: X) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> M::Map ...</nenv>
          requires envMask(X |-> M, X, Mask)

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => nsRef(NS) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nested-namespaces>... X |-> NS::Namespace ...</nested-namespaces>
          requires namespace in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, _, Mask::Set) => T ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes>... X |-> T::CPPType ...</ntypes>
          requires type in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => templateRef(N :: X, T) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <templates>... N :: X |-> (_::Map _::CPPType |-> (T::CPPType, _)) ...</templates>
          requires isCPPClassType(T) andBool type in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, Tag::Tag, Mask::Set) => templateRef(N :: X, T) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <templates>... N :: X |-> (_::Map (_::CPPType |-> (T::CPPType, _))) ...</templates>
          requires isCPPClassType(T) andBool getTag(T) ==K Tag andBool type in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag(), Mask::Set) => cSet(stripType(T) |-> (T, I) M, N :: X) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <nenv> NE::Map </nenv>
          <templates>... N :: X |-> (_::CPPType |-> (T::CPPType, I::TemplateInfo) M::Map) ...</templates>
          requires isCPPFunctionType(T) andBool notBool X in_keys(NE)
               andBool function in Mask

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, _, Mask::Set) => notFound(X) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
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

     rule templateMask((N :: X |-> ((_::CPPType |-> (T::CPPType, _)) _::Map)) _, N::NNSVal :: X::CId, Mask::Set)
          => function in Mask
          requires isCPPFunctionType(T)

     rule templateMask((N :: X |-> ((_::CPPType |-> (T::CPPType, _)) _::Map)) _, N::NNSVal :: X::CId, Mask::Set)
          => type in Mask
          requires isCPPClassType(T)

     rule templateMask((N :: X |-> _) _, N::NNSVal :: X::CId, Mask::Set)
          => variable in Mask [owise]

     rule envMask((X |-> ((_::CPPType |-> (T::CPPType, _)) _::Map)) _, X::CId, Mask::Set)
          => function in Mask
          requires isCPPFunctionType(T)

     rule envMask((X |-> _) _, X::CId, Mask::Set)
          => variable in Mask [owise]

     rule <k> nameLookupInFullNamespace(X::CId, N::Namespace, T::Tag, Mask::Set, OldUsingDirectives::Set)
          =>                                                  nameLookupInNamespaces(X, SetItem(N) getUsingNamespaces(BlockUsingDirectives NewUsingDirectives OldUsingDirectives, N), T, Mask, notFound(X))
          orIfNotFound guardedFind(X, hasParentNamespace(N),  nameLookupInFullNamespace(X, getParentNamespace(N), T, Mask, (OldUsingDirectives NewUsingDirectives) -Set getUsingNamespaces(BlockUsingDirectives NewUsingDirectives OldUsingDirectives, N)))
          ...</k>
          <using-namespaces> BlockUsingDirectives::Set </using-namespaces>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nusing-namespaces> NewUsingDirectives::Set </nusing-namespaces>

     syntax Set ::= getUsingNamespaces(Set, Namespace) [function]

     rule getUsingNamespaces(SetItem(Using::Namespace) S::Set, N::Namespace) => SetItem(Using) getUsingNamespaces(S, N)
          requires enclosesNamespace(N, Using)

     rule getUsingNamespaces(.Set, _) => .Set

     rule getUsingNamespaces(SetItem(_) S::Set, N::Namespace) => getUsingNamespaces(S, N) [owise]

     // unqualified name lookup
     rule <k> lookupNameInBlock(X::CId, NoTag(), Mask::Set) => lookupEnumerator(X, E, Mask, .K) ...</k>
          <enums>... X |-> E::Enum ...</enums>
          requires variable in Mask

     rule <k> lookupNameInBlock(X::CId, NoTag(), Mask::Set) => cSet(S, NoNamespace() :: X) ...</k>
          <tr-env>... X |-> S::Map ...</tr-env>
          requires envMask(X |-> S, X, Mask)

     rule <k> lookupNameInBlock(X::CId, _, Mask::Set) => T ...</k>
          <tr-types>... X |-> T::CPPType ...</tr-types>
          requires type in Mask

     rule <k> lookupNameInBlock(X::CId, _, Mask::Set) => notFound(X) ...</k>
          <tr-env> Env::Map </tr-env>
          <tr-types> Types::Map </tr-types>
          <enums> UE::Map </enums>
          requires (notBool X in_keys(Env) orBool notBool envMask(Env, X, Mask))
           andBool (notBool X in_keys(Types) orBool notBool type in Mask)
           andBool (notBool X in_keys(UE) orBool notBool variable in Mask)

     rule <k> lookupEnumerator(X::CId, E::Enum, Mask::Set, C:K) => #if C ==K .K #then V #else classSet(V, {C}:>Class :: X, SetItem({C}:>Class)) #fi ... </k>
          <curr-tr-scope> enumScope(E) </curr-tr-scope>
          <enum-id> E </enum-id>
          <enumerators>... X |-> V::PRVal </enumerators>
          requires variable in Mask

     rule <k> lookupEnumerator(X::CId, E::Enum, Mask::Set, C:K) => #if C ==K .K #then prv(V, Tr, ET) #else classSet(prv(V, Tr, ET), {C}:>Class :: X, SetItem({C}:>Class)) #fi ... </k>
          <curr-tr-scope> Sc::Scope </curr-tr-scope>
          <enum-id> E </enum-id>
          <enum-type> ET::CPPType </enum-type>
          <enumerators>... X |-> prv(V::CPPValue, Tr::Trace, _) </enumerators>
          requires Sc =/=K enumScope(E)
               andBool variable in Mask

     rule <k> lookupEnumerator(X::CId, E::Enum, Mask::Set, _) => notFound(X) ...</k>
          <enum-id> E </enum-id>
          <enumerators> Enumerators::Map </enumerators>
          requires notBool X in_keys(Enumerators) orBool notBool variable in Mask

     rule lookupMember(X::CId, C::Class, IsBody::Bool, T::Tag, Mask::Set)
          => resolveClassSet(#lookupMember(X, C, IsBody, T, Mask))

     syntax Expr ::= resolveClassSet(Expr) [strict]

     rule resolveClassSet(classSet(M:Map, X::QualId, _)) => cSet(M, X)

     rule resolveClassSet(classSet(T:CPPType, _, _)) => T

     rule resolveClassSet(classSet(V:PRVal, _, _)) => V

     rule resolveClassSet(notFound(X::CId)) => notFound(X)

     // lookup member in class (and base-classes)
     rule <k> #lookupMember(X::CId, C::Class, _, NoTag(), Mask::Set) => classSet(S, C :: X, SetItem(C)) ...</k>
          <class-id> C </class-id>
          <cenv>... X |-> S::Map ...</cenv>
          requires envMask(X |-> S, X, Mask)

     rule <k> #lookupMember(X::CId, C::Class, _, _, Mask::Set) => classSet(T, C :: X, SetItem(C)) ...</k>
          <class-id> C </class-id>
          <ctypes>... X |-> T::CPPType ...</ctypes>
          requires type in Mask

     rule <k> #lookupMember(X::CId, C::Class, _, NoTag(), Mask::Set) => lookupEnumerator(X, E, Mask, C) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenums>... X |-> E::Enum </cenums>
          requires variable in Mask

     rule <k> #lookupMember(X::CId, C::Class, IsBody:Bool, T::Tag, Mask::Set) => #if IsBody #then lookupMemberInBaseClasses(X, BaseClasses, T, Mask, notFound(X)) #else notFound(X) #fi ...</k>
          <class-id> C </class-id>
          <base-classes> BaseClasses::List </base-classes>
          <cenv> Env::Map </cenv>
          <ctypes> Types::Map </ctypes>
          <cenums> UE::Map </cenums>
          requires (notBool X in_keys(Env) orBool notBool envMask(Env, X, Mask))
           andBool (notBool X in_keys(Types) orBool notBool type in Mask)
           andBool (notBool X in_keys(UE) orBool notBool variable in Mask)

     rule lookupMemberInBaseClasses(X::CId, (ListItem(B::Class) => .List) _, T::Tag, Mask::Set, E::Expr => mergeClassSet(E, #lookupMember(X, B, true, T, Mask)))

     rule lookupMemberInBaseClasses(... baseClasses: .List, result: E::Expr) => E

     syntax Expr ::= mergeClassSet(Expr, Expr) [strict]

     syntax KItem ::= "ambiguous"

     rule mergeClassSet(E::Expr, notFound(_)) => E

     rule mergeClassSet(notFound(_), E::Expr) => E

     rule mergeClassSet(classSet(_, _, C1::Set) #as C2::CandidateSet, classSet(_, _, B::Set)) => C2
          requires isIgnoredClassSet(B, C1)

     rule mergeClassSet(classSet(_, _, C::Set), classSet(_, _, B1::Set) #as B2::CandidateSet) => B2
          requires isIgnoredClassSet(C, B1)

     rule mergeClassSet(classSet(C1:CPPType, X::QualId, C2::Set), classSet(B1:CPPType, X::QualId, B2::Set))
          => classSet(C1, X, B2 C2)
          requires C1 ==Type B1
               andBool notBool isIgnoredClassSet(C2, B2)
               andBool notBool isIgnoredClassSet(B2, C2)

     rule mergeClassSet(classSet(C1:Map, X::QualId, C2::Set), classSet(B1:Map, X::QualId, B2::Set))
          => classSet(C1, X, B2 C2)
          requires keys(C1) ==K keys(B1)
               andBool notBool isIgnoredClassSet(C2, B2)
               andBool notBool isIgnoredClassSet(B2, C2)

     rule mergeClassSet(classSet(_, C1::QualId, C2::Set), classSet(_, _::QualId, B2::Set))
          => classSet(ambiguous, C1, C2 B2) [owise]

     syntax Bool ::= isIgnoredClassSet(Set, Set) [function]
                   | #isIgnoredClassSet(Class, Set) [function]

     rule isIgnoredClassSet(.Set, _) => true

     rule isIgnoredClassSet((SetItem(C::Class) => .Set) _, S::Set)
          requires #isIgnoredClassSet(C, S)

     rule isIgnoredClassSet(...) => false [owise]

     rule #isIgnoredClassSet(_, .Set) => false

     rule #isIgnoredClassSet(B::Class, SetItem(D::Class) _) => true
          requires isDirectBaseClassOf(B, D)

     rule #isIgnoredClassSet(_, (SetItem(_) => .Set) _) [owise]

     // lookup in inner classes
     rule lookupOuterMember(X::CId, C::Class, IsBody::Bool, Tag::Tag, Mask::Set) => lookupMember(X, C, IsBody, Tag, Mask)
          orIfNotFound guardedFind(X, isInnerClass(C),     lookupOuterMember(X, getOuterClass(C), IsBody, Tag, Mask))

     // 3.4.1:8
     rule lookupNameInFullClass(X::CId, C::Class, IsBody::Bool, BlockScope::Bool, Tag::Tag, Mask::Set)
       => guardedFind(X, BlockScope,                        lookupNameInBlock(X, Tag, Mask))                            // @ref n4296 3.4.1:8.1
          orIfNotFound                                      lookupMember(X, C, IsBody, Tag, Mask)                             // @ref n4296 3.4.1:8.2
          orIfNotFound guardedFind(X, isInnerClass(C),      lookupOuterMember(X, getOuterClass(C), IsBody, Tag, Mask))          // @ref n4296 3.4.1:8.3
          orIfNotFound guardedFind(X, isLocalInnerClass(C), lookupLocalBeforeClass(X, C, Tag, Mask))                    // @ref n4296 3.4.1:8.4
          orIfNotFound                                      nameLookupInFullNamespace(X, getClassNamespace(C), Tag, Mask, .Set)   // @ref n4296 3.4.1:8.5

     rule (.K => argDependentNameLookup(X, Args)) ~> CallExpr(Name(NoNNS(), X::CId), Args::StrictList, krlist(.List))

     rule <k> CallExpr((ExprLoc(L::CabsLoc, E:Expr) => E), _Args::StrictList, krlist(.List)) ...</k>
          <curr-tr-program-loc> _ => L </curr-tr-program-loc>

     context CallExpr(Name(HOLE:NNS, _), _, _)
             requires HOLE =/=K NoNNS()
             [result(NNSVal)]

     rule (.K => qualifiedNameLookup(X, N, defaultMask)) ~> CallExpr(Name(N:NNSVal, X::CId), _, krlist(.List))

     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> CallExpr((lv(_, _, t(... st: classType(C::Class))) #Or xv(_, _, t(... st: classType(C::Class))) #Or prv(_, _, t(... st: classType(C::Class))))  . no-template Name(NoNNS(), X::CId), _, krlist(.List))

     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> CallExpr((le(_, _, t(... st: classType(C::Class))) #Or xe(_, _, t(... st: classType(C::Class))) #Or pre(_, _, t(... st: classType(C::Class)))) . no-template Name(NoNNS(), X::CId), _, krlist(.List))

     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> CallExpr(_:Val . no-template Name(C:NNSVal, X::CId), _, _)

     rule cSet(Y::Map, X::QualId) ~> CallExpr(E::Expr, Args::StrictList, krlist(.List))
          => resolveOverload(cSet(Y, X), Args, E)
          ~> stripResolveOverloadResult()

     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> (lv(_, _, t(... st: classType(C::Class))) #Or xv(_, _, t(... st: classType(C::Class))) #Or prv(_, _, t(... st: classType(C::Class)))) . no-template Name(NoNNS(), X::CId)

     rule (.K => qualifiedNameLookup(X, C, defaultMask)) ~> (le(_, _, t(... st: classType(C::Class))) #Or xe(_, _, t(... st: classType(C::Class))) #Or pre(_, _, t(... st: classType(C::Class)))) . no-template Name(NoNNS(), X::CId)

     rule (cSet(_, C:Class :: _) => .K) ~> _ . no-template Name(NoNNS() => C, _)

     syntax Bool ::= isQualifiedName(Expr) [function]

     rule isQualifiedName(Name(N::NNS, _)) => true
          requires N =/=K NoNNS()

     rule isQualifiedName(_) => false [owise]

     rule qualifiedNameLookup(X::CId, N:Namespace, Mask::Set) => nameLookupInNamespaceScope(X, N, NoTag(), Mask)

     rule qualifiedNameLookup(X::CId, C:Class, Mask::Set) => lookupMember(X, C, true, NoTag(), Mask)

     rule qualifiedNameLookup(X::CId, E:Enum, Mask::Set) => lookupEnumerator(X::CId, E, Mask, .K)

     rule Name(N::NNS, X::CId)
       => resolveUniqueDecl(#if N ==K NoNNS()
                            #then nameLookup(X, NoTag(), defaultMask)
                            #else qualifiedNameLookup(X, N, defaultMask)
                            #fi, ExecName(N, X), false)

     rule & Name(N::NNS, X::CId)
       => & resolveUniqueDecl(#if N ==K NoNNS()
                              #then nameLookup(X, NoTag(), defaultMask)
                              #else qualifiedNameLookup(X, N, defaultMask)
                              #fi, ExecName(N, X), N =/=K NoNNS())

     context & HOLE:Expr
             requires notBool isName(HOLE) andBool notBool isExprLoc(HOLE)

     rule <k> & (ExprLoc(L::CabsLoc, E:Expr) => E) ...</k>
          <curr-tr-program-loc> _ => L </curr-tr-program-loc>

     rule ElaboratedTypeSpecifier(T::Tag, X::CId, NoNNS()) => resolveElabSpecifier(T, nameLookup(X, T, typeMask))
     requires T =/=K NoTag()

     rule ElaboratedTypeSpecifier(T::Tag, X::CId, N::NNS) => qualifiedNameLookup(X, N, typeMask)
     requires T =/=K NoTag() andBool N =/=K NoNNS()

     rule ElaboratedTypeSpecifier(T::Tag, X::CId, NoNNS(), Args::List)
          => resolveElabSpecifier(nameLookup(X, T, typeMask), list(Args))
     requires T =/=K NoTag()

     context qualifiedNameLookup(_, (HOLE:NNS), _) [result(NNSVal)]

     rule <k> NoNNS() => N ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>

     rule <k> NoNNS() => NoNamespace() ...</k>
          <curr-tr-scope> _:BlockScope </curr-tr-scope>

     rule NNS(X:CId) => extractNNS(nameLookup(X, NoTag(), nnsMask))

     rule NNS(Name(N::NNS, X::CId)) => extractNNS(qualifiedNameLookup(X, N, nnsMask))
          requires N =/=K NoNNS()

     rule NNS(Name(NoNNS(), X::CId)) => NNS(X)

     rule N::NNS :: NNS(X:CId) => NNS(Name(N, X)) [anywhere]

     rule NNS(Name(NoNNS(), X:CId)) => NNS(X) [anywhere]

     syntax KItem ::= extractNNS(KItem) [strict]

     rule extractNNS(nsRef(N::Namespace)) => N

     rule extractNNS(t(_, _, classType(C::Class))) => C

     rule extractNNS(t(_, _, scopedEnum(E::Enum, _))) => E

     rule extractNNS(t(_, _, unscopedEnum(E::Enum, _, _))) => E

     syntax Expr ::= argDependentNameLookup(CId, StrictList)
                   | argDependentNameLookup(CId, StrictList, StrictList, Expr) [strict(4)]
                   | #argDependentNameLookup(CId, StrictList, List, Set, CandidateSet)

     syntax AType ::= resolveElabSpecifier(Tag, KItem) [strict(2)]
                    | resolveElabSpecifier(KItem, StrictList) [strict(1, 2), klabel(resolveElabSpecifier2)]
                    | specializeTypeTemplate(QualId, CPPType, List)

     rule <k> nameLookup(X::CId, Tag::Tag, Mask::Set) => nameLookupInScope(X, Tag, Mask, Scope) ...</k>
          <curr-tr-scope> Scope::Scope </curr-tr-scope>

     rule nameLookupInScope(X::CId, Tag::Tag, Mask::Set, Scope::Scope) => lookupNameInFullClass(X, classFromScope(Scope), isInBody(Scope), isBlockScope(Scope), Tag, Mask)
          requires inClassScope(Scope)

     syntax Bool ::= isInBody(Scope) [function]

     rule isInBody(blockScope(...)) => true

     rule isInBody(classScope(_, IsBody::Bool)) => IsBody

     rule nameLookupInScope(X::CId, Tag::Tag, Mask::Set, enumScope(E::Enum)) => nameLookupInEnumScope(X, Tag, Mask, enumScope(E))

     // 3.4.1: 6
     rule nameLookupInScope(X::CId, Tag::Tag, Mask::Set, Scope::Scope) => lookupNameInBlock(X, Tag, Mask)
                                 orIfNotFound nameLookupInFullNamespace(X, getInnermostNamespace(Scope), Tag, Mask, .Set)
          requires notBool inClassScope(Scope) andBool notBool isEnumScope(Scope)

     rule <k> nameLookupInEnumScope(X::CId, _, _, enumScope(E::Enum)) => V ... </k>
          <enum-id> E </enum-id>
          <enumerators>... X |-> V::PRVal ...</enumerators>

     rule <k> nameLookupInEnumScope(X::CId, Tag::Tag, Mask::Set, enumScope(E::Enum)) => nameLookupInScope(X, Tag, Mask, getRestOfScope(enumScope(E))) ... </k>
          <enum-id> E </enum-id>
          <enumerators> Enumerators::Map </enumerators>
          requires notBool X in_keys(Enumerators) orBool notBool variable in Mask


     // arg dependent name lookup
     rule argDependentNameLookup(X::CId, Args::StrictList) => argDependentNameLookup(X, Args, Args, nameLookup(X, NoTag(), defaultMask))

     context argDependentNameLookup(_, _, (HOLE:StrictList => types(HOLE)), _)

     rule <k> (.K => isDependentName(X, Args, Types)) ~> argDependentNameLookup(X::CId, list(Args::List), krlist(Types::List), _:CandidateSet) ...</k>
          <curr-template-context> templateInfo(...) </curr-template-context>

     rule <k> (.K => false) ~> argDependentNameLookup(_::CId, list(_Args::List), krlist(_Types::List), _:CandidateSet) ...</k>
          <curr-template-context> noTemplate </curr-template-context>

     // TODO(dwightguth): class member stuff
     syntax KItem ::= isDependentName(CId, List, List)

     rule isDependentName(_, ListItem(PackExpansionExpr(_)) _, _) => true

     rule true ~> isDependentName(_, _, _) => true

     rule (false => .K) ~> isDependentName(_, _, _)

     rule isDependentName(_, .List, .List) => false

     rule <k> false ~> argDependentNameLookup(X::CId, _Args::StrictList, _Types::StrictList, cSet(Y::Map, QX::QualId)) => cSet(Y, QX) ...</k>
           <tr-env> Env::Map </tr-env>
           requires hasSpecialDeclInArgLookup(X, Y, Env)

     syntax Bool ::= hasSpecialDeclInArgLookup(CId, Map, Map) [function]

     // 3.4.2:3.2
     rule hasSpecialDeclInArgLookup(X::CId, _, _::Map (X |-> ((_::CPPType |-> (T::CPPType, envEntry(... using: false))) _::Map))) => true
          requires isCPPFunctionType(T)

     rule hasSpecialDeclInArgLookup(_, _::CPPType |-> (T::CPPType, _), _) => true
          requires notBool isCPPFunctionType(T)

     rule hasSpecialDeclInArgLookup(_, _, _) => false [owise]

     // associated namespaces
     rule <k> (.K => getFunctionAddressTypes(Args))
              ~> false ~> argDependentNameLookup(X::CId, list(Args::List), krlist(_Types::List), cSet(... candidates: Y::Map)) ...</k>
          <tr-env> Env::Map </tr-env>
          requires notBool hasSpecialDeclInArgLookup(X, Y, Env)

     rule <k> (.K => getFunctionAddressTypes(Args))
              ~> false ~> argDependentNameLookup(_::CId, list(Args::List), krlist(_Types::List), notFound(_)) ...</k>

     // if the argument is the name or address of a set of overloaded functions
     // and/or function templates, its associated classes and namespaces are
     // the union of those associated with each of the members of the set,
     // i.e., the classes and namespaces associated with its parameter types
     // and return type
     syntax KItem ::= getFunctionAddressTypes(List)

     rule (.K => nameLookup(X, NoTag(), defaultMask)) ~> getFunctionAddressTypes((ListItem(Name(NoNNS(), X::CId)) => .List) _)

     syntax Predicate ::= "isCPPFunctionType"
     rule isCPPFunctionType::Predicate(T:CPPType) => isCPPFunctionType(T)
     rule (cSet(... candidates: M::Map) => .K) ~> getFunctionAddressTypes(_) ~> false ~> argDependentNameLookup(_, _, krlist(_::List (.List => filterList(keys_list(M), isCPPFunctionType))), _)

     rule getFunctionAddressTypes((ListItem(N::Init) => .List) _)
          requires notBool isName(N) andBool notBool isAddressOfName(N)

     syntax Bool ::= isAddressOfName(Init) [function]

     rule isAddressOfName(& _:Name) => true

     rule isAddressOfName(UnaryOperator(operator&, _:Name)) => true

     rule isAddressOfName(_) => false [owise]

     rule <k> getFunctionAddressTypes(.List) ~> false ~> argDependentNameLookup(X::CId, Args::StrictList, krlist(Types::List), Y:CandidateSet) => #argDependentNameLookup(X, Args, Types, getAssociatedNamespaces(Types, <namespaces> B </namespaces>), Y) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <namespaces> B::Bag </namespaces>

     syntax Set ::= getAssociatedNamespaces(List, NamespacesCell) [function]
                   | #getAssociatedNamespaces(Set, NamespacesCell) [function]

     syntax List ::= getAssociatedClasses(List) [function]
                   | #getAssociatedClasses(Class, ClassInfo) [function]
                   | getTemplateArgTypes(TemplateArgs) [function]

     // @ref n4296 3.4.2:2.1
     rule getAssociatedNamespaces((ListItem(cppFundamentalType #as T::CPPType) => .List) _, _)

     rule getAssociatedNamespaces((ListItem(t(_, _, no-type)) => .List) _, _)

     // @ref n4296 3.4.2:2.2
     rule getAssociatedNamespaces(ListItem(t(... st: classType((_ :: Class(_, _, Args::TemplateArgs)) #as C::Class))) L::List, B::NamespacesCell)
          => getAssociatedNamespaces(getTemplateArgTypes(Args) L, B) #getAssociatedNamespaces(List2Set(getInnermostNamespaces(getAssociatedClasses(ListItem(C)))), B)

     // @ref n4296 3.4.2:2.3
     rule getAssociatedNamespaces(ListItem(t(_, _, scopedEnum(N::Namespace :: _, _))) L::List, B::NamespacesCell)
          => getAssociatedNamespaces(L, B) #getAssociatedNamespaces(SetItem(N), B)

     rule getAssociatedNamespaces(ListItem(t(_, _, unscopedEnum(N::Namespace :: _, _, _))) L::List, B::NamespacesCell)
          => getAssociatedNamespaces(L, B) #getAssociatedNamespaces(SetItem(N), B)

     // @ref n4296 3.4.2:2.4
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

     rule getAssociatedClasses(.List) => .List
     rule getAssociatedClasses(ListItem(C::Class) L::List) => #getAssociatedClasses(C, getClassInfo(C)) getAssociatedClasses(L)

     rule #getAssociatedClasses(N:Namespace :: C::ClassSpecifier, #incomplete) => ListItem(classScope(N :: C, true))

     rule #getAssociatedClasses(N:Namespace :: C::ClassSpecifier, <class>... <base-classes> Bases::List </base-classes> ...</class>) => ListItem(classScope(N :: C, true)) getAssociatedClasses(Bases)

     rule getTemplateArgTypes(t(Q::Quals, Mods::Set, T::CPPSimpleType), Ps::TemplateArgs) => ListItem(t(Q, Mods, T)) getTemplateArgTypes(Ps)

     rule getTemplateArgTypes(.TemplateArgs) => .List

     rule #argDependentNameLookup(_::CId, _Args::StrictList, _Types::List, .Set, Y:CandidateSet) => Y

     rule (.K => qualifiedNameLookup(X, N, SetItem(function))) ~> #argDependentNameLookup(X::CId, _, _, (SetItem(N::Namespace) => .Set) _, _)

     rule (M:CandidateSet => .K) ~> #argDependentNameLookup(_, _, _, _, Y:CandidateSet => cSetUnion2(M, Y))

     // elaborated type specifiers
     rule resolveElabSpecifier(_, T:CPPType) => T

     rule resolveElabSpecifier(T:ClassKey, notFound(X::CId)) => declareClassName(T, X, false)

     rule resolveElabSpecifier(templateRef(Q::QualId, T::CPPType), krlist(Args::List))
          => specializeTypeTemplate(Q, T, Args)

     rule <k> specializeTypeTemplate(_::QualId, t(Q::Quals, Mods::Set, classType(N::Namespace :: Class(Tag::Tag, C::CId, .TemplateArgs))), Args::List)
               => t(Q, Mods, classType(N :: Class(Tag, C, toTemplateArgs(Args))))
          ...</k>

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

     rule filterNonMemberLookupSet(cSet(M::Map, Q::QualId), T::CPPType)
          => #if isCPPClassType(T) #then cSet(stripMemberFunctions(M), Q) #else cSet(stripEnum1(stripMemberFunctions(M), T), Q) #fi

     rule filterNonMemberLookupSet(cSet(M::Map, Q::QualId), T1::CPPType, T2::CPPType)
          => #if isCPPClassType(T1) orBool isCPPClassType(T2) #then cSet(stripMemberFunctions(M), Q) #else cSet(stripEnum1(stripEnum2(stripMemberFunctions(M), T2), T1), Q) #fi

     syntax Map ::= stripMemberFunctions(Map) [function]

     rule stripMemberFunctions(M::Map _::CPPType |-> (T::CPPType, _)) => stripMemberFunctions(M)
          requires isCPPFunctionType(T) andBool isFunctionMember(T)

     rule stripMemberFunctions(.Map) => .Map

     rule stripMemberFunctions(M::Map _::CPPType |-> (T::CPPType, K:KItem)) => stripType(T) |-> (T, K) stripMemberFunctions(M) [owise]

     syntax Map ::= stripEnum1(Map, CPPType) [function]
                  | stripEnum2(Map, CPPType) [function]

     syntax Bool ::= stripEnum(Int, List, CPPType) [function]

     rule stripEnum1(M::Map _::CPPType |-> (T::CPPType, K:KItem), cppEnumType #as T1::CPPType)
          => #if stripEnum(0, getParams(T), T1) #then .Map #else stripType(T) |-> (T, K) #fi stripEnum1(M, T1)
          requires isCPPFunctionType(T)

     rule stripEnum2(M::Map _::CPPType |-> (T::CPPType, K:KItem), cppEnumType #as T2::CPPType)
          => #if stripEnum(1, getParams(T), T2) #then .Map #else stripType(T) |-> (T, K) #fi stripEnum1(M, T2)
          requires isCPPFunctionType(T)

     rule stripEnum(I::Int, L::List, T::CPPType)
          => size(L) <=Int I orBool ({L[I]}:>CPPType =/=Type T andBool notBool (isCPPRefType({L[I]}:>CPPType) andBool utype(innerType({L[I]}:>CPPType)) ==Type T))

     rule stripEnum1(.Map, _) => .Map

     rule stripEnum2(.Map, _) => .Map

     rule stripEnum1(M::Map _::CPPType |-> (T::CPPType, K:KItem), T1::CPPType) => stripType(T) |-> (T, K) stripEnum1(M, T1) [owise]

     rule stripEnum2(M::Map _::CPPType |-> (T::CPPType, K:KItem), T2::CPPType) => stripType(T) |-> (T, K) stripEnum2(M, T2) [owise]

     rule addBuiltinCandidates(operator,, E1::Expr, _, _, E2::Expr, _, _, C1:CandidateSet, C2:CandidateSet)
          => resolveEmptyOverload(cSetUnion2(C1, C2), list(ListItem(E1) ListItem(E2)), Comma(E1, E2), BinaryOperator(operator,, E1, E2))

     rule addBuiltinCandidates(operator&, E1::Expr, _, _, C1:CandidateSet, C2:CandidateSet)
          => resolveEmptyOverload(cSetUnion2(C1, C2), list(ListItem(E1)), & E1, UnaryOperator(operator&, E1))

     rule addBuiltinCandidates(operator->, E1::Expr, _, _, E2::Name, _, _, C1:CandidateSet, C2:CandidateSet)
          => resolveEmptyOverloadArrow(cSetUnion2(C1, C2), list(ListItem(E1)), E1 -> no-template E2, BinaryOperator(operator->, E1, E2), E2)

     syntax Expr ::= resolveEmptyOverload(CandidateSet, StrictList, Expr, Expr)
                   | resolveEmptyOverloadArrow(CandidateSet, StrictList, Expr, Expr, Name)
                   | #resolveEmptyOverload(Expr, K)

     rule resolveEmptyOverload(C::CandidateSet, Args::StrictList, Builtin::Expr, E::Expr)
          => resolveOverload(C, Args, E) ~> #resolveEmptyOverload(Builtin, .K)

     rule resolveEmptyOverloadArrow(C::CandidateSet, Args::StrictList, Builtin::Expr, E::Expr, N::Name)
          => resolveOverload(C, Args, E) ~> #resolveEmptyOverload(Builtin, N)


     rule resolveOverloadResult(E:ResolvedExpr)
          ~> #resolveEmptyOverload(_, .K)
          => resolveOverloadResult(E)
          requires notBool isNotFoundNameRef(E)

     rule resolveOverloadResult(E:ResolvedExpr)
          ~> #resolveEmptyOverload(_, N:Name)
          => resolveOverloadResult(BinaryOperator(operator->, E, N))
          requires notBool isNotFoundNameRef(E)

     // no viable candidates
     rule notFound(_)
          ~> #resolveEmptyOverload(E::Expr, _)
          => resolveOverloadResult(E)

     rule addBuiltinCandidates(O::OpId, E1::Expr, T1::CPPType, _, E2::Expr, T2::CPPType, _, C1:CandidateSet, C2:CandidateSet)
          => resolveOverload(cSetUnion2(C1, cSetUnion2(C2, builtinCandidates(O, T1, T2, C2, builtinOperator(O, E1, E2)))), list(ListItem(E1) ListItem(E2)), BinaryOperator(O, E1, E2))
          requires O =/=K operator, andBool O =/=K operator->

     rule addBuiltinCandidates(O::OpId, E1::Expr, T1::CPPType, _, C1:CandidateSet, C2:CandidateSet)
          => resolveOverload(cSetUnion2(C1, cSetUnion2(C2, builtinCandidates(O, T1, C2, builtinOperator(O, E1)))), list(ListItem(E1)), UnaryOperator(O, E1))
          requires O =/=K operator&

     syntax CandidateSet ::= builtinCandidates(OpId, CPPType, CPPType, CandidateSet, Expr) [function, klabel(builtinCandidates2)]
                           | #builtinCandidates(OpId, CPPType, CPPType, Expr) [function, klabel(#builtinCandidates2)]
                           | builtinCandidates(OpId, CPPType, CandidateSet, Expr) [function]
                           | #builtinCandidates(OpId, CPPType, Expr) [function]
                           | filterBuiltinCandidates(CandidateSet, CandidateSet) [function]

     rule builtinCandidates(O::OpId, T1::CPPType, T2::CPPType, NonMemberCandidates::CandidateSet, E::Expr)
          => filterBuiltinCandidates(#builtinCandidates(O, T1, T2, E), NonMemberCandidates)

     rule filterBuiltinCandidates(C:CandidateSet, notFound(_)) => C

     rule #builtinCandidates(O::OpId, T1::CPPType, T2::CPPType, E::Expr)
          => cSetUnion2(pairwiseReturning(type(bool), promotedArithmeticTypes, E, O), cSetUnion2(identicalReturning(type(bool), enumTypesFrom(T1) enumTypesFrom(T2), E, O), identicalReturning(type(bool), pointerTypesFrom(T1) pointerTypesFrom(T2), E, O)))
          requires O ==K operator< orBool O ==K operator<= orBool O ==K operator> orBool O ==K operator>=

     syntax CandidateSet ::= pairwiseReturning(CPPType, Set, Expr, OpId) [function]
                           | identicalReturning(CPPType, Set, Expr, OpId) [function]
                           | makeSet(Map, OpId) [function]

     syntax Set ::= enumTypesFrom(CPPType) [function]
                  | pointerTypesFrom(CPPType) [function]
                  | "promotedArithmeticTypes" [function]
                  | "promotedIntegralTypes" [function]

     syntax Map ::= #identicalReturning(CPPType, Set, Expr) [function]
                  | #pairwiseReturning(CPPType, Set, Set, Expr) [function]
                  | #pairwiseReturning2(CPPType, CPPType, Set, Expr) [function]

     rule enumTypesFrom(cppEnumType #as T::CPPType) => SetItem(utype(T))

     rule enumTypesFrom(T::CPPType) => .Set
          requires notBool isCPPClassType(T) [owise]

     rule pointerTypesFrom(T::CPPType) => .Set
          requires notBool isCPPIntegerType(T)
               andBool notBool isCPPNullPtrTType(T)
               andBool notBool isCPPPointerType(T)
               andBool notBool isCPPClassType(T)

     rule promotedArithmeticTypes =>
          SetItem(type(float))
          SetItem(type(double))
          SetItem(type(long-double))
          promotedIntegralTypes

     rule promotedIntegralTypes =>
          SetItem(type(int))
          SetItem(type(unsigned))
          SetItem(type(long))
          SetItem(type(unsigned-long))
          SetItem(type(long-long))
          SetItem(type(oversized))
          SetItem(type(unsigned-long-long))
          SetItem(type(unsigned-oversized))

     rule makeSet(M::Map, O::OpId) => cSet(M, NoNamespace() :: O)

     rule identicalReturning(Ret::CPPType, S::Set, E::Expr, O::OpId)
          => makeSet(#identicalReturning(Ret, S, E), O)

     rule #identicalReturning(Ret::CPPType, SetItem(T::CPPType) S::Set, E::Expr)
          => #fun(F::CPPType => stripType(F) |-> (F, builtinOp(E)))(func(Ret, T, T)) #identicalReturning(Ret, S, E)

     rule #identicalReturning(...) => .Map [owise]

     rule pairwiseReturning(Ret::CPPType, S::Set, E::Expr, O::OpId)
          => makeSet(#pairwiseReturning(Ret, S, S, E), O)

     // technically this will create some duplicates but because the values are the same
     // they should merge together cleanly
     rule #pairwiseReturning(Ret::CPPType, SetItem(L::CPPType) S::Set, R::Set, E::Expr)
          => #pairwiseReturning2(Ret, L, R, E) #pairwiseReturning(Ret, S, R, E)

     rule #pairwiseReturning(...) => .Map [owise]

     rule #pairwiseReturning2(Ret::CPPType, L::CPPType, SetItem(R::CPPType) S::Set, E::Expr)
          => #fun(F::CPPType => stripType(F) |-> (F, builtinOp(E)))(func(Ret, L, R)) #pairwiseReturning2(Ret, L, S, E)

     rule #pairwiseReturning2(...) => .Map [owise]

endmodule
