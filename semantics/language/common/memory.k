require "memory/reading.k"
require "memory/writing.k"

module C-MEMORY-SYNTAX
     // location, type
     syntax K ::= read(SymLoc, K) [strict(2)]
     // location, value
     syntax K ::= write(K, K) [strict(2)]

     syntax K ::= concretize(Type, K) [strict(2)] 

     // data, offset, size in bits
     syntax K ::= extractBitsFromList(K, Int, Int) [strict(1)]

     syntax K ::= fromUnion(Id) [klabel('fromUnion)]

     // Either buffered or unbuffered depending on whether we're executing.
     // If the flag is true, then we disable checking undefinedness checking
     // (i.e., multiple, unsequenced writes to a single location). This is
     // always disabled in direct io mode.
     syntax K ::= writeBytes(SymLoc, K, Bool) [strict(2)] 
     syntax K ::= writeByte(SymLoc, K)
     // returns the bytes in the order in which they are in memory
     syntax K ::= readBytes(SymLoc, Int) 
     syntax K ::= readByte(SymLoc) 
endmodule

module C-MEMORY
     imports C-MEMORY-WRITING 
     imports C-MEMORY-READING 
endmodule
