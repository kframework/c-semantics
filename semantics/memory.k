require "memory/reading.k"
require "memory/writing.k"
require "memory/alloc.k"

module C-MEMORY-SYNTAX
     // location, type
     syntax K ::= "read" "(" SymLoc "," K ")" [strict(2)]
     // location, value
     syntax K ::= "write" "(" K "," K ")" [strict(2)]
     syntax K ::= "writeByte" "(" SymLoc "," K ")" 

     syntax K ::= "mconst"

     syntax K ::= "makeUnwritable" "(" SymLoc ")" 
     syntax K ::= "makeUnwritableSubObject" "(" K ")" 
     syntax K ::= "makeUnwritableVar" "(" K ")"
     context makeUnwritableSubObject((HOLE => peval(HOLE)))

     syntax K ::= "allocateType" "(" SymLoc "," Type ")"
     syntax K ::= "allocateTypeIfAbsent" "(" SymLoc "," Type ")"
     syntax K ::= "allocString" "(" SymLoc "," String ")"
     syntax K ::= "allocWString" "(" SymLoc "," KList ")"

     syntax K ::= "zeroBlock" "(" SymLoc ")"

     syntax K ::= "alloc" "(" K "," K ")" // should be K K 
     syntax K ::= "realloc" "(" K "," K "," K "," K ")" // should be K K 

     // deletes the base object from memory, given a location
     syntax K ::= "deleteBlock" "(" SymLoc ")"
     // deletes the base object from memory, given a location and it size (as a
     // check)
     syntax K ::= "deleteSizedBlock" "(" SymLoc "," Int ")"

     syntax K ::= memblock(Int, Bag, Map)
     syntax K ::= "concretize" "(" Type "," K ")" [strict(2)] 

     // data, offset, size in bits
     syntax K ::= "extractBitsFromList" "(" K "," Int "," Int ")" [strict(1)]

     syntax K ::= "checkValidLoc" "(" SymLoc ")"
     syntax K ::= "checkDerefLoc" "(" SymLoc ")"
     syntax K ::= "fromUnion" "(" Id ")" [klabel('fromUnion)]
     syntax K ::= "sizeofLocation" "(" SymLoc ")"
endmodule

module C-MEMORY
     imports C-MEMORY-WRITING 
     imports C-MEMORY-READING 
     imports C-MEMORY-ALLOC 
endmodule
