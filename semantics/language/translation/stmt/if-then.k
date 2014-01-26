module C-STMT-IF-THEN-SYNTAX
     syntax Bool ::= isTruthValue(TypedValue) [function]
endmodule

module C-STMT-IF-THEN
     imports C-STMT-IF-THEN-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     rule isTruthValue(tv(V:K, t(_, T:SimpleType))) 
          => T ==K int andBool (V ==K 0 orBool V ==K 1 orBool V ==K symVal)

     rule IfThenElse(V:TypedValue, S1:K, S2:K) => S1 ~> discard ~> S2
          when isTruthValue(V)
          [structural]
     rule IfThenElse((V:TypedValue => simplifyTruth(V)), _, _)
          when notBool isTruthValue(V)
          [structural]

endmodule

