module C-EXPR-SEQUENCING
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     rule Comma(list(ListItem(K:K) L:List))
          => commaEval(K) ~> discard ~> Comma(list(L))
          when L =/=List .List
          [structural]
     rule Comma(list(ListItem(K:K))) => commaEval(K)
          [structural]

     syntax K ::= commaEval(K) [strict(all(context('reval), result(Value)))]
     rule commaEval(V:Value) => V

endmodule
