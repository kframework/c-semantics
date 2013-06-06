require "dynamic-c-semantics.k"

module DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     imports DYNAMIC-INCLUDE
     syntax K ::= "assign" "(" K "," K ")"
     syntax Id ::= "compoundLiteral" "(" Int ")"
     
     syntax K ::= "lvGetOffset" "(" K "," K "," Type ")"
     syntax K ::= "tvGetOffset" "(" K "," K "," Type ")"

     syntax K ::= "fromArray" "(" Int "," Int ")" // offset, length
     
     syntax K ::= makeTruth(Bool) [function]
     rule makeTruth(B:Bool) => #if B:Bool #then tv(1, t(.Set, int)) #else tv(0, t(.Set, int)) #fi
     
     syntax Int ::= arrayLength(K) [function]
     rule arrayLength(t(_:Set, arrayType(_:KResult, N:Int))) => N:Int
     /*@ these large numbers are used instead of an infinity---the result of these rules shouldn't be used later anyway */
     rule arrayLength(t(_:Set, flexibleArrayType(_:KResult))) => 36893488147419103232
     rule arrayLength(t(_:Set, incompleteArrayType(_:KResult))) => 36893488147419103232

     syntax K ::= rkludge(K) [function]
     syntax K ::= pkludge(K) [function]

     // chathhorn: to work around the new semantics for contexts.
     rule reval(K:K) => K ~> reval(HOLE) [heat]
     rule R:KResult ~> reval(HOLE) => reval(rkludge(R)) [cool]

     rule peval(K:K) => K ~> peval(HOLE) [heat]
     rule R:KResult ~> peval(HOLE) => peval(pkludge(R)) [cool]

     rule lv(L:SymLoc, T:Type) => lval(L:SymLoc, T:Type)
     
     // fixme Whoah!  What about char types?  What is this about?
     // If the lvalue designates an object of automatic storage duration that
     // could have been declared with the register storage class (never had its
     // address taken), and that object is uninitialized (not declared with an
     // initializer and no assignment to it has been performed prior to use),
     // the behavior is undefined.
     
     rule [reval-skipval]: rkludge(skipval) => skipval [structural]
     rule [reval-emptyval]: rkludge(emptyValue) => emptyValue [structural]
     rule [reval-tv-normal]: rkludge(tv(L:KList, T:KResult)) => tv(L:KList, T:KResult) [structural] 
     rule [peval-tv-normal]: pkludge(tv(V:KList, T:KResult)) => tv(V:KList, T:KResult) [structural]
     
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
          when notBool isArrayType(T) andBool notBool isFunctionType(T) 
          [structural]
     rule pkludge(lval(Loc:SymLoc, T:Type)) => lval(Loc, T)
          when notBool isArrayType(T) andBool notBool isFunctionType(T) 
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
          => tv(Loc, t(SetItem(fromArray(0, arrayLength(T))), pointerType(innerType(T))))
          when isArrayType(T) 
          [structural]
     rule [peval-lv-array]: 
          pkludge(lval(Loc:SymLoc, T:Type))
          => tv(Loc, t(SetItem(fromArray(0, arrayLength(T))), pointerType(innerType(T))))
          when isArrayType(T) 
          [structural]
     // should never get to the situation where we have tv(..., arrayType)
     
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{4}}}{
     A function designator is an expression that has function type.  Except
     when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, or the unary \cinline{&} operator, a function
     designator with type ``function returning T'' is converted to an
     expression that has type ``pointer to a function returning T''.
     }*/
     rule [reval-function]: 
          rkludge(lval(Loc:SymLoc, T:Type)) => tv(Loc, t(.Set, pointerType(T)))
          when isFunctionType(T) 
          [structural]
     rule [peval-function]: 
          pkludge(lval(Loc:SymLoc, T:Type)) => tv(Loc, t(.Set, pointerType(T)))
          when isFunctionType(T) 
          [structural]
     
endmodule

module DYNAMIC-SEMANTICS-LITERALS
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
          
     syntax Bool ::= withinRange(Int, SimpleType) [function]
     rule withinRange(I:Int, T:K) => (I:Int <=Int max(t(.Set, T:K))) andBool (I:Int >=Int min(t(.Set, T:K)))
     
     syntax String ::= simplifyForHex(String) [function]
     rule simplifyForHex(S:String) => simplifyForHex(butFirstChar(S:String))
          when (firstChar(S:String) ==String "0")
               andBool (lengthString(S:String) >Int 1)
     rule simplifyForHex(S:String) => S:String
          when (firstChar(S:String) =/=String "0")
               orBool (lengthString(S:String) ==Int 1)
          
     syntax K ::= "hexOrOctalConstant" "(" K ")"
      // TODO(chathhorn): hex, elided
     // rule HexConstant(S:String) => hexOrOctalConstant(String2Rat(simplifyForHex(S:String), 16)) [structural, anywhere]
     // rule OctalConstant(N:Int) => hexOrOctalConstant(String2Rat(Rat2String(N:Int, 10), 8)) [structural, anywhere]

     /*@ \fromStandard{\source[n1570]{\para{6.4.4.1}{4--6}}}{
     
     The value of a decimal constant is computed base 10; that of an octal
     constant, base 8; that of a hexadecimal constant, base 16. The lexically
     first digit is the most significant.
     
     The type of an integer constant is the first of the corresponding list in which its value can be represented.\\
     \begin{tabular}{@{}lll@{}}
     \toprule
     Suffix    &    Decimal Constant    &         Octal or Hexadecimal Constant  \\
     \midrule
     none      &         \cinline{int}                           &    \cinline{int} \\
               &         \cinline{long int}                 &    \cinline{unsigned int} \\
               &         \cinline{long long int}            &    \cinline{long int} \\
               &                                       &    \cinline{unsigned long int} \\
               &                                       &    \cinline{long long int} \\
               &                                       &    \cinline{unsigned long long int} \\
     \midrule
     \cinline{u} or \cinline{U}    &         \cinline{unsigned int}             &    \cinline{unsigned int} \\
               &         \cinline{unsigned long int}        &    \cinline{unsigned long int} \\
               &         \cinline{unsigned long long int}   &    \cinline{unsigned long long int} \\
     \midrule
     \cinline{l} or \cinline{L}    &         \cinline{long int}                 &    \cinline{long int} \\
               &         \cinline{long long int}            &    \cinline{unsigned long int} \\
               &                                       &    \cinline{long long int} \\
               &                                       &    \cinline{unsigned long long int} \\
     \midrule
     Both \cinline{u} or \cinline{U} and \cinline{l} or \cinline{L}   &    \cinline{unsigned long int}        &    \cinline{unsigned long int} \\
                                   &    \cinline{unsigned long long int}   &    \cinline{unsigned long long int} \\
     \midrule
     \cinline{ll} or \cinline{LL}  &    \cinline{long long int}            &    \cinline{long long int} \\
                    &                                  &    \cinline{unsigned long long int} \\
     \midrule
     Both \cinline{u} or \cinline{U} and \cinline{ll} or \cinline{LL} &    \cinline{unsigned long long int}   &    \cinline{unsigned long long int} \\
     \bottomrule
     \end{tabular}

     If an integer constant cannot be represented by any type in its list, it
     may have an extended integer type, if the extended integer type can
     represent its value. If all of the types in the list for the constant are
     signed, the extended integer type shall be signed. If all of the types in
     the list for the constant are unsigned, the extended integer type shall be
     unsigned. If the list contains both signed and unsigned types, the
     extended integer type may be signed or unsigned. If an integer constant
     cannot be represented by any type in its list and has no extended integer
     type, then the integer constant has no type.
     }*/  
     rule NoSuffix(DecimalConstant(I:Int)) =>
          #if withinRange(I:Int, int) #then tv(I:Int, t(.Set, int)) #else
          #if withinRange(I:Int, long-int) #then tv(I:Int, t(.Set, long-int)) #else
          #if withinRange(I:Int, long-long-int) #then tv(I:Int, t(.Set, long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi #fi #fi
          [structural, anywhere]
     
     rule NoSuffix(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I:Int, int) #then tv(I:Int, t(.Set, int)) #else
          #if withinRange(I:Int, unsigned-int) #then tv(I:Int, t(.Set, unsigned-int)) #else
          #if withinRange(I:Int, long-int) #then tv(I:Int, t(.Set, long-int)) #else
          #if withinRange(I:Int, unsigned-long-int) #then tv(I:Int, t(.Set, unsigned-long-int)) #else
          #if withinRange(I:Int, long-long-int) #then tv(I:Int, t(.Set, long-long-int)) #else
          #if withinRange(I:Int, unsigned-long-long-int) #then tv(I:Int, t(.Set, unsigned-long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi #fi #fi #fi #fi #fi
          [structural, anywhere]

     rule ConstU(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I:Int, unsigned-int) #then tv(I:Int, t(.Set, unsigned-int)) #else
          #if withinRange(I:Int, unsigned-long-int) #then tv(I:Int, t(.Set, unsigned-long-int)) #else
          #if withinRange(I:Int, unsigned-long-long-int) #then tv(I:Int, t(.Set, unsigned-long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi #fi #fi
          [structural, anywhere]
          
     rule ConstL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I:Int, long-int) #then tv(I:Int, t(.Set, long-int)) #else
          #if withinRange(I:Int, unsigned-long-int) #then tv(I:Int, t(.Set, unsigned-long-int)) #else
          #if withinRange(I:Int, long-long-int) #then tv(I:Int, t(.Set, long-long-int)) #else
          #if withinRange(I:Int, unsigned-long-long-int) #then tv(I:Int, t(.Set, unsigned-long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi #fi #fi #fi
          [structural, anywhere]
          
     rule ConstUL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I:Int, unsigned-long-int) #then tv(I:Int, t(.Set, unsigned-long-int)) #else
          #if withinRange(I:Int, unsigned-long-long-int) #then tv(I:Int, t(.Set, unsigned-long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi #fi
          [structural, anywhere]
          
     rule ConstLL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I:Int, long-long-int) #then tv(I:Int, t(.Set, long-long-int)) #else
          #if withinRange(I:Int, unsigned-long-long-int) #then tv(I:Int, t(.Set, unsigned-long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi #fi
          [structural, anywhere]
     
     rule ConstULL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I:Int, unsigned-long-long-int) #then tv(I:Int, t(.Set, unsigned-long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi
          [structural, anywhere]
          
          
     rule ConstU(DecimalConstant(I:Int)) =>
          #if withinRange(I:Int, unsigned-int) #then tv(I:Int, t(.Set, unsigned-int)) #else
          #if withinRange(I:Int, unsigned-long-int) #then tv(I:Int, t(.Set, unsigned-long-int)) #else
          #if withinRange(I:Int, unsigned-long-long-int) #then tv(I:Int, t(.Set, unsigned-long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi #fi #fi
          [structural, anywhere]
     rule ConstL(DecimalConstant(I:Int)) =>
          #if withinRange(I:Int, long-int) #then tv(I:Int, t(.Set, long-int)) #else
          #if withinRange(I:Int, long-long-int) #then tv(I:Int, t(.Set, long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi #fi
          [structural, anywhere]
     rule ConstUL(DecimalConstant(I:Int)) =>
          #if withinRange(I:Int, unsigned-long-int) #then tv(I:Int, t(.Set, unsigned-long-int)) #else
          #if withinRange(I:Int, unsigned-long-long-int) #then tv(I:Int, t(.Set, unsigned-long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi #fi        
          [structural, anywhere]
     rule ConstLL(DecimalConstant(I:Int)) =>
          #if withinRange(I:Int, long-long-int) #then tv(I:Int, t(.Set, long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi
          [structural, anywhere]
     rule ConstULL(DecimalConstant(I:Int)) =>
          #if withinRange(I:Int, unsigned-long-long-int) #then tv(I:Int, t(.Set, unsigned-long-long-int)) #else
               tv(I:Int, t(.Set, no-type))
          #fi
          [structural, anywhere]
     
     /*@ \fromStandard{\source[n1570]{\para{6.4.4.2}{4}}}{
     An unsuffixed floating constant has type \cinline{double}. If suffixed by
     the letter \cinline{f} or \cinline{F}, it has type \cinline{float}. If
     suffixed by the letter \cinline{l} or \cinline{L}, it has type
     \cinline{long double}.
     }*/
     syntax K ::= "reducedFloat" "(" Float ")"
     rule DecimalFloatConstant(_:String, _:Int, F:Float) => reducedFloat(F:Float) [structural, anywhere]
     rule HexFloatConstant(_:String, _:Int, F:Float) => reducedFloat(F:Float) [structural, anywhere]
     
     rule NoSuffix(reducedFloat(F:Float)) => tv(F:Float, t(.Set, double))
          [structural, anywhere]
     rule ConstL(reducedFloat(F:Float)) => tv(F:Float, t(.Set, long-double))
          [structural, anywhere]
     rule ConstF(reducedFloat(F:Float)) => tv(F:Float, t(.Set, float))
          [structural, anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.4.4.4}{10}}}{
     An integer character constant has type \cinline{int}. The value of an
     integer character constant containing a single character that maps to a
     single-byte execution character is the numerical value of the
     representation of the mapped character interpreted as an integer. The
     value of an integer character constant containing more than one character
     (e.g., \cinline{'ab'}), or containing a character or escape sequence that
     does not map to a single-byte execution character, is
     implementation-defined. If an integer character constant contains a single
     character or escape sequence, its value is the one that results when an
     object with type \cinline{char} whose value is that of the single
     character or escape sequence is converted to type \cinline{int}.
     }*/
     rule CharLiteral(N:Int) 
          => cast(t(.Set, int), cast(t(.Set, char), tv(N:Int, t(.Set, int))))
          [structural, anywhere]
     rule WCharLiteral(N:Int) => tv(N:Int, cfg:wcharut) [structural, anywhere]
     rule Constant(V:KResult) => V:KResult [structural, anywhere]
     // chathhorn: note this rule.
     rule [create-internal-value]: <k> N:Int => tv(N:Int, cfg:largestUnsigned) ...</k>
          [structural] // for internal computations
     
     // here we start with a local address, put the string in memory, then
     // change the address to be readonly
     
     /*@ \fromStandard{\source[n1570]{\para{6.4.5}{6}}}{For character string
     literals, the array elements have type \cinline{char}, and are initialized
     with the individual bytes of the multibyte character sequence. \ldots

     For wide string literals prefixed by the letter \cinline{L}, the array elements
     have type \cinline{wchar_t} and are initialized with the sequence of wide
     characters corresponding to the multibyte character sequence\ldots

     }*/  
          
     rule [const-string-notfound]:
          <k> (. => allocString(Loc, S +String "\0"))
               ~> Constant(StringLiteral(S:String))
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <br/>
          <stringLiterals>
               M:Map
               (. => S |-> lv(Loc, t(.Set, arrayType(t(.Set, char), lengthString(S) +Int 1))))
          </stringLiterals>
          when notBool (S in keys(M))
          [large, structural]
          
     syntax K ::= "wstring" "(" KList ")"
     rule [const-wstring-notfound]:
          <k> (.K => allocWString(Loc, (S:KList,, 0)))
               ~> Constant(WStringLiteral(S:KList))
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <br/>
          <stringLiterals>
               M:Map
               (.Map => wstring(S:KList) |-> lv(Loc, t(.Set, arrayType(cfg:wcharut, (lengthKList S:KList) +Int 1))))
          </stringLiterals>
          when notBool wstring(S:KList) in keys M:Map
          [large, structural]
          
     rule [const-string-found]:
          <k> Constant(StringLiteral(S:String)) => V:KResult ...</k>
          <stringLiterals>... S:String |-> V:KResult ...</stringLiterals>
          [structural]
     rule [const-wstring-found]:
          <k> Constant(WStringLiteral(S:KList)) => V:KResult ...</k>
          <stringLiterals>... wstring(S:KList) |-> V:KResult ...</stringLiterals>
          [structural]
endmodule

module DYNAMIC-SEMANTICS-IDENTIFIERS
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.1}{2}}}{
     An identifier is a primary expression, provided it has been declared as
     designating an object (in which case it is an lvalue) or a function (in
     which case it is a function designator).
     }*/
     rule [lookup]:
          <k> X:Id => lv(Loc, T) ...</k>
          <env>... X:Id |-> Loc:SymLoc ...</env>
          <types>... X:Id |-> T:Type ...</types>
          [structural]
          
     rule [lookup-builtin-function-notfound]:
          <k> (.K 
                    => addToEnv(X:Id, Loc)
                    ~> initFunction(
                         tv(Loc, t(.Set, pointerType(T:KResult))),
                         functionPrototype(X:Id, T:KResult)
                    )
               )
               ~> X:Id
          ...</k>
          <br/>
          <env> Env:Map </env>
          <types>... X:Id |-> T:KResult ...</types>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          when isFunctionType(T:KResult)
          andBool notBool X:Id in keys Env:Map
          [large, structural]
endmodule

module DYNAMIC-SEMANTICS-ARRAY-SUBSCRIPTING
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.1}{2--3}}}{
     A postfix expression followed by an expression in square brackets
     \cinline{[]} is a subscripted designation of an element of an array
     object. The definition of the subscript operator \cinline{[]} is that
     \cinline{E1[E2]} is identical to \cinline{(*((E1)+(E2)))}. Because of the
     conversion rules that apply to the binary \cinline{+} operator, if
     \cinline{E1} is an array object (equivalently, a pointer to the initial
     element of an array object) and \cinline{E2} is an integer,
     \cinline{E1[E2]} designates the \cinline{E2}-th element of \cinline{E1}
     (counting from zero).

     Successive subscript operators designate an element of a multidimensional
     array object. If \cinline{E} is an $n$-dimensional array ($n \ge 2$) with
     dimensions $i \times j \times\cdots\times k$, then \cinline{E} (used as
     other than an lvalue) is converted to a pointer to an ($n -
     1$)-dimensional array with dimensions $j \times\cdots\times k$. If the
     unary \cinline{*} operator is applied to this pointer explicitly, or
     implicitly as a result of subscripting, the result is the referenced ($n -
     1$)-dimensional array, which itself is converted into a pointer if used as
     other than an lvalue. It follows from this that arrays are stored in
     row-major order (last subscript varies fastest).
     }*/
     rule [array-subscript]:
          <k> E1:K[E2:K]
               => *(E1:K + E2:K) 
          ...</k>
          [structural]
endmodule


module DYNAMIC-SEMANTICS-FUNCTION-CALLS
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE

     syntax K ::= "application" "(" K "," VTList ")" [strict(1)]
     syntax K ::= "application'" "(" K "," VTList ")" [strict(1)]
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.2}{3}}}{
     A postfix expression followed by parentheses \cinline{()} containing a
     possibly empty, comma-separated list of expressions is a function call.
     The postfix expression denotes the called function. The list of
     expressions specifies the arguments to the function.
     }*/
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.2}{6}}}{
     \broken{If the expression that denotes the called function has a type that
     does not include a prototype, the integer promotions are performed on each
     argument, and arguments that have type \cinline{float} are promoted to
     \cinline{double}. These are called the default argument promotions. If the
     number of arguments does not equal the number of parameters, the behavior
     is undefined. If the function is defined with a type that includes a
     prototype, and either the prototype ends with an ellipsis (\cinline{,
     ...}) or the types of the arguments after promotion are not compatible
     with the types of the parameters, the behavior is undefined. If the
     function is defined with a type that does not include a prototype, and the
     types of the arguments after promotion are not compatible with those of
     the parameters after promotion, the behavior is undefined, except for the
     following cases: 
     
     \begin{itemize}
     \item one promoted type is a signed integer type, the other promoted type
     is the corresponding unsigned integer type, and the value is representable
     in both types;

     \item both types are pointers to qualified or unqualified versions of a
     character type or \cinline{void}.

     \end{itemize}
     }}*/
     
     rule [function-application-pre]:
          <k> Call(tv(Loc:SymLoc, t(_, pointerType(T:KResult))), klist(L:VTList))
               => application(readFunction(Loc), L)
          ...</k>
          when isFunctionType(T)
          [structural]
     //@ this extra step is useful for putting the function name in the
     // transition graph
     rule [call]:
          <k> application(Fun:KResult, L:VTList)
               => application'(Fun:KResult, L:VTList)
          ...</k>
          [structural]

     rule [populateFromGlobal]:
          <k> populateFromGlobal => .K ...</k>
          <currTU> Tu:K </currTU>
          //<br/>
          <genv>... Tu:K |-> map(G:Map) ...</genv> <env> _ => G:Map </env>
          <gtypes>... Tu:K |-> map(GT:Map) ...</gtypes> <types> _ => GT:Map </types>
          <gstructs> GS:Map </gstructs> <structs> _ => GS:Map </structs>
          [structural]

     rule [builtin-application]:
          <k> application'(functionPrototype(X:Id, T:KResult), L:VTList)
               => application'(functionObject(X:Id, T:KResult, handleBuiltin(X:Id, T:KResult)), L:VTList)
          ...</k>
          [structural]
          
     rule [function-application]:
          <k> application'(functionObject(X:Id, t(_, functionType(R:Type, P:VTList)), B:K), L:VTList) ~> K:K 
               => sequencePoint
               ~> populateFromGlobal
               ~> bind(L:VTList, P:VTList)
               ~> B:K
          </k>
          <br/>
          <callStack> .List => ListItem(
               C:Bag
               <continuation> K:K </continuation>
               <currTU> OldTu:K </currTU>
               <stackCurrentFunction> CurrFun:K </stackCurrentFunction>
               <stackCurrentProgramLoc> CurrLoc:K </stackCurrentProgramLoc>
          ) ...</callStack>
          <br/>
          (<control>
               <currTU> OldTu:K </currTU>
               <currentFunction> CurrFun:K </currentFunction>
               <currentProgramLoc> CurrLoc:K </currentProgramLoc>
               C:Bag
          </control>
          =>
          <control>
               <currentFunction> X:Id </currentFunction>
               <currTU> Tu:K </currTU>
               <currentProgramLoc> CurrLoc:K </currentProgramLoc>
          ...</control>)
          <funTUs>... OldTu:K |-> map((_ X:Id |-> Tu:K)) ...</funTUs>
          [structural, large]
endmodule


module DYNAMIC-SEMANTICS-MEMBERS
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{3}}}{
     A postfix expression followed by the \cinline{.} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member, and is an lvalue if the first expression is
     an lvalue. \broken{If the first expression has qualified type, the result
     has the so-qualified version of the type of the designated member.}
     }*/
     // fixme tool bug, can't use L:KLabel
     rule <k> lv(Loc:SymLoc, t(_, structType(S:Id))) . F:Id
               => lv(Loc:SymLoc +bits Offset:Int, T:KResult)
          ...</k>
          <structs>...
               S:Id |-> aggregateInfo(_, (_ F:Id |-> T:KResult), (_ F:Id |-> Offset:Int))
          ...</structs>
          [structural]
     rule <k> lv(Loc:SymLoc, t(_, unionType(S:Id))) . F:Id
               => lv(Loc +bits Offset:Int, t(SetItem(fromUnion(S:Id)) Se:Set, T:K))
          ...</k>
          <structs>...
               S:Id |-> aggregateInfo(_, (_ F:Id |-> t(Se:Set, T:K)), (_ F:Id |-> Offset:Int))
          ...</structs>
          [structural]
          
     rule <k> tv(L:KList, T:KResult) . F:Id
               => extractField(L:KList, T:KResult, F:Id)
          ...</k>
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{4}}}{
     A postfix expression followed by the \cinline{->} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member of the object to which the first expression
     points, and is an lvalue. \broken{If the first expression is a pointer to
     a qualified type, the result has the so-qualified version of the type of
     the designated member.}
     }*/
     rule K:K -> F:Id => (* K:K) . F:Id [macro]
endmodule

module DYNAMIC-SEMANTICS-POSTFIX-INCREMENT-AND-DECREMENT
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     syntax K ::= "postOpRef" "(" K "," KLabel ")"
     syntax K ::= "postInc" "(" SymLoc "," K "," Type ")" [strict(2)]
     syntax K ::= "postDec" "(" SymLoc "," K "," Type ")" [strict(2)]
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.4}{2}}}{
     The result of the postfix \cinline{++} operator is the value of the
     operand. As a side effect, the value of the operand object is incremented
     (that is, the value 1 of the appropriate type is added to it). See the
     discussions of additive operators and compound assignment for information
     on constraints, types, and conversions and the effects of operations on
     pointers. The value computation of the result is sequenced before the side
     effect of updating the stored value of the operand. With respect to an
     indeterminately-sequenced function call, the operation of postfix
     \cinline{++} is a single evaluation. Postfix \cinline{++} on an object
     with atomic type is a read-modify-write operation with
     \cinline{memory_order_seq_cst} memory order semantics.
     }*/  
     rule [post-increment-start]:
          <k> lv(Loc:SymLoc, T:Type) ++
               => postInc(Loc, read(Loc, T), T)
          ...</k>
          [structural]
     rule [post-increment]:
          <k> postInc(Loc:SymLoc, tv(V:K, T:Type), T:Type)
               => lv(Loc, T) := tv(V, T) + tv(1, t(.Set, int))
               ~> discard ~> tv(V, T)
          ...</k>
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.4}{3}}}{
     The postfix \cinline{--} operator is analogous to the postfix \cinline{++}
     operator, except that the value of the operand is decremented (that is,
     the value 1 of the appropriate type is subtracted from it).
     }*/  
     rule [post-decrement-start]:
          <k> lv(Loc:SymLoc, T:Type) --
               => postDec(Loc, read(Loc, T), T)
          ...</k>
          [structural]
     rule [post-decrement]:
          <k> postDec(Loc:SymLoc, tv(V:K, T:Type), T:Type)
               => lv(Loc, T) := tv(V, T) - tv(1, t(.Set, int))
               ~> discard ~> tv(V, T)
          ...</k>
          [structural]
     
endmodule

module DYNAMIC-SEMANTICS-COMPOUND-LITERAL
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     syntax K ::= "handleCompoundLiteral" "(" K ")" [strict]
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.5}{3--7}}}{
     A postfix expression that consists of a parenthesized type name followed
     by a brace-enclosed list of initializers is a \emph{compound literal}. It
     provides an unnamed object whose value is given by the initializer list.
     
     If the type name specifies an array of unknown size, the size is
     determined by the initializer list as specified in 6.7.9, and the type of
     the compound literal is that of the completed array type. Otherwise (when
     the type name specifies an object type), the type of the compound literal
     is that specified by the type name. In either case, the result is an
     lvalue.
     
     The value of the compound literal is that of an unnamed object initialized
     by the initializer list. If the compound literal occurs outside the body
     of a function, the object has static storage duration; otherwise, it has
     automatic storage duration associated with the enclosing block.
     
     All the semantic rules for initializer lists in 6.7.9 also apply to
     compound literals.
     
     String literals, and compound literals with const-qualified types, need
     not designate distinct objects.
     }*/
     
     /*@ We use \kinline{compoundLiteral(N:Int)} here as the identifier of the
     compound literal.*/
     // comes back from figureInit as initValue(id, type, inits)
     rule <k> CompoundLiteral(N:Int, T:KResult, K:K, Init:K)
               => handleCompoundLiteral(figureInit(compoundLiteral(N:Int), DeclType(T:KResult, K:K), Init:K))
          ...</k>
          [structural]
          
     rule <k> handleCompoundLiteral(initValue(X:Id, T:KResult, Init:K))
               => allocateType(Loc, T:KResult)
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, T:KResult)
               ~> initialize(X:Id, T:KResult, Init:K)
               ~> X:Id
          ...</k>
          //<br/>
          <compoundLiteralMap> M:Map => M:Map[Loc / X:Id] </compoundLiteralMap>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          when notBool X:Id in keys M:Map
          [structural]
          
     rule <k> handleCompoundLiteral(initValue(X:Id, T:KResult, Init:K))
               => addToEnv(X, Loc)
               ~> giveType(X, T)
               ~> initialize(X, T, Init)
               ~> X
          ...</k>
          <compoundLiteralMap>... X |-> Loc:SymLoc ...</compoundLiteralMap>
          [structural]
endmodule

module DYNAMIC-SEMANTICS-PREFIX-INCREMENT-AND-DECREMENT
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.1}{2}}}{
     The value of the operand of the prefix \cinline{++} operator is
     incremented. The result is the new value of the operand after
     incrementation. The expression \cinline{++E} is equivalent to
     \cinline{(E+=1)}. See the discussions of additive operators and compound
     assignment for information on constraints, types, side effects, and
     conversions and the effects of operations on pointers.
     }*/
     rule ++ E:K => E:K += tv(1, t(.Set, int)) [structural]
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.1}{3}}}{
     The prefix \cinline{--} operator is analogous to the prefix \cinline{++}
     operator, except that the value of the operand is decremented.
     }*/
     rule -- E:K => E:K -= tv(1, t(.Set, int)) [structural]
endmodule


module DYNAMIC-SEMANTICS-REFERENCE
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
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
          <k> &(lv(Loc:SymLoc, T:Type))
               => tv(Loc, t(.Set, pointerType(T)))
          ...</k>
          [structural]
endmodule


module DYNAMIC-SEMANTICS-DEREFERENCE
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.2}{4}}}{
     The unary \cinline{*} operator denotes indirection. If the operand points
     to a function, the result is a function designator; if it points to an
     object, the result is an lvalue designating the object. If the operand has
     type ``pointer to type'', the result has type ``type''. If an invalid
     value has been assigned to the pointer, the behavior of the unary
     \cinline{*} operator is undefined.
     }*/
     rule [deref]:
          <k> *(tv(Loc:SymLoc, t(_, pointerType(t(S:Set, T:K)))))
               => checkDerefLoc(Loc)
               ~> lv(Loc, t(S, T))
          ...</k>
          when notBool T ==K void
          [structural]
endmodule

module DYNAMIC-SEMANTICS-UNARY-ARITHMETIC
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{2}}}{
     The result of the unary \cinline{+} operator is the value of its
     (promoted) operand. The integer promotions are performed on the operand,
     and the result has the promoted type.
     }*/       
     rule [unaryPlus-int]: 
          + tv(I:Int, T:Type) => arithInterpret(T, I:Int)
          when isPromoted(T)
          [structural]
     rule [unaryPlus-float]: 
          + tv(F:Float, T:Type) => tv(F:Float, T:Type)
          [structural]   
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{3}}}{
     The result of the unary \cinline{-} operator is the negative of its
     (promoted) operand. The integer promotions are performed on the operand,
     and the result has the promoted type.
     }*/
     rule [unaryMinus-int]: 
          - tv(I:Int, T:Type) => arithInterpret(T, 0 -Int I:Int)
          when isPromoted(T)
          [structural]
     rule [unaryMinus-float]: 
          - tv(F:Float, T:Type) => arithInterpret(T, 0.0 -Float F:Float)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{4}}}{
     The result of the \cinline{\~} operator is the bitwise complement of its
     (promoted) operand (that is, each bit in the result is set if and only if
     the corresponding bit in the converted operand is not set). The integer
     promotions are performed on the operand, and the result has the promoted
     type. If the promoted type is an unsigned type, the expression
     \cinline{\~E} is equivalent to the maximum value representable in that
     type minus \cinline{E}.
     }*/
     rule ~ tv(I:Int, T:Type) => arithInterpret(T, ~Int I:Int)
          when isPromoted(T)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{5}}}{
     The result of the logical negation operator \cinline{!} is 0 if the value
     of its operand compares unequal to 0, 1 if the value of its operand
     compares equal to 0. The result has type \cinline{int}.  The expression
     \cinline{!E} is equivalent to \cinline{(0==E)}.
     }*/
     rule !(E:K) => tv(0, t(.Set, int)) == E:K
          [structural]
endmodule
     
module DYNAMIC-SEMANTICS-SIZEOF
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.4}{2}}}{
     The \cinline{sizeof} operator yields the size (in bytes) of its operand,
     which may be an expression or the parenthesized name of a type. The size
     is determined from the type of the operand. The result is an integer. If
     the type of the operand is a variable length array type, the operand is
     evaluated; otherwise, the operand is not evaluated and the result is an
     integer constant.
     }*/
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.4}{5}}}{
     The value of the result of both operators is implementation-defined, and
     its type (an unsigned integer type) is \cinline{size_t}, defined in
     \header{<stddef.h>} (and other headers).
     }*/
     
     rule sizeofType(T:KResult) => cast(cfg:sizeut, byteSizeofType(T:KResult)) 
          [structural]
     syntax K ::= "byteSizeofType-aux" "(" K ")" [strict]
     rule byteSizeofType(T:KResult) => byteSizeofType-aux(bitSizeofType(T:KResult)) 
          [structural]
     rule byteSizeofType-aux(tv(N:Int, T:KResult)) => tv(bitsToBytes(N:Int), T:KResult)
          [structural]
     rule <k> SizeofExpression(E:K) => sizeofType(typeof(E:K)) ...</k>
          [structural]
     rule <k> SizeofType(T:KResult, K:K) => sizeofType(DeclType(T:KResult, K:K)) ...</k>
          [structural]
endmodule

module DYNAMIC-SEMANTICS-CAST
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.4}{5--6}}}{
     Preceding an expression by a parenthesized type name converts the value of
     the expression to the named type. This construction is called a cast.  A
     cast that specifies no conversion has no effect on the type or value of an
     expression.
     
     If the value of the expression is represented with greater range or
     precision than required by the type named by the cast (6.3.1.8), then the
     cast specifies a conversion even if the type of the expression is the same
     as the named type and removes any extra range and precision.
     }*/
     rule <k> Cast(T:KResult, K:K, V:KResult) => cast(DeclType(T:KResult, K:K), V:KResult) ...</k>
          [structural]
endmodule

module DYNAMIC-SEMANTICS-MULTIPLICATIVE-OPERATORS
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.5}{3--6}}}{
     The usual arithmetic conversions are performed on the operands.

     The result of the binary \cinline{*} operator is the product of the
     operands.

     The result of the \cinline{/} operator is the quotient from the division
     of the first operand by the second; the result of the \cinline{\%}
     operator is the remainder. In both operations, if the value of the second
     operand is zero, the behavior is undefined.

     When integers are divided, the result of the \cinline{/} operator is the
     algebraic quotient with any fractional part discarded. If the quotient
     \cinline{a/b} is representable, the expression \cinline{(a/b)*b + a\%b}
     shall equal \cinline{a}; otherwise, the behavior of both \cinline{a/b} and
     \cinline{a\%b} is undefined.
     }*/
     
     rule tv(I1:Int, T:Type) * tv(I2:Int, T:Type) => arithInterpret(T, I1:Int *Int I2:Int)
          when isPromoted(T)
          [structural]
     rule tv(F1:Float, T:Type) * tv(F2:Float, T:Type) => arithInterpret(T, F1:Float *Float F2:Float)
          [structural]
          
     rule tv(I1:Int, T:Type) / tv(I2:Int, T:Type) => arithInterpret(T, I1:Int /Int I2:Int)
          when isPromoted(T:Type) andBool I2:Int =/=Int 0
          [structural]
     rule tv(F1:Float, T:Type) / tv(F2:Float, T:Type) => arithInterpret(T, F1:Float /Float F2:Float)
          [structural]
     // TODO(chathhorn): truncated Int, elided
     // fixme this seems out of place and strange
     // rule piece(unknown(N:Int), N) /Int M:Int 
     //      => piece(unknown(N), N)
     //      when M =/=Int 0
     //      [structural, anywhere]
          
     rule tv(I1:Int, T:Type) % tv(I2:Int, T:Type) => arithInterpret(T, I1:Int %Int I2:Int)
          when isPromoted(T)
               andBool (min(T) <=Int I1:Int /Int I2:Int) 
               andBool (max(T) >=Int I1:Int /Int I2:Int)
               andBool (I2:Int =/=Int 0)
          [structural]
endmodule

module DYNAMIC-SEMANTICS-ADDITIVE-OPERATORS
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
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
     
     syntax K ::= "addToPointer" "(" SymLoc "," Type "," K "," K ")" [strict(4)]
     rule <k> tv(Loc:SymLoc, t(S:Set, pointerType(T':KResult))) + tv(I:Int, T:KResult)
               => addToPointer(Loc, t(S:Set, pointerType(T':KResult)), I:Int, sizeofType(T':KResult))
          ...</k>
          when hasIntegerType(T:KResult)
          andBool T':KResult =/=K void
          [structural]
     rule <k> tv(I:Int, T:KResult) + tv(Loc:SymLoc, t(S:Set, pointerType(T':KResult)))
               => addToPointer(Loc, t(S:Set, pointerType(T':KResult)), I:Int, sizeofType(T':KResult))
          ...</k>
          when hasIntegerType(T:KResult)
          andBool T':KResult =/=K void
          [structural]
     rule <k> tv(Loc:SymLoc, t(S:Set, pointerType(T':KResult))) - tv(I:Int, T:KResult)
               => addToPointer(Loc, t(S:Set, pointerType(T':KResult)), 0 -Int I:Int, sizeofType(T':KResult)) 
          ...</k>
          when hasIntegerType(T:KResult)
          andBool T':KResult =/=K void
          [structural]
               
     rule <k> addToPointer(Loc:SymLoc, T:KResult, I:Int, tv(Size:Int, _))
               => tv(ladd(Loc, (I:Int *Int Size:Int)), newFromArray(T:KResult, I:Int))
          ...</k>
          when ifFromArrayInBounds(T:KResult, I:Int)
          [structural]
          
     syntax KResult ::= newFromArray(K, Int) [function]
     rule newFromArray(t(SetItem(fromArray(Offset:Int, Len:Int)), pointerType(T:KResult)), I:Int) 
          => t(SetItem(fromArray(Offset:Int +Int I:Int, Len:Int)), pointerType(T:KResult))
     rule newFromArray(t(.Set, pointerType(T:KResult)), I:Int) 
          => t(.Set, pointerType(T:KResult))
          
     syntax Bool ::= ifFromArrayInBounds(K, Int) [function]
     rule ifFromArrayInBounds(t(SetItem(fromArray(Offset:Int, Len:Int)), pointerType(T:KResult)), I:Int)
          => true
          when Offset:Int +Int I:Int <=Int Len:Int
     rule ifFromArrayInBounds(t(SetItem(fromArray(Offset:Int, Len:Int)), pointerType(T:KResult)), I:Int)
          => false
          when Offset:Int +Int I:Int >Int Len:Int
     rule ifFromArrayInBounds(t(.Set, pointerType(T:KResult)), _:Int)
          => true
          
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

     syntax K ::= "computePointerDifference" "(" SymLoc "," SymLoc "," K ")" [strict(3)] // ptr1, ptr2, size of ptr type
     rule [start-pointer-difference]: 
          tv(L1:SymLoc, t(_, pointerType(T:KResult))) - tv(L2:SymLoc, t(_, pointerType(T:KResult)))
               => computePointerDifference(L1, L2, sizeofType(T))
          [structural]
     rule [pointer-difference]: 
          computePointerDifference(loc(Base:SymBase, Offset1:Int, 0), loc(Base:SymBase, Offset2:Int, 0), tv(Size:Int, _))
               => tv((Offset1:Int -Int Offset2:Int) /Int Size:Int, cfg:ptrdiffut)
          when (Offset1:Int -Int Offset2:Int) %Int Size:Int ==Int 0
          [structural]
     
     rule tv(I1:Int, T:Type) + tv(I2:Int, T:Type) => arithInterpret(T, (I1:Int +Int I2:Int))
          when isPromoted(T)
          [structural]
     rule tv(I1:Int, T:Type) - tv(I2:Int, T:Type) => arithInterpret(T, (I1:Int -Int I2:Int))
          when isPromoted(T)
          [structural]
     rule tv(F1:Float, T:Type) + tv(F2:Float, T:Type) => arithInterpret(T, F1:Float +Float F2:Float)
          [structural]
     rule tv(F1:Float, T:Type) - tv(F2:Float, T:Type) => arithInterpret(T, (F1:Float -Float F2:Float))
          [structural]
endmodule

module DYNAMIC-SEMANTICS-BITWISE-SHIFT
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     syntax K ::= leftShiftInterpret(Type, BaseValue, K) [function]
     syntax K ::= rightShiftInterpret(Type, BaseValue) [function]
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.7}{3}}}{
     The integer promotions are performed on each of the operands. The type of
     the result is that of the promoted left operand. If the value of the right
     operand is negative or is greater than or equal to the width of the
     promoted left operand, the behavior is undefined
     }*/
     /*@ \fromStandard{\source[n1570]{\para{6.5.7}{4}}}{
     The result of \cinline{E1 << E2} is \cinline{E1} left-shifted \cinline{E2}
     bit positions; vacated bits are filled with zeros. If \cinline{E1} has an
     unsigned type, the value of the result is $\text{\cinline{E1}}\times
     2^\text{\cinline{E2}}$, reduced modulo one more than the maximum value
     representable in the result type. If \cinline{E1} has a signed type and
     nonnegative value, and $\text{\cinline{E1}}\times 2^\text{\cinline{E2}}$
     is representable in the result type, then that is the resulting value;
     otherwise, the behavior is undefined.
     }*/
     rule tv(I:Int, T:KResult) << tv(N:Int, T':KResult)
               => leftShiftInterpret(T:KResult, I:Int <<Int N:Int, tv(I:Int, T:KResult))
          when isPromoted(T:KResult) andBool isPromoted(T':KResult)
          andBool N:Int <Int numBits(T:KResult)
          [structural]
     rule leftShiftInterpret(T:KResult, I:Int, tv(E1:Int, T:KResult)) => tv(I:Int %Int (max(T:KResult) +Int 1), T:KResult)
          when hasUnsignedIntegerType(T:KResult)
     rule leftShiftInterpret(T:KResult, I:Int, tv(E1:Int, T:KResult)) => tv(I:Int, T:KResult)
          when hasSignedIntegerType(T:KResult)
          // andBool I:Int <=Int (2 ^Int absInt(numBits(T:KResult)))
          andBool I:Int <=Int max(T:KResult)
          andBool I:Int >=Int min(T:KResult)
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.7}{5}}}{
     The result of \cinline{E1 >> E2} is \cinline{E1} right-shifted
     \cinline{E2} bit positions. If \cinline{E1} has an unsigned type or if
     \cinline{E1} has a signed type and a nonnegative value, the value of the
     result is the integral part of the quotient of $\text{\cinline{E1}} /
     2^\text{\cinline{E2}}$. If \cinline{E1} has a signed type and a negative
     value, the resulting value is implementation-defined.
     }*/
     rule tv(I:Int, T:KResult) >> tv(N:Int, T':KResult) 
               => rightShiftInterpret(T:KResult, I:Int >>Int N:Int)
          when isPromoted(T:KResult) andBool isPromoted(T':KResult)
          andBool N:Int <Int numBits(T:KResult)
          [structural]
     rule rightShiftInterpret(T:KResult, I:Int) => tv(I:Int, T:KResult)
          when hasIntegerType(T:KResult)
endmodule


module DYNAMIC-SEMANTICS-RELATIONAL
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.8}{3}}}{
     If both of the operands have arithmetic type, the usual arithmetic
     conversions are performed.
     }
     
     \fromStandard{\source[n1570]{\para{6.5.8}{4}}}{
     For the purposes of these operators, a pointer to an object that is not an
     element of an array behaves the same as a pointer to the first element of
     an array of length one with the type of the object as its element type.
     }
     
     \fromStandard{\source[n1570]{\para{6.5.8}{5}}}{
     When two pointers are compared, the result depends on the relative
     locations in the address space of the objects pointed to. If two pointers
     to object types both point to the same object, or both point one past the
     last element of the same array object, they compare equal. If the objects
     pointed to are members of the same aggregate object, pointers to structure
     members declared later compare greater than pointers to members declared
     earlier in the structure, and pointers to array elements with larger
     subscript values compare greater than pointers to elements of the same
     array with lower subscript values. All pointers to members of the same
     union object compare equal. If the expression \cinline{P} points to an
     element of an array object and the expression \cinline{Q} points to the
     last element of the same array object, the pointer expression
     \cinline{Q+1} compares greater than \cinline{P}. In all other cases, the
     behavior is undefined.
     }
     
     \fromStandard{\source[n1570]{\para{6.5.8}{6}}}{
     Each of the operators \cinline{<} (less than), \cinline{>} (greater than),
     \cinline{<=} (less than or equal to), and \cinline{>=} (greater than or
     equal to) shall yield 1 if the specified relation is true and 0 if it is
     false. The result has type \cinline{int}.
     }*/
          
     rule tv(I1:Int, T:KResult) < tv(I2:Int, T:KResult)
               => makeTruth(I1:Int <Int I2:Int)
          when isPromoted(T:KResult) orBool isPointerType(T:KResult)
          [structural]
     rule tv(I1:Int, T:KResult) <= tv(I2:Int, T:KResult)
               => makeTruth(I1:Int <=Int I2:Int)
          when isPromoted(T:KResult) orBool isPointerType(T:KResult)
          [structural]
     rule tv(I1:Int, T:KResult) > tv(I2:Int, T:KResult)
               => makeTruth(I1:Int >Int I2:Int)
          when isPromoted(T:KResult) orBool isPointerType(T:KResult)
          [structural]
     rule tv(I1:Int, T:KResult) >= tv(I2:Int, T:KResult)
               => makeTruth(I1:Int >=Int I2:Int)
          when isPromoted(T:KResult) orBool isPointerType(T:KResult)
          [structural]
     rule tv(F1:Float, T:KResult) < tv(F2:Float, T:KResult)
               => makeTruth(F1:Float <Float F2:Float)
          [structural]
     rule tv(F1:Float, T:KResult) <= tv(F2:Float, T:KResult)
               => makeTruth(F1:Float <=Float F2:Float)
          [structural]
     rule tv(F1:Float, T:KResult) > tv(F2:Float, T:KResult)
               => makeTruth(F1:Float >Float F2:Float)
          [structural]
     rule tv(F1:Float, T:KResult) >= tv(F2:Float, T:KResult)
               => makeTruth(F1:Float >=Float F2:Float)
          [structural]
     
     //- comparison of pointers
     // fixme could check 6.5.8:2
     // fixme there are further restrictions on pointers
     rule [ptr-compare-lt]: tv(loc(Base:SymBase, Offset:Int, 0), T:KResult) < tv(loc(Base:SymBase, Offset':Int, 0), T':KResult)
               => makeTruth(Offset:Int <Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
     rule [ptr-compare-lte]: tv(loc(Base:SymBase, Offset:Int, 0), T:KResult) <= tv(loc(Base:SymBase, Offset':Int, 0), T':KResult)
               => makeTruth(Offset:Int <=Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
     rule [ptr-compare-gt]: tv(loc(Base:SymBase, Offset:Int, 0), T:KResult) > tv(loc(Base:SymBase, Offset':Int, 0), T':KResult)
               => makeTruth(Offset:Int >Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
     rule [ptr-compare-gte]: tv(loc(Base:SymBase, Offset:Int, 0), T:KResult) >= tv(loc(Base:SymBase, Offset':Int, 0), T':KResult)
               => makeTruth(Offset:Int >=Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
endmodule


module DYNAMIC-SEMANTICS-EQUALITY
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE

     /*@ \fromStandard{\source[n1570]{\para{6.5.9}{3--4}}}{
     The \cinline{==} (equal to) and \cinline{!=} (not equal to) operators are
     analogous to the relational operators except for their lower precedence.
     Each of the operators yields 1 if the specified relation is true and 0 if
     it is false. The result has type \cinline{int}. For any pair of operands,
     exactly one of the relations is true.
     
     If both of the operands have arithmetic type, the usual arithmetic
     conversions are performed. Values of complex types are equal if and only
     if both their real parts are equal and also their imaginary parts are
     equal. Any two values of arithmetic types from different type domains are
     equal if and only if the results of their conversions to the (complex)
     result type determined by the usual arithmetic conversions are equal.
     }*/
     
     rule tv(I1:Int, T:KResult) == tv(I2:Int, T:KResult)
          => makeTruth(I1:Int ==K I2:Int)
          when (
               isPromoted(T:KResult)
               orBool (isPointerType(T:KResult) andBool isConcreteNumber(I1:Int) andBool isConcreteNumber(I2:Int))
          ) andBool notBool (isUnknown(I1:Int) orBool isUnknown(I2:Int))
          [structural]
     rule tv(I1:Int, T:KResult) != tv(I2:Int, T:KResult)
          => makeTruth(I1:Int =/=K I2:Int)
          when (
               isPromoted(T:KResult)
               orBool (isPointerType(T:KResult) andBool isConcreteNumber(I1:Int) andBool isConcreteNumber(I2:Int))
          ) andBool notBool (isUnknown(I1:Int) orBool isUnknown(I2:Int))
          [structural]
          
     rule tv(F1:Float, T:KResult) == tv(F2:Float, T:KResult) => makeTruth(F1:Float ==Float F2:Float)
          [structural]
     rule tv(F1:Float, T:KResult) != tv(F2:Float, T:KResult) => makeTruth(F1:Float =/=Float F2:Float)
          [structural]
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.9}{5--7}}}{
     Otherwise, at least one operand is a pointer. If one operand is a pointer
     and the other is a null pointer constant, the null pointer constant is
     converted to the type of the pointer. If one operand is a pointer to an
     object type and the other is a pointer to a qualified or unqualified
     version of \cinline{void}, the former is converted to the type of the
     latter.

     Two pointers compare equal if and only if both are null pointers, both are
     pointers to the same object (imports a pointer to an object and a
     subobject at its beginning) or function, both are pointers to one past the
     last element of the same array object, or one is a pointer to one past the
     end of one array object and the other is a pointer to the start of a
     different array object that happens to immediately follow the first array
     object in the address space.

     For the purposes of these operators, a pointer to an object that is not an
     element of an array behaves the same as a pointer to the first element of
     an array of length one with the type of the object as its element type.
     }*/
     // if they're identical, we know for sure they are the same
     rule tv(N:Int, T:KResult) == tv(N:Int, T':KResult)
          => tv(1, t(.Set, int))
          when isPointerType(T:KResult) 
          andBool isPointerType(T':KResult)
          [structural]
     rule tv(N:Int, T:KResult) != tv(N:Int, T':KResult)
          => tv(0, t(.Set, int))
          when isPointerType(T:KResult) 
          andBool isPointerType(T':KResult)
          [structural]
     
     // if one of the pointers is null, it's also straightforward
     rule tv(NullPointer, T:KResult) == tv(N:Int, T':KResult)
          => makeTruth(NullPointer ==K N:Int)
          when isPointerType(T:KResult) 
          andBool isPointerType(T':KResult)
          [structural]
     rule tv(NullPointer, T:KResult) != tv(N:Int, T':KResult)
          => makeTruth(NullPointer =/=K N:Int)
          when isPointerType(T:KResult) 
          andBool isPointerType(T':KResult)
          [structural]
     rule tv(N:Int, T:KResult) == tv(NullPointer, T':KResult)
          => makeTruth(NullPointer ==K N:Int)
          when isPointerType(T:KResult) 
          andBool isPointerType(T':KResult)
          [structural]
     rule tv(N:Int, T:KResult) != tv(NullPointer, T':KResult)
          => makeTruth(NullPointer =/=K N:Int)
          when isPointerType(T:KResult) 
          andBool isPointerType(T':KResult)
          [structural]
          
     // otherwise, there are a number of cases.  
     // First, they are part of the same object        
     rule <k> tv(loc(Base:SymBase, Offset:Int, 0), T:KResult) == tv(loc(Base:SymBase, Offset':Int, 0), T':KResult) 
               => makeTruth(Offset:Int ==Int Offset':Int)
          ...</k>
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
     rule <k> tv(loc(Base:SymBase, Offset:Int, 0), T:KResult) != tv(loc(Base:SymBase, Offset':Int, 0), T':KResult) 
               => makeTruth(Offset:Int =/=Int Offset':Int)
          ...</k>
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
          
     // next, they are part of different objects.  
     // here, if the two objects are alive, and our pointers are in bounds, we
     // can conclude something.  if one of the objects is dead, we can't
     // conclude anything (the address could have been reused)
     rule [compare-eq-different-objects]: 
          <k> tv(loc(Base:SymBase, Offset:Int, 0), T:KResult) == tv(loc(Base':SymBase, Offset':Int, 0), T':KResult) 
               => tv(0, t(.Set, int))
          ...</k>
          <object>...
               <basePtr> Base </basePtr>
               <oLength> Len:Int </oLength>
          ...</object>
          <object>...
               <basePtr> Base' </basePtr>
               <oLength> Len':Int </oLength>
          ...</object>
          when (isPointerType(T:KResult) andBool isPointerType(T':KResult))
               andBool (Base =/=K Base')
               andBool (Offset:Int <Int Len:Int)
               andBool (Offset':Int <Int Len':Int)
          [structural]
     rule [compare-neq-different-objects]: 
          <k> tv(loc(Base:SymBase, Offset:Int, 0), T:KResult) != tv(loc(Base':SymBase, Offset':Int, 0), T':KResult) 
               => tv(1, t(.Set, int))
          ...</k>
          <object>...
               <basePtr> Base </basePtr>
               <oLength> Len:Int </oLength>
          ...</object>
          <object>...
               <basePtr> Base' </basePtr>
               <oLength> Len':Int </oLength>
          ...</object>
          when (isPointerType(T:KResult) andBool isPointerType(T':KResult))
               andBool (Base =/=K Base')
               andBool (Offset:Int <Int Len:Int)
               andBool (Offset':Int <Int Len':Int)
          [structural]
     
     // otherwise we can't conclude anything
          
     //- comparison of ints with pointers
     // fixme there are further restrictions on pointers
     rule [equal-null-left]:
          (tv(N:Int, T:KResult) => tv(NullPointer, T':KResult)) == tv(_, T':KResult)
          when (isPromoted(T:KResult))
               andBool (isPointerType(T':KResult))
               andBool (N:Int ==K NullPointerConstant)
          [structural]
     rule [equal-null-right]:
          tv(_, T:KResult) == (tv(N:Int, T':KResult) => tv(NullPointer, T:KResult))
          when isPointerType(T:KResult) 
               andBool isPromoted(T':KResult)
               andBool N:Int ==K NullPointerConstant
          [structural]
     
     rule [nequal-null-left]: 
          (tv(N:Int, T:KResult) => tv(NullPointer, T':KResult)) != tv(_, T':KResult)
          when isPromoted(T:KResult) 
               andBool isPointerType(T':KResult)
               andBool N:Int ==K NullPointerConstant
          [structural]
     rule [nequal-null-right]: 
          tv(_, T:KResult) != (tv(N:Int, T':KResult) => tv(NullPointer, T:KResult))
          when isPointerType(T:KResult) 
               andBool isPromoted(T':KResult)
               andBool N:Int ==K NullPointerConstant
          [structural]
endmodule

module DYNAMIC-SEMANTICS-BITWISE
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE                    

     /*@ \fromStandard{\source[n1570]{\para{6.5.10}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.
     
     The result of the binary \cinline{&} operator is the bitwise AND of the
     operands (that is, each bit in the result is set if and only if each of
     the corresponding bits in the converted operands is set).
     }*/
     rule tv(I1:Int, T:Type) & tv(I2:Int, T:Type) => arithInterpret(T, I1:Int &Int I2:Int)
          when isPromoted(T)
          [structural]
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.11}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.
     
     The result of the \cinline{^} operator is the bitwise exclusive OR of the
     operands (that is, each bit in the result is set if and only if exactly
     one of the corresponding bits in the converted operands is set).     
     }*/
     rule tv(I1:Int, T:Type) ^ tv(I2:Int, T:Type) => arithInterpret(T, I1:Int xorInt I2:Int)
          when isPromoted(T)
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.12}{3--4}}}{
     The usual arithmetic conversions are performed on the operands.
     
     The result of the \cinline{|} operator is the bitwise inclusive OR of the
     operands (that is, each bit in the result is set if and only if at least
     one of the corresponding bits in the converted operands is set).
     }*/
     rule tv(I1:Int, T:Type) | tv(I2:Int, T:Type) => arithInterpret(T, I1:Int |Int I2:Int)
          when isPromoted(T)
          [structural]
endmodule

module DYNAMIC-SEMANTICS-LOGICAL
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ Here, we wrapped the controlling expressions with
     \kinline{simplifyTruth} when heating them, so that we are guaranteed
     the values in those locations are either \kinline{tv(0, int)} or
     \kinline{tv(1, int)}.*/
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.13}{3--4}}}{
     The \cinline{&&} operator shall yield 1 if both of its operands compare
     unequal to 0; otherwise, it yields 0. The result has type \cinline{int}.
     
     Unlike the bitwise binary \cinline{&} operator, the \cinline{&&} operator
     guarantees left-to-right evaluation; if the second operand is evaluated,
     there is a sequence point between the evaluations of the first and second
     operands. If the first operand compares equal to 0, the second operand is
     not evaluated.
     } */ 
     rule <k> tv(0, t(_, int)) && E:K
               => tv(0, t(.Set, int))
          ...</k>
          [structural]
     rule <k> tv(1, t(_, int)) && E:K
               => sequencePoint
               ~> simplifyTruth(E:K)
          ...</k>
          [structural]
     rule <k> (V:KResult => simplifyTruth(V:KResult)) && _ ...</k>
          when isNotTruthValue(V:KResult)
          [structural]   
                    
     /*@ \fromStandard{\source[n1570]{\para{6.5.14}{3--4}}}{
     The \cinline{||} operator shall yield 1 if either of its operands compare
     unequal to 0; otherwise, it yields 0. The result has type \cinline{int}.

     Unlike the bitwise \cinline{|} operator, the \cinline{||} operator
     guarantees left-to-right evaluation; if the second operand is evaluated,
     there is a sequence point between the evaluations of the first and second
     operands. If the first operand compares unequal to 0, the second operand
     is not evaluated.
     }*/
     rule <k> tv(0, t(_, int)) || E:K
               => sequencePoint
               ~> simplifyTruth(E:K)
          ...</k>
          [structural]
     rule <k> tv(1, t(_, int)) || E:K
               => tv(1, t(.Set, int))
          ...</k>
          [structural]
     rule <k> (V:KResult => V:KResult != tv(0, t(.Set, int))) || _ ...</k>
          when isNotTruthValue(V:KResult)
          [structural]

endmodule

module DYNAMIC-SEMANTICS-CONDITIONAL-EXPRESSION
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE

     syntax K ::= "getTypes" "(" KList ")"
     syntax K ::= "types" "(" KList ")"
     context types((_,, HOLE,, _))
     syntax K ::= "convertedType" "(" K ")" [strict]
     
     rule <k> getTypes(L:KList) => types(wrapWithTypeOf(L:KList)) ...</k> [structural]
     
     syntax KList ::=  wrapWithTypeOf(KList) [function]
     rule wrapWithTypeOf((K:K,, L:KList)) => (retype(typeof(K:K)),, wrapWithTypeOf(L:KList))
     rule wrapWithTypeOf(.KList) => .KList
     
     syntax K ::= retype(K) [strict]
     
     // fixme, not handling qualifiers correctly
     rule retype(T:KResult) => t(.Set, pointerType(innerType(T:KResult)))
          when isArrayType(T:KResult)
          [structural]
     rule retype(T:KResult) => t(.Set, pointerType(T:KResult))
          when isFunctionType(T:KResult)
          [structural]
     rule retype(T:KResult) => T:KResult
          when notBool (isArrayType(T:KResult) orBool isFunctionType(T:KResult))
          [structural]   
     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{4}}}{
     The first operand is evaluated; there is a sequence point between its
     evaluation and the evaluation of the second or third operand (whichever is
     evaluated). The second operand is evaluated only if the first compares
     unequal to 0; the third operand is evaluated only if the first compares
     equal to 0; the result is the value of the second or third operand
     (whichever is evaluated), converted to the type described below.
     }*/  
     rule <k> (.K => getTypes((E1:K,, E2:K))) ~> E:K ? E1:K : E2:K ...</k>
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{5}}}{
     If both the second and third operands have arithmetic type, the result
     type that would be determined by the usual arithmetic conversions, were
     they applied to those two operands, is the type of the result. If both the
     operands have structure or union type, the result has that type. If both
     operands have void type, the result has void type.
     }*/
     rule <k> (types((T1:KResult,, T2:KResult)) => convertedType(usualArithmeticConversion(T1:KResult, T2:KResult)))
               ~> E:K ? E1:K : E2:K
          ...</k>
          when T1:KResult =/=K T2:KResult
          andBool isArithmeticType(T1:KResult)
          andBool isArithmeticType(T2:KResult)
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{6}}}{
     \broken{If both the second and third operands are pointers or one is a
     null pointer constant and the other is a pointer, the result type is a
     pointer to a type qualified with all the type qualifiers of the types
     referenced by both operands. Furthermore, if both operands are pointers to
     compatible types or to differently qualified versions of compatible types,
     the result type is a pointer to an appropriately qualified version of the
     composite type}; if one operand is a null pointer constant, the result has
     the type of the other operand; \broken{otherwise, one operand is a pointer
     to void or a qualified version of \cinline{void}, in which case the result
     type is a pointer to an appropriately qualified version of
     \cinline{void}.}
     }*/
     // fixme, this is too relaxed; could be any integer zero.  need static
     // semantics to handle this properly
     rule [conditional-left-is-null]:
          <k> (types((T1:KResult,, T2:KResult)) => convertedType(T2:KResult))
               ~> E:K ? tv(0, T1:KResult) : E2:K
          ...</k>
          when hasIntegerType(T1:KResult)
          andBool isPointerType(T2:KResult)
          [structural]
     rule [conditional-right-is-null]:
          <k> (types((T1:KResult,, T2:KResult)) => convertedType(T1:KResult))
               ~> E:K ? E1:K : tv(0, T2:KResult)
          ...</k>
          when hasIntegerType(T2:KResult)
          andBool isPointerType(T1:KResult)
          [structural]
          
     // fixme, this is wrong
     rule <k> (types((T1:KResult,, T2:KResult)) => convertedType(T1:KResult))
               ~> E:K ? E1:K : E2:K
          ...</k>
          when isPointerType(T1:KResult)
          andBool isPointerType(T2:KResult)
          [structural]
          
     // this should take care of the void/struct cases
     rule <k> (types((T:KResult,, T:KResult)) => convertedType(T:KResult))
               ~> E:K ? E1:K : E2:K
          ...</k>
          when notBool isPointerType(T:KResult)
          [structural]
     rule <k> convertedType(T:KResult) ~> E:K ? E1:K : E2:K
               => IfThenElse(E:K, cast(T:KResult, E1:K), cast(T:KResult, E2:K))
          ...</k>
          [structural]
endmodule

module DYNAMIC-SEMANTICS-ASSIGNMENT
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.16}{3}}}{
     An assignment operator stores a value in the object designated by the left
     operand. \broken{An assignment expression has the value of the left
     operand after the assignment}, but is not an lvalue. The type of an
     assignment expression is the type the left operand would have after lvalue
     conversion. The side effect of updating the stored value of the left
     operand is sequenced after the value computations of the left and right
     operands. The evaluations of the operands are unsequenced.
     }*/
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{2}}}{
     Insimple assignment (\cinline{=}), the value of the right operand is
     converted to the type of the assignment expression and replaces the value
     stored in the object designated by the left operand.
     }*/

     rule [assign]:
          <k> lv(Loc:SymLoc, T:Type) := tv(V:KList, T)
               => write(lv(Loc, T), tv(V, T))
               ~> tv(V, T)
          ...</k>
          [structural]
     rule [convert-for-assignment]:
          <k> lv(_, T:Type) := (tv(V:KList, T':KResult) 
               => cast(T, tv(V, T')))
          ...</k>
          when T =/=K T':KResult
          [structural]
     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{3}}}{
     \broken{If the value being stored in an object is read from another object
     that overlaps in any way the storage of the first object, then the overlap
     shall be exact and the two objects shall have qualified or unqualified
     versions of a compatible type; otherwise, the behavior is undefined.}
     }*/
     
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.16.2}{3}}}{
     Acompound assignment of the form \cinline{E1 op= E2} is equivalent to the
     simple assignment expression \cinline{E1 = E1 op (E2)}, except that the
     lvalue \cinline{E1} is evaluated only once, and with respect to an
     indeterminately-sequenced function call, the operation of a compound
     assignment is a single evaluation. If \cinline{E1} has an atomic type,
     compound assignment is a read-modify-write operation with
     \cinline{memory_order_seq_cst} memory order semantics.
     }*/
     syntax K ::= "compoundAssignment" "(" KLabel "," K "," K ")"
     // these should not be nd, in order to keep the operations together
     context compoundAssignment(_, (HOLE => peval(HOLE)), _)
     context compoundAssignment(_, _, (HOLE => reval(HOLE)))
          
     rule [compoundAssignment-mult]:
          <k> E1:K *= E2:K => compoundAssignment('_*_, E1:K, E2:K) ...</k>
          [structural]
     rule [compoundAssignment-div]:
          <k> E1:K /= E2:K => compoundAssignment('_/_, E1:K, E2:K) ...</k>
          [structural]
     rule [compoundAssignment-modulo]:
          <k> E1:K %= E2:K => compoundAssignment('_%_, E1:K, E2:K) ...</k>
          [structural]
     rule [compoundAssignment-plus]:
          <k> E1:K += E2:K => compoundAssignment('_+_, E1:K, E2:K) ...</k>
          [structural]
     rule [compoundAssignment-minus]:
          <k> E1:K -= E2:K => compoundAssignment('_-_, E1:K, E2:K) ...</k>
          [structural]
     rule [compoundAssignment-left-shift]:
          <k> E1:K <<= E2:K => compoundAssignment('_<<_, E1:K, E2:K) ...</k>
          [structural]
     rule [compoundAssignment-right-shift]:
          <k> E1:K >>= E2:K => compoundAssignment('_>>_, E1:K, E2:K) ...</k>
          [structural]
     rule [compoundAssignment-bitwise-and]:
          <k> E1:K &= E2:K => compoundAssignment('_&_, E1:K, E2:K) ...</k>
          [structural]
     rule [compoundAssignment-bitwise-xor]:
          <k> E1:K ^= E2:K => compoundAssignment('_^_, E1:K, E2:K) ...</k>
          [structural]
     rule [compoundAssignment-bitwise-or]:
          <k> E1:K |= E2:K => compoundAssignment('_|_, E1:K, E2:K) ...</k>
          [structural]

     rule <k> compoundAssignment(L:KLabel, V:KResult, V':KResult)
               => V:KResult := L:KLabel(reval(V:KResult),, V':KResult)
          ...</k>
          [structural]
endmodule

module DYNAMIC-SEMANTICS-SEQUENCING
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.17}{2}}}{
     The left operand of a comma operator is evaluated as a void expression;
     there is a sequence point between its evaluation and that of the right
     operand. Then the right operand is evaluated; the result has its type and
     value.
     }*/
     rule <k> Comma(klist((V:KResult,, K':K,, L:KList))) 
          => sequencePoint
          ~> Comma(klist((K':K,, L:KList))) ...</k>
          [structural]
     rule <k> Comma(klist(K:K)) => K:K ...</k>
          [structural]
endmodule

module DYNAMIC-C-EXPRESSIONS
     imports DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE

     imports DYNAMIC-SEMANTICS-COMPOUND-LITERAL
     imports DYNAMIC-SEMANTICS-LOGICAL
     imports DYNAMIC-SEMANTICS-CONDITIONAL-EXPRESSION
     imports DYNAMIC-SEMANTICS-SIZEOF
     imports DYNAMIC-SEMANTICS-IDENTIFIERS
     imports DYNAMIC-SEMANTICS-FUNCTION-CALLS
     imports DYNAMIC-SEMANTICS-ARRAY-SUBSCRIPTING
     imports DYNAMIC-SEMANTICS-CAST
     imports DYNAMIC-SEMANTICS-ASSIGNMENT
     imports DYNAMIC-SEMANTICS-LITERALS
     imports DYNAMIC-SEMANTICS-BITWISE
     imports DYNAMIC-SEMANTICS-BITWISE-SHIFT
     imports DYNAMIC-SEMANTICS-MULTIPLICATIVE-OPERATORS
     imports DYNAMIC-SEMANTICS-ADDITIVE-OPERATORS
     imports DYNAMIC-SEMANTICS-RELATIONAL
     imports DYNAMIC-SEMANTICS-EQUALITY
     imports DYNAMIC-SEMANTICS-UNARY-ARITHMETIC
     imports DYNAMIC-SEMANTICS-MEMBERS
     imports DYNAMIC-SEMANTICS-DEREFERENCE
     imports DYNAMIC-SEMANTICS-REFERENCE
     imports DYNAMIC-SEMANTICS-POSTFIX-INCREMENT-AND-DECREMENT
     imports DYNAMIC-SEMANTICS-PREFIX-INCREMENT-AND-DECREMENT
     imports DYNAMIC-SEMANTICS-SEQUENCING
endmodule
