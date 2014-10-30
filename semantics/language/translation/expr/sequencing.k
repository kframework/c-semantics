module C-EXPR-SEQUENCING
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     rule Comma(list(ListItem(K:K) L:List))
          => toRVal(K) ~> discard ~> Comma(list(L))
          when L =/=List .List
          [structural]
     rule Comma(list(ListItem(K:K))) => toRVal(K)
          [structural]

endmodule
