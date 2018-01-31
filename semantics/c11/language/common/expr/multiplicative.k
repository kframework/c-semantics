module C-COMMON-EXPR-MULTIPLICATIVE
     imports BOOL
     imports FLOAT
     imports INT
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
          => arithInterpret(T, I1 *Int I2)
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) * tv(F2:Float, T'::UType)
          => arithInterpret(T, F1 *Float F2)
          requires T ==Type T'
          [structural]

     rule tv(I1:Int, T::UType) / tv(I2:Int, T'::UType)
          => arithInterpret(T, I1 /Int I2)
          requires isPromoted(T) andBool I2 =/=Int 0
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) / tv(F2:Float, T'::UType)
          => arithInterpret(T, F1 /Float F2)
          requires T ==Type T' andBool F2 =/=Float 0.0
          [structural]
     rule (.K => UNDEF("CEMX1", "Division by 0."))
          ~> L:RValue / tv(0, T'::UType)
          requires isIntegerUType(utype(L)) andBool isPromoted(utype(L))
               andBool utype(L) ==Type T'
          [structural]
     rule (.K => UNDEF("CEMX1", "Division by 0.") )
          ~> L:RValue / tv(Z:Float, T'::UType)
          requires isFloatUType(utype(L))
               andBool Z ==Float 0.0
               andBool utype(L) ==Type T'
          [structural]


     rule tv(I1:Int, T::UType) % tv(I2:Int, T'::UType)
          => arithInterpret(T, I1 %Int I2)
          requires isPromoted(T)
               andBool (I2 =/=Int 0)
               andBool (min(T) <=Int I1 /Int I2)
               andBool (max(T) >=Int I1 /Int I2)
               andBool T ==Type T'
          [structural]
     rule (.K => IMPL("CEMX4", "Modulus operator with a pointer value as an argument."))
          ~> tv(I1:SymLoc, T::UType) % tv(I2:Int, T'::UType)
          requires isPromoted(T)
               andBool (I2 =/=Int 0)
               andBool T ==Type T'
          [structural]
     rule (.K => UNDEF("CEMX2", "Modulus by 0."))
          ~> L:RValue % tv(0, T'::UType)
          requires isIntegerUType(utype(L)) andBool isPromoted(utype(L))
               andBool utype(L) ==Type T'
          [structural]
     rule (.K => UNDEF("CEMX3", "Signed integer overflow.")) ~>
          tv(I1:Int, T:IntegerUType) % tv(I2:Int, T'::UType)
          requires I2 =/=Int 0
               andBool notBool (min(T) <=Int I1 /Int I2
                    andBool max(T) >=Int I1 /Int I2)
               andBool isPromoted(T)
               andBool I2 =/=Int 0
               andBool T ==Type T'
          [structural]

endmodule

