module CPP-BITSIZE-SYNTAX
     imports CPP-TYPING-SORTS

     syntax Int ::= byteSizeofType(CPPType) [klabel(byteSizeofTypeCpp), function]

     syntax Int ::= bitSizeofType(CPPType) [klabel(bitSizeofTypeCpp), function]

     // Round up to the nearest multiple of the second arg * cfg:bitsPerByte.
     syntax Int ::= padTo(Int, Int) [function]
endmodule

module CPP-BITSIZE
     imports CPP-BITSIZE-SYNTAX
     imports INT
     imports CPP-CLASS-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     rule padTo(N::Int, A::Int) => N
          requires (N %Int (A *Int cfg:bitsPerByte)) ==Int 0

     rule padTo(N::Int, A::Int)
          => N +Int ((A *Int cfg:bitsPerByte) -Int (N %Int (A *Int cfg:bitsPerByte))) [owise]

     syntax Int ::= byteSizeofType(CPPSimpleType) [klabel(byteSizeofSimpleTypeCpp), function]

     rule byteSizeofType(t(_, _, T::CPPSimpleType)) => byteSizeofType(T)

     rule byteSizeofType(classType(C::Class)) => byteSizeofClass(getClassInfo(C))

     rule byteSizeofType(scopedEnum(... underlyingType: T::CPPType)) => byteSizeofType(T)

     rule byteSizeofType(unscopedEnum(... underlyingType: T::CPPType)) => byteSizeofType(T)

     syntax Int ::= byteSizeofClass(ClassInfo) [function]

     rule byteSizeofClass(<class>... <sizeof> V::Int </sizeof> ...</class>)
          => V

     syntax Int ::= bitSizeofClass(ClassInfo) [function]

     rule bitSizeofClass(C::ClassInfo) => byteSizeofClass(C) *Int cfg:bitsPerByte

     rule byteSizeofType(pointerType(_)) => cfg:ptrsize

     rule byteSizeofType(lvRefType(_)) => cfg:refsize

     rule byteSizeofType(rvRefType(_)) => cfg:refsize

     rule byteSizeofType(memberPointerType(_, t(... st: functionType(...)) #as T::CPPType)) => cfg:memberFunctionPtrSize

     rule byteSizeofType(memberPointerType(_, T::CPPType)) => cfg:memberDataPtrSize
          requires notBool(isCPPFunctionType(T))

     rule byteSizeofType(arrayType(t(_, _, S::CPPSimpleType), N::Int)) => N *Int byteSizeofType(S)

     rule byteSizeofType(functionType(...)) => 0

     rule byteSizeofType(bool) => cfg:sizeofBool

     rule byteSizeofType(signed-char) => cfg:sizeofSignedChar

     rule byteSizeofType(unsigned-char) => cfg:sizeofSignedChar

     rule byteSizeofType(char) => cfg:sizeofSignedChar

     rule byteSizeofType(short) => cfg:sizeofShortInt

     rule byteSizeofType(unsigned-short) => cfg:sizeofShortInt

     rule byteSizeofType(int) => cfg:sizeofInt

     rule byteSizeofType(unsigned) => cfg:sizeofInt

     rule byteSizeofType(long) => cfg:sizeofLongInt

     rule byteSizeofType(unsigned-long) => cfg:sizeofLongLongInt

     rule byteSizeofType(long-long) => cfg:sizeofLongInt

     rule byteSizeofType(oversized) => cfg:sizeofOversizedInt

     rule byteSizeofType(unsigned-long-long) => cfg:sizeofLongLongInt

     rule byteSizeofType(unsigned-oversized) => cfg:sizeofOversizedInt

     rule byteSizeofType(float) => cfg:sizeofFloat

     rule byteSizeofType(double) => cfg:sizeofDouble

     rule byteSizeofType(long-double) => cfg:sizeofLongDouble

     rule byteSizeofType(nullptr_t) => cfg:ptrsize

     rule byteSizeofType(T:CPPSimpleWideCharType) => byteSizeofType(underlyingType(T))

     rule byteSizeofType(bitfieldType(_, N::Int)) => (N +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte

     rule bitSizeofType(T::CPPType) => byteSizeofType(T) *Int cfg:bitsPerByte
          requires notBool isCPPBitfieldType(T)

     rule bitSizeofType(t(... st: bitfieldType(_, N::Int))) => N

endmodule
