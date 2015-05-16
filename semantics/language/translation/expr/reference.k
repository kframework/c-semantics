module C-EXPR-REFERENCE
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule &(e(K:K, T:Type)) => e( & K, t(.Set, pointerType(T)))

     rule * (e(K:K, T:Type)) => e( * K, innerType(T))
          requires notBool isVoidType(innerType(T))

endmodule
