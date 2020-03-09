module CPP-TYPING-SORTS
     syntax AType

     syntax CPPType

     syntax CPPDType ::= CPPType | CPPVariadic | InitListType | NoInitType

     syntax CPPVariadic

     syntax InitListType

     syntax NoInitType

     syntax CPPSimpleType

     syntax EffectiveType ::= CPPType

     syntax CPPTypes ::= List{CPPDType, ","}

     syntax ExceptionSet

     syntax ClassInfo

     syntax IncompleteInfo

     syntax TemplateInfo

     syntax MethodInfo

     syntax RValue
endmodule

module CPP-DEPENDENT-SYNTAX
     syntax StrictList ::= typeStrict(StrictList)
endmodule

module CPP-TYPING-SYNTAX
     imports BASIC-K
     imports SET
     imports STRING-SYNTAX
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS
     imports SYMLOC-SORTS

     syntax AType ::= CPPType

     syntax CPPType ::= t(q: Quals, m: Set, st: CPPSimpleType) [klabel(tcpp)]

     syntax CPPType ::= innerType(CPPType) [function, klabel(cppInnerType)]

     syntax CPPType ::= innerType(CPPSimpleType) [function, klabel(innerTypeOfSimpleType)]

     syntax CPPSimpleType ::= simpleType(CPPType) [function, klabel(cppSimpleType)]

     syntax CPPSimpleType ::= underlyingType(CPPSimpleType) [function, klabel(underlyingSimpleType)]

     syntax CPPType ::= underlyingType(CPPType) [function]

     // removes all syntax not part of the type of the entity.
     syntax CPPType ::= stripType(CPPType) [function]

     syntax CPPSimpleIntegerType ::= CPPSimpleSignedType
                                   | CPPSimpleUnsignedType
                                   | CPPSimpleCharType
                                   | CPPSimpleBoolType
                                   | CPPSimpleWideCharType

     syntax CPPSimpleFundamentalType ::= CPPSimpleIntegerType
                                       | CPPSimpleFloatingType
                                       | CPPSimpleVoidType
                                       | CPPSimpleNullPtrTType

     syntax CPPSimpleType ::= CPPSimpleFundamentalType
                            | CPPSimpleCompoundType
                            | CPPSimpleBitfieldType
                            | CPPSimpleDependentType
                            | CPPSimpleAutoType

     syntax CPPSimpleSignedType ::= bitfieldType(CPPSimpleSignedType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleUnsignedType ::= bitfieldType(CPPSimpleUnsignedType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleSignedCharType ::= bitfieldType(CPPSimpleSignedCharType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleUnsignedCharType ::= bitfieldType(CPPSimpleUnsignedCharType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleBoolType ::= bitfieldType(CPPSimpleBoolType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleWideCharType ::= bitfieldType(CPPSimpleWideCharType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleScopedEnumType ::= bitfieldType(CPPSimpleScopedEnumType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleUnscopedEnumType ::= bitfieldType(CPPSimpleUnscopedEnumType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleBitfieldType ::= bitfieldType(CPPSimpleType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleSignedType ::= CPPSimpleBottomType
     syntax CPPSimpleUnsignedType ::= CPPSimpleBottomType
     syntax CPPSimpleSignedCharType ::= CPPSimpleBottomType
     syntax CPPSimpleUnsignedCharType ::= CPPSimpleBottomType
     syntax CPPSimpleBoolType ::= CPPSimpleBottomType
     syntax CPPSimpleWideCharType ::= CPPSimpleBottomType
     syntax CPPSimpleScopedEnumType ::= CPPSimpleBottomType
     syntax CPPSimpleUnscopedEnumType ::= CPPSimpleBottomType
     syntax CPPSimpleBitfieldType ::= CPPSimpleBottomType

     syntax CPPSimpleBottomType ::= bitfieldType(CPPSimpleBottomType, Int) [klabel(bitfieldTypeCpp)]

     syntax CPPSimpleSignedType ::= CPPSimpleSignedCharType | "short" | "int" | "long" | "long-long" | "oversized"

     syntax CPPSimpleUnsignedType ::= CPPSimpleUnsignedCharType | "unsigned-short" | "unsigned" | "unsigned-long" | "unsigned-long-long"
                                    | "unsigned-oversized"

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

     syntax CPPSimpleArrayType ::= CPPSimpleFixedArrayType | CPPSimpleIncompleteArrayType
                                 | dynamicArrayType(CPPType, Expr)

     syntax CPPSimpleFixedArrayType ::= arrayType(CPPType, Int) [klabel(cppArrayType)]

     syntax CPPSimpleIncompleteArrayType ::= incompleteArrayType(CPPType) [klabel(cppIncompleteArrayType)]

     syntax CPPSimplePointerType ::= pointerType(CPPType) [klabel(cppPointerType)]

     syntax CPPSimpleMemberPointerType ::= memberPointerType(CPPType, CPPType)

     syntax CPPSimpleLVRefType ::= lvRefType(CPPType)

     syntax CPPSimpleRVRefType ::= rvRefType(CPPType)

     syntax CPPSimpleFunctionType ::= functionType(returnType: CPPType, paramTypes: CPPTypes, methodInfo: MethodInfo, linkage: LanguageLinkage, exceptions: ExceptionSet) [klabel(cppFunctionType)]

     syntax Int ::= paramCount(CPPSimpleFunctionType) [function]

     syntax CPPSimpleClassType ::= classType(Class)

     syntax CPPSimpleDependentType ::= dependentType(String, Int)

     syntax CPPSimpleAutoType ::= "auto"
                                | "decltype(auto)"

     syntax CPPSimpleScopedEnumType ::= scopedEnum(id: Enum, underlyingType: CPPType)

     syntax CPPSimpleUnscopedEnumType ::= unscopedEnum(id: Enum, underlyingType: CPPType, utFixed: Bool)

     syntax CPPSimpleEnumType ::= CPPSimpleScopedEnumType | CPPSimpleUnscopedEnumType

     syntax CPPSimpleCompoundType ::= CPPSimpleEnumType

     syntax CPPVariadic ::= "variadic"

     syntax InitListType ::= initListType(List)

     syntax NoInitType ::= NoInitType()

     syntax CPPType ::= "cppIntegerType"
                      | "cppEnumType"
                      | "cppRefType"
                      | "cppFundamentalType"
                      | "cppScalarType"

     rule cppIntegerType => t(_, _, signed-char #Or unsigned-char #Or char #Or bool #Or short #Or int #Or long #Or long-long #Or oversized #Or unsigned-short #Or unsigned #Or unsigned-long #Or unsigned-long-long #Or unsigned-oversized #Or wchar_t #Or char16_t #Or char32_t #Or bitfieldType(signed-char #Or unsigned-char #Or char #Or bool #Or short #Or int #Or long #Or long-long #Or oversized #Or unsigned-short #Or unsigned #Or unsigned-long #Or unsigned-long-long #Or unsigned-oversized #Or wchar_t #Or char16_t #Or char32_t, _)) [macro, unboundVariables(_)]
     rule cppEnumType => t(_, _, scopedEnum(_, _) #Or unscopedEnum(_, _, _) #Or bitfieldType(scopedEnum(_, _) #Or unscopedEnum(_, _, _), _)) [macro, unboundVariables(_)]
     rule cppRefType => t(_, _, lvRefType(_) #Or rvRefType(_)) [macro, unboundVariables(_)]
     rule cppFundamentalType => cppIntegerType #Or t(_, _, void #Or nullptr_t #Or float #Or double #Or long-double) [macro, unboundVariables(_)]
     rule cppScalarType => cppIntegerType #Or cppEnumType #Or t(_, _, float #Or double #Or long-double #Or pointerType(_) #Or memberPointerType(_, _) #Or nullptr_t) [macro, unboundVariables(_)]

     syntax Bool ::= isCPPVoidType(CPPDType) [function]
                   | isCPPUnsignedType(CPPDType) [function]
                   | isCPPUnscopedEnumType(CPPDType) [function]
                   | isCPPSignedType(CPPDType) [function]
                   | isCPPScopedEnumType(CPPDType) [function]
                   | isCPPRefType(CPPDType) [function]
                   | isCPPRVRefType(CPPDType) [function]
                   | isCPPPointerType(CPPDType) [function]
                   | isCPPNullPtrTType(CPPDType) [function]
                   | isCPPMemberPointerType(CPPDType) [function]
                   | isCPPMemberFunctionPointerType(CPPDType) [function]
                   | isCPPLVRefType(CPPDType) [function]
                   | isCPPIntegerType(CPPDType) [function]
                   | isCPPFunctionType(CPPDType) [function]
                   | isCPPFloatingType(CPPDType) [function]
                   | isCPPEnumType(CPPDType) [function]
                   | isCPPClassType(CPPDType) [function]
                   | isCPPBoolType(CPPDType) [function]
                   | isCPPBitfieldType(CPPDType) [function]
                   | isCPPArrayType(CPPDType) [function]
                   | isCPPArithmeticType(CPPDType) [function]
                   | isCPPWideCharType(CPPDType) [function]
                   | isCPPCharType(CPPDType) [function]

     syntax Expr ::= setType(CPPType, Expr) [strict(c; 2)]

     syntax Quals ::= getQuals(CPPType) [function]

     syntax CPPType ::= addQuals(Quals, CPPType) [function]

     syntax Bool ::= isAdjustedType(CPPType) [function]

     syntax CPPType ::= adjustFunctionType(CPPType) [function]

     syntax CPPType ::= setMethod(CPPType) [function]

     syntax Bool ::= isFunctionMember(CPPType) [function]
                   | hasImplicitParameter(CPPType) [function]

     syntax List ::= getParams(CPPType) [function, klabel(cppgetParams)]
                   | getRealParams(CPPType) [function]

     syntax RefQualifier ::= getRefQualifier(CPPType) [function]

     syntax CPPType ::= setRefQualifier(CPPType, RefQualifier) [function]

     syntax Quals ::= getCVSQuals(CPPType) [function]

     syntax CPPType ::= setCVSQuals(CPPType, Quals) [function]

     syntax Bool ::= isMethodStatic(CPPType) [function]

     syntax CPPType ::= setMethodStatic(CPPType) [function]

     syntax Bool ::= isMethodVirtual(CPPType) [function]

     syntax CPPType ::= setMethodVirtual(CPPType) [function]

     syntax Bool ::= isMethodPure(CPPType) [function]

     syntax CPPType ::= setMethodPure(CPPType) [function]

     syntax Bool ::= isMethodExplicit(CPPType) [function]

     syntax CPPType ::= setMethodExplicit(CPPType) [function]

     syntax Bool ::= isMethodUserProvided(CPPType) [function]

     syntax CPPType ::= setMethodUserProvided(CPPType, Bool) [function]

     syntax Bool ::= isMethodConstructor(CPPType) [function]

     syntax CPPType ::= setMethodConstructor(CPPType, Bool) [function]

     syntax Class ::= getMethodClass(CPPType) [function]

     syntax CPPType ::= setMethodClass(CPPType, Class) [function]

     syntax Bool ::= isVariadicFunction(CPPType) [function]

     syntax CPPType ::= getReturnType(CPPType) [function, klabel(cppgetReturnType)]

     syntax Bool ::= acceptsNArgs(Int, CPPType, List) [function]

     syntax CPPType ::= const(CPPSimpleType) [function, klabel(constCpp)]
                      | const(CPPType) [function, klabel(constCpp2)]
                      | volatile(CPPSimpleType) [function, klabel(volatileCpp)]
                      | volatile(CPPType) [function, klabel(volatileCpp2)]

     syntax CPPType ::= type(CPPSimpleType) [function, klabel(cppType)]

     syntax CPPType ::= utype(Typed) [function, klabel(cppUTypeVal)]

     syntax CPPType ::= type(Typed) [function, klabel(cppTypeVal)]

     syntax CPPType ::= utype(CPPType) [function, klabel(cppUTypeType)]

     syntax Bool ::= isObjectType(K) [function]
                   | isPointerToObjectType(CPPType) [function]
                   | isPointerToFunctionType(CPPType) [function]
                   | isCompleteType(CPPType) [function, klabel(isCompleteTypeCPP)]
                   | isAggregateType(CPPType) [function, klabel(isAggregateTypeCPP)]
                   | isVolatileType(CPPType) [function, klabel(isVolatileTypeCPP)]
                   | isConstType(CPPType) [function, klabel(isConstTypeCPP)]
                   | isStdInitializerList(CPPType) [function]

     syntax Type ::= convertTypeToC(CPPType) [function]

     syntax ParamDecl ::= convertDTypeToC(CPPDType) [function]

     syntax CPPType ::= convertTypeToCPP(Type) [function]

     syntax CPPDType ::= convertDTypeToCPP(ParamDecl) [function]

     syntax CPPType ::= correspondingUnsignedType(CPPType) [function, klabel(correspondingUnsignedTypeCpp)]

     syntax Int ::= max(CPPType) [function, klabel(maxCpp)]
                  | min(CPPType) [function, klabel(minCpp)]
                  | precision(CPPType) [function]
                  | exponent(CPPType) [function]

     syntax Float ::= fmax(CPPType) [function, klabel(fmaxCpp)]
                    | fmin(CPPType) [function, klabel(fminCpp)]

     syntax Bool ::= inRange(CPPValue, CPPType) [function, klabel(inRangeCpp)]

     syntax Tag ::= getTag(CPPType) [function, klabel(getTagCpp)]

     syntax Tag ::= getTag(Class) [function, klabel(getClassTag)]

     syntax MethodInfo ::= "noMethod"
                         | methodInfo(refQual: RefQualifier, cvQuals: Quals, static: Bool, virtual:Bool, pure: Bool, explicit: Bool, class: K, userProvided: Bool, constructor: Bool)
                         | defaultMethodInfo() [function]

     syntax CPPDType ::= implicitObjectParameter(CPPType)

     syntax CPPType ::= implicitObjectParameterType(CPPType) [function]

     syntax Expr ::= getBaseClassSubobject(base: LVal, baseType: CPPType) [strict(c; 1)]

     syntax Bool ::= isBaseClassOf(base: CPPType, derived: CPPType) [function]
                   | isVirtualBaseClassOf(CPPType, CPPType) [function]
                   | isBaseClassOf(base: Class, derived: Class) [function, klabel(isClassBaseClassOf)]
                   | isProperBaseClassOf(base: CPPType, derived: CPPType) [function]
                   | isProperBaseClassOf(base: Class, derived: Class) [function, klabel(isClassProperBaseClassOf)]
                   | isDirectBaseClassOf(base: Class, derived: Class) [function]
                   | hasVirtualMembers(Class) [function, klabel(hasVirtualMembersCl)]
                   | hasVirtualMembers(CPPType) [function]
                   | isUnionLikeClass(Class) [function]
                   | isVirtualCall(Trace, CPPType) [function]

     syntax CPPType ::= getMostDerivedArrayElement(CPPType) [function]

     syntax IncompleteInfo ::= "#incomplete"

     syntax EnumInfo ::= getEnumInfo(CPPType) [function]
                       | #getEnumInfo(Enum) [function]

     syntax CppenumCell
     syntax EnumInfo ::= CppenumCell | IncompleteInfo

     syntax Bool ::= CPPType "==Type" CPPType [function]
                   | CPPType "=/=Type" CPPType [function]

     syntax Bool ::= overrides(CPPType, CPPType) [function]

     syntax ExceptionSet ::= exSet(Set) | "noexcept(true)" | "noexcept(false)"

     syntax KResult ::= ExceptionSet

     syntax ExceptionSpec ::= ExceptionSet

     syntax Bool ::= isUnnamedLValue(CPPType) [function]
                   | isUnnamedXValue(CPPType) [function]
                   | isUnnamedPRValue(CPPType) [function]

     syntax DefaultArgumentsResult ::= emptyDefaultArguments(CPPType) [function]

     syntax Enum ::= getEnumId(CPPType) [function]

     syntax Bool ::= isEnumScoped(CPPType) [function]
                   | isEnumFixed(CPPType) [function]

     // Intended to use only when the derived class
     // has only one such base.
     syntax Int ::= getBaseClassOffset(base: Class, derived: Class) [function]

endmodule

module CPP-TYPING
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports FLOAT
     imports LIST
     imports K-REFLECTION
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX

     rule paramCount(functionType(... paramTypes: Ts::CPPTypes)) => CPPTypesSize(Ts)

     rule getParams(t(_, _, functionType(... paramTypes: L::CPPTypes, methodInfo: noMethod))) => toList(L)

     rule getParams(t(_, _, functionType(... paramTypes: L::CPPTypes, methodInfo: methodInfo(... constructor: true)))) => toList(L)

     rule getParams(t(_, _, functionType(... paramTypes: L::CPPTypes, methodInfo: methodInfo(RQ::RefQualifier, CVS::Quals, IsStatic::Bool, _, _, _, C::Class, _, false)))) => ListItem(implicitObjectParameter(getImpliedParamType(RQ, CVS, IsStatic, C))) toList(L)

     rule getRealParams(T::CPPType) => #getRealParams(getParams(T))

     rule getReturnType(t(_, _, functionType(... returnType: T::CPPType))) => T

     rule isVariadicFunction(T::CPPType) => size(getParams(T)) =/=Int size(getRealParams(T))

     rule implicitObjectParameterType(T::CPPType)
          => {#fun((implicitObjectParameter(T2::CPPType) => T2))(getParams(T)[0])}:>CPPType

     syntax List ::= #getRealParams(List) [function]

     rule #getRealParams(L::List ListItem(variadic)) => L

     rule #getRealParams(L::List) => L [owise]

     // 13.3.2:2.1
     rule acceptsNArgs(M::Int, T::CPPType, _) => true
          requires size(getRealParams(T)) ==Int M

     // 13.3.2:2.2
     rule acceptsNArgs(M::Int, T::CPPType, _) => isVariadicFunction(T)
          requires size(getRealParams(T)) <Int M

     // 13.3.2:2.3
     rule acceptsNArgs(M::Int, T::CPPType, DArgs::List)
          => notBool isNoArg(DArgs[#if hasImplicitParameter(T) #then M -Int 1 #else M #fi])
          requires size(getRealParams(T)) >Int M

     // members cannot be C linkage
     rule setMethod(T::CPPType) => #fun(t(... st: functionType(... linkage: L::LanguageLinkage => #if L ==K CLinkage #then CPPLinkage #else L #fi)))(T)

     rule isFunctionMember(t(... st: functionType(... methodInfo: methodInfo(...)))) => true

     rule isFunctionMember(_) => false [owise]

     rule hasImplicitParameter(t(_, _, functionType(... methodInfo: methodInfo(... constructor: IsConstructor:Bool)))) => notBool IsConstructor

     rule hasImplicitParameter(_) => false [owise]

     // TODO(traiansf): Handle conversion functions and functions introduced by using declarations
     syntax CPPType ::= getImpliedParamType(RefQualifier, Quals, static: Bool, Class) [function]

     // 13.3.1:4
     rule getImpliedParamType(... static: true) => type(no-type)

     // 13.3.1:4.2
     rule getImpliedParamType(RefRValue(), Q::Quals, false, C::Class) => type( rvRefType(t(Q, .Set, classType(C))))

     // 13.3.1:4.1
     rule getImpliedParamType(_, Q::Quals, false, C::Class) => type(lvRefType(t(Q, .Set, classType(C)))) [owise]

     rule defaultMethodInfo() => methodInfo(RefNone(), noQuals, false, false, false, false, .K, true, false)

     rule getRefQualifier(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIRefQualifier(MI)

     rule setRefQualifier(T::CPPType, RQ::RefQualifier)
       => #fun(t(... st: functionType(... methodInfo: MI::MethodInfo => setMIRefQualifier(MI, RQ))))(T)

     syntax RefQualifier ::= getMIRefQualifier(MethodInfo) [function]

     rule getMIRefQualifier(methodInfo(... refQual: RQ::RefQualifier)) => RQ

     rule getMIRefQualifier(noMethod) => RefNone()

     syntax MethodInfo ::= setMIRefQualifier(MethodInfo, RefQualifier) [function]

     rule setMIRefQualifier(methodInfo(...) #as MI::MethodInfo, RQ::RefQualifier) => #fun(methodInfo(... refQual: _ => RQ))(MI)

     rule setMIRefQualifier(noMethod => defaultMethodInfo(), RQ::RefQualifier)

     rule getCVSQuals(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMICVSQuals(MI)

     rule setCVSQuals(T::CPPType, CVS::Quals)
       => #fun(t(... st: functionType(... methodInfo: MI::MethodInfo => setMICVSQuals(MI, CVS))))(T)

     syntax Quals ::= getMICVSQuals(MethodInfo) [function]

     rule getMICVSQuals(methodInfo(... cvQuals: CVS::Quals)) => CVS

     rule getMICVSQuals(noMethod) => noQuals

     syntax MethodInfo ::= setMICVSQuals(MethodInfo, Quals) [function]

     rule setMICVSQuals(methodInfo(...) #as MI::MethodInfo, CVS::Quals) => #fun(methodInfo(... cvQuals: _ => CVS))(MI)

     rule setMICVSQuals(noMethod => defaultMethodInfo(), CVS::Quals)

     rule isMethodStatic(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIStatic(MI)

     rule setMethodStatic(T::CPPType)
      => #fun(t(... st: functionType(... methodInfo: MI::MethodInfo => setMIStatic(MI))))(T)

     syntax Bool ::= getMIStatic(MethodInfo) [function]

     rule getMIStatic(methodInfo(... static: IsStatic::Bool)) => IsStatic

     rule getMIStatic(noMethod) => false

     syntax MethodInfo ::= setMIStatic(MethodInfo) [function]

     rule setMIStatic(methodInfo(...) #as MI::MethodInfo) => #fun(methodInfo(... static: _ => true))(MI)

     rule setMIStatic(noMethod => defaultMethodInfo())

     rule isMethodUserProvided(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIUserProvided(MI)

     rule setMethodUserProvided(T::CPPType, B::Bool)
       => #fun(t(... st: functionType(... methodInfo: MI::MethodInfo => setMIUserProvided(MI, B))))(T)

     syntax Bool ::= getMIUserProvided(MethodInfo) [function]

     rule getMIUserProvided(methodInfo(... userProvided: IsUserProvided::Bool)) => IsUserProvided

     rule getMIUserProvided(noMethod) => true

     syntax MethodInfo ::= setMIUserProvided(MethodInfo, Bool) [function]

     rule setMIUserProvided(methodInfo(...) #as MI::MethodInfo, UserProvided::Bool) => #fun(methodInfo(... userProvided: _ => UserProvided))(MI)

     rule setMIUserProvided(noMethod => defaultMethodInfo(), _)

     rule isMethodConstructor(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIConstructor(MI)

     rule setMethodConstructor(T::CPPType, B::Bool)
       => #fun(t(... st: functionType(... methodInfo: MI::MethodInfo => setMIConstructor(MI, B))))(T)

     syntax Bool ::= getMIConstructor(MethodInfo) [function]

     rule getMIConstructor(methodInfo(... constructor: IsConstructor::Bool)) => IsConstructor

     rule getMIConstructor(noMethod) => false

     syntax MethodInfo ::= setMIConstructor(MethodInfo, Bool) [function]

     rule setMIConstructor(methodInfo(...) #as MI::MethodInfo, IsConstructor::Bool) => #fun(methodInfo(... constructor: _ => IsConstructor))(MI)

     rule setMIConstructor(noMethod => defaultMethodInfo(), _)

     rule isMethodVirtual(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIVirtual(MI)

     rule setMethodVirtual(T::CPPType)
          => #fun(t(... st: functionType(... methodInfo: MI::MethodInfo => setMIVirtual(MI))))(T)

     syntax Bool ::= getMIVirtual(MethodInfo) [function]

     rule getMIVirtual(methodInfo(... virtual: IsVirtual::Bool)) => IsVirtual

     rule getMIVirtual(noMethod) => false

     syntax MethodInfo ::= setMIVirtual(MethodInfo) [function]

     rule setMIVirtual(methodInfo(...) #as MI::MethodInfo) => #fun(methodInfo(... virtual: _ => true))(MI)

     rule setMIVirtual(noMethod => defaultMethodInfo())

     rule isMethodPure(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIPure(MI)

     rule setMethodPure(T::CPPType)
          => #fun(t(... st: functionType(... methodInfo: MI::MethodInfo => setMIPure(MI))))(T)

     syntax Bool ::= getMIPure(MethodInfo) [function]

     rule getMIPure(methodInfo(... pure: IsPure::Bool)) => IsPure

     rule getMIPure(noMethod) => false

     syntax MethodInfo ::= setMIPure(MethodInfo) [function]

     rule setMIPure(methodInfo(...) #as MI::MethodInfo) => #fun(methodInfo(... pure: _ => true))(MI)

     rule setMIPure(noMethod => defaultMethodInfo())

     rule isMethodExplicit(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIExplicit(MI)

     rule setMethodExplicit(T::CPPType)
          => #fun(t(... st: functionType(... methodInfo: MI::MethodInfo => setMIExplicit(MI))))(T)

     syntax Bool ::= getMIExplicit(MethodInfo) [function]

     rule getMIExplicit(methodInfo(... explicit: IsExplicit::Bool)) => IsExplicit

     rule getMIExplicit(noMethod) => false

     syntax MethodInfo ::= setMIExplicit(MethodInfo) [function]

     rule setMIExplicit(methodInfo(...) #as MI::MethodInfo) => #fun(methodInfo(... explicit: _ => true))(MI)

     rule setMIExplicit(noMethod => defaultMethodInfo())

     rule getMethodClass(t(... st: functionType(... methodInfo: MI::MethodInfo))) => getMIClass(MI)

     rule setMethodClass(T::CPPType, C::Class)
          => #fun(t(... st: functionType(... methodInfo: MI::MethodInfo => setMIClass(MI, C))))(T)

     syntax Class ::= getMIClass(MethodInfo) [function]

     rule getMIClass(methodInfo(... class: C::Class)) => C

     syntax MethodInfo ::= setMIClass(MethodInfo, Class) [function]

     rule setMIClass(methodInfo(...) #as MI::MethodInfo, C::Class) => #fun(methodInfo(... class: _ => C))(MI)

     rule setMIClass(noMethod => defaultMethodInfo(), C::Class)

     rule const(T::CPPSimpleType) => t(toQuals(SetItem(Const())), .Set, T)

     rule const(T::CPPType) => addQuals(toQuals(SetItem(Const())), T)

     rule volatile(T::CPPSimpleType) => t(toQuals(SetItem(Volatile())), .Set, T)

     rule volatile(T::CPPType) => addQuals(toQuals(SetItem(Volatile())), T)

     rule type(T::CPPSimpleType) => t(noQuals, .Set, T)

     rule type(lv(_, _, T::CPPType)) => T

     rule type(le(_, _, T::CPPType)) => T

     rule type(prv(_, _, T::CPPType)) => T

     rule type(pre(_, _, T::CPPType)) => T

     rule type(xv(_, _, T::CPPType)) => T

     rule type(xe(_, _, T::CPPType)) => T

     rule innerType(t(_, _, T::CPPSimpleType)) => innerType(T)
          requires notBool isCPPSimpleBitfieldType(T)

     rule innerType(t(Q::Quals, Mods::Set, bitfieldType(T::CPPSimpleType, _))) => t(Q, Mods, T)

     rule innerType(pointerType(T::CPPType)) => T

     rule innerType(arrayType(T::CPPType, _)) => T

     rule innerType(incompleteArrayType(T::CPPType)) => T

     rule innerType(dynamicArrayType(T::CPPType, _)) => T

     rule innerType(lvRefType(T::CPPType)) => T

     rule innerType(rvRefType(T::CPPType)) => T

     rule simpleType(t(_, _, T::CPPSimpleType)) => T

     rule isObjectType(T::CPPType) => notBool isCPPFunctionType(T) andBool notBool isCPPRefType(T) andBool notBool isCPPVoidType(T)

     rule isPointerToObjectType(T::CPPType)
          => isCPPPointerType(T) andBool isObjectType(innerType(T))

     rule isPointerToFunctionType(T::CPPType)
          => isCPPPointerType(T) andBool isCPPFunctionType(innerType(T))

     rule utype(V::Val) => utype(type(V))

     rule utype(t(_, Mods::Set, T::CPPSimpleType)) => t(noQuals, Mods, T)

     rule isVolatileType(t(Q::Quals, _, _)) => Volatile() inQuals Q

     rule isConstType(t(Q::Quals, _, _)) => Const() inQuals Q

     rule isStdInitializerList(t(... st: classType(GlobalNamespace() :: Namespace(Identifier("std")) :: Class(Class(), Identifier("initializer_list"), _)))) => true

     rule isStdInitializerList(...) => false [owise]

     rule getTag(t(_, _, classType(C::Class))) => getTag(C)

     rule getTag(_::ClassQualifier :: Class(Tag::Tag, _, _)) => Tag

     rule addQuals(Qs'::Quals, t(Qs::Quals, Mods::Set, T::CPPSimpleType))
          => t(Qs +Quals Qs', Mods, T)

     rule getQuals(t(Q::Quals, _, _)) => Q

     rule getEnumInfo(E::CPPType) => #getEnumInfo(getEnumId(E))

     rule [[ #getEnumInfo(X::Enum) => <cppenum> <enum-id> X </enum-id> B </cppenum> ]]
          <cppenum> <enum-id> X </enum-id> B::Bag </cppenum>

     rule #getEnumInfo(_) => #incomplete [owise]

     rule isCompleteType(t(_, _, incompleteArrayType(_))) => false

     rule isCompleteType(cppEnumType #as T::CPPType) => getEnumInfo(T) =/=K #incomplete //TODO(h0nzZik): false in 7.2, par 6

     rule isCompleteType(t(... st: classType(...)) #as T::CPPType) => getClassInfo(T) =/=K #incomplete

     rule isCompleteType(t(... st: _:CPPSimpleArrayType) #as T::CPPType) => false
          requires notBool isCompleteType(innerType(T))

     rule isCompleteType(t(_, _, void)) => false

     rule isCompleteType(_) => true [owise]

     rule isAggregateType(t(... st: _:CPPSimpleArrayType) #as T::CPPType) => true

     rule isAggregateType(t(... st: classType(...)) #as T::CPPType) => isAggregateClass(getClassInfo(T))

     rule isAggregateType(_) => false [owise]

     syntax Bool ::= isAggregateClass(ClassInfo) [function]

     rule isAggregateClass(<class>... <is-aggregate> B::Bool </is-aggregate> ...</class>) => B

     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, signed-char)) => t(Q, Mods, unsigned-char)

     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, short)) => t(Q, Mods, unsigned-short)

     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, int)) => t(Q, Mods, unsigned)

     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, long)) => t(Q, Mods, unsigned-long)

     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, long-long)) => t(Q, Mods, unsigned-long-long)

     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, oversized)) => t(Q, Mods, unsigned-oversized)

     rule stripType(t(Q::Quals, _, T:CPPSimpleFundamentalType)) => t(Q, .Set, T)

     rule stripType(t(_, _, bitfieldType(T::CPPSimpleType, _) => T))

     rule stripType(t(Q::Quals, _, pointerType(T::CPPType))) => t(Q, .Set, pointerType(stripType(T)))

     rule stripType(t(Q::Quals, _, arrayType(T::CPPType, N::Int))) => t(Q, .Set, arrayType(stripType(T), N))

     rule stripType(t(Q::Quals, _, incompleteArrayType(T::CPPType))) => t(Q, .Set, incompleteArrayType(stripType(T)))

     rule stripType(t(Q::Quals, _, lvRefType(T::CPPType))) => t(Q, .Set, lvRefType(stripType(T)))

     rule stripType(t(Q::Quals, _, rvRefType(T::CPPType))) => t(Q, .Set, rvRefType(stripType(T)))

     rule stripType(t(Q::Quals, _, memberPointerType(C::CPPType, T::CPPType))) => t(Q, .Set, memberPointerType(stripType(C), stripType(T)))

     rule stripType(t(Q::Quals, _, functionType(Ret::CPPType, Params::CPPTypes, MI::MethodInfo, L::LanguageLinkage, _))) => t(Q, .Set, functionType(stripType(Ret), toCPPTypes(stripTypes(toTemplateArgs(Params))), stripMI(MI), L, noexcept(false)))

     syntax MethodInfo ::= stripMI(MethodInfo) [function]

     rule stripMI(noMethod) => defaultMethodInfo()

     rule stripMI(methodInfo(... refQual: RQ::RefQualifier, cvQuals: CVS::Quals)) => #fun(methodInfo(... refQual: _ => RQ, cvQuals: _ => CVS))(defaultMethodInfo())

     rule stripType(t(Q::Quals, _, classType(C::Class))) => t(Q, .Set, classType(stripClass(C)))

     syntax Class ::= stripClass(Class) [function]

     rule stripClass(N:Namespace :: Class(T::Tag, X::CId, Ts::TemplateArgs)) => N :: Class(T, X, stripTypes(Ts))

     rule stripClass(localQual(B::BlockScope) :: Class(T::Tag, X::CId, Ts::TemplateArgs)) => localQual(B) :: Class(T, X, stripTypes(Ts))

     rule stripClass(C:Class :: Class(T::Tag, X::CId, Ts::TemplateArgs)) => stripClass(C) :: Class(T, X, stripTypes(Ts))

     rule stripType(t(Q::Quals, _, scopedEnum(N:Namespace :: Enum(X::CId), _))) => t(Q, .Set, scopedEnum(N :: Enum(X), type(int)))

     rule stripType(t(Q::Quals, _, scopedEnum(C:Class :: Enum(X::CId), _))) => t(Q, .Set, scopedEnum(stripClass(C) :: Enum(X), type(int)))

     rule stripType(t(Q::Quals, _, scopedEnum(localQual(B::BlockScope) :: Enum(X::CId), _))) => t(Q, .Set, scopedEnum(localQual(B) :: Enum(X), type(int)))

     rule stripType(t(Q::Quals, _, unscopedEnum(N:Namespace :: Enum(X::CId), _, _))) => t(Q, .Set, unscopedEnum(N :: Enum(X), type(int), false))

     rule stripType(t(Q::Quals, _, unscopedEnum(C:Class :: Enum(X::CId), _, _))) => t(Q, .Set, unscopedEnum(stripClass(C) :: Enum(X), type(int), false))

     rule stripType(t(Q::Quals, _, unscopedEnum(localQual(B::BlockScope) :: Enum(X::CId), _, _))) => t(Q, .Set, unscopedEnum(localQual(B) :: Enum(X), type(int), false))

     rule stripType(T::CPPType) => T [owise]

     syntax TemplateArgs ::= stripTypes(TemplateArgs) [function]

     rule stripTypes(T::CPPType, Ts::TemplateArgs) => stripType(T), stripTypes(Ts)

     rule stripTypes(.TemplateArgs) => .TemplateArgs

     rule T1::CPPType ==Type T2::CPPType => stripType(T1) ==K stripType(T2)

     rule T1::CPPType =/=Type T2::CPPType => notBool (T1 ==Type T2)

     rule overrides(t(... st: functionType(... paramTypes: P1::CPPTypes, methodInfo: MI1::MethodInfo)),
                    t(... st: functionType(... paramTypes: P2::CPPTypes, methodInfo: MI2::MethodInfo)))
          => stripTypes(toTemplateArgs(P1)) ==K stripTypes(toTemplateArgs(P2)) andBool stripMI(MI1) ==K stripMI(MI2)

     rule overrides(...) => false [owise]

     rule underlyingType(T::CPPSimpleType) => T [owise]

     rule underlyingType(t(Q::Quals, Mods::Set, T::CPPSimpleType))
          => t(Q, Mods, underlyingType(T))

     rule underlyingType(scopedEnum(_, T::CPPType)) => simpleType(T)

     rule underlyingType(unscopedEnum(_, T::CPPType, _)) => simpleType(T)

     rule underlyingType(bitfieldType(T::CPPSimpleType, N::Int)) => bitfieldType(underlyingType(T), N)

     rule inRange(I:Int, T::CPPType)
          => I <=Int max(T) andBool I >=Int min(T)

     rule inRange(F:Float, T::CPPType)
          => F <=Float fmax(T) andBool F >=Float fmin(T)

     rule inRange(Loc:SymLoc, T::CPPType)
          => bitSizeofType(T) >=Int cfg:ptrsize *Int cfg:bitsPerByte

     // bitfields can't have values beyond their actual type, regardless of their width
     rule min(t(... st: bitfieldType(...)) #as T::CPPType) => maxInt(#min(T), #min(innerType(T)))

     rule max(t(... st: bitfieldType(...)) #as T::CPPType) => minInt(#max(T), #max(innerType(T)))

     rule min(T::CPPType) => #min(T) [owise]

     rule max(T::CPPType) => #max(T) [owise]

     syntax Int ::= #min(CPPType) [function]
                  | #max(CPPType) [function]

     rule #min(t(... st: _:CPPSimpleSignedType) #as T::CPPType) => 0 -Int (1 <<Int ((bitSizeofType(T)) -Int 1))

     rule #max(t(... st: _:CPPSimpleSignedType) #as T::CPPType) => (1 <<Int ((bitSizeofType(T)) -Int 1)) -Int 1

     rule #min(t(... st: _:CPPSimpleUnsignedType)) => 0

     rule #max(t(... st: _:CPPSimpleUnsignedType) #as T::CPPType) => (1 <<Int (bitSizeofType(T))) -Int 1

     rule #min(t(... st: _:CPPSimpleBoolType)) => 0

     rule #max(t(... st: _:CPPSimpleBoolType)) => 1

     rule #min(t(_, _, char)) => #min(underlyingType(type(char)))

     rule #min(t(_, _, bitfieldType(char, N::Int))) => #min(underlyingType(type(bitfieldType(char, N))))

     rule #max(t(_, _, char)) => #max(underlyingType(type(char)))

     rule #max(t(_, _, bitfieldType(char, N::Int))) => #max(underlyingType(type(bitfieldType(char, N))))

     rule #min(t(... st: _:CPPSimpleWideCharType) #as T::CPPType) => #min(underlyingType(T))

     rule #max(t(... st: _:CPPSimpleWideCharType) #as T::CPPType) => #max(underlyingType(T))

     rule #min(cppEnumType #as T::CPPType) => #min(underlyingType(T))
          requires isEnumFixed(T)

     rule #max(cppEnumType #as T::CPPType) => #max(underlyingType(T))
          requires isEnumFixed(T)

     rule #min(cppEnumType #as T::CPPType) => #getEnumMin(getEnumInfo(T))
          requires notBool isEnumFixed(T)

     rule #max(cppEnumType #as T::CPPType) => #getEnumMax(getEnumInfo(T))
          requires notBool isEnumFixed(T)

     rule precision(t(_, _, float)) => cfg:precisionofFloat

     rule precision(t(_, _, double)) => cfg:precisionofDouble

     rule precision(t(_, _, long-double)) => cfg:precisionofLongDouble

     rule exponent(t(_, _, float)) => cfg:exponentofFloat

     rule exponent(t(_, _, double)) => cfg:exponentofDouble

     rule exponent(t(_, _, long-double)) => cfg:exponentofLongDouble

     rule fmax(T::CPPType) => maxValueFloat(precision(T), exponent(T))

     rule fmin(T::CPPType) => --Float fmax(T)

     rule isUnnamedLValue(T::CPPType)
          => isCPPLVRefType(T) orBool (isCPPRVRefType(T) andBool isCPPFunctionType(innerType(T)))

     rule isUnnamedXValue(T::CPPType)
          => isCPPRVRefType(T) andBool isObjectType(innerType(T))

     rule isUnnamedPRValue(T::CPPType)
          => notBool isUnnamedLValue(T) andBool notBool isUnnamedXValue(T)

     rule getBaseClassSubobject(lv(L::SymLoc, Tr::Trace, D::CPPType), B::CPPType) => lv(baseClassSubobject(L, B, D), Tr, B)

     rule getBaseClassOffset(Base::Class, Derived::Class)
         => {getAllBaseClassOffsets(Derived)[ Base ]}:>Int

     // Returns a mapping of type Class |-> Offset, including C |-> 0 for given class C.
     syntax Map ::= getAllBaseClassOffsets(Class) [function]

     rule getAllBaseClassOffsets(D::Class) => #getAllBaseClassOffsets2(.Map, D |-> 0)

     syntax Map ::= #getAllBaseClassOffsets2(processed: Map, fresh: Map) [function]

     rule #getAllBaseClassOffsets2(Processed::Map, .Map) => Processed

     rule #getAllBaseClassOffsets2(M::Map => M[D <- CurrentOffset],
               ((D::Class |-> CurrentOffset::Int) => .Map) _::Map (.Map => getDirectBaseClassOffsets(CurrentOffset, getClassInfo(D))))

     syntax Map ::= getDirectBaseClassOffsets(currentOffset: Int, info: ClassInfo) [function]

     rule getDirectBaseClassOffsets(CurrentOffset::Int,
               <class>... <base-classes>BCS::List</base-classes> <cenv> ClassEnv::Map </cenv>  ...</class>)
          => #getDirectBaseClassOffsets(.Map, BCS, CurrentOffset, ClassEnv)

     syntax Map ::= #getDirectBaseClassOffsets(result: Map, bases: List, currentOffset: Int, cenv: Map) [function]

     rule #getDirectBaseClassOffsets(M::Map, .List, _, _) => M

     rule #getDirectBaseClassOffsets(M::Map, (ListItem(B:Class) => ListItem(type(classType(B)))) _, _, _)

     rule #getDirectBaseClassOffsets(M::Map => M[B <- CurrentOffset +Int Offset],
               (ListItem(t(...st: classType(B::Class)) #as T::CPPType) => .List) _,
               CurrentOffset::Int,
               (baseClass(B) |-> (_::Map stripType(T) |-> (_,classOffset(_, Offset::Int)))) _::Map)
     requires notBool (B in_keys(M))

     rule isProperBaseClassOf(t(_, _, classType(B::Class)), t(_, _, classType(D::Class)))
          => isProperBaseClassOf(B, D)

     rule isProperBaseClassOf(D::Class, D) => false

     rule isProperBaseClassOf(B::Class, D::Class) => isBaseClassOf(B, D)
          requires B =/=K D

     rule isBaseClassOf(t(_, _, classType(B::Class)), t(_, _, classType(D::Class))) => isBaseClassOf(B, D)

     rule isBaseClassOf(B::Class, D::Class) => #isBaseClassOf(B, ListItem(D))

     syntax Bool ::= #isBaseClassOf(base: Class, derived: List) [function, withConfig]

     rule #isBaseClassOf(B::Class, ListItem(B) _) => true

     rule #isBaseClassOf(_, .List) => false

     rule [[ #isBaseClassOf(B::Class, (ListItem(D::Class) => BC) _) ]]
          <class-id> D </class-id>
          <base-classes> BC::List </base-classes>
          requires D =/=K B

     rule [[ isDirectBaseClassOf(B::Class, D::Class) => B in BC ]]
          <class-id> D </class-id>
          <base-classes> BC::List </base-classes>

     rule hasVirtualMembers(C::Class) => hasVirtualMembers(type(classType(C)))

     rule hasVirtualMembers(T::CPPType) => #hasVirtualMembers(getClassInfo(T))

     syntax Bool ::= #hasVirtualMembers(ClassInfo) [function]

     rule #hasVirtualMembers(<class>... <function-members> ListItem(Class.FunctionMember(_, t(... st: functionType(... methodInfo: methodInfo(... virtual: false))))) => .List ...</function-members> ...</class>)

     rule #hasVirtualMembers(<class>... <base-classes> ListItem(B::Class) => .List ...</base-classes> <virtual-bases> VirtualBases::Set </virtual-bases> ...</class>)
          requires notBool B in VirtualBases andBool notBool #hasVirtualMembers(getClassInfo(B))

     rule #hasVirtualMembers(<class>... <base-classes> .List </base-classes> <function-members> .List </function-members> ...</class>) => false

     rule #hasVirtualMembers(...) => true [owise]

     rule isUnionLikeClass(_ :: Class(Union(), _, _)) => true

     rule isUnionLikeClass(C::Class) => #isUnionLikeClass(getClassInfo(C)) [owise]

     syntax Bool ::= #isUnionLikeClass(ClassInfo) [function]

     rule #isUnionLikeClass(<class>... <variant-members> S::Set </variant-members> ...</class>) => size(S) >Int 0

     rule getMostDerivedArrayElement(t(... st: _:CPPSimpleArrayType) #as T::CPPType => innerType(T))

     rule getMostDerivedArrayElement(T::CPPType) => T [owise]

     rule setType(T::CPPType, lv(Loc::SymLoc, Tr::Trace, _)) => lv(Loc, Tr, T)

     rule setType(T::CPPType, prv(Loc::SymLoc, Tr::Trace, _)) => prv(Loc, Tr, T)

     rule isEnumScoped(t(_, _, scopedEnum(_, _))) => true

     rule isEnumScoped(t(_, _, unscopedEnum(_, _, _))) => false

     rule isEnumFixed(t(... st: scopedEnum(...))) => true

     rule isEnumFixed(t(... st: unscopedEnum(_, _, B::Bool))) => B

     rule isEnumFixed(t(... st: bitfieldType(...)) #as T::CPPType => innerType(T))

     rule getEnumId(t(_, _, scopedEnum(X::Enum, _))) => X

     rule getEnumId(t(_, _, unscopedEnum(X::Enum, _, _))) => X

     rule getEnumId(t(... st: bitfieldType(...)) #as T::CPPType => innerType(T))

     syntax Int ::= #getEnumMin(K) [function]
                  | #getEnumMax(K) [function]

     rule #getEnumMin(<cppenum>... <enum-min>Min::Int</enum-min>  ...</cppenum>) => Min

     rule #getEnumMax(<cppenum>... <enum-max>Max::Int</enum-max>  ...</cppenum>) => Max

     rule isVirtualCall(hasTrace(Name(N::NNS, _)), _) => false
          requires N =/=K NoNNS()

     rule isVirtualCall(hasTrace(_ . _ Name(N::NNS, _)), _) => false
          requires N =/=K NoNNS()

     rule isVirtualCall(_, T::CPPType) => false
          requires notBool isMethodVirtual(T)

     rule isVirtualCall(hasTrace(_), _) => true [owise]

endmodule

module C-CPP-TYPING
     imports C-TYPING-SYNTAX
     imports CPP-TYPING
     imports SETTINGS-SYNTAX

     rule convertTypeToC(t(Q::Quals, Mods::Set, functionType(... returnType: Ret::CPPType, paramTypes: Args::CPPTypes)))
          => t(Q, Mods, functionType(utype(convertTypeToC(Ret)), convertDTypesToC(toList(Args))))

     syntax List ::= convertDTypesToC(List) [function]
     rule convertDTypesToC(.List) => .List
     rule convertDTypesToC(ListItem(T::CPPDType) L::List) => ListItem(convertDTypeToC(T)) convertDTypesToC(L)

     rule convertTypeToC(t(Q::Quals, Mods::Set, void::CPPSimpleVoidType)) => t(Q, Mods, void::SimpleVoidType)

     rule convertTypeToC(t(Q::Quals, Mods::Set, bool::CPPSimpleBoolType)) => t(Q, Mods, bool::SimpleBoolType)

     rule convertTypeToC(t(Q::Quals, Mods::Set, signed-char::CPPSimpleSignedCharType)) => t(Q, Mods, signed-char::SimpleSignedCharType)

     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-char::CPPSimpleUnsignedCharType)) => t(Q, Mods, unsigned-char::SimpleUnsignedCharType)

     rule convertTypeToC(t(Q::Quals, Mods::Set, char::CPPSimpleCharType)) => t(Q, Mods, char::SimpleCharType)

     rule convertTypeToC(t(Q::Quals, Mods::Set, short)) => t(Q, Mods, short-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-short)) => t(Q, Mods, unsigned-short-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, int::CPPSimpleSignedType)) => t(Q, Mods, int::SimpleIntType)

     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned)) => t(Q, Mods, unsigned-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, long)) => t(Q, Mods, long-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-long)) => t(Q, Mods, unsigned-long-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, long-long)) => t(Q, Mods, long-long-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, oversized)) => t(Q, Mods, oversized-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-long-long)) => t(Q, Mods, unsigned-long-long-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-oversized)) => t(Q, Mods, unsigned-oversized-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, float::CPPSimpleFloatingType)) => t(Q, Mods, float::SimpleFloatType)

     rule convertTypeToC(t(Q::Quals, Mods::Set, double::CPPSimpleFloatingType)) => t(Q, Mods, double::SimpleFloatType)

     rule convertTypeToC(t(Q::Quals, Mods::Set, long-double::CPPSimpleFloatingType)) => t(Q, Mods, long-double::SimpleFloatType)

     rule convertDTypeToC(variadic::CPPVariadic) => variadic::Variadic

     rule convertDTypeToC(t(...) #as T::CPPType) => convertTypeToC(T)

     rule convertTypeToC(t(Q::Quals, Mods::Set, pointerType(T::CPPType))) => t(Q, Mods, pointerType(convertTypeToC(T)))

     rule convertTypeToC(t(Q::Quals, Mods::Set, nullptr_t)) => t(Q, Mods, pointerType(type(void::SimpleVoidType)))

     rule convertTypeToC(t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int))) => t(Q, Mods, arrayType(convertTypeToC(T), N))

     rule convertTypeToC(t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType))) => t(Q, Mods, incompleteArrayType(convertTypeToC(T)))

     // TODO(chathhorn): struct/union namespace, memberPointerType, classes, template args
     rule convertTypeToC(t(Q::Quals, Mods::Set, classType(_::Namespace :: Class(Struct(), X::CId, _))) #as C::CPPType) => t(Q, Mods, structType(tag(X, "C++", global)))

     rule convertTypeToC(t(Q::Quals, Mods::Set, classType(_::Namespace :: Class(Union(), X::CId, _))) #as C::CPPType) => t(Q, Mods, unionType(tag(X, "C++", global)))

     rule convertTypeToC(t(Q::Quals, Mods::Set, classType(_::Namespace :: Class(Class(), X::CId, _))) #as C::CPPType) => t(Q, Mods, structType(tag(X, "C++", global)))

     rule convertTypeToC(t(Q::Quals, Mods::Set, lvRefType(T::CPPType))) => t(Q, Mods, pointerType(convertTypeToC(T)))

     rule convertTypeToC(t(Q::Quals, Mods::Set, rvRefType(T::CPPType))) => t(Q, Mods, pointerType(convertTypeToC(T)))

     rule convertTypeToC(t(Q::Quals, Mods::Set, memberPointerType(_, T::CPPType))) => t(Q, Mods, pointerType(convertTypeToC(T)))

     rule convertTypeToC(t(Q::Quals, Mods::Set, wchar_t)) => convertTypeToC(t(Q, Mods, underlyingType(wchar_t)))

     rule convertTypeToC(t(Q::Quals, Mods::Set, unscopedEnum(_, T::CPPType, _))) => convertTypeToC(t(Q, Mods, simpleType(T)::CPPSimpleType))

     rule convertTypeToC(t(Q::Quals, Mods::Set, scopedEnum(_, T::CPPType))) => convertTypeToC(t(Q, Mods, simpleType(T)::CPPSimpleType))

     // TODO(chathhorn): make configurable
     rule convertTypeToC(t(Q::Quals, Mods::Set, char16_t)) => t(Q, Mods, unsigned-short-int)

     rule convertTypeToC(t(Q::Quals, Mods::Set, char32_t)) => t(Q, Mods, unsigned-int)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, pointerType(T::Type))) => t(Q, Mods, pointerType(convertTypeToCPP(T)))

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, void::SimpleVoidType)) => t(Q, Mods, void::CPPSimpleVoidType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, bool::SimpleBoolType)) => t(Q, Mods, bool::CPPSimpleBoolType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, signed-char::SimpleSignedCharType)) => t(Q, Mods, signed-char::CPPSimpleSignedCharType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-char::SimpleUnsignedCharType)) => t(Q, Mods, unsigned-char::CPPSimpleUnsignedCharType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, char::SimpleCharType)) => t(Q, Mods, char::CPPSimpleCharType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, short-int)) => t(Q, Mods, short)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-short-int)) => t(Q, Mods, unsigned-short)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, int::SimpleIntType)) => t(Q, Mods, int::CPPSimpleSignedType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, signed-int)) => t(Q, Mods, int::CPPSimpleSignedType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-int)) => t(Q, Mods, unsigned)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, long-int)) => t(Q, Mods, long)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-long-int)) => t(Q, Mods, unsigned-long)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, long-long-int)) => t(Q, Mods, long-long)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, oversized-int)) => t(Q, Mods, oversized)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-long-long-int)) => t(Q, Mods, unsigned-long-long)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unsigned-oversized-int)) => t(Q, Mods, unsigned-oversized)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, float::SimpleFloatType)) => t(Q, Mods, float::CPPSimpleFloatingType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, double::SimpleFloatType)) => t(Q, Mods, double::CPPSimpleFloatingType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, long-double::SimpleFloatType)) => t(Q, Mods, long-double::CPPSimpleFloatingType)

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, structType(tag(X::CId, _, global)))) => t(Q, Mods, classType(GlobalNamespace() :: Class(Struct(), X, .TemplateArgs)))

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, unionType(tag(X::CId, _, global)))) => t(Q, Mods, classType(GlobalNamespace() :: Class(Union(), X, .TemplateArgs)))

     rule convertTypeToCPP(t(Q::Quals, Mods::Set, functionType(Ret::UType, Args::List)))
          => t(Q, Mods, functionType(convertTypeToCPP(type(Ret)), toCPPTypes(convertDTypesToCPP(Args)), noMethod, CLinkage, noexcept(false)))

     syntax List ::= convertDTypesToCPP(List) [function]
     rule convertDTypesToCPP(.List) => .List
     rule convertDTypesToCPP(ListItem(T::ParamDecl) L::List) => ListItem(convertDTypeToCPP(T)) convertDTypesToCPP(L)

     rule convertDTypeToCPP(variadic::Variadic) => variadic::CPPVariadic
     rule convertDTypeToCPP(t(...) #as T::Type) => convertTypeToCPP(T)

     rule utype(T:CPPType)::UType => utype(convertTypeToC(T))

     rule utype(V:Val)::UType => utype(convertTypeToC(type(V)::CPPType))

     rule type(V:Val)::Type => convertTypeToC(type(V))

     rule type(V:TExpr)::Type => convertTypeToC(type(V))

     rule isCPPVoidType(t(... st: void)) => true
     rule isCPPVoidType(_) => false [owise]
     rule isCPPUnsignedType(t(... st: _:CPPSimpleUnsignedType)) => true
     rule isCPPUnsignedType(_) => false [owise]
     rule isCPPUnscopedEnumType(t(... st: _:CPPSimpleUnscopedEnumType)) => true
     rule isCPPUnscopedEnumType(_) => false [owise]
     rule isCPPSignedType(t(... st: _:CPPSimpleSignedType)) => true
     rule isCPPSignedType(_) => false [owise]
     rule isCPPScopedEnumType(t(... st: _:CPPSimpleScopedEnumType)) => true
     rule isCPPScopedEnumType(_) => false [owise]
     rule isCPPRefType(cppRefType) => true
     rule isCPPRefType(_) => false [owise]
     rule isCPPRVRefType(t(... st: rvRefType(...))) => true
     rule isCPPRVRefType(_) => false [owise]
     rule isCPPPointerType(t(... st: pointerType(...))) => true
     rule isCPPPointerType(_) => false [owise]
     rule isCPPNullPtrTType(t(... st: nullptr_t)) => true
     rule isCPPNullPtrTType(_) => false [owise]
     rule isCPPMemberPointerType(t(... st: memberPointerType(...))) => true
     rule isCPPMemberPointerType(_) => false [owise]
     rule isCPPMemberFunctionPointerType(t(... st: memberPointerType(_, t(... st: functionType(...))))) => true
     rule isCPPMemberFunctionPointerType(_) => false [owise]
     rule isCPPLVRefType(t(... st: lvRefType(...))) => true
     rule isCPPLVRefType(_) => false [owise]
     rule isCPPIntegerType(cppIntegerType) => true
     rule isCPPIntegerType(_) => false [owise]
     rule isCPPFunctionType(t(... st: functionType(...))) => true
     rule isCPPFunctionType(_) => false [owise]
     rule isCPPFloatingType(t(... st: _:CPPSimpleFloatingType)) => true
     rule isCPPFloatingType(_) => false [owise]
     rule isCPPEnumType(cppEnumType) => true
     rule isCPPEnumType(_) => false [owise]
     rule isCPPClassType(t(... st: classType(...))) => true
     rule isCPPClassType(_) => false [owise]
     rule isCPPBoolType(t(... st: _:CPPSimpleBoolType)) => true
     rule isCPPBoolType(_) => false [owise]
     rule isCPPBitfieldType(t(... st: _:CPPSimpleBitfieldType)) => true
     rule isCPPBitfieldType(_) => false [owise]
     rule isCPPArrayType(t(... st: _:CPPSimpleArrayType)) => true
     rule isCPPArrayType(_) => false [owise]
     rule isCPPArithmeticType(T::CPPType) => isCPPIntegerType(T) orBool isCPPFloatingType(T)
     rule isCPPWideCharType(t(... st: _:CPPSimpleWideCharType)) => true
     rule isCPPWideCharType(_) => false [owise]
     rule isCPPCharType(t(... st: _:CPPSimpleCharType)) => true
     rule isCPPCharType(_) => false [owise]

endmodule
