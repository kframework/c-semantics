module C-SYMBOLIC-VALUE-SYNTAX
     syntax SymLoc ::= SymVal
     syntax SymVal ::= "symVal"
endmodule

module C-SYMBOLIC-VALUE
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX

     rule symVal +bits _:Int => symVal
     rule symVal +bytes _:Int => symVal

     rule floorLoc(symVal) => symVal
     rule ceilingLoc(symVal) => symVal

     rule write-aux(symVal, _, _) => .
          [structural]

endmodule
