module C-EXPR-BITWISE
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ERROR-SYNTAX

     rule ~ tv(symVal, T:Type) => tv(symVal, T)
          requires isPromoted(T)
          [structural]

     rule tv(symVal, T1:Type) << tv(E2:Int, T2:Type) => tv(symVal, T1)
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T1):>Int
          [structural]
     rule tv(E1:Int, T1:Type) << tv(symVal, T2:Type) => tv(symVal, T1)
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E1 >=Int 0
          [structural]
     rule _:ErrorExit ~> tv(E1:Int, T1:Type) << tv(symVal, T2:Type)
          => tv(symVal, T1)
          requires isPromoted(T1) andBool isPromoted(T2)
          andBool E1 <Int 0 andBool isErrorRecovery
     rule tv(symVal, T1:Type) << tv(symVal, T2:Type) => tv(symVal, T1)
          requires isPromoted(T1) andBool isPromoted(T2)
          [structural]

     rule tv(symVal, T1:Type) >> tv(E2:Int, T2:Type) => tv(symVal, T1)
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T1):>Int
          [structural]
     rule tv(E1:Int, T1:Type) >> tv(symVal, T2:Type) => tv(symVal, T1)
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E1 >=Int 0
          [structural]
     rule tv(symVal, T1:Type) >> tv(symVal, T2:Type) => tv(symVal, T1)
          requires isPromoted(T1) andBool isPromoted(T2)
          [structural]

     rule tv(E1:CValue, T:Type) & tv(E2:CValue, T':Type) => tv(symVal, T)
          requires ((E1 ==K symVal) orBool (E2 ==K symVal))
               andBool isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(E1:CValue, T:Type) ^ tv(E2:CValue, T':Type) => tv(symVal, T)
          requires ((E1 ==K symVal) orBool (E2 ==K symVal))
               andBool isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(E1:CValue, T:Type) | tv(E2:CValue, T':Type) => tv(symVal, T)
          requires ((E1 ==K symVal) orBool (E2 ==K symVal))
               andBool isPromoted(T)
               andBool T ==Type T'
          [structural]
endmodule
