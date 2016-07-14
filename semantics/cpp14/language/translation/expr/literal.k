module CPP-EXPR-LITERAL
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYMLOC-SYNTAX

     syntax Expr ::= StringLiteral(String, K) [klabel(StringLiteral2)]
     context StringLiteral(_, (HOLE:KItem => typeof(HOLE)))

     rule StringLiteral(S::String) => StringLiteral(S, StringLiteral(S))

     rule StringLiteral(S::String, T:CPPType) => lv(lnew(string(S), T), T)

endmodule
