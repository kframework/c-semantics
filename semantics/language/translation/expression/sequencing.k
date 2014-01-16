module C-EXPRESSION-SEQUENCING
     imports C-EXPRESSION-EVAL-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     syntax K ::= commaEval(K) [strict]

     rule commaEval(R:KResult) => rkludge(R)
          [structural]

     rule Comma(klist(K:K,, L:KList)) 
          => commaEval(K) ~> discard ~> Comma(klist(L))
          when L =/=KList .KList
          [structural]
     rule Comma(klist(K:K)) => commaEval(K)
          [structural]
endmodule
