module C-CONVERSIONS
     imports C-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-HELPERS
     imports C-COMPAT-SYNTAX
     imports C-CONFIGURATION
     
     //- switch assumes casts can happen anywhere
     rule cast(T:KResult, tv(L:KList, T:KResult))
          => tv(L:KList, T:KResult)
          [structural, anywhere]
          
     rule cast(t(S:Set, T:K), tv(L:KList, t(_, T:K)))
          => tv(L:KList, t(S:Set, T:K))
          [structural, anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.2}{1}}}{
     When any scalar value is converted to \cinline{_Bool}, the result is 0 if
     the value compares equal to 0; otherwise, the result is 1.
     }*/
     // cleanme only need one rule
     // fixme worried about qualifiers
     rule [cast-integer-to-bool]:
          cast(t(S:Set, bool), tv(I:Int, T:KResult))
          => #if I:Int ==Int 0 
               #then tv(0, t(S:Set, bool)) 
               #else tv(1, t(S:Set, bool)) #fi
          when hasIntegerType(T:KResult)
          [structural, anywhere]
     rule [cast-non-integer-to-bool]:
          cast(t(S:Set, bool), tv(L:KList, T:KResult)) 
          => cast(t(S:Set, bool), tv(0, t(.Set, int)) != tv(L:KList, T:KResult))
          when notBool hasIntegerType(T:KResult)
          [structural, anywhere]
     
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{1}}}{
     When a value with integer type is converted to another integer type other
     than \cinline{_Bool}, if the value can be represented by the new type, it
     is unchanged.
     }*/
     rule [cast-integer-no-value-change]:
          cast(T:KResult, tv(I:Int, T':KResult)) => tv(I:Int, T:KResult)
          when (min(T:KResult) <=Int I:Int) 
               andBool (max(T:KResult) >=Int I:Int)
               andBool hasIntegerType(T':KResult)
               andBool hasIntegerType(T:KResult)
               andBool notBool isBoolType (T:KResult)
          [structural, anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{2}}}{
     Otherwise, if the new type is unsigned, the value is converted by
     repeatedly adding or subtracting one more than the maximum value that can
     be represented in the new type until the value is in the range of the new
     type.
     }*/
     rule [cast-ubitfield-of-small]:
          cast(T:KResult, tv(I:Int, T':KResult)) 
          => cast(T:KResult, tv(I:Int +Int max(T:KResult) +Int 1, T':KResult))
          when isBitfieldType(T:KResult)
               andBool (I:Int <Int min(T:KResult))
               andBool hasIntegerType(T':KResult)
               andBool hasUnsignedIntegerType(innerType(T:KResult))
          [structural, anywhere]
     rule [cast-uchar-of-small]:
          cast(t(S:Set, unsigned-char), tv(I:Int, T':KResult)) 
          => cast(t(S:Set, unsigned-char),
               tv(I:Int +Int max(t(S:Set, unsigned-char)) +Int 1, T':KResult))
          when (I:Int <Int min(t(S:Set, unsigned-char)))
               andBool hasIntegerType(T':KResult)
          [structural, anywhere]
     rule [cast-usint-of-small]:
          cast(t(S:Set, unsigned-short-int), tv(I:Int, T':KResult)) 
          => cast(t(S:Set, unsigned-short-int),
               tv(I +Int max(t(S, unsigned-short-int)) +Int 1, T'))
          when (I:Int <Int min(t(S:Set, unsigned-short-int)))
               andBool hasIntegerType(T':KResult)
          [structural, anywhere]
     rule [cast-uint-of-small]:
          cast(t(S:Set, unsigned-int), tv(I:Int, T':KResult)) 
          => cast(t(S:Set, unsigned-int),
               tv(I:Int +Int max(t(S:Set, unsigned-int)) +Int 1, T'))
          when (I:Int <Int min(t(S:Set, unsigned-int)))
               andBool hasIntegerType(T':KResult)
          [structural, anywhere]
     rule [cast-ulong-of-small]:
          cast(t(S:Set, unsigned-long-int), tv(I:Int, T':KResult)) 
          => cast(t(S:Set, unsigned-long-int),
               tv(I:Int +Int max(t(S:Set, unsigned-long-int)) +Int 1, T'))
          when (I:Int <Int min(t(S:Set, unsigned-long-int)))
               andBool hasIntegerType(T':KResult)
          [structural, anywhere]
     rule [cast-ullong-of-small]:
          cast(t(S:Set, unsigned-long-long-int), tv(I:Int, T':KResult)) 
          => cast(t(S:Set, unsigned-long-long-int),
               tv(I:Int +Int max(t(S:Set, unsigned-long-long-int)) +Int 1, T'))
          when (I:Int <Int min(t(S:Set, unsigned-long-long-int)))
               andBool hasIntegerType(T':KResult)          
          [structural, anywhere]
     
     rule [cast-ubitfield-of-big]:
          cast(T:KResult, tv(I:Int, T':KResult)) 
          => tv(I:Int %Int (max(T:KResult) +Int 1), T:KResult)
          when isBitfieldType(T:KResult)
               andBool (I:Int >Int max(T:KResult))
               andBool hasIntegerType(T':KResult)
               andBool hasUnsignedIntegerType(innerType(T:KResult))
          [structural, anywhere]
     rule [cast-uchar-of-big]:
          cast(t(S:Set, unsigned-char), tv(I:Int, T':Type)) 
          => tv(I %Int (max(t(S, unsigned-char)) +Int 1), t(S, unsigned-char))
          when (I >Int max(t(S, unsigned-char)))
               andBool hasIntegerType(T')
          [structural, anywhere]
     rule [cast-usint-of-big]:
          cast(t(S:Set, unsigned-short-int), tv(I:Int, T':KResult)) 
          => tv(I:Int %Int (max(t(S:Set, unsigned-short-int)) +Int 1),
               t(S:Set, unsigned-short-int))
          when (I:Int >Int max(t(S:Set, unsigned-short-int)))
               andBool hasIntegerType(T':KResult)
          [structural, anywhere]
     rule [cast-uint-of-big]:
          cast(t(S:Set, unsigned-int), tv(I:Int, T':KResult)) 
          => tv(I:Int %Int (max(t(S:Set, unsigned-int)) +Int 1),
               t(S:Set, unsigned-int))
          when (I:Int >Int max(t(S:Set, unsigned-int)))
               andBool hasIntegerType(T':KResult)
          [structural, anywhere]
     rule [cast-ulong-of-big]:
          cast(t(S:Set, unsigned-long-int), tv(I:Int, T':KResult)) 
          => tv(I:Int %Int (max(t(S:Set, unsigned-long-int)) +Int 1),
               t(S:Set, unsigned-long-int))
          when (I:Int >Int max(t(S:Set, unsigned-long-int)))
               andBool hasIntegerType(T':KResult)
          [structural, anywhere]
     rule [cast-ullong-of-big]:
          cast(t(S:Set, unsigned-long-long-int), tv(I:Int, T':KResult)) 
          => tv(I:Int %Int (max(t(S:Set, unsigned-long-long-int)) +Int 1),
               t(S:Set, unsigned-long-long-int))
          when (I:Int >Int max(t(S:Set, unsigned-long-long-int)))
               andBool hasIntegerType(T':KResult)
          [structural, anywhere]

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{3}}}{
     Otherwise, the new type is signed and the value cannot be represented in
     it; either the result is implementation-defined or an
     implementation-defined signal is raised.
     }*/
     // choice
     rule [cast-sbitfield-of-huge]:
          cast(T:KResult, tv(I:Int, T':KResult)) 
          => cast(T, tv(I %Int (2 ^Int absInt(numBits(T))), T')) 
          when isBitfieldType(T)
               andBool (absInt(I) >Int (2 ^Int absInt(numBits(T))))
               andBool hasIntegerType(T')
               andBool hasSignedIntegerType(innerType(T))
          [structural, anywhere]
     rule [cast-schar-of-huge]:
          cast(t(S:Set, signed-char), tv(I:Int, T':KResult)) 
          => cast(t(S:Set, signed-char),
               tv(I %Int (2 ^Int absInt(numBits(t(S, signed-char)))), T')) 
          when (absInt(I) >Int (2 ^Int absInt(numBits(t(S, signed-char)))))
               andBool hasIntegerType(T')
          [structural, anywhere]
     rule [cast-sint-of-huge]:
          cast(t(S:Set, short-int), tv(I:Int, T':KResult)) 
          => cast(t(S, short-int), 
               tv(I %Int (2 ^Int absInt(numBits(t(S, short-int)))), T')) 
          when (absInt(I) >Int (2 ^Int absInt(numBits(t(S, short-int)))))
               andBool hasIntegerType(T')
          [structural, anywhere]
     rule [cast-int-of-huge]:
          cast(t(S:Set, int), tv(I:Int, T':KResult)) 
          => cast(t(S, int), 
               tv(I %Int (2 ^Int absInt(numBits(t(S, int)))), T')) 
          when (absInt(I) >Int (2 ^Int absInt(numBits(t(S, int)))))
               andBool hasIntegerType(T')
          [structural, anywhere]
     rule [cast-long-of-huge]:
          cast(t(S:Set, long-int), tv(I:Int, T':KResult)) 
          => cast(t(S:Set, long-int), 
               tv(I %Int (2 ^Int absInt(numBits(t(S, long-int)))), T')) 
          when (absInt(I:Int) >Int (2 ^Int absInt(numBits(t(S:Set, long-int)))))
               andBool hasIntegerType(T':KResult)
          [structural, anywhere]
     rule [cast-llong-of-huge]:
          cast(t(S:Set, long-long-int), tv(I:Int, T':KResult))
          => cast(t(S:Set, long-long-int), 
               tv(I %Int (2 ^Int absInt(numBits(t(S, long-long-int)))), T')) 
          when (absInt(I) >Int (2 ^Int absInt(numBits(t(S, long-long-int)))))
               andBool hasIntegerType(T')
          [structural, anywhere]
          
     rule [cast-signed-of-small]:
          cast(T:Type, tv(I:Int, T':Type))
          => tv(I +Int (2 ^Int absInt(numBits(T))), T)
          when (I <Int min(T))
               andBool (absInt(I) <=Int (2 ^Int absInt(numBits(T))))
               andBool hasSignedIntegerType(T)
               andBool hasIntegerType(T')
               andBool notBool isBoolType (T)
          [structural, anywhere] 
     rule [cast-signed-of-big]:
          cast(T:Type, tv(I:Int, T':Type)) 
          => tv(I -Int (2 ^Int absInt(numBits(T))), T)
          when (I >Int max(T))
               andBool (absInt(I) <=Int (2 ^Int absInt(numBits(T))))
               andBool hasSignedIntegerType(T)
               andBool hasIntegerType(T')
               andBool notBool isBoolType (T)
          [structural, anywhere]

     // this is starting to get into sketchy land
     rule [cast-unknown-integer]:
          cast(T:Type, tv(piece(unknown(Len:Int), Len:Int), T':Type)) 
          => tv(piece(unknown(value(bitSizeofType(T))),
               value(bitSizeofType(T))), T)
          when hasIntegerType(T)
               andBool hasIntegerType(T')
          [structural, anywhere]
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.4}{1}}}{
     When a finite value of real floating type is converted to an integer type
     other than \cinline{_Bool}, the fractional part is discarded (i.e., the
     value is truncated toward zero). If the value of the integral part cannot
     be represented by the integer type, the behavior is undefined.
     }*/
     // fixme
     rule cast(T:KResult, tv(V:Float, t(S:Set, double))) 
          => cast(T:KResult, tv(Float2Int(V:Float), t(S:Set, long-long-int)))
          when hasIntegerType(T:KResult)
               andBool notBool isBoolType (T:KResult)
          [structural, anywhere]
     rule cast(T:KResult, tv(V:Float, t(S:Set, float))) 
          => cast(T:KResult, tv(Float2Int(V:Float), t(S:Set, long-long-int)))
          when hasIntegerType(T:KResult)
               andBool notBool isBoolType (T:KResult)
          [structural, anywhere]
     rule cast(T:KResult, tv(V:Float, t(S:Set, long-double))) 
          => cast(T:KResult, tv(Float2Int(V:Float), t(S:Set, long-long-int)))
          when hasIntegerType(T:KResult)
               andBool notBool isBoolType (T:KResult)
          [structural, anywhere]
     
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
     rule [cast-int-to-float]:
          cast(t(S:Set, float), tv(I:Int, T:KResult)) 
          => tv(Int2Float(I:Int), t(S:Set, float))
          when hasIntegerType(T:KResult)
          [structural, anywhere]
     rule [cast-int-to-double]:
          cast(t(S:Set, double), tv(I:Int, T:KResult)) 
          => tv(Int2Float(I:Int), t(S:Set, double))
          when hasIntegerType(T:KResult)
          [structural, anywhere]
     rule [cast-int-to-long-double]:
          cast(t(S:Set, long-double), tv(I:Int, T:KResult)) 
          => tv(Int2Float(I:Int), t(S:Set, long-double))
          when hasIntegerType(T:KResult)
          [structural, anywhere]
     
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
     rule cast(t(S:Set, T':K), tv(F:Float, t(_, T:K))) 
          => tv(F:Float, t(S:Set, T':K))
          when (T:K ==K float orBool T:K ==K double orBool T:K ==K long-double)
               andBool ((T':K ==K float) orBool (T':K ==K double)
                    orBool (T':K ==K long-double))
          [structural, anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.2}{1}}}{
     The (nonexistent) value of a void expression (an expression that has type
     \cinline{void}) shall not be used in any way, and implicit or explicit
     conversions (except to \cinline{void}) shall not be applied to such an
     expression. If an expression of any other type is evaluated as a void
     expression, its value or designator is discarded. (A void expression is
     evaluated for its side effects.)
     }*/     
     rule cast(t(_, void), _:KResult) => skipval
          [structural, anywhere]
     
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
     rule cast(t(S:Set, pointerType(T:KResult)), tv(N:Int, T':KResult)) 
          => tv(NullPointer, t(S:Set, pointerType(T:KResult)))
          when hasIntegerType(T':KResult)
               andBool N:Int ==K NullPointerConstant
          [structural, anywhere]
          
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
     rule cast(t(S:Set, pointerType(T:KResult)), tv(N:Int, T':KResult)) 
          => tv(N, t(S, pointerType(T)))
          when hasIntegerType(T')
               andBool N =/=K NullPointerConstant
          [structural, anywhere]
     rule cast(t(S:Set, pointerType(T:KResult)), tv(N:SymLoc, T':KResult)) 
          => tv(N, t(S, pointerType(T)))
          when hasIntegerType(T')
          [structural, anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{6}}}{
     Any pointer type may be converted to an integer type. Except as previously
     specified, the result is implementation-defined. If the result cannot be
     represented in the integer type, the behavior is undefined. The result
     need not be in the range of values of any integer type.
     }*/
     // fixme needs to check size
     rule cast(T:KResult, tv(N:Int, t(_, pointerType(_))))
          => tv(N, T)
          when hasIntegerType(T)
               andBool notBool isBoolType (T)
          [structural, anywhere]
     rule cast(T:KResult, tv(N:SymLoc, t(_, pointerType(_))))
          => tv(N, T)
          when hasIntegerType(T)
               andBool notBool isBoolType (T)
          [structural, anywhere]
          
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
     rule cast(t(S:Set, pointerType(T:KResult)), 
               tv(Loc:SymLoc, t(_, pointerType(_)))) 
          => tv(Loc:SymLoc, t(S:Set, pointerType(T:KResult)))
          [structural, anywhere]
endmodule

