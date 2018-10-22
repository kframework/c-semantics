module C-EXPR-REFERENCE
     imports BOOL
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule &(ncle(K:K, T::Type))
          => te(& K, utype(pointerType(T)))

     rule * (te(K:K, T:PointerUType)) => le(* K, innerType(T))
          requires notBool isVoidType(innerType(T))

endmodule
