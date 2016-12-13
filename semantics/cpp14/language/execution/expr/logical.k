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
     rule ! prv((unknown(I:Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, _:CPPBoolType)

     context (HOLE:Expr => reval(HOLE)) || _ [result(PRVal)]
     rule prv(0, _, _:CPPBoolType) || R::Expr => R
     rule prv(1, Tr::Trace, T:CPPBoolType) || _ => prv(1, Tr, T)
     rule prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, _:CPPBoolType) || _

     context (HOLE:Expr => reval(HOLE)) && _ [result(PRVal)]
     rule prv(1, _, _:CPPBoolType) && R::Expr => R
     rule prv(0, Tr::Trace, T:CPPBoolType) && _ => prv(0, Tr, T)
     rule prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, _:CPPBoolType) && _

endmodule
