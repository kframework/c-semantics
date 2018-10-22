module C-EXPR-LOGICAL-SYNTAX
     imports BASIC-K
     syntax KItem ::= simplifyTruth(K) [function]
endmodule

module C-EXPR-LOGICAL
     imports C-EXPR-LOGICAL-SYNTAX
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule simplifyTruth(V:K) => V != tv(0, ut(SetItem(IntegerConstant), int))

     rule L:K && R:K => #and(simplifyTruth(L), simplifyTruth(R))

     syntax KItem ::= #and(K, K)
     context #and((HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     context #and(_, (HOLE:KItem => reval(HOLE))) [result(RValue)]
     rule #and(L:RValue, R:RValue)
          => te(stripHold(L) && stripHold(R), utype(int))
     requires isHold(L)
     rule #and(tv(0, ut(S:Set, int)), _:RValue) => tv(0, ut(S, int))
     rule #and(tv(1, ut(S:Set, int)), R:RValue) => R
     rule #and(tv((unknown(I:Int) => #if I ==Int 0 #then 0 #else 1 #fi), ut(_, int)), _)

     rule L:K || R:K => #or(simplifyTruth(L), simplifyTruth(R))

     syntax KItem ::= #or(K, K)
     context #or((HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     context #or(_, (HOLE:KItem => reval(HOLE))) [result(RValue)]
     rule #or(L:RValue, R:RValue)
          => te(stripHold(L) || stripHold(R), utype(int))
     requires isHold(L)
     rule #or(tv(0, ut(S:Set, int)), R:RValue) => R
     rule #or(tv(1, ut(S:Set, int)), _:RValue) => tv(1, ut(S, int))
     rule #or(tv((unknown(I:Int) => #if I ==Int 0 #then 0 #else 1 #fi), ut(_, int)), _)

endmodule
