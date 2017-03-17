module CPP-TYPING-SORTS
     syntax AType
     syntax CPPType ::= CPPFunctionType
                      | CPPClassType
     syntax CPPDType ::= CPPType | CPPVariadic | InitListType
     syntax CPPVariadic
     syntax InitListType
     syntax CPPSimpleType
     syntax EffectiveType ::= CPPType
     syntax CPPTypeExpr ::= CPPType
     syntax CPPDTypeExpr ::= CPPTypeExpr | CPPDType
     syntax CPPTypeExprs ::= List{CPPDTypeExpr, ","}
     syntax CPPTypes ::= List{CPPDType, ","}
     syntax CPPTypeExprs ::= CPPTypes
     syntax ExceptionSet
     syntax CPPFunctionType
     syntax CPPClassType
endmodule

module CPP-DEPENDENT-SYNTAX
     imports CPP-TYPING-SORTS
     imports CPP-DYNAMIC-SORTS
     syntax Bool ::= isDependentInScope(CPPTypeExpr) [function]
                   | areDependentInScope(TemplateParams) [function]
                   | areDependentInScope(CPPTypeExprs) [function]
                   | isAuto(CPPDTypeExpr) [function]
     syntax StrictList ::= typeStrict(StrictList)
endmodule

module CPP-TYPING-SYNTAX
     imports CPP-DEPENDENT-SYNTAX
     imports BASIC-K
     imports SET
     imports STRING-SYNTAX
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS

     syntax AType ::= CPPType

     syntax CPPType ::= t(q: Quals, m: Set, st: CPPSimpleType) [klabel(tcpp)]

     syntax CPPTypeExpr ::= innerType(CPPTypeExpr) [function, klabel(cppInnerType)]
     syntax CPPType ::= innerType(CPPType) [function, klabel(cppInnerType)]
     syntax CPPType ::= innerType(CPPSimpleType) [function, klabel(innerTypeOfSimpleType)]
     syntax CPPSimpleType ::= simpleType(CPPType) [function, klabel(cppSimpleType)]

     syntax CPPSimpleType ::= underlyingType(CPPSimpleType) [function, klabel(underlyingSimpleType)]
     syntax CPPType ::= underlyingType(CPPType) [function]

     syntax CPPSimpleFundamentalType ::= CPPSimpleSignedType | CPPSimpleUnsignedType | CPPSimpleFloatingType
                            | CPPSimpleCharType | CPPSimpleBoolType | CPPSimpleVoidType
                            | CPPSimpleWideCharType | CPPSimpleNullPtrTType
     syntax CPPSimpleType ::= CPPSimpleFundamentalType
                            | CPPSimpleCompoundType

     syntax CPPSimpleSignedType ::= CPPSimpleSignedCharType | "short" | "int" | "long" | "long-long"
     syntax CPPSimpleUnsignedType ::= CPPSimpleUnsignedCharType | "unsigned-short" | "unsigned" | "unsigned-long" | "unsigned-long-long"
     syntax CPPSimpleFloatingType ::= "float" | "double" | "long-double"
     syntax CPPSimpleCharType ::= CPPSimpleSignedCharType | CPPSimpleUnsignedCharType
     syntax CPPSimpleSignedCharType ::= "signed-char"
     syntax CPPSimpleUnsignedCharType ::= "unsigned-char"
     syntax CPPSimpleBoolType ::= "bool"
     syntax CPPSimpleVoidType ::= "void"
     syntax CPPSimpleCharType ::= "char"
     syntax CPPSimpleUnsignedType ::= "size_t" [function]
     syntax CPPSimpleSignedType ::= "ptrdiff_t" [function]
     syntax CPPSimpleWideCharType ::= "wchar_t" | "char16_t" | "char32_t"
     syntax CPPSimpleNullPtrTType ::= "nullptr_t"

     syntax CPPSimpleType ::= "no-type"

     syntax CPPSimpleCompoundType ::= CPPSimplePointerType
                            | CPPSimpleMemberPointerType
                            | CPPSimpleFunctionType
                            | CPPSimpleArrayType
                            | CPPSimpleClassType
                            | CPPSimpleLVRefType
                            | CPPSimpleRVRefType

     syntax CPPSimpleTypeExpr ::= CPPSimpleType 
                                | CPPSimpleDependentType
                                | CPPSimpleAutoType
                                | CPPSimpleArrayTypeExpr
                                | CPPSimplePointerTypeExpr
                                | CPPSimpleFunctionTypeExpr
                                | CPPSimpleClassTypeExpr
                                | CPPSimpleLVRefTypeExpr
                                | CPPSimpleRVRefTypeExpr

     syntax CPPSimpleArrayTypeExpr ::= arrayType(CPPTypeExpr, Int) [klabel(cppArrayType)]
     syntax CPPSimpleArrayTypeExpr ::= incompleteArrayType(CPPTypeExpr) [klabel(cppIncompleteArrayType)]
     syntax CPPSimplePointerTypeExpr ::= pointerType(CPPTypeExpr) [klabel(cppPointerType)]
     syntax CPPSimpleLVRefTypeExpr ::= lvRefType(CPPTypeExpr)
     syntax CPPSimpleRVRefTypeExpr ::= rvRefType(CPPTypeExpr)
     syntax CPPSimpleFunctionTypeExpr ::= functionType(returnType: CPPTypeExpr, paramTypes: CPPTypeExprs, methodInfo:MethodInfo, linkage: LanguageLinkage, exceptions: ExceptionSet) [klabel(cppFunctionType)]
     syntax CPPSimpleClassTypeExpr ::= classType(ClassTemplate)

     syntax CPPSimpleArrayType ::= CPPSimpleFixedArrayType | CPPSimpleIncompleteArrayType
     syntax CPPSimpleFixedArrayType ::= arrayType(CPPType, Int) [klabel(cppArrayType)]
     syntax CPPSimpleIncompleteArrayType ::= incompleteArrayType(CPPType) [klabel(cppIncompleteArrayType)]
     syntax CPPSimplePointerType ::= pointerType(CPPType) [klabel(cppPointerType)]
     syntax CPPSimpleMemberPointerType ::= CPPSimpleMemberFunctionPointerType
                                         | memberPointerType(CPPClassType, CPPType)
     syntax CPPSimpleMemberFunctionPointerType ::= memberPointerType(CPPClassType, CPPFunctionType)
     syntax CPPSimpleLVRefType ::= lvRefType(CPPType)
     syntax CPPSimpleRVRefType ::= rvRefType(CPPType)
     // TODO: exception specification
     syntax CPPSimpleFunctionType ::= functionType(returnType: CPPType, paramTypes: CPPTypes, methodInfo: MethodInfo, linkage: LanguageLinkage, exceptions: ExceptionSet) [klabel(cppFunctionType)]
     syntax CPPSimpleClassType ::= classType(Class)

     syntax CPPSimpleDependentType ::= dependentType(String)
     syntax CPPSimpleAutoType ::= "auto"
                                | "decltype(auto)"
     syntax CPPSimpleArrayTypeExpr ::= dynamicArrayType(CPPType, Expr)

     syntax CPPFunctionType ::= t(q: Quals, m: Set, st: CPPSimpleFunctionType) [klabel(tcpp)]
     syntax CPPArithmeticType ::= CPPIntegerType | CPPFloatingType
     syntax CPPScalarType ::= CPPArithmeticType | CPPEnumType | CPPPointerType | CPPMemberPointerType | CPPNullPtrTType
     syntax CPPFundamentalType ::= CPPVoidType | CPPArithmeticType | CPPNullPtrTType
     syntax CPPCharType ::= t(q: Quals, m: Set, st: CPPSimpleCharType) [klabel(tcpp)]
     syntax CPPBoolType ::= t(q: Quals, m: Set, st: CPPSimpleBoolType) [klabel(tcpp)]
     syntax CPPFloatingType ::= t(q: Quals, m: Set, st: CPPSimpleFloatingType) [klabel(tcpp)]
     syntax CPPIntegerType ::= CPPCharType | CPPBoolType | CPPSignedType | CPPUnsignedType | CPPWideCharType
     syntax CPPSignedType ::= t(q: Quals, m: Set, st: CPPSimpleSignedType) [klabel(tcpp)]
     syntax CPPUnsignedType ::= t(q: Quals, m: Set, st: CPPSimpleUnsignedType) [klabel(tcpp)]
     syntax CPPVoidType ::= t(q: Quals, m: Set, st: CPPSimpleVoidType) [klabel(tcpp)]
     syntax CPPArrayType ::= t(q: Quals, m: Set, st: CPPSimpleArrayType) [klabel(tcpp)]
     syntax CPPPointerType ::= t(q: Quals, m: Set, st: CPPSimplePointerType) [klabel(tcpp)]
     syntax CPPMemberPointerType ::= CPPMemberFunctionPointerType
                                   | t(q: Quals, m: Set, st: CPPSimpleMemberPointerType) [klabel(tcpp)]
     syntax CPPMemberFunctionPointerType ::= t(q: Quals, m: Set, st: CPPSimpleMemberFunctionPointerType) [klabel(tcpp)]
     syntax CPPLVRefType ::= t(q: Quals, m: Set, st: CPPSimpleLVRefType) [klabel(tcpp)]
     syntax CPPRVRefType ::= t(q: Quals, m: Set, st: CPPSimpleRVRefType) [klabel(tcpp)]
     syntax CPPNullPtrTType ::= t(q: Quals, m: Set, st: CPPSimpleNullPtrTType) [klabel(tcpp)]
     syntax CPPRefType ::= CPPLVRefType | CPPRVRefType
     syntax CPPClassType ::= t(q: Quals, m: Set, st: CPPSimpleClassType) [klabel(tcpp)]
     syntax CPPWideCharType ::= t(q: Quals, m: Set, st: CPPSimpleWideCharType) [klabel(tcpp)]
     syntax CPPBitfieldType
     syntax CPPEnumType ::= CPPScopedEnumType | CPPUnscopedEnumType
     syntax CPPScopedEnumType
     syntax CPPUnscopedEnumType
     syntax CPPType ::= CPPScalarType
                      | CPPRefType
                      | CPPArrayType 
                      | CPPFundamentalType

     syntax CPPFunctionTypeExpr ::= CPPFunctionType | t(q: Quals, m: Set, st: CPPSimpleFunctionTypeExpr) [klabel(tcpp)]
     syntax CPPClassTypeExpr ::= CPPClassType | t(q: Quals, m: Set, st: CPPSimpleClassTypeExpr) [klabel(tcpp)]
     syntax CPPArrayTypeExpr ::= CPPArrayType | t(q: Quals, m: Set, st: CPPSimpleArrayTypeExpr) [klabel(tcpp)]
     syntax CPPRefTypeExpr ::= CPPRefType | t(q: Quals, m: Set, st: CPPSimpleLVRefTypeExpr) [klabel(tcpp)]
                             | t(q: Quals, m: Set, st: CPPSimpleRVRefTypeExpr) [klabel(tcpp)]
     syntax CPPTypeExpr ::= t(q: Quals, m: Set, st: CPPSimpleTypeExpr) [klabel(tcpp)]
                          | CPPFunctionTypeExpr
                          | CPPClassTypeExpr
                          | CPPArrayTypeExpr
                          | CPPRefTypeExpr

     syntax CPPVariadic ::= "variadic"
     syntax InitListType ::= initListType(List)

     syntax Expr ::= setType(CPPType, Expr) [strict]

     syntax Quals ::= getQuals(CPPType) [function]
     syntax CPPType ::= addQuals(Quals, CPPType) [function]

     syntax Bool ::= isAdjustedType(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionTypeExpr ::= adjustFunctionType(CPPFunctionTypeExpr) [function]

     syntax Bool ::= isFunctionMember(CPPFunctionTypeExpr) [function]
     syntax List ::= getParams(CPPFunctionTypeExpr) [function, klabel(cppgetParams)]
                   | getRealParams(CPPFunctionTypeExpr) [function]
     syntax RefQualifier ::= getRefQualifier(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionType ::= setRefQualifier(CPPFunctionType, RefQualifier) [function]
     syntax Quals ::= getCVSQuals(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionType ::= setCVSQuals(CPPFunctionType, Quals) [function]
     syntax Bool ::= isMethodStatic(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionType ::= setMethodStatic(CPPFunctionType) [function]
     syntax Bool ::= isMethodVirtual(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionType ::= setMethodVirtual(CPPFunctionType) [function]
     syntax Bool ::= isMethodExplicit(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionType ::= setMethodExplicit(CPPFunctionType) [function]
     syntax Bool ::= isMethodUserProvided(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionType ::= setMethodUserProvided(CPPFunctionType, Bool) [function]
     syntax Bool ::= isMethodConstructor(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionType ::= setMethodConstructor(CPPFunctionType, Bool) [function]
     syntax Class ::= getMethodClass(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionType ::= setMethodClass(CPPFunctionType, Class) [function]
     syntax Bool ::= isVariadicFunction(CPPFunctionTypeExpr) [function]
     syntax CPPTypeExpr ::= getReturnType(CPPFunctionTypeExpr) [function, klabel(cppgetReturnType)]
     syntax CPPType ::= getReturnType(CPPFunctionType) [function, klabel(cppgetReturnType)]

     syntax Bool ::= acceptsNArgs(Int, CPPFunctionType) [function]

     syntax CPPType ::= const(CPPSimpleType) [function, klabel(constCpp)]

     syntax CPPType ::= type(CPPSimpleTypeExpr) [function, klabel(cppType)]
     // this significantly reduces the number of casts we have to do when converting between Class and CPPClassType
     syntax CPPClassType ::= type(CPPSimpleClassType) [function, klabel(cppType)]
     syntax CPPType ::= utype(Typed) [function, klabel(cppUTypeVal)]
     syntax CPPType ::= type(Typed) [function, klabel(cppTypeVal)]
     syntax CPPType ::= utype(CPPTypeExpr) [function, klabel(cppUTypeType)]

     syntax Bool ::= isObjectType(K) [function]
                   | isCompleteType(CPPType) [function, klabel(isCompleteTypeCPP)]
                   | isAggregateType(CPPType) [function, klabel(isAggregateTypeCPP)]
                   | isVolatileType(CPPType) [function, klabel(isVolatileTypeCPP)]
                   | isConstType(CPPType) [function, klabel(isConstTypeCPP)]

     syntax Type ::= convertTypeToC(CPPType) [function]
     syntax DType ::= convertTypeToC(CPPDType) [function]

     syntax CPPType ::= convertTypeToCPP(Type) [function]
     syntax CPPDType ::= convertTypeToCPP(DType) [function]

     syntax CPPType ::= correspondingUnsignedType(CPPType) [function, klabel(correspondingUnsignedTypeCpp)]

     syntax Int ::= max(CPPType) [function, klabel(maxCpp)]
                  | min(CPPType) [function, klabel(minCpp)]
                  | precision(CPPFloatingType) [function]
                  | exponent(CPPFloatingType) [function]
     syntax Float ::= fmax(CPPType) [function, klabel(fmaxCpp)]
                    | fmin(CPPType) [function, klabel(fminCpp)]
     syntax Bool ::= inRange(CPPValue, CPPType) [function, klabel(inRangeCpp)]

     syntax Tag ::= getTag(CPPTypeExpr) [function, klabel(getTagCpp)]
     syntax Tag ::= getTag(Class) [function, klabel(getClassTag)]

     syntax ClassInfo ::= getClassInfo(CPPClassType) [function]
                        | getClassInfo(Class) [function, klabel(getClassInfoOfClass)]
                        | #getClassInfo(Class, K) [function]
     syntax ClassInfo ::= ClassCell | "#incomplete"

     syntax MethodInfo ::= "noMethod"
                         | methodInfo(refQual: RefQualifier, cvQuals: Quals, static: Bool, virtual:Bool, explicit: Bool, class: K, userProvided: Bool, constructor: Bool)
                         | defaultMethodInfo() [function]

     syntax CPPDType ::= implicitObjectParameter(CPPTypeExpr)

     syntax Bool ::= isBaseClassOf(base: CPPClassType, derived: CPPClassType) [function]
                   | isVirtualBaseClassOf(CPPClassType, CPPClassType) [function]
                   | isBaseClassOf(base: Class, derived: Class) [function, klabel(isClassBaseClassOf)]
                   | hasVirtualMembers(CPPClassType) [function]
                   | isUnionLikeClass(Class) [function]
     
     syntax CPPType ::= getMostDerivedArrayElement(CPPType) [function]

     syntax Bool ::= CPPType "==Type" CPPType [function]
                   | CPPType "=/=Type" CPPType [function]

     syntax ExceptionSet ::= exSet(Set) | "noexcept(true)" | "noexcept(false)"
     syntax KResult ::= ExceptionSet
     syntax ExceptionSpec ::= ExceptionSet

     syntax Bool ::= isUnnamedLValue(CPPType) [function]
                   | isUnnamedXValue(CPPType) [function]
                   | isUnnamedPRValue(CPPType) [function]

endmodule

module CPP-TYPING
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports FLOAT
     imports K-REFLECTION
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX

     rule getParams(t(_, _, functionType(... paramTypes: L::CPPTypes, methodInfo: noMethod))) => toList(L)
     rule getParams(t(_, _, functionType(... paramTypes: L::CPPTypes, methodInfo: methodInfo(... constructor: true)))) => toList(L)
     rule getParams(t(_, _, functionType(... paramTypes: L::CPPTypes, methodInfo: methodInfo(RQ::RefQualifier, CVS::Quals, IsStatic::Bool, _, _, C::Class, _, false)))) => ListItem(implicitObjectParameter(getImpliedParamType(RQ, CVS, IsStatic, C))) toList(L)
     rule getRealParams(T::CPPFunctionTypeExpr) => #getRealParams(getParams(T))
     rule getReturnType(t(_, _, functionType(... returnType: T::CPPType))) => T
     rule isVariadicFunction(T::CPPFunctionTypeExpr) => size(getParams(T)) =/=Int size(getRealParams(T))

     syntax List ::= #getRealParams(List) [function]
     rule #getRealParams(L::List ListItem(variadic)) => L
     rule #getRealParams(L::List) => L [owise]

     // 13.3.2:2.1
     rule acceptsNArgs(M::Int, T::CPPFunctionType) => true
          requires size(getRealParams(T)) ==Int M
     // 13.3.2:2.2
     rule acceptsNArgs(M::Int, T::CPPFunctionType) => isVariadicFunction(T)
          requires size(getRealParams(T)) <Int M
     // TODO(dwightguth): default function arguments

     rule isFunctionMember(t(... st: functionType(... methodInfo: methodInfo(...)))) => true
     rule isFunctionMember(_) => false [owise]

     // TODO(traiansf): Handle conversion functions and functions introduced by using declarations
     syntax CPPTypeExpr ::= getImpliedParamType(RefQualifier, Quals, static: Bool, Class) [function]
     // 13.3.1:4
     rule getImpliedParamType(... static: true) => type(no-type)
     // 13.3.1:4.2
     rule getImpliedParamType(RefRValue(), Q::Quals, false, C::Class) => type( rvRefType(t(Q, .Set, classType(C))))
     // 13.3.1:4.1
     rule getImpliedParamType(_, Q::Quals, false, C::Class) => type(lvRefType(t(Q, .Set, classType(C)))) [owise]

     rule defaultMethodInfo() => methodInfo(RefNone(), noQuals, false, false, false, .K, true, false)

     rule getRefQualifier(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIRefQualifier(MI)
     rule setRefQualifier(t(Quals::Quals, Mods::Set, functionType(RetT::CPPType, ParamT::CPPTypes, MI::MethodInfo, L::LanguageLinkage, E::ExceptionSet)), RQ::RefQualifier)
          => t(Quals, Mods, functionType(RetT, ParamT, setMIRefQualifier(MI, RQ), L, E))

     syntax RefQualifier ::= getMIRefQualifier(MethodInfo) [function]
     rule getMIRefQualifier(methodInfo(... refQual: RQ::RefQualifier)) => RQ
     rule getMIRefQualifier(noMethod) => RefNone()
     syntax MethodInfo ::= setMIRefQualifier(MethodInfo, RefQualifier) [function]
     rule setMIRefQualifier(methodInfo(...) #as MI::MethodInfo, RQ::RefQualifier) => #fun(methodInfo(... refQual: _ => RQ))(MI)
     rule setMIRefQualifier(noMethod => defaultMethodInfo(), RQ::RefQualifier)

     rule getCVSQuals(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMICVSQuals(MI)
     rule setCVSQuals(t(Quals::Quals, Mods::Set, functionType(RetT::CPPType, ParamT::CPPTypes, MI::MethodInfo, L::LanguageLinkage, E::ExceptionSet)), CVS::Quals)
          => t(Quals, Mods, functionType(RetT, ParamT, setMICVSQuals(MI, CVS), L, E))

     syntax Quals ::= getMICVSQuals(MethodInfo) [function]
     rule getMICVSQuals(methodInfo(... cvQuals: CVS::Quals)) => CVS
     rule getMICVSQuals(noMethod) => noQuals
     syntax MethodInfo ::= setMICVSQuals(MethodInfo, Quals) [function]
     rule setMICVSQuals(methodInfo(...) #as MI::MethodInfo, CVS::Quals) => #fun(methodInfo(... cvQuals: _ => CVS))(MI)
     rule setMICVSQuals(noMethod => defaultMethodInfo(), CVS::Quals)
     
     rule isMethodStatic(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIStatic(MI)
     rule setMethodStatic(t(Quals::Quals, Mods::Set, functionType(RetT::CPPType, ParamT::CPPTypes, MI::MethodInfo, L::LanguageLinkage, E::ExceptionSet)))
          => t(Quals, Mods, functionType(RetT, ParamT, setMIStatic(MI), L, E))

     syntax Bool ::= getMIStatic(MethodInfo) [function]
     rule getMIStatic(methodInfo(... static: IsStatic::Bool)) => IsStatic
     rule getMIStatic(noMethod) => false
     syntax MethodInfo ::= setMIStatic(MethodInfo) [function]
     rule setMIStatic(methodInfo(...) #as MI::MethodInfo) => #fun(methodInfo(... static: _ => true))(MI)
     rule setMIStatic(noMethod => defaultMethodInfo())

     rule isMethodUserProvided(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIUserProvided(MI)
     rule setMethodUserProvided(t(Quals::Quals, Mods::Set, functionType(RetT::CPPType, ParamT::CPPTypes, MI::MethodInfo, L::LanguageLinkage, E::ExceptionSet)), B::Bool)
          => t(Quals, Mods, functionType(RetT, ParamT, setMIUserProvided(MI, B), L, E))

     syntax Bool ::= getMIUserProvided(MethodInfo) [function]
     rule getMIUserProvided(methodInfo(... userProvided: IsUserProvided::Bool)) => IsUserProvided
     rule getMIUserProvided(noMethod) => true
     syntax MethodInfo ::= setMIUserProvided(MethodInfo, Bool) [function]
     rule setMIUserProvided(methodInfo(...) #as MI::MethodInfo, UserProvided::Bool) => #fun(methodInfo(... userProvided: _ => UserProvided))(MI)
     rule setMIUserProvided(noMethod => defaultMethodInfo(), _)

     rule isMethodConstructor(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIConstructor(MI)
     rule setMethodConstructor(t(Quals::Quals, Mods::Set, functionType(RetT::CPPType, ParamT::CPPTypes, MI::MethodInfo, L::LanguageLinkage, E::ExceptionSet)), B::Bool)
          => t(Quals, Mods, functionType(RetT, ParamT, setMIConstructor(MI, B), L, E))

     syntax Bool ::= getMIConstructor(MethodInfo) [function]
     rule getMIConstructor(methodInfo(... constructor: IsConstructor::Bool)) => IsConstructor
     rule getMIConstructor(noMethod) => false
     syntax MethodInfo ::= setMIConstructor(MethodInfo, Bool) [function]
     rule setMIConstructor(methodInfo(...) #as MI::MethodInfo, IsConstructor::Bool) => #fun(methodInfo(... constructor: _ => IsConstructor))(MI)
     rule setMIConstructor(noMethod => defaultMethodInfo(), _)

     rule isMethodVirtual(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIVirtual(MI)
     rule setMethodVirtual(t(Quals::Quals, Mods::Set, functionType(RetT::CPPType, ParamT::CPPTypes, MI::MethodInfo, L::LanguageLinkage, E::ExceptionSet)))
          => t(Quals, Mods, functionType(RetT, ParamT, setMIVirtual(MI), L, E))

     syntax Bool ::= getMIVirtual(MethodInfo) [function]
     rule getMIVirtual(methodInfo(... virtual: IsVirtual::Bool)) => IsVirtual
     rule getMIVirtual(noMethod) => false
     syntax MethodInfo ::= setMIVirtual(MethodInfo) [function]
     rule setMIVirtual(methodInfo(...) #as MI::MethodInfo) => #fun(methodInfo(... virtual: _ => true))(MI)
     rule setMIVirtual(noMethod => defaultMethodInfo())

     rule isMethodExplicit(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIExplicit(MI)
     rule setMethodExplicit(t(Quals::Quals, Mods::Set, functionType(RetT::CPPType, ParamT::CPPTypes, MI::MethodInfo, L::LanguageLinkage, E::ExceptionSet)))
          => t(Quals, Mods, functionType(RetT, ParamT, setMIExplicit(MI), L, E))

     syntax Bool ::= getMIExplicit(MethodInfo) [function]
     rule getMIExplicit(methodInfo(... explicit: IsExplicit::Bool)) => IsExplicit
     rule getMIExplicit(noMethod) => false
     syntax MethodInfo ::= setMIExplicit(MethodInfo) [function]
     rule setMIExplicit(methodInfo(...) #as MI::MethodInfo) => #fun(methodInfo(... explicit: _ => true))(MI)
     rule setMIExplicit(noMethod => defaultMethodInfo())
     
     rule getMethodClass(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIClass(MI)
     rule setMethodClass(t(Quals::Quals, Mods::Set, functionType(RetT::CPPType, ParamT::CPPTypes, MI::MethodInfo, L::LanguageLinkage, E::ExceptionSet)), C::Class)
          => t(Quals, Mods, functionType(RetT, ParamT, setMIClass(MI, C), L, E))

     syntax Class ::= getMIClass(MethodInfo) [function]
     rule getMIClass(methodInfo(... class: C::Class)) => C
     syntax MethodInfo ::= setMIClass(MethodInfo, Class) [function]
     rule setMIClass(methodInfo(...) #as MI::MethodInfo, C::Class) => #fun(methodInfo(... class: _ => C))(MI)
     rule setMIClass(noMethod => defaultMethodInfo(), C::Class)

     rule const(T::CPPSimpleType) => t(toQuals(SetItem(Const())), .Set, T)

     rule type(T::CPPSimpleType) => t(noQuals, .Set, T)
     rule type(lv(_, _, T::CPPType)) => T
     rule type(le(_, _, T::CPPType)) => T
     rule type(prv(_, _, T::CPPType)) => T
     rule type(pre(_, _, T::CPPType)) => T
     rule type(xv(_, _, T::CPPType)) => T
     rule type(xe(_, _, T::CPPType)) => T

     rule innerType(t(_, _, T::CPPSimpleType)) => innerType(T)
     rule innerType(pointerType(T::CPPType)) => T
     rule innerType(arrayType(T::CPPType, _)) => T
     rule innerType(incompleteArrayType(T::CPPType)) => T
     rule innerType(lvRefType(T::CPPType)) => T
     rule innerType(rvRefType(T::CPPType)) => T

     rule simpleType(t(_, _, T::CPPSimpleType)) => T

     rule isObjectType(T:K) => notBool isCPPFunctionType(T) andBool notBool isCPPRefType(T) andBool notBool isCPPVoidType(T)

     rule utype(V::Val) => utype(type(V))
     rule utype(t(_, Mods::Set, T::CPPSimpleType)) => t(noQuals, Mods, T)

     rule isVolatileType(t(Q::Quals, _, _)) => Volatile() inQuals Q
     rule isConstType(t(Q::Quals, _, _)) => Const() inQuals Q

     rule getTag(t(_, _, classType(C::Class))) => getTag(C)
     rule getTag(_::CPPType) => .K [owise]

     rule getTag(_::ClassQualifier :: Class(Tag::Tag, _, _)) => Tag

     rule addQuals(Qs'::Quals, t(Qs::Quals, Mods::Set, T::CPPSimpleType))
          => t(Qs +Quals Qs', Mods, T)
     rule getQuals(t(Q::Quals, _, _)) => Q

     rule getClassInfo(t(... st: classType(C::Class))) => getClassInfo(C)
     rule getClassInfo(C::Class) => #getClassInfo(C, #configuration)
     rule #getClassInfo(C::Class, <generatedTop>... <curr-tu> Tu::String </curr-tu> <tu-id> Tu </tu-id> <class> <class-id> C </class-id> B::Bag </class> ...</generatedTop>) => <class> <class-id> C </class-id> B </class>
     rule #getClassInfo(_, _) => #incomplete [owise]

     rule isCompleteType(t(_, _, incompleteArrayType(_))) => false
     rule isCompleteType(T:CPPEnumType) => false //TODO(dwightguth): true in certain cases
     rule isCompleteType(T:CPPClassType) => getClassInfo(T) =/=K #incomplete
     rule isCompleteType(T:CPPArrayType) => false
          requires notBool isCompleteType(innerType(T))
     rule isCompleteType(t(_, _, void)) => false
     rule isCompleteType(_) => true [owise]

     rule isAggregateType(T:CPPArrayType) => true
     rule isAggregateType(T:CPPClassType) => isAggregateClass(getClassInfo(T))
     rule isAggregateType(_) => false [owise]
     syntax Bool ::= isAggregateClass(ClassInfo) [function]

     rule isAggregateClass(<class>... <is-aggregate> B::Bool </is-aggregate> ...</class>) => B

     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, signed-char)) => t(Q, Mods, unsigned-char)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, short)) => t(Q, Mods, unsigned-short)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, int)) => t(Q, Mods, unsigned)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, long)) => t(Q, Mods, unsigned-long)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, long-long)) => t(Q, Mods, unsigned-long-long)

     rule t(Q::Quals, _, T:CPPSimpleFundamentalType) ==Type t(Q, _, T) => true
     rule t(Q::Quals, _, pointerType(T1::CPPType)) ==Type t(Q, _, pointerType(T2::CPPType)) => T1 ==Type T2
     rule t(Q::Quals, _, arrayType(T1::CPPType, N::Int)) ==Type t(Q, _, arrayType(T2::CPPType, N)) => T1 ==Type T2
     rule t(Q::Quals, _, incompleteArrayType(T1::CPPType)) ==Type t(Q, _, incompleteArrayType(T2::CPPType)) => T1 ==Type T2
     rule t(Q::Quals, _, lvRefType(T1::CPPType)) ==Type t(Q, _, lvRefType(T2::CPPType)) => T1 ==Type T2
     rule t(Q::Quals, _, rvRefType(T1::CPPType)) ==Type t(Q, _, rvRefType(T2::CPPType)) => T1 ==Type T2
     rule t(Q::Quals, _, memberPointerType(C1::CPPClassType, T1::CPPType)) ==Type t(Q, _, memberPointerType(C2::CPPClassType, T2::CPPType)) => T1 ==Type T2 andBool C1 ==Type C2
     rule t(Q::Quals, _, functionType(R1::CPPType, P1::CPPTypes, MI1::MethodInfo,  _, _)) ==Type t(Q, _, functionType(R2::CPPType, P2::CPPTypes, MI2::MethodInfo, _, _)) => R1 ==Type R2 andBool toTemplateArgs(P1) ==Types toTemplateArgs(P2) andBool MI1 ==Type MI2

     syntax Bool ::= MethodInfo "==Type" MethodInfo [function]
     rule noMethod ==Type noMethod => true
     rule methodInfo(... refQual: RQ1::RefQualifier, cvQuals: CVS1::Quals) ==Type methodInfo(... refQual: RQ2::RefQualifier, cvQuals: CVS2::Quals) =>  RQ1 ==K RQ2 andBool CVS1 ==K CVS2
     rule methodInfo(... refQual: RQ::RefQualifier, cvQuals: Q::Quals) ==Type noMethod => RQ ==K RefNone() andBool Q ==K noQuals 
     rule noMethod ==Type methodInfo(... refQual: RQ::RefQualifier, cvQuals: Q::Quals) => RQ ==K RefNone() andBool Q ==K noQuals 

     rule t(Q::Quals, _, classType(N1::Namespace :: Class(T1::Tag, X1::CId, Ts1::TemplateArgs))) ==Type t(Q::Quals, _, classType(N2::Namespace :: Class(T2::Tag, X2::CId, Ts2::TemplateArgs))) => N1 ==K N2 andBool T1 ==K T2 andBool X1 ==K X2 andBool Ts1 ==Types Ts2
     syntax Bool ::= TemplateArgs "==Types" TemplateArgs [function]
     rule T1::CPPType, Ts1::TemplateArgs ==Types T2::CPPType, Ts2::TemplateArgs => T1 ==Type T2 andBool Ts1 ==Types Ts2
     rule .TemplateArgs ==Types .TemplateArgs => true
     rule t(Q1::Quals, _, T1::CPPSimpleType) ==Type t(Q2::Quals, _, T2::CPPSimpleType) => false
          requires Q1 =/=K Q2 orBool getKLabel(T1) =/=K getKLabel(T2)
     rule _ ==Types _ => false [owise]
     rule T1::CPPType =/=Type T2::CPPType => notBool (T1 ==Type T2)

     rule underlyingType(T::CPPSimpleType) => T [owise]
     rule underlyingType(t(Q::Quals, Mods::Set, T::CPPSimpleType))
          => t(Q, Mods, underlyingType(T))

     rule inRange(I:Int, T::CPPIntegerType)
          => I <=Int max(T) andBool I >=Int min(T)
     rule inRange(F:Float, T::CPPFloatingType)
          => F <=Float fmax(T) andBool F >=Float fmin(T)
     rule inRange(Loc:SymLoc, T::CPPIntegerType)
          => byteSizeofType(T) >=Int cfg:ptrsize

     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, signed-char))
          => t(Q, Mods, unsigned-char)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, short))
          => t(Q, Mods, unsigned-short)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, int))
          => t(Q, Mods, unsigned)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, long))
          => t(Q, Mods, unsigned-long)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, long-long))
          => t(Q, Mods, unsigned-long-long)

     rule min(T:CPPSignedType) => 0 -Int (1 <<Int ((byteSizeofType(T) *Int cfg:bitsPerByte) -Int 1))
     rule max(T:CPPSignedType) => (1 <<Int ((byteSizeofType(T) *Int cfg:bitsPerByte) -Int 1)) -Int 1

     rule min(_:CPPUnsignedType) => 0
     rule max(T:CPPUnsignedType) => (1 <<Int (byteSizeofType(T) *Int cfg:bitsPerByte)) -Int 1

     rule min(t(_, _, bool)) => 0
     rule max(t(_, _, bool)) => 1

     rule min(t(_, _, char)) => min(underlyingType(type(char)))
     rule max(t(_, _, char)) => max(underlyingType(type(char)))

     rule min(T:CPPWideCharType) => min(underlyingType(T))
     rule max(T:CPPWideCharType) => max(underlyingType(T))

     rule precision(t(_, _, float)) => cfg:precisionofFloat
     rule precision(t(_, _, double)) => cfg:precisionofDouble
     rule precision(t(_, _, long-double)) => cfg:precisionofLongDouble
     rule exponent(t(_, _, float)) => cfg:exponentofFloat
     rule exponent(t(_, _, double)) => cfg:exponentofDouble
     rule exponent(t(_, _, long-double)) => cfg:exponentofLongDouble

     rule fmax(T::CPPFloatingType) => maxValueFloat(precision(T), exponent(T))
     rule fmin(T::CPPFloatingType) => --Float fmax(T)

     rule isUnnamedLValue(T::CPPType)
          => isCPPLVRefType(T) orBool (isCPPRVRefType(T) andBool isCPPFunctionType(innerType(T)))
     rule isUnnamedXValue(T::CPPType)
          => isCPPRVRefType(T) andBool isObjectType(innerType(T))
     rule isUnnamedPRValue(T::CPPType) 
          => notBool isUnnamedLValue(T) andBool notBool isUnnamedXValue(T)
    
     rule isBaseClassOf(t(_, _, classType(B::Class)), t(_, _, classType(D::Class))) => isBaseClassOf(B, D)
     rule isBaseClassOf(B::Class, D::Class) => #isBaseClassOf(B, ListItem(D), #configuration)

     syntax Bool ::= #isBaseClassOf(base: Class, derived: List, K) [function]
     rule #isBaseClassOf(B::Class, ListItem(B) _, _) => true
     rule #isBaseClassOf(_, .List, _) => false
     rule #isBaseClassOf(B::Class, (ListItem(D::Class) => BC) _, 
            <generatedTop>... 
              <class-id> D </class-id>
              <base-classes> BC::List </base-classes>
            ...</generatedTop>)
         requires D =/=K B

     rule hasVirtualMembers(T::CPPClassType) => #hasVirtualMembers(getClassInfo(T))
     syntax Bool ::= #hasVirtualMembers(ClassInfo) [function]
     // TODO(dwightguth): non-virtual base classes
     rule #hasVirtualMembers(<class>... <base-classes> .List </base-classes> <function-members> ListItem(kpair(_, t(... st: functionType(... methodInfo: methodInfo(... virtual: true))))) ...</function-members> ...</class>) => true
     rule #hasVirtualMembers(<class>... <base-classes> .List </base-classes> <function-members> ListItem(_) => .List ...</function-members> ...</class>) [owise]
     rule #hasVirtualMembers(<class>... <base-classes> .List </base-classes> <function-members> .List </function-members> ...</class>) => false

     rule isUnionLikeClass(_ :: Class(Union(), _, _)) => true
     rule isUnionLikeClass(C::Class) => #isUnionLikeClass(getClassInfo(C)) [owise]
     syntax Bool ::= #isUnionLikeClass(ClassInfo) [function]
     rule #isUnionLikeClass(<class>... <variant-members> S::Set </variant-members> ...</class>) => size(S) >Int 0

     rule getMostDerivedArrayElement(T:CPPArrayType => innerType(T))
     rule getMostDerivedArrayElement(T::CPPType) => T [owise]

     rule setType(T::CPPType, lv(Loc::SymLoc, Tr::Trace, _)) => lv(Loc, Tr, T)
     rule setType(T::CPPType, prv(Loc::SymLoc, Tr::Trace, _)) => prv(Loc, Tr, T)

endmodule

module C-CPP-TYPING
     imports C-TYPING-SYNTAX
     imports CPP-TYPING
     imports SETTINGS-SYNTAX

     rule convertTypeToC(t(Q::Quals, Mods::Set, functionType(... returnType: Ret::CPPType, paramTypes: Args::CPPTypes, linkage: CLinkage))) => t(Q, Mods, functionType(utype(convertTypeToC(Ret)), mapList(toList(Args), #klabel(`convertTypeToC`))))
     rule convertTypeToC(t(Q::Quals, Mods::Set, void::CPPSimpleVoidType)) => t(Q, Mods, void::SimpleVoidType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, bool::CPPSimpleBoolType)) => t(Q, Mods, bool::SimpleBoolType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, signed-char::CPPSimpleSignedCharType)) => t(Q, Mods, signed-char::SimpleSignedCharType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-char::CPPSimpleUnsignedCharType)) => t(Q, Mods, unsigned-char::SimpleUnsignedCharType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, char::CPPSimpleCharType)) => t(Q, Mods, char::SimpleCharType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, short)) => t(Q, Mods, short-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-short)) => t(Q, Mods, unsigned-short-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, int::CPPSimpleSignedType)) => t(Q, Mods, int::SimpleSignedIntType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned)) => t(Q, Mods, unsigned-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, long)) => t(Q, Mods, long-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-long)) => t(Q, Mods, unsigned-long-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, long-long)) => t(Q, Mods, long-long-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-long-long)) => t(Q, Mods, unsigned-long-long-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, float::CPPSimpleFloatingType)) => t(Q, Mods, float::SimpleFloatType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, double::CPPSimpleFloatingType)) => t(Q, Mods, double::SimpleFloatType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, long-double::CPPSimpleFloatingType)) => t(Q, Mods, long-double::SimpleFloatType)
     rule convertTypeToC(variadic::CPPVariadic) => variadic::Variadic
     rule convertTypeToC(t(Q::Quals, Mods::Set, pointerType(T::CPPType))) => t(Q, Mods, pointerType(convertTypeToC(T)))
     rule convertTypeToC(t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int))) => t(Q, Mods, arrayType(convertTypeToC(T), N))


     rule convertTypeToCPP(t(Q::Quals, Mods::Set, pointerType(T::Type))) => t(Q, Mods, pointerType(convertTypeToCPP(T)))
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, void::SimpleVoidType)) => t(Q, Mods, void::CPPSimpleVoidType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, bool::SimpleBoolType)) => t(Q, Mods, bool::CPPSimpleBoolType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, signed-char::SimpleSignedCharType)) => t(Q, Mods, signed-char::CPPSimpleSignedCharType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-char::SimpleUnsignedCharType)) => t(Q, Mods, unsigned-char::CPPSimpleUnsignedCharType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, char::SimpleCharType)) => t(Q, Mods, char::CPPSimpleCharType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, short-int)) => t(Q, Mods, short)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-short-int)) => t(Q, Mods, unsigned-short)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, int::SimpleSignedIntType)) => t(Q, Mods, int::CPPSimpleSignedType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-int)) => t(Q, Mods, unsigned)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, long-int)) => t(Q, Mods, long)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-long-int)) => t(Q, Mods, unsigned-long)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, long-long-int)) => t(Q, Mods, long-long)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-long-long-int)) => t(Q, Mods, unsigned-long-long)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, float::SimpleFloatType)) => t(Q, Mods, float::CPPSimpleFloatingType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, double::SimpleFloatType)) => t(Q, Mods, double::CPPSimpleFloatingType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, long-double::SimpleFloatType)) => t(Q, Mods, long-double::CPPSimpleFloatingType)
 
endmodule
