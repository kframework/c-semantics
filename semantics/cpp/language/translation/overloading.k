module CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     imports CPP-TRANSLATION-TYPING-EXPR-SORTS
     imports CPP-TRANSLATION-VALUE-CATEGORY-SORTS

     syntax ValResult ::= CandidateSet

     syntax CandidateSet ::= cSet(candidates: Map, id: QualId)

     // evaluates to `resolveOverloadResult(_)` or `notFound(_)`
     syntax Expr ::= resolveOverload(CandidateSet, StrictList, Expr)
                   | resolveConversionOverload(CandidateSet, StrictList, Expr, CPPType)
                   | resolveRefConversionOverload(CandidateSet, StrictList, Expr, CPPType)
                   | checkAccess(Expr)

     syntax Expr ::= resolveUniqueDecl(KItem, Expr, Bool) [strict(1)]
                   | cSetUnion(KItem, KItem) [strict]

     // not a real expression, but getArgs understands it.
     syntax Expr ::= "constructor"

     syntax CandidateSet ::= cSetUnion2(CandidateSet, CandidateSet) [function]

     syntax BuiltinOp ::= builtinOp(Expr)

     syntax KItem ::= canBeImplicitlyConvertedTo(fromType: CPPType, fromCat: ValueCategory, toType: CPPType)

     syntax KItem ::= resolveOverloadResult(KItem)
                    | stripResolveOverloadResult()
endmodule

module CPP-TRANSLATION-OVERLOADING
     imports CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports C-CONFIGURATION
     imports COLLECTIONS
     imports INT
     imports K-EQUAL
     imports STRING
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-TRANSLATION-DECL-TEMPLATE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-ENV-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-ODR-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX
     imports ERROR-SYNTAX

     rule resolveOverloadResult(X)
          ~> stripResolveOverloadResult()
          => X

     // access checking stub (not implemented yet)
     rule checkAccess(E::Expr) => resolveOverloadResult(E)

     syntax Expr ::= resolveOverloadWithType(CandidateSet, StrictList, Expr, OverloadType)

     rule resolveOverload(C::CandidateSet, L::StrictList, E::Expr)
          => resolveOverloadWithType(C, L, E, NotConversionOverload())

     rule resolveConversionOverload(C::CandidateSet, L::StrictList, E::Expr, T::CPPType)
          => resolveOverloadWithType(C, L, E, ConversionOverload(T))

     rule resolveRefConversionOverload(C::CandidateSet, L::StrictList, E::Expr, T::CPPType)
          => resolveOverloadWithType(C, L, E, RefConversionOverload(T))

     syntax OverloadType ::= NotConversionOverload()
                           | ConversionOverload(CPPType)
                           | RefConversionOverloadType

     syntax RefConversionOverloadType ::= RefConversionOverload(CPPType)

     rule resolveOverloadWithType(notFound(X::CId), _, _, _) => notFound(X)

     rule <k> resolveOverloadWithType(cSet(... id: Q::QualId) #as C::CandidateSet, list(Args::List), E::Expr, O::OverloadType)
              => #resolveOverload(C,
                   list(getArgs(Args, Q, E, Obj)),
                   list(getArgs(Args, Q, E, Obj)),
                   list(getArgs(Args, Q, E, Obj)),
                   E, O)
          ...</k>
          <tr-this> Obj:K </tr-this>

     syntax Expr ::= #resolveOverload(cands: CandidateSet, args: StrictList, types: StrictList, cats: StrictList, trace: Expr, ot: OverloadType)
                   | #resolveOverload2(cands: CandidateSet, args: StrictList, types: StrictList, cats: StrictList, trace: Expr, ot: OverloadType)


     syntax List ::= getArgs(List, QualId, Expr, K) [function]

     // @ref n4296 13.3.1.1.1:2
     rule getArgs(Args::List, C:Class :: _, Obj::Expr . no-template _, _)
          => ListItem(Obj) Args

     // @ref n4296 13.3.1.1.1:3 case (1)
     rule getArgs(Args::List, N:Namespace :: _, _, _) => Args

     // @ref n4296 13.3.1.1.1:3 case (2) when this is in scope
     rule getArgs(Args::List, C:Class :: _, _:Name, Obj:PRVal)
          => ListItem(* Obj) Args
          requires isBaseClassOf(type(classType(C)), innerType(type(Obj)))

     // @ref n4296 13.3.1.1.1:3 case (2) when this is not in scope
     rule getArgs(Args::List, C:Class :: _, _:Name, Obj::PRVal)
          => ListItem(contrivedObject(type(classType(C)))) Args
          requires Obj ==K .K orBool notBool isBaseClassOf(type(classType(C)), innerType(type(Obj)))

     // @ref n4296 13.3.1.2:6
     rule getArgs(Args::List, _, UnaryOperator(...), _) => Args

     rule getArgs(Args::List, _, BinaryOperator(...), _) => Args

     // @ref n4296 13.3.1.3:1
     rule getArgs(Args::List, _, constructor, _) => Args

     // strict version
     rule cSetUnion(notFound(_), E::KItem) => E

     rule cSetUnion(E::KItem, notFound(_)) => E

     rule cSetUnion(cSet(M1::Map, QX::QualId), cSet(M2::Map, QX)) => cSet(M1 M2, QX)

     // function version
     rule cSetUnion2(notFound(_), E::CandidateSet) => E

     rule cSetUnion2(E::CandidateSet, notFound(_)) => E

     rule cSetUnion2(cSet(M1::Map, QX::QualId), cSet(M2::Map, QX)) => cSet(M1 M2, QX)

     context #resolveOverload(... types: (HOLE:StrictList => types(HOLE)))

     context #resolveOverload(... cats: (HOLE:StrictList => cats(HOLE)))

     syntax KItem ::= filterViableCandidates(Map, List, List, List)
                    | filterViableCandidatesResult(Map)
                    | filterViableCandidates1(src: Map, filtered: Map, List, List, List)
                    | filterViableCandidates2(currType: CPPType, currEntry: KItem, src: Map, filtered: Map, List, List, List)

     rule (.K => filterViableCandidates(CS, Args, Types, Cats))
          ~>
          #resolveOverload(cSet(... candidates: CS::Map), list(Args::List), krlist(Types::List), krlist(Cats::List), _, _)


     rule (filterViableCandidatesResult(Filtered::Map)
          ~>
          #resolveOverload(cSet(_, Id::QualId), Args::StrictList,
                    Types::StrictList, Cats::StrictList, Trace::Expr, OT::OverloadType)
          ) => #resolveOverload2(cSet(Filtered, Id), Args, Types, Cats, Trace, OT)

     rule filterViableCandidates(M::Map, Args::List, Types::List, Cats::List)
          =>
          filterViableCandidates1(M, .Map, Args, Types, Cats)

     rule filterViableCandidates1(.Map, Filtered::Map, _, _, _)
          =>
          filterViableCandidatesResult(Filtered)

     rule filterViableCandidates1(_::CPPType |-> (T::CPPType, CurEntry::KItem) Src::Map, Filtered::Map, Args::List, Types::List, Cats::List)
          => keepThisCandidate(T, CurEntry, Args, Types, Cats)
          ~> filterViableCandidates2(T, CurEntry, Src, Filtered, Args, Types, Cats)

     rule (Keep:Bool ~>
           filterViableCandidates2(T::CPPType, K::KItem, Src::Map, Filtered::Map, Args::List, Types::List, Cats::List))
          =>
          filterViableCandidates1(Src, #if Keep #then stripType(T) |-> (T, K) #else .Map #fi Filtered, Args, Types, Cats)

     syntax KItem ::= keepThisCandidate(CPPType, KItem, List, List, List)
                    | keepThisCandidate1(CPPType, KItem, List, List, List)
                    | keepThisCandidate2(CPPType, KItem, List, List, List)

     rule keepThisCandidate(T::CPPType, K::KItem, Args::List, Types::List, Cats::List)
          =>
          #if notBool isCPPFunctionType(T) //e.g. a function pointer
          #then
               true
          #else
               keepThisCandidate1(T, K, Args, Types, Cats)
          #fi

     rule keepThisCandidate1(T::CPPType, K::KItem, Args::List, Types::List, Cats::List)
          =>
          #if notBool acceptsNArgs(size(Args), T, getDefaultArgsVals(getDA(T, K)))
          #then
               false
          #else
               keepThisCandidate2(T, K, Args, Types, Cats)
          #fi

     rule (.K => notViableTypes(T, Types, getDefaultArgsTypes(getDA(T, K)), Cats, getDefaultArgsCats(getDA(T, K))))
          ~> keepThisCandidate2(T::CPPType, K::KItem, _, Types::List, Cats::List)

     rule (B:Bool ~> keepThisCandidate2(...)) => notBool B

     syntax DefaultArgumentsResult ::= getDA(CPPType, KItem) [function]
     rule getDA(_, envEntry(... defaultArgs: DA::DefaultArgumentsResult)) => DA
     rule getDA(T::CPPType, _) => emptyDefaultArguments(T) [owise]
     
     syntax KItem ::= #notViableTypes(params: List, types: List, daTypes:List, cats: List, daCats: List, isNonStaticRefNone: Bool)
                   | notViableTypes(CPPType, List, List, List, List)

     rule notViableTypes(T::CPPType, Types::List, DATypes::List, Cats::List, DACats::List)
          => #notViableTypes(getParams(T), Types, DATypes, Cats, DACats, isFunctionMember(T) andBool notBool isMethodStatic(T) andBool getRefQualifier(T) ==K RefNone())

     rule (.K => viableType(P, A, C))
          ~> #notViableTypes((ListItem(P:CPPType) => .List) _, (ListItem(A::CPPType) => .List) _, (ListItem(_) => .List) _, (ListItem(C::ValueCategory) => .List) _, (ListItem(_) => .List) _, _)

    rule (.K => viableImplicitObjectParameter(P, A, C, B))
          ~> #notViableTypes((ListItem(implicitObjectParameter(P:CPPType)) => .List) _, (ListItem(A::CPPType) => .List) _, _, (ListItem(C::ValueCategory) => .List) _, _, B::Bool)

     rule (false ~> #notViableTypes(...)) => true
     rule (true => .K) ~> #notViableTypes(...)


     rule #notViableTypes(... params: ListItem(variadic)) => false

     rule #notViableTypes(... params: .List, types: .List, cats: .List) => false

     // default arguments
     rule #notViableTypes(ListItem(P:CPPType) _, .List => ListItem(A) DAs, ListItem(A::CPPType) DAs::List, .List => DCs, DCs::List, _)

     rule canBeImplicitlyConvertedTo(...
               fromType: FromType::CPPType,
               fromCat:  FromCat::ValueCategory,
               toType:   ToType::CPPType
          ) => viableType(FromType, ToType, FromCat)

     syntax KItem ::= viableType(CPPType, CPPType, ValueCategory)
                    | viableImplicitObjectParameter(CPPType, CPPType, ValueCategory, isNonStaticRefNone: Bool)

     rule viableType(P::CPPType, A::CPPType, C::ValueCategory)
          =>
          computeConversionSequence(P, A, C, false, false, true)
          ~> canConvert()

     rule viableImplicitObjectParameter(cppRefType #as P::CPPType, A::CPPType, C::ValueCategory, B::Bool)
          =>
          computeConversionSequence(P, A, C, B, true, true)
          ~> canConvert()

     syntax KItem ::= canConvert()

     rule (CS:ConversionSequence ~> canConvert())
          => CS =/=K cannot-convert

     rule viableImplicitObjectParameter(t(... st: no-type), _, _, _) => true

     rule canConvertWithStandardConversion(P::CPPType, A::CPPType, C::ValueCategory) => computeSCS(P, A, C, false) =/=K cannot-convert

     // Result: ConversionSequence
     syntax KItem ::= computeConversionSequence(CPPType, CPPDType, ValueCategory, isNonStaticRefNone: Bool, isImplicit: Bool, canUserDefinedConvert: Bool)

     syntax KResult ::= ConversionSequence

     syntax ConversionSequence ::= CannotConvert
                                 | "ellipsisConversionSequence"
                                 | computeSCS(CPPType, CPPType, ValueCategory, isOverload: Bool) [function]
                                 | computeSCS2(Conversion, CPPType, CPPType, isOverload: Bool) [function]
                                 | computeSCS3(Conversion, Conversion, CPPType, CPPType) [function]
                                 | standardConversionSequence(Conversion, typeConv: Conversion, Conversion, isNonStaticRefNone: Bool, param: CPPType)
                                 | userDefinedConversionSequence(ConversionSequence, QualId, CPPType, ConversionSequence)
                                 | "ambiguousConversionSequence"
                                 | listInitSequence(CPPType, ConversionSequence)
                                 | "bottomConversionSequence"

     // @ref n4296 13.3.3.1.4:1 (identity conversion)
     rule computeConversionSequence(cppRefType #as P::CPPType, A:CPPType, C::ValueCategory, B::Bool, _, _)
          => standardConversionSequence(identity, identity, identity, B, P)
          requires bindsDirectlyToExp(P, A, C, B)
               andBool notBool (isCPPClassType(innerType(P)) andBool isCPPClassType(A)
                    andBool isProperBaseClassOf(innerType(P), A))

     rule computeConversionSequence(cppRefType #as P::CPPType, t(... st: classType(...)) #as A::CPPType, C::ValueCategory, B::Bool, _, _)
          => standardConversionSequence(identity, derivedToBaseConversion(P, A), identity, B, P)
          requires bindsDirectlyToExp(P, A, C, B) andBool isCPPClassType(innerType(P))
               andBool isProperBaseClassOf(innerType(P), A)

     rule computeConversionSequence(cppRefType #as P::CPPType, A:CPPType, C::ValueCategory, false, false, CanUDC::Bool)
          => computeConversionSequence(innerType(P), A, C, false, false, CanUDC)
          requires notBool bindsDirectlyToExp(P, A, C, false)
               andBool notBool bindsDirectlyToConversion(P, A, C)
               andBool isValidReferenceType(P)

     rule computeConversionSequence(cppRefType #as P::CPPType, A:CPPType, C::ValueCategory, false, false, _)
          => cannot-convert
          requires notBool bindsDirectlyToExp(P, A, C, false)
               andBool notBool bindsDirectlyToConversion(P, A, C)
               andBool notBool isValidReferenceType(P)

     // @ref n4296 13.3.1:5.1-5.2
     rule computeConversionSequence(cppRefType #as P::CPPType, A:CPPType, C::ValueCategory, B::Bool, true, _)
          => cannot-convert
          requires notBool bindsDirectlyToExp(P, A, C, B)

     rule computeConversionSequence(P::CPPType, initListType(ListItem(A::CPPType)), initListCat(ListItem(C::ValueCategory)), false, false, CanUDC::Bool)
          => computeListInitSequence(P, computeConversionSequence(P, A, C, false, false, CanUDC))
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P) andBool notBool isCPPArrayType(P)

     syntax KItem ::= computeListInitSequence(CPPType, KItem) [strict(2)]

     rule computeListInitSequence(P::CPPType, CS:ConversionSequence)
          => listInitSequence(P, CS)

     syntax KItem ::= computeUserDefinedConversionSequence(KItem, QualId, CPPType, KItem) [strict(1,4)]

     rule computeUserDefinedConversionSequence(CS1:ConversionSequence, Q::QualId, T::CPPType, CS2:ConversionSequence)
          => userDefinedConversionSequence(CS1, Q, T, CS2)

     rule computeConversionSequence(P::CPPType, initListType(.List), _, false, false, _)
          => listInitSequence(P, standardConversionSequence(identity, identity, identity, false, P))
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P) andBool notBool isCPPArrayType(P)

     rule computeConversionSequence(P::CPPType, initListType(L::List), _, false, false, _)
          => cannot-convert
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P) andBool notBool isCPPArrayType(P)
               andBool size(L) >Int 1

     syntax Bool ::= bindsDirectlyToExp(CPPType, CPPType, ValueCategory, isNonStaticRefNone: Bool) [function]
                   | bindsDirectlyToConversion(CPPType, CPPType, ValueCategory) [function]

     rule bindsDirectlyToExp(t(... st: lvRefType(T1::CPPType)), T2::CPPType, lvalue, _) => true
          requires isReferenceCompatible(T1, T2)

     rule bindsDirectlyToExp(T::CPPType, T2::CPPType, xvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)

     rule bindsDirectlyToExp(T::CPPType, t(... st: classType(...)) #as T2::CPPType, prvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)

     rule bindsDirectlyToExp(T::CPPType, t(... st: _:CPPSimpleArrayType) #as T2::CPPType, prvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)

     rule bindsDirectlyToExp(T::CPPType, t(... st: functionType(...)) #as T2::CPPType, lvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)

     rule bindsDirectlyToExp(t(... st: lvRefType(t(... q: Q::Quals => Q +Qual Const()))), _, _:RValueCategory, true => false)

     rule bindsDirectlyToExp(t(... st: rvRefType(t(... q: Q::Quals => Q +Qual Const()))), _, _:RValueCategory, true => false)

     rule bindsDirectlyToExp(...) => false [owise]

     rule bindsDirectlyToConversion(T::CPPType, T2::CPPType, C::ValueCategory) => false
          requires notBool (isCPPClassType(T2) andBool notBool isReferenceRelated(innerType(T), T2))
               orBool bindsDirectlyToExp(T, T2, C, false)

     rule computeConversionSequence(P::CPPType, A:CPPType, C::ValueCategory, false, false, CanUDC::Bool) => adjustParamType(computeSCS(utype(P), utype(A), C, CanUDC), P)
          requires notBool isCPPRefType(P)
               andBool ((notBool isCPPClassType(P) andBool notBool isCPPClassType(A))
                    orBool utype(A) ==Type utype(P)
                    orBool (isCPPClassType(A) andBool isCPPClassType(P) andBool isBaseClassOf(P, A)))

     rule computeConversionSequence(P::CPPType, A:CPPType, C::ValueCategory, false, false, CanUDC:Bool) => #if CanUDC #then computeUDC(utype(P), utype(A), C) #else cannot-convert #fi [owise]


     syntax KItem ::= computeUDC(CPPType, CPPType, ValueCategory)
                    | #computeUDC(KItem, KItem) [strict(1,2)]

     rule computeUDC(t(... st: classType(P::Class)), A::CPPType, C::ValueCategory)
          => computeUDCTo(P, getClassInfo(P), A, C)
          requires notBool isCPPClassType(A)

     rule computeUDC(P::CPPType, t(... st: classType(A::Class)), C::ValueCategory)
          => computeUDCFrom(P, A, getClassInfo(A), C)
          requires notBool isCPPClassType(P)

     rule computeUDC(t(... st: classType(P::Class)), t(... st: classType(A::Class)), C::ValueCategory)
          =>
          #computeUDC(
               computeUDCFrom(type(classType(P)), A, getClassInfo(A), C),
               computeUDCTo(P, getClassInfo(P), type(classType(A)), C)
          )

     rule #computeUDC(CS1:ConversionSequence, CS2:ConversionSequence)
          =>
          resolveUDC(ListItem(CS1) ListItem(CS1))


     syntax KItem ::= computeUDCTo(Class, ClassInfo, CPPType, ValueCategory)
                    | #computeUDCTo(Class, List, CPPType, ValueCategory, List)

     rule computeUDCTo(_ :: Class(_, X::CId, _) #as P::Class, <class>... <cenv>... ConstructorId(X) |-> M::Map ...</cenv> ...</class>, A::CPPType, C::ValueCategory)
          => #computeUDCTo(P, singleParamFunctions(keys_list(stripExplicit(M))), A, C, .List)

     syntax List ::= singleParamFunctions(List) [function]

     rule singleParamFunctions(ListItem(t(... st: ST::CPPSimpleFunctionType) #as FuncT::CPPType) L::List)
          => #if paramCount(ST) ==Int 1 #then ListItem(FuncT) #else .List #fi
             singleParamFunctions(L)

     rule singleParamFunctions(.List) => .List

     rule (.K => computeUserDefinedConversionSequence(
               computeConversionSequence(Param, A, C, false, false, false),
               P :: ConstructorId(X),
               FuncT,
               computeConversionSequence(type(classType(P)), type(classType(P)), unnamedCat(Ret), false, false, false)
            )
          ) ~>
          #computeUDCTo(
               _ :: Class(_, X::CId, _) #as P::Class,
               (ListItem(t(... st: functionType(... returnType: Ret::CPPType, paramTypes: Param::CPPType)) #as FuncT::CPPType) => .List) L::List,
               A::CPPType,
               C::ValueCategory,
               _
          )

     rule (UDC:ConversionSequence => .K)
          ~> #computeUDCTo(_, _, _, _, (.List => ListItem(UDC)) _)

     rule #computeUDCTo(_, .List, _, _, Result::List)
     => resolveUDC(Result)

     syntax KItem ::= computeUDCFrom(CPPType, Class, ClassInfo, ValueCategory)
                    | #computeUDCFrom(CPPType, List, Class, ValueCategory, List)

     rule computeUDCFrom(P::CPPType, A::Class, <class>... <conversion-functions> L::List </conversion-functions> ...</class>, C::ValueCategory)
          => #computeUDCFrom(P, L, A, C, .List)

     rule (.K => computeUserDefinedConversionSequence(
               computeConversionSequence(implicitObjectParameterType(FuncT), type(classType(A)), C, getRefQualifier(FuncT) ==K RefNone(), true, false),
               A :: ConversionId(Ret),
               FuncT,
               computeConversionSequence(P, Ret, unnamedCat(Ret), false, false, false)
            )
          )
          ~>
          #computeUDCFrom(
               P::CPPType,
               (ListItem(t(... st: functionType(... returnType: Ret::CPPType)) #as FuncT::CPPType) => .List) L::List,
               A::Class,
               C::ValueCategory,
               _
          )

     rule (UDC:ConversionSequence => .K)
          ~> #computeUDCFrom(_, _, _, _, (.List => ListItem(UDC)) _)

     rule #computeUDCFrom(_, .List, _, _, Result::List) => resolveUDC(Result)

     // result: ConversionSequence
     syntax KItem ::= resolveUDC(KItem)
                    | resolveUDCHold()
                    | #resolveUDC(List, List)

     rule resolveUDC(K::KItem)
          => K ~> resolveUDCHold()

     rule L:List ~> resolveUDCHold()
          => #resolveUDC(L, .List)

     rule #resolveUDC((ListItem(cannot-convert) => .List) _, _)

     rule #resolveUDC((ListItem(userDefinedConversionSequence(cannot-convert, _, _, _)) => .List) _, _)

     rule #resolveUDC((ListItem(userDefinedConversionSequence(_, _, _, cannot-convert)) => .List) _, _)

     rule #resolveUDC((ListItem(C::ConversionSequence) => .List) _, (.List => ListItem(C)) _) [owise]

     rule #resolveUDC(.List, .List) => cannot-convert

     rule #resolveUDC(.List, ListItem(C::ConversionSequence)) => C

     rule #resolveUDC(.List, ListItem(_) ListItem(_) _) => ambiguousConversionSequence

     rule computeSCS(P::CPPType, A::CPPType, _:GLValueCategory, B::Bool) => computeSCS2(lvalueConversion, P, prvalType(A), B)
          requires notBool isCPPFunctionType(A) andBool notBool isCPPArrayType(A)

     rule computeSCS(P::CPPType, A::CPPType, _:GLValueCategory, B::Bool) => computeSCS2(arrayConversion, P, type(pointerType(innerType(A))), B)
          requires isCPPArrayType(A)

     rule computeSCS(P::CPPType, A::CPPType, _:LValueCategory, B::Bool) => computeSCS2(functionConversion, P, type(pointerType(A)), B)
          requires isCPPFunctionType(A)

     rule computeSCS(P::CPPType, A::CPPType, prvalue, B::Bool) => computeSCS2(identity, P, A, B)
          requires notBool isCPPArrayType(A)

     rule computeSCS(...) => cannot-convert [owise]

     rule computeSCS2(C::Conversion, cppIntegerType #as P::CPPType, cppIntegerType #as A::CPPType, _) => computeSCS3(C, integralPromotion(P, A), P, A)
          requires utype(P) =/=Type utype(A) andBool (promote(A) ==Type P orBool promote(promote(A)) ==Type P)

     rule computeSCS2(C::Conversion, cppIntegerType #as P::CPPType, t(... st: _:CPPSimpleUnscopedEnumType) #as A::CPPType, _) => computeSCS3(C, integralPromotion(P, A), P, A)
          requires utype(P) =/=Type utype(A) andBool (promote(A) ==Type P orBool promote(promote(A)) ==Type P)

     rule computeSCS2(C::Conversion, t(... st: double) #as P::CPPType, t(... st: float), _) => computeSCS3(C, floatingPromotion, P, P)

     rule computeSCS2(C::Conversion, cppIntegerType #as P::CPPType, cppIntegerType #as A::CPPType, _) => computeSCS3(C, integralConversion, P, P)
          requires utype(P) =/=Type utype(A) andBool promote(A) =/=Type P andBool promote(promote(A)) =/=Type P andBool notBool isCPPBoolType(P)

     rule computeSCS2(C::Conversion, cppIntegerType #as P::CPPType, t(... st: _:CPPSimpleUnscopedEnumType) #as A::CPPType, _) => computeSCS3(C, integralConversion, P, P)
          requires utype(P) =/=Type utype(A) andBool promote(A) =/=Type P andBool promote(promote(A)) =/=Type P andBool notBool isCPPBoolType(P)

     rule computeSCS2(C::Conversion, t(... st: _:CPPSimpleFloatingType) #as P::CPPType, t(... st: _:CPPSimpleFloatingType) #as A::CPPType, _) => computeSCS3(C, floatingConversion, P, P)
          requires notBool (simpleType(P) ==K double andBool simpleType(P) ==K float)

     rule computeSCS2(C::Conversion, cppIntegerType #as P::CPPType, t(... st: _:CPPSimpleFloatingType) #as A::CPPType, _) => computeSCS3(C, floatingIntegralConversion, P, P)

     rule computeSCS2(C::Conversion, t(... st: _:CPPSimpleFloatingType) #as P::CPPType, cppIntegerType #as A::CPPType, _) => computeSCS3(C, floatingIntegralConversion, P, P)

     rule computeSCS2(C::Conversion, t(... st: _:CPPSimpleFloatingType) #as P::CPPType, t(... st: _:CPPSimpleUnscopedEnumType) #as A::CPPType, _) => computeSCS3(C, floatingIntegralConversion, P, P)

     rule computeSCS2(C::Conversion, t(... st: pointerType(...)) #as P::CPPType, cppIntegerType #as A::CPPType, _) => computeSCS3(C, pointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, t(... st: pointerType(...)) #as P::CPPType, t(... st: nullptr_t) #as A::CPPType, _) => computeSCS3(C, pointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, t(... st: nullptr_t) #as P::CPPType, cppIntegerType #as A::CPPType, _) => computeSCS3(C, pointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, t(... st: pointerType(t(... st: void))) #as P::CPPType, t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, _))) #as A::CPPType, _)
          => computeSCS3(C, pointerConversion(P, A), P, t(Q, Mods, pointerType(t(Q', Mods', void))))
          requires notBool isSimilar(utype(P), utype(A))

     rule computeSCS2(C::Conversion, t(... st: pointerType(t(... st: T:CPPSimpleClassType) #as B::CPPType)) #as P::CPPType, t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, classType(...)) #as D::CPPType)) #as A::CPPType, _)
          => computeSCS3(C, pointerConversion(P, A), P, t(Q, Mods, pointerType(t(Q', Mods', T))))
          requires B =/=K D andBool isBaseClassOf(B, D)

     rule computeSCS2(C::Conversion, t(... st: memberPointerType(...)) #as P::CPPType, cppIntegerType #as A::CPPType, _) => computeSCS3(C, memberPointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, t(... st: memberPointerType(...)) #as P::CPPType, t(... st: nullptr_t) #as A::CPPType, _) => computeSCS3(C, memberPointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, t(... st: memberPointerType(t(... st: classType(...)) #as D::CPPType, t(... st: T::CPPSimpleType))) #as P::CPPType, t(Q::Quals, Mods::Set, memberPointerType(t(... st: classType(...)) #as B::CPPType, t(Q'::Quals, Mods'::Set, T))) #as A::CPPType, _)
          => computeSCS3(C, memberPointerConversion(P, A), P, t(Q, Mods, memberPointerType(D, t(Q', Mods', T))))
          requires B =/=K D andBool isBaseClassOf(B, D)

     rule computeSCS2(C::Conversion, t(... st: _:CPPSimpleBoolType) #as P::CPPType, cppIntegerType #as A::CPPType, _) => computeSCS3(C, booleanConversion(A), P, P)
          requires utype(P) =/=Type utype(A)

     rule computeSCS2(C::Conversion, t(... st: _:CPPSimpleBoolType) #as P::CPPType, t(... st: _:CPPSimpleUnscopedEnumType) #as A::CPPType, _) => computeSCS3(C, booleanConversion(A), P, P)

     rule computeSCS2(C::Conversion, t(... st: _:CPPSimpleBoolType) #as P::CPPType, t(... st: pointerType(...)) #as A::CPPType, _) => computeSCS3(C, booleanConversion(A), P, P)

     rule computeSCS2(C::Conversion, t(... st: _:CPPSimpleBoolType) #as P::CPPType, t(... st: memberPointerType(...)) #as A::CPPType, _) => computeSCS3(C, booleanConversion(A), P, P)

     rule computeSCS2(C::Conversion, P::CPPType, A::CPPType, _)
          => computeSCS3(C, identity, P, A)
          requires isSimilar(utype(P), utype(A))

     rule computeSCS2(C::Conversion, t(... st: classType(...)) #as P::CPPType, t(... st: classType(...)) #as A::CPPType, true)
          => computeSCS3(C, derivedToBaseConversion(P, A), P, A)
          requires utype(P) =/=Type utype(A) andBool isBaseClassOf(P, A)

     rule computeSCS2(...) => cannot-convert [owise]

     rule computeSCS3(C1::Conversion, C2::Conversion, P::CPPType, A::CPPType)
          => standardConversionSequence(C1, C2, identity, false, P)
          requires cvQualificationSignature(P) ==K cvQualificationSignature(A)

     rule computeSCS3(C1::Conversion, C2::Conversion, P::CPPType, A::CPPType)
          => standardConversionSequence(C1, C2, qualificationConversion, false, P)
          requires cvQualificationSignature(P) =/=K cvQualificationSignature(A) andBool cvQualificationSignature(A) <=QualSig cvQualificationSignature(P)

     rule computeSCS3(_, _, _, _) => cannot-convert [owise]

     syntax ConversionSequence ::= adjustParamType(ConversionSequence, CPPType) [function]

     rule adjustParamType(standardConversionSequence(...) #as S1::ConversionSequence, P::CPPType) => #fun(standardConversionSequence(... param: _ => P))(S1)

     rule adjustParamType(cannot-convert, _) => cannot-convert

     syntax Conversion ::= "identity"
                         | "lvalueConversion"
                         | "arrayConversion"
                         | "functionConversion"
                         | "qualificationConversion"
                         | integralPromotion(CPPType, CPPType)
                         | "floatingPromotion"
                         | "integralConversion"
                         | "floatingConversion"
                         | "floatingIntegralConversion"
                         | pointerConversion(CPPType, CPPType)
                         | memberPointerConversion(CPPType, CPPType)
                         | booleanConversion(CPPType)
                         | derivedToBaseConversion(CPPType, CPPType)

     // we need to add the odr-use to the external-uses cell if it is a use of an object or function
     // with C linkage, because we may need to be able to detect that the native entity associated with
     // this declaration needs to be linked in.
     syntax Map ::= addOdrUse(Map, CId, CabsLoc) [function]

     rule addOdrUse(EU::Map, Identifier(_) #as X::CId, L::CabsLoc) => EU[X <- L]

     rule addOdrUse(EU::Map, _, _) => EU [owise]

     syntax CId ::= fetchMangled(Set) [function]

     rule fetchMangled(SetItem(odrDecl(_, _, Mangled::CId, _, _)) _::Set) => Mangled

     rule fetchMangled(_) => #NoName [owise]

     syntax KItem ::= updateExternalUses(SymBase)

     rule <k> updateExternalUses(Base::SymBase) => .K ...</k>
          <odr-decls> Decls::Map </odr-decls>
          <external-uses> EU::Map => addOdrUse(EU, fetchMangled({Decls[Base]}:>Set), L) </external-uses>
          <curr-tr-program-loc> L::CabsLoc </curr-tr-program-loc>

     // do not actually perform overload resolution, this was a function call
     // in which the postfix expression was a function pointer
     rule #resolveOverload2(cSet(... candidates: _::CPPType |-> (T::CPPType, envEntry(... base: Base::SymBase)), id: X::QualId), list(Args::List), _, _, E::Expr, _)
          => Odr.newUse(Base)
          ~> updateExternalUses(Base)
          ~> checkAccess(CallExpr(lv(lnew(Base), hasTrace(E), T), list(Args), krlist(getDefaultArgsVals(emptyDefaultArguments(innerType(T))))))
          requires isCPPPointerType(T) andBool isCPPFunctionType(innerType(T)) andBool Base =/=K nonStatic

     rule #resolveOverload2(cSet(... candidates: _::CPPType |-> (T::CPPType, envEntry(... base: nonStatic))), list(Args::List), _, _, E::Expr, _)
          => checkAccess(CallExpr(le(E, hasTrace(E), T), list(Args), krlist(getDefaultArgsVals(emptyDefaultArguments(innerType(T))))))
          requires isCPPPointerType(T) andBool isCPPFunctionType(innerType(T))

     // only one viable candidate
     rule bestViable(T::CPPType, envEntry(... base: Base::SymBase, defaultArgs: defArgs(... vals: DArgs::StrictListResult)))
          ~> #resolveOverload2(cSet(... id: X::QualId), list(Args::List), _, _, E::Expr, _)
          => #if isMethodPure(T) andBool isVirtualCall(hasTrace(E), T) #then .K #else Odr.newUse(Base) #fi
          ~> updateExternalUses(Base)
          ~> checkAccess(CallExpr(lv(lnew(Base), hasTrace(E), T), list(Args), DArgs))

     rule bestViable(T::CPPType, builtinOp(E::Expr)) ~> #resolveOverload2(...)
          => resolveOverloadResult(E)

     rule (.K => computeBestViable(M, Types, Cats, O))
          ~> #resolveOverload2(cSet(... candidates: M::Map), list(Args::List), krlist(Types::List), krlist(Cats::List), _, O::OverloadType)
          requires allFunctionTypes(M)

     syntax Bool ::= allFunctionTypes(Map) [function]

     rule allFunctionTypes(.Map) => true

     rule allFunctionTypes((_::CPPType |-> (T::CPPType, _)) M::Map)
          => isCPPFunctionType(T) andBool allFunctionTypes(M)

     syntax KItem ::= computeBestViable(Map, List, List, OverloadType)
                    | #computeBestViable(CPPType, K, List, List, List, OverloadType, List)
                    | checkIsBest(CPPType, K, List, List, OverloadType, List)
                    | bestViable(CPPType, K)
                    | "noBestViable"

     rule computeBestViable(.Map, _, _, _) => noBestViable

     rule computeBestViable(_::CPPType |-> (T::CPPType, K:KItem) M::Map, Types::List, Cats::List, O::OverloadType)
          => #computeBestViable(T, K, Map2List(M), Types, Cats, O, .List)

     rule (.K => isBetterFunctionThan(T2, K2, T1, K1, Types, Cats, O))
          ~> #computeBestViable(
               T1::CPPType,
               K1:K,
               ListItem(kpair(T2::CPPType, K2:K)) _,
               Types::List,
               Cats::List,
               O::OverloadType,
               _
          )

     rule (false => .K)
          ~> #computeBestViable(
               _,
               _,
               (ListItem(kpair(T2::CPPType, K2:K)) => .List) _,
               _,
               _,
               _,
               (.List => ListItem(kpair(T2, K2))) _
          )

     rule (true => .K)
          ~> #computeBestViable(
               (T1::CPPType => T2),
               (K1:K => K2),
               (ListItem(kpair(T2::CPPType, K2:K)) => .List) _,
               _,
               _,
               _,
               (.List => ListItem(kpair(T1, K1))) _
          )

     rule #computeBestViable(T::CPPType, K:K, .List, Types::List, Cats::List, O::OverloadType, Others::List)
          => checkIsBest(T, K, Types, Cats, O, Others)

     rule (.K => isBetterFunctionThan(T1, K1, T2, K2, Types, Cats, O))
          ~> checkIsBest(
               T1::CPPType,
               K1:K,
               Types::List,
               Cats::List,
               O::OverloadType,
               ListItem(kpair(T2::CPPType, K2:K)) _
          )

     rule (true => .K)
          ~> checkIsBest(
               _,
               _,
               _,
               _,
               _,
               (ListItem(kpair(T2::CPPType, K2:K)) => .List) _
          )

     rule false ~> checkIsBest(...) => noBestViable [owise]

     rule checkIsBest(T::CPPType, K:K, _, _, _, .List)
          => bestViable(T, K)

     syntax KItem ::= isBetterFunctionThan(CPPType, K, CPPType, K, List, List, OverloadType)
                    | #isBetterFunctionThan(KItem, KItem, CPPType, K, CPPType, K, List, List, OverloadType) [strict(1,2)]

     rule isBetterFunctionThan(F1::CPPType, K1:K, F2::CPPType, K2:K, Types::List, Cats::List, NotConversionOverload())
          => #isBetterFunctionThan(
               hasWorseConversionSequenceThan(F1, F2, Types, Cats),
               hasBetterConversionSequenceThan(F1, F2, Types, Cats),
               F1, K1, F2, K2, Types, Cats, NotConversionOverload()
          )
          requires notBool (isTemplateSpecialization(K1) andBool isTemplateSpecialization(K2))

     // TODO(dwightguth): n4296 13.3.3:1.4,1.5,1.7
     rule #isBetterFunctionThan(
               HasWorseCS:Bool,
               HasBetterCS:Bool,
               F1::CPPType,
               K1:K,
               F2::CPPType,
               K2:K,
               Types::List,
               Cats::List,
               NotConversionOverload()
          )
          => notBool HasWorseCS andBool (HasBetterCS orBool (notBool isTemplateSpecialization(K1) andBool isTemplateSpecialization(K2)))

     syntax KItem ::= KItem "orB" KItem [strict(1)]
                    | KItem "andB" KItem [strict(1)]

     rule (true orB _) => true
     rule (false orB K::KItem) => K
     rule (false andB _) => false
     rule (true andB K::KItem) => K

     syntax KItem ::= hasWorseConversionSequenceThan(CPPType, CPPType, List, List)
                   | hasBetterConversionSequenceThan(CPPType, CPPType, List, List)
                   | #hasWorseCSThan(KItem, KItem) [strict]
                   | #hasBetterCSThan(KItem, KItem) [strict]
                   | #hasWorseCSThan2(List, List)
                   | #hasBetterCSThan2(List, List)

     rule hasWorseConversionSequenceThan(F1::CPPType, F2::CPPType, Types::List, Cats::List)
          => #hasWorseCSThan(getConversionSequences(F1, Types, Cats), getConversionSequences(F2, Types, Cats))

     rule hasBetterConversionSequenceThan(F1::CPPType, F2::CPPType, Types::List, Cats::List)
          => #hasBetterCSThan(getConversionSequences(F1, Types, Cats), getConversionSequences(F2, Types, Cats))

     rule #hasWorseCSThan(krlist(L1::List), krlist(L2::List))
          => #hasWorseCSThan2(L1, L2)

     rule #hasBetterCSThan(krlist(L1::List), krlist(L2::List))
          => #hasBetterCSThan2(L1, L2)

     rule #hasWorseCSThan2(ListItem(C1::ConversionSequence) L1::List, ListItem(C2::ConversionSequence) L2::List)
          => C2 >CS C1 orB #hasWorseCSThan2(L1, L2)
          requires C1 =/=K bottomConversionSequence andBool C2 =/=K bottomConversionSequence

     rule #hasBetterCSThan2(ListItem(C1::ConversionSequence) L1::List, ListItem(C2::ConversionSequence) L2::List)
          => C1 >CS C2 orB #hasBetterCSThan2(L1, L2)
          requires C1 =/=K bottomConversionSequence andBool C2 =/=K bottomConversionSequence

     rule #hasBetterCSThan2(ListItem(bottomConversionSequence) L1::List, ListItem(_) L2::List)
          => #hasBetterCSThan2(L1, L2)

     rule #hasWorseCSThan2(ListItem(bottomConversionSequence) L1::List, ListItem(_) L2::List)
          => #hasWorseCSThan2(L1, L2)

     rule #hasBetterCSThan2(ListItem(_) L1::List, ListItem(bottomConversionSequence) L2::List)
          => #hasBetterCSThan2(L1, L2)

     rule #hasWorseCSThan2(ListItem(_) L1::List, ListItem(bottomConversionSequence) L2::List)
          => #hasWorseCSThan2(L1, L2)

     rule #hasBetterCSThan2(.List, .List) => false

     rule #hasWorseCSThan2(.List, .List) => false

     syntax KItem ::= getConversionSequences(CPPType, List, List)
                   | #getConversionSequences(List, List, List, isNonStaticRefNone: Bool, isStatic: Bool, result: List)

     rule getConversionSequences(T::CPPType, Types::List, Cats::List)
          =>
          #getConversionSequences(
               getParams(T),
               Types,
               Cats,
               isFunctionMember(T) andBool notBool isMethodStatic(T) andBool getRefQualifier(T) ==K RefNone(),
               isMethodStatic(T),
               .List
          )

     rule (.K => computeConversionSequence(P, A, C, false, false, true))
          ~> #getConversionSequences(
               (ListItem(P:CPPType) => .List) _,
               (ListItem(A::CPPType) => .List) _,
               (ListItem(C::ValueCategory) => .List) _,
               B1::Bool,
               B2::Bool,
               _
          )

     rule (.K => computeConversionSequence(P, A, C, IsNonStaticRefNone, true, true))
          ~> #getConversionSequences(
               (ListItem(implicitObjectParameter(P:CPPType)) => .List) _,
               (ListItem(A::CPPType) => .List) _,
               (ListItem(C::ValueCategory) => .List) _,
               IsNonStaticRefNone::Bool,
               false,
               _
          )

     rule (CS:ConversionSequence => .K)
          ~> #getConversionSequences(... result: (.List => ListItem(CS)) _)

     rule #getConversionSequences(
               ListItem(implicitObjectParameter(_)) Ps::List,
               ListItem(_) As::List,
               ListItem(_) Cs::List,
               IsNonStaticRefNone::Bool,
               true,
               (.List => ListItem(bottomConversionSequence)) _
          )

     rule #getConversionSequences(
               ListItem(variadic),
               (ListItem(_) => .List) As::List,
               (ListItem(_) => .List) Cs::List,
               B1::Bool,
               B2::Bool,
               (.List => ListItem(ellipsisConversionSequence)) _
          )

     rule #getConversionSequences(_, .List, .List, _, _, Result::List) => krlist(Result)

     syntax Bool ::= ConversionSequence ">CS" ConversionSequence [function]
                   | Conversion ">Conv" Conversion [function]

     syntax Int ::= rank(ConversionSequence) [function, klabel(rankCS)]
                  | rank(Conversion) [function, klabel(rankConv)]
                  | form(ConversionSequence) [function]

     rule form(ellipsisConversionSequence) => 1

     rule form(userDefinedConversionSequence(...)) => 2

     rule form(ambiguousConversionSequence) => 2

     rule form(standardConversionSequence(...)) => 3

     rule form(listInitSequence(_, CS::ConversionSequence) => CS)

     rule rank(standardConversionSequence(C1::Conversion, C2::Conversion, C3::Conversion, _, _)) => minInt(rank(C1), minInt(rank(C2), rank(C3)))

     // exact match
     rule rank(identity) => 3

     rule rank(lvalueConversion) => 3

     rule rank(arrayConversion) => 3

     rule rank(functionConversion) => 3

     rule rank(qualificationConversion) => 3

     // promotion
     rule rank(integralPromotion(...)) => 2

     rule rank(floatingPromotion) => 2

     // conversion
     rule rank(integralConversion) => 1

     rule rank(floatingConversion) => 1

     rule rank(floatingIntegralConversion) => 1

     rule rank(pointerConversion(...)) => 1

     rule rank(memberPointerConversion(...)) => 1

     rule rank(booleanConversion(...)) => 1

     rule rank(derivedToBaseConversion(...)) => 1

     // @ref n4820 12.3.3.2:4.1
     rule booleanConversion(A1::CPPType) >Conv booleanConversion(A2::CPPType)
          => true
          requires notBool (isCPPPointerType(A1) orBool isCPPMemberPointerType(A1) orBool isCPPNullPtrTType(A1))
               andBool (isCPPPointerType(A2) orBool isCPPMemberPointerType(A2) orBool isCPPNullPtrTType(A2))

     rule integralPromotion(P1::CPPType, A1::CPPType) >Conv integralPromotion(P2::CPPType, A2::CPPType)
          => true
          requires promote(A1) ==Type P1 andBool promote(promote(A2)) ==Type P2
               andBool promote(A2) =/=Type promote(promote(A2))

     // @ref n4820 12.3.3.2:4.3a
     rule pointerConversion(t(... st: pointerType(t(... st: classType(...)) #as A::CPPType)), t(... st: pointerType(t(... st: classType(...)) #as B1::CPPType)))
          >Conv
          pointerConversion(t(... st: pointerType(t(... st: void))), t(... st: pointerType(B2::CPPType)))
          => true
          requires B1 ==Type B2 andBool A =/=Type B1 andBool isBaseClassOf(A, B1)

     // @ref n4820 12.3.3.2:4.3b
     rule pointerConversion(t(... st: pointerType(t(... st: void))), t(... st: pointerType(t(... st: classType(...)) #as A::CPPType)))
          >Conv
          pointerConversion(t(... st: pointerType(t(... st: void))), t(... st: pointerType(t(... st: classType(...)) #as B::CPPType)))
          => true
          requires A =/=Type B andBool isBaseClassOf(A, B)

     // @ref n4820 12.3.3.2:4.4.1
     rule pointerConversion(t(... st: pointerType(t(... st: classType(...)) #as B::CPPType)), t(... st: pointerType(t(... st: classType(...)) #as C1::CPPType)))
          >Conv
          pointerConversion(t(... st: pointerType(t(... st: classType(...)) #as A::CPPType)), t(... st: pointerType(C2::CPPType)))
          => true
          requires A =/=Type B andBool B =/=Type C1 andBool C1 ==Type C2 andBool isBaseClassOf(A, B) andBool isBaseClassOf(B, C1)

     // @ref n4820 12.3.3.2:4.4.3
     rule pointerConversion(t(... st: pointerType(t(... st: classType(...)) #as A1::CPPType)), t(... st: pointerType(t(... st: classType(...)) #as B::CPPType)))
          >Conv
          pointerConversion(t(... st: pointerType(A2::CPPType)), t(... st: pointerType(t(... st: classType(...)) #as C::CPPType)))
          => true
          requires A1 ==Type A2 andBool A1 =/=Type B andBool B =/=Type C andBool isBaseClassOf(A1, B) andBool isBaseClassOf(B, C)

     // @ref n4820 12.3.3.2:4.4.3
     rule memberPointerConversion(t(... st: memberPointerType(P1::CPPType, _)), t(... st: memberPointerType(A1::CPPType, _)))
          >Conv
          memberPointerConversion(t(... st: memberPointerType(P2::CPPType, _)), t(... st: memberPointerType(A2::CPPType, _)))
          =>
          pointerConversion(type(pointerType(A1)), type(pointerType(P1)))
          >Conv
          pointerConversion(type(pointerType(A2)), type(pointerType(P2)))

     // @ref n4820 12.3.3.2:4.4.4
     rule derivedToBaseConversion(P1::CPPType, A1::CPPType)
          >Conv
          derivedToBaseConversion(P2::CPPType, A2::CPPType)
          =>
          pointerConversion(type(pointerType(P1)), type(pointerType(A1)))
          >Conv
          pointerConversion(type(pointerType(P2)), type(pointerType(A2)))

     rule _ >Conv _ => false [owise]

     rule C1::ConversionSequence
          >CS
          C2::ConversionSequence
          => true
          requires form(C1) >Int form(C2)

     rule listInitSequence(T1::CPPType, _)
          >CS
          listInitSequence(T2::CPPType, _)
          => true
          requires isStdInitializerList(T1) andBool notBool isStdInitializerList(T2)

     rule listInitSequence(t(... st: arrayType(T::CPPType, N1::Int)), _)
          >CS
          listInitSequence(t(... st: arrayType(T::CPPType, N2::Int)), _)
          => true
          requires N1 <Int N2

     // list init sequences are treated as their underlying category unless one of the two cases above applies
     rule listInitSequence(_, C1::ConversionSequence)
          >CS
          C2::ConversionSequence
          => true
          requires C1 >CS C2

     rule C1::ConversionSequence
          >CS
          listInitSequence(_, C2::ConversionSequence)
          => true
          requires C1 >CS C2

     // identity is proper subsequence of any non-identity transformation
     rule standardConversionSequence(identity, identity, identity, _, _)
          >CS
          standardConversionSequence(C1::Conversion, C2::Conversion, C3::Conversion, _, _)
          => true
          requires C1 =/=K identity orBool C2 =/=K identity orBool C3 =/=K identity

     // any proper subsequence excluding the lvalue transformations
     rule standardConversionSequence(_, identity, identity, _, _)
          >CS
          standardConversionSequence(_, C2::Conversion, C3::Conversion, _, _)
          => true
          requires C2 =/=K identity orBool C3 =/=K identity

     rule standardConversionSequence(_, identity, C3::Conversion, _, _)
          >CS
          standardConversionSequence(_, C2::Conversion, C3::Conversion, _, _)
          => true
          requires C2 =/=K identity

     rule standardConversionSequence(_, C2::Conversion, identity, _, _)
          >CS
          standardConversionSequence(_, C2::Conversion, C3::Conversion, _, _)
          => true
          requires C3 =/=K identity

     rule (standardConversionSequence(... typeConv: C1::Conversion) #as S1::ConversionSequence)
          >CS
          (standardConversionSequence(... typeConv: C2::Conversion) #as S2::ConversionSequence)
          => true
          requires rank(S1) >Int rank(S2) orBool (rank(S1) ==Int rank(S2) andBool C1 >Conv C2)

     // @ref n4296 13.3.3.2:3.1.3 mentions binding an rvalue reference to an rvalue.
     // The only case when an rvalue reference can be bound (which we know
     // it can be if we've reached this point) but not bound to an rvalue
     // is if it is bound to an lvalue. But an rvalue reference can be
     // bound to an lvalue if and only if the rvalue reference is a
     // function reference. So we check the inner type of the reference
     // instead in order to avoid having to compute the value category
     // to which the reference is bound.
     rule standardConversionSequence(... isNonStaticRefNone: false, param: t(... st: rvRefType(...)) #as S1::CPPType)
          >CS
          standardConversionSequence(... isNonStaticRefNone: false, param: t(... st: lvRefType(...)) #as S2::CPPType)
          => true
          requires notBool isCPPFunctionType(innerType(S1))

     // @ref n4296 13.3.3.2:3.1.4 also mentions the value category the reference is bound
     // to, but like rvalue references, lvalue references can be bound to a
     // function if and only if the function is an lvalue. So again, we check
     // only the inner type of the reference.
     rule standardConversionSequence(... param: t(... st: lvRefType(...)) #as S1::CPPType)
          >CS
          standardConversionSequence(... param: t(... st: rvRefType(...)) #as S2::CPPType)
          => true
          requires isCPPFunctionType(innerType(S1))
               andBool isCPPFunctionType(innerType(S2))

     rule standardConversionSequence(C1::Conversion, C2::Conversion, qualificationConversion, _, T1::CPPType)
          >CS
          standardConversionSequence(C1, C2, qualificationConversion, _, T2::CPPType)
          => true
          requires isSimilar(T1, T2)
               andBool #fun(Q1::Quals => #fun(Q2::Quals => Q1 =/=K Q2 andBool Q1 <=Quals Q2)(getQuals(T2)))(getQuals(T1))

     rule standardConversionSequence(... param: cppRefType #as S1::CPPType)
          >CS
          standardConversionSequence(... param: cppRefType #as S2::CPPType)
          => true
          requires #fun(T1::CPPType => #fun(T2::CPPType => utype(T1) ==Type utype(T2)
               andBool #fun(Q1::Quals => #fun(Q2::Quals => Q1 =/=K Q2 andBool Q1 <=Quals Q2)
                    (getQuals(T2)))(getQuals(T1)))(innerType(S2)))(innerType(S1))

     rule userDefinedConversionSequence(_, X::QualId, T1::CPPType, U1::ConversionSequence)
          >CS
          userDefinedConversionSequence(_, X, T2::CPPType, U2::ConversionSequence)
          => true
          requires T1 ==Type T2 andBool U1 >CS U2

     rule _ >CS _ => false [owise]

     // no viable candidates
     // normally this is ill formed, but it can be well formed in some cases such as operator overloading of certain operators
     rule noBestViable ~> #resolveOverload2(... cands: cSet(... id: X::QualId)) => notFound(getId(X))

     rule #resolveOverload2(... cands: cSet(... candidates: (_::CPPType => stripType(adjustFunctionType(T))) |-> (T::CPPType => adjustFunctionType(T), _:TemplateInfo)))
          requires isCPPFunctionType(T) andBool notBool isAdjustedType(T)

     // TODO(traiansf): properly resolve default arguments for templates
     rule (lv(loc(Base::SymBase, 0), _, _) => .K)
          ~> bestViable(T::CPPType, (_ => envEntry(Base, false, emptyDefaultArguments(T))))

     rule resolveUniqueDecl(cSet(... candidates: _::CPPType |-> (T::CPPType, envEntry(... base: Base::SymBase)), id: X::QualId), E::Expr, _)
          => Odr.newUse(Base)
          ~> updateExternalUses(Base)
          ~> lv(lnew(Base), hasTrace(E), T)
          requires Base =/=K nonStatic
               andBool notBool isCPPRefType(T)
               andBool notBool isMemberBase(Base)

     rule resolveUniqueDecl(cSet(... candidates: _::CPPType |-> (T::CPPType, envEntry(... base: nonStatic))), E::Expr, _) => le(E, hasTrace(E), T)

     // resolve anonymous union member lookup
     rule resolveUniqueDecl(cSet(... candidates: _ |-> (_, envEntry(... base: memberBase(unnamedObject(C::Class), X::CId, _)))), _, _)
          => Name(NoNNS(), unnamedObject(C)) . no-template Name(NoNNS(), X)

     rule resolveUniqueDecl(cSet(_::CPPType |-> (T::CPPType, _:ClassOffset), C:Class :: X::CId), E::Expr, false) => le((*This()) . no-template Name(C, X), hasTrace(E), T)

     rule resolveUniqueDecl(cSet(_::CPPType |-> (T::CPPType, _:ClassOffset), C:Class :: X::CId), E::Expr, true)
          => dataMemberValue(memberPointer(C, X, T), hasTrace(E), T)

     rule resolveUniqueDecl(cSet(... candidates: _::CPPType |-> (T::CPPType, envEntry(... base: Base::SymBase))), E::Expr, _) =>
          #if Base =/=K nonStatic
          #then
               le(lv(lnew(Base), hasTrace(E), T), hasTrace(E), innerType(T))
          #else
               le(E, hasTrace(E), T)
          #fi
          requires isCPPRefType(T)

     rule resolveUniqueDecl(V:KItem, _, _) => V
          requires isKResult(V) andBool notBool isCandidateSet(V) andBool notBool isNotFoundNameRef(V)

     rule (.K => ILL("TOL1", "No declaration found for name '" +String showCId(X) +String "'.")) ~> resolveUniqueDecl(notFound(X::CId), _, _)

     // NOTE: the category of the contrivedObject is defaulted to lvalue as its value does not matter, as the
     // conversion sequence for the implicit object parameter will be ignored in this case.
     // See also 13.3.3.1.4:3 http://www.open-std.org/jtc1/sc22/wg21/docs/cwg_active.html#1278
     rule catof(contrivedObject(_) => lvalue)

     rule typeof(contrivedObject(T::CPPType) => T)

     rule contrivedObject(T::CPPType) => noObject()
          requires Translation()
endmodule
