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
     rule byteSizeofType(functionType(_, _, _)) => 0
     rule byteSizeofType(signed-char) => cfg:sizeofSignedChar
     rule byteSizeofType(int) => cfg:sizeofInt
     rule byteSizeofType(nullptr_t) => cfg:ptrsize

     rule bitSizeofType(T::CPPType) => byteSizeofType(T) *Int cfg:bitsPerByte
          requires notBool isCPPBitfieldType(T)

endmodule
