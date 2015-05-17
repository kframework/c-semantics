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
     rule te(L:K, _) && te(R:K, _) => #and(simplifyTruth(L), simplifyTruth(R))
     rule te(L:K, _) && tv(V:CValue, T:Type)
          => #and(simplifyTruth(L), simplifyTruth(tv(V, T)))

     syntax KItem ::= #and(K, K)
     context #and((HOLE => reval(HOLE)), _) [result(RValue)]
     context #and(_, (HOLE => reval(HOLE))) [result(RValue)]
     rule #and(L:RValue, R:RValue)
          => te(stripHold(L) && stripHold(R), t(.Set, int))

     context _ || (HOLE => reval(HOLE)) [result(RValue)]
     rule te(L:K, _) || te(R:K, _) => #or(simplifyTruth(L), simplifyTruth(R))
     rule te(L:K, _) || tv(V:CValue, T:Type)
          => #or(simplifyTruth(L), simplifyTruth(tv(V, T)))

     syntax KItem ::= #or(K, K)
     context #or((HOLE => reval(HOLE)), _) [result(RValue)]
     context #or(_, (HOLE => reval(HOLE))) [result(RValue)]
     rule #or(L:RValue, R:RValue)
          => te(stripHold(L) || stripHold(R), t(.Set, int))

endmodule
