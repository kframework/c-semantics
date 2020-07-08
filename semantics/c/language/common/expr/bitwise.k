module C-COMMON-EXPR-BITWISE
     imports BASIC-K
     imports BOOL
     imports INT
     imports SYMLOC-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BITS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{4}}}{
     The result of the \cinline{\~} operator is the bitwise complement of its
     (promoted) operand (that is, each bit in the result is set if and only if
     the corresponding bit in the converted operand is not set). The integer
     promotions are performed on the operand, and the result has the promoted
     type. If the promoted type is an unsigned type, the expression
     \cinline{\~E} is equivalent to the maximum value representable in that
     type minus \cinline{E}.
     }*/
     rule ~ tv(I:Int, T::UType) => bitwiseInterpret(T, ~Int I, isNegZero(I, T), false)
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
     rule tv(E1:Int, T1::UType) << tv(E2:Int, T2::UType)
          => bitwiseInterpret(T1, E1 <<Int E2,
               isNegZero(E1, T1) orBool isNegZero(E2, T2),
               true)
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T1)
               andBool E1 >=Int 0
          [structural]

     rule tv((L:IntPtr => unknown(maxIntPtrValue(L))), T::UType) << tv(E2:Int, T'::UType)
          requires isPromoted(T) andBool isPromoted(T')
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T)

     rule (.K => CV("CEB1",
               "Both bitwise shift operands must have integer type."))
          ~> L:RValue << R:RValue
          requires notBool isIntegerType(type(L))
               orBool notBool isIntegerType(type(R))
          [structural]
     rule (.K => UNDEF("CEB2",
               "The right operand in a bitwise shift is negative."))
          ~> L:RValue << tv(E2:Int, T2::UType)
          requires isPromoted(utype(L)) andBool isPromoted(T2)
               andBool E2 <Int 0
          [structural]
     rule (.K => UNDEF("CEB3",
               "The right operand in a bitwise shift is greater than or equal to the bit width of the left operand."))
          ~> L:RValue << tv(E2:Int, T2::UType)
          requires isPromoted(utype(L)) andBool isPromoted(T2)
               andBool E2 >=Int bitSizeofType(type(L))
          [structural]
     rule (.K => UNDEF("CEB4",
               "The left operand in a bitwise left-shift is negative."))
          ~> tv(E1:Int, signedIntegerUType #as T1::UType) << R:RValue
          requires isPromoted(T1) andBool isPromoted(utype(R))
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
     rule tv(E1:Int, T1::UType) >> tv(E2:Int, T2::UType)
          => bitwiseInterpret(T1, E1 >>Int E2,
               isNegZero(E1, T1) orBool isNegZero(E2, T2),
               true)
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T1)
               andBool E1 >=Int 0
          [structural]

     rule tv((L:IntPtr => unknown(maxIntPtrValue(L))), T::UType) >> tv(E2:Int, T'::UType)
          requires isPromoted(T) andBool isPromoted(T')
               andBool E2 >=Int 0
               andBool E2 <Int bitSizeofType(T)

     rule (.K => CV("CEB5",
               "Both bitwise shift operands must have integer type."))
          ~> L:RValue >> R:RValue
          requires notBool isIntegerType(type(L))
               orBool notBool isIntegerType(type(R))
          [structural]
     rule (.K => UNDEF("CEB6",
               "The right operand in a bitwise shift is negative."))
          ~> L:RValue >> tv(E2:Int, T2::UType)
          requires isPromoted(utype(L)) andBool isPromoted(T2)
               andBool E2 <Int 0
          [structural]
     rule (.K => UNDEF("CEB7",
               "The right operand in a bitwise shift is greater than or equal to the bit width of the left operand."))
          ~> L:RValue >> tv(E2:Int, T2::UType)
          requires isPromoted(utype(L)) andBool isPromoted(T2)
               andBool E2 >=Int bitSizeofType(type(L))
          [structural]
     rule (.K => IMPL("CEB8",
               "The left operand in a bitwise right-shift is negative."))
          ~> tv(E1:Int, signedIntegerUType #as T1::UType) >> R:RValue
          requires isPromoted(T1) andBool isPromoted(utype(R))
               andBool E1 <Int 0
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.10}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.

     The result of the binary \cinline{&} operator is the bitwise AND of the
     operands (that is, each bit in the result is set if and only if each of
     the corresponding bits in the converted operands is set).
     }*/
     rule tv(E1:Int, T::UType) & tv(E2:Int, T'::UType)
          => bitwiseInterpret(T, E1 &Int E2,
               isNegZero(E1, T) orBool isNegZero(E2, T'),
               false)
          requires isPromoted(T) andBool T ==Type T'
          [structural]

     rule tv(L:SymLoc, T::UType) & tv(E2:Int, T'::UType)
          => tv(L, T) + tv((offset(L) &Int E2) -Int offset(L), T')
          requires (~Int (getAlign(L) -Int 1) &Int ~Int E2) &Int max(correspondingUnsignedType(T)) ==Int 0
               andBool isPromoted(T) andBool T ==Type T'
     rule tv(E2:Int, T::UType) & tv(L:SymLoc, T'::UType)
          => tv((offset(L) &Int E2) -Int offset(L), T) + tv(L, T')
          requires (~Int (getAlign(L) -Int 1) &Int ~Int E2) &Int max(correspondingUnsignedType(T)) ==Int 0
               andBool isPromoted(T) andBool T ==Type T'

     rule tv(L:SymLoc, T::UType) & tv(E2:Int, T'::UType)
          => tv(0, T)
          requires getAlign(L) >Int E2 andBool E2 >=Int 0
               andBool isPromoted(T) andBool T ==Type T'
     rule tv(E2:Int, T::UType) & tv(L:SymLoc, T'::UType)
          => tv(0, T)
          requires getAlign(L) >Int E2 andBool E2 >=Int 0
               andBool isPromoted(T) andBool T ==Type T'

     rule tv((L:SymLoc => unknown(maxIntPtrValue(L))), T::UType) & tv(E2:Int, T'::UType)
          requires notBool (getAlign(L) >Int E2 andBool E2 >=Int 0)
               andBool notBool ((~Int (getAlign(L) -Int 1) &Int ~Int E2) &Int max(correspondingUnsignedType(T)) ==Int 0)
               andBool isPromoted(T) andBool T ==Type T'
     rule tv(E2:Int, T::UType) & tv((L:SymLoc => unknown(maxIntPtrValue(L))), T'::UType)
          requires notBool (getAlign(L) >Int E2 andBool E2 >=Int 0)
               andBool notBool ((~Int (getAlign(L) -Int 1) &Int ~Int E2) &Int max(correspondingUnsignedType(T)) ==Int 0)
               andBool isPromoted(T) andBool T ==Type T'

     rule (.K => CV("CEB9",
               "Both bitwise AND operands must have integer type."))
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
     rule tv(E1:Int, T::UType) ^ tv(E2:Int, T'::UType)
          => bitwiseInterpret(T, E1 xorInt E2,
               isNegZero(E1, T) orBool isNegZero(E2, T'),
               false)
          requires isPromoted(T) andBool T ==Type T'
          [structural]


     rule tv(_:IntPtr, T::UType) ^ tv(I::CValue, T'::UType)
          => tv(unknown(0), T)
          requires isPromoted(T) andBool T ==Type T'
               andBool I =/=K 0
     rule tv(I::CValue, T::UType) ^ tv(_:IntPtr, T'::UType)
          => tv(unknown(0), T)
          requires isPromoted(T) andBool T ==Type T'
               andBool I =/=K 0
     rule tv(0, T::UType) ^ tv(I:IntPtr, T'::UType)
          => tv(I, T)
          requires isPromoted(T) andBool T ==Type T'
     rule tv(I:IntPtr, T::UType) ^ tv(0, T'::UType)
          => tv(I, T)
          requires isPromoted(T) andBool T ==Type T'

     rule (.K => CV("CEB10",
               "Both bitwise exclusive OR operands must have integer type."))
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
     rule tv(E1:Int, T::UType) | tv(E2:Int, T'::UType)
          => bitwiseInterpret(T, E1 |Int E2,
               isNegZero(E1, T) orBool isNegZero(E2, T'),
               false)
          requires isPromoted(T) andBool T ==Type T'
          [structural]

     rule tv(L:SymLoc, T::UType) | tv(E2:Int, T'::UType)
          => tv(L, T) + tv((offset(L) |Int E2) -Int offset(L), T')
          requires getAlign(L) >Int E2 andBool E2 >=Int 0
               andBool isPromoted(T) andBool T ==Type T'
               andBool L =/=K NullPointer
     rule tv(E2:Int, T::UType) | tv(L:SymLoc, T'::UType)
          => tv((offset(L) |Int E2) -Int offset(L), T) + tv(L, T')
          requires getAlign(L) >Int E2 andBool E2 >=Int 0
               andBool isPromoted(T) andBool T ==Type T'
               andBool L =/=K NullPointer
     rule tv(NullPointer, T::UType) | tv(E2:Int, T'::UType)
          => tv(E2, T')
          requires isPromoted(T) andBool T ==Type T'
     rule tv(E2:Int, T::UType) | tv(NullPointer, T'::UType)
          => tv(E2, T')
          requires isPromoted(T) andBool T ==Type T'

     rule (.K => CV("CEB11",
               "Both bitwise inclusive OR operands must have integer type."))
          ~> L:RValue | R:RValue
          requires notBool isIntegerType(type(L))
               orBool notBool isIntegerType(type(R))
          [structural]

     syntax KItem ::= bitwiseInterpret(UType, Int, Bool, overflowLint: Bool)   [klabel(bitwiseInterpret3)]
     rule bitwiseInterpret(unsignedIntegerUType #as T::UType, N::Int, _, OverflowLint:Bool) => intArithInterpret(T, N, OverflowLint)
     rule bitwiseInterpret(signedIntegerUType #as T::UType, N::Int, true, OverflowLint:Bool) => intArithInterpret(T, N, OverflowLint)
     rule bitwiseInterpret(signedIntegerUType #as T::UType, N::Int, false, OverflowLint:Bool)
          => bitwiseInterpret(intArithInterpret(T, N, OverflowLint:Bool))

     syntax KItem ::= bitwiseInterpret(KItem) [strict]
     rule bitwiseInterpret(tv(N:Int, T::UType)) => tv(N, T)
          requires notBool isNegZero(N, T)
     rule bitwiseInterpret(tv(N::CValue, T::UType)) => tv(N, T)
          requires notBool isInt(N)
     rule (.K => IMPLUB("CEB12",
               // TODO(chathhorn): this can result in false positives in cases
               // such as "~~INT_MIN" (where INT_MIN == ~INT_MAX) because
               // clearly INT_MIN can't be a trap representation.
               "Potential negative zero produced via bitwise operations, undefined under sign and magnitude or one's complement arithmetic, implementation-defined otherwise."))
          ~> bitwiseInterpret(tv(N:Int, T::UType))
          requires isNegZero(N, T)

     // Because of the undefinedness of bit shifting negative numbers, the
     // bitwise operations behave the same regardless of the encoding of
     // negative numbers. Detecting the negative zeros that might result under
     // different encodings, then, is just a matter of detecting the two
     // negative zero bit patterns in the result (100... and 111...).
     syntax Bool ::= isNegZero(Int, UType) [function]
     rule isNegZero(N::Int, T::UType) => true
          // TODO(chathhorn): Technically we shouldn't use min(T) for this
          // case, because clearly min(T) won't be a trap representation.
          requires N ==Int min(T) // Two's complement, sign and magnitude.
     rule isNegZero(N::Int, _) => true
          requires N ==Int -1 // Ones' complement.
     rule isNegZero(N::Int, T::UType) => false
          requires N =/=Int min(T) andBool N =/=Int -1

     rule tv(V::CValue, T::UType) ^ tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) ^ tv(stripUnknown(V'), T'))
          requires (isUnknown(V) orBool isUnknown(V'))
     rule tv(V::CValue, T::UType) & tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) & tv(stripUnknown(V'), T'))
          requires (isUnknown(V) orBool isUnknown(V'))
     rule tv(V::CValue, T::UType) | tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) | tv(stripUnknown(V'), T'))
          requires (isUnknown(V) orBool isUnknown(V'))
     rule tv(V::CValue, T::UType) >> tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) >> tv(stripUnknown(V'), T'))
          requires (isUnknown(V) orBool isUnknown(V'))
     rule tv(V::CValue, T::UType) << tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) << tv(stripUnknown(V'), T'))
          requires (isUnknown(V) orBool isUnknown(V'))

endmodule
