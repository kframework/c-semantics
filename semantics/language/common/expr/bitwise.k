module C-COMMON-EXPR-BITWISE
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{4}}}{
     The result of the \cinline{\~} operator is the bitwise complement of its
     (promoted) operand (that is, each bit in the result is set if and only if
     the corresponding bit in the converted operand is not set). The integer
     promotions are performed on the operand, and the result has the promoted
     type. If the promoted type is an unsigned type, the expression
     \cinline{\~E} is equivalent to the maximum value representable in that
     type minus \cinline{E}.
     }*/
     rule ~ tv(I:Int, T:Type) => bitwiseInterpret(T, ~Int I, isNegZero(I, T))
          requires isPromoted(T)
          [structural]

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
          => bitwiseInterpret(T1, E1 <<Int E2,
               isNegZero(E1, T1) orBool isNegZero(E2, T2))
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T1)
               andBool E1 >=Int 0
          [structural]
     rule (.K => CV("CEB1",
               "Both bitwise shift operands must have integer type.",
               "6.5.7:2"))
          ~> L:RValue << R:RValue
          requires notBool isIntegerType(type(L))
               orBool notBool isIntegerType(type(R))
          [structural]
     rule (.K => UNDEF("CEB2",
               "The right operand in a bitwise shift is negative.",
               "6.5.7:3, J.2:1 item 51"))
          ~> L:RValue << tv(E2:Int, T2:Type)
          requires isPromoted(type(L)) andBool isPromoted(T2)
               andBool E2 <Int 0
          [structural]
     rule (.K => UNDEF("CEB3",
               "The right operand in a bitwise shift is greater than or equal to the bit width of the left operand.",
               "6.5.7:3, J.2:1 item 51"))
          ~> L:RValue << tv(E2:Int, T2:Type)
          requires isPromoted(type(L)) andBool isPromoted(T2)
               andBool E2 >=Int bitSizeofType(type(L))
          [structural]
     rule (.K => UNDEF("CEB4",
               "The left operand in a bitwise left-shift is negative.",
               "6.5.7:4, J.2:1 item 52"))
          ~> tv(E1:Int, T1:Type) << R:RValue
          requires isPromoted(T1) andBool isPromoted(type(R))
               andBool E1 <Int 0
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
          => bitwiseInterpret(T1, E1 >>Int E2,
               isNegZero(E1, T1) orBool isNegZero(E2, T2))
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T1)
               andBool (E1 >=Int 0 orBool notBool isSignedIntegerType(T1))
          [structural]
     rule (.K => CV("CEB5",
               "Both bitwise shift operands must have integer type.",
               "6.5.7:2"))
          ~> L:RValue >> R:RValue
          requires notBool isIntegerType(type(L))
               orBool notBool isIntegerType(type(R))
          [structural]
     rule (.K => UNDEF("CEB6",
               "The right operand in a bitwise shift is negative.",
               "6.5.7:3, J.2:1 item 51"))
          ~> L:RValue >> tv(E2:Int, T2:Type)
          requires isPromoted(type(L)) andBool isPromoted(T2)
               andBool E2 <Int 0
          [structural]
     rule (.K => UNDEF("CEB7",
               "The right operand in a bitwise shift is greater than or equal to the bit width of the left operand.",
               "6.5.7:3, J.2:1 item 51"))
          ~> L:RValue >> tv(E2:Int, T2:Type)
          requires isPromoted(type(L)) andBool isPromoted(T2)
               andBool E2 >=Int bitSizeofType(type(L))
          [structural]
     rule (.K => IMPL("CEB8",
               "The left operand in a bitwise right-shift is negative.",
               "6.5.7:5, J.3.5:1 item 5"))
          ~> tv(E1:Int, T1:Type) >> R:RValue
          requires isPromoted(T1) andBool isPromoted(type(R))
               andBool E1 <Int 0 andBool isSignedIntegerType(T1)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.10}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.

     The result of the binary \cinline{&} operator is the bitwise AND of the
     operands (that is, each bit in the result is set if and only if each of
     the corresponding bits in the converted operands is set).
     }*/
     rule tv(E1:Int, T:Type) & tv(E2:Int, T':Type)
          => bitwiseInterpret(T, E1 &Int E2,
               isNegZero(E1, T) orBool isNegZero(E2, T'))
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]

     rule tv(unknownAlignedInt(Align:Int), T:Type) & tv(E2:Int, T':Type)
          => #if Align >Int E2 #then tv(0, T) #else tv(unknown, T) & tv(E2, T') #fi
          requires isPromoted(T) andBool E2 >=Int 0
               andBool T ==Type T'
     rule tv(E1:Int, T:Type) & tv(unknownAlignedInt(Align:Int), T':Type)
          => #if Align >Int E1 #then tv(0, T) #else tv(E1, T) & tv(unknown, T') #fi
          requires isPromoted(T) andBool E1 >=Int 0
               andBool T ==Type T'

     rule tv(unknown, T:Type) & tv(E2:Int, T':Type)
          => tv(unknown, T)
          requires isPromoted(T) andBool E2 >=Int 0
               andBool T ==Type T'
     rule tv(E1:Int, T:Type) & tv(unknown, T':Type)
          => tv(unknown, T)
          requires isPromoted(T) andBool E1 >=Int 0
               andBool T ==Type T'

     rule tv(unknown, T:Type) & tv(E2:Int, T':Type)
          => trap(T)
          requires isPromoted(T) andBool E2 <Int 0
               andBool T ==Type T'
     rule tv(E1:Int, T:Type) & tv(unknown, T':Type)
          => trap(T)
          requires isPromoted(T) andBool E1 <Int 0
               andBool T ==Type T'

     rule tv(L:SymLoc, T:Type) & tv(E2:Int, T':Type)
          => tv(L, T)
          requires ~Int (getAlign(L) -Int 1) &Int value(arithInterpret(T', ~Int E2)):>Int ==Int 0
               andBool isPromoted(T) andBool T ==Type T'
     rule tv(E2:Int, T:Type) & tv(L:SymLoc, T':Type)
          => tv(L, T)
          requires ~Int (getAlign(L) -Int 1) &Int ~Int E2 ==Int 0
               andBool isPromoted(T) andBool T ==Type T'


     rule (.K => CV("CEB9",
               "Both bitwise AND operands must have integer type.",
               "6.5.10:2"))
          ~> L:RValue & R:RValue
          requires notBool isIntegerType(type(L))
               orBool notBool isIntegerType(type(R))
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.11}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.

     The result of the \cinline{^} operator is the bitwise exclusive OR of the
     operands (that is, each bit in the result is set if and only if exactly
     one of the corresponding bits in the converted operands is set).
     }*/
     rule tv(E1:Int, T:Type) ^ tv(E2:Int, T':Type)
          => bitwiseInterpret(T, E1 xorInt E2,
               isNegZero(E1, T) orBool isNegZero(E2, T'))
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule (.K => CV("CEB10",
               "Both bitwise exclusive OR operands must have integer type.",
               "6.5.11:2"))
          ~> L:RValue ^ R:RValue
          requires notBool isIntegerType(type(L))
               orBool notBool isIntegerType(type(R))
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.12}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.

     The result of the \cinline{|} operator is the bitwise inclusive OR of the
     operands (that is, each bit in the result is set if and only if at least
     one of the corresponding bits in the converted operands is set).
     }*/
     rule tv(E1:Int, T:Type) | tv(E2:Int, T':Type)
          => bitwiseInterpret(T, E1 |Int E2,
               isNegZero(E1, T) orBool isNegZero(E2, T'))
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule (.K => CV("CEB11",
               "Both bitwise inclusive OR operands must have integer type.",
               "6.5.12:2"))
          ~> L:RValue | R:RValue
          requires notBool isIntegerType(type(L))
               orBool notBool isIntegerType(type(R))
          [structural]

     syntax KItem ::= bitwiseInterpret(Type, Int, Bool)
     rule bitwiseInterpret(T:UnsignedIntegerType, N:Int, _) => arithInterpret(T, N)
     rule bitwiseInterpret(T:SignedIntegerType, N:Int, true) => arithInterpret(T, N)
     rule bitwiseInterpret(T:SignedIntegerType, N:Int, false)
          => bitwiseInterpret(arithInterpret(T, N))

     syntax KItem ::= bitwiseInterpret(K) [strict]
     rule bitwiseInterpret(tv(N:Int, T:Type)) => tv(N, T)
          requires notBool isNegZero(N, T)
     rule (.K => UNDEF("CEB12",
               // TODO(chathhorn): this can result in false positives in cases
               // such as "~~INT_MIN" (where INT_MIN == ~INT_MAX) because
               // clearly INT_MIN can't be trap representation.
               "Potential negative zero produced via bitwise operations (this could be a false positive).",
               "6.2.6.2:4, J.2:1 item 14"))
          ~> bitwiseInterpret(tv(N:Int, T:Type))
          requires isNegZero(N, T)

     // Because of the undefinedness of bit shifting negative numbers, the
     // bitwise operations behave the same regardless of the encoding of
     // negative numbers. Detecting the negative zeros that might result under
     // different encodings, then, is just a matter of detecting the two
     // negative zero bit patterns in the result (100... and 111...).
     syntax Bool ::= isNegZero(Int, Type) [function]
     rule isNegZero(N:Int, T:Type) => true
          // TODO(chathhorn): Technically we shouldn't use min(T) for this
          // case, because clearly min(T) won't be a trap representation.
          requires N ==Int min(T) // Two's complement, sign and magnitude.
     rule isNegZero(N:Int, _) => true
          requires N ==Int -1 // Ones' complement.
     rule isNegZero(N:Int, T:Type) => false
          requires N =/=Int min(T)
               andBool N =/=Int -1

endmodule
