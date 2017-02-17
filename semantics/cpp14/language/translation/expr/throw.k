module CPP-EXPR-THROW
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     context Throw(HOLE:Expr => reval(HOLE)) [result(PRVal)]

     rule Throw(V:PRVal) => pre(Throw(V), combine(trace(V), #klabel(`Throw`)), type(void))

endmodule
