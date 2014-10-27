module C-COMMON-EXPR-REFERENCE-SYNTAX
     syntax K ::= checkRestrict(SymLoc, Type)
endmodule

module C-COMMON-EXPR-REFERENCE
     imports C-COMMON-EXPR-REFERENCE-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.2}{3}}}{
     The unary \cinline{&} operator yields the address of its operand. If the
     operand has type ``type'', the result has type ``pointer to type''.
     \broken{If the operand is the result of a unary \cinline{*} operator,
     neither that operator nor the \cinline{&} operator is evaluated and the
     result is as if both were omitted, except that the constraints on the
     operators still apply and the result is not an lvalue. Similarly, if the
     operand is the result of a \cinline{[]} operator, neither the \cinline{&}
     operator nor the unary \cinline{*} that is implied by the \cinline{[]} is
     evaluated and the result is as if the \cinline{&} operator were removed
     and the \cinline{[]} operator were changed to a \cinline{+} operator.}
     Otherwise, the result is a pointer to the object or function designated by
     its operand.
     }
     */
     rule &(nclv(Loc:SymLoc, T:Type))
          => tv(addProv(align(getAlignas(T)),
               addProv(fromArray(0, byteSizeofType(T)), Loc)),
               t(.Set, pointerType(T)))
          when notBool isRegisterLoc(Loc)
          [structural]
     rule (. => CV("CER1", "Unary '&' operator applied to non-lvalue.", "6.5.3.2:1"))
          ~> &(tv(_, _))
          [structural]
     rule (. => CV("CER2", "Unary '&' operator applied to a value with register storage class.", "6.5.3.2:1"))
          ~> &(nclv(Loc:SymLoc, _))
          when isRegisterLoc(Loc)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.2}{4}}}{
     The unary \cinline{*} operator denotes indirection. If the operand points
     to a function, the result is a function designator; if it points to an
     object, the result is an lvalue designating the object. If the operand has
     type ``pointer to type'', the result has type ``type''. If an invalid
     value has been assigned to the pointer, the behavior of the unary
     \cinline{*} operator is undefined.
     }*/
     rule *(tv(Loc:SymLoc, T:Type))
          => checkRestrict(Loc, T)
          ~> lv(stripAllButFromUnion(Loc), innerType(T))
          when isPointerType(T)
               andBool notBool isVoidType(innerType(T))
               andBool Loc =/=K NullPointer
               andBool ifFromArrayInBounds(Loc,
                    t(.Set, pointerType(t(.Set, char))), 1)
          [structural]
     rule (. => UNDEF("CER3",
               "Dereferencing a null pointer.",
               "6.5.3.2:4"))
          ~> *(tv(Loc:SymLoc, _))
          when Loc ==K NullPointer
          [structural]
     rule (. => UNDEF("CER4",
               "Dereferencing a pointer past the end of an array.",
               "6.5.6:8"))
          ~> *(tv(Loc:SymLoc, _))
          when notBool ifFromArrayInBounds(Loc,
               t(.Set, pointerType(t(.Set, char))), 1)
          [structural]
endmodule

