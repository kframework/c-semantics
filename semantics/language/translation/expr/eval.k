module C-EXPR-EVAL
     imports C-DYNAMIC-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports COMPAT-SYNTAX

     rule reval(ncle(K:K, T:Type) => te(K, stripQualifiers(T)))
          requires notBool isArrayOrFunctionType(T)
     rule reval(ncle(K:K, T:ArrayType) => te(K, arrayToPtrType(T)))
     rule reval(ncle(K:K, T:FunctionType) => te(K, t(.Set, pointerType(T))))

     rule le(K:K, T:Type) => ncle(K, T)

endmodule
