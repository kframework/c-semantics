module C-EXPRESSION-EVAL-SYNTAX
endmodule

module C-EXPRESSION-EVAL
     imports C-EXPRESSION-EVAL-SYNTAX
     imports C-EXPRESSION-ADDITIVE-OPERATORS-SYNTAX
     imports C-EXPRESSION-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-DECLARATION-SYNTAX

     syntax Int ::= arrayLength(K) [function]
     rule arrayLength(t(_:Set, arrayType(_:KResult, N:Int))) => N
     /*@ these large numbers are used instead of an infinity---the result of
     these rules shouldn't be used later anyway */
     rule arrayLength(t(_:Set, flexibleArrayType(_:KResult)))
          => 36893488147419103232
     rule arrayLength(t(_:Set, incompleteArrayType(_:KResult)))
          => 36893488147419103232
     
     // chathhorn: to work around the new semantics for contexts.
     rule reval(K:K) => K ~> reval(HOLE) [heat]
     rule K:K ~> reval(HOLE) => reval(rkludge(K)) [cool, ndlocal]
     rule rkludge(K:K) => K
          when isKResult(K) =/=K true

     rule peval(K:K) => K ~> peval(HOLE) [heat]
     rule K:K ~> peval(HOLE) => peval(pkludge(K)) [cool, ndlocal]
     rule pkludge(K:K) => K
          when isKResult(K) =/=K true

     rule lv(L:SymLoc, T:Type) => lval(L, T)
          [structural]
     
     // fixme Whoah!  What about char types?  What is this about?
     // If the lvalue designates an object of automatic storage duration that
     // could have been declared with the register storage class (never had its
     // address taken), and that object is uninitialized (not declared with an
     // initializer and no assignment to it has been performed prior to use),
     // the behavior is undefined.
     
     rule [reval-skipval]: 
          rkludge(skipval) => skipval
     rule [reval-emptyval]:
          rkludge(emptyValue) => emptyValue
     rule [reval-tv-normal]:
          rkludge(tv(L:KList, T:KResult)) => tv(L:KList, T:KResult)
     rule [peval-tv-normal]:
          pkludge(tv(V:KList, T:KResult)) => tv(V:KList, T:KResult)
     
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
     rule rkludge(lval(Loc:SymLoc, T:Type)) => read(Loc, unqualifyType(T))
          when notBool isArrayType(T) 
               andBool notBool isFunctionType(T) 
          [structural]
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
     rule [reval-lv-array]: 
          rkludge(lval(Loc:SymLoc, T:Type))
          => tv(Loc, t(SetItem(fromArray(0, arrayLength(T))),
               pointerType(innerType(T))))
          when isArrayType(T) 
     rule [peval-lv-array]: 
          pkludge(lval(Loc:SymLoc, T:Type))
          => tv(Loc, t(SetItem(fromArray(0, arrayLength(T))),
               pointerType(innerType(T))))
          when isArrayType(T) 
     // should never get to the situation where we have tv(..., arrayType)
     
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{4}}}{
     A function designator is an expression that has function type.  Except
     when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, or the unary \cinline{&} operator, a function
     designator with type ``function returning T'' is converted to an
     expression that has type ``pointer to a function returning T''.
     }*/
     rule [reval-function]: 
          rkludge(lval(Loc:SymLoc, T:Type)) 
          => tv(Loc, t(.Set, pointerType(T)))
          when isFunctionType(T) 
     rule [peval-function]: 
          pkludge(lval(Loc:SymLoc, T:Type)) 
          => tv(Loc, t(.Set, pointerType(T)))
          when isFunctionType(T) 
     
endmodule
