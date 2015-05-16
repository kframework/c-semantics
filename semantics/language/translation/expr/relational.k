module C-EXPR-RELATIONAL
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     rule L:RValue < R:RValue => e(stripHold(L) < stripHold(R), t(.Set, int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (type(L) ==Type type(R) andBool isPromoted(type(L)))
                    orBool (type(L) ==Type type(R) andBool isFloatType(type(L)))
               )

     rule L:RValue <= R:RValue => e(stripHold(L) <= stripHold(R), t(.Set, int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (type(L) ==Type type(R) andBool isPromoted(type(L)))
                    orBool (type(L) ==Type type(R) andBool isFloatType(type(L)))
               )

     rule L:RValue > R:RValue => e(stripHold(L) > stripHold(R), t(.Set, int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (type(L) ==Type type(R) andBool isPromoted(type(L)))
                    orBool (type(L) ==Type type(R) andBool isFloatType(type(L)))
               )

     rule L:RValue >= R:RValue => e(stripHold(L) >= stripHold(R), t(.Set, int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (type(L) ==Type type(R) andBool isPromoted(type(L)))
                    orBool (type(L) ==Type type(R) andBool isFloatType(type(L)))
               )

     rule L:RValue == R:RValue => e(stripHold(L) == stripHold(R), t(.Set, int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (type(L) ==Type type(R) andBool isPromoted(type(L)))
                    orBool (type(L) ==Type type(R) andBool isFloatType(type(L)))
               )

     rule L:RValue != R:RValue => e(stripHold(L) != stripHold(R), t(.Set, int))
          requires (isHold(L) orBool isHold(R))
               andBool (
                    (isPointerType(type(L)) andBool isPointerType(type(R)))
                    orBool (type(L) ==Type type(R) andBool isPromoted(type(L)))
                    orBool (type(L) ==Type type(R) andBool isFloatType(type(L)))
               )

endmodule
