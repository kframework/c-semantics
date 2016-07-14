module CPP-TYPING-SYNTAX
     imports COMMON-SYNTAX
     imports CPP-SYNTAX
     imports MEMORY-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     syntax AType ::= CPPType

     syntax CPPType ::= t(Quals, Set, CPPSimpleType) [klabel(tcpp)]
     syntax CPPDType ::= typedDeclaration(CPPType, CId) [klabel(dtcpp)]

     syntax CPPType ::= innerType(CPPType) [function, klabel(cppInnerType)]

     syntax EffectiveType ::= CPPType

     syntax CPPSimpleType ::= CPPSimpleBasicType

     syntax CPPSimpleBasicType ::= CPPSimpleIntegerType | CPPSimpleVoidType
     syntax CPPSimpleIntegerType ::= CPPSimpleSignedType | CPPSimpleCharType
     syntax CPPSimpleSignedType ::= "int" | CPPSimpleSignedCharType
     syntax CPPSimpleCharType ::= CPPSimpleSignedCharType | CPPSimpleUnsignedCharType
     syntax CPPSimpleSignedCharType ::= "signed-char"
     syntax CPPSimpleUnsignedCharType ::= "unsigned-char"
     syntax CPPSimpleVoidType ::= "void"
     syntax CPPSimpleCharType ::= "char" [function]

     syntax CPPSimpleType ::= CPPSimplePointerType
                            | CPPSimpleFunctionType
                            | CPPSimpleArrayType
                            | CPPSimpleRefType
     syntax CPPSimpleRefType ::= CPPSimpleLVRefType
                               | CPPSimpleRVRefType

     syntax CPPSimpleArrayType ::= CPPSimpleFixedArrayType
     syntax CPPSimpleFixedArrayType ::= arrayType(CPPType, Int) [klabel(cppArrayType)]

     syntax CPPSimplePointerType ::= pointerType(CPPType) [klabel(cppPointerType)]
     syntax CPPSimpleLVRefType ::= lvRefType(CPPType)
     syntax CPPSimpleRVRefType ::= rvRefType(CPPType)
     syntax CPPSimpleFunctionType ::= functionType(CPPType, List, Prototype, LanguageLinkage) [klabel(cppFunctionType)]

     syntax CPPFunctionType ::= t(Quals, Set, CPPSimpleFunctionType) [klabel(tcpp)]
     syntax CPPBasicType ::= CPPIntegerType | CPPVoidType
     syntax CPPIntegerType ::= t(Quals, Set, CPPSimpleIntegerType) [klabel(tcpp)]
     syntax CPPVoidType ::= t(Quals, Set, CPPSimpleVoidType) [klabel(tcpp)]
     syntax CPPArrayType ::= t(Quals, Set, CPPSimpleArrayType) [klabel(tcpp)]
     syntax CPPPointerType ::= t(Quals, Set, CPPSimplePointerType) [klabel(tcpp)]
     syntax CPPLVRefType ::= t(Quals, Set, CPPSimpleLVRefType) [klabel(tcpp)]
     syntax CPPRVRefType ::= t(Quals, Set, CPPSimpleRVRefType) [klabel(tcpp)]
     syntax CPPRefType ::= CPPLVRefType | CPPRVRefType
     syntax CPPClassType
     syntax CPPCompleteType ::= CPPFunctionType | CPPPointerType
     syntax CPPType ::= CPPCompleteType | CPPFunctionType | CPPArrayType

     syntax Prototype ::= proto(List, Expr)
                        | "noproto"

     syntax CPPDType ::= "variadic"

     syntax List ::= getParams(CPPFunctionType) [function, klabel(cppgetParams)]

     syntax CPPType ::= const(CPPSimpleType) [function, klabel(constCpp)]

     syntax CPPType ::= type(CPPSimpleType) [function, klabel(cppType)]
     syntax CPPType ::= utype(Typed) [function, klabel(cppUTypeVal)]
     syntax CPPType ::= type(Typed) [function, klabel(cppTypeVal)]
     syntax CPPType ::= utype(CPPType) [function, klabel(cppUTypeType)]

     syntax Typed ::= Val | TExpr

     syntax Bool ::= isCPPObjectType(K) [function]

     syntax Bool ::= isVolatileType(CPPType) [function, klabel(isVolatileTypeCPP)]

endmodule

module CPP-TYPING
     imports CPP-TYPING-SYNTAX

     rule getParams(t(_, _, functionType(_, L::List, _, _))) => L

     rule const(T::CPPSimpleType) => t(toQuals(SetItem(Const())), .Set, T)

     rule type(T::CPPSimpleType) => t(noQuals, .Set, T)
     rule type(lv(_, T::CPPType)) => T
     rule type(le(_, T::CPPType)) => T

     rule innerType(t(_, _, pointerType(T::CPPType))) => T
     rule innerType(t(_, _, arrayType(T::CPPType, _))) => T
     rule innerType(t(_, _, lvRefType(T::CPPType))) => T
     rule innerType(t(_, _, rvRefType(T::CPPType))) => T

     rule isCPPObjectType(T:K) => notBool isCPPFunctionType(T) andBool notBool isCPPRefType(T) andBool notBool isCPPVoidType(T)

     rule utype(lv(_, T::CPPType)) => utype(T)
     rule utype(le(_, T::CPPType)) => utype(T)
     rule utype(t(_, Mods::Set, T::CPPSimpleType)) => t(noQuals, Mods, T)

     rule isVolatileType(t(Q::Quals, _, _)) => Volatile() inQuals Q

endmodule
