module CPP-BITSIZE-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax Int ::= byteSizeofType(CPPType) [klabel(byteSizeofTypeCpp), function]
endmodule

module CPP-BITSIZE
     imports CPP-BITSIZE-SYNTAX
     imports C-SETTINGS-SYNTAX

     syntax Int ::= byteSizeofType(CPPSimpleType) [klabel(byteSizeofSimpleTypeCpp), function]
     rule byteSizeofType(t(_, _, T::CPPSimpleType)) => byteSizeofType(T)

     rule byteSizeofType(pointerType(_)) => cfg:ptrsize
     rule byteSizeofType(functionType(_, _, _, _)) => 0

endmodule
