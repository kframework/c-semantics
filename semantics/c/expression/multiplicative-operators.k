module C-EXPRESSION-MULTIPLICATIVE-OPERATORS
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
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
     
     rule tv(I1:Int, T:Type) * tv(I2:Int, T:Type)
          => arithInterpret(T, I1:Int *Int I2:Int)
          when isPromoted(T)
          [structural]
     rule tv(F1:Float, T:Type) * tv(F2:Float, T:Type)
          => arithInterpret(T, F1:Float *Float F2:Float)
          [structural]
          
     rule tv(I1:Bits, T:Type) / tv(I2:Int, T:Type)
          => arithInterpret(T, I1 /Bits I2)
          when isPromoted(T:Type) andBool I2 =/=Int 0
          [structural]
     rule tv(F1:Float, T:Type) / tv(F2:Float, T:Type)
          => arithInterpret(T, F1:Float /Float F2:Float)
          [structural]
     // fixme this seems out of place and strange
     rule piece(unknown(N:Int), N) /Bits M:Int
          => piece(unknown(N), N)
          when M =/=Int 0
          [structural, anywhere]
          
     rule tv(I1:Int, T:Type) % tv(I2:Int, T:Type)
          => arithInterpret(T, I1 %Int I2)
          when isPromoted(T)
               andBool (min(T) <=Int I1:Int /Int I2:Int) 
               andBool (max(T) >=Int I1:Int /Int I2:Int)
               andBool (I2:Int =/=Int 0)
          [structural]
endmodule

