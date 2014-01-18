module C-EXPRESSION-ID-RVAL
     imports C-EXPRESSION-EVAL-SYNTAX
     imports C-MEMORY-SYNTAX

     rule instantiateIdVal(L:SymLoc, T:Type) => read(L, T)
          [structural]

endmodule
