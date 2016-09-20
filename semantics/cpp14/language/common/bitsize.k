module CPP-BITSIZE-SYNTAX
     imports CPP-TYPING-SORTS

     syntax Int ::= byteSizeofType(CPPType) [klabel(byteSizeofTypeCpp), function]
     syntax Int ::= bitSizeofType(CPPType) [klabel(bitSizeofTypeCpp), function]
endmodule

module CPP-BITSIZE
     imports CPP-BITSIZE-SYNTAX
     imports INT
     imports C-SETTINGS-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax Int ::= byteSizeofType(CPPSimpleType) [klabel(byteSizeofSimpleTypeCpp), function]
     rule byteSizeofType(t(_, _, T::CPPSimpleType)) => byteSizeofType(T)

     rule byteSizeofType(pointerType(_)) => cfg:ptrsize
     rule byteSizeofType(arrayType(t(_, _, S::CPPSimpleType), N::Int)) => N *Int byteSizeofType(S)
     rule byteSizeofType(functionType(_, _, _)) => 0
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
     rule byteSizeofType(unsigned-long-long) => cfg:sizeofLongLongInt
     rule byteSizeofType(float) => cfg:sizeofFloat
     rule byteSizeofType(double) => cfg:sizeofDouble
     rule byteSizeofType(long-double) => cfg:sizeofLongDouble
     rule byteSizeofType(nullptr_t) => cfg:ptrsize

     rule bitSizeofType(T::CPPType) => byteSizeofType(T) *Int cfg:bitsPerByte
          requires notBool isCPPBitfieldType(T)

endmodule
