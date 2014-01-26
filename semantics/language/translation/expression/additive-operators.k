module C-EXPRESSION-ADDITIVE-OPERATORS
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-BITSIZE-SYNTAX

     imports C-SETTINGS-SYNTAX

     rule tv(V':K, t(S:Set, pointerType(T':Type))) + tv(V:K, T:Type)
          => tv(symVal, t(S, pointerType(T')))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool hasIntegerType(T)
               andBool T' =/=K void
          [structural]
     rule tv(V:K, T:Type) + tv(V':K, t(S:Set, pointerType(T':Type)))
          => tv(symVal, t(S, pointerType(T')))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool hasIntegerType(T)
               andBool T' =/=K void
          [structural]
     rule tv(V':K, t(S:Set, pointerType(T':Type))) - tv(V:K, T:Type)
          => tv(symVal, t(S, pointerType(T')))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool hasIntegerType(T)
               andBool T' =/=K void
          [structural]
               

     rule tv(V:K, t(_, pointerType(T:Type))) - tv(V':K, t(_, pointerType(T:Type)))
          => tv(symVal, cfg:ptrdiffut)
          when (V ==K symVal) orBool (V' ==K symVal)
          [structural]
     
     rule tv(V:K, T:Type) + tv(V':K, T:Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (isPromoted(T) orBool isFloatType(T))
          [structural]
     rule tv(V:K, T:Type) - tv(V':K, T:Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (isPromoted(T) orBool isFloatType(T))
          [structural]

endmodule

