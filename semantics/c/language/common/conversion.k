module C-CONVERSION-SYNTAX
     imports BASIC-K
     imports FLOAT
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS

     // interpret the result of arithmetic as in 6.5.4
     syntax KItem ::= intArithInterpret(UType, Int)
     syntax KItem ::= intArithInterpret(UType, Int, overflowLint: Bool)
     syntax KItem ::= floatArithInterpret(UType, Float)
     // as described in 6.3 // totype, fromvalue
     // change it to function in order
     // to solve anywhere rule
     syntax Cast ::= cast(UType, K)
     syntax Cast ::= cast(UType, K, explicit: Bool)
endmodule

module C-CONVERSION
     imports C-CONFIGURATION
     imports C-CONVERSION-SYNTAX
     imports INT
     imports FLOAT
     imports SYMLOC-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-CHECK-USE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIST
     imports SET

     rule intArithInterpret(T:UType, N:Int) => intArithInterpret(T, N, true)
     rule intArithInterpret(integerUType #as T::UType, N::Int, _) => tv(N, T)
          requires (min(T) <=Int N) andBool (max(T) >=Int N)
     rule intArithInterpret(unsignedIntegerUType #as T::UType, N::Int, OverflowLint:Bool) => tv(N modInt (max(T) +Int 1), T)
          requires ((N >Int max(T)) orBool (N <Int min(T))) andBool (notBool hasLint orBool notBool OverflowLint)
     // unsigned arithmetic isn't supposed to overflow
     rule (.K => UNDEF("CCV1", "Signed integer overflow."))
          ~> intArithInterpret(signedIntegerUType #as T::UType, I::Int, _)
          requires notBool ((min(T) <=Int I) andBool (max(T) >=Int I))
          [structural]

     rule floatArithInterpret(ut(... st: _:SimpleFloatType) #as T::UType, F::Float) => tv(roundCFloat(T, F), T)
          requires fmin(T) <=Float F andBool fmax(T) >=Float F
     rule (.K => UNDEF("CCV12", "Floating-point overflow."))
          ~> floatArithInterpret(ut(... st: _:SimpleFloatType) #as T::UType, F::Float)
          requires notBool (fmin(T) <=Float F andBool fmax(T) >=Float F)

     rule cast(T::UType, K::K) => cast(T, K, false)
     context cast(_, (HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     rule cast(T'::UType, tv(V:CValue, T::UType), _) => tv(V, castTypes(T', T))
          requires T' ==Type T andBool notBool isPointerUType(T')

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.2}{1}}}{
     When any scalar value is converted to \cinline{_Bool}, the result is 0 if
     the value compares equal to 0; otherwise, the result is 1.
     }*/
     rule cast(ut(Mods::Set, bool), tv(I:Int, integerUType #as T::UType), _)
          => #if I ==Int 0
               #then tv(0, castTypes(ut(Mods, bool), T))
               #else tv(1, castTypes(ut(Mods, bool), T)) #fi

     rule cast(ut(Mods::Set, bool), tv(F:Float, ut(... st: _:SimpleFloatType) #as T::UType), _)
          => #if F ==Float zeroCFloat(T)
               #then tv(0, castTypes(ut(Mods, bool), T))
               #else tv(1, castTypes(ut(Mods, bool), T)) #fi

     rule cast(ut(Mods::Set, bool), tv(V:SymLoc, ut(... st: pointerType(_)) #as T::UType), _)
          => #if V ==K NullPointer
               #then tv(0, castTypes(ut(Mods, bool), T))
               #else tv(1, castTypes(ut(Mods, bool), T)) #fi

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{1}}}{
     When a value with integer type is converted to another integer type other
     than \cinline{_Bool}, if the value can be represented by the new type, it
     is unchanged.
     }*/
     rule cast(integerUType #as T'::UType, tv(V:Int, integerUType #as T::UType), _)
          => tv(V, castTypes(T', T))
          requires T' =/=Type T andBool notBool isBoolUType(T') andBool intInRange(V, T')

     rule cast(integerUType #as T'::UType, tv(encodedPtr(L:SymLoc, N::Int, M::Int), integerUType #as T::UType), _)
          => tv(encodedPtr(L, N, M), T')
          requires notBool isBoolUType(T')
               andBool M -Int N <=Int bitSizeofType(T')

     rule cast(integerUType #as T'::UType, tv(encodedValue(V::EncodableValue, N::Int, M::Int), integerUType), _)
          => tv(encodedValue(V, N, M), T')
          requires notBool isBoolUType(T')
               andBool M -Int N <=Int bitSizeofType(T')

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{2}}}{
     Otherwise, if the new type is unsigned, the value is converted by
     repeatedly adding or subtracting one more than the maximum value that can
     be represented in the new type until the value is in the range of the new
     type.
     }*/
     rule cast(unsignedIntegerUType #as T'::UType, tv(I:Int, integerUType #as T::UType), _)
          => tv(I modInt (max(T') +Int 1), castTypes(T', T))
          requires (I <Int min(T')) andBool notBool hasLint

     rule cast(unsignedIntegerUType #as T'::UType, tv(I:Int, integerUType #as T::UType), _)
          => tv(I %Int (max(T') +Int 1), castTypes(T', T))
          requires (I >Int max(T')) andBool notBool hasLint

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{3}}}{
     Otherwise, the new type is signed and the value cannot be represented in
     it; either the result is implementation-defined or an
     implementation-defined signal is raised.
     }*/
     // choice
     // rule cast(T':BitfieldUType, tv(I:Int, integerUType #as T::UType))
     //      => cast(T', tv(I %Int (2 ^Int absInt(bitSizeofType(T'))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(T'))))
     //           andBool isSignedIntegerType(innerType(T'))
     //      [structural]
     // rule cast(ut(Mods:Set, signed-char), tv(I:Int, integerUType #as T::UType))
     //      => cast(ut(Mods, signed-char),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(ut(Mods, signed-char)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(ut(Mods, signed-char)))))
     //      [structural]
     // rule cast(ut(Mods:Set, short-int), tv(I:Int, integerUType #as T::UType))
     //      => cast(ut(Mods, short-int),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(ut(Mods, short-int)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(ut(Mods, short-int)))))
     //      [structural]
     // rule cast(ut(Mods:Set, int), tv(I:Int, integerUType #as T::UType))
     //      => cast(ut(Mods, int),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(ut(Mods, int)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(ut(Mods, int)))))
     //      [structural]
     // rule cast(ut(Mods:Set, long-int), tv(I:Int, integerType #as T::Type))
     //      => cast(ut(Mods, long-int),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(ut(Mods, long-int)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(ut(Mods, long-int)))))
     //      [structural]
     // rule cast(ut(Mods:Set, long-long-int), tv(I:Int, integerUType #as T::UType))
     //      => cast(ut(Mods, long-long-int),
     //           tv(I %Int (2 ^Int absInt(bitSizeofType(ut(Mods, long-long-int)))), T))
     //      requires (absInt(I) >Int (2 ^Int absInt(bitSizeofType(ut(Mods, long-long-int)))))
     //      [structural]
     // rule cast(signedIntegerUType #as T'::UType, tv(I:Int, integerUType #as T::UType))
     //      => tv(I +Int (2 ^Int absInt(bitSizeofType(T'))), T')
     //      requires (I <Int min(T'))
     //           andBool (absInt(I) <=Int (2 ^Int absInt(bitSizeofType(T'))))
     //           andBool notBool isBoolUType (T')
     //      [structural]
     // rule cast(signedIntegerUType #as T'::UType, tv(I:Int, integerUType #as T::UType))
     //      => tv(I -Int (2 ^Int absInt(bitSizeofType(T'))), T')
     //      requires (I >Int max(T'))
     //           andBool (absInt(I) <=Int (2 ^Int absInt(bitSizeofType(T'))))
     //           andBool notBool isBoolUType (T')
     //      [structural]

     rule (.K => IMPL("CCV2",
               "Conversion to signed integer outside the range that can be represented."))
          ~> cast(signedIntegerUType #as T'::UType, tv(I:Int, integerUType), false)
          requires notBool intInRange(I, T')
          [structural]

     rule (.K => IMPL("CCV2-E",
               "Explicit conversion to signed integer outside the range that can be represented."))
          ~> cast(signedIntegerUType #as T'::UType, tv(I:Int, integerUType), true)
          requires notBool intInRange(I, T')
          [structural]

     rule cast(T'::UType, tv(unknown(I:Int), T::UType), E::Bool)
          => makeUnknown(cast(T', tv(I, T), E))
          requires notBool isPointerUType(T')

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.4}{1}}}{
     When a finite value of real floating type is converted to an integer type
     other than \cinline{_Bool}, the fractional part is discarded (i.e., the
     value is truncated toward zero). If the value of the integral part cannot
     be represented by the integer type, the behavior is undefined.
     }*/
     rule cast(integerUType #as T'::UType, tv(V:Float, ut(... st: _:SimpleFloatType) #as T::UType), _)
          => tv(Float2Int(V), castTypes(T', T))
          requires intInRange(Float2Int(V), T')
               andBool notBool isBoolUType (T')

     rule (.K => UNDEF("CCV3",
               "Conversion to integer from float outside the range that can be represented."))
          ~> cast(integerUType #as T'::UType, tv(V:Float, ut(... st: _:SimpleFloatType)), _)
          requires notBool intInRange(Float2Int(V), T')
          [structural]

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
     rule cast(ut(... st: _:SimpleFloatType) #as T'::UType, tv(V:Int, integerUType #as T::UType), _)
          => tv(Int2Float(V, typePrecision(T'), typeExponent(T')), castTypes(T', T))
          requires floatInRange(Int2Float(V, maxFloatPrecision, maxFloatExponent), T')

     //TODO(traiansf): Shouldn't here be an undef rule for too large integers, too?

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
     rule cast(ut(... st: _:SimpleFloatType) #as T'::UType, tv(V:Float, ut(... st: _:SimpleFloatType) #as T::UType), _)
          => tv(roundCFloat(T', V), castTypes(T', T))
          requires T' =/=Type T andBool floatInRange(V, T')

     rule (.K => UNDEF("CCV4",
               "Floating-point value outside the range of values that can be represented after conversion."))
          ~> cast(ut(... st: _:SimpleFloatType) #as T'::UType, tv(V:Float, ut(... st: _:SimpleFloatType)), _)
          requires notBool floatInRange(V, T')
          [structural]


     /*@ \fromStandard{\source[n1570]{\para{6.3.2.2}{1}}}{
     The (nonexistent) value of a void expression (an expression that has type
     \cinline{void}) shall not be used in any way, and implicit or explicit
     conversions (except to \cinline{void}) shall not be applied to such an
     expression. If an expression of any other type is evaluated as a void
     expression, its value or designator is discarded. (A void expression is
     evaluated for its side effects.)
     }*/
     rule cast(ut(_, void), V:RValue, _) => voidVal::RValue
          requires notBool isHold(V)

     rule (.K => UNDEF("CCV5", "Casting empty value to type other than void."))
          ~> cast(ut(_, T::SimpleUType), emptyValue, _)
          requires T =/=K void
          [structural]
     rule (.K => UNDEF("CCV6", "Casting void type to non-void type."))
          ~> cast(ut(_, T::SimpleUType), voidVal::RValue, _)
          requires T =/=K void
          [structural]

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
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{4}}}{
     Conversion of a null pointer to another pointer type yields a null pointer
     of that type. Any two null pointers shall compare equal.
     }*/
     rule cast(ut(... st: pointerType(_)) #as T'::UType, V:RValue, _) => tv(NullPointer, castTypes(T', utype(V)))
          requires isNullPointerConstant(V)
               orBool (value(V) ==K NullPointer andBool isPointerUType(utype(V)))

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{5}}}{
     An integer may be converted to any pointer type. Except as previously
     specified, the result is implementation-defined, might not be correctly
     aligned, might not point to an entity of the referenced type, and might be
     a trap representation.
     }*/
     rule <k>(.K => IMPL("CCV13", "Conversion from an integer to non-null pointer."))
               ~> cast(ut(... st: pointerType(_)) #as T'::UType, tv(V:CValue, integerUType #as T::UType), _)
          ...</k>
          requires notBool isNullPointerConstant(tv(V, T)) andBool notBool #isHardwareAddress(V)

     rule <k>(.K => IMPL("CCV13-H", "Conversion from an integer to non-null hardware-dependent pointer."))
               ~> cast(ut(... st: pointerType(_)) #as T'::UType, tv(V:CValue, integerUType #as T::UType), _)
          ...</k>
          requires notBool isNullPointerConstant(tv(V, T)) andBool #isHardwareAddress(V)

     // (the address at 'start' is <= 'addr') or (start == 0)
     // (the address at 'end' is >= 'addr') or (end == last-element).
     // If only one of them is equal to 'addr', we change the other one.
     syntax KItem ::= #findHardwareAddress(addr:Int, start:Int, end:Int)  [function, withConfig]
     syntax KItem ::= #findHardwareAddress5(addr:Int, start:Int, middle:Int, middleItem:KItem, end:Int)  [function]

     syntax Bool ::= isInHardwareAddressRange(addr:Int, hwAddr:KItem) [function]

     rule #isHardwareAddress(Addr:Int) => isHardwareAddress(findHardwareAddress(Addr))
     rule #isHardwareAddress(Addr:CValue) => false
          requires notBool isInt(Addr)

     rule [[findHardwareAddress(Addr:Int) =>
               #fun(X:MaybeHardwareAddress => X)(#findHardwareAddress(Addr, 0, size(L) -Int 1))
          ]]
          <hardware-addresses> sortedHardwareAddresses(L:List) </hardware-addresses>
          requires size(L) >Int 0
     rule [[findHardwareAddress(Addr:Int) => noHardwareAddress]]
          <hardware-addresses> sortedHardwareAddresses(L:List) </hardware-addresses>
          requires size(L) ==Int 0

     rule [[ #findHardwareAddress(Addr:Int, Start:Int, Start) => L[Start] ]]
          <hardware-addresses> sortedHardwareAddresses(L:List) </hardware-addresses>
          requires isInHardwareAddressRange(Addr, L[Start])
     rule [[ #findHardwareAddress(Addr:Int, Start:Int, Start) => noHardwareAddress ]]
          <hardware-addresses> sortedHardwareAddresses(L:List) </hardware-addresses>
          requires notBool isInHardwareAddressRange(Addr, L[Start])

     rule [[ #findHardwareAddress(Addr:Int, Start:Int, End:Int) => L[Start] ]]
          <hardware-addresses> sortedHardwareAddresses(L:List) </hardware-addresses>
          requires Start ==Int End -Int 1
               andBool isInHardwareAddressRange(Addr, L[Start])
               andBool notBool isInHardwareAddressRange(Addr, L[End])
     rule [[ #findHardwareAddress(Addr:Int, Start:Int, End:Int) => L[End] ]]
          <hardware-addresses> sortedHardwareAddresses(L:List) </hardware-addresses>
          requires Start ==Int End -Int 1
               andBool notBool isInHardwareAddressRange(Addr, L[Start])
               andBool isInHardwareAddressRange(Addr, L[End])
     rule [[ #findHardwareAddress(Addr:Int, Start:Int, End:Int) => noHardwareAddress ]]
          <hardware-addresses> sortedHardwareAddresses(L:List) </hardware-addresses>
          requires Start ==Int End -Int 1
               andBool notBool isInHardwareAddressRange(Addr, L[Start])
               andBool notBool isInHardwareAddressRange(Addr, L[End])

     rule [[ #findHardwareAddress(Addr:Int, Start:Int, End:Int) =>
               #findHardwareAddress5(Addr, Start, (Start +Int End) /Int 2, L[(Start +Int End) /Int 2], End)
          ]]
          <hardware-addresses> sortedHardwareAddresses(L:List) </hardware-addresses>
          requires Start <Int End -Int 1

     rule #findHardwareAddress5(Addr:Int, Start:Int, Middle:Int, #hardwareAddress(MiddleAddr:Int, _:Int), _End:Int) =>
               #findHardwareAddress(Addr, Start, Middle)
          requires Addr <Int MiddleAddr
     rule #findHardwareAddress5(Addr:Int, _Start:Int, Middle:Int, #hardwareAddress(MiddleAddr:Int, _:Int), End:Int) =>
               #findHardwareAddress(Addr, Middle, End)
          requires Addr >=Int MiddleAddr

     rule isInHardwareAddressRange(Addr:Int, #hardwareAddress(BaseAddr:Int, Size:Int)) =>
          Addr >=Int BaseAddr andBool Addr <Int BaseAddr +Int Size

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{6}}}{
     Any pointer type may be converted to an integer type. Except as previously
     specified, the result is implementation-defined. If the result cannot be
     represented in the integer type, the behavior is undefined. The result
     need not be in the range of values of any integer type.
     }*/
     rule cast(integerUType #as T'::UType, tv(V::CValue, ut(... st: pointerType(_)) #as T::UType), _)
          => implPointerToInt()
          ~> checkUse(tv(cfg:pointerToInt(V, T'), castTypes(T', T)))
          requires notBool isBoolUType(T')
               andBool (byteSizeofType(T) <=Int byteSizeofType(T')
                    orBool (V ==K NullPointer))
               andBool notBool isAbsolute(V)
     rule (.K => UNDEF("CCV7",
               "Conversion from pointer to integer of a value possibly unrepresentable in the integer type."))
          ~> cast(integerUType #as T'::UType, tv(V::CValue, ut(... st: pointerType(_)) #as T::UType), _)
          requires (V =/=K NullPointer)
               andBool notBool isBoolUType(T')
               andBool byteSizeofType(T) >Int byteSizeofType(T')
          [structural]

     rule (.K => IMPL("CCVE4", "Casting a pointer to an integer."))
          ~> implPointerToInt()

     syntax Bool ::= isAbsolute(CValue) [function]
     rule isAbsolute(_) => false [owise]

     rule (.K => CV("CCV9",
          "Conversion from pointer to floating point type or from floating point type to pointer."))
          ~> cast(T'::UType, tv(_, T::UType), _)
          requires (isPointerUType(T) andBool isFloatUType(T'))
               orBool (isFloatUType(T) andBool isPointerUType(T'))

     rule (.K => CV("CCV10",
          "Conversion to or from non-scalar type."))
          ~> cast(T'::UType, tv(_, T::UType), _)
          requires T =/=Type T' andBool notBool isVoidType(type(T')) andBool (
               (notBool isPointerUType(T) andBool notBool isArithmeticType(type(T))) orBool
               (notBool isPointerUType(T') andBool notBool isArithmeticType(type(T'))))

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
     rule cast(ut(Mods'::Set, pointerType(T'::Type)), tv(Loc:SymLoc, ut(Mods::Set, pointerType(T::Type))), _)
          => adjustPointerBounds(tv(Loc, castTypes(ut(Mods', pointerType(T')), ut(Mods, pointerType(T)))))
          requires Loc =/=K NullPointer
               andBool getAlignas(T') <=Int getAlign(Loc)
               andBool notBool (isFunctionType(T) andBool notBool isFunctionType(T'))
               andBool getQualifiers(T) <=Quals getQualifiers(T')
     //TODO(dwightguth): handle pointer alignment
     rule (.K => UNDEF("CCV11",
               "Conversion to a pointer type with a stricter alignment requirement (possibly undefined)."))
          ~> cast(ut(_, pointerType(T'::Type)), tv(Loc:SymLoc, ut(_, pointerType(T::Type))), _)
          requires T' =/=Type T
               andBool notBool (isFunctionType(T) andBool notBool isFunctionType(T'))
               andBool getAlignas(T') >Int getAlign(Loc)
          [structural]
     rule (.K => UNDEF("CCV14",
               "Conversion of a function pointer to object pointer type."))
          ~> cast(ut(_, pointerType(T'::Type)), tv(Loc:SymLoc, ut(_, pointerType(T::Type))), _)
          requires isFunctionType(T) andBool notBool isFunctionType(T')
          [structural]
     rule (.K => lintCastingAwayQuals())
          ~> cast(
               ut(_, pointerType(T'::Type)),
               tv(Loc:SymLoc, ut(_, pointerType(T::Type => addQualifiers(getQualifiers(T'), stripQualifiers(T))))),
               _)
          requires getQualifiers(T) >Quals getQualifiers(T')
          [structural]

     syntax Error ::= lintCastingAwayQuals()
                    | implPointerToInt()
     rule lintCastingAwayQuals() => .K
          requires notBool hasLint
     rule implPointerToInt() => .K
          requires notBool hasLint

     syntax UType ::= castTypes(UType, UType) [function]
     rule castTypes(ut(_, T'::SimpleUType), ut(Mods::Set, _)) => ut(Mods, T')

endmodule
