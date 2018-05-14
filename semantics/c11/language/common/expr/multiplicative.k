module C-COMMON-EXPR-MULTIPLICATIVE
     imports BOOL
     imports FLOAT
     imports INT
     imports C-BITS-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.5}{3--6}}}{
     The usual arithmetic conversions are performed on the operands.

     The result of the binary \cinline{*} operator is the product of the
     operands.

     The result of the \cinline{/} operator is the quotient from the division
     of the first operand by the second; the result of the \cinline{\%}
     operator is the remainder. In both operations, if the value of the second
     operand is zero, the behavior is undefined.

     When integers are divided, the result of the \cinline{/} operator is the
     algebraic quotient with any fractional part discarded. If the quotient
     \cinline{a/b} is representable, the expression \cinline{(a/b)*b + a\%b}
     shall equal \cinline{a}; otherwise, the behavior of both \cinline{a/b} and
     \cinline{a\%b} is undefined.
     }*/

     rule tv(I1:Int, T::UType) * tv(I2:Int, T'::UType)
          => intArithInterpret(T, I1 *Int I2)
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) * tv(F2:Float, T'::UType)
          => floatArithInterpret(T, F1 *Float F2)
          requires T ==Type T'
          [structural]
     rule tv(V::CValue, T::UType) * tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) * tv(stripUnknown(V'), T'))
          requires isUnknown(V) orBool isUnknown(V')

     rule tv(I1:Int, T::UType) / tv(I2:Int, T'::UType)
          => intArithInterpret(T, I1 /Int I2)
          requires isPromoted(T) andBool T ==Type T'
               andBool notBool isZero(I2)
          [structural]
     rule tv(F1:Float, T::UType) / tv(F2:Float, T'::UType)
          => floatArithInterpret(T, F1 /Float F2)
          requires T ==Type T' andBool notBool isZero(F2)
          [structural]
     rule tv(V::CValue, T::UType) / tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) / tv(V', T'))
          requires isUnknown(V) andBool notBool isUnknown(V')
     rule (.K => UNDEF("CEMX1", "Division by 0."))
          ~> L:RValue / tv(V'::CValue, T'::UType)
          requires utype(L) ==Type T' andBool isZero(V')
          [structural]
     rule (.K => IMPLUB("CEMX5", "Division by an implementation-defined or unspecified value."))
          ~> L:RValue / tv(V'::CValue, T'::UType)
          requires utype(L) ==Type T' andBool isUnknown(V')
               andBool notBool isZero(V')
          [structural]


     rule tv(I1:Int, T::UType) % tv(I2:Int, T'::UType)
          => intArithInterpret(T, I1 %Int I2)
          requires isPromoted(T) andBool T ==Type T'
               andBool notBool isZero(I2)
               andBool (min(T) <=Int I1 /Int I2)
               andBool (max(T) >=Int I1 /Int I2)
          [structural]
     rule tv(V::CValue, T::UType) % tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) % tv(V', T'))
          requires isUnknown(V) andBool notBool isUnknown(V')
               andBool notBool isZero(V')
     rule (.K => IMPL("CEMX4", "Modulus operator with a pointer value as an argument."))
          ~> tv(I1:SymLoc, T::UType) % tv(V'::CValue, T'::UType)
          requires isPromoted(T) andBool T ==Type T'
               andBool notBool isZero(V')
          [structural]
     rule (.K => UNDEF("CEMX2", "Modulus by 0."))
          ~> L:RValue % tv(V'::CValue, T'::UType)
          requires utype(L) ==Type T' andBool isZero(V')
          [structural]
     rule (.K => IMPLUB("CEMX6", "Modulus by an implementation-defined or unspecified value."))
          ~> L:RValue % tv(V'::CValue, T'::UType)
          requires utype(L) ==Type T' andBool isUnknown(V')
               andBool notBool isZero(V')
          [structural]
     rule (.K => UNDEF("CEMX3", "Signed integer overflow.")) ~>
          tv(I1:Int, T:IntegerUType) % tv(I2:Int, T'::UType)
          requires isPromoted(T) andBool T ==Type T'
               andBool notBool isZero(I2)
               andBool notBool (min(T) <=Int I1 /Int I2
                    andBool max(T) >=Int I1 /Int I2)
          [structural]

     syntax Bool ::= isZero(CValue) [function]
     rule isZero(0) => true
     rule isZero(V:Float) => V ==Float 0.0
     rule isZero(unknown(V::CValue)) => isZero(V)
     rule isZero(_) => false [owise]

endmodule

