module C-EXPR-REFERENCE
     imports BOOL
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     // Special exception for linker locs so they can be used in static
     // initializers.
     rule &(ncle(lv(Loc::SymLoc, _), T::Type)) => tv(Loc, utype(pointerType(T)))
     rule &(ncle(K:K, T::Type)) => te(& K, utype(pointerType(T)))
          requires getKLabel(K) =/=K #klabel(`lv`)

     rule * (te(K:K, T:PointerUType)) => le(* K, innerType(T))
          requires notBool isVoidType(innerType(T))

endmodule
