module C-EXPR-ADDITIVE
     imports C-BITSIZE-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule L:RValue + R:RValue => te(stripHold(L) + stripHold(R), utype(L))
          requires (isHold(L) orBool isHold(R))
               andBool notBool isFunctionPointerType(type(L))
               andBool isCompletePointerType(type(L))
               andBool isIntegerType(type(R))
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
     rule L:RValue + R:RValue => te(stripHold(L) + stripHold(R), utype(R))
          requires (isHold(L) orBool isHold(R))
               andBool notBool isFunctionPointerType(type(R))
               andBool isCompletePointerType(type(R))
               andBool isIntegerType(type(L))
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))

     rule L:RValue - R:RValue => te(stripHold(L) - stripHold(R), utype(L))
          requires (isHold(L) orBool isHold(R))
               andBool notBool isFunctionPointerType(type(L))
               andBool isCompletePointerType(type(L))
               andBool isIntegerType(type(R))
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
     rule L:RValue - R:RValue => te(stripHold(L) - stripHold(R), utype(cfg:ptrdiffut))
          requires (isHold(L) orBool isHold(R))
               andBool notBool isFunctionPointerType(type(L))
               andBool isCompletePointerType(type(L))
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
               andBool notBool isFunctionPointerType(type(R))
               andBool isCompletePointerType(type(R))
               andBool areCompatible(
                    stripQualifiers(innerType(type(L))),
                    stripQualifiers(innerType(type(R))))

     rule L:RValue + R:RValue => te(stripHold(L) + stripHold(R), utype(L))
          requires (isHold(L) orBool isHold(R))
               andBool (isPromoted(utype(L)) orBool isFloatUType(utype(L)))
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
               andBool utype(L) ==Type utype(R)
     rule L:RValue - R:RValue => te(stripHold(L) - stripHold(R), utype(L))
          requires (isHold(L) orBool isHold(R))
               andBool (isPromoted(utype(L)) orBool isFloatUType(utype(L)))
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
               andBool utype(L) ==Type utype(R)

endmodule

