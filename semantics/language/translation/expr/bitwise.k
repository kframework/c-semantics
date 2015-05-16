module C-EXPR-BITWISE
     imports C-ABSTRACT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule ~ e(K:K, T:Type) => e(~ K, T)
          requires isPromoted(T)

     rule e(L:K, T:Type) << tv(R:Int, T':Type) => e(L << tv(R, T'), T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool R >=Int 0
               andBool R <Int bitSizeofType(T):>Int
     rule tv(L:Int, T:Type) << e(R:K, T':Type) => e(tv(L, T) << R, T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool L >=Int 0
     rule _:ErrorExit ~> tv(L:Int, T:Type) << e(R:K, T':Type) => e(tv(L, T) << R, T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool L <Int 0 andBool isErrorRecovery
     rule e(L:K, T:Type) << e(R:K, T':Type) => e(L << R, T)
          requires isPromoted(T) andBool isPromoted(T')

     rule e(L:K, T:Type) >> tv(R:Int, T':Type) => e(L >> tv(R, T'), T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool R >=Int 0
               andBool R <Int bitSizeofType(T):>Int
     rule tv(L:Int, T:Type) >> e(R:K, T':Type) => e(tv(L, T) >> R, T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool L >=Int 0
     rule e(L:K, T:Type) >> e(R:K, T':Type) => e(L >> R, T)
          requires isPromoted(T) andBool isPromoted(T')

     rule L:RValue & R:RValue => e(stripHold(L) & stripHold(R), type(L))
          requires (isHold(L) orBool isHold(R))
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)
     rule L:RValue ^ R:RValue => e(stripHold(L) ^ stripHold(R), type(L))
          requires (isHold(L) orBool isHold(R))
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)
     rule L:RValue | R:RValue => e(stripHold(L) | stripHold(R), type(L))
          requires (isHold(L) orBool isHold(R))
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)

endmodule
