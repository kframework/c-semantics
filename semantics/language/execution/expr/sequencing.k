module C-EXPR-SEQUENCING
     imports C-COMMON-EXPR-EVAL-SYNTAX

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

     rule Comma(list(ListItem(K:K) L:List))
          => toRVal(K) ~> discard ~> sequencePoint ~> Comma(list(L))
          when L =/=List .List
          [structural]
     rule Comma(list(ListItem(K:K))) => toRVal(K)
          [structural]

endmodule
