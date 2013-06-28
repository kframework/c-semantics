require "memory/reading.k"
require "memory/writing.k"
require "memory/alloc.k"

module C-MEMORY-SYNTAX
endmodule

module C-MEMORY
     imports C-MEMORY-WRITING 
     imports C-MEMORY-READING 
     imports C-MEMORY-ALLOC 
endmodule
