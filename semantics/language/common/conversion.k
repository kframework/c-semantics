module C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX

     // interpret the result of arithmetic as in 6.5.4
     syntax KItem ::= arithInterpret(Type, NumValue) [function]
     syntax KItem ::= arithInterpretHold(Type, NumValue)
     // as described in 6.3 // totype, fromvalue
     // change it to function in order
     // to solve anywhere rule
     syntax KItem ::= cast(Type, RValue) [function]
     //Might not need this if we have anywhere rule
     syntax KItem ::= castHold(Type, RValue)
endmodule

module C-CONVERSION
     imports C-CONVERSION-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports DEBUG-SYNTAX
     imports COMPAT-SYNTAX

     rule arithInterpret(T:IntegerType, N:Int) => tv(N, T)
          requires (min(T) <=Int N)
               andBool (max(T) >=Int N)
     rule arithInterpret(T:Type, unknown) => tv(unknown, T)
     rule arithInterpret(T:Type, trap) => trap(T)
     // fixme
     rule arithInterpret(T:FloatType, F:Float) => tv(F, T)
     // signed arithmetic isn't supposed to overflow
     rule arithInterpret(T:UnsignedIntegerType, N:Int) => tv(N modInt (max(T) +Int 1), T)
          requires (N >Int max(T)) orBool (N <Int min(T))
     rule arithInterpret(T:SignedIntegerType, I:Int) => arithInterpretHold(T, I:Int)
          requires notBool ((min(T) <=Int I) andBool (max(T) >=Int I))

     rule (.K => UNDEF("CCV1", "signed overflow.", "6.5:5, J.2:1 item 36"))
          ~> arithInterpretHold(T:SignedIntegerType, I:Int)
          requires notBool ((min(T) <=Int I) andBool (max(T) >=Int I))
          [structural]
     rule _:ErrorExit ~> arithInterpretHold(T:SignedIntegerType, N:Int) 
          => tv(((N -Int min(T)) modInt (1 <<Int bitSizeofType(T)) +Int min(T)), T)
          requires ((N >Int max(T)) orBool (N <Int min(T))) andBool isErrorRecovery

     rule cast(T':Type, tv(V:CValue, T:Type)) => tv(V, cast(T', T))
          requires stripQualifiers(T) ==Type stripQualifiers(T')
               andBool notBool isPointerType(T')

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.2}{1}}}{
     When any scalar value is converted to \cinline{_Bool}, the result is 0 if
     the value compares equal to 0; otherwise, the result is 1.
     }*/
     rule cast(t(Mods:Set, bool), tv(I:Int, T:IntegerType))
          => #if I ==Int 0
               #then tv(0, cast(t(Mods, bool), T))
               #else tv(1, cast(t(Mods, bool), T)) #fi

     rule cast(t(Mods:Set, bool), tv(F:Float, T:FloatType))
          => #if F ==Float Int2Float(0, 53, 11)
               #then tv(0, cast(t(Mods, bool), T))
               #else tv(1, cast(t(Mods, bool), T)) #fi

     rule cast(t(Mods:Set, bool), tv(V:SymLoc, T:PointerType))
          => #if V ==K NullPointer
               #then tv(0, cast(t(Mods, bool), T))
               #else tv(1, cast(t(Mods, bool), T)) #fi

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{1}}}{
     When a value with integer type is converted to another integer type other
     than \cinline{_Bool}, if the value can be represented by the new type, it
     is unchanged.
     }*/
     rule cast(T':IntegerType, tv(V:Int, T:IntegerType))
          => tv(V, cast(T', T))
          requires notBool isBoolType(T')
               andBool inRange(V, T')

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{2}}}{
     Otherwise, if the new type is unsigned, the value is converted by
     repeatedly adding or subtracting one more than the maximum value that can
     be represented in the new type until the value is in the range of the new
     type.
     }*/
     rule cast(T':BitfieldType, tv(I:Int, T:IntegerType))
          => cast(T', tv(I +Int max(T') +Int 1, T))
          requires (I <Int min(T'))
               andBool isUnsignedIntegerType(innerType(T'))

     rule cast(t(Mods:Set, unsigned-char), tv(I:Int, T:IntegerType))
          => cast(t(Mods, unsigned-char),
               tv(I +Int max(t(Mods, unsigned-char)) +Int 1, T))
          requires (I <Int min(t(Mods, unsigned-char)))

     rule cast(t(Mods:Set, unsigned-short-int), tv(I:Int, T:IntegerType))
          => cast(t(Mods, unsigned-short-int),
               tv(I +Int max(t(Mods, unsigned-short-int)) +Int 1, T))
          requires (I <Int min(t(Mods, unsigned-short-int)))

     rule cast(t(Mods:Set, unsigned-int), tv(I:Int, T:IntegerType))
          => cast(t(Mods, unsigned-int),
               tv(I +Int max(t(Mods, unsigned-int)) +Int 1, T))
          requires (I <Int min(t(Mods, unsigned-int)))

     rule cast(t(Mods:Set, unsigned-long-int), tv(I:Int, T:IntegerType))
          => cast(t(Mods, unsigned-long-int),
               tv(I +Int max(t(Mods, unsigned-long-int)) +Int 1, T))
          requires (I <Int min(t(Mods, unsigned-long-int)))

     rule cast(t(Mods:Set, unsigned-long-long-int), tv(I:Int, T:IntegerType))
          => cast(t(Mods, unsigned-long-long-int),
               tv(I +Int max(t(Mods, unsigned-long-long-int)) +Int 1, T))
          requires (I <Int min(t(Mods, unsigned-long-long-int)))

     rule cast(T':BitfieldType, tv(I:Int, T:IntegerType))
          => tv(I %Int (max(T') +Int 1), cast(T', T))
          requires (I >Int max(T'))
               andBool isUnsignedIntegerType(innerType(T'))

     rule cast(t(Mods:Set, unsigned-char), tv(I:Int, T:IntegerType))
          => tv(I %Int (max(t(Mods, unsigned-char)) +Int 1),
               cast(t(Mods, unsigned-char), T))
          requires (I >Int max(t(Mods, unsigned-char)))

     rule cast(t(Mods:Set, unsigned-short-int), tv(I:Int, T:IntegerType))
          => tv(I %Int (max(t(Mods, unsigned-short-int)) +Int 1),
               cast(t(Mods, unsigned-short-int), T))
          requires (I >Int max(t(Mods, unsigned-short-int)))

     rule cast(t(Mods:Set, unsigned-int), tv(I:Int, T:IntegerType))
          => tv(I %Int (max(t(Mods, unsigned-int)) +Int 1),
               cast(t(Mods, unsigned-int), T))
          requires (I >Int max(t(Mods, unsigned-int)))

     rule cast(t(Mods:Set, unsigned-long-int), tv(I:Int, T:IntegerType))
          => tv(I %Int (max(t(Mods, unsigned-long-int)) +Int 1),
               cast(t(Mods, unsigned-long-int), T))
          requires (I >Int max(t(Mods, unsigned-long-int)))

     rule cast(t(Mods:Set, unsigned-long-long-int), tv(I:Int, T:IntegerType))
          => tv(I %Int (max(t(Mods, unsigned-long-long-int)) +Int 1),
               cast(t(Mods, unsigned-long-long-int), T))
          requires (I >Int max(t(Mods, unsigned-long-long-int)))

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{3}}}{
     Otherwise, the new type is signed and the value cannot be represented in
     it; either the result is implementation-defined or an
     implementation-defined signal is raised.
     }*/
     // choice
     // rule cast(T':BitfieldType, tv(I:Int, T:IntegerType))
     //      => cast(T', tv(I %Int (2 ^Int absInt(bitSizeofType(T'))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(T'))))
     //           andBool isSignedIntegerType(innerType(T'))
     //      [structural]
     // rule cast(t(Mods:Set, signed-char), tv(I:Int, T:IntegerType))
     //      => cast(t(Mods, signed-char),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(t(Mods, signed-char)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(t(Mods, signed-char)))))
     //      [structural]
     // rule cast(t(Mods:Set, short-int), tv(I:Int, T:IntegerType))
     //      => cast(t(Mods, short-int),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(t(Mods, short-int)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(t(Mods, short-int)))))
     //      [structural]
     // rule cast(t(Mods:Set, int), tv(I:Int, T:IntegerType))
     //      => cast(t(Mods, int),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(t(Mods, int)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(t(Mods, int)))))
     //      [structural]
     // rule cast(t(Mods:Set, long-int), tv(I:Int, T:IntegerType))
     //      => cast(t(Mods, long-int),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(t(Mods, long-int)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(t(Mods, long-int)))))
     //      [structural]
     // rule cast(t(Mods:Set, long-long-int), tv(I:Int, T:IntegerType))
     //      => cast(t(Mods, long-long-int),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(t(Mods, long-long-int)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(t(Mods, long-long-int)))))
     //      [structural]
     // rule cast(T':SignedIntegerType, tv(I:Int, T:IntegerType))
     //      => tv(I +Int (2 ^Int absInt(bitSizeofType(T'))), T')
     //      requires (I <Int min(T'))
     //           andBool (absInt(I) <=Int (2 ^Int absInt(bitSizeofType(T'))))
     //           andBool notBool isBoolType (T')
     //      [structural]
     // rule cast(T':SignedIntegerType, tv(I:Int, T:IntegerType))
     //      => tv(I -Int (2 ^Int absInt(bitSizeofType(T'))), T')
     //      requires (I >Int max(T'))
     //           andBool (absInt(I) <=Int (2 ^Int absInt(bitSizeofType(T'))))
     //           andBool notBool isBoolType (T')
     //      [structural]

     rule cast(T':SignedIntegerType, tv(I:Int, T:IntegerType)) => castHold(T', tv(I:Int, T))
          requires notBool inRange(I, T')
     rule _:ErrorExit ~> castHold(T':SignedIntegerType, tv(I:Int, T:IntegerType)) => cast(T', tv(I:Int, T))
          requires inRange(I, T') andBool isErrorRecovery

     rule (.K => IMPL("CCV2",
               "conversion to signed integer outside the range that can be represented.",
               "6.3.1.3:3, J.3.5:1 item 4"))
          ~> castHold(T':SignedIntegerType, tv(I:Int, _:IntegerType))
          requires notBool inRange(I, T')
          [structural]

     rule _:ErrorExit ~> (castHold(T':SignedIntegerType, tv(I:Int, T:IntegerType))
          => castHold(T', tv(I +Int (2 ^Int absInt(bitSizeofType(T'))), T)))
          requires isErrorRecovery
               andBool (I <Int min(T'))
               andBool (absInt(I) <=Int (1 <<Int absInt(bitSizeofType(T'))))
               andBool notBool isBoolType (T')
          [structural]
     rule _:ErrorExit ~> (castHold(T':SignedIntegerType, tv(I:Int, T:IntegerType))
          => castHold(T', tv(I -Int (1 <<Int absInt(bitSizeofType(T'))), T)))
          requires isErrorRecovery
               andBool (I >Int max(T'))
               andBool (absInt(I) <=Int (1 <<Int absInt(bitSizeofType(T'))))
               andBool notBool isBoolType (T')
          [structural]

     // TODO(chathhorn): not sure about this.
     rule cast(T':Type, tv(unknown, T:Type))
          => tv(unknown, cast(T', T))
          requires bitSizeofType(T') >=Int bitSizeofType(T)
     rule cast(T':Type, tv(unknown, T:Type))
          => trap(cast(T', T))
          requires bitSizeofType(T') <Int bitSizeofType(T)

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.4}{1}}}{
     When a finite value of real floating type is converted to an integer type
     other than \cinline{_Bool}, the fractional part is discarded (i.e., the
     value is truncated toward zero). If the value of the integral part cannot
     be represented by the integer type, the behavior is undefined.
     }*/
     rule cast(T':IntegerType, tv(V:Float, T:FloatType)) => tv(Float2Int(V), cast(T', T))
          requires inRange(Float2Int(V), T')
               andBool notBool isBoolType (T')

     rule cast(T':IntegerType, tv(V:Float, T:FloatType)) => castHold(T', tv(V:Float, T))
          requires notBool inRange(Float2Int(V), T')

     rule (.K => UNDEF("CCV3",
               "conversion to integer from float outside the range that can be represented.",
               "6.3.1.4:1, J.2:1 item 17"))
          ~> castHold(T':IntegerType, tv(V:Float, _:FloatType))
          requires notBool inRange(Float2Int(V), T')
          [structural]

     rule _:ErrorExit ~> castHold(T':IntegerType, tv(V:Float, _:FloatType)) 
          => arithInterpret(T', Float2Int(V))
          requires notBool inRange(Float2Int(V), T') andBool isErrorRecovery

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
     rule cast(T':FloatType, tv(V:Int, T:IntegerType))
          => tv(Int2Float(V, 53, 11), cast(T', T))
          requires inRange(Int2Float(V, 53, 11), T')

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
     rule cast(T':FloatType, tv(V:Float, T:FloatType)) => tv(V, cast(T', T))
          requires inRange(V, T')

     rule cast(T':FloatType, tv(V:Float, T:FloatType)) => castHold(T', tv(V:Float, T))
          requires notBool inRange(V, T')

     rule (.K => UNDEF("CCV4",
               "floating-point value outside the range of values that can be represented after conversion.",
               "6.3.1.5:1, J.2:1 item 18"))
          ~> castHold(T':FloatType, tv(V:Float, _:FloatType))
          requires notBool inRange(V, T')
          [structural]

     rule _:ErrorExit ~> castHold(T':FloatType, tv(V:Float, T:FloatType))
          => tv(V, cast(T', T))
          requires notBool inRange(V, T') andBool isErrorRecovery


     /*@ \fromStandard{\source[n1570]{\para{6.3.2.2}{1}}}{
     The (nonexistent) value of a void expression (an expression that has type
     \cinline{void}) shall not be used in any way, and implicit or explicit
     conversions (except to \cinline{void}) shall not be applied to such an
     expression. If an expression of any other type is evaluated as a void
     expression, its value or designator is discarded. (A void expression is
     evaluated for its side effects.)
     }*/
     rule cast(t(_, void), V:RValue) => voidVal
          requires notBool isHold(V)

     rule cast(t(_, T:SimpleType), emptyValue) => castHold(t(.Set, T), emptyValue)
          requires T =/=K void
     rule cast(t(_, T:SimpleType), voidVal) => castHold(t(.Set, T), voidVal)
          requires (T =/=K void)

     rule (.K => UNDEF("CCV5", "casting empty value to type other than void.", "6.3.2.2:1, J.2:1 item 23"))
          ~> castHold(t(_, T:SimpleType), emptyValue)
          requires T =/=K void
          [structural]
     rule (.K => UNDEF("CCV6", "casting void type to non-void type.", "6.3.2.2:1, J.2:1 item 23") )
          ~> castHold(t(_, T:SimpleType), voidVal)
          requires (T =/=K void)
          [structural]

     rule _:ErrorExit ~> castHold(t(S:Set, T:SimpleType), emptyValue) => tv(trap, t(S, T))
          requires T =/=K void andBool isErrorRecovery
     rule _:ErrorExit ~> castHold(t(S:Set, T:SimpleType), voidVal) => tv(trap, t(S, T))
          requires T =/=K void andBool isErrorRecovery

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
     rule cast(T':PointerType, V:RValue) => tv(NullPointer, cast(T', type(V)))
          requires isNullPointerConstant(V)

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{4}}}{
     Conversion of a null pointer to another pointer type yields a null pointer
     of that type. Any two null pointers shall compare equal.
     }*/
     rule cast(T':PointerType, tv(NullPointer, T:PointerType)) => tv(NullPointer, cast(T', T))

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{5}}}{
     An integer may be converted to any pointer type. Except as previously
     specified, the result is implementation-defined, might not be correctly
     aligned, might not point to an entity of the referenced type, and might be
     a trap representation.
     }*/
     rule cast(T':PointerType, tv(V:CValue, T:IntegerType))
          => checkUse(tv(cfg:intToPointer(V, T), cast(T', T)))
          requires (V =/=K 0)

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{6}}}{
     Any pointer type may be converted to an integer type. Except as previously
     specified, the result is implementation-defined. If the result cannot be
     represented in the integer type, the behavior is undefined. The result
     need not be in the range of values of any integer type.
     }*/
     rule cast(T':IntegerType, tv(V:CValue, T:PointerType))
          => checkUse(tv(cfg:pointerToInt(V, T'), cast(T', T)))
          requires notBool isBoolType(T')
               andBool (byteSizeofType(T) <=Int byteSizeofType(T')
                    orBool (V ==K NullPointer))
     rule cast(T':IntegerType, tv(V:CValue, T:PointerType))
          => castHold(T', tv(V:CValue, T))
          requires (V =/=K NullPointer)
               andBool notBool isBoolType(T')
               andBool byteSizeofType(T) >Int byteSizeofType(T')
     rule (.K => UNDEF("CCV7",
               "conversion from pointer to integer of a value possibly unrepresentable in the integer type.",
               "6.3.2.3:6, J.2:1 item 24"))
          ~> castHold(T':IntegerType, tv(V:CValue, T:PointerType))
          requires (V =/=K NullPointer)
               andBool notBool isBoolType(T')
               andBool byteSizeofType(T) >Int byteSizeofType(T')
          [structural]
     rule _:ErrorExit ~> castHold(T':IntegerType, tv(V:CValue, T:PointerType))
          => checkUse(tv(cfg:pointerToInt(V, T'), cast(T', T)))
          requires notBool isBoolType(T')
               andBool (byteSizeofType(T) <=Int byteSizeofType(T')
                    orBool (V ==K NullPointer))
               andBool isErrorRecovery

     rule cast(T':Type, tv(V:CValue, T:Type))
          => castHold(T', tv(V, T))
          requires (isPointerType(T) andBool isFloatType(T'))
               orBool (isFloatType(T) andBool isPointerType(T'))
               orBool (stripQualifiers(T) =/=Type stripQualifiers(T')) andBool
               ((notBool isPointerType(T)
                    andBool notBool isArithmeticType(T)
                    andBool notBool isVoidType(T'))
               orBool (notBool isPointerType(T')
                    andBool notBool isArithmeticType(T')
                    andBool notBool isVoidType(T')))

     rule (.K => CV("CCV9",
          "conversion from pointer to floating point type or from floating point type to pointer.",
          "6.5.4:4"))
          ~> castHold(T':Type, tv(_, T:Type))
          requires (isPointerType(T) andBool isFloatType(T'))
               orBool (isFloatType(T) andBool isPointerType(T'))

     rule (.K => CV("CCV10",
          "conversion to or from non-scalar type.",
          "6.5.4:2"))
          ~> castHold(T':Type, tv(_, T:Type))
          requires notBool isVoidType(T') andBool (
               (notBool isPointerType(T) andBool notBool isArithmeticType(T)) orBool
               (notBool isPointerType(T') andBool notBool isArithmeticType(T')))

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
     rule cast(t(Mods':Set, pointerType(T':Type)),
               tv(Loc:SymLoc, t(Mods:Set, pointerType(T:Type))))
          => tv(Loc, cast(t(Mods', pointerType(T')), t(Mods, pointerType(T))))
          requires Loc ==K NullPointer orElseBool getAlignas(T') <=Int getAlign(Loc)
          orElseBool isFunctionType(T) andBool isFunctionType(T')
     //TODO(dwightguth): handle pointer alignment
     rule cast(t(Mods':Set, pointerType(T':Type)), tv(Loc:SymLoc, t(Mods:Set, pointerType(T:Type))))
          => castHold(t(Mods', pointerType(T':Type)), tv(Loc:SymLoc, t(Mods, pointerType(T))))
          requires Loc =/=K NullPointer andBool getAlignas(T') >Int getAlign(Loc)
     rule (.K => UNDEF("CCV11",
               "conversion to a pointer type with a stricter alignment requirement (possibly undefined).",
               "6.3.2.3:7, J.2:1 item 25"))
          ~> castHold(t(_, pointerType(T':Type)), tv(Loc:SymLoc, t(_, pointerType(_))))
          requires getAlignas(T') >Int getAlign(Loc)
          [structural]
     rule _:ErrorExit ~> castHold(t(Mods':Set, pointerType(T':Type)),
               tv(Loc:SymLoc, t(Mods:Set, pointerType(T:Type))))
          => tv(Loc, cast(t(Mods', pointerType(T')), t(Mods, pointerType(T))))
          requires isErrorRecovery

     syntax Type ::= cast(Type, Type) [function, klabel('castTypes)]

     rule cast(T':Type, T:Type) => T'
          requires notBool hasReadFrom(T)
               andBool notBool fromConstantExpr(T)
     rule cast(T':Type, T:Type)
          => addModifier(getReadFrom(T), stripReadFrom(T'))
          requires hasReadFrom(T)
     rule cast(T':Type, T:Type) => addModifiers(getConstants(T), T')
          requires fromConstantExpr(T)
endmodule

