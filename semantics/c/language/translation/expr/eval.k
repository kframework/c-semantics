module C-EXPR-EVAL
     imports BOOL
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule reval(ncle(K:K, T::Type) => te(K, utype(T)))
          requires notBool isArrayOrFunctionType(T)
     rule reval(ncle(K:K, T:ArrayType) => te(K, utype(arrayToPtrType(T))))
     rule reval(ncle(K:K, T:FunctionType) => te(K, utype(pointerType(T))))

     rule le(K:K, T::Type) => ncle(K, T)

endmodule
