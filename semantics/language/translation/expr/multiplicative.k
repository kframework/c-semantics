module C-EXPR-MULTIPLICATIVE
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule L:RValue * R:RValue => te(stripHold(L) * stripHold(R), type(L))
          requires (isHold(L) orBool isHold(R))
               andBool (isPromoted(type(L)) orBool isFloatType(type(L)))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(type(R)))
               andBool type(L) ==Type type(R)
          [structural]

     rule te(L:K, T:Type) / tv(V:CValue, T':Type) => te(L / tv(V, T'), T)
          requires ((isPromoted(T) andBool V =/=K 0) orBool isFloatType(T))
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))
               andBool T ==Type T'
     rule L:RValue / R:RValue => te(stripHold(L) / stripHold(R), type(L))
          requires isHold(R)
               andBool (isPromoted(type(L)) orBool isFloatType(type(L)))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(type(R)))
               andBool type(L) ==Type type(R)
     rule _:ErrorExit ~> L:RValue / tv(0, T:Type) => te(stripHold(L) / tv(0, T), type(L))
          requires isPromoted(type(L))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(T))
               andBool type(L) ==Type T
               andBool isErrorRecovery

     rule te(L:K, T:Type) % tv(V:CValue, T':Type) => te(L % tv(V, T'), T)
          requires isPromoted(T)
               andBool V =/=K 0
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))
               andBool T ==Type T'
     rule L:RValue % R:RValue => te(stripHold(L) % stripHold(R), type(L))
          requires isHold(R)
               andBool isPromoted(type(L))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(type(R)))
               andBool type(L) ==Type type(R)
     rule _:ErrorExit ~> L:RValue % tv(0, T:Type) => te(stripHold(L) % tv(0, T), type(L))
          requires isPromoted(type(L))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(T))
               andBool type(L) ==Type T
               andBool isErrorRecovery
endmodule

