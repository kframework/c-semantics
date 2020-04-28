module C-COMMON-EXPR-REFERENCE
     imports BOOL
     imports INT
     imports K-EQUAL
     imports SETTINGS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-CHECK-USE-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
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
     rule &(nclv(Loc:SymLoc, T::Type))
          => checkUse(tv(addProv(fromArray(0, byteSizeofType(T), T), Loc),
               utype(pointerType(T))))
          requires notBool isRegisterLoc(Loc)
               andBool notBool isBitfieldType(T)
               andBool isCompleteType(T)
          [structural]
     // fromArray is used to catch dimension and field boundaries in aggregates and unions.
     // since incomplete types cannot be included in aggregates or unions, except the
     // flexible array member, we don't need the fromArray tag in this case and so we
     // drop it since computing the size of an incomplete type is impossible.
     rule &(nclv(Loc:SymLoc, T::Type))
          => checkUse(tv(Loc, utype(pointerType(T))))
          requires notBool isRegisterLoc(Loc)
               andBool notBool isBitfieldType(T)
               andBool notBool isCompleteType(T)
          [structural]
     rule (.K => CV("CER1", "Unary '&' operator applied to non-lvalue."))
          ~> &(_:RValue)
          [structural]
     rule (.K => CV("CER2", "Unary '&' operator applied to a value with register storage class."))
          ~> &(nclv(Loc:SymLoc, _))
          requires isRegisterLoc(Loc)
          [structural]
     rule (.K => CV("CER5", "Unary '&' operator applied to a bit-field."))
          ~> &(nclv(Loc:SymLoc, T::Type))
          requires isBitfieldType(T)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.2}{4}}}{
     The unary \cinline{*} operator denotes indirection. If the operand points
     to a function, the result is a function designator; if it points to an
     object, the result is an lvalue designating the object. If the operand has
     type ``pointer to type'', the result has type ``type''. If an invalid
     value has been assigned to the pointer, the behavior of the unary
     \cinline{*} operator is undefined.
     }*/
     rule *(tv(Loc:SymLoc, ut(... st: pointerType(_)) #as T::UType))
          => checkLoc(Loc)
          ~> lv(stripFromArray(Loc), innerType(T))
          requires notBool isVoidType(innerType(T))
               andBool Loc =/=K NullPointer
               andBool ifFromArrayInBounds(Loc,
                    utype(pointerType(type(char))), 1) ==K true
               andBool (notBool hasLint orBool notBool isNativeLoc(Loc))
          [structural]

     rule (.K => CV("CER6", "Unary '*' operator applied to non-pointer."))
          ~> * R:RValue
          requires notBool isPointerUType(utype(R))

     rule (.K => UNDEF("CER3",
               "Dereferencing a null pointer."))
          ~> *(tv(NullPointer, _))
          [structural]
     rule (.K => UNDEF("CER4",
               "Dereferencing a pointer past the end of an array."))
          ~> *(tv(Loc:SymLoc, _))
          requires ifFromArrayInBounds(Loc,
               utype(pointerType(type(char))), 1) =/=K true
          [structural]

endmodule

