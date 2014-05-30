module C-COMMON-EXPR-EVAL-SYNTAX
     // TODO(chathhorn): hackish, rename at least
     syntax KItem ::= rkludge(K) [function, klabel('rkludge)]
     syntax KItem ::= pkludge(K) [function, klabel('pkludge)]
     syntax KItem ::= instantiate(SymLoc, Type)
     syntax KItem ::= checkLoc(SymLoc)
endmodule

module C-COMMON-EXPR-EVAL
     imports C-COMMON-EXPR-EVAL-SYNTAX

     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-LITERAL-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     syntax Int ::= arrayLength(Type) [function]
     rule arrayLength(t(_, arrayType(_, N:CSize))) => N
     /*@ these large numbers are used instead of an infinity---the result of
     these rules shouldn't be used later anyway */
     rule arrayLength(t(_, flexibleArrayType(_)))
          => 36893488147419103232
     rule arrayLength(t(_, incompleteArrayType(_)))
          => 36893488147419103232
     
     // chathhorn: to work around the new semantics for contexts.
     rule reval(K:K) => checkUse(K) ~> reval(HOLE) [heat]
     rule K:K ~> reval(HOLE) => reval(rkludge(K)) [cool, ndlocal]
     rule rkludge(K:K) => K
          when isKResult(K) =/=K true

     rule peval(K:K) => K ~> peval(HOLE) [heat]
     rule K:K ~> peval(HOLE) => peval(pkludge(K)) [cool, ndlocal]
     rule pkludge(K:K) => K
          when isKResult(K) =/=K true

     rule lv(L:SymLoc, T:Type) => lval(L, T)
          [structural]

     // FIXME Whoah!  What about char types?  What is this about?
     // If the lvalue designates an object of automatic storage duration that
     // could have been declared with the register storage class (never had its
     // address taken), and that object is uninitialized (not declared with an
     // initializer and no assignment to it has been performed prior to use),
     // the behavior is undefined.
     
     rule rkludge(skipval) => skipval
     rule rkludge(emptyValue) => emptyValue
     rule rkludge(tv(V:CValue, T:Type)) => tv(V, T)

     rule pkludge(tv(V:CValue, T:Type)) => tv(V, T)
     
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
     rule pkludge(lval(Loc:SymLoc, T:Type)) => lval(Loc, T)
          when notBool isArrayType(T) 
               andBool notBool isFunctionType(T) 
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
     rule rkludge(lval(Loc:SymLoc, T:Type))
          => tv(Loc, stripQualifiers(arrayToPointer(T)))
          when isArrayType(T) 
     rule pkludge(lval(Loc:SymLoc, T:Type))
          => tv(Loc, arrayToPointer(T))
          when isArrayType(T)

     syntax Type ::= arrayToPointer(Type) [function]
     rule arrayToPointer(t(Mods:Set, T:SimpleType))
          => t(Mods SetItem(fromArray(0, arrayLength(t(Mods, T)))),
               pointerType(innerType(t(Mods, T))))
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{4}}}{
     A function designator is an expression that has function type.  Except
     when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, or the unary \cinline{&} operator, a function
     designator with type ``function returning T'' is converted to an
     expression that has type ``pointer to a function returning T''.
     }*/
     rule rkludge(lval(Loc:SymLoc, T:Type)) 
          => tv(Loc, t(.Set, pointerType(T)))
          when isFunctionType(T) 
     rule pkludge(lval(Loc:SymLoc, T:Type)) 
          => tv(Loc, t(.Set, pointerType(T)))
          when isFunctionType(T) 

     rule rkludge(lval(Loc:SymLoc, T:Type)) 
          => instantiate(Loc, T)
          when notBool isArrayType(T)
               andBool notBool isFunctionType(T) 
          [structural]

     syntax KItem ::= checkUse(K) [strict]

     rule checkUse(V:KResult) => V
          when isTypedValue(V) =/=K true
     rule checkUse(tv(V:CValue, T:Type)) => tv(V, T)
          when (isSymLoc(V) =/=K true)
               andBool (isTrap(V) =/=K true)
     rule checkUse(tv(V:SymLoc, T:Type))
          => checkLoc(V) ~> tv(V, T)
          when notBool isRegisterLoc(V)
     rule checkUse(tv(V:SymLoc, T:Type))
          => UNDEF("CEE1", "Address of a value declared with register storage class used in an expression.", "")
          ~> tv(V, T)
          when isRegisterLoc(V)
     rule checkUse(tv(trap, T:Type))
          => UNDEF("CEE2", "Indeterminate value used in an expression.", "")
          ~> tv(trap, T)
     
endmodule
