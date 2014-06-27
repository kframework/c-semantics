module C-COMMON-EXPR-ADDITIVE
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-BITSIZE-SYNTAX

     imports C-ERROR-SYNTAX

     imports C-SETTINGS-SYNTAX

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

     rule tv(Loc:SymLoc, T':Type) + tv(I:Int, T:Type)
          => addToPointer(Loc, T', I)
          when hasIntegerType(T) andBool isPointerType(T')
               andBool simpleType(innerType(T')) =/=K void
          [structural]
     rule tv(I:Int, T:Type) + tv(Loc:SymLoc, T':Type)
          => addToPointer(Loc, T', I)
          when hasIntegerType(T) andBool isPointerType(T')
               andBool simpleType(innerType(T')) =/=K void
          [structural]
     rule tv(Loc:SymLoc, T':Type) - tv(I:Int, T:Type)
          => addToPointer(Loc, T', 0 -Int I)
          when hasIntegerType(T) andBool isPointerType(T')
               andBool simpleType(innerType(T')) =/=K void
          [structural]

     syntax K ::= addToPointer(SymLoc, Type, Int) [function]
     rule addToPointer(Loc:SymLoc, T:Type, I:Int)
          => tv(newFromArray(Loc, T, I)
               +bytes (I *Int byteSizeofType(innerType(T))), T)
          when ifFromArrayInBounds(Loc, T, I)
          [structural]
     rule (. => ERROR("CEA1",
               "A pointer (or array subscript) outside the bounds of an object.",
               (46,, 49)) )
          ~> addToPointer(Loc:SymLoc, T:Type, I:Int)
          when notBool ifFromArrayInBounds(Loc, T, I)
          [structural]

     syntax SymLoc ::= newFromArray(SymLoc, Type, Int) [function]
     rule newFromArray(
               loc(Base:SymBase, Offset:Int, SetItem(
                    fromArray(ArrOffset:Int, Len:Int)) Prov:Set), T:Type, I:Int)
          => loc(Base, Offset, SetItem(
               fromArray(ArrOffset +Int I *Int byteSizeofType(innerType(T)), Len)) Prov)
     rule newFromArray(Loc:SymLoc, _, _) => Loc
          when notBool isFromArray(Loc)

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

     rule tv(L1:SymLoc, t(_, pointerType(T:Type)))
               - tv(L2:SymLoc, t(_, pointerType(T:Type)))
          => computePointerDifference(offset(L1) -Int offset(L2),
               byteSizeofType(T))
          when base(L1) ==K base(L2)
          [structural]
     // ptr1, ptr2, size of ptr type
     syntax K ::= computePointerDifference(Int, Int)
     rule computePointerDifference(Diff:Int, Size:Int)
          => tv(Diff /Int Size, cfg:ptrdiffut)
          when (Diff %Int Size ==Int 0)
               andBool (Diff /Int Size) <=Int max(cfg:ptrdiffut)
               andBool (Diff /Int Size) >=Int min(cfg:ptrdiffut)
          [structural]
     rule (. => UNDEF("CEA2", "Pointer difference outside the range that can be represented.",
               "6.5.6"))
          ~> computePointerDifference(Diff:Int, Size:Int)
          when (Diff /Int Size) >Int max(cfg:ptrdiffut)
               orBool (Diff /Int Size) <Int min(cfg:ptrdiffut)
          [structural]

     rule tv(I1:Int, T:Type) + tv(I2:Int, T':Type)
          => arithInterpret(T, (I1 +Int I2))
          when isPromoted(T) andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T:Type) - tv(I2:Int, T':Type)
          => arithInterpret(T, (I1 -Int I2))
          when isPromoted(T) andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) + tv(F2:Float, T':Type)
          => arithInterpret(T, F1 +Float F2)
          when T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) - tv(F2:Float, T':Type)
          => arithInterpret(T, (F1 -Float F2))
          when T ==Type T'
          [structural]
endmodule
