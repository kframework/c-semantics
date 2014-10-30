module C-STMT-IF-THEN-SYNTAX
     // TODO(chathhorn): I suppose this might not be the best place for this.
     syntax Bool ::= isTruthValue(RValue) [function]
endmodule

module C-STMT-IF-THEN
     imports C-STMT-IF-THEN-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX

     rule isTruthValue(tv(V:K, t(_, T:SimpleType))) 
          => T ==K int andBool (V ==K 0 orBool V ==K 1)

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

     rule [if-then-else-true]:
          IfThenElse(tv(1, t(_, int)), S:K, _) => sequencePoint ~> S
          [structural]
     rule [if-then-else-false]:
          IfThenElse(tv(0, t(_, int)), _, S:K) => sequencePoint ~> S
          [structural]
     rule IfThenElse((V:RValue => simplifyTruth(V)), _, _)
          when notBool isTruthValue(V)
          [structural]
endmodule

