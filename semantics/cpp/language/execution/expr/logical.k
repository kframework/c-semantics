module CPP-EXECUTION-EXPR-LOGICAL
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     context ! (HOLE:Expr => reval(HOLE)) requires Execution() [ndheat, result(PRV)]

     rule ! prv(0, _, t(... st: _:CPPSimpleBoolType) #as T::CPPType)
          => prv(1, noTrace, T)
          requires Execution()

     rule ! prv(1, _, t(... st: _:CPPSimpleBoolType) #as T::CPPType)
          => prv(0, noTrace, T)
          requires Execution()

     rule ! prv((unknown(I:Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, t(... st: _:CPPSimpleBoolType))
          requires Execution()

     context (HOLE:Expr => reval(HOLE)) || _ requires Execution() [result(PRV)]

     rule prv(0, _, t(... st: _:CPPSimpleBoolType)) || R::Expr => R
          requires Execution()

     rule prv(1, Tr::Trace, t(... st: _:CPPSimpleBoolType) #as T::CPPType) || _ => prv(1, Tr, T)
          requires Execution()

     rule prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, t(... st: _:CPPSimpleBoolType)) || _
          requires Execution()

     context (HOLE:Expr => reval(HOLE)) && _ requires Execution() [result(PRV)]

     rule prv(1, _, t(... st: _:CPPSimpleBoolType)) && R::Expr => R
          requires Execution()

     rule prv(0, Tr::Trace, t(... st: _:CPPSimpleBoolType) #as T::CPPType) && _ => prv(0, Tr, T)
          requires Execution()

     rule prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, t(... st: _:CPPSimpleBoolType)) && _
          requires Execution()

endmodule
