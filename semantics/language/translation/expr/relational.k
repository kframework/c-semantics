module C-EXPR-RELATIONAL
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     rule tv(V:K, T:Type) < tv(V':K, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==K T') andBool isPromoted(T))
                    orBool ((T ==K T') andBool isFloatType(T))
               )
          [structural]
     rule tv(V:K, T:Type) <= tv(V':K, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==K T') andBool isPromoted(T))
                    orBool ((T ==K T') andBool isFloatType(T))
               )
          [structural]
     rule tv(V:K, T:Type) > tv(V':K, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==K T') andBool isPromoted(T))
                    orBool ((T ==K T') andBool isFloatType(T))
               )
          [structural]
     rule tv(V:K, T:Type) >= tv(V':K, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==K T') andBool isPromoted(T))
                    orBool ((T ==K T') andBool isFloatType(T))
               )
          [structural]
     rule tv(V:K, T:Type) == tv(V':K, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==K T') andBool isPromoted(T))
                    orBool ((T ==K T') andBool isFloatType(T))
               )
          [structural]
     rule tv(V:K, T:Type) != tv(V':K, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==K T') andBool isPromoted(T))
                    orBool ((T ==K T') andBool isFloatType(T))
               )
          [structural]
          
endmodule


