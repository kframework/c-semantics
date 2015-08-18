module C-EXPR-UNARY
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     rule + te(K:K, T:Type) => te( + K, T)
          requires isPromoted(T) orBool isFloatType(T)

     rule - te(K:K, T:Type) => te( - K, T)
          requires isPromoted(T) orBool isFloatType(T)

endmodule
