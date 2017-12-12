module C-COMMON-EXPR-EVAL-SYNTAX
     imports BASIC-K
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     syntax KItem ::= instantiate(SymLoc, Type)
     syntax KItem ::= checkUse(K) [strict]
     syntax KItem ::= checkLoc(SymLoc)
endmodule

module C-COMMON-EXPR-EVAL
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports K-REFLECTION
     imports INT
     imports BITS-SYNTAX
     imports SETTINGS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-SYNTAX

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
     rule checkCompleteLValue(T::Type) => .K
          requires isCompleteType(T)
     rule (.K => UNDEF("CEE5", "Trying to convert an incomplete lvalue not of array type."))
          ~> checkCompleteLValue(T::Type)
          requires notBool isCompleteType(T)

     // Lvalue conversion.
     rule reval(nclv(Loc::SymLoc, T::Type)
          => checkCompleteLValue(T)
          ~> instantiate(Loc, T))
          requires notBool isArrayOrFunctionType(T)
          [structural]

     rule <k> lv(Loc::SymLoc => resolveLinking(Loc, Linkings), T::Type) ...</k>
          <linkings> Linkings::Map </linkings>
          requires Loc =/=K NullPointer andBool (base(Loc) in_keys(Linkings))
          [structural]
     rule <k> lv(Loc::SymLoc, T::Type)
               => lvalConvert(Loc, T, getLastAccessType(Loc))
          ...</k>
          <linkings> Linkings::Map </linkings>
          requires Loc =/=K NullPointer andBool notBool base(Loc) in_keys(Linkings)
          [structural]
     rule lv(NullPointer, T::Type) => nclv(NullPointer, T)
          [structural]

     syntax KItem ::= lvalConvert(SymLoc, Type, K) [strict(3)]
     rule <k> lvalConvert(Loc::SymLoc, T::Type, LAT:EffectiveType)
               => checkEffectiveType(T, bitOffset(Loc), LAT)
               // The new last access type becomes a composite of the current
               // last-access object type and the type of the current lvalue
               // expression.
               ~> nclv(updateLastAccessType(Loc, T, LAT), T)
          ...</k>
          <mem> Mem::Map </mem>
          requires base(Loc) in_keys(Mem)
          [structural]
     rule <k> lvalConvert(Loc::SymLoc, T::Type, _)
               => nclv(Loc, T)
          ...</k>
          <mem> Mem::Map </mem>
          requires notBool (base(Loc) in_keys(Mem))
          [structural]

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

     syntax SymLoc ::= arrayToPtrLoc(SymLoc, Type) [function]
     rule arrayToPtrLoc(Loc::SymLoc, T:FixedLengthArrayType)
          => addProv(fromArray(0, byteSizeofType(T)), Loc)
     rule arrayToPtrLoc(Loc::SymLoc, _) => Loc [owise]

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{4}}}{
     A function designator is an expression that has function type. Except
     when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, or the unary \cinline{&} operator, a function
     designator with type ``function returning T'' is converted to an
     expression that has type ``pointer to a function returning T''.
     }*/

     rule reval(nclv(Loc::SymLoc, T:FunctionType)
          => checkUse(tv(Loc, utype(pointerType(T)))))
          [structural]

     rule reval(trap(T::UType)
          => UNDEF("CEE2", "Indeterminate value used in an expression.")
          ~> tv(trap, T))
          [structural]

     syntax KItem ::= checkRegister(SymLoc)
     rule <k> checkRegister(_) => .K ...</k>
          <initializing> true </initializing>
          [structural]
     rule <k> checkRegister(Loc:SymLoc) => .K ...</k>
          <initializing> false </initializing>
          requires notBool isRegisterLoc(Loc)
          [structural]
     rule <k> (.K => UNDEF("CEE1",
                    "Address of an array declared with register storage class used in an expression."))
              ~> checkRegister(Loc:SymLoc)
          ...</k>
          <initializing> false </initializing>
          requires isRegisterLoc(Loc)
          [structural]

     rule checkUse(V:KResult) => V
          requires getKLabel(V) =/=K #klabel(`tv`)
          [structural]
     rule checkUse(tv(V::CValue, T::UType)) => tv(V, T)
          requires notBool (isSymLoc(V) andBool isPointerUType(T))
               andBool notBool isTrap(V)
               andBool notBool isOpaque(V)
          [structural]
     rule <k> checkUse(tv(V:Opaque, T::UType)) => tv(V, T) ...</k>
          <curr-tu> "builtin" </curr-tu>
          [structural]
     rule <k> checkUse(tv(V:Opaque, T::UType)) => checkOpaque(V) ~> tv(V, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          requires Tu =/=K "builtin"
          [structural]
     rule checkUse(tv(trap, T::UType)) => trap(T)
          [structural]
     rule <k> checkUse(tv(V:SymLoc, T:PointerUType))
               => checkLoc(resolveLinking(V, Linkings))
               ~> tv(resolveLinking(V, Linkings), T)
          ...</k>
          <linkings> Linkings::Map </linkings>
          [structural]

     syntax Error ::= "errorLocBounds"
     syntax KItem ::= "errorLocInvalid"
     rule checkLoc(NullPointer) => .K
          [structural]
     rule checkLoc(loc(_, _, _) #as Loc::SymLoc => stripProv(Loc))
          [structural]
     rule <k> checkLoc(loc(Base::SymBase, Offset::Int)) => .K ...</k>
          <mem>... Base |-> object(_, Sz::Int, _) ...</mem>
          requires (Offset <=Int Sz) andBool (Offset >=Int 0)
          [structural]
     rule <k> checkLoc(loc(Base::SymBase, Offset::Int))
               => UNDEF("CEE3", "Found pointer that refers outside the bounds of an object + 1.")
               ~> errorLocBounds
          ...</k>
          <mem>... Base |-> object(_, Sz::Int, _) ...</mem>
          requires (Offset >Int Sz) orBool (Offset <Int 0)
          [structural]
     rule <k> checkLoc(loc(_, _) #as Loc::SymLoc) => .K ...</k>
          <mem> Mem::Map </mem>
          requires (isStaticDuration(Loc) orBool isNativeLoc(Loc))
               andBool notBool (base(Loc) in_keys(Mem))
          [structural]
     rule <k> checkLoc(loc(_, _) #as Loc::SymLoc)
               => UNDEF("CEE4", "Referring to an object outside of its lifetime.")
               ~> errorLocInvalid
          ...</k>
          <mem> Mem::Map </mem>
          requires notBool (base(Loc) in_keys(Mem))
               andBool notBool isStaticDuration(Loc)
               andBool notBool isNativeLoc(Loc)
          [structural]

     syntax KItem ::= checkOpaque(Opaque) [function]
     rule checkOpaque(_) => .K
          requires notBool hasLint

endmodule
