module C-STATEMENT-IF-THEN
     imports C-SYNTAX

     rule [if-then-else]:
          IfThenElse(_:KResult, S1:K, S2:K) => S1 ~> S2
          [structural]

endmodule

