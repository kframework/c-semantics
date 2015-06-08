module C-EXPR-ADDITIVE
     imports C-BITSIZE-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule L:RValue + R:RValue => te(stripHold(L) + stripHold(R), type(L))
          requires (isHold(L) orBool isHold(R))
               andBool notBool isFunctionPointerType(type(L))
               andBool isCompletePointerType(type(L))
               andBool isIntegerType(type(R))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(type(R)))
     rule L:RValue + R:RValue => te(stripHold(L) + stripHold(R), type(R))
          requires (isHold(L) orBool isHold(R))
               andBool notBool isFunctionPointerType(type(R))
               andBool isCompletePointerType(type(R))
               andBool isIntegerType(type(L))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(type(R)))

     rule L:RValue - R:RValue => te(stripHold(L) - stripHold(R), type(L))
          requires (isHold(L) orBool isHold(R))
               andBool notBool isFunctionPointerType(type(L))
               andBool isCompletePointerType(type(L))
               andBool isIntegerType(type(R))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(type(R)))
     rule L:RValue - R:RValue => te(stripHold(L) - stripHold(R), t(.Set, cfg:ptrdiffut))
          requires (isHold(L) orBool isHold(R))
               andBool notBool isFunctionPointerType(type(L))
               andBool isCompletePointerType(type(L))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(type(R)))
               andBool type(L) ==Type type(R)

     rule L:RValue + R:RValue => te(stripHold(L) + stripHold(R), type(L))
          requires (isHold(L) orBool isHold(R))
               andBool (isPromoted(type(L)) orBool isFloatType(type(L)))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(type(R)))
               andBool type(L) ==Type type(R)
     rule L:RValue - R:RValue => te(stripHold(L) - stripHold(R), type(L))
          requires (isHold(L) orBool isHold(R))
               andBool (isPromoted(type(L)) orBool isFloatType(type(L)))
               andBool notBool (fromConstantExpr(type(L)) xorBool fromConstantExpr(type(R)))
               andBool type(L) ==Type type(R)

endmodule

