module MEMORY-SORTS
     syntax EffectiveType
     syntax CPPType
endmodule

module MEMORY-SYNTAX
     imports MEMORY-SORTS
     imports ARRAY
     imports BASIC-K
     imports INT-SYNTAX
     imports LIST
     imports BITS-SORTS
     imports COMMON-SORTS
     imports SYMLOC-SORTS

     /* object(effective type, size, byte map) */
     syntax KItem ::= object(EffectiveType, Int, Array)

endmodule
