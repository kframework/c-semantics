module CPP-TYPING-SORTS
     syntax AType
     syntax CPPType
     syntax CPPDType ::= CPPType | CPPVariadic
     syntax CPPVariadic
     syntax CPPSimpleType
     syntax EffectiveType ::= CPPType
     syntax CPPTypeExpr
     syntax CPPDTypeExpr ::= CPPTypeExpr | CPPDType
     syntax CPPTypeExprs ::= List{CPPDTypeExpr, ","}
     syntax CPPTypes ::= List{CPPDType, ","}
     syntax CPPTypeExprs ::= CPPTypes
endmodule

module CPP-DEPENDENT-SYNTAX
     imports CPP-TYPING-SORTS
     imports CPP-DYNAMIC-SORTS
     syntax Bool ::= isDependentInScope(CPPTypeExpr) [function]
                   | areDependentInScope(TemplateParams) [function]
                   | areDependentInScope(CPPTypeExprs) [function]
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

     syntax CPPType ::= t(Quals, Set, CPPSimpleType) [klabel(tcpp)]

     syntax CPPTypeExpr ::= innerType(CPPTypeExpr) [function, klabel(cppInnerType)]
     syntax CPPType ::= innerType(CPPType) [function, klabel(cppInnerType)]
     syntax CPPSimpleType ::= simpleType(CPPType) [function, klabel(cppSimpleType)]

     syntax CPPSimpleType ::= underlyingType(CPPSimpleType) [function]

     syntax CPPSimpleType ::= CPPSimpleBasicType

     syntax CPPSimpleArithmeticType ::= CPPSimpleIntegerType | CPPSimpleFloatingType
     syntax CPPSimpleBasicType ::= CPPSimpleArithmeticType | CPPSimpleVoidType | CPPSimpleNullPtrTType
     syntax CPPSimpleIntegerType ::= CPPSimpleSignedType | CPPSimpleUnsignedType | CPPSimpleCharType | CPPSimpleBoolType
     syntax CPPSimpleSignedType ::= CPPSimpleSignedCharType | "short" | "int" | "long" | "long-long"
     syntax CPPSimpleUnsignedType ::= CPPSimpleUnsignedCharType | "unsigned-short" | "unsigned" | "unsigned-long" | "unsigned-long-long"
     syntax CPPSimpleFloatingType ::= "float" | "double" | "long-double"
     syntax CPPSimpleCharType ::= CPPSimpleSignedCharType | CPPSimpleUnsignedCharType
     syntax CPPSimpleSignedCharType ::= "signed-char"
     syntax CPPSimpleUnsignedCharType ::= "unsigned-char"
     syntax CPPSimpleBoolType ::= "bool"
     syntax CPPSimpleVoidType ::= "void"
     syntax CPPSimpleCharType ::= "char"
     syntax CPPSimpleIntegerType ::= "wchar_t" | "char16_t" | "char32_t" | "size_t" [function]
     syntax CPPSimpleNullPtrTType ::= "nullptr_t"

     syntax CPPSimpleType ::= CPPSimplePointerType
                            | CPPSimpleFunctionType
                            | CPPSimpleArrayType
                            | CPPSimpleRefType
                            | CPPSimpleNullPtrTType
                            | CPPSimpleClassType
     syntax CPPSimpleRefType ::= CPPSimpleLVRefType
                               | CPPSimpleRVRefType

     syntax CPPSimpleTypeExpr ::= CPPSimpleType | CPPSimpleDependentType
                                | CPPSimpleArrayTypeExpr
                                | CPPSimplePointerTypeExpr
                                | CPPSimpleLVRefTypeExpr
                                | CPPSimpleRVRefTypeExpr
                                | CPPSimpleFunctionTypeExpr
                                | CPPSimpleClassTypeExpr

     syntax CPPSimpleArrayTypeExpr ::= arrayType(CPPTypeExpr, Int) [klabel(cppArrayType)]
     syntax CPPSimpleArrayTypeExpr ::= incompleteArrayType(CPPTypeExpr) [klabel(cppIncompleteArrayType)]
     syntax CPPSimplePointerTypeExpr ::= pointerType(CPPTypeExpr) [klabel(cppPointerType)]
     syntax CPPSimpleLVRefTypeExpr ::= lvRefType(CPPTypeExpr)
     syntax CPPSimpleRVRefTypeExpr ::= rvRefType(CPPTypeExpr)
     syntax CPPSimpleFunctionTypeExpr ::= functionType(CPPTypeExpr, CPPTypeExprs, LanguageLinkage) [klabel(cppFunctionType)]
     syntax CPPSimpleClassTypeExpr ::= classType(ClassTemplate)

     syntax CPPSimpleArrayType ::= CPPSimpleFixedArrayType | CPPSimpleIncompleteArrayType
     syntax CPPSimpleFixedArrayType ::= arrayType(CPPType, Int) [klabel(cppArrayType)]
     syntax CPPSimpleIncompleteArrayType ::= incompleteArrayType(CPPType) [klabel(cppIncompleteArrayType)]
     syntax CPPSimplePointerType ::= pointerType(CPPType) [klabel(cppPointerType)]
     syntax CPPSimpleLVRefType ::= lvRefType(CPPType)
     syntax CPPSimpleRVRefType ::= rvRefType(CPPType)
     // TODO: exception specification
     syntax CPPSimpleFunctionType ::= functionType(CPPType, CPPTypes, LanguageLinkage) [klabel(cppFunctionType)]
     syntax CPPSimpleClassType ::= classType(Class)

     syntax CPPSimpleDependentType ::= dependentType(String)

     syntax CPPFunctionType ::= t(Quals, Set, CPPSimpleFunctionType) [klabel(tcpp)]
     syntax CPPArithmeticType ::= CPPIntegerType | t(Quals, Set, CPPSimpleArithmeticType) [klabel(tcpp)]
     syntax CPPBasicType ::= CPPIntegerType | CPPVoidType
     syntax CPPCharType ::= t(Quals, Set, CPPSimpleCharType) [klabel(tcpp)]
     syntax CPPBoolType ::= t(Quals, Set, CPPSimpleBoolType) [klabel(tcpp)]
     syntax CPPIntegerType ::= CPPCharType | CPPBoolType | CPPSignedType | CPPUnsignedType
     syntax CPPSignedType ::= t(Quals, Set, CPPSimpleSignedType) [klabel(tcpp)]
     syntax CPPUnsignedType ::= t(Quals, Set, CPPSimpleUnsignedType) [klabel(tcpp)]
     syntax CPPVoidType ::= t(Quals, Set, CPPSimpleVoidType) [klabel(tcpp)]
     syntax CPPArrayType ::= t(Quals, Set, CPPSimpleArrayType) [klabel(tcpp)]
     syntax CPPPointerType ::= t(Quals, Set, CPPSimplePointerType) [klabel(tcpp)]
     syntax CPPLVRefType ::= t(Quals, Set, CPPSimpleLVRefType) [klabel(tcpp)]
     syntax CPPRVRefType ::= t(Quals, Set, CPPSimpleRVRefType) [klabel(tcpp)]
     syntax CPPNullPtrTType ::= t(Quals, Set, CPPSimpleNullPtrTType) [klabel(tcpp)]
     syntax CPPRefType ::= CPPLVRefType | CPPRVRefType
     syntax CPPClassType ::= t(Quals, Set, CPPSimpleClassType) [klabel(tcpp)]
     syntax CPPBitfieldType
     syntax CPPEnumType
     syntax CPPCompleteType ::= CPPFunctionType | CPPPointerType | CPPIntegerType | CPPNullPtrTType | CPPRefType
     syntax CPPType ::= CPPFunctionType
                      | CPPPointerType
                      | CPPNullPtrTType
                      | CPPRefType
                      | CPPArrayType 
                      | CPPClassType 
                      | CPPBasicType
                      | CPPEnumType

     syntax CPPFunctionTypeExpr ::= CPPFunctionType | t(Quals, Set, CPPSimpleFunctionTypeExpr) [klabel(tcpp)]
     syntax CPPClassTypeExpr ::= CPPClassType | t(Quals, Set, CPPSimpleClassTypeExpr) [klabel(tcpp)]
     syntax CPPArrayTypeExpr ::= CPPArrayType | t(Quals, Set, CPPSimpleArrayTypeExpr) [klabel(tcpp)]
     syntax CPPTypeExpr ::= CPPType | t(Quals, Set, CPPSimpleTypeExpr) [klabel(tcpp)]
                          | CPPFunctionTypeExpr
                          | CPPClassTypeExpr
                          | CPPArrayTypeExpr

     syntax CPPVariadic ::= "variadic"

     syntax Quals ::= getQuals(CPPType) [function]

     syntax Bool ::= isAdjustedType(CPPFunctionTypeExpr) [function]
     syntax CPPFunctionTypeExpr ::= adjustFunctionType(CPPFunctionTypeExpr) [function]

     syntax CPPUnsignedType ::= correspondingUnsignedType(CPPSignedType) [function, klabel(correspondingUnsignedTypeCpp)]

     syntax List ::= getParams(CPPFunctionTypeExpr) [function, klabel(cppgetParams)]
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

     syntax Int ::= max(CPPIntegerType) [function, klabel(maxCpp)]
                  | min(CPPIntegerType) [function, klabel(minCpp)]

     syntax Tag ::= getTag(CPPTypeExpr) [function, klabel(getTagCpp)]

     syntax ClassInfo ::= getClassInfo(CPPClassType) [function]
                        | #getClassInfo(CPPClassType, K) [function]
     syntax ClassInfo ::= ClassCell | "#incomplete"

     syntax Bool ::= CPPType "==Type" CPPType [function]
                   | CPPType "=/=Type" CPPType [function]

endmodule

module CPP-TYPING
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports K-REFLECTION
     imports COMMON-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule getParams(t(_, _, functionType(_, L::CPPTypes, _))) => toList(L)
     rule getReturnType(t(_, _, functionType(T::CPPType, _, _))) => T

     rule const(T::CPPSimpleType) => t(toQuals(SetItem(Const())), .Set, T)

     rule type(T::CPPSimpleType) => t(noQuals, .Set, T)
     rule type(lv(_, _, T::CPPType)) => T
     rule type(le(_, _, T::CPPType)) => T
     rule type(prv(_, _, T::CPPType)) => T
     rule type(pre(_, _, T::CPPType)) => T
     rule type(xv(_, _, T::CPPType)) => T
     rule type(xe(_, _, T::CPPType)) => T

     rule innerType(t(_, _, pointerType(T::CPPType))) => T
     rule innerType(t(_, _, arrayType(T::CPPType, _))) => T
     rule innerType(t(_, _, incompleteArrayType(T::CPPType))) => T
     rule innerType(t(_, _, lvRefType(T::CPPType))) => T
     rule innerType(t(_, _, rvRefType(T::CPPType))) => T

     rule simpleType(t(_, _, T::CPPSimpleType)) => T

     rule isObjectType(T:K) => notBool isCPPFunctionType(T) andBool notBool isCPPRefType(T) andBool notBool isCPPVoidType(T)

     rule utype(V::Val) => utype(type(V))
     rule utype(t(_, Mods::Set, T::CPPSimpleType)) => t(noQuals, Mods, T)

     rule isVolatileType(t(Q::Quals, _, _)) => Volatile() inQuals Q

     rule getTag(t(_, _, classType(_ :: Class(Tag::Tag, _, _)))) => Tag
     rule getTag(_) => .K [owise]

     rule getQuals(t(Q::Quals, _, _)) => Q

     rule getClassInfo(T::CPPClassType) => #getClassInfo(T, #configuration)
     rule #getClassInfo(t(_, _, classType(C::Class)), <generatedTop>... <class> <class-id> C </class-id> B::Bag </class> ...</generatedTop>) => <class> <class-id> C </class-id> B </class>
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

     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, signed-char)) => t(Q, Mods, unsigned-char)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, short)) => t(Q, Mods, unsigned-short)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, int)) => t(Q, Mods, unsigned)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, long)) => t(Q, Mods, unsigned-long)
     rule correspondingUnsignedType(t(Q::Quals, Mods::Set, long-long)) => t(Q, Mods, unsigned-long-long)

     rule T1::CPPType ==Type T2::CPPType => T1 ==K T2
     rule T1::CPPType =/=Type T2::CPPType => T1 =/=K T2

endmodule

module C-CPP-TYPING
     imports C-TYPING-SYNTAX
     imports CPP-TYPING
     imports COMPAT-SYNTAX

     rule convertTypeToC(t(Q::Quals, Mods::Set, functionType(Ret::CPPType, Args::CPPTypes, CLinkage))) => t(Q, Mods, functionType(utype(convertTypeToC(Ret)), mapList(toList(Args), #klabel(`convertTypeToC`))))
     rule convertTypeToC(t(Q::Quals, Mods::Set, int::CPPSimpleSignedType)) => t(Q, Mods, int::SimpleSignedIntType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned)) => t(Q, Mods, unsigned-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, long)) => t(Q, Mods, long-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-long)) => t(Q, Mods, unsigned-long-int)
     rule convertTypeToC(t(Q::Quals, Mods::Set, signed-char::CPPSimpleSignedCharType)) => t(Q, Mods, signed-char::SimpleSignedCharType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, unsigned-char::CPPSimpleUnsignedCharType)) => t(Q, Mods, unsigned-char::SimpleUnsignedCharType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, char::CPPSimpleCharType)) => t(Q, Mods, char::SimpleCharType)
     rule convertTypeToC(variadic::CPPVariadic) => variadic::Variadic
     rule convertTypeToC(t(Q::Quals, Mods::Set, pointerType(T::CPPType))) => t(Q, Mods, pointerType(convertTypeToC(T)))


     rule convertTypeToCPP(t(Q::Quals, Mods::Set, int::SimpleSignedIntType)) => t(Q, Mods, int::CPPSimpleSignedType)

     rule max(T::CPPIntegerType) => max(utype(convertTypeToC(T)))
     rule min(T::CPPIntegerType) => min(utype(convertTypeToC(T)))

endmodule
