module C-SYMBOLIC-VALUE-SYNTAX
     syntax CSize ::= SymVal
     syntax SymLoc ::= SymVal
     syntax SymVal ::= "symVal"
endmodule

module C-SYMBOLIC-VALUE
     imports C-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITS-SYNTAX

     // Various rules for cramming this symVal down the throat of the
     // semantics. It might make better sense to just move all this stuff to
     // common.
     rule symVal +bits _:Int => symVal
     rule symVal +bytes _:Int => symVal

     rule floorLoc(symVal) => symVal
     rule ceilingLoc(symVal) => symVal

     rule write-aux(symVal, _, _) => .
          [structural]

     rule bitSizeofType(T:Type) => symVal
          when isIncompleteType(T)

     //rule symVal => tv(symVal, t(.Set, no-type))
endmodule
