module C-STATIC
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     rule Computation(_:KResult) => sequencePoint
     rule Nop => .

endmodule
