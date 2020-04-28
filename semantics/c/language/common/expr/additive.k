module C-COMMON-EXPR-ADDITIVE
     imports BASIC-K
     imports BOOL
     imports FLOAT
     imports INT
     imports K-REFLECTION
     imports SET
     imports STRING-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-CHECK-USE-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.6}{2}}}{
     For addition, either both operands shall have arithmetic type, or one
     operand shall be a pointer to a complete object type and the other shall
     have integer type.
     }

     \fromStandard{\source[n1570]{\para{6.5.6}{3}}}{
     For subtraction, one of the following shall hold:
     \begin{itemize}
     \item both operands have arithmetic type;

     \item both operands are pointers to qualified or unqualified versions of
     compatible complete object types; or

     \item the left operand is a pointer to a complete object type and the
     right operand has integer type.

     \end{itemize}
     (Decrementing is equivalent to subtracting 1.)
     }

     \fromStandard{\source[n1570]{\para{6.5.6}{4}}}{
     If both operands have arithmetic type, the usual arithmetic conversions
     are performed on them.
     }

     \fromStandard{\source[n1570]{\para{6.5.6}{5}}}{
     The result of the binary \cinline{+} operator is the sum of the operands.
     }

     \fromStandard{\source[n1570]{\para{6.5.6}{6}}}{
     The result of the binary \cinline{-} operator is the difference resulting
     from the subtraction of the second operand from the first.
     }

     \fromStandard{\source[n1570]{\para{6.5.6}{7}}}{
     For the purposes of these operators, a pointer to an object that is not an
     element of an array behaves the same as a pointer to the first element of
     an array of length one with the type of the object as its element type.
     }

     \fromStandard{\source[n1570]{\para{6.5.6}{8}}}{
     When an expression that has integer type is added to or subtracted from a
     pointer, the result has the type of the pointer operand. If the pointer
     operand points to an element of an array object, and the array is large
     enough, the result points to an element offset from the original element
     such that the difference of the subscripts of the resulting and original
     array elements equals the integer expression. In other words, if the
     expression \cinline{P} points to the $i$-th element of an array object,
     the expressions \cinline{(P)+N} (equivalently, \cinline{N+(P)}) and
     \cinline{(P)-N} (where \cinline{N} has the value $n$) point to,
     respectively, the $i+n$-th and $i-n$-th elements of the array object,
     provided they exist. Moreover, if the expression \cinline{P} points to the
     last element of an array object, the expression \cinline{(P)+1} points one
     past the last element of the array object, and if the expression
     \cinline{Q} points one past the last element of an array object, the
     expression \cinline{(Q)-1} points to the last element of the array object.
     If both the pointer operand and the result point to elements of the same
     array object, or one past the last element of the array object, the
     evaluation shall not produce an overflow; otherwise, the behavior is
     undefined. If the result points one past the last element of the array
     object, it shall not be used as the operand of a unary \cinline{*}
     operator that is evaluated.
     }*/

     rule tv(Loc:SymLoc, ut(... st: pointerType(_)) #as T'::UType) + tv(I:Int, integerUType #as T::UType)
          => addToPointer(Loc, T', I)
          requires notBool isFunctionType(innerType(T'))
               andBool isCompleteType(innerType(T'))
               andBool isPromoted(T)
          [structural]
     rule tv(I:Int, integerUType #as T::UType) + tv(Loc:SymLoc, ut(... st: pointerType(_)) #as T'::UType)
          => addToPointer(Loc, T', I)
          requires notBool isFunctionType(innerType(T'))
               andBool isCompleteType(innerType(T'))
               andBool isPromoted(T)
          [structural]
     rule tv(Loc:SymLoc, ut(... st: pointerType(_)) #as T'::UType) - tv(I:Int, integerUType #as T::UType)
          => addToPointer(Loc, T', 0 -Int I)
          requires notBool isFunctionType(innerType(T'))
               andBool isCompleteType(innerType(T'))
               andBool isPromoted(T)
          [structural]

     rule tv(Loc:SymLoc, T::UType) + tv(I:Int, T'::UType)
          => addToIntptr(Loc, T, I)
          requires isPromoted(T) andBool T ==Type T'
          [structural]
     rule tv(I:Int, T::UType) + tv(Loc:SymLoc, T'::UType)
          => addToIntptr(Loc, T, I)
          requires isPromoted(T) andBool T ==Type T'
          [structural]
     rule tv(Loc:SymLoc, T::UType) - tv(I:Int, T'::UType)
          => addToIntptr(Loc, T, 0 -Int I)
          requires isPromoted(T) andBool T ==Type T'
          [structural]
     rule tv(_:SymLoc, T::UType) + tv((Loc':SymLoc => unknown(maxIntPtrValue(Loc'))), T'::UType)
          requires isPromoted(T) andBool T ==Type T'
          [structural]

     rule (.K => CV("CEA7",
               "Computing pointer addition of a pointer not to a complete object type."))
          ~> L:RValue + R:RValue
          requires isPointerType(type(L)) andBool isIntegerType(type(R))
               andBool (isFunctionType(innerType(type(L)))
                    orBool notBool isCompleteType(innerType(type(L))))
          [structural]
     rule (.K => CV("CEA7",
               "Computing pointer addition of a pointer not to a complete object type."))
          ~> L:RValue + R:RValue
          requires isIntegerType(type(L)) andBool isPointerType(type(R))
               andBool (isFunctionType(innerType(type(R)))
                    orBool notBool isCompleteType(innerType(type(R))))
          [structural]
     rule (.K => CV("CEA8",
               "Computing pointer minus integer of a pointer not to a complete object type."))
          ~> L:RValue - R:RValue
          requires isPointerType(type(L)) andBool isIntegerType(type(R))
               andBool (isFunctionType(innerType(type(L)))
                    orBool notBool isCompleteType(innerType(type(L))))
          [structural]

     rule (.K => CV("CEA3", "Invalid operand types to addition."))
          ~> L:RValue + R:RValue
          requires notBool ((isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
               orBool (isPointerType(type(L)) andBool isIntegerType(type(R)))
               orBool (isPointerType(type(R)) andBool isIntegerType(type(L))))

     rule (.K => CV("CEA4", "Invalid operand types to subtraction."))
          ~> L:RValue - R:RValue
          requires notBool ((isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
               orBool (isPointerType(type(L)) andBool isPointerType(type(R)))
               orBool (isPointerType(type(L)) andBool isIntegerType(type(R))))

     syntax KItem ::= addToPointer(SymLoc, UType, Int)
     rule addToPointer(Loc:SymLoc, T::UType, I:Int)
          => checkUse(tv(newFromArray(Loc, T, I)
               +bytes (I *Int byteSizeofType(innerType(T))), T))
          requires ifFromArrayInBounds(Loc, T, I) ==K true
     rule (.K => UNDEF("CEA1",
               "A pointer (or array subscript) outside the bounds of an object."))
          ~> addToPointer(Loc:SymLoc, T::UType, I:Int)
          requires notBool ifFromArrayInBounds(Loc, T, I)

     syntax KItem ::= addToIntptr(SymLoc, UType, Int)
     rule addToIntptr(Loc:SymLoc, T::UType, I:Int)
          => checkUse(tv(newFromArray(Loc, utype(pointerType(type(char))), I)
               +bytes I, T))
          requires ifFromArrayInBounds(Loc, utype(pointerType(type(char))), I) ==K true
     rule (.K => UNDEF("CEA1",
               "A pointer (or array subscript) outside the bounds of an object."))
          ~> addToIntptr(Loc:SymLoc, T::UType, I:Int)
          requires notBool ifFromArrayInBounds(Loc, utype(pointerType(type(char))), I)

     syntax SymLoc ::= newFromArray(SymLoc, UType, Int) [function]
                     | #newFromArray(SymBase, Int, K, Set, Set, UType, Int) [function]

     rule newFromArray(loc(Base:SymBase, Offset:Int, .Set), _, _)
          => loc(Base, Offset, .Set)
     rule newFromArray(loc(Base:SymBase, Offset:Int, SetItem(K:KItem) Prov:Set), T::UType, I:Int)
          => #newFromArray(Base, Offset, K, Prov, .Set, T, I)
     rule newFromArray(Loc:SymLoc, _, _) => Loc
          requires notBool isFromArray(Loc)

     rule #newFromArray(Base:SymBase, Offset:Int, fromArray(ArrOffset:Int, Len:Int, Eff::EffectiveType),
               .Set, Prov:Set, T::UType, I:Int)
          => loc(Base, Offset, SetItem(
               fromArray(ArrOffset +Int I *Int byteSizeofType(innerType(T)), Len, Eff)) Prov)
     rule #newFromArray(Base:SymBase, Offset:Int, K:KItem, .Set, Prov:Set, _, _)
          => loc(Base, Offset, SetItem(K) Prov)
          requires fromArray(...) :/=K K
     rule #newFromArray(Base:SymBase, Offset:Int, fromArray(ArrOffset:Int, Len:Int, Eff::EffectiveType),
               SetItem(K':KItem) S:Set, Prov:Set, T::UType, I:Int)
          => #newFromArray(Base, Offset, K', S, SetItem(fromArray(ArrOffset +Int
               I *Int byteSizeofType(innerType(T)), Len, Eff)) Prov, T, I)
     rule #newFromArray(Base:SymBase, Offset:Int, K:KItem, SetItem(K':KItem)
               S:Set, Prov:Set, T::UType, I:Int)
          => #newFromArray(Base, Offset, K', S, SetItem(K) Prov, T, I)
          requires fromArray(...) :/=K K

     /*@ \fromStandard{\source[n1570]{\para{6.5.6}{9}}}{
     When two pointers are subtracted, both shall point to elements of the same
     array object, or one past the last element of the array object; the result
     is the difference of the subscripts of the two array elements. The size of
     the result is implementation-defined, and its type (a signed integer type)
     is \cinline{ptrdiff_t} defined in the \cinline{<stddef.h>} header. If the
     result is not representable in an object of that type, the behavior is
     undefined. In other words, if the expressions \cinline{P} and \cinline{Q}
     point to, respectively, the $i$-th and $j$-th elements of an array object,
     the expression \cinline{(P)-(Q)} has the value $i-j$ provided the value
     fits in an object of type \cinline{ptrdiff_t}. Moreover, if the expression
     P points either to an element of an array object or one past the last
     element of an array object, and the expression \cinline{Q} points to the
     last element of the same array object, the expression
     \cinline{((Q)+1)-(P)} has the same value as \cinline{((Q)-(P))+1} and as
     \cinline{-((P)-((Q)+1))}, and has the value zero if the expression
     \cinline{P} points one past the last element of the array object, even
     though the expression \cinline{(Q)+1} does not point to an element of the
     array object.
     }*/

     rule tv(L1:SymLoc, ut(_, pointerType(T::Type)))
               - tv(L2:SymLoc, ut(_, pointerType(T'::Type)))
          => computePointerDifference(offset(L1) -Int offset(L2), byteSizeofType(T), utype(cfg:ptrdiffut), "ptrdiff_t")
          requires sameBase(L1, L2)
               andBool notBool isFunctionType(T) andBool notBool isFunctionType(T')
               andBool isCompleteType(T) andBool isCompleteType(T')
               andBool stripQualifiers(T) ==Type stripQualifiers(T')
          [structural]

     rule tv(L1:SymLoc, integerUType #as T::UType)
               - tv(L2:SymLoc, integerUType #as T'::UType)
          => computePointerDifference(offset(L1) -Int offset(L2), 1, T, #if isSignedIntegerUType(T) #then "intptr_t" #else "uintptr_t" #fi)
          requires sameBase(L1, L2)
               andBool isPromoted(T) andBool T ==Type T'

     rule (.K => CV("CEA9",
               "Computing pointer difference between pointers not to qualified or unqualified versions of compatible complete object types."))
          ~> L:RValue - R:RValue
          requires isPointerUType(utype(L)) andBool isPointerUType(utype(R))
               andBool (isFunctionType(innerType(utype(L))) orBool isFunctionType(innerType(utype(R)))
                    orBool notBool isCompleteType(innerType(utype(L)))
                    orBool notBool isCompleteType(innerType(utype(R)))
                    orBool stripQualifiers(innerType(utype(L)))
                         =/=Type stripQualifiers(innerType(utype(R))))

     rule (.K => UNDEF("CEA5", "Computing pointer difference between two different objects."))
          ~> tv(L1:SymLoc, _) - tv(L2:SymLoc, _)
          requires notBool sameBase(L1, L2)

     // ptr1, ptr2, size of ptr type
     syntax KItem ::= computePointerDifference(Int, Int, UType, String)
     rule computePointerDifference(Diff:Int, Size:Int, T::UType, _)
          => tv(Diff /Int Size, T)
          requires (Diff %Int Size ==Int 0)
               andBool (Diff /Int Size) <=Int max(T)
               andBool (Diff /Int Size) >=Int min(T)
          [structural]
     rule (.K => UNDEF("CEA2", "Pointer difference outside the range that can be represented by object of type " +String S +String "."))
          ~> computePointerDifference(Diff:Int, Size:Int, T::UType, S::String)
          requires (Diff /Int Size) >Int max(T)
               orBool (Diff /Int Size) <Int min(T)
          [structural]

     rule tv(I1:Int, T::UType) + tv(I2:Int, T'::UType)
          => intArithInterpret(T, (I1 +Int I2))
          requires isPromoted(T) andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T::UType) - tv(I2:Int, T'::UType)
          => intArithInterpret(T, (I1 -Int I2))
          requires isPromoted(T) andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) + tv(F2:Float, T'::UType)
          => floatArithInterpret(T, F1 +Float F2)
          requires T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) - tv(F2:Float, T'::UType)
          => floatArithInterpret(T, (F1 -Float F2))
          requires T ==Type T'
          [structural]

     rule tv(V::CValue, T::UType) + tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) + tv(stripUnknown(V'), T'))
          requires isUnknown(V) orBool isUnknown(V')
     rule tv(V::CValue, T::UType) - tv(V'::CValue, T'::UType)
          => makeUnknown(tv(stripUnknown(V), T) - tv(stripUnknown(V'), T'))
          requires isUnknown(V) orBool isUnknown(V')

endmodule
