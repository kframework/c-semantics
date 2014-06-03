module C-EXPR-RELATIONAL
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     rule tv(V:CValue, T:Type) < tv(V':CValue, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==Type T') andBool isPromoted(T))
                    orBool ((T ==Type T') andBool hasFloatType(T))
               )
          [structural]
     rule tv(V:CValue, T:Type) <= tv(V':CValue, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==Type T') andBool isPromoted(T))
                    orBool ((T ==Type T') andBool hasFloatType(T))
               )
          [structural]
     rule tv(V:CValue, T:Type) > tv(V':CValue, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==Type T') andBool isPromoted(T))
                    orBool ((T ==Type T') andBool hasFloatType(T))
               )
          [structural]
     rule tv(V:CValue, T:Type) >= tv(V':CValue, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==Type T') andBool isPromoted(T))
                    orBool ((T ==Type T') andBool hasFloatType(T))
               )
          [structural]
     rule tv(V:CValue, T:Type) == tv(V':CValue, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==Type T') andBool isPromoted(T))
                    orBool ((T ==Type T') andBool hasFloatType(T))
               )
          [structural]
     rule tv(V:CValue, T:Type) != tv(V':CValue, T':Type) 
          => tv(symVal, t(.Set, int))
          when ((V ==K symVal) orBool (V' ==K symVal))
               andBool (
                    (isPointerType(T) andBool isPointerType(T'))
                    orBool ((T ==Type T') andBool isPromoted(T))
                    orBool ((T ==Type T') andBool hasFloatType(T))
               )
          [structural]

endmodule
