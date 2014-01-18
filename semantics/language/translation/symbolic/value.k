module C-SYMBOLIC-VALUE-SYNTAX
     syntax SymLoc ::= SymVal
     syntax SymVal ::= "symVal"
endmodule

module C-SYMBOLIC-VALUE
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX

     rule symVal +bits _:Int => symVal
     rule symVal +bytes _:Int => symVal

     rule floorLoc(symVal) => symVal
     rule ceilingLoc(symVal) => symVal

     rule write-aux(symVal, _, _) => .
          [structural]

     rule bitSizeofType(T:Type) => tv(symVal, T)
          when isIncompleteType(T)

endmodule
