module C-EXPRESSION-SEQUENCING
     imports C-COMMON-EXPRESSION-EVAL-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports COMPAT-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.17}{2}}}{
     The left operand of a comma operator is evaluated as a void expression;
     there is a sequence point between its evaluation and that of the right
     operand. Then the right operand is evaluated; the result has its type and
     value.
     }*/

     syntax K ::= commaEval(K) [strict]

     rule commaEval(R:KResult) => rkludge(R)
          [structural]

     rule Comma(klist(K:K,, L:KList)) 
          => commaEval(K) ~> discard ~> sequencePoint ~> Comma(klist(L))
          when L =/=KList .KList
          [structural]
     rule Comma(klist(K:K)) => commaEval(K)
          [structural]
endmodule
