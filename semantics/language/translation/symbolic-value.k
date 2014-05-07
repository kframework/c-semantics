module C-SYMBOLIC-VALUE-SYNTAX
     syntax CSize ::= SymVal
     syntax SymLoc ::= SymVal
     syntax Bits ::= SymVal
     syntax SymVal ::= "symVal"
endmodule

module C-SYMBOLIC-VALUE
     imports C-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITS-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports COMPAT-SYNTAX

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
          when notBool isCompleteType(T)
     rule bitSizeofType(t(_, arrayType(_, symVal))) => symVal

     rule splitBytes(tv(symVal, T:Type)) 
          => dataList(
               times(byteSizeofType(T), piece(symVal, cfg:bitsPerByte)))

     rule write-specific(Loc:SymLoc, tv(symVal, T:Type), NBits:Int)
          => writeBitfield(
               Loc
               , T
               , calculateNewBytes(
                    getBitOffset(Loc)
                    , piece(symVal, NBits)
                    , readBytes(floorLoc(Loc), 
                         bitsToBytes(NBits +Int getBitOffset(Loc))
                    )
               )
          )
          when (NBits %Int cfg:bitsPerByte =/=Int 0)
               orBool (notBool isByteLoc(Loc))
               orBool (isBitfieldType(T) andBool notBool hasUnionMarker(T))
          [structural]

     //rule symVal => tv(symVal, t(.Set, no-type))
endmodule
