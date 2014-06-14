module C-COMMON-EXPR-MULTIPLICATIVE

     imports C-BITS-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-PROMOTION-SYNTAX
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

     rule tv(I1:Int, T:Type) * tv(I2:Int, T':Type)
          => arithInterpret(T, I1 *Int I2)
          when isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) * tv(F2:Float, T':Type)
          => arithInterpret(T, F1 *Float F2)
          when T ==Type T'
          [structural]

     rule tv(I1:Int, T:Type) / tv(I2:Int, T':Type)
          => arithInterpret(T, I1 /Int I2)
          when isPromoted(T:Type) andBool I2 =/=Int 0
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) / tv(F2:Float, T':Type)
          => arithInterpret(T, F1 /Float F2)
          when T ==Type T'
          [structural]
     rule (. => UNDEF("CEM1", "Division by 0.", "6.5.5:5") )
          ~> tv(_, T:Type) / tv(0, T':Type)
          when hasIntegerType(T) andBool isPromoted(T)
               andBool T ==Type T'
          [structural]

     rule tv(I1:Int, T:Type) % tv(I2:Int, T':Type)
          => arithInterpret(T, I1 %Int I2)
          when isPromoted(T)
               andBool (min(T) <=Int I1 /Int I2) 
               andBool (max(T) >=Int I1 /Int I2)
               andBool (I2 =/=Int 0)
               andBool T ==Type T'
          [structural]
     rule (. => UNDEF("CEM2", "Modulus by 0.", "6.5.5:5") )
          ~> tv(_, T:Type) % tv(0, T':Type)
          when hasIntegerType(T) andBool isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule (. => UNSPEC("CEM3", "Signed overflow.", "6.3.1.3:3") ) ~>
          tv(I1:Int, T:Type) % tv(I2:Int, T':Type)
          when hasIntegerType(T)
               andBool notBool (min(T) <=Int I1 /Int I2
                    andBool max(T) >=Int I1 /Int I2)
               andBool isPromoted(T)
               andBool I2 =/=Int 0
               andBool T ==Type T'
          [structural]

endmodule

