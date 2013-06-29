module C-EXPRESSION-REFERENCE
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-SYNTAX

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
     rule [ref]:
          &(lval(Loc:SymLoc, T:Type)) => tv(Loc, t(.Set, pointerType(T)))
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.2}{4}}}{
     The unary \cinline{*} operator denotes indirection. If the operand points
     to a function, the result is a function designator; if it points to an
     object, the result is an lvalue designating the object. If the operand has
     type ``pointer to type'', the result has type ``type''. If an invalid
     value has been assigned to the pointer, the behavior of the unary
     \cinline{*} operator is undefined.
     }*/
     rule [deref]:
          *(tv(Loc:SymLoc, t(_, pointerType(t(S:Set, T:K)))))
          => checkDerefLoc(Loc) ~> lv(Loc, t(S, T))
          when notBool T ==K void
          [structural]
endmodule

