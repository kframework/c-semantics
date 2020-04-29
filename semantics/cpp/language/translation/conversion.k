module CPP-TRANSLATION-CONVERSION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule convertType(t(... st: pointerType(...)) #as T::CPPType, prv(0, hasTrace(IntegerLiteral(0, T2::CPPType)), _)) => prv(NullPointer, hasTrace(IntegerLiteral(0, T2)), T)

     rule convertType(t(... st: nullptr_t) #as T::CPPType, prv(0, hasTrace(IntegerLiteral(0, T2::CPPType)), _)) => prv(nullptrVal, hasTrace(IntegerLiteral(0, T2)), T)

     rule convertType(t(... st: memberPointerType(...)) #as T::CPPType, prv(0, hasTrace(IntegerLiteral(0, T2::CPPType)), _)) => prv(NullMemberPointer, hasTrace(IntegerLiteral(0, T2)), T)

     rule convertType(T::CPPType, pre(E:Expr, Tr::Trace, _)) => pre(ConvertType(T, E), Tr, T)

     rule isNullPointerConstant(prv(_, hasTrace(IntegerLiteral(0, _)), _)) => true

     rule isNullPointerConstant(pre(_, _, _)) => false

endmodule
