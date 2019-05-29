module C-EXPR-EVAL
     imports BOOL
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule reval(ncle(K:K, T::Type) => te(K, rvalType(T)))

     rule le(K:K, T::Type) => ncle(K, T)

endmodule
