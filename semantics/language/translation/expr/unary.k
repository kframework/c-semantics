module C-EXPR-UNARY
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-TYPING-SYNTAX

     rule + tv(symVal, T:Type) => tv(symVal, T)
          requires isPromoted(T) orBool isFloatType(T)
          [structural]

     rule - tv(symVal, T:Type) => tv(symVal, T)
          requires isPromoted(T) orBool isFloatType(T)
          [structural]

endmodule
