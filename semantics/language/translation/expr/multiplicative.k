module C-EXPR-MULTIPLICATIVE
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     rule tv(V:CValue, T:Type) * tv(V':CValue, T':Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool V' ==K symVal)
               andBool (isPromoted(T) orBool hasFloatType(T))
               andBool T ==Type T'
          [structural]

     rule tv(V:CValue, T:Type) / tv(V':CValue, T':Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool V' ==K symVal)
               andBool (
                    (isPromoted(T) andBool V' =/=K 0)
                    orBool hasFloatType(T))
               andBool T ==Type T'
          [structural]

     rule tv(V:CValue, T:Type) % tv(V':CValue, T':Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool isPromoted(T)
               andBool (V' =/=K 0)
               andBool T ==Type T'
          [structural]
endmodule

