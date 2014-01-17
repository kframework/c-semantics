module C-SYMBOLIC-MULTIPLICATIVE-OPERATORS
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     rule tv(V:K, T:Type) * tv(V':K, T:Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool V' ==K symVal)
               andBool (isPromoted(T) orBool isFloatType(T))
          [structural]

     rule tv(V:K, T:Type) / tv(V':K, T:Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool V' ==K symVal)
               andBool (
                    (isPromoted(T) andBool V' =/=K 0)
                    orBool isFloatType(T))
          [structural]
          
     rule tv(V:K, T:Type) % tv(V':K, T:Type)
          => tv(symVal, T)
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool isPromoted(T)
               andBool (V' =/=K 0)
          [structural]
endmodule

