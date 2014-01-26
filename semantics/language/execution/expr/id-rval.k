module C-EXPR-ID-RVAL
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-MEMORY-READING-SYNTAX

     rule instantiateIdVal(L:SymLoc, T:Type) => read(L, T)
          [structural]

endmodule
