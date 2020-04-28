module C-COMMON-EXPR-EVAL-SYNTAX
     imports BASIC-K
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     syntax KItem ::= instantiate(SymLoc, Type)
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
     imports C-CHECK-USE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-TYPING-SYNTAX

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

     syntax KItem ::= lvalConvert(SymLoc, Type, KItem) [strict(3)]
     rule <k> lvalConvert(Loc::SymLoc, T::Type, LAT:EffectiveType)
               => checkEffectiveType(T, offset(Loc), bitOffsetIntoLastByte(Loc), getFromArray(Loc), LAT)
               // The new last access type becomes a composite of the current
               // last-access object type and the type of the current lvalue
               // expression.
               ~> nclv(updateLastAccessType(Loc, T, LAT), T)
          ...</k>
          <mem> Mem::Map </mem>
          requires base(Loc) in_keys(Mem)
          [structural]
     rule <k> lvalConvert(Loc::SymLoc, T::Type, LAT:EffectiveType)
               => nclv(updateLastAccessType(Loc, T, LAT), T)
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

     rule reval(nclv(Loc::SymLoc, t(... st: _:SimpleArrayType) #as T::Type)
          => checkRegister(Loc)
          ~> checkUse(tv(arrayToPtrLoc(Loc, T), utype(arrayToPtrType(T)))))
          [structural]

     syntax SymLoc ::= arrayToPtrLoc(SymLoc, Type) [function]
     rule arrayToPtrLoc(Loc::SymLoc, t(... st: _:SimpleFixedArrayType) #as T::Type)
          => addProv(fromArray(0, byteSizeofType(T), T), Loc)
     rule arrayToPtrLoc(Loc::SymLoc, _) => Loc [owise]

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{4}}}{
     A function designator is an expression that has function type. Except
     when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, or the unary \cinline{&} operator, a function
     designator with type ``function returning T'' is converted to an
     expression that has type ``pointer to a function returning T''.
     }*/

     rule reval(nclv(Loc::SymLoc, t(... st: functionType(...)) #as T::Type)
          => checkUse(tv(Loc, utype(pointerType(T)))))
          [structural]

     rule reval(trap(T::UType)
          => UNDEF("CEE2", "Indeterminate value used in an expression.")
          ~> tv(trap, T))
          [structural]

     syntax KItem ::= checkRegister(SymLoc)
     rule checkRegister(Loc:SymLoc) => .K
          requires notBool isRegisterLoc(Loc)
          [structural]
     rule (.K => UNDEF("CEE1", "Address of an array declared with register storage class used in an expression."))
          ~> checkRegister(Loc:SymLoc)
          requires isRegisterLoc(Loc)
          [structural]

endmodule
