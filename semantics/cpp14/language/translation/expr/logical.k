module CPP-EXPR-LOGICAL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (V:PRVal => convertType(type(bool), V)) || _
          requires notBool isCPPBoolType(type(V))
     rule _ || (V:PRVal => convertType(type(bool), V))
          requires notBool isCPPBoolType(type(V))

     context (HOLE:Expr => reval(HOLE)) || _ [result(PRVal)]
     context _ || (HOLE:Expr => reval(HOLE)) [result(PRVal)]

     rule L:PRVal || R:PRVal => pre(stripHold(L) || stripHold(R), combine(trace(L), trace(R), #klabel(`_||__CPP-SYNTAX`)), type(bool))
          requires isCPPBoolType(type(L))
               andBool isCPPBoolType(type(R))
               andBool isTExpr(L)
     rule prv(0, _, _:CPPBoolType) || R:PRVal => R
     rule prv(1, Tr::Trace, T:CPPBoolType) || _:PRVal => prv(1, Tr, T)
     rule prv((unknown(I::Int) => {#if I ==Int 0 #then 0 #else 1 #fi}:>Int), _, _:CPPBoolType) || _:PRVal

endmodule
