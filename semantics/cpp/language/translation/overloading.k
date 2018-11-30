module CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPE-MAP-SORTS
     imports CPP-TYPING-SORTS
     imports CPP-TRANSLATION-TYPING-EXPR-SORTS
     imports CPP-TRANSLATION-VALUE-CATEGORY-SORTS

     syntax ValResult ::= CandidateSet

     syntax CandidateSet ::= cSet(candidates: TypeMap, id: QualId)

     syntax Expr ::= resolveOverload(CandidateSet, StrictList, Expr)
                   | resolveConversionOverload(CandidateSet, StrictList, Expr, CPPType)
                   | resolveRefConversionOverload(CandidateSet, StrictList, Expr, CPPType)
                   | resolveUniqueDecl(K, Expr, Bool) [strict(1)]
                   | cSetUnion(K, K) [strict]
                   | checkAccess(Expr)

     // not a real expression, but getArgs understands it.
     syntax Expr ::= "constructor"

     syntax CandidateSet ::= cSetUnion2(CandidateSet, CandidateSet) [function]

     syntax BuiltinOp ::= builtinOp(Expr)

     syntax Bool ::= canBeImplicitlyConvertedTo(fromType: CPPType, fromCat: ValueCategory, toType: CPPType) [function]
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
     imports CPP-TRANSLATION-TEMPLATE-DEDUCTION-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX
     imports ERROR-SYNTAX

     // access checking stub (not implemented yet)
     rule checkAccess(E::Expr) => E

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

     syntax List ::= getArgs(List, QualId, Expr, K) [function]

     // 13.3.1.1.1:2
     rule getArgs(Args::List, C:Class :: _, Obj::Expr . no-template _, _)
          => ListItem(Obj) Args

     // 13.3.1.1.1:3 case (1)
     rule getArgs(Args::List, N:Namespace :: _, _, _) => Args

     // 13.3.1.1.1:3 case (2) when this is in scope
     rule getArgs(Args::List, C:Class :: _, _:Name, Obj:PRVal)
          => ListItem(* Obj) Args
          requires isBaseClassOf(type(classType(C)), {innerType(type(Obj))}:>CPPClassType)

     // 13.3.1.1.1:3 case (2) when this is not in scope
     rule getArgs(Args::List, C:Class :: _, _:Name, Obj::PRVal)
          => ListItem(contrivedObject(type(classType(C)))) Args
          requires Obj ==K .K orBool notBool isBaseClassOf(type(classType(C)), {innerType(type(Obj))}:>CPPClassType)

     // 13.3.1.2:6
     rule getArgs(Args::List, _, UnaryOperator(...), _) => Args

     rule getArgs(Args::List, _, BinaryOperator(...), _) => Args

     // 13.3.1.3:1
     rule getArgs(Args::List, _, constructor, _) => Args

     // strict version
     rule cSetUnion(notFound(_), E::Expr) => E

     rule cSetUnion(E::Expr, notFound(_)) => E

     rule cSetUnion(cSet(M1::TypeMap, QX::QualId), cSet(M2::TypeMap, QX)) => cSet(M1 M2, QX)

     // function version
     rule cSetUnion2(notFound(_), E::CandidateSet) => E

     rule cSetUnion2(E::CandidateSet, notFound(_)) => E

     rule cSetUnion2(cSet(M1::TypeMap, QX::QualId), cSet(M2::TypeMap, QX)) => cSet(M1 M2, QX)

     context #resolveOverload(... types: (HOLE:StrictList => types(HOLE)))

     context #resolveOverload(... cats: (HOLE:StrictList => cats(HOLE)))

     rule #resolveOverload(cSet(... candidates: (T:CPPFunctionType |-> envEntry(... defaultArgs: DA::DefaultArgumentsResult) => .Map) _), list(Args::List), krlist(Types::List), krlist(Cats::List), _, _)
          requires notBool acceptsNArgs(size(Args), T, getDefaultArgsVals(DA))
            orBool notViableTypes(T, Types, getDefaultArgsTypes(DA), Cats, getDefaultArgsCats(DA))

     rule #resolveOverload(cSet(... candidates: (T:CPPFunctionType |-> builtinOp(_) => .Map) _), list(Args::List), krlist(Types::List), krlist(Cats::List), _, _)
          requires #fun(DA::DefaultArgumentsResult =>
               notBool acceptsNArgs(size(Args), T, getDefaultArgsVals(DA))
                 orBool notViableTypes(T, Types, getDefaultArgsTypes(DA), Cats, getDefaultArgsCats(DA)))
               (emptyDefaultArguments(T))

     syntax Bool ::= #notViableTypes(params: List, types: List, daTypes:List, cats: List, daCats: List, isNonStaticRefNone: Bool) [function]
                   | notViableTypes(CPPType, List, List, List, List) [function]
                   | viableType(CPPType, CPPType, ValueCategory) [function]
                   | viableImplicitObjectParameter(CPPType, CPPType, ValueCategory, isNonStaticRefNone: Bool) [function]

     rule notViableTypes(T::CPPFunctionType, Types::List, DATypes::List, Cats::List, DACats::List)
          => #notViableTypes(getParams(T), Types, DATypes, Cats, DACats, isFunctionMember(T) andBool notBool isMethodStatic(T) andBool getRefQualifier(T) ==K RefNone())

     rule #notViableTypes(ListItem(P:CPPType) Ps::List, ListItem(A::CPPType) As::List, ListItem(_) DAs::List, ListItem(C::ValueCategory) Cs::List, ListItem(_) DCs::List, B::Bool)
     => notBool viableType(P, A, C) orBool #notViableTypes(Ps, As, DAs, Cs, DCs, B)

     rule #notViableTypes(ListItem(implicitObjectParameter(P:CPPType))  Ps::List, ListItem(A::CPPType) As::List, DAs::List, ListItem(C::ValueCategory) Cs::List, DCs::List, B::Bool)
     => notBool viableImplicitObjectParameter(P, A, C, B) orBool #notViableTypes(Ps, As, DAs, Cs, DCs, B)

     rule #notViableTypes(... params: ListItem(variadic)) => false

     rule #notViableTypes(... params: .List, types: .List, cats: .List) => false

     // default arguments
     rule #notViableTypes(ListItem(P:CPPType) _, .List => ListItem(A) DAs, ListItem(A::CPPType) DAs::List, .List => DCs, DCs::List, _)

     rule canBeImplicitlyConvertedTo(...
               fromType: FromType::CPPType,
               fromCat:  FromCat::ValueCategory,
               toType:   ToType::CPPType
          ) => viableType(FromType, ToType, FromCat)

     rule viableType(P::CPPType, A::CPPType, C::ValueCategory) => conversionSequence(P, A, C, false, false, true) =/=K cannot-convert

     rule viableImplicitObjectParameter(P:CPPRefType, A::CPPType, C::ValueCategory, B::Bool)
          => conversionSequence(P, A, C, B, true, true) =/=K cannot-convert

     rule viableImplicitObjectParameter(t(... st: no-type), _, _, _) => true

     rule canConvertWithStandardConversion(P::CPPType, A::CPPType, C::ValueCategory) => computeSCS(P, A, C, false) =/=K cannot-convert

     syntax ConversionSequence ::= CannotConvert
                                 | conversionSequence(CPPType, CPPDType, ValueCategory, isNonStaticRefNone: Bool, isImplicit: Bool, canUserDefinedConvert: Bool) [function]
                                 | computeUDC(CPPType, CPPType, ValueCategory) [function]
                                 | computeUDCFrom(CPPType, Class, ClassInfo, ValueCategory) [function]
                                 | computeUDCTo(Class, ClassInfo, CPPType, ValueCategory) [function]
                                 | "ellipsisConversionSequence"
                                 | computeSCS(CPPType, CPPType, ValueCategory, isOverload: Bool) [function]
                                 | computeSCS2(Conversion, CPPType, CPPType, isOverload: Bool) [function]
                                 | computeSCS3(Conversion, Conversion, CPPType, CPPType) [function]
                                 | standardConversionSequence(Conversion, typeConv: Conversion, Conversion, isNonStaticRefNone: Bool, param: CPPType)
                                 | userDefinedConversionSequence(ConversionSequence, QualId, CPPType, ConversionSequence)
                                 | "ambiguousConversionSequence"
                                 | listInitSequence(CPPType, ConversionSequence)
                                 | "bottomConversionSequence"

     // 13.3.3.1.4:1 (identity conversion)
     rule conversionSequence(P:CPPRefType, A:CPPType, C::ValueCategory, B::Bool, _, _)
          => standardConversionSequence(identity, identity, identity, B, P)
          requires bindsDirectlyToExp(P, A, C, B)
               andBool notBool (isCPPClassType(innerType(P)) andBool isCPPClassType(A)
                    andBool isBaseClassOf({innerType(P)}:>CPPClassType, {A}:>CPPClassType))

     rule conversionSequence(P:CPPRefType, A:CPPClassType, C::ValueCategory, B::Bool, _, _)
          => standardConversionSequence(identity, derivedToBaseConversion(P, A), identity, B, P)
          requires bindsDirectlyToExp(P, A, C, B) andBool isCPPClassType(innerType(P))
               andBool isBaseClassOf({innerType(P)}:>CPPClassType, A)

     rule conversionSequence(P:CPPRefType, A:CPPType, C::ValueCategory, false, false, CanUDC::Bool)
          => conversionSequence(innerType(P), A, C, false, false, CanUDC)
          requires notBool bindsDirectlyToExp(P, A, C, false)
               andBool notBool bindsDirectlyToConversion(P, A, C)
               andBool isValidReferenceType(P)

     rule conversionSequence(P:CPPRefType, A:CPPType, C::ValueCategory, false, false, _)
          => cannot-convert
          requires notBool bindsDirectlyToExp(P, A, C, false)
               andBool notBool bindsDirectlyToConversion(P, A, C)
               andBool notBool isValidReferenceType(P)

     // 13.3.1:5.1-5.2
     rule conversionSequence(P:CPPRefType, A:CPPType, C::ValueCategory, B::Bool, true, _)
          => cannot-convert
          requires notBool bindsDirectlyToExp(P, A, C, B)

     rule conversionSequence(P::CPPType, initListType(ListItem(A::CPPType)), initListCat(ListItem(C::ValueCategory)), false, false, CanUDC::Bool)
          => listInitSequence(P, conversionSequence(P, A, C, false, false, CanUDC))
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P) andBool notBool isCPPArrayType(P)

     rule conversionSequence(P::CPPType, initListType(.List), _, false, false, _)
          => listInitSequence(P, standardConversionSequence(identity, identity, identity, false, P))
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P) andBool notBool isCPPArrayType(P)

     rule conversionSequence(P::CPPType, initListType(L::List), _, false, false, _)
          => cannot-convert
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P) andBool notBool isCPPArrayType(P)
               andBool size(L) >Int 1

     syntax Bool ::= bindsDirectlyToExp(CPPRefType, CPPType, ValueCategory, isNonStaticRefNone: Bool) [function]
                   | bindsDirectlyToConversion(CPPRefType, CPPType, ValueCategory) [function]

     rule bindsDirectlyToExp(t(... st: lvRefType(T1::CPPType)), T2::CPPType, lvalue, _) => true
          requires isReferenceCompatible(T1, T2)

     rule bindsDirectlyToExp(T::CPPRefType, T2::CPPType, xvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)

     rule bindsDirectlyToExp(T::CPPRefType, T2:CPPClassType, prvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)

     rule bindsDirectlyToExp(T::CPPRefType, T2:CPPArrayType, prvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)

     rule bindsDirectlyToExp(T::CPPRefType, T2:CPPFunctionType, lvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)

     rule bindsDirectlyToExp(t(... st: lvRefType(t(... q: Q::Quals => Q +Qual Const()))), _, _:RValueCategory, true => false)

     rule bindsDirectlyToExp(t(... st: rvRefType(t(... q: Q::Quals => Q +Qual Const()))), _, _:RValueCategory, true => false)

     rule bindsDirectlyToExp(...) => false [owise]

     rule bindsDirectlyToConversion(T::CPPRefType, T2::CPPType, C::ValueCategory) => false
          requires notBool (isCPPClassType(T2) andBool notBool isReferenceRelated(innerType(T), T2))
               orBool bindsDirectlyToExp(T, T2, C, false)

     rule conversionSequence(P::CPPType, A:CPPType, C::ValueCategory, false, false, CanUDC::Bool) => adjustParamType(computeSCS(utype(P), utype(A), C, CanUDC), P)
          requires notBool isCPPRefType(P)
               andBool ((notBool isCPPClassType(P) andBool notBool isCPPClassType(A))
                    orBool utype(A) ==Type utype(P)
                    orBool (isCPPClassType(A) andBool isCPPClassType(P) andBool isBaseClassOf({P}:>CPPClassType, {A}:>CPPClassType)))

     rule conversionSequence(P::CPPType, A:CPPType, C::ValueCategory, false, false, CanUDC:Bool) => #if CanUDC #then computeUDC(utype(P), utype(A), C) #else cannot-convert #fi [owise]

     rule computeUDC(t(... st: classType(P::Class)), A::CPPType, C::ValueCategory) => computeUDCTo(P, getClassInfo(P), A, C)
          requires notBool isCPPClassType(A)

     rule computeUDC(P::CPPType, t(... st: classType(A::Class)), C::ValueCategory) => computeUDCFrom(P, A, getClassInfo(A), C)
          requires notBool isCPPClassType(P)

     rule computeUDC(t(... st: classType(P::Class)), t(... st: classType(A::Class)), C::ValueCategory) => resolveUDC(ListItem(computeUDCFrom(type(classType(P)), A, getClassInfo(A), C)) ListItem(computeUDCTo(P, getClassInfo(P), type(classType(A)), C)), .List)

     rule computeUDCTo(_ :: Class(_, X::CId, _) #as P::Class, <class>... <cenv>... ConstructorId(X) |-> M::TypeMap ...</cenv> ...</class>, A::CPPType, C::ValueCategory)
          => resolveUDC(#computeUDCTo(P, keys_list(stripExplicit(M)), A, C), .List)

     rule computeUDCFrom(P::CPPType, A::Class, <class>... <conversion-functions> L::List </conversion-functions> ...</class>, C::ValueCategory)
          => resolveUDC(#computeUDCFrom(P, L, A, C), .List)

     syntax List ::= #computeUDCFrom(CPPType, List, Class, ValueCategory) [function]
                   | #computeUDCTo(Class, List, CPPType, ValueCategory) [function]

     syntax ConversionSequence ::= resolveUDC(List, List) [function]

     rule #computeUDCTo(_ :: Class(_, X::CId, _) #as P::Class, ListItem(t(... st: functionType(... returnType: Ret::CPPType, paramTypes: Param::CPPType)) #as FuncT::CPPFunctionType) L::List, A::CPPType, C::ValueCategory)
          => ListItem(userDefinedConversionSequence(conversionSequence(Param, A, C, false, false, false), P :: ConstructorId(X), FuncT, conversionSequence(type(classType(P)), type(classType(P)), unnamedCat(Ret), false, false, false))) #computeUDCTo(P, L, A, C)

     rule #computeUDCTo(_, .List, _, _) => .List

     rule #computeUDCFrom(P::CPPType, ListItem(t(... st: functionType(... returnType: Ret::CPPType)) #as FuncT::CPPFunctionType) L::List, A::Class, C::ValueCategory)
          => ListItem(userDefinedConversionSequence(conversionSequence(implicitObjectParameterType(FuncT), type(classType(A)), C, getRefQualifier(FuncT) ==K RefNone(), true, false), A :: ConversionId(Ret), FuncT, conversionSequence(P, Ret, unnamedCat(Ret), false, false, false))) #computeUDCFrom(P, L, A, C)

     rule #computeUDCFrom(_, .List, _, _) => .List

     rule resolveUDC((ListItem(cannot-convert) => .List) _, _)

     rule resolveUDC((ListItem(userDefinedConversionSequence(cannot-convert, _, _, _)) => .List) _, _)

     rule resolveUDC((ListItem(userDefinedConversionSequence(_, _, _, cannot-convert)) => .List) _, _)

     rule resolveUDC((ListItem(C::ConversionSequence) => .List) _, (.List => ListItem(C)) _) [owise]

     rule resolveUDC(.List, .List) => cannot-convert

     rule resolveUDC(.List, ListItem(C::ConversionSequence)) => C

     rule resolveUDC(.List, ListItem(_) ListItem(_) _) => ambiguousConversionSequence

     rule computeSCS(P::CPPType, A::CPPType, _:GLValueCategory, B::Bool) => computeSCS2(lvalueConversion, P, prvalType(A), B)
          requires notBool isCPPFunctionType(A) andBool notBool isCPPArrayType(A)

     rule computeSCS(P::CPPType, A::CPPType, _:GLValueCategory, B::Bool) => computeSCS2(arrayConversion, P, type(pointerType(innerType(A))), B)
          requires isCPPArrayType(A)

     rule computeSCS(P::CPPType, A::CPPType, _:LValueCategory, B::Bool) => computeSCS2(functionConversion, P, type(pointerType(A)), B)
          requires isCPPFunctionType(A)

     rule computeSCS(P::CPPType, A::CPPType, prvalue, B::Bool) => computeSCS2(identity, P, A, B)
          requires notBool isCPPArrayType(A)

     rule computeSCS(...) => cannot-convert [owise]

     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPIntegerType, _) => computeSCS3(C, integralPromotion(P, A), P, A)
          requires utype(P) =/=Type utype(A) andBool (promote(A) ==Type P orBool promote(promote(A)) ==Type P)

     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPUnscopedEnumType, _) => computeSCS3(C, integralPromotion(P, A), P, A)
          requires utype(P) =/=Type utype(A) andBool (promote(A) ==Type P orBool promote(promote(A)) ==Type P)

     rule computeSCS2(C::Conversion, t(... st: double) #as P::CPPType, t(... st: float), _) => computeSCS3(C, floatingPromotion, P, P)

     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPIntegerType, _) => computeSCS3(C, integralConversion, P, P)
          requires utype(P) =/=Type utype(A) andBool promote(A) =/=Type P andBool promote(promote(A)) =/=Type P andBool notBool isCPPBoolType(P)

     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPUnscopedEnumType, _) => computeSCS3(C, integralConversion, P, P)
          requires utype(P) =/=Type utype(A) andBool promote(A) =/=Type P andBool promote(promote(A)) =/=Type P andBool notBool isCPPBoolType(P)

     rule computeSCS2(C::Conversion, P:CPPFloatingType, A:CPPFloatingType, _) => computeSCS3(C, floatingConversion, P, P)
          requires notBool (simpleType(P) ==K double andBool simpleType(P) ==K float)

     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPFloatingType, _) => computeSCS3(C, floatingIntegralConversion, P, P)

     rule computeSCS2(C::Conversion, P:CPPFloatingType, A:CPPIntegerType, _) => computeSCS3(C, floatingIntegralConversion, P, P)

     rule computeSCS2(C::Conversion, P:CPPFloatingType, A:CPPUnscopedEnumType, _) => computeSCS3(C, floatingIntegralConversion, P, P)

     rule computeSCS2(C::Conversion, P:CPPPointerType, A:CPPIntegerType, _) => computeSCS3(C, pointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, P:CPPPointerType, A:CPPNullPtrTType, _) => computeSCS3(C, pointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, P:CPPNullPtrTType, A:CPPIntegerType, _) => computeSCS3(C, pointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, t(... st: pointerType(t(... st: void))) #as P::CPPType, t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, _))) #as A::CPPType, _)
          => computeSCS3(C, pointerConversion(P, A), P, t(Q, Mods, pointerType(t(Q', Mods', void))))
          requires notBool isSimilar(utype(P), utype(A))

     rule computeSCS2(C::Conversion, t(... st: pointerType(t(... st: T:CPPSimpleClassType) #as B::CPPClassType)) #as P::CPPType, t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, _) #as D:CPPClassType)) #as A::CPPType, _)
          => computeSCS3(C, pointerConversion(P, A), P, t(Q, Mods, pointerType(t(Q', Mods', T))))
          requires B =/=K D andBool isBaseClassOf(B, D)

     rule computeSCS2(C::Conversion, P:CPPMemberPointerType, A:CPPIntegerType, _) => computeSCS3(C, memberPointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, P:CPPMemberPointerType, A:CPPNullPtrTType, _) => computeSCS3(C, memberPointerConversion(P, A), P, P)

     rule computeSCS2(C::Conversion, t(... st: memberPointerType(D:CPPClassType, t(... st: T::CPPSimpleType))) #as P::CPPType, t(Q::Quals, Mods::Set, memberPointerType(B:CPPClassType, t(Q'::Quals, Mods'::Set, T))) #as A::CPPType, _)
          => computeSCS3(C, memberPointerConversion(P, A), P, t(Q, Mods, memberPointerType(D, t(Q', Mods', T))))
          requires B =/=K D andBool isBaseClassOf(B, D)

     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPIntegerType, _) => computeSCS3(C, booleanConversion(A), P, P)
          requires utype(P) =/=Type utype(A)

     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPUnscopedEnumType, _) => computeSCS3(C, booleanConversion(A), P, P)

     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPPointerType, _) => computeSCS3(C, booleanConversion(A), P, P)

     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPMemberPointerType, _) => computeSCS3(C, booleanConversion(A), P, P)

     rule computeSCS2(C::Conversion, P::CPPType, A::CPPType, _)
          => computeSCS3(C, identity, P, A)
          requires isSimilar(utype(P), utype(A))

     rule computeSCS2(C::Conversion, P:CPPClassType, A:CPPClassType, true)
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
     rule #resolveOverload(cSet(... candidates: T:CPPPointerType |-> envEntry(... base: Base::SymBase), id: X::QualId), list(Args::List), _, _, E::Expr, _)
          => Odr.newUse(Base)
          ~> updateExternalUses(Base)
          ~> checkAccess(CallExpr(lv(lnew(Base), hasTrace(E), T), list(Args), krlist(getDefaultArgsVals(emptyDefaultArguments(innerType(T))))))
          requires isCPPFunctionType(innerType(T)) andBool Base =/=K nonStatic

     rule #resolveOverload(cSet(... candidates: T:CPPPointerType |-> envEntry(... base: nonStatic)), list(Args::List), _, _, E::Expr, _)
          => checkAccess(CallExpr(le(E, hasTrace(E), T), list(Args), krlist(getDefaultArgsVals(emptyDefaultArguments(innerType(T))))))
          requires isCPPFunctionType(innerType(T))

     // only one viable candidate
     rule bestViable(T::CPPFunctionType, envEntry(... base: Base::SymBase, defaultArgs: defArgs(... vals: DArgs::StrictListResult))) ~> #resolveOverload(cSet(... id: X::QualId), list(Args::List), _, _, E::Expr, _)
          => #if isMethodPure(T) andBool isVirtualCall(hasTrace(E), T) #then .K #else Odr.newUse(Base) #fi
          ~> updateExternalUses(Base)
          ~> checkAccess(CallExpr(lv(lnew(Base), hasTrace(E), T), list(Args), DArgs))

     rule bestViable(T::CPPFunctionType, builtinOp(E::Expr)) ~> #resolveOverload(...) => E

     rule (.K => computeBestViable(M, Types, Cats, O))
          ~> #resolveOverload(cSet(... candidates: M::TypeMap), list(Args::List), krlist(Types::List), krlist(Cats::List), _, O::OverloadType)
          requires allViable(M, size(Args), Types, Cats) [owise] //allViable is expensive so we evaluate this rule late in order to avoid recomputing it over and over unnecessarily

     syntax Bool ::= allViable(cands: TypeMap, Int, List, List) [function]

     rule allViable(T::CPPType |-> envEntry(... defaultArgs: DA::DefaultArgumentsResult) M::TypeMap, NArgs::Int, Types::List, Cats::List)
          => isCPPFunctionType(T) andBool acceptsNArgs(NArgs, {T}:>CPPFunctionType, getDefaultArgsVals(DA))
               andBool notBool notViableTypes(T, Types, getDefaultArgsTypes(DA), Cats, getDefaultArgsCats(DA))
               andBool allViable(M, NArgs, Types, Cats)

     // TODO(traiansf): properly resolve default arguments for templates
     rule allViable(T::CPPType |-> Val:KItem M::TypeMap, NArgs::Int, Types::List, Cats::List)
          => isCPPFunctionType(T) andBool #fun(DA::DefaultArgumentsResult =>
               acceptsNArgs(NArgs, {T}:>CPPFunctionType, getDefaultArgsVals(DA))
               andBool notBool notViableTypes(T, Types, getDefaultArgsTypes(DA), Cats, getDefaultArgsCats(DA)))(emptyDefaultArguments(T))
               andBool allViable(M, NArgs, Types, Cats)
          requires isTemplateSpecialization(Val) orBool isBuiltinOp(Val)

     rule allViable(T::CPPType |-> templateInfo(...) _, _, _, _) => false

     rule allViable(... cands: .Map) => true

     syntax KItem ::= computeBestViable(TypeMap, List, List, OverloadType) [function]
                    | #computeBestViable(CPPFunctionType, K, List, List, List, OverloadType, List) [function]
                    | checkIsBest(CPPFunctionType, K, List, List, OverloadType, List) [function]
                    | bestViable(CPPFunctionType, K)
                    | "noBestViable"

     rule computeBestViable(.Map, _, _, _) => noBestViable

     rule computeBestViable(T::CPPFunctionType |-> K:KItem M::TypeMap, Types::List, Cats::List, O::OverloadType)
          => #computeBestViable(T, K, Map2List(M), Types, Cats, O, .List)

     rule #computeBestViable(
               T1::CPPFunctionType,
               K1:K,
               (ListItem(kpair(T2::CPPFunctionType, K2:K)) => .List) _,
               Types::List,
               Cats::List,
               O::OverloadType,
               (.List => ListItem(kpair(T2, K2))) _
          )
          requires notBool isBetterFunctionThan(T2, K2, T1, K1, Types, Cats, O)

     rule #computeBestViable(
               (T1::CPPFunctionType => T2),
               (K1:K => K2),
               (ListItem(kpair(T2::CPPFunctionType, K2:K)) => .List) _,
               _,
               _,
               _,
               (.List => ListItem(kpair(T1, K1))) _
          )
          [owise]

     rule #computeBestViable(T::CPPFunctionType, K:K, .List, Types::List, Cats::List, O::OverloadType, Others::List)
          => checkIsBest(T, K, Types, Cats, O, Others)

     rule checkIsBest(
               T1::CPPFunctionType,
               K1:K,
               Types::List,
               Cats::List,
               O::OverloadType,
               (ListItem(kpair(T2::CPPFunctionType, K2:K)) => .List) _
          )
          requires isBetterFunctionThan(T1, K1, T2, K2, Types, Cats, O)

     rule checkIsBest(T::CPPFunctionType, K:K, _, _, _, .List) => bestViable(T, K)

     rule checkIsBest(...) => noBestViable [owise]

     syntax Bool ::= isBetterFunctionThan(CPPFunctionType, K, CPPFunctionType, K, List, List, OverloadType) [function]

     // TODO(dwightguth): 13.3.3:1.4,1.5,1.7
     rule isBetterFunctionThan(F1::CPPFunctionType, K1:K, F2::CPPFunctionType, K2:K, Types::List, Cats::List, NotConversionOverload()) =>
          notBool hasWorseConversionSequenceThan(F1, F2, Types, Cats)
               andBool (hasBetterConversionSequenceThan(F1, F2, Types, Cats)
                    orBool (notBool isTemplateSpecialization(K1) andBool isTemplateSpecialization(K2)))
          requires notBool (isTemplateSpecialization(K1) andBool isTemplateSpecialization(K2))

     syntax Bool ::= hasWorseConversionSequenceThan(CPPFunctionType, CPPFunctionType, List, List) [function]
                   | hasBetterConversionSequenceThan(CPPFunctionType, CPPFunctionType, List, List) [function]
                   | #hasWorseCSThan(List, List) [function]
                   | #hasBetterCSThan(List, List) [function]

     syntax List ::= getConversionSequences(CPPFunctionType, List, List) [function]
                   | #getConversionSequences(List, List, List, isNonStaticRefNone: Bool, isStatic: Bool) [function]

     rule hasWorseConversionSequenceThan(F1::CPPFunctionType, F2::CPPFunctionType, Types::List, Cats::List)
          => #hasWorseCSThan(getConversionSequences(F1, Types, Cats), getConversionSequences(F2, Types, Cats))

     rule hasBetterConversionSequenceThan(F1::CPPFunctionType, F2::CPPFunctionType, Types::List, Cats::List)
          => #hasBetterCSThan(getConversionSequences(F1, Types, Cats), getConversionSequences(F2, Types, Cats))

     rule #hasWorseCSThan(ListItem(C1::ConversionSequence) L1::List, ListItem(C2::ConversionSequence) L2::List)
          => C2 >CS C1 orBool #hasWorseCSThan(L1, L2)
          requires C1 =/=K bottomConversionSequence andBool C2 =/=K bottomConversionSequence

     rule #hasBetterCSThan(ListItem(C1::ConversionSequence) L1::List, ListItem(C2::ConversionSequence) L2::List)
          => C1 >CS C2 orBool #hasBetterCSThan(L1, L2)
          requires C1 =/=K bottomConversionSequence andBool C2 =/=K bottomConversionSequence

     rule #hasBetterCSThan(ListItem(bottomConversionSequence) L1::List, ListItem(_) L2::List)
          => #hasBetterCSThan(L1, L2)

     rule #hasWorseCSThan(ListItem(bottomConversionSequence) L1::List, ListItem(_) L2::List)
          => #hasWorseCSThan(L1, L2)

     rule #hasBetterCSThan(ListItem(_) L1::List, ListItem(bottomConversionSequence) L2::List)
          => #hasBetterCSThan(L1, L2)

     rule #hasWorseCSThan(ListItem(_) L1::List, ListItem(bottomConversionSequence) L2::List)
          => #hasWorseCSThan(L1, L2)

     rule #hasBetterCSThan(.List, .List) => false

     rule #hasWorseCSThan(.List, .List) => false

     rule getConversionSequences(T::CPPFunctionType, Types::List, Cats::List)
          => #getConversionSequences(getParams(T), Types, Cats, isFunctionMember(T) andBool notBool isMethodStatic(T) andBool getRefQualifier(T) ==K RefNone(), isMethodStatic(T))

     rule #getConversionSequences(ListItem(P:CPPType) Ps::List, ListItem(A::CPPType) As::List, ListItem(C::ValueCategory) Cs::List, B1::Bool, B2::Bool)
          => ListItem(conversionSequence(P, A, C, false, false, true)) #getConversionSequences(Ps, As, Cs, B1, B2)

     rule #getConversionSequences(ListItem(implicitObjectParameter(P:CPPType)) Ps::List, ListItem(A::CPPType) As::List, ListItem(C::ValueCategory) Cs::List, IsNonStaticRefNone::Bool, false)
          => ListItem(conversionSequence(P, A, C, IsNonStaticRefNone, true, true)) #getConversionSequences(Ps, As, Cs, IsNonStaticRefNone, false)

     rule #getConversionSequences(ListItem(implicitObjectParameter(_)) Ps::List, ListItem(_) As::List, ListItem(_) Cs::List, IsNonStaticRefNone::Bool, true)
          => ListItem(bottomConversionSequence) #getConversionSequences(Ps, As, Cs, IsNonStaticRefNone, true)

     rule #getConversionSequences(ListItem(variadic), ListItem(_) As::List, ListItem(_) Cs::List, B1::Bool, B2::Bool)
          => ListItem(ellipsisConversionSequence) #getConversionSequences(ListItem(variadic), As, Cs, B1, B2)

     rule #getConversionSequences(_, .List, .List, _, _) => .List

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

     rule booleanConversion(A1::CPPType) >Conv booleanConversion(A2::CPPType)
          => true
          requires notBool (isCPPPointerType(A1) orBool isCPPMemberPointerType(A1) orBool isCPPNullPtrTType(A1))
               andBool (isCPPPointerType(A2) orBool isCPPMemberPointerType(A2) orBool isCPPNullPtrTType(A2))

     rule integralPromotion(P1::CPPType, A1::CPPType) >Conv integralPromotion(P2::CPPType, A2::CPPType)
          => true
          requires promote(A1) ==Type P1 andBool promote(promote(A2)) ==Type P2
               andBool promote(A2) =/=Type promote(promote(A2))

     rule pointerConversion(t(... st: pointerType(A:CPPClassType)), t(... st: pointerType(B1:CPPClassType)))
          >Conv
          pointerConversion(t(... st: pointerType(t(... st: void))), t(... st: pointerType(B2::CPPClassType)))
          => true
          requires B1 ==Type B2 andBool A =/=Type B1 andBool isBaseClassOf(A, B1)

     rule pointerConversion(t(... st: pointerType(t(... st: void))), t(... st: pointerType(A:CPPClassType)))
          >Conv
          pointerConversion(t(... st: pointerType(t(... st: void))), t(... st: pointerType(B:CPPClassType)))
          => true
          requires A =/=Type B andBool isBaseClassOf(A, B)

     rule pointerConversion(t(... st: pointerType(B:CPPClassType)), t(... st: pointerType(C1:CPPClassType)))
          >Conv
          pointerConversion(t(... st: pointerType(A:CPPClassType)), t(... st: pointerType(C2::CPPClassType)))
          => true
          requires A =/=Type B andBool B =/=Type C1 andBool C1 ==Type C2 andBool isBaseClassOf(A, B) andBool isBaseClassOf(B, C1)

     rule pointerConversion(t(... st: pointerType(A1:CPPClassType)), t(... st: pointerType(B:CPPClassType)))
          >Conv
          pointerConversion(t(... st: pointerType(A2::CPPClassType)), t(... st: pointerType(C:CPPClassType)))
          => true
          requires A1 ==Type A2 andBool A1 =/=Type B andBool B =/=Type C andBool isBaseClassOf(A1, B) andBool isBaseClassOf(B, C)

     rule derivedToBaseConversion(P1::CPPType, A1::CPPType)
          >Conv
          derivedToBaseConversion(P2::CPPType, A2::CPPType)
          =>
          pointerConversion(type(pointerType(P1)), type(pointerType(A1)))
          >Conv
          pointerConversion(type(pointerType(P2)), type(pointerType(A2)))

     rule memberPointerConversion(t(... st: memberPointerType(P1::CPPClassType, _)), t(... st: memberPointerType(A1::CPPClassType, _)))
          >Conv
          memberPointerConversion(t(... st: memberPointerType(P2::CPPClassType, _)), t(... st: memberPointerType(A2::CPPClassType, _)))
          =>
          pointerConversion(type(pointerType(A1)), type(pointerType(P1)))
          >Conv
          pointerConversion(type(pointerType(A2)), type(pointerType(P2)))

     rule _ >Conv _ => false [owise]

     rule C1::ConversionSequence
          >CS
          C2::ConversionSequence
          => true
          requires form(C1) >Int form(C2)

     rule C1::ConversionSequence
          >CS
          C2::ConversionSequence
          => true
          requires form(C2) >Int form(C1)

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

     // 13.3.3.2:3.1.3 mentions binding an rvalue reference to an rvalue.
     // The only case when an rvalue reference can be bound (which we know
     // it can be if we've reached this point) but not bound to an rvalue
     // is if it is bound to an lvalue. But an rvalue reference can be
     // bound to an lvalue if and only if the rvalue reference is a
     // function reference. So we check the inner type of the reference
     // instead in order to avoid having to compute the value category
     // to which the reference is bound.
     rule standardConversionSequence(... isNonStaticRefNone: false, param: S1:CPPRVRefType)
          >CS
          standardConversionSequence(... isNonStaticRefNone: false, param: S2:CPPLVRefType)
          => true
          requires notBool isCPPFunctionType(innerType(S1))

     // 13.3.3.2:3.1.4 also mentions the value category the reference is bound
     // to, but like rvalue references, lvalue references can be bound to a
     // function if and only if the function is an lvalue. So again, we check
     // only the inner type of the reference.
     rule standardConversionSequence(... param: S1:CPPLVRefType)
          >CS
          standardConversionSequence(... param: S2:CPPRVRefType)
          => true
          requires isCPPFunctionType(innerType(S1))
               andBool isCPPFunctionType(innerType(S2))

     rule standardConversionSequence(C1::Conversion, C2::Conversion, qualificationConversion, _, T1::CPPType)
          >CS
          standardConversionSequence(C1, C2, qualificationConversion, _, T2::CPPType)
          => true
          requires isSimilar(T1, T2)
               andBool #fun(Q1::Quals => #fun(Q2::Quals => Q1 =/=K Q2 andBool Q1 <=Quals Q2)(getQuals(T2)))(getQuals(T1))

     rule standardConversionSequence(... param: S1:CPPRefType)
          >CS
          standardConversionSequence(... param: S2:CPPRefType)
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
     rule noBestViable ~> #resolveOverload(... cands: cSet(... id: X::QualId)) => notFound(getId(X))

     rule #resolveOverload(... cands: cSet(... candidates: (T:CPPFunctionTypeExpr => adjustFunctionType(T)) |-> _:TemplateInfo))
          requires notBool isAdjustedType(T)

     rule <k> (.K => deduceTemplateFromCall(T, Args, .List, Q)) ~> #resolveOverload(... cands: cSet(... candidates: (T:CPPFunctionTypeExpr |-> templateInfo(... id: Q::QualId) => .Map) _), args: list(Args::List)) ...</k>
          <template-deduction> _ => .Map </template-deduction>
          requires isAdjustedType(T)

     rule (templateSpecialization(T:CPPType, I::TemplateInfo, Args::Map) => .K) ~> #resolveOverload(... cands: cSet(... candidates: (.Map => T |-> templateSpecialization(T, I, Args)) _))

     rule (.K => instantiateObjectTemplate(Spec)) ~> bestViable(T::CPPFunctionType, Spec:TemplateSpecialization)

     // TODO(traiansf): properly resolve default arguments for templates
     rule (lv(loc(Base::SymBase, 0), _, _) => .K) ~> bestViable(T::CPPFunctionType, (_ => envEntry(Base, false, emptyDefaultArguments(T))))

     rule resolveUniqueDecl(cSet(... candidates: T::CPPType |-> envEntry(... base: Base::SymBase), id: X::QualId), E::Expr, _)
          => Odr.newUse(Base)
          ~> updateExternalUses(Base)
          ~> lv(lnew(Base), hasTrace(E), T)
          requires Base =/=K nonStatic
               andBool notBool isCPPRefType(T)
               andBool notBool isMemberBase(Base)

     rule resolveUniqueDecl(cSet(... candidates: T::CPPType |-> envEntry(... base: nonStatic)), E::Expr, _) => le(E, hasTrace(E), T)

     // resolve anonymous union member lookup
     rule resolveUniqueDecl(cSet(... candidates: _ |-> envEntry(... base: memberBase(unnamedObject(C::Class), X::CId, _))), _, _)
          => Name(NoNNS(), unnamedObject(C)) . no-template Name(NoNNS(), X)

     rule resolveUniqueDecl(cSet(T::CPPType |-> _:ClassOffset, C:Class :: X::CId), E::Expr, false) => le((*This()) . no-template Name(C, X), hasTrace(E), T)

     rule resolveUniqueDecl(cSet(T::CPPType |-> _:ClassOffset, C:Class :: X::CId), E::Expr, true)
          => dataMemberValue(memberPointer(C, X, T), hasTrace(E), T)

     rule <k> resolveUniqueDecl(cSet(... candidates: T:CPPRefType |-> envEntry(... base: Base::SymBase)), E::Expr, _) => le(E, hasTrace(E), T) ...</k>
          <references> Refs::Map </references>
          requires notBool loc(Base, 0) in_keys(Refs)

     rule <k> resolveUniqueDecl(cSet(... candidates: T:CPPRefType |-> envEntry(... base: Base::SymBase)), E::Expr, _) => lv(lnew(Base), hasTrace(E), T) ...</k>
          <references>... loc(Base, 0) |-> _ ...</references>

     rule resolveUniqueDecl(V:KResult, _, _) => V
          requires notBool isCandidateSet(V) andBool notBool isNotFoundNameRef(V)

     rule (.K => ILL("TOL1", "No declaration found for name '" +String showCId(X) +String "'.")) ~> resolveUniqueDecl(notFound(X::CId), _, _)

     // NOTE: the category of the contrivedObject is defaulted to lvalue as its value does not matter, as the
     // conversion sequence for the implicit object parameter will be ignored in this case.
     // See also 13.3.3.1.4:3 http://www.open-std.org/jtc1/sc22/wg21/docs/cwg_active.html#1278
     rule catof(contrivedObject(_) => lvalue)

     rule typeof(contrivedObject(T::CPPType) => T)

     rule contrivedObject(T::CPPType) => noObject()
          requires Translation()
endmodule
