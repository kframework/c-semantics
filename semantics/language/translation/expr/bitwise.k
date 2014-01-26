module C-EXPR-BITWISE
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-TYPING-SYNTAX

     rule tv(symVal, T:Type) << tv(N:Int, T':Type)
          => tv(symVal, T)
          when isPromoted(T) andBool isPromoted(T')
               andBool N <Int numBits(T)
          [structural]
     rule tv(_, T:Type) << tv(symVal, T':Type)
          => tv(symVal, T)
          when isPromoted(T) andBool isPromoted(T')
          [structural]

     rule tv(symVal, T:Type) >> tv(N:Int, T':Type)
          => tv(symVal, T)
          when isPromoted(T) andBool isPromoted(T')
               andBool N <Int numBits(T)
          [structural]
     rule tv(_, T:Type) >> tv(symVal, T':Type)
          => tv(symVal, T)
          when isPromoted(T) andBool isPromoted(T')
          [structural]

     rule tv(V:K, T:Type) & tv(V':K, T:Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool isPromoted(T)
          [structural]
     rule tv(V:K, T:Type) ^ tv(V':K, T:Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool isPromoted(T)
          [structural]
     rule tv(V:K, T:Type) | tv(V':K, T:Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool isPromoted(T)
          [structural]
endmodule
