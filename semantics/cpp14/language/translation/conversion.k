module CPP-TRANSLATION-CONVERSION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule convertType(T:CPPPointerType, prv(0, hasTrace(IntegerLiteral(0, T2::CPPType)), _)) => prv(NullPointer, hasTrace(IntegerLiteral(0, T2)), T)
     rule convertType(T:CPPNullPtrTType, prv(0, hasTrace(IntegerLiteral(0, T2::CPPType)), _)) => prv(nullptrVal, hasTrace(IntegerLiteral(0, T2)), T)

endmodule
