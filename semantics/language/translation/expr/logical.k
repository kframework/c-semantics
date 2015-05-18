module C-EXPR-LOGICAL-SYNTAX
     syntax KItem ::= simplifyTruth(K) [function]
endmodule

module C-EXPR-LOGICAL
     imports C-EXPR-LOGICAL-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule simplifyTruth(V:K) => V != tv(0, t(SetItem(IntegerConstant), int))

     context _ && (HOLE => reval(HOLE)) [result(RValue)]
     rule L:RValue && R:RValue
          => #and(simplifyTruth(stripHold(L)), simplifyTruth(stripHold(R)))

     syntax KItem ::= #and(K, K)
     context #and((HOLE => reval(HOLE)), _) [result(RValue)]
     context #and(_, (HOLE => reval(HOLE))) [result(RValue)]
     rule #and(L:RValue, R:RValue)
          => te(stripHold(L) && stripHold(R), t(.Set, int))

     context _ || (HOLE => reval(HOLE)) [result(RValue)]
     rule L:RValue || R:RValue
          => #or(simplifyTruth(stripHold(L)), simplifyTruth(stripHold(R)))

     syntax KItem ::= #or(K, K)
     context #or((HOLE => reval(HOLE)), _) [result(RValue)]
     context #or(_, (HOLE => reval(HOLE))) [result(RValue)]
     rule #or(L:RValue, R:RValue)
          => te(stripHold(L) || stripHold(R), t(.Set, int))

endmodule
