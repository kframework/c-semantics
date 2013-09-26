require "memory/reading.k"
require "memory/writing.k"

module C-MEMORY-SYNTAX
     // location, type
     syntax K ::= read(SymLoc, K) [strict(2)]
     // location, value
     syntax K ::= write(K, K) [strict(2)]
     syntax K ::= writeByte(SymLoc, K)

     syntax K ::= concretize(Type, K) [strict(2)] 

     // data, offset, size in bits
     syntax K ::= extractBitsFromList(K, Int, Int) [strict(1)]

     syntax K ::= fromUnion(Id) [klabel('fromUnion)]
endmodule

module C-MEMORY
     imports C-MEMORY-WRITING 
     imports C-MEMORY-READING 
     imports C-MEMORY-ALLOC 
endmodule
