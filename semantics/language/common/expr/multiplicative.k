module C-COMMON-EXPR-MULTIPLICATIVE
     imports C-BITS-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

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

     rule tv(I1:Int, T:Type) * tv(I2:Int, T':Type)
          => arithInterpret(T, I1 *Int I2)
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) * tv(F2:Float, T':Type)
          => arithInterpret(T, F1 *Float F2)
          requires T ==Type T'
          [structural]

     rule tv(I1:Int, T:Type) / tv(I2:Int, T':Type)
          => arithInterpret(T, I1 /Int I2)
          requires isPromoted(T:Type) andBool I2 =/=Int 0
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) / tv(F2:Float, T':Type)
          => arithInterpret(T, F1 /Float F2)
          requires T ==Type T'
          [structural]
     rule (.K => UNDEF("CEMX1", "Division by 0.", "6.5.5:5, J.2:1 item 45") )
          ~> L:RValue / tv(0, T':Type)
          requires isIntegerType(type(L)) andBool isPromoted(type(L))
               andBool type(L) ==Type T'
          [structural]

     rule tv(I1:Int, T:Type) % tv(I2:Int, T':Type)
          => arithInterpret(T, I1 %Int I2)
          requires isPromoted(T)
               andBool (I2 =/=Int 0)
               andBool (min(T) <=Int I1 /Int I2)
               andBool (max(T) >=Int I1 /Int I2)
               andBool T ==Type T'
          [structural]
     rule (.K => UNDEF("CEMX2", "Modulus by 0.", "6.5.5:5, J.2:1 item 45") )
          ~> L:RValue % tv(0, T':Type)
          requires isIntegerType(type(L)) andBool isPromoted(type(L))
               andBool type(L) ==Type T'
          [structural]
     rule (.K => UNDEF("CEMX3", "Signed overflow.", "6.5:5, J.2:1 item 36") ) ~>
          tv(I1:Int, T:IntegerType) % tv(I2:Int, T':Type)
          requires I2 =/=Int 0 
               andBool notBool (min(T) <=Int I1 /Int I2
                    andBool max(T) >=Int I1 /Int I2)
               andBool isPromoted(T)
               andBool I2 =/=Int 0
               andBool T ==Type T'
          [structural]
     rule _:ErrorExit ~> tv(I1:Int, T:IntegerType) % tv(I2:Int, T':Type)
          => arithInterpret(T, I1 %Int I2)
          requires isPromoted(T) andBool I2 =/=Int 0 andBool T ==Type T'
               andBool isErrorRecovery

endmodule

