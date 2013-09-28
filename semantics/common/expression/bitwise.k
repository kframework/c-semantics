module C-EXPRESSION-BITWISE-SYNTAX
     // TODO(chathhorn): error check
     syntax K ::= leftShiftInterpret(Type, BaseValue, K) [function]
     syntax K ::= rightShiftInterpret(Type, BaseValue) [function]
endmodule

module C-EXPRESSION-BITWISE
     imports C-EXPRESSION-BITWISE-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.7}{3}}}{
     The integer promotions are performed on each of the operands. The type of
     the result is that of the promoted left operand. If the value of the right
     operand is negative or is greater than or equal to the width of the
     promoted left operand, the behavior is undefined
     }*/
     /*@ \fromStandard{\source[n1570]{\para{6.5.7}{4}}}{
     The result of \cinline{E1 << E2} is \cinline{E1} left-shifted \cinline{E2}
     bit positions; vacated bits are filled with zeros. If \cinline{E1} has an
     unsigned type, the value of the result is $\text{\cinline{E1}}\times
     2^\text{\cinline{E2}}$, reduced modulo one more than the maximum value
     representable in the result type. If \cinline{E1} has a signed type and
     nonnegative value, and $\text{\cinline{E1}}\times 2^\text{\cinline{E2}}$
     is representable in the result type, then that is the resulting value;
     otherwise, the behavior is undefined.
     }*/
     rule tv(I:Int, T:Type) << tv(N:Int, T':Type)
          => leftShiftInterpret(T, I <<Int N, tv(I, T))
          when isPromoted(T) andBool isPromoted(T')
               andBool N <Int numBits(T)
          [structural]
     rule leftShiftInterpret(T:Type, I:Int, tv(_:Int, T:Type))
          => tv(I:Int %Int (max(T) +Int 1), T)
          when hasUnsignedIntegerType(T)
     rule leftShiftInterpret(T:Type, I:Int, tv(E:Int, T:Type))
          => tv(I, T)
          when hasSignedIntegerType(T)
               andBool E >=Int 0
               andBool I <=Int max(T)
               andBool I >=Int min(T)
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.7}{5}}}{
     The result of \cinline{E1 >> E2} is \cinline{E1} right-shifted
     \cinline{E2} bit positions. If \cinline{E1} has an unsigned type or if
     \cinline{E1} has a signed type and a nonnegative value, the value of the
     result is the integral part of the quotient of $\text{\cinline{E1}} /
     2^\text{\cinline{E2}}$. If \cinline{E1} has a signed type and a negative
     value, the resulting value is implementation-defined.
     }*/
     rule tv(I:Int, T:Type) >> tv(N:Int, T':Type) 
          => rightShiftInterpret(T, I >>Int N)
          when isPromoted(T) andBool isPromoted(T')
               andBool N <Int numBits(T)
          [structural]
     rule rightShiftInterpret(T:Type, I:Int) => tv(I, T)
          when hasIntegerType(T)

     /*@ \fromStandard{\source[n1570]{\para{6.5.10}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.
     
     The result of the binary \cinline{&} operator is the bitwise AND of the
     operands (that is, each bit in the result is set if and only if each of
     the corresponding bits in the converted operands is set).
     }*/
     rule tv(I1:Bits, T:Type) & tv(I2:Bits, T:Type)
          => arithInterpret(T, I1 &Bits I2)
          when isPromoted(T)
          [structural]
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.11}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.
     
     The result of the \cinline{^} operator is the bitwise exclusive OR of the
     operands (that is, each bit in the result is set if and only if exactly
     one of the corresponding bits in the converted operands is set).     
     }*/
     rule tv(I1:Bits, T:Type) ^ tv(I2:Bits, T:Type)
          => arithInterpret(T, I1 xorBits I2)
          when isPromoted(T)
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.12}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.
     
     The result of the \cinline{|} operator is the bitwise inclusive OR of the
     operands (that is, each bit in the result is set if and only if at least
     one of the corresponding bits in the converted operands is set).
     }*/
     rule tv(I1:Bits, T:Type) | tv(I2:Bits, T:Type)
          => arithInterpret(T, I1 |Bits I2)
          when isPromoted(T)
          [structural]
endmodule
