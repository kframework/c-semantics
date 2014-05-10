module C-CONVERSION-SYNTAX
     // interpret the result of arithmetic as in 6.5.4
     syntax K ::= arithInterpret(Type, BaseValue) [function]
     // as described in 6.3 // totype, fromvalue
     syntax TypedValue ::= cast(Type, Value) [function]
endmodule

module C-CONVERSION
     imports C-CONVERSION-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-SYMLOC-SYNTAX
     
     rule arithInterpret(T:Type, I:Int) => tv(I, T)
          when (min(T) <=Int I) 
               andBool (max(T) >=Int I)
               andBool hasIntegerType(T)
     rule arithInterpret(T:Type, piece(unknown(N:Int), N:Int)) 
          => tv(piece(unknown(N), N), T)
     // fixme
     rule arithInterpret(t(S:Set, T:SimpleType), F:Float) 
          => tv(F, t(S, T))
          when (T ==K double)
               orBool (T ==K float)
               orBool (T ==K long-double)
     // signed arithmetic isn't supposed to overflow
     rule arithInterpret(T:Type, I:Int) => tv(I %Int (max(T) +Int 1), T)
          when hasUnsignedIntegerType(T)
               andBool (I >Int max(T))
     rule arithInterpret(T:Type, I:Int) 
          => arithInterpret(T, (I %Int (max(T) +Int 1)) +Int (max(T) +Int 1))
          // must be like this so ((unsigned int)(~((unsigned int)~0)) != 0)
          // will work, but not sure why
          when hasUnsignedIntegerType(T)
               andBool (I <Int min(T))

     //- switch assumes casts can happen anywhere
     rule cast(T:Type, tv(V:CValue, T:Type)) => tv(V, T)
          
     rule cast(t(S:Set, T:SimpleType), tv(V:CValue, t(_, T:SimpleType))) 
          => tv(V, t(S, T))
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.2}{1}}}{
     When any scalar value is converted to \cinline{_Bool}, the result is 0 if
     the value compares equal to 0; otherwise, the result is 1.
     }*/
     rule cast(t(S:Set, bool), tv(I:Int, T:Type))
          => #if I ==Int 0 
               #then tv(0, t(S, bool)) 
               #else tv(1, t(S, bool)) #fi
          when hasIntegerType(T)
     rule cast(t(S:Set, bool), tv(F:Float, T:Type))
          => #if Float2Int(F) ==Int 0 
               #then tv(0, t(S, bool)) 
               #else tv(1, t(S, bool)) #fi
          when isFloatType(T)
     rule cast(t(S:Set, bool), tv(V:CValue, T:Type))
          => #if V ==K NullPointer 
               #then tv(0, t(S, bool)) 
               #else tv(1, t(S, bool)) #fi
          when isPointerType(T)

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{1}}}{
     When a value with integer type is converted to another integer type other
     than \cinline{_Bool}, if the value can be represented by the new type, it
     is unchanged.
     }*/
     rule cast(T':Type, tv(I:Int, T:Type)) => tv(I, T')
          when (min(T') <=Int I)
               andBool (max(T') >=Int I)
               andBool hasIntegerType(T)
               andBool hasIntegerType(T')
               andBool notBool isBoolType (T')
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{2}}}{
     Otherwise, if the new type is unsigned, the value is converted by
     repeatedly adding or subtracting one more than the maximum value that can
     be represented in the new type until the value is in the range of the new
     type.
     }*/
     rule cast(T':Type, tv(I:Int, T:Type)) 
          => cast(T', tv(I +Int max(T') +Int 1, T))
          when isBitfieldType(T')
               andBool (I <Int min(T'))
               andBool hasIntegerType(T)
               andBool hasUnsignedIntegerType(innerType(T'))
     rule cast(t(S:Set, unsigned-char), tv(I:Int, T:Type)) 
          => cast(t(S, unsigned-char), 
               tv(I +Int max(t(S, unsigned-char)) +Int 1, T))
          when (I <Int min(t(S, unsigned-char)))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, unsigned-short-int), tv(I:Int, T:Type)) 
          => cast(t(S, unsigned-short-int),
               tv(I +Int max(t(S, unsigned-short-int)) +Int 1, T))
          when (I <Int min(t(S, unsigned-short-int)))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, unsigned-int), tv(I:Int, T:Type)) 
          => cast(t(S, unsigned-int),
               tv(I +Int max(t(S, unsigned-int)) +Int 1, T))
          when (I <Int min(t(S, unsigned-int)))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, unsigned-long-int), tv(I:Int, T:Type)) 
          => cast(t(S, unsigned-long-int),
               tv(I +Int max(t(S, unsigned-long-int)) +Int 1, T))
          when (I <Int min(t(S, unsigned-long-int))) 
               andBool hasIntegerType(T)
     rule cast(t(S:Set, unsigned-long-long-int), tv(I:Int, T:Type)) 
          => cast(t(S, unsigned-long-long-int),
               tv(I +Int max(t(S, unsigned-long-long-int)) +Int 1, T))
          when (I <Int min(t(S, unsigned-long-long-int)))
               andBool hasIntegerType(T)          
     
     rule cast(T':Type, tv(I:Int, T:Type)) 
          => tv(I %Int (max(T') +Int 1), T')
          when isBitfieldType(T')
               andBool (I >Int max(T'))
               andBool hasIntegerType(T)
               andBool hasUnsignedIntegerType(innerType(T'))
     rule cast(t(S:Set, unsigned-char), tv(I:Int, T:Type)) 
          => tv(I %Int (max(t(S, unsigned-char)) +Int 1), t(S, unsigned-char))
          when (I >Int max(t(S, unsigned-char)))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, unsigned-short-int), tv(I:Int, T:Type)) 
          => tv(I %Int (max(t(S, unsigned-short-int)) +Int 1),
               t(S, unsigned-short-int))
          when (I >Int max(t(S, unsigned-short-int)))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, unsigned-int), tv(I:Int, T:Type)) 
          => tv(I %Int (max(t(S, unsigned-int)) +Int 1),
               t(S, unsigned-int))
          when (I >Int max(t(S, unsigned-int)))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, unsigned-long-int), tv(I:Int, T:Type)) 
          => tv(I %Int (max(t(S, unsigned-long-int)) +Int 1),
               t(S, unsigned-long-int))
          when (I >Int max(t(S, unsigned-long-int)))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, unsigned-long-long-int), tv(I:Int, T:Type)) 
          => tv(I %Int (max(t(S, unsigned-long-long-int)) +Int 1),
               t(S, unsigned-long-long-int))
          when (I >Int max(t(S, unsigned-long-long-int)))
               andBool hasIntegerType(T)

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{3}}}{
     Otherwise, the new type is signed and the value cannot be represented in
     it; either the result is implementation-defined or an
     implementation-defined signal is raised.
     }*/
     // choice
     rule cast(T':Type, tv(I:Int, T:Type)) 
          => cast(T', tv(I %Int (2 ^Int absInt(numBits(T'))), T)) 
          when isBitfieldType(T')
               andBool (absInt(I) >Int (2 ^Int absInt(numBits(T'))))
               andBool hasIntegerType(T)
               andBool hasSignedIntegerType(innerType(T'))
     rule cast(t(S:Set, signed-char), tv(I:Int, T:Type)) 
          => cast(t(S, signed-char),
               tv(I %Int (2 ^Int absInt(numBits(t(S, signed-char)))), T)) 
          when (absInt(I) >Int (2 ^Int absInt(numBits(t(S, signed-char)))))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, short-int), tv(I:Int, T:Type)) 
          => cast(t(S, short-int), 
               tv(I %Int (2 ^Int absInt(numBits(t(S, short-int)))), T)) 
          when (absInt(I) >Int (2 ^Int absInt(numBits(t(S, short-int)))))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, int), tv(I:Int, T:Type)) 
          => cast(t(S, int), 
               tv(I %Int (2 ^Int absInt(numBits(t(S, int)))), T)) 
          when (absInt(I) >Int (2 ^Int absInt(numBits(t(S, int)))))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, long-int), tv(I:Int, T:Type)) 
          => cast(t(S, long-int), 
               tv(I %Int (2 ^Int absInt(numBits(t(S, long-int)))), T)) 
          when (absInt(I) >Int (2 ^Int absInt(numBits(t(S, long-int)))))
               andBool hasIntegerType(T)
     rule cast(t(S:Set, long-long-int), tv(I:Int, T:Type))
          => cast(t(S, long-long-int), 
               tv(I %Int (2 ^Int absInt(numBits(t(S, long-long-int)))), T)) 
          when (absInt(I) >Int (2 ^Int absInt(numBits(t(S, long-long-int)))))
               andBool hasIntegerType(T)
          
     rule cast(T':Type, tv(I:Int, T:Type))
          => tv(I +Int (2 ^Int absInt(numBits(T'))), T')
          when (I <Int min(T'))
               andBool (absInt(I) <=Int (2 ^Int absInt(numBits(T'))))
               andBool hasSignedIntegerType(T')
               andBool hasIntegerType(T)
               andBool notBool isBoolType (T')
     rule cast(T':Type, tv(I:Int, T:Type)) 
          => tv(I -Int (2 ^Int absInt(numBits(T'))), T')
          when (I >Int max(T'))
               andBool (absInt(I) <=Int (2 ^Int absInt(numBits(T'))))
               andBool hasSignedIntegerType(T')
               andBool hasIntegerType(T)
               andBool notBool isBoolType (T')

     // this is starting to get into sketchy land
     rule cast(T':Type, tv(piece(unknown(Len:Int), Len:Int), T:Type)) 
          => tv(piece(unknown(bitSizeofType(T')), bitSizeofType(T')), T')
          when hasIntegerType(T') andBool hasIntegerType(T)
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.4}{1}}}{
     When a finite value of real floating type is converted to an integer type
     other than \cinline{_Bool}, the fractional part is discarded (i.e., the
     value is truncated toward zero). If the value of the integral part cannot
     be represented by the integer type, the behavior is undefined.
     }*/
     // fixme
     rule cast(T:Type, tv(V:Float, t(S:Set, double))) 
          => cast(T, tv(Float2Int(V), t(S, long-long-int)))
          when hasIntegerType(T)
               andBool notBool isBoolType (T)
     rule cast(T:Type, tv(V:Float, t(S:Set, float))) 
          => cast(T, tv(Float2Int(V), t(S, long-long-int)))
          when hasIntegerType(T)
               andBool notBool isBoolType (T)
     rule cast(T:Type, tv(V:Float, t(S:Set, long-double))) 
          => cast(T, tv(Float2Int(V), t(S, long-long-int)))
          when hasIntegerType(T)
               andBool notBool isBoolType (T)
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.4}{2}}}{
     When a value of integer type is converted to a real floating type, if the
     value being converted can be represented exactly in the new type, it is
     unchanged. If the value being converted is in the range of values that can
     be represented but cannot be represented exactly, the result is either the
     nearest higher or nearest lower representable value, chosen in an
     implementation-defined manner. If the value being converted is outside the
     range of values that can be represented, the behavior is undefined.
     Results of some implicit conversions may be represented in greater range
     and precision than that required by the new type (see 6.3.1.8 and
     6.8.6.4).
     }*/
     rule cast(t(S:Set, float), tv(I:Int, T:Type)) 
          => tv(Int2Float(I), t(S, float))
          when hasIntegerType(T)
     rule cast(t(S:Set, double), tv(I:Int, T:Type)) 
          => tv(Int2Float(I), t(S, double))
          when hasIntegerType(T)
     rule cast(t(S:Set, long-double), tv(I:Int, T:Type)) 
          => tv(Int2Float(I), t(S, long-double))
          when hasIntegerType(T)
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.5}{2}}}{
     When a value of real floating type is converted to a real floating type,
     if the value being converted can be represented exactly in the new type,
     it is unchanged. If the value being converted is in the range of values
     that can be represented but cannot be represented exactly, the result is
     either the nearest higher or nearest lower representable value, chosen in
     an implementation-defined manner. If the value being converted is outside
     the range of values that can be represented, the behavior is undefined.
     Results of some implicit conversions may be represented in greater range
     and precision than that required by the new type (see 6.3.1.8 and
     6.8.6.4).
     }*/
     // fixme all floats same precision
     rule cast(t(S:Set, T':SimpleType), tv(F:Float, t(_, T:SimpleType))) 
          => tv(F, t(S, T'))
          when ((T ==K float) 
                    orBool (T ==K double) 
                    orBool (T ==K long-double))
               andBool 
               ((T' ==K float) 
                    orBool (T' ==K double) 
                    orBool (T' ==K long-double))
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.2}{1}}}{
     The (nonexistent) value of a void expression (an expression that has type
     \cinline{void}) shall not be used in any way, and implicit or explicit
     conversions (except to \cinline{void}) shall not be applied to such an
     expression. If an expression of any other type is evaluated as a void
     expression, its value or designator is discarded. (A void expression is
     evaluated for its side effects.)
     }*/     
     rule cast(t(_, void), _:Value) => skipval
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{1--2}}}{
     A pointer to void may be converted to or from a pointer to any object
     type. A pointer to any object type may be converted to a pointer to void
     and back again; the result shall compare equal to the original pointer.

     For any qualifier $q$, a pointer to a non-$q$-qualified type may be
     converted to a pointer to the $q$-qualified version of the type; the
     values stored in the original and converted pointers shall compare equal.
     }*/


     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{3}}}{
     An integer constant expression with the value 0, or such an expression
     cast to type \cinline{void *}, is called a null pointer constant. If a
     null pointer constant is converted to a pointer type, the resulting
     pointer, called a null pointer, is guaranteed to compare unequal to a
     pointer to any object or function.
     }*/
     rule cast(t(S:Set, pointerType(T':Type)), tv(N:CValue, T:Type)) 
          => tv(NullPointer, t(S, pointerType(T')))
          when hasIntegerType(T)
               andBool N ==K NullPointerConstant
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{4}}}{
     Conversion of a null pointer to another pointer type yields a null pointer
     of that type. Any two null pointers shall compare equal.
     }*/
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{5}}}{
     An integer may be converted to any pointer type. Except as previously
     specified, the result is implementation-defined, might not be correctly
     aligned, might not point to an entity of the referenced type, and might be
     a trap representation.
     }*/
     // choice implementation defined behavior
     rule cast(t(S:Set, pointerType(T':Type)), tv(N:CValue, T:Type)) 
          => tv(N, t(S, pointerType(T')))
          when hasIntegerType(T)
               andBool N =/=K NullPointerConstant
     rule cast(t(S:Set, pointerType(T':Type)), tv(N:SymLoc, T:Type)) 
          => tv(N, t(S, pointerType(T')))
          when hasIntegerType(T)
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{6}}}{
     Any pointer type may be converted to an integer type. Except as previously
     specified, the result is implementation-defined. If the result cannot be
     represented in the integer type, the behavior is undefined. The result
     need not be in the range of values of any integer type.
     }*/
     // fixme needs to check size
     rule cast(T:Type, tv(N:Int, t(_, pointerType(_))))
          => tv(N, T)
          when hasIntegerType(T)
               andBool notBool isBoolType (T)
     rule cast(T:Type, tv(N:SymLoc, t(_, pointerType(_))))
          => tv(N, T)
          when hasIntegerType(T)
               andBool notBool isBoolType (T)
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{7}}}{
     A pointer to an object type may be converted to a pointer to a different
     object type. If the resulting pointer is not correctly aligned for the
     referenced type, the behavior is undefined. Otherwise, when converted back
     again, the result shall compare equal to the original pointer. When a
     pointer to an object is converted to a pointer to a character type, the
     result points to the lowest addressed byte of the object. Successive
     increments of the result, up to the size of the object, yield pointers to
     the remaining bytes of the object.
     }*/
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{8}}}{
     A pointer to a function of one type may be converted to a pointer to a
     function of another type and back again; the result shall compare equal to
     the original pointer. If a converted pointer is used to call a function
     whose type is not compatible with the referenced type, the behavior is
     undefined.
     }*/
     // fixme
     // possibly not true with other endiannesses
     // choice
     // needs to handle alignment
     rule cast(t(S:Set, pointerType(T:Type)), 
               tv(Loc:SymLoc, t(_, pointerType(_)))) 
          => tv(Loc, t(S, pointerType(T)))
endmodule

