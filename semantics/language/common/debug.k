module DEBUG-SYNTAX
     syntax K ::= assert(Bool, Int) // check, error#
     syntax K ::= "PAUSE" | PAUSE(K) | ASSERT(Bool, K)
endmodule

module DEBUG
     imports DEBUG-SYNTAX

     rule assert(true, _) => . [structural, anywhere]
     rule ASSERT(true, _) => . [structural, anywhere]
endmodule
