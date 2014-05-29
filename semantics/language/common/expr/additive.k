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
     
     rule tv(Loc:SymLoc, t(Mods:Set, pointerType(T':Type))) 
               + tv(I:Int, T:Type)
          => addToPointer(Loc, t(Mods, pointerType(T')), I, sizeofType(T'))
          when hasIntegerType(T)
               andBool T' =/=K void
          [structural]
     rule tv(I:Int, T:Type)
               + tv(Loc:SymLoc, t(Mods:Set, pointerType(T':Type)))
          => addToPointer(Loc, t(Mods, pointerType(T')), I, sizeofType(T'))
          when hasIntegerType(T)
               andBool T' =/=K void
          [structural]
     rule tv(Loc:SymLoc, t(Mods:Set, pointerType(T':Type))) 
               - tv(I:Int, T:Type)
          => addToPointer(Loc, t(Mods, pointerType(T')), 0 -Int I, sizeofType(T')) 
          when hasIntegerType(T)
               andBool T' =/=K void
          [structural]
               
     syntax K ::= addToPointer(SymLoc, Type, K, K) [strict(4)]
     rule addToPointer(Loc:SymLoc, T:Type, I:Int, tv(Size:Int, _))
          => tv(Loc +bytes (I *Int Size), newFromArray(T, I))
          when ifFromArrayInBounds(T, I)
          [structural]
     // TODO(chathhorn): the fromArray tag gets lost during e.g. assignment --
     // probably need to tag the memory.
     rule (. => ERROR("00044", "A pointer (or array subscript) outside the bounds of an object.", (46,, 49)) ) ~>
          addToPointer(_, T:Type, I:Int, tv(_, _))
          when notBool ifFromArrayInBounds(T, I)
          [structural]
          
     syntax Type ::= newFromArray(Type, Int) [function]
     rule newFromArray(
               t(SetItem(fromArray(Offset:Int, Len:Int)) Mods:Set,
               pointerType(T:Type)), I:Int) 
          => t(SetItem(fromArray(Offset +Int I, Len)) Mods, pointerType(T))
     rule newFromArray(T:Type, _) => T
          when notBool isFromArray(T)

     syntax Bool ::= ifFromArrayInBounds(K, Int) [function]
     rule ifFromArrayInBounds(
               t(SetItem(fromArray(Offset:Int, Len:Int)) _, 
               pointerType(_)), I:Int)
          => true
          when Offset +Int I <=Int Len
     rule ifFromArrayInBounds(
               t(SetItem(fromArray(Offset:Int, Len:Int)) _,
               pointerType(_)), I:Int)
          => false
          when Offset +Int I >Int Len
     rule ifFromArrayInBounds(T:Type, _) => true
          when notBool isFromArray(T)

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

     // ptr1, ptr2, size of ptr type
     syntax K ::= "computePointerDifference" "(" SymLoc "," SymLoc "," K ")"
          [strict(3)]
     rule tv(L1:SymLoc, t(_, pointerType(T:Type)))
               - tv(L2:SymLoc, t(_, pointerType(T:Type)))
          => computePointerDifference(L1, L2, sizeofType(T))
          [structural]
     rule computePointerDifference(loc(Base:SymBase, Offset1:Int),
               loc(Base:SymBase, Offset2:Int), tv(Size:Int, _))
          => tv((Offset1 -Int Offset2) /Int Size, cfg:ptrdiffut)
          when (Offset1 -Int Offset2) %Int Size ==Int 0
          [structural]
     
     rule tv(I1:Int, T:Type) + tv(I2:Int, T:Type)
          => arithInterpret(T, (I1 +Int I2))
          when isPromoted(T)
          [structural]
     rule tv(I1:Int, T:Type) - tv(I2:Int, T:Type)
          => arithInterpret(T, (I1 -Int I2))
          when isPromoted(T)
          [structural]
     rule tv(F1:Float, T:Type) + tv(F2:Float, T:Type)
          => arithInterpret(T, F1 +Float F2)
          [structural]
     rule tv(F1:Float, T:Type) - tv(F2:Float, T:Type)
          => arithInterpret(T, (F1 -Float F2))
          [structural]
endmodule

