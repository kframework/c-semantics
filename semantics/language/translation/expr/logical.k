module C-EXPR-LOGICAL-SYNTAX
     imports BASIC-K
     syntax KItem ::= simplifyTruth(K) [function]
endmodule

module C-EXPR-LOGICAL
     imports C-EXPR-LOGICAL-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule simplifyTruth(V:K) => V != tv(0, t(SetItem(IntegerConstant), int))

     rule L:K && R:K => #and(simplifyTruth(L), simplifyTruth(R))

     syntax KItem ::= #and(K, K)
     context #and((HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     context #and(_, (HOLE:KItem => reval(HOLE))) [result(RValue)]
     rule #and(L:RValue, R:RValue)
          => te(stripHold(L) && stripHold(R), t(.Set, int))
     requires isHold(L)
     rule #and(tv(0, t(S:Set, int)), _:RValue) => tv(0, t(S, int))
     rule #and(tv(1, t(S:Set, int)), R:RValue) => R

     rule L:K || R:K => #or(simplifyTruth(L), simplifyTruth(R))

     syntax KItem ::= #or(K, K)
     context #or((HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     context #or(_, (HOLE:KItem => reval(HOLE))) [result(RValue)]
     rule #or(L:RValue, R:RValue)
          => te(stripHold(L) || stripHold(R), t(.Set, int))
     requires isHold(L)
     rule #or(tv(0, t(S:Set, int)), R:RValue) => R
     rule #or(tv(1, t(S:Set, int)), _:RValue) => tv(1, t(S, int))

endmodule
