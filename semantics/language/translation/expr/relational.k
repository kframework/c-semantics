module C-EXPR-RELATIONAL
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     rule L:RValue < R:RValue => te(stripHold(L) < stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               )

     rule L:RValue <= R:RValue => te(stripHold(L) <= stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               )

     rule L:RValue > R:RValue => te(stripHold(L) > stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               )

     rule L:RValue >= R:RValue => te(stripHold(L) >= stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               )

     rule L:RValue == R:RValue => te(stripHold(L) == stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               )

     rule L:RValue != R:RValue => te(stripHold(L) != stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               )

     //- comparison of ints with pointers
     // fixme there are further restrictions on pointers
     rule (tv(N:Int, T::UType) => tv(NullPointer, T')) == tv(_, T':PointerUType)
          requires isPromoted(T) andBool isNullPointerConstant(tv(N, T))
     rule (tv(N:Int, T::UType) => tv(NullPointer, T')) == te(_, T':PointerUType)
          requires isPromoted(T) andBool isNullPointerConstant(tv(N, T))

     rule tv(_, T:PointerUType) == (tv(N:Int, T'::UType) => tv(NullPointer, T))
          requires isPromoted(T') andBool isNullPointerConstant(tv(N, T'))
     rule te(_, T:PointerUType) == (tv(N:Int, T'::UType) => tv(NullPointer, T))
          requires isPromoted(T') andBool isNullPointerConstant(tv(N, T'))

     rule (tv(N:Int, T::UType) => tv(NullPointer, T')) != tv(_, T':PointerUType)
          requires isPromoted(T) andBool isNullPointerConstant(tv(N, T))
     rule (tv(N:Int, T::UType) => tv(NullPointer, T')) != te(_, T':PointerUType)
          requires isPromoted(T) andBool isNullPointerConstant(tv(N, T))

     rule te(_, T:PointerUType) != (tv(N:Int, T'::UType) => tv(NullPointer, T))
          requires isPromoted(T') andBool isNullPointerConstant(tv(N, T'))
     rule tv(_, T:PointerUType) != (tv(N:Int, T'::UType) => tv(NullPointer, T))
          requires isPromoted(T') andBool isNullPointerConstant(tv(N, T'))

endmodule
