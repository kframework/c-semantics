module MEMORY-SYNTAX
     imports C-TYPING-SYNTAX
     imports ARRAY

     /* object(effective type, size, byte map) */
     syntax KItem ::= object(Type, Int, Array)
endmodule

module MEMORY
     imports MEMORY-SYNTAX
endmodule
