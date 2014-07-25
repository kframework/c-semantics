module C-COMMON-EXPR-BITWISE
     imports C-BITS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

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
     rule tv(E1:Int, T1:Type) << tv(E2:Int, T2:Type)
          => cast(T1, tv(E1 <<Int E2, cfg:largestUnsigned))
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T1)
               andBool E1 >=Int 0
          [structural]
     rule (. => CV("CEB1", "Both bitwise shift operands must have integer type.", "6.5.7:2"))
          ~> tv(_, T1:Type) << tv(_, T2:Type)
          requires notBool hasIntegerType(T1) 
               orBool notBool hasIntegerType(T2)
          [structural]
     rule (. => UNDEF("CEB2", "The right operand in a bitwise shift is negative.", "6.5.7:3"))
          ~> tv(_, _) << tv(E2:Int, _)
          requires E2 <Int 0
          [structural]
     rule (. => UNDEF("CEB3", "The right operand in a bitwise shift is greater than or equal to the bit width of the left operand.", "6.5.7:3"))
          ~> tv(_, T1:Type) << tv(E2:Int, _)
          requires E2 >=Int bitSizeofType(T1)
          [structural]
     rule (. => UNDEF("CEB4", "The left operand in a bitwise left-shift is negative.", "6.5.7:4"))
          ~> tv(E1:Int, _) << tv(_, _)
          requires E1 <Int 0
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.7}{5}}}{
     The result of \cinline{E1 >> E2} is \cinline{E1} right-shifted
     \cinline{E2} bit positions. If \cinline{E1} has an unsigned type or if
     \cinline{E1} has a signed type and a nonnegative value, the value of the
     result is the integral part of the quotient of $\text{\cinline{E1}} /
     2^\text{\cinline{E2}}$. If \cinline{E1} has a signed type and a negative
     value, the resulting value is implementation-defined.
     }*/
     rule tv(E1:Int, T1:Type) >> tv(E2:Int, T2:Type) 
          => cast(T1, tv(E1 >>Int E2, cfg:largestUnsigned))
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T1)
               andBool E1 >=Int 0
          [structural]
     rule (. => CV("CEB5", "Both bitwise shift operands must have integer type.", "6.5.7:2"))
          ~> tv(_, T1:Type) >> tv(_, T2:Type)
          requires notBool hasIntegerType(T1) 
               orBool notBool hasIntegerType(T2)
          [structural]
     rule (. => UNDEF("CEB6", "The right operand in a bitwise shift is negative.", "6.5.7:3"))
          ~> tv(_, _) >> tv(E2:Int, _)
          requires E2 <Int 0
          [structural]
     rule (. => UNDEF("CEB7", "The right operand in a bitwise shift is greater than or equal to the bit width of the left operand.", "6.5.7:3"))
          ~> tv(_, T1:Type) >> tv(E2:Int, _)
          requires E2 >=Int bitSizeofType(T1)
          [structural]
     rule (. => UNSPEC("CEB8", "The left operand in a bitwise right-shift is negative.", "6.5.7:5"))
          ~> tv(E1:Int, _) >> tv(_, _)
          requires E1 <Int 0
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.10}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.

     The result of the binary \cinline{&} operator is the bitwise AND of the
     operands (that is, each bit in the result is set if and only if each of
     the corresponding bits in the converted operands is set).
     }*/
     rule tv(E1:Bits, T:Type) & tv(E2:Bits, T':Type)
          => arithInterpret(T, E1 &Bits E2)
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule (. => CV("CEB9", "Both bitwise AND operands must have integer type.", "6.5.10:2"))
          ~> tv(_, T1:Type) & tv(_, T2:Type)
          requires notBool hasIntegerType(T1)
               orBool notBool hasIntegerType(T2)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.11}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.

     The result of the \cinline{^} operator is the bitwise exclusive OR of the
     operands (that is, each bit in the result is set if and only if exactly
     one of the corresponding bits in the converted operands is set).     
     }*/
     rule tv(E1:Bits, T:Type) ^ tv(E2:Bits, T':Type)
          => arithInterpret(T, E1 xorBits E2)
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule (. => CV("CEB10", "Both bitwise exclusive OR operands must have integer type.", "6.5.11:2"))
          ~> tv(_, T1:Type) ^ tv(_, T2:Type)
          requires notBool hasIntegerType(T1)
               orBool notBool hasIntegerType(T2)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.12}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.

     The result of the \cinline{|} operator is the bitwise inclusive OR of the
     operands (that is, each bit in the result is set if and only if at least
     one of the corresponding bits in the converted operands is set).
     }*/
     rule tv(E1:Bits, T:Type) | tv(E2:Bits, T':Type)
          => arithInterpret(T, E1 |Bits E2)
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule (. => CV("CEB11", "Both bitwise inclusive OR operands must have integer type.", "6.5.12:2"))
          ~> tv(_, T1:Type) | tv(_, T2:Type)
          requires notBool hasIntegerType(T1)
               orBool notBool hasIntegerType(T2)
          [structural]
endmodule
