module C-EXPR-SEQUENCING
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     syntax KItem ::= commaEval(K) [strict]

     rule commaEval(R:KResult) => rkludge(R)
          [structural]

     rule Comma(list(ListItem(K:K) L:List)) 
          => commaEval(K) ~> discard ~> Comma(list(L))
          when L =/=MSet .List
          [structural]
     rule Comma(list(ListItem(K:K))) => commaEval(K)
          [structural]
endmodule
