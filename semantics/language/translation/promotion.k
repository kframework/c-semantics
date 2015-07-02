module C-PROMOTION
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     rule L:KLabel(
               (V:RValue => cast(promote(type(V)), V))
          )
          requires isIntegerType(type(V))
               andBool isArithUnaryOp(L)
               andBool notBool isPromoted(type(V))
     rule L:KLabel(
               (V:RValue => cast(promote(type(V)), V))
               ,, _
          )
          requires isIntegerType(type(V))
               andBool isArithBinOp(L)
               andBool notBool isPromoted(type(V))
     rule L:KLabel(
               _,,
               (V:RValue => cast(promote(type(V)), V))
          )
          requires isIntegerType(type(V))
               andBool isArithBinOp(L)
               andBool notBool isPromoted(type(V))

     // fixme these could be done more cleanly

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
     rule Lbl:KLabel(L:RValue,, R:RValue)
          => Lbl(cast(
               usualArithmeticConversion(type(L), type(R)), L),,
               cast(usualArithmeticConversion(type(L), type(R)), R))
          requires isArithBinConversionOp(Lbl)
               andBool isArithmeticType(type(L))
               andBool isArithmeticType(type(R))
               andBool (type(L) =/=Type type(R))

endmodule
