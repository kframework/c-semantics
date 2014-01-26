module C-EXPRESSION-ID-RVAL
     imports C-COMMON-EXPRESSION-EVAL-SYNTAX
     imports C-MEMORY-SYNTAX

     rule instantiateIdVal(L:SymLoc, T:Type) => read(L, T)
          [structural]

endmodule
