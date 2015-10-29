module C-COMMON-EXPR-EVAL-SYNTAX
     imports C-SYMLOC-SYNTAX

     syntax KItem ::= instantiate(SymLoc, Type)
     syntax KItem ::= checkUse(K) [strict]
     syntax Type ::= arrayToPtrType(Type) [function]
endmodule

module C-COMMON-EXPR-EVAL
     imports C-COMMON-EXPR-EVAL-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports C-SETTINGS-SYNTAX

     syntax KItem ::= "reval" "(" ")"
     rule reval(HOLE:K) => HOLE ~> reval() [heat]
     rule HOLE:KItem ~> reval() => reval(HOLE) [cool, ndlocal]

     // If the lvalue designates an object of automatic storage duration that
     // could have been declared with the register storage class (never had its
     // address taken), and that object is uninitialized (not declared with an
     // initializer and no assignment to it has been performed prior to use),
     // the behavior is undefined.

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{2}}}{
     Except when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, the unary \cinline{&} operator, the
     \cinline{++} operator, the \cinline{--} operator, or the left operand of
     the \cinline{.} operator or an assignment operator, an lvalue that does
     not have an array type is converted to the value stored in the designated
     object (and is no longer an lvalue); this is called lvalue conversion.  If
     the lvalue has qualified type, the value has the unqualified version of
     the type of the lvalue; additionally, if the lvalue has atomic type, the
     value has the non-atomic version of the type of the lvalue; otherwise, the
     value has the type of the lvalue. \ldots
     }*/

     syntax KItem ::= checkCompleteLValue(Type)
     rule checkCompleteLValue(T:Type) => .K
          requires isCompleteType(T)
     rule (.K => UNDEF("CEE3", "Trying to convert an incomplete lvalue not of array type.", "6.3.2.1:2"))
          ~> checkCompleteLValue(T:Type)
          requires notBool isCompleteType(T)
     rule _:ErrorExit ~> checkCompleteLValue(_) => .K
          requires isErrorRecovery

     // Lvalue conversion.
     rule reval(nclv(Loc::SymLoc, T::Type)
          => checkCompleteLValue(T) ~> checkUse(unqualify(instantiate(Loc, T))))
          requires notBool isArrayOrFunctionType(T)
          [structural]

     rule lv(Loc::SymLoc, T::Type) => nclv(Loc, T)
          [structural]

     syntax KItem ::= unqualify(K) [strict]
     rule unqualify(tv(V::CValue, T::Type)) => tv(V, stripQualifiers(T))
     rule unqualify(te(V:K, T::Type))
          => te(unqualify(V), stripQualifiers(T))
     rule unqualify(trap(T::Type)) => trap(stripQualifiers(T))

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{3}}}{
     Except when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, or the unary \cinline{&} operator, or is a
     string literal used to initialize an array, an expression that has type
     ``array of type'' is converted to an expression with type ``pointer to
     type'' that points to the initial element of the array object and is not
     an lvalue. If the array object has register storage class, the behavior is
     undefined.
     }*/

     rule reval(nclv(Loc::SymLoc, T:ArrayType)
          => checkRegister(Loc)
          ~> checkUse(tv(arrayToPtrLoc(Loc, T), arrayToPtrType(T))))
          [structural]

     rule arrayToPtrType(T:Type)
          => stripQualifiers(t(getModifiers(T), pointerType(innerType(T))))

     syntax SymLoc ::= arrayToPtrLoc(SymLoc, Type) [function]
     rule arrayToPtrLoc(Loc::SymLoc, T::Type)
          => addProv(basedOn(base(Loc), getRestrictBlock(T)),
             addProv(fromArray(0, byteSizeofType(innerType(T)) *Int arrayLength(T)),
             Loc))
          requires isRestrictType(T)
     rule arrayToPtrLoc(Loc::SymLoc, T::Type)
          => addProv(fromArray(0, byteSizeofType(innerType(T)) *Int arrayLength(T)),
             Loc)
          requires notBool isRestrictType(T)

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{4}}}{
     A function designator is an expression that has function type. Except
     when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, or the unary \cinline{&} operator, a function
     designator with type ``function returning T'' is converted to an
     expression that has type ``pointer to a function returning T''.
     }*/

     rule reval(nclv(Loc::SymLoc, T:FunctionType)
               => checkUse(tv(Loc, t(.Set, pointerType(T)))))
          [structural]

     rule reval(trap(T:Type)
               => UNDEF("CEE2", "Indeterminate value used in an expression.",
                    "6.2.4, 6.7.9, 6.8, J.2:1 item 11")
               ~> tv(trap, T))
          [structural]
     rule _:ErrorExit ~> tv(trap, T:IntegerType) ~> reval() => tv(0, T) ~> reval()
          requires isErrorRecovery
     rule _:ErrorExit ~> tv(trap, T:FloatType) ~> reval() => tv(0.0, T) ~> reval()
          requires isErrorRecovery
     rule _:ErrorExit ~> tv(trap, T:PointerType) ~> reval() => tv(NullPointer, T) ~> reval()
          requires isErrorRecovery

     syntax KItem ::= checkRegister(SymLoc)
     rule <k> checkRegister(_) => .K ...</k>
          <initializing> true </initializing>
          [structural]
     rule <k> checkRegister(Loc:SymLoc) => .K ...</k>
          <initializing> false </initializing>
          requires notBool isRegisterLoc(Loc)
          [structural]
     rule <k> (.K => UNDEF("CEE1",
                    "Address of an array declared with register storage class used in an expression.",
                    "6.3.2.1:3, J.2:1 item 22"))
              ~> checkRegister(Loc:SymLoc)
          ...</k>
          <initializing> false </initializing>
          requires isRegisterLoc(Loc)
          [structural]
     rule _:ErrorExit ~> checkRegister(_) => .K
          requires isErrorRecovery

     rule checkUse(V:KResult) => V
          requires getKLabel(V) =/=K #klabel(`tv`)
          [structural]
     rule checkUse(tv(V::CValue, T::Type)) => tv(V, T)
          requires isSymLoc(V) =/=K true andBool isTrap(V) =/=K true
          [structural]
     rule checkUse(tv(trap, T::Type)) => trap(T)
          [structural]
     rule checkUse(tv(V:SymLoc, T::Type)) => checkLoc(V) ~> tv(V, T)
          [structural]

     syntax KItem ::= checkLoc(SymLoc)
     rule checkLoc(Loc::SymLoc) => checkLoc'(stripProv(Loc))
          [structural]

     syntax KItem ::= "checkLoc'" "(" SymLoc ")"
     rule checkLoc'(NullPointer) => .K
          [structural]
     rule <k> checkLoc'(Loc::SymLoc) => .K ...</k>
          <mem> Mem::Map </mem>
          requires (isStaticDuration(Loc) orBool isNativeLoc(Loc))
               andBool notBool (base(Loc) in_keys(Mem))
          [structural]
     rule <k> checkLoc'(loc(Base::SymBase, Offset::Int))
               => checkOffsets(Offset, Len)
          ...</k>
          <mem>... Base |-> object(_, Len::Int, _, _) ...</mem>
          [structural]
     rule <k> checkLoc'(loc(Base::SymBase, Offset::Int)) => errorLocInvalid ...</k>
          <mem> Mem::Map </mem>
          requires notBool (Base in_keys(Mem))
               andBool notBool isStaticDuration(loc(Base, Offset))
               andBool notBool isNativeLoc(loc(Base, Offset))
          [structural]

     syntax KItem ::= checkOffsets(Int, Int) [function]
     rule checkOffsets(Offset::Int, Len::Int) => .K
          requires (Offset <=Int Len) andBool (Offset >=Int 0)
     rule checkOffsets(_, _) => errorLocBounds [owise]

     syntax Error ::= "errorLocInvalid"
                    | "errorLocBounds"
     rule (.K => UNDEF("CEE4",
               "Referring to an object outside of its lifetime.",
               "6.2.4:2, J.2:1 item 9"))
          ~> errorLocInvalid
          [structural]
     rule (.K => UNDEF("CEE3",
               "Found pointer that refers outside the bounds of an object + 1.",
               "6.3.2.1:1, J.2:1 item 19"))
          ~> errorLocBounds
          [structural]

endmodule
