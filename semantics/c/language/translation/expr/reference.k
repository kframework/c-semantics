module C-EXPR-REFERENCE
     imports BOOL
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule &(ncle(K:KItem, T::Type))
          => te(& K, utype(pointerType(T)))

     rule * (te(K:KItem, ut(... st: pointerType(_)) #as T::UType)) => le(* K, innerType(T))
          requires notBool isVoidType(innerType(T))

endmodule
