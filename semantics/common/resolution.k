module COMMON-RESOLUTION-SYNTAX
     imports BASIC-K
     imports SYMLOC-SORTS

     syntax KItem ::= resolveCPPReference(SymBase)
                    | "resolveMain"
endmodule

module COMMON-RESOLUTION
     imports COMMON-RESOLUTION-SYNTAX
endmodule
