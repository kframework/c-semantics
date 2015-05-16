module C-EXPR-UNARY
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule + e(K:K, T:Type) => e( + K, T)
          requires isPromoted(T) orBool isFloatType(T)

     rule - e(K:K, T:Type) => e( - K, T)
          requires isPromoted(T) orBool isFloatType(T)

endmodule
