module CPP-EXECUTION-EXPR-LOGICAL
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     context ! (HOLE:Expr => reval(HOLE)) requires Execution() [ndheat, result(PRV)]

     rule ! prv(0, _, T:CPPBoolType)
          => prv(1, noTrace, T)
          requires Execution()

     rule ! prv(1, _, T:CPPBoolType)
          => prv(0, noTrace, T)
          requires Execution()

     rule ! prv((unknown(I:Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, _:CPPBoolType)
          requires Execution()

     context (HOLE:Expr => reval(HOLE)) || _ requires Execution() [result(PRV)]

     rule prv(0, _, _:CPPBoolType) || R::Expr => R
          requires Execution()

     rule prv(1, Tr::Trace, T:CPPBoolType) || _ => prv(1, Tr, T)
          requires Execution()

     rule prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, _:CPPBoolType) || _
          requires Execution()

     context (HOLE:Expr => reval(HOLE)) && _ requires Execution() [result(PRV)]

     rule prv(1, _, _:CPPBoolType) && R::Expr => R
          requires Execution()

     rule prv(0, Tr::Trace, T:CPPBoolType) && _ => prv(0, Tr, T)
          requires Execution()

     rule prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, _:CPPBoolType) && _
          requires Execution()

endmodule
