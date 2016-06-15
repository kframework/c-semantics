module C-EXPR-REFERENCE
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     rule &(ncle(K:K, T::Type))
          => te(& K, utype(pointerType(T)))

     rule * (te(K:K, T::UType)) => le(* K, innerType(T))
          requires notBool isVoidType(innerType(T))

endmodule
