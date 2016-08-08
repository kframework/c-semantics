module CPP-TYPING-SORTS
     syntax AType
     syntax CPPType
     syntax CPPDType
     syntax CPPSimpleType
     syntax EffectiveType ::= CPPType
endmodule

module CPP-TYPING-SYNTAX
     imports BASIC-K
     imports SET
     imports CPP-TYPING-SORTS
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS

     syntax AType ::= CPPType

     syntax CPPType ::= t(Quals, Set, CPPSimpleType) [klabel(tcpp)]
     syntax CPPDType ::= typedDeclaration(CPPType, CId) [klabel(dtcpp)]

     syntax CPPType ::= innerType(CPPType) [function, klabel(cppInnerType)]

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
     syntax CPPSimpleCharType ::= "char" [function]
     syntax CPPSimpleIntegerType ::= "wchar_t" | "char16_t" | "char32_t"
     syntax CPPSimpleNullPtrTType ::= "nullptr_t"

     syntax CPPSimpleType ::= CPPSimplePointerType
                            | CPPSimpleFunctionType
                            | CPPSimpleArrayType
                            | CPPSimpleRefType
                            | CPPSimpleNullPtrTType
     syntax CPPSimpleRefType ::= CPPSimpleLVRefType
                               | CPPSimpleRVRefType

     syntax CPPSimpleArrayType ::= CPPSimpleFixedArrayType
     syntax CPPSimpleFixedArrayType ::= arrayType(CPPType, Int) [klabel(cppArrayType)]

     syntax CPPSimplePointerType ::= pointerType(CPPType) [klabel(cppPointerType)]
     syntax CPPSimpleLVRefType ::= lvRefType(CPPType)
     syntax CPPSimpleRVRefType ::= rvRefType(CPPType)
     // TODO: exception specification
     syntax CPPSimpleFunctionType ::= functionType(CPPType, List, LanguageLinkage) [klabel(cppFunctionType)]

     syntax CPPFunctionType ::= t(Quals, Set, CPPSimpleFunctionType) [klabel(tcpp)]
     syntax CPPBasicType ::= CPPIntegerType | CPPVoidType
     syntax CPPIntegerType ::= t(Quals, Set, CPPSimpleIntegerType) [klabel(tcpp)]
     syntax CPPVoidType ::= t(Quals, Set, CPPSimpleVoidType) [klabel(tcpp)]
     syntax CPPArrayType ::= t(Quals, Set, CPPSimpleArrayType) [klabel(tcpp)]
     syntax CPPPointerType ::= t(Quals, Set, CPPSimplePointerType) [klabel(tcpp)]
     syntax CPPLVRefType ::= t(Quals, Set, CPPSimpleLVRefType) [klabel(tcpp)]
     syntax CPPRVRefType ::= t(Quals, Set, CPPSimpleRVRefType) [klabel(tcpp)]
     syntax CPPNullPtrTType ::= t(Quals, Set, CPPSimpleNullPtrTType) [klabel(tcpp)]
     syntax CPPRefType ::= CPPLVRefType | CPPRVRefType
     syntax CPPClassType
     syntax CPPBitfieldType
     syntax CPPCompleteType ::= CPPFunctionType | CPPPointerType | CPPIntegerType
     syntax CPPType ::= CPPCompleteType | CPPArrayType

     syntax CPPDType ::= "variadic"

     syntax List ::= getParams(CPPFunctionType) [function, klabel(cppgetParams)]
     syntax CPPType ::= getReturnType(CPPFunctionType) [function, klabel(cppgetReturnType)]

     syntax CPPType ::= const(CPPSimpleType) [function, klabel(constCpp)]

     syntax CPPType ::= type(CPPSimpleType) [function, klabel(cppType)]
     syntax CPPType ::= utype(Typed) [function, klabel(cppUTypeVal)]
     syntax CPPType ::= type(Typed) [function, klabel(cppTypeVal)]
     syntax CPPType ::= utype(CPPType) [function, klabel(cppUTypeType)]

     syntax Typed ::= Val | TExpr

     syntax Bool ::= isCPPObjectType(K) [function]

     syntax Bool ::= isVolatileType(CPPType) [function, klabel(isVolatileTypeCPP)]

     syntax Type ::= convertTypeToC(CPPType) [function]
     syntax DType ::= convertTypeToC(CPPDType) [function]

     syntax CPPType ::= convertTypeToCPP(Type) [function]
     syntax CPPDType ::= convertTypeToCPP(DType) [function]

     syntax Int ::= max(CPPIntegerType) [function, klabel(maxCpp)]
                  | min(CPPIntegerType) [function, klabel(minCpp)]

endmodule

module CPP-TYPING
     imports CPP-TYPING-SYNTAX
     imports BOOL
     imports COMMON-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule getParams(t(_, _, functionType(_, L::List, _))) => L
     rule getReturnType(t(_, _, functionType(T::CPPType, _, _))) => T

     rule const(T::CPPSimpleType) => t(toQuals(SetItem(Const())), .Set, T)

     rule type(T::CPPSimpleType) => t(noQuals, .Set, T)
     rule type(lv(_, T::CPPType)) => T
     rule type(le(_, T::CPPType)) => T
     rule type(prv(_, T::CPPType)) => T
     rule type(pre(_, T::CPPType)) => T
     rule type(xv(_, T::CPPType)) => T
     rule type(xe(_, T::CPPType)) => T

     rule innerType(t(_, _, pointerType(T::CPPType))) => T
     rule innerType(t(_, _, arrayType(T::CPPType, _))) => T
     rule innerType(t(_, _, lvRefType(T::CPPType))) => T
     rule innerType(t(_, _, rvRefType(T::CPPType))) => T

     rule isCPPObjectType(T:K) => notBool isCPPFunctionType(T) andBool notBool isCPPRefType(T) andBool notBool isCPPVoidType(T)

     rule utype(V::Val) => utype(type(V))
     rule utype(t(_, Mods::Set, T::CPPSimpleType)) => t(noQuals, Mods, T)

     rule isVolatileType(t(Q::Quals, _, _)) => Volatile() inQuals Q

endmodule

module C-CPP-TYPING
     imports C-TYPING-SYNTAX
     imports CPP-TYPING
     imports COMPAT-SYNTAX

     rule convertTypeToC(t(Q::Quals, Mods::Set, functionType(Ret::CPPType, Args::List, CLinkage))) => t(Q, Mods, functionType(utype(convertTypeToC(Ret)), mapList(Args, #klabel(`convertTypeToC`))))
     rule convertTypeToC(t(Q::Quals, Mods::Set, int::CPPSimpleSignedType)) => t(Q, Mods, int::SimpleSignedIntType)
     rule convertTypeToC(t(Q::Quals, Mods::Set, signed-char::CPPSimpleSignedCharType)) => t(Q, Mods, signed-char::SimpleSignedCharType)
     rule convertTypeToC(variadic::CPPDType) => variadic::Variadic
     rule convertTypeToC(t(Q::Quals, Mods::Set, pointerType(T::CPPType))) => t(Q, Mods, pointerType(convertTypeToC(T)))


     rule convertTypeToCPP(t(Q::Quals, Mods::Set, int::SimpleSignedIntType)) => t(Q, Mods, int::CPPSimpleSignedType)

     rule max(T::CPPIntegerType) => max(utype(convertTypeToC(T)))
     rule min(T::CPPIntegerType) => min(utype(convertTypeToC(T)))

endmodule
