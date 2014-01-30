module C-SYMBOLIC-VALUE-SYNTAX
     syntax Int ::= SymVal
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
     imports C-TYPING-INTERPRETATION-SYNTAX
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

     rule bitSizeofType(T:Type) => tv(symVal, T)
          when isIncompleteType(T)

     rule bitsToBytes(symVal) => symVal

     // From typing/interpretation.k
     rule ArrayType(T:Type, tv(symVal, _), _) 
          => pushTypeDown(T, makeArrayType(symVal)) 
          [structural, anywhere]

endmodule
