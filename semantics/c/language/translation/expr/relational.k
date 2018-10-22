module C-EXPR-RELATIONAL
     imports BOOL
     imports SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-COMMON-EXPR-RELATIONAL-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule L:RValue < R:RValue => te(stripHold(L) < stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               ) andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))

     rule L:RValue <= R:RValue => te(stripHold(L) <= stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               ) andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))

     rule L:RValue > R:RValue => te(stripHold(L) > stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               ) andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))

     rule L:RValue >= R:RValue => te(stripHold(L) >= stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (utype(L) ==Type utype(R) andBool isPromoted(utype(L)))
                    orBool (utype(L) ==Type utype(R) andBool isFloatType(type(L)))
               ) andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))

     rule L:RValue == R:RValue => te(stripHold(L) == stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    isCompatibleEqualityTypes(utype(L), utype(R), value(L), value(R))
               )

     rule L:RValue != R:RValue => te(stripHold(L) != stripHold(R), utype(int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    isCompatibleEqualityTypes(utype(L), utype(R), value(L), value(R))
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
