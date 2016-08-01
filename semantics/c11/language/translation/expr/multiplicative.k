module C-EXPR-MULTIPLICATIVE
     imports BOOL
     imports K-EQUAL 
     imports C-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule L:RValue * R:RValue => te(stripHold(L) * stripHold(R), utype(L))
          requires (isHold(L) orBool isHold(R))
               andBool (isPromoted(utype(L)) orBool isFloatType(type(L)))
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
               andBool utype(L) ==Type utype(R)
          [structural]

     rule te(L:K, T::UType) / tv(V:CValue, T'::UType) => te(L / tv(V, T'), T)
          requires ((isPromoted(T) andBool V =/=K 0) orBool isFloatUType(T))
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))
               andBool T ==Type T'
     rule L:RValue / R:RValue => te(stripHold(L) / stripHold(R), utype(L))
          requires isHold(R)
               andBool (isPromoted(utype(L)) orBool isFloatType(type(L)))
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
               andBool utype(L) ==Type utype(R)

     rule te(L:K, T::UType) % tv(V:CValue, T'::UType) => te(L % tv(V, T'), T)
          requires isPromoted(T)
               andBool V =/=K 0
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))
               andBool T ==Type T'
     rule L:RValue % R:RValue => te(stripHold(L) % stripHold(R), utype(L))
          requires isHold(R)
               andBool isPromoted(utype(L))
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
               andBool utype(L) ==Type utype(R)
endmodule

