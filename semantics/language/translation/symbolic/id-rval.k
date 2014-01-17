module C-SYMBOLIC-ID-RVAL
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-EXPRESSION-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     // TODO(chathhorn): might want to limit this to non-file-scope.
     rule rkludge(lval(_, T:Type)) => tv(symVal, T)
          when notBool isArrayType(T) 
               andBool notBool isFunctionType(T) 
          [structural]

endmodule
