module C-EXPRESSION-ID-RVAL
     imports C-SYM-VAL-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-EXPRESSION-EVAL-SYNTAX

     rule rkludge(lval(Loc:SymLoc, T:Type)) => tv(symVal, T)
          when notBool isArrayType(T) 
               andBool notBool isFunctionType(T) 
          [structural]

endmodule
