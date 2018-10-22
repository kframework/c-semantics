module C-STMT-IF-THEN
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.8}{4}}}{
     \ldots There is a sequence point between the evaluation of a full
     expression and the evaluation of the next full expression to be evaluated.
     }*/

     /*@ \fromStandard{\source[n1570]{\para{6.8.4.1}{10}}}{
     In both forms, the first substatement is executed if the expression
     compares unequal to 0. In the \cinline{else} form, the second substatement
     is executed if the expression compares equal to 0. If the first
     substatement is reached via a label, the second substatement is not
     executed.
     }*/
     rule IfThenElse(tv((unknown(I:Int) => #if I ==Int 0 #then 0 #else 1 #fi), ut(_, int)), _, _)

     rule [if-then-else-true]:
          IfThenElse(tv(1, ut(_, int)), S:K, _) => sequencePoint ~> S
          [structural]
     rule [if-then-else-false]:
          IfThenElse(tv(0, ut(_, int)), _, S:K) => sequencePoint ~> S
          [structural]

endmodule

