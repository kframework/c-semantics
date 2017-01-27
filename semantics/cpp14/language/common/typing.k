module CPP-TYPING-SORTS
     syntax AType
     syntax CPPType
     syntax CPPDType ::= CPPType | CPPVariadic
     syntax CPPVariadic
     syntax CPPSimpleType
     syntax EffectiveType ::= CPPType
     syntax CPPTypeExpr ::= CPPType
     syntax CPPDTypeExpr ::= CPPTypeExpr | CPPDType
     syntax CPPTypeExprs ::= List{CPPDTypeExpr, ","}
     syntax CPPTypes ::= List{CPPDType, ","}
     syntax CPPTypeExprs ::= CPPTypes
     syntax ExceptionSet
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
     syntax CPPSimpleFunctionTypeExpr ::= functionType(CPPTypeExpr, CPPTypeExprs, LanguageLinkage, ExceptionSet) [klabel(cppFunctionType)]
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
     syntax CPPSimpleFunctionType ::= functionType(CPPType, CPPTypes, LanguageLinkage, ExceptionSet) [klabel(cppFunctionType)]
     syntax CPPSimpleClassType ::= classType(Class)

     syntax CPPSimpleDependentType ::= dependentType(String)
     syntax CPPSimpleAutoType ::= "auto"
                                | "decltype(auto)"
     syntax CPPSimpleArrayTypeExpr ::= dynamicArrayType(CPPType, Expr)

     syntax CPPSimpleScopedEnumType ::= scopedEnum(id: EnumId, underlyingType: CPPIntegerType)
     syntax CPPSimpleUnscopedEnumType ::= unscopedEnum(id: EnumId, underlyingType: CPPIntegerType)
     syntax CPPSimpleEnumType ::= CPPSimpleScopedEnumType | CPPSimpleUnscopedEnumType
     syntax CPPSimpleCompoundType ::= CPPSimpleEnumType

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
     syntax CPPScopedEnumType ::= t(q: Quals, m: Set, st: CPPSimpleScopedEnumType) [klabel(tcpp)]
     syntax CPPUnscopedEnumType ::= t(q: Quals, m: Set, st: CPPSimpleUnscopedEnumType) [klabel(tcpp)]

     syntax CPPType ::= CPPFunctionType
                      | CPPScalarType
                      | CPPRefType
                      | CPPArrayType 
                      | CPPClassType 
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

     syntax Quals ::= getQuals(CPPType) [function]
     syntax CPPType ::= addQuals(Quals, CPPType) [function]

     syntax Bool ::= isAdjustedType(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionTypeExpr ::= adjustFunctionType(CPPFunctionTypeExpr) [function]

     syntax List ::= getParams(CPPFunctionTypeExpr) [function, klabel(cppgetParams)]
                   | getRealParams(CPPFunctionTypeExpr) [function]
     syntax Bool ::= isVariadicFunction(CPPFunctionTypeExpr) [function]
     syntax CPPTypeExpr ::= getReturnType(CPPFunctionTypeExpr) [function, klabel(cppgetReturnType)]
     syntax CPPType ::= getReturnType(CPPFunctionType) [function, klabel(cppgetReturnType)]

     syntax CPPType ::= const(CPPSimpleType) [function, klabel(constCpp)]

     syntax CPPType ::= type(CPPSimpleTypeExpr) [function, klabel(cppType)]
     syntax CPPType ::= utype(Typed) [function, klabel(cppUTypeVal)]
     syntax CPPType ::= type(Typed) [function, klabel(cppTypeVal)]
     syntax CPPType ::= utype(CPPTypeExpr) [function, klabel(cppUTypeType)]

     syntax Bool ::= isObjectType(K) [function]
                   | isCompleteType(CPPType) [function, klabel(isCompleteTypeCPP)]
                   | isAggregateType(CPPType) [function, klabel(isAggregateTypeCPP)]
                   | isVolatileType(CPPType) [function, klabel(isVolatileTypeCPP)]

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

     syntax ClassInfo ::= getClassInfo(CPPClassType) [function]
                        | #getClassInfo(CPPClassType, K) [function]
     syntax ClassInfo ::= ClassCell | "#incomplete"

     syntax Bool ::= isBaseClassOf(CPPClassType, CPPClassType) [function]
                   | isVirtualBaseClassOf(CPPClassType, CPPClassType) [function]

     syntax EnumInfo ::= getEnumInfo(CPPEnumType) [function]
                       | #getEnumInfo(EnumId, K) [function]
     syntax EnumInfo ::= CppenumCell | "#incomplete"

     syntax EnumId ::= enumId(QualId)

     syntax Bool ::= CPPType "==Type" CPPType [function]
                   | CPPType "=/=Type" CPPType [function]

     syntax ExceptionSet ::= exSet(Set) | "noexcept(true)" | "noexcept(false)"
     syntax KResult ::= ExceptionSet
     syntax ExceptionSpec ::= ExceptionSet

     syntax Bool ::= isUnnamedLValue(CPPType) [function]
                   | isUnnamedXValue(CPPType) [function]
                   | isUnnamedPRValue(CPPType) [function]

     syntax EnumId ::= getEnumId(CPPEnumType) [function]
     syntax Bool ::= getScoped(CPPEnumType) [function]
endmodule

module CPP-TYPING
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports FLOAT
     imports K-REFLECTION
     imports COMMON-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule getParams(t(_, _, functionType(_, L::CPPTypes, _, _))) => toList(L)
     rule getRealParams(T::CPPFunctionTypeExpr) => #getRealParams(getParams(T))
     rule getReturnType(t(_, _, functionType(T::CPPType, _, _, _))) => T
     rule isVariadicFunction(T::CPPFunctionTypeExpr) => size(getParams(T)) =/=Int size(getRealParams(T))

     syntax List ::= #getRealParams(List) [function]
     rule #getRealParams(L::List ListItem(variadic)) => L
     rule #getRealParams(L::List) => L [owise]

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

     rule getTag(t(_, _, classType(_::ClassQualifier :: Class(Tag::Tag, _, _)))) => Tag
     rule getTag(_) => .K [owise]

     rule addQuals(Qs'::Quals, t(Qs::Quals, Mods::Set, T::CPPSimpleType))
          => t(Qs +Quals Qs', Mods, T)
     rule getQuals(t(Q::Quals, _, _)) => Q

     rule getClassInfo(T::CPPClassType) => #getClassInfo(T, #configuration)
     rule #getClassInfo(t(_, _, classType(C::Class)), <generatedTop>... <class> <class-id> C </class-id> B::Bag </class> ...</generatedTop>) => <class> <class-id> C </class-id> B </class>
     rule #getClassInfo(_, _) => #incomplete [owise]

     rule getEnumInfo(E::CPPEnumType) => #getEnumInfo(getEnumId(E), #configuration)

     rule #getEnumInfo(X::EnumId, <generatedTop>... <cppenum> <enum-id> X </enum-id> B::Bag </cppenum> ...</generatedTop>) => <cppenum> <enum-id> X </enum-id> B </cppenum>
     rule #getEnumInfo(_, _) => #incomplete [owise]

     rule isCompleteType(t(_, _, incompleteArrayType(_))) => false
     rule isCompleteType(T:CPPEnumType) => getEnumInfo(T) =/=K #incomplete //TODO(h0nzZik): false in 7.2, par 6

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
     rule t(Q::Quals, _, functionType(R1::CPPType, P1::CPPTypes, _, _)) ==Type t(Q, _, functionType(R2::CPPType, P2::CPPTypes, _, _)) => R1 ==Type R2 andBool toTemplateArgs(P1) ==Types toTemplateArgs(P2)
     rule t(Q::Quals, _, classType(N1::Namespace :: Class(T1::Tag, X1::CId, Ts1::TemplateArgs))) ==Type t(Q::Quals, _, classType(N2::Namespace :: Class(T2::Tag, X2::CId, Ts2::TemplateArgs))) => N1 ==K N2 andBool T1 ==K T2 andBool X1 ==K X2 andBool Ts1 ==Types Ts2
     rule t(Q::Quals, _, scopedEnum(X::EnumId, _)) ==Type t(Q, _, scopedEnum(X::EnumId, _)) => true
     rule t(Q::Quals, _, unscopedEnum(X::EnumId, _)) ==Type t(Q, _, unscopedEnum(X::EnumId, _)) => true

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
     rule underlyingType(scopedEnum(_, T::CPPIntegerType)) => simpleType(T)
     rule underlyingType(unscopedEnum(_, T::CPPIntegerType)) => simpleType(T)


     rule inRange(I:Int, T::CPPIntegerType)
          => I <=Int max(T) andBool I >=Int min(T)
     rule inRange(F:Float, T::CPPFloatingType)
          => F <=Float fmax(T) andBool F >=Float fmin(T)

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

     rule getScoped(t(_, _, scopedEnum(_, _))) => true
     rule getScoped(t(_, _, unscopedEnum(_, _))) => false
     rule getEnumId(t(_, _, scopedEnum(X::EnumId, _))) => X
     rule getEnumId(t(_, _, unscopedEnum(X::EnumId, _))) => X

endmodule

module C-CPP-TYPING
     imports C-TYPING-SYNTAX
     imports CPP-TYPING
     imports COMPAT-SYNTAX
     imports SETTINGS-SYNTAX

     rule convertTypeToC(t(Q::Quals, Mods::Set, functionType(Ret::CPPType, Args::CPPTypes, CLinkage, _))) => t(Q, Mods, functionType(utype(convertTypeToC(Ret)), mapList(toList(Args), #klabel(`convertTypeToC`))))
     rule convertTypeToC(t(Q::Quals, Mods::Set, void::CPPSimpleVoidType)) => t(Q, Mods, void::SimpleVoidType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, bool::CPPSimpleBoolType)) => t(Q, Mods, bool::SimpleBoolType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, int::CPPSimpleSignedType)) => t(Q, Mods, int::SimpleSignedIntType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned)) => t(Q, Mods, unsigned-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, long)) => t(Q, Mods, long-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-long)) => t(Q, Mods, unsigned-long-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, signed-char::CPPSimpleSignedCharType)) => t(Q, Mods, signed-char::SimpleSignedCharType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-char::CPPSimpleUnsignedCharType)) => t(Q, Mods, unsigned-char::SimpleUnsignedCharType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, char::CPPSimpleCharType)) => t(Q, Mods, char::SimpleCharType)
     rule convertTypeToC(variadic::CPPVariadic) => variadic::Variadic
     rule convertTypeToC(t(Q::Quals, Mods::Set, pointerType(T::CPPType))) => t(Q, Mods, pointerType(convertTypeToC(T)))
     rule convertTypeToC(t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int))) => t(Q, Mods, arrayType(convertTypeToC(T), N))


     rule convertTypeToCPP(t(Q::Quals, Mods::Set, int::SimpleSignedIntType)) => t(Q, Mods, int::CPPSimpleSignedType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, void::SimpleVoidType)) => t(Q, Mods, void::CPPSimpleVoidType)
     rule convertTypeToCPP(t(Q::Quals, Mods::Set, pointerType(T::Type))) => t(Q, Mods, pointerType(convertTypeToCPP(T)))
endmodule
