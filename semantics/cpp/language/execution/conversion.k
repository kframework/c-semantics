module CPP-EXECUTION-CONVERSION
     imports CPP-CONVERSION-SYNTAX
     imports CPP-SYNTAX

endmodule

module C-CPP-VAL-CONVERSION-SYNTAX
     imports C-DYNAMIC-SORTS
     imports CPP-DYNAMIC-SORTS
     syntax PRVal ::= convertValToCPP(RValue) [function]
endmodule

module C-CPP-EXECUTION-VAL-CONVERSION
     imports C-CPP-VAL-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule reval(V::Expr)::Expr => reval(convertValToCPP({V}:>RValue))::Expr
          requires isRValue(V)

     rule convertValToCPP(tv(V::CValue, T::UType)) => prv({V}:>CPPValue, noTrace, convertTypeToCPP(type(T)))
          requires isCPPValue(V)

     rule convertValToCPP(voidVal) => prv(voidVal, noTrace, type(void))

endmodule
