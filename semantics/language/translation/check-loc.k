module C-CHECK-LOC
     imports C-MEMORY-ALLOC-SYNTAX

     rule isValidLoc(_) => true
     rule isInBounds(_) => true

     rule errorLocInvalid => .
     rule errorLocBounds => .
endmodule
