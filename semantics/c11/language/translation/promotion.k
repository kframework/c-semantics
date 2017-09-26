module C-PROMOTION
     imports C-COMMON-PROMOTION-SYNTAX
     imports BOOL
     imports C-COMMON-PROMOTION-CONTEXT-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule L:KLabel(
               (V:RValue => cast(promote(utype(V)), V))
          )
          requires isIntegerType(type(V))
               andBool isArithUnaryOp(#klabel(L))
               andBool notBool isPromoted(utype(V))
     rule L:KLabel(
               (V:RValue => cast(promote(utype(V)), V))
               , _:RValue
          )
          requires isIntegerType(type(V))
               andBool isArithBinOp(#klabel(L))
               andBool notBool isPromoted(utype(V))
     rule L:KLabel(
               _:RValue,
               (V:RValue => cast(promote(utype(V)), V))
          )
          requires isIntegerType(type(V))
               andBool isArithBinOp(#klabel(L))
               andBool notBool isPromoted(utype(V))

     rule Lbl:KLabel(tv(_, (T::UType => stripConstants(T))), R:RValue)
          requires isArithBinNonEqualityOp(#klabel(Lbl))
               andBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(R)
               andBool (notBool isIntegerUType(T) orBool isPromoted(T))
     rule Lbl:KLabel(L:RValue, tv(_, (T::UType => stripConstants(T))))
          requires isArithBinNonEqualityOp(#klabel(Lbl))
               andBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(L)
               andBool (notBool isIntegerUType(T) orBool isPromoted(T))

     rule Lbl:KLabel(te(_, (T::UType => stripConstants(T))), R:RValue)
          requires isArithBinNonEqualityOp(#klabel(Lbl))
               andBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(R)
               andBool (notBool isIntegerUType(T) orBool isPromoted(T))
     rule Lbl:KLabel(L:RValue, te(_, (T::UType => stripConstants(T))))
          requires isArithBinNonEqualityOp(#klabel(Lbl))
               andBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(L)
               andBool (notBool isIntegerUType(T) orBool isPromoted(T))

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.8}{1}}}{
     Many operators that expect operands of arithmetic type cause conversions
     and yield result types in a similar way. The purpose is to determine a
     common real type for the operands and result. For the specified operands,
     each operand is converted, without change of type domain, to a type whose
     corresponding real type is the common real type. Unless explicitly stated
     otherwise, the common real type is also the corresponding real type of the
     result, whose type domain is the type domain of the operands if they are
     the same, and complex otherwise. This pattern is called the usual
     arithmetic conversions:
     }*/
     rule Lbl:KLabel(L:RValue, R:RValue)
          => Lbl(
               cast(usualArithmeticConversion(utype(L), utype(R)), L),
               cast(usualArithmeticConversion(utype(L), utype(R)), R))
          requires isArithBinConversionOp(#klabel(Lbl))
               andBool isArithmeticType(type(L))
               andBool isArithmeticType(type(R))
               andBool (notBool isIntegerType(type(L)) orBool isPromoted(utype(L)))
               andBool (notBool isIntegerType(type(R)) orBool isPromoted(utype(R)))
               andBool notBool (isArithBinNonEqualityOp(#klabel(Lbl)) andBool (fromConstantExpr(L) xorBool fromConstantExpr(R)))
               andBool (utype(L) =/=Type utype(R))

endmodule
