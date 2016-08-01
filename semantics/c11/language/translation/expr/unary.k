module C-EXPR-UNARY
     imports BOOL
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule + te(K:K, T::UType) => te( + K, T)
          requires isPromoted(T) orBool isFloatUType(T)

     rule - te(K:K, T::UType) => te( - K, T)
          requires isPromoted(T) orBool isFloatUType(T)

endmodule
