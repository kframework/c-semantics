module C-PROMOTION
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     rule L:KLabel(
               (tv(V:CValue, T:IntegerType) => tv(V, promote(T)))
          )
          requires isArithUnaryOp(L)
               andBool notBool isPromoted(T)
          [structural]
     rule L:KLabel(
               (e(K:K, T:IntegerType) => e(K, promote(T)))
          )
          requires isArithUnaryOp(L)
               andBool notBool isPromoted(T)
          [structural]
     rule L:KLabel(
               (tv(V:CValue, T:IntegerType) => tv(V, promote(T)))
               ,, _
          )
          requires isArithBinOp(L)
               andBool notBool isPromoted(T)
          [structural]
     rule L:KLabel(
               (e(K:K, T:IntegerType) => e(K, promote(T)))
               ,, _
          )
          requires isArithBinOp(L)
               andBool notBool isPromoted(T)
          [structural]
     rule L:KLabel(
               _,,
               (tv(V:CValue, T:IntegerType) => tv(V, promote(T)))
          )
          requires isArithBinOp(L)
               andBool notBool isPromoted(T)
          [structural]
     rule L:KLabel(
               _,,
               (e(K:K, T:IntegerType) => e(K, promote(T)))
          )
          requires isArithBinOp(L)
               andBool notBool isPromoted(T)
          [structural]

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
          [structural]

     rule Lbl:KLabel(L:KLabel(_,, (T:Type => stripConstants(T))),,
                     R:KLabel(_,, (T':Type => stripConstants(T'))))
          requires isArithBinOp(Lbl)
               andBool (T ==Type T')
               andBool (IntegerConstant in getModifiers(T) xorBool IntegerConstant in getModifiers(T'))
               andBool (L ==KLabel 'tv orBool L ==KLabel 'e)
               andBool (R ==KLabel 'tv orBool R ==KLabel 'e)
          [structural]

endmodule
