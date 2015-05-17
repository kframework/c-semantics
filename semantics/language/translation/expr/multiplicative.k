module C-EXPR-MULTIPLICATIVE
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule L:RValue * R:RValue => te(stripHold(L) * stripHold(R), type(L))
          requires (isHold(L) orBool isHold(R))
               andBool (isPromoted(type(L)) orBool isFloatType(type(L)))
               andBool type(L) ==Type type(R)
          [structural]

     rule te(L:K, T:Type) / tv(V:CValue, T':Type) => te(L / tv(V, T'), T)
          requires ((isPromoted(T) andBool V =/=K 0) orBool isFloatType(T))
               andBool T ==Type T'
     rule L:RValue / R:RValue => te(stripHold(L) / stripHold(R), type(L))
          requires isHold(R)
               andBool (isPromoted(type(L)) orBool isFloatType(type(L)))
               andBool type(L) ==Type type(R)

     rule te(L:K, T:Type) % tv(V:CValue, T':Type) => te(L % tv(V, T'), T)
          requires isPromoted(T)
               andBool V =/=K 0
               andBool T ==Type T'
     rule L:RValue % R:RValue => te(stripHold(L) % stripHold(R), type(L))
          requires isHold(R)
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)
endmodule

