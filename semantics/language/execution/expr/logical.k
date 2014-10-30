module C-EXPR-LOGICAL
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-STMT-IF-THEN-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX

     /*@ Here, we wrapped the controlling expressions with
     \kinline{simplifyTruth} when heating them, so that we are guaranteed
     the values in those locations are either \kinline{tv(0, int)} or
     \kinline{tv(1, int)}.*/
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.13}{3--4}}}{
     The \cinline{&&} operator shall yield 1 if both of its operands compare
     unequal to 0; otherwise, it yields 0. The result has type \cinline{int}.
     
     Unlike the bitwise binary \cinline{&} operator, the \cinline{&&} operator
     guarantees left-to-right evaluation; if the second operand is evaluated,
     there is a sequence point between the evaluations of the first and second
     operands. If the first operand compares equal to 0, the second operand is
     not evaluated.
     } */ 
     rule tv(0, t(_, int)) && _ => tv(0, t(.Set, int))
          [structural]
     rule tv(1, t(_, int)) && E:K
          => sequencePoint ~> simplifyTruth(E)
          [structural]
     rule (V:RValue => simplifyTruth(V)) && _ 
          when notBool isTruthValue(V)
          [structural]   
                    
     /*@ \fromStandard{\source[n1570]{\para{6.5.14}{3--4}}}{
     The \cinline{||} operator shall yield 1 if either of its operands compare
     unequal to 0; otherwise, it yields 0. The result has type \cinline{int}.

     Unlike the bitwise \cinline{|} operator, the \cinline{||} operator
     guarantees left-to-right evaluation; if the second operand is evaluated,
     there is a sequence point between the evaluations of the first and second
     operands. If the first operand compares unequal to 0, the second operand
     is not evaluated.
     }*/
     rule tv(0, t(_, int)) || E:K
          => sequencePoint ~> simplifyTruth(E)
          [structural]
     rule tv(1, t(_, int)) || _ => tv(1, t(.Set, int))
          [structural]
     rule (V:RValue => simplifyTruth(V)) || _
          when notBool isTruthValue(V)
          [structural]

endmodule
