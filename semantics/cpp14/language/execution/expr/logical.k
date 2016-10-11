module CPP-EXPR-LOGICAL
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     context ! (HOLE:Expr => reval(HOLE)) [ndheat, result(PRVal)]
     rule ! prv(0, _, T:CPPBoolType)
          => prv(1, noTrace, T)
     rule ! prv(1, _, T:CPPBoolType)
          => prv(0, noTrace, T)
     rule ! prv((unknown(I:Int) => {#if I ==Int 0 #then 0 #else 1 #fi}:>Int), _, _:CPPBoolType)

endmodule
