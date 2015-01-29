module C-EXPR-ADDITIVE
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-BITSIZE-SYNTAX

     imports C-SETTINGS-SYNTAX

     rule tv(V':CValue, t(Mods:Set, pointerType(T':Type))) + tv(V:CValue, T:Type)
          => tv(symVal, t(Mods, pointerType(T')))
          requires ((V ==K symVal) orBool (V' ==K symVal))
               andBool hasIntegerType(T)
               andBool simpleType(T') =/=K void
          [structural]
     rule tv(V:CValue, T:Type) + tv(V':CValue, t(Mods:Set, pointerType(T':Type)))
          => tv(symVal, t(Mods, pointerType(T')))
          requires ((V ==K symVal) orBool (V' ==K symVal))
               andBool hasIntegerType(T)
               andBool simpleType(T') =/=K void
          [structural]
     rule tv(V':CValue, t(Mods:Set, pointerType(T':Type))) - tv(V:CValue, T:Type)
          => tv(symVal, t(Mods, pointerType(T')))
          requires ((V ==K symVal) orBool (V' ==K symVal))
               andBool hasIntegerType(T)
               andBool simpleType(T') =/=K void
          [structural]

     rule tv(V:CValue, t(_, pointerType(T:Type))) - tv(V':CValue, t(_, pointerType(T':Type)))
          => tv(symVal, t(.Set, cfg:ptrdiffut))
          requires (V ==K symVal) orBool (V' ==K symVal)
               andBool T ==Type T'
          [structural]

     rule tv(V:CValue, T:Type) + tv(V':CValue, T':Type)
          => tv(symVal, T)
          requires ((V ==K symVal) orBool (V' ==K symVal))
               andBool (isPromoted(T) orBool hasFloatType(T))
               andBool T ==Type T'
          [structural]
     rule tv(V:CValue, T:Type) - tv(V':CValue, T':Type)
          => tv(symVal, T)
          requires ((V ==K symVal) orBool (V' ==K symVal))
               andBool (isPromoted(T) orBool hasFloatType(T))
               andBool T ==Type T'
          [structural]

endmodule

