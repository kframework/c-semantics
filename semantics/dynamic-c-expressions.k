kmod DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE is
	including DYNAMIC-INCLUDE
	op assign : K K -> K
	op compoundLiteral : #Nat -> #Id
	
	op lvGetOffset : K K Type -> K
	op tvGetOffset : K K Type -> K

	op fromArray : #Int #Nat -> K // offset, length
	
	declare arrayLength : KResult -> #Nat
	define arrayLength(t(_:Set, arrayType(_:KResult, N:#Nat))) => N:#Nat
	define arrayLength(t(_:Set, flexibleArrayType(_:KResult))) => 36893488147419103232 // need "infinity"
	define arrayLength(t(_:Set, incompleteArrayType(_:KResult))) => 36893488147419103232 // need "infinity"
	
	// fixme Whoah!  What about char types?  What is this about?
	// If the lvalue designates an object of automatic storage duration that could have been declared with the register storage class (never had its address taken), and that object is uninitialized (not declared with an initializer and no assignment to it has been performed prior to use), the behavior is undefined.
	
	
	rule [reval-skipval]: reval(skipval) => skipval [structural]
	rule [reval-emptyval]: reval(emptyValue) => emptyValue [structural]
	// rule [reval-tv-normal]: reval(tv(L:List{K}, T:KResult)) => tv(L:List{K}, T:KResult) if notBool hasArrayType(T:KResult) andBool notBool hasFunctionType(T:KResult) [structural]
	rule [reval-tv-normal]: reval(tv(L:List{K}, T:KResult)) => tv(L:List{K}, T:KResult) [structural] 
	// tvs can't be arrays or functions
	// rule [peval-tv-normal]: peval(tv(V:List{K}, T:KResult)) => tv(V:List{K}, T:KResult) if notBool hasArrayType(T:KResult) andBool notBool hasFunctionType(T:KResult) [structural]
	rule [peval-tv-normal]: peval(tv(V:List{K}, T:KResult)) => tv(V:List{K}, T:KResult) [structural]
	
	/*@ \source[n1570]{\para{6.3.2.1}{2}}
	Except when it is the operand of the \cinline{sizeof} operator, the \cinline{_Alignof} operator, the unary \cinline{&} operator, the \cinline{++} operator, the \cinline{--} operator, or the left operand of the \cinline{.} operator or an assignment operator, an lvalue that does not have an array type is converted to the value stored in the designated object (and is no longer an lvalue); this is called lvalue conversion.  If the lvalue has qualified type, the value has the unqualified version of the type of the lvalue; additionally, if the lvalue has atomic type, the value has the non-atomic version of the type of the lvalue; otherwise, the value has the type of the lvalue. \ldots
	*/
	rule reval(lv(Loc:#Nat, T:KResult)) => read(Loc:#Nat, unqualifyType(T:KResult)) 
		when notBool hasArrayType(T:KResult) andBool notBool hasFunctionType(T:KResult) 
		[structural]
	rule peval(lv(Loc:#Nat, T:KResult)) => lv(Loc:#Nat, T:KResult) 
		when notBool hasArrayType(T:KResult) andBool notBool hasFunctionType(T:KResult) 
		[structural]

	
	/*@ \source[n1570]{\para{6.3.2.1}{3}}
	Except when it is the operand of the \cinline{sizeof} operator, the \cinline{_Alignof} operator, or the unary \cinline{&} operator, or is a string literal used to initialize an array, an expression that has type ``array of type'' is converted to an expression with type ``pointer to type'' that points to the initial element of the array object and is not an lvalue. If the array object has register storage class, the behavior is undefined.
	*/
	rule [reval-lv-array]: reval(lv(Loc:#Nat, T:KResult)) => tv(Loc:#Nat, t(SetItem(fromArray(0, arrayLength(T:KResult))), pointerType(innerType(T:KResult))))
		when hasArrayType(T:KResult) 
		[structural]
	rule [peval-lv-array]: peval(lv(Loc:#Nat, T:KResult)) => tv(Loc:#Nat, t(SetItem(fromArray(0, arrayLength(T:KResult))), pointerType(innerType(T:KResult))))
		when hasArrayType(T:KResult) 
		[structural]
	// should never get to the situation where we have tv(..., arrayType)
	
	
	/*@ \source[n1570]{\para{6.3.2.1}{4}}
	A function designator is an expression that has function type.  Except when it is the operand of the \cinline{sizeof} operator, the \cinline{_Alignof} operator, or the unary \cinline{&} operator, a function designator with type ``function returning T'' is converted to an expression that has type ``pointer to a function returning T''.
	*/
	rule [reval-function]: 
		reval(lv(Loc:#Nat, T:KResult)) => tv(Loc:#Nat, t(.Set, pointerType(T:KResult))) 
		when hasFunctionType(T:KResult) 
		[structural]
	rule [peval-function]: 
		peval(lv(Loc:#Nat, T:KResult)) => tv(Loc:#Nat, t(.Set, pointerType(T:KResult))) 
		when hasFunctionType(T:KResult) 
	[structural]
	
endkm

kmod DYNAMIC-SEMANTICS-COMPOUND-LITERAL is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	op handleCompoundLiteral : K -> K [metadata "strict=()"]
	
	/*@ \source[n1570]{\para{6.5.2.5}{3}}
	A postfix expression that consists of a parenthesized type name followed by a brace-enclosed list of initializers is a compound literal. It provides an unnamed object whose value is given by the initializer list.
	*/
	
	/*@ We use \kinline{compoundLiteral(N:#Nat)} here as the identifier of the compound literal.
	*/
	// comes back from figureInit as initializerValue(id, type, inits)
	rule
		< k > CompoundLiteral(N:#Nat, T:KResult, K:K, Init:K)
			=> handleCompoundLiteral(figureInitializer(compoundLiteral(N:#Nat), DeclType(T:KResult, K:K), Init:K))
		...</ k >
		[structural]
		
	rule
		< k > handleCompoundLiteral(initializerValue(X:#Id, T:KResult, Init:K))
			=> allocateType(Loc:#Nat, T:KResult)
			~> addToEnv(X:#Id, Loc:#Nat)
			~> giveType(X:#Id, T:KResult)
			~> initialize(X:#Id, T:KResult, Init:K)
			~> X:#Id
		...</ k >
		< compoundLiteralMap > M:Map => M:Map[Loc:#Nat / X:#Id] </ compoundLiteralMap >
		< nextLoc > Loc:#Nat => inc(Loc:#Nat) </ nextLoc >
		when notBool $hasMapping(M:Map, X:#Id)
		[structural]
		
	rule
		< k > handleCompoundLiteral(initializerValue(X:#Id, T:KResult, Init:K))
			=> addToEnv(X:#Id, Loc:#Nat)
			~> giveType(X:#Id, T:KResult)
			~> initialize(X:#Id, T:KResult, Init:K)
			~> X:#Id
		...</ k >
		< compoundLiteralMap >... X:#Id |-> Loc:#Nat ...</ compoundLiteralMap >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-BOOLEAN is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/* Here, we wrapped the controlling expressions with \kinline{simplifyTruth} when heating them, so that we are guaranteed the values in those locations are either \kinline{tv(0, int)} or \kinline{tv(1, int)}.
	*/
	
		
	/*@ \source[n1570]{\para{6.5.13}{3--4}}
	The \cinline{&&} operator shall yield 1 if both of its operands compare unequal to 0; otherwise, it yields 0. The result has type \cinline{int}.
	
	Unlike the bitwise binary \cinline{&} operator, the \cinline{&&} operator guarantees left-to-right evaluation; if the second operand is evaluated, there is a sequence point between the evaluations of the first and second operands. If the first operand compares equal to 0, the second operand is not evaluated.
	*/	
	rule
		< k > tv(0, t(_, int)) && E:K
			=> tv(0, t(.Set, int))
		...</ k >
		[structural]
	rule
		< k > tv(1, t(_, int)) && E:K
			=> sequencePoint
			~> simplifyTruth(E:K)
		...</ k >
		[structural]
	rule
		< k > (V:KResult => simplifyTruth(V:KResult)) && _ ...</ k >
		when isNotTruthValue(V:KResult)
		[structural]	
				
	/*@ \source[n1570]{\para{6.5.14}{3--4}}
	The \cinline{||} operator shall yield 1 if either of its operands compare unequal to 0; otherwise, it yields 0. The result has type \cinline{int}.

	Unlike the bitwise \cinline{|} operator, the \cinline{||} operator guarantees left-to-right evaluation; if the second operand is evaluated, there is a sequence point between the evaluations of the first and second operands. If the first operand compares unequal to 0, the second operand is not evaluated.
	*/
	rule
		< k > tv(0, t(_, int)) || E:K
			=> sequencePoint
			~> simplifyTruth(E:K)
		...</ k >
		[structural]
	rule
		< k > tv(1, t(_, int)) || E:K
			=> tv(1, t(.Set, int))
		...</ k >
		[structural]
	rule
		< k > (V:KResult => V:KResult != tv(0, t(.Set, int))) || _ ...</ k >
		when isNotTruthValue(V:KResult)
		[structural]

	
	/*@ \source[n1570]{\para{6.5.3.3}{5}}
	The result of the logical negation operator \cinline{!} is 0 if the value of its operand compares unequal to 0, 1 if the value of its operand compares equal to 0. The result has type \cinline{int}.  The expression \cinline{!E} is equivalent to \cinline{(0==E)}.
	*/
	rule !(E:K) => tv(0, t(.Set, int)) == E:K
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-CONDITIONAL-EXPRESSION is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE

	op getTypes : List{K} -> K
	op types : List{K} -> K
	context types((_,, HOLE,, _))
	op convertedType : K -> K [metadata "strict=()"]
	
	rule < k > getTypes(L:List{K}) => types(wrapWithTypeOf(L:List{K})) ...</ k > [structural]
	
	declare wrapWithTypeOf : List{K} -> List{K}
	define wrapWithTypeOf((K:K,, L:List{K})) => (retype(typeof(K:K)),, wrapWithTypeOf(L:List{K})) [structural]
	define wrapWithTypeOf(.List{K}) => .List{K} [structural]
	
	declare retype : K -> K [metadata "strict=()"]
	
	// fixme, not handling qualifiers correctly
	define
		retype(T:KResult) => t(.Set, pointerType(innerType(T:KResult)))
		when hasArrayType(T:KResult)
		[structural]
	define
		retype(T:KResult) => t(.Set, pointerType(T:KResult))
		when hasFunctionType(T:KResult)
		[structural]
	define
		retype(T:KResult) => T:KResult
		when notBool (hasArrayType(T:KResult) orBool hasFunctionType(T:KResult))
		[structural]	
	/*@ \source[n1570]{\para{6.5.15}{4}}
	The first operand is evaluated; there is a sequence point between its evaluation and the evaluation of the second or third operand (whichever is evaluated). The second operand is evaluated only if the first compares unequal to 0; the third operand is evaluated only if the first compares equal to 0; the result is the value of the second or third operand (whichever is evaluated), converted to the type described below.
	*/

	
	rule
		< k > (.K => getTypes((E1:K,, E2:K))) ~> E:K ? E1:K : E2:K ...</ k >
		[structural]
		
	/*@ \source[n1570]{\para{6.5.15}{5}}
	If both the second and third operands have arithmetic type, the result type that would be determined by the usual arithmetic conversions, were they applied to those two operands, is the type of the result. If both the operands have structure or union type, the result has that type. If both operands have void type, the result has void type.
	*/
	rule
		< k > (types((T1:KResult,, T2:KResult)) => convertedType(usualArithmeticConversion(T1:KResult, T2:KResult)))
			~> E:K ? E1:K : E2:K
		...</ k >
		when T1:KResult =/=Bool T2:KResult
		andBool hasArithmeticType(T1:KResult)
		andBool hasArithmeticType(T2:KResult)
		[structural]
		
	/*@ \source[n1570]{\para{6.5.15}{6}}
	\broken{If both the second and third operands are pointers or one is a null pointer constant and the other is a pointer, the result type is a pointer to a type qualified with all the type qualifiers of the types referenced by both operands. Furthermore, if both operands are pointers to compatible types or to differently qualified versions of compatible types, the result type is a pointer to an appropriately qualified version of the composite type}; if one operand is a null pointer constant, the result has the type of the other operand; \broken{otherwise, one operand is a pointer to void or a qualified version of void, in which case the result type is a pointer to an appropriately qualified version of void.}
	*/
	// fixme, this is too relaxed; could be any integer zero.  need static semantics to handle this properly
	rule [conditional-left-is-null]:
		< k > (types((T1:KResult,, T2:KResult)) => convertedType(T2:KResult))
			~> E:K ? tv(0, T1:KResult) : E2:K
		...</ k >
		when hasIntegerType(T1:KResult)
		andBool hasPointerType(T2:KResult)
		[structural]
	rule [conditional-right-is-null]:
		< k > (types((T1:KResult,, T2:KResult)) => convertedType(T1:KResult))
			~> E:K ? E1:K : tv(0, T2:KResult)
		...</ k >
		when hasIntegerType(T2:KResult)
		andBool hasPointerType(T1:KResult)
		[structural]
		
	// fixme, this is wrong
	rule
		< k > (types((T1:KResult,, T2:KResult)) => convertedType(T1:KResult))
			~> E:K ? E1:K : E2:K
		...</ k >
		when hasPointerType(T1:KResult)
		andBool hasPointerType(T2:KResult)
		[structural]
		
	// this should take care of the void/struct cases
	rule
		< k > (types((T:KResult,, T:KResult)) => convertedType(T:KResult))
			~> E:K ? E1:K : E2:K
		...</ k >
		when notBool hasPointerType(T:KResult)
		[structural]
	rule
		< k > convertedType(T:KResult) ~> E:K ? E1:K : E2:K
			=> IfThenElse(E:K, cast(T:KResult, E1:K), cast(T:KResult, E2:K))
		...</ k >
		[structural]
		
endkm

kmod DYNAMIC-SEMANTICS-SIZEOF is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.3.4}{2}}
	The \cinline{sizeof} operator yields the size (in bytes) of its operand, which may be an expression or the parenthesized name of a type. The size is determined from the type of the operand. The result is an integer. If the type of the operand is a variable length array type, the operand is evaluated; otherwise, the operand is not evaluated and the result is an integer constant.
	*/
	
	rule sizeofType(T:KResult) => cast(cfg:sizeut, byteSizeofType(T:KResult)) [structural]
	op byteSizeofType-aux : K -> K [metadata "strict=()"]
	rule byteSizeofType(T:KResult) => byteSizeofType-aux(bitSizeofType(T:KResult)) [structural]
	rule byteSizeofType-aux(tv(N:#Nat, T:KResult)) => tv(bitsToBytes(N:#Nat), T:KResult)
		//if T:KResult ==Bool cfg:largestUnsigned
		[structural]
	rule
		< k > SizeofExpression(E:K) => sizeofType(typeof(E:K)) ...</ k >
		[structural]
	rule
		< k > SizeofType(T:KResult, K:K) => sizeofType(DeclType(T:KResult, K:K)) ...</ k >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-IDENTIFIERS is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.1}{2}}
	An identifier is a primary expression, provided it has been declared as designating an object (in which case it is an lvalue) or a function (in which case it is a function designator).
	*/
	rule [lookup]:
		< k > X:#Id => lv(Loc:#Nat, T:KResult) ...</ k >
		< env >... X:#Id |-> Loc:#Nat ...</ env >
		< types >... X:#Id |-> T:KResult ...</ types >
		[structural]
		
	rule [lookup-builtin-function-notfound]:
		< k > (.K 
				=> addToEnv(X:#Id, Loc:#Nat)
				~> initFunction(
					tv(Loc:#Nat, t(.Set, pointerType(T:KResult))),
					functionPrototype(X:#Id, T:KResult)
				)
			)
			~> X:#Id
		...</ k >
		< env > Env:Map </ env >
		< types >... X:#Id |-> T:KResult ...</ types >
		< nextLoc > Loc:#Nat => inc(Loc:#Nat) </ nextLoc >
		when hasFunctionType(T:KResult)
		andBool notBool $hasMapping(Env:Map, X:#Id)
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-FUNCTION-CALLS is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE

	op application : K List{KResult} -> K [metadata "strict=(1)"]
	/*@ \source[n1570]{\para{6.5.2.2}{3}}
	A postfix expression followed by parentheses \cinline{()} containing a possibly empty, comma-separated list of expressions is a function call. The postfix expression denotes the called function. The list of expressions specifies the arguments to the function.
	*/
	
	/*@ \source[n1570]{\para{6.5.2.2}{6}}
	\broken{If the expression that denotes the called function has a type that does not include a prototype, the integer promotions are performed on each argument, and arguments that have type float are promoted to double. These are called the default argument promotions. If the number of arguments does not equal the number of parameters, the behavior is undefined. If the function is defined with a type that includes a prototype, and either the prototype ends with an ellipsis (\cinline{, ...}) or the types of the arguments after promotion are not compatible with the types of the parameters, the behavior is undefined. If the function is defined with a type that does not include a prototype, and the types of the arguments after promotion are not compatible with those of the parameters after promotion, the behavior is undefined, except for the following cases: 
	\begin{itemize}
	\item one promoted type is a signed integer type, the other promoted type is the corresponding unsigned integer type, and the value is representable in both types;
	\item both types are pointers to qualified or unqualified versions of a character type or void.
	\end{itemize}
	}
	*/
	
	rule [function-application-pre]:
		< k > Call(tv(Loc:#Nat, t(_, pointerType(T:KResult))), List(L:List{KResult}))
			=> application(readFunction(Loc:#Nat), L:List{KResult})
		...</ k >
		when hasFunctionType(T:KResult)
		[structural]

	rule [populateFromGlobal]:
		< k > populateFromGlobal => .K ...</ k >
		< genv >... Tu:K |-> Map(G:Map) ...</ genv > < env > _ => G:Map </ env >
		< gtypes >... Tu:K |-> Map(GT:Map) ...</ gtypes > < types > _ => GT:Map </ types >
		< gstructs > GS:Map </ gstructs > < structs > _ => GS:Map </ structs >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		[structural]

	rule [builtin-application]:
		< k > application(functionPrototype(X:#Id, T:KResult), L:List{KResult})
			=> application(functionObject(X:#Id, T:KResult, handleBuiltin(X:#Id, T:KResult)), L:List{KResult})
		...</ k >
		[structural]
		
	rule [function-application]:
		< k > application(functionObject(X:#Id, t(_, functionType(R:KResult, P:List{KResult})), B:K), L:List{KResult}) ~> K:K 
			=> sequencePoint
			~> populateFromGlobal
			~> bind(L:List{KResult}, P:List{KResult})
			~> B:K
		</ k >
		< callStack > .List => ListItem(
			< stackFrame > C:Bag
				< continuation > K:K </ continuation >
				< currentTranslationUnit > OldTu:K </ currentTranslationUnit >
				< stackCurrentFunction > CurrFun:K </ stackCurrentFunction >
				< stackCurrentProgramLoc > CurrLoc:K </ stackCurrentProgramLoc >
			</ stackFrame >
		) ...</ callStack >
		@latex("\\kBR")
		(< control >
			< currentTranslationUnit > OldTu:K </ currentTranslationUnit >
			< currentFunction > CurrFun:K </ currentFunction >
			< currentProgramLoc > CurrLoc:K </ currentProgramLoc >
			C:Bag
		</ control >
		=>
		< control >
			< currentFunction > X:#Id </ currentFunction >
			< currentTranslationUnit > Tu:K </ currentTranslationUnit >
			< currentProgramLoc > CurrLoc:K </ currentProgramLoc >
		...</ control >)
		< functionTranslationUnits >... OldTu:K |-> Map((_ X:#Id |-> Tu:K)) ...</ functionTranslationUnits >
		[structural large]
endkm

kmod DYNAMIC-SEMANTICS-ARRAY-SUBSCRIPTING is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.2.1}{2}}
	A postfix expression followed by an expression in square brackets \cinline{[]} is a subscripted designation of an element of an array object. The definition of the subscript operator \cinline{[]} is that \cinline{E1[E2]} is identical to \cinline{(*((E1)+(E2)))}. Because of the conversion rules that apply to the binary \cinline{+} operator, if \cinline{E1} is an array object (equivalently, a pointer to the initial element of an array object) and \cinline{E2} is an integer, \cinline{E1[E2]} designates the \cinline{E2}-th element of \cinline{E1} (counting from zero).
	*/
	// op subscript : K K K K -> K [metadata "strict=(3 4)"]
	rule [array-subscript]:
		< k > E1:K[E2:K]
			=> *(E1:K + E2:K) 
		...</ k >
		[structural]
	// rule [array-subscript]:
		// < k > E1:K[E2:K]
			// => subscript(E1:K, E2:K, typeof(E1:K), typeof(E2:K))
		// ...</ k >
		// [structural]
	// rule [array-subscript-aux]:
		// < k > subscript(E1:K, E2:K, typeof(E1:K))
			// => 
		// ...</ k >
		// [structural]
endkm

kmod DYNAMIC-SEMANTICS-LITERALS is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	// here we start with a local address, put the string in memory, then change the address to be readonly
	
	rule [const-string-notfound]:
		< k > (.K => allocString(Loc:#Nat, S:#String +String "\0"))
			~> Constant(StringLiteral(S:#String))
		...</ k >
		< nextSharedLoc > Loc:#Nat => inc(Loc:#Nat) </ nextSharedLoc >
		< stringLiterals >
			M:Map
			(.Map => S:#String |-> lv(Loc:#Nat, t(.Set, arrayType(t(.Set, char), lengthString(S:#String) +Nat 1))))
		</ stringLiterals >
		when notBool($hasMapping(M:Map, S:#String))
		[structural]
		
	op wstring : List{K} -> K 
	rule [const-wstring-notfound]:
		< k > (.K => allocWString(Loc:#Nat, (S:List{K},, 0)))
			~> Constant(WStringLiteral(S:List{K}))
		...</ k >
		< nextSharedLoc > Loc:#Nat => inc(Loc:#Nat) </ nextSharedLoc >
		< stringLiterals >
			M:Map
			(.Map => wstring(S:List{K}) |-> lv(Loc:#Nat, t(.Set, arrayType(cfg:wcharut, lengthList{K}(S:List{K}) +Nat 1))))
		</ stringLiterals >
		when notBool($hasMapping(M:Map, wstring(S:List{K})))
		[structural]
		
	rule [const-string-found]:
		< k > Constant(StringLiteral(S:#String)) => V:KResult ...</ k >
		< stringLiterals >... S:#String |-> V:KResult ...</ stringLiterals >
		[structural]
	rule [const-wstring-found]:
		< k > Constant(WStringLiteral(S:List{K})) => V:KResult ...</ k >
		< stringLiterals >... wstring(S:List{K}) |-> V:KResult ...</ stringLiterals >
		[structural]
	
	/*@ \source[n1570]{\para{6.4.4.1}{5}}
	The type of an integer constant is the first of the corresponding list in which its value can be represented.
\begin{tabular}{@{}lll@{}}
\toprule
Suffix		&	Decimal Constant	&		Octal or Hexadecimal Constant  \\
\midrule
none	&		\cinline{int}						&	\cinline{int} \\
		&		\cinline{long int}				&	\cinline{unsigned int} \\
		&		\cinline{long long int}			&	\cinline{long int} \\
		&								&	\cinline{unsigned long int} \\
		&								&	\cinline{long long int} \\
		&								&	\cinline{unsigned long long int} \\
\midrule
\cinline{u} or \cinline{U}	&		\cinline{unsigned int} 			&	\cinline{unsigned int} \\
		&		\cinline{unsigned long int} 		&	\cinline{unsigned long int} \\
		&		\cinline{unsigned long long int} 	&	\cinline{unsigned long long int} \\
\midrule
\cinline{l} or \cinline{L}	&		\cinline{long int} 				&	\cinline{long int} \\
		&		\cinline{long long int} 			&	\cinline{unsigned long int} \\
		&								&	\cinline{long long int} \\
		&								&	\cinline{unsigned long long int} \\
\midrule
Both \cinline{u} or \cinline{U} and \cinline{l} or \cinline{L}	&	\cinline{unsigned long int} 		&	\cinline{unsigned long int} \\
						&	\cinline{unsigned long long int} 	&	\cinline{unsigned long long int} \\
\midrule
\cinline{ll} or \cinline{LL} 	&	\cinline{long long int}			&	\cinline{long long int} \\
			&							&	\cinline{unsigned long long int} \\
\midrule
Both \cinline{u} or \cinline{U} and \cinline{ll} or \cinline{LL}	&	\cinline{unsigned long long int} 	&	\cinline{unsigned long long int} \\
\bottomrule
\end{tabular}
*/
	/*@ \source[n1570]{\para{6.4.4.1}{6}}
	If an integer constant cannot be represented by any type in its list, it may have an extended integer type, if the extended integer type can represent its value. If all of the types in the list for the constant are signed, the extended integer type shall be signed. If all of the types in the list for the constant are unsigned, the extended integer type shall be unsigned. If the list contains both signed and unsigned types, the extended integer type may be signed or unsigned. If an integer constant cannot be represented by any type in its list and has no extended integer type, then the integer constant has no type.
	*/
	
	
	/*@ \source[n1570]{\para{6.4.4.4}{10}}
	An integer character constant has type \cinline{int}. The value of an integer character constant containing a single character that maps to a single-byte execution character is the numerical value of the representation of the mapped character interpreted as an integer. The value of an integer character constant containing more than one character (e.g., \cinline{'ab'}), or containing a character or escape sequence that does not map to a single-byte execution character, is implementation-defined. If an integer character constant contains a single character or escape sequence, its value is the one that results when an object with type \cinline{char} whose value is that of the single character or escape sequence is converted to type \cinline{int}.
	*/
	// c1x 6.4.4.4:10
	rule CharLiteral(N:#Nat) 
		=> cast(t(.Set, int), cast(t(.Set, char), tv(N:#Nat, t(.Set, int))))
		[structural anywhere]
	rule WCharLiteral(N:#Nat) => tv(N:#Nat, cfg:wcharut) [structural anywhere]
	rule Constant(V:KResult) => V:KResult [structural anywhere]
	rule [create-internal-value]: < k > N:#Nat => tv(N:#Nat, cfg:largestUnsigned) ...</ k >
		[structural] // for internal computations
		
	declare withinRange : #Int SimpleType -> #Bool
	define withinRange(I:#Int, T:K) => (I:#Int <=Int max(t(.Set, T:K))) andBool (I:#Int >=Int min(t(.Set, T:K))) [structural]
	
	rule NoSuffix(DecimalConstant(I:#Int)) =>
		if withinRange(I:#Int, int) then tv(I:#Int, t(.Set, int)) else
		if withinRange(I:#Int, long-int) then tv(I:#Int, t(.Set, long-int)) else
		if withinRange(I:#Int, long-long-int) then tv(I:#Int, t(.Set, long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi fi fi
		[structural anywhere]
		
	declare simplifyForHex : #String -> #String
	define simplifyForHex(S:#String) => simplifyForHex(butFirstChar(S:#String))
		when firstChar(S:#String) ==Bool "0"
		andBool lengthString(S:#String) >Nat 1
		[structural]
	define simplifyForHex(S:#String) => S:#String
		when firstChar(S:#String) =/=Bool "0"
		orBool lengthString(S:#String) ==Bool 1
		[structural]
		
		
	op hexOrOctalConstant : K -> K
	rule HexConstant(S:#String) => hexOrOctalConstant(String2Rat(simplifyForHex(S:#String), 16)) [structural anywhere]
	rule OctalConstant(N:#Nat) => hexOrOctalConstant(truncRat(String2Rat(Rat2String(N:#Nat, 10), 8))) [structural anywhere] // truncRat is just for sorts
	
	rule NoSuffix(hexOrOctalConstant(I:#Int)) =>
		if withinRange(I:#Int, int) then tv(I:#Int, t(.Set, int)) else
		if withinRange(I:#Int, unsigned-int) then tv(I:#Int, t(.Set, unsigned-int)) else
		if withinRange(I:#Int, long-int) then tv(I:#Int, t(.Set, long-int)) else
		if withinRange(I:#Int, unsigned-long-int) then tv(I:#Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:#Int, long-long-int) then tv(I:#Int, t(.Set, long-long-int)) else
		if withinRange(I:#Int, unsigned-long-long-int) then tv(I:#Int, t(.Set, unsigned-long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi fi fi fi fi fi
		[structural anywhere]

	rule U(hexOrOctalConstant(I:#Int)) =>
		if withinRange(I:#Int, unsigned-int) then tv(I:#Int, t(.Set, unsigned-int)) else
		if withinRange(I:#Int, unsigned-long-int) then tv(I:#Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:#Int, unsigned-long-long-int) then tv(I:#Int, t(.Set, unsigned-long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi fi fi
		[structural anywhere]
		
	rule L(hexOrOctalConstant(I:#Int)) =>
		if withinRange(I:#Int, long-int) then tv(I:#Int, t(.Set, long-int)) else
		if withinRange(I:#Int, unsigned-long-int) then tv(I:#Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:#Int, long-long-int) then tv(I:#Int, t(.Set, long-long-int)) else
		if withinRange(I:#Int, unsigned-long-long-int) then tv(I:#Int, t(.Set, unsigned-long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi fi fi fi
		[structural anywhere]
		
	rule UL(hexOrOctalConstant(I:#Int)) =>
		if withinRange(I:#Int, unsigned-long-int) then tv(I:#Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:#Int, unsigned-long-long-int) then tv(I:#Int, t(.Set, unsigned-long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi fi
		[structural anywhere]
		
	rule LL(hexOrOctalConstant(I:#Int)) =>
		if withinRange(I:#Int, long-long-int) then tv(I:#Int, t(.Set, long-long-int)) else
		if withinRange(I:#Int, unsigned-long-long-int) then tv(I:#Int, t(.Set, unsigned-long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi fi
		[structural anywhere]
	
	rule ULL(hexOrOctalConstant(I:#Int)) =>
		if withinRange(I:#Int, unsigned-long-long-int) then tv(I:#Int, t(.Set, unsigned-long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi
		[structural anywhere]
		
		
	rule U(DecimalConstant(I:#Int)) =>
		if withinRange(I:#Int, unsigned-int) then tv(I:#Int, t(.Set, unsigned-int)) else
		if withinRange(I:#Int, unsigned-long-int) then tv(I:#Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:#Int, unsigned-long-long-int) then tv(I:#Int, t(.Set, unsigned-long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi fi fi
		[structural anywhere]
	rule L(DecimalConstant(I:#Int)) =>
		if withinRange(I:#Int, long-int) then tv(I:#Int, t(.Set, long-int)) else
		if withinRange(I:#Int, long-long-int) then tv(I:#Int, t(.Set, long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi fi
		[structural anywhere]
	rule UL(DecimalConstant(I:#Int)) =>
		if withinRange(I:#Int, unsigned-long-int) then tv(I:#Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:#Int, unsigned-long-long-int) then tv(I:#Int, t(.Set, unsigned-long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi fi		
		[structural anywhere]
	rule LL(DecimalConstant(I:#Int)) =>
		if withinRange(I:#Int, long-long-int) then tv(I:#Int, t(.Set, long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi
		[structural anywhere]
	rule ULL(DecimalConstant(I:#Int)) =>
		if withinRange(I:#Int, unsigned-long-long-int) then tv(I:#Int, t(.Set, unsigned-long-long-int)) else
			tv(I:#Int, t(.Set, no-type))
		fi
		[structural anywhere]
	
	/*@ \source[n1570]{\para{6.4.4.2}{4}}
	An unsuffixed floating constant has type \cinline{double}. If suffixed by the letter \cinline{f} or \cinline{F}, it has type \cinline{float}. If suffixed by the letter \cinline{l} or \cinline{L}, it has type \cinline{long double}.
	*/
	
	op reducedFloat : #Float -> K
	rule DecimalFloatConstant(_:#String, _:#Int, F:#Float) => reducedFloat(F:#Float) [structural anywhere]
	rule HexFloatConstant(_:#String, _:#Int, F:#Float) => reducedFloat(F:#Float) [structural anywhere]
	
	rule NoSuffix(reducedFloat(F:#Float)) => tv(F:#Float, t(.Set, double))
		[structural anywhere]
	rule L(reducedFloat(F:#Float)) => tv(F:#Float, t(.Set, long-double))
		[structural anywhere]
	rule F(reducedFloat(F:#Float)) => tv(F:#Float, t(.Set, float))
		[structural anywhere]

endkm

kmod DYNAMIC-SEMANTICS-ASSIGNMENT is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.16}{3}}
	An assignment operator stores a value in the object designated by the left operand. \broken{An assignment expression has the value of the left operand after the assignment}, but is not an lvalue. The type of an assignment expression is the type the left operand would have after lvalue conversion. The side effect of updating the stored value of the left operand is sequenced after the value computations of the left and right operands. The evaluations of the operands are unsequenced.
	*/
		
	/*@ \source[n1570]{\para{6.5.16.1}{2}}
	Insimple assignment (\cinline{=}), the value of the right operand is converted to the type of the assignment expression and replaces the value stored in the object designated by the left operand.
	*/
	rule [assign]:
		< k > lv(Loc:#Nat, T:KResult) := RHS
			=> write(lv(Loc:#Nat, T:KResult), RHS)
			~> RHS
		...</ k >
		where RHS = tv(V:List{K}, T:KResult)
		[structural]
	rule [convert-for-assignment]:
		< k >
			lv(_, T:KResult)
			:=
			(tv(V:List{K}, T':KResult) => cast(T:KResult, tv(V:List{K}, T':KResult)))
		...</ k >
		when T:KResult =/=Bool T':KResult
		[structural]
	/*@ \source[n1570]{\para{6.5.16.1}{3}}
	\broken{If the value being stored in an object is read from another object that overlaps in any way the storage of the first object, then the overlap shall be exact and the two objects shall have qualified or unqualified versions of a compatible type; otherwise, the behavior is undefined.}
	*/
	
	
	/*@ \source[n1570]{\para{6.5.16.2}{3}}
	Acompound assignment of the form \cinline{E1 op= E2} is equivalent to the simple assignment expression \cinline{E1 = E1 op (E2)}, except that the lvalue \cinline{E1} is evaluated only once, and with respect to an indeterminately-sequenced function call, the operation of a compound assignment is a single evaluation. If \cinline{E1} has an atomic type, compound assignment is a read-modify-write operation with \cinline{memory_order_seq_cst} memory order semantics.
	*/
	op compoundAssignment : KLabel K K -> K
	// these should not be nd, in order to keep the operations together
	context compoundAssignment(_, (HOLE => peval(HOLE)), _)
	context compoundAssignment(_, _, (HOLE => reval(HOLE)))
		
	rule [compoundAssignment-mult]:
		< k > E1:K *= E2:K => compoundAssignment('_*_, E1:K, E2:K) ...</ k >
		[structural]
	rule [compoundAssignment-div]:
		< k > E1:K /= E2:K => compoundAssignment('_/_, E1:K, E2:K) ...</ k >
		[structural]
	rule [compoundAssignment-modulo]:
		< k > E1:K %= E2:K => compoundAssignment('_%_, E1:K, E2:K) ...</ k >
		[structural]
	rule [compoundAssignment-plus]:
		< k > E1:K += E2:K => compoundAssignment('_+_, E1:K, E2:K) ...</ k >
		[structural]
	rule [compoundAssignment-minus]:
		< k > E1:K -= E2:K => compoundAssignment('_-_, E1:K, E2:K) ...</ k >
		[structural]
	rule [compoundAssignment-left-shift]:
		< k > E1:K <<= E2:K => compoundAssignment('_<<_, E1:K, E2:K) ...</ k >
		[structural]
	rule [compoundAssignment-right-shift]:
		< k > E1:K >>= E2:K => compoundAssignment('_>>_, E1:K, E2:K) ...</ k >
		[structural]
	rule [compoundAssignment-bitwise-and]:
		< k > E1:K &= E2:K => compoundAssignment('_&_, E1:K, E2:K) ...</ k >
		[structural]
	rule [compoundAssignment-bitwise-xor]:
		< k > E1:K ^= E2:K => compoundAssignment('_^_, E1:K, E2:K) ...</ k >
		[structural]
	rule [compoundAssignment-bitwise-or]:
		< k > E1:K |= E2:K => compoundAssignment('_|_, E1:K, E2:K) ...</ k >
		[structural]

	rule
		< k > compoundAssignment(L:KLabel, V:KResult, V':KResult)
			=> V:KResult := L:KLabel(reval(V:KResult),, V':KResult)
		...</ k >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-BITWISE is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.7}{3}}
	The integer promotions are performed on each of the operands. The type of the result is that of the promoted left operand. If the value of the right operand is negative or is greater than or equal to the width of the promoted left operand, the behavior is undefined
	*/
	rule tv(I:#Int, T:KResult) << tv(N:#Nat, T':KResult) => leftShiftInterpret(T:KResult, I:#Int <<Int N:#Nat, tv(I:#Int, T:KResult))
		when hasBeenPromoted(T:KResult)
		andBool hasBeenPromoted(T':KResult)
		andBool N:#Nat <Int numBits(T:KResult)
		[structural]
	rule tv(I:#Int, T:KResult) >> tv(N:#Nat, T':KResult) => rightShiftInterpret(T:KResult, I:#Int >>Int N:#Nat)
		when hasBeenPromoted(T:KResult)
		andBool hasBeenPromoted(T':KResult)
		andBool N:#Nat <Int numBits(T:KResult)
		[structural]
				
		
	/*@ \source[n1570]{\para{6.5.10}{3--4}}
	The usual arithmetic conversions are performed on the operands.
	
	The result of the binary \cinline{&} operator is the bitwise AND of the operands (that is, each bit in the result is set if and only if each of the corresponding bits in the converted operands is set).
	*/
	rule tv(I1:#Int, T:KResult) & tv(I2:#Int, T:KResult) => arithInterpret(T:KResult, I1:#Int &Int I2:#Int)
		when hasBeenPromoted(T:KResult)
		[structural]
	
	/*@ \source[n1570]{\para{6.5.11}{3--4}}
	The usual arithmetic conversions are performed on the operands.
	
	The result of the \cinline{^} operator is the bitwise exclusive OR of the operands (that is, each bit in the result is set if and only if exactly one of the corresponding bits in the converted operands is set).	
	*/
	rule tv(I1:#Int, T:KResult) ^ tv(I2:#Int, T:KResult) => arithInterpret(T:KResult, I1:#Int xorInt I2:#Int)
		when hasBeenPromoted(T:KResult)
		[structural]
		
	/*@ \source[n1570]{\para{6.5.12}{3--4}}
	The usual arithmetic conversions are performed on the operands.
	
	The result of the \cinline{|} operator is the bitwise inclusive OR of the operands (that is, each bit in the result is set if and only if at least one of the corresponding bits in the converted operands is set).
	*/
	rule tv(I1:#Int, T:KResult) | tv(I2:#Int, T:KResult) => arithInterpret(T:KResult, I1:#Int |Int I2:#Int)
		when hasBeenPromoted(T:KResult)
		[structural]

	/*@ \source[n1570]{\para{6.5.3.3}{4}}
	The result of the \cinline{\~} operator is the bitwise complement of its (promoted) operand (that is, each bit in the result is set if and only if the corresponding bit in the converted operand is not set). The integer promotions are performed on the operand, and the result has the promoted type. If the promoted type is an unsigned type, the expression \cinline{\~E} is equivalent to the maximum value representable in that type minus \cinline{E}.
	*/
	rule ~ tv(I:#Int, T:KResult) => arithInterpret(T:KResult, ~Int I:#Int)
		when hasBeenPromoted(T:KResult)
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-BOOLEAN-ARITHMETIC is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.8}{3}}
	If both of the operands have arithmetic type, the usual arithmetic conversions are performed.
	
	\source[n1570]{\para{6.5.8}{4}}
	For the purposes of these operators, a pointer to an object that is not an element of an array behaves the same as a pointer to the first element of an array of length one with the type of the object as its element type.
	
	\source[n1570]{\para{6.5.8}{5}}
	When two pointers are compared, the result depends on the relative locations in the address space of the objects pointed to. If two pointers to object types both point to the same object, or both point one past the last element of the same array object, they compare equal. If the objects pointed to are members of the same aggregate object, pointers to structure members declared later compare greater than pointers to members declared earlier in the structure, and pointers to array elements with larger subscript values compare greater than pointers to elements of the same array with lower subscript values. All pointers to members of the same union object compare equal. If the expression \cinline{P} points to an element of an array object and the expression \cinline{Q} points to the last element of the same array object, the pointer expression \cinline{Q+1} compares greater than \cinline{P}. In all other cases, the behavior is undefined.
	
	\source[n1570]{\para{6.5.8}{5}}
	Each of the operators \cinline{<} (less than), \cinline{>} (greater than), \cinline{<=} (less than or equal to), and \cinline{>=} (greater than or equal to) shall yield 1 if the specified relation is true and 0 if it is false. The result has type \cinline{int}.
	*/
	
	declare makeTruth : #Bool -> K
	define makeTruth(B:#Bool) => if B:#Bool then tv(1, t(.Set, int)) else tv(0, t(.Set, int)) fi [structural]
	
	rule tv(I1:#Int, T:KResult) < tv(I2:#Int, T:KResult)
			=> makeTruth(I1:#Int <Int I2:#Int)
		when hasBeenPromoted(T:KResult)
		orBool (hasPointerType(T:KResult) andBool isConcreteNumber(I1:#Int) andBool isConcreteNumber(I2:#Int))
		[structural]
	rule tv(I1:#Int, T:KResult) <= tv(I2:#Int, T:KResult)
			=> makeTruth(I1:#Int <=Int I2:#Int)
		when hasBeenPromoted(T:KResult)
		orBool (hasPointerType(T:KResult) andBool isConcreteNumber(I1:#Int) andBool isConcreteNumber(I2:#Int))
		[structural]
	rule tv(I1:#Int, T:KResult) > tv(I2:#Int, T:KResult)
			=> makeTruth(I1:#Int >Int I2:#Int)
		when hasBeenPromoted(T:KResult)
		orBool (hasPointerType(T:KResult) andBool isConcreteNumber(I1:#Int) andBool isConcreteNumber(I2:#Int))
		[structural]
	rule tv(I1:#Int, T:KResult) >= tv(I2:#Int, T:KResult)
			=> makeTruth(I1:#Int >=Int I2:#Int)
		when hasBeenPromoted(T:KResult)
		orBool (hasPointerType(T:KResult) andBool isConcreteNumber(I1:#Int) andBool isConcreteNumber(I2:#Int))
		[structural]
	rule
		tv(F1:#Float, T:KResult) < tv(F2:#Float, T:KResult)
			=> makeTruth(F1:#Float <Float F2:#Float)
		[structural]
	rule
		tv(F1:#Float, T:KResult) <= tv(F2:#Float, T:KResult)
			=> makeTruth(F1:#Float <=Float F2:#Float)
		[structural]
	rule
		tv(F1:#Float, T:KResult) > tv(F2:#Float, T:KResult)
			=> makeTruth(F1:#Float >Float F2:#Float)
		[structural]
	rule
		tv(F1:#Float, T:KResult) >= tv(F2:#Float, T:KResult)
			=> makeTruth(F1:#Float >=Float F2:#Float)
		[structural]
	
	//- comparison of pointers
	// fixme could check 6.5.8:2
	// fixme there are further restrictions on pointers
	rule [ptr-compare-lt]: tv(sym(Base:#Nat) +Nat Offset:#Nat, T:KResult) < tv(sym(Base:#Nat) +Nat Offset':#Nat, T':KResult)
			=> makeTruth(Offset:#Nat <Int Offset':#Nat)
		when hasPointerType(T:KResult) andBool hasPointerType(T':KResult)
		[structural]
	rule [ptr-compare-lte]: tv(sym(Base:#Nat) +Nat Offset:#Nat, T:KResult) <= tv(sym(Base:#Nat) +Nat Offset':#Nat, T':KResult)
			=> makeTruth(Offset:#Nat <=Int Offset':#Nat)
		when hasPointerType(T:KResult) andBool hasPointerType(T':KResult)
		[structural]
	rule [ptr-compare-gt]: tv(sym(Base:#Nat) +Nat Offset:#Nat, T:KResult) > tv(sym(Base:#Nat) +Nat Offset':#Nat, T':KResult)
			=> makeTruth(Offset:#Nat >Int Offset':#Nat)
		when hasPointerType(T:KResult) andBool hasPointerType(T':KResult)
		[structural]
	rule [ptr-compare-gte]: tv(sym(Base:#Nat) +Nat Offset:#Nat, T:KResult) >= tv(sym(Base:#Nat) +Nat Offset':#Nat, T':KResult)
			=> makeTruth(Offset:#Nat >=Int Offset':#Nat)
		when hasPointerType(T:KResult) andBool hasPointerType(T':KResult)
		[structural]

	/*@ \source[n1570]{\para{6.5.9}{3}}
	The \cinline{==} (equal to) and \cinline{!=} (not equal to) operators are analogous to the relational operators except for their lower precedence. Each of the operators yields 1 if the specified relation is true and 0 if it is false. The result has type \cinline{int}. For any pair of operands, exactly one of the relations is true.
	*/
	
	rule tv(I1:#Int, T:KResult) == tv(I2:#Int, T:KResult)
		=> makeTruth(I1:#Int ==Bool I2:#Int)
		when (
			hasBeenPromoted(T:KResult)
			orBool (hasPointerType(T:KResult) andBool isConcreteNumber(I1:#Int) andBool isConcreteNumber(I2:#Int))
		) andBool notBool (isUnknown(I1:#Int) orBool isUnknown(I2:#Int))
		[structural]
	rule tv(I1:#Int, T:KResult) != tv(I2:#Int, T:KResult)
		=> makeTruth(I1:#Int =/=Bool I2:#Int)
		when (
			hasBeenPromoted(T:KResult)
			orBool (hasPointerType(T:KResult) andBool isConcreteNumber(I1:#Int) andBool isConcreteNumber(I2:#Int))
		) andBool notBool (isUnknown(I1:#Int) orBool isUnknown(I2:#Int))
		[structural]
		
	op isUnknown : K -> #Bool
	rule [isUnknown-piece]: isUnknown(piece(_:#Nat, _:#Nat)) => true [structural]
	rule [isUnknown-ptr]: isUnknown(sym(_:#Nat) +Nat _:#Nat) => false [structural]
	//rule [isUnknown-bito]: isUnknown(bito(_:#Nat) +Nat _) => false [structural]
	rule [isUnknown-int]: isUnknown(I:#Int) => false
		when  I:#Int <=Int 0 orBool I:#Int >Int 0
		[structural]
	
	// if they're identical, we know for sure they are the same
	rule tv(N:#Nat, T:KResult) == tv(N:#Nat, T':KResult)
		=> tv(1, t(.Set, int))
		when hasPointerType(T:KResult) 
		andBool hasPointerType(T':KResult)
		[structural]
	rule tv(N:#Nat, T:KResult) != tv(N:#Nat, T':KResult)
		=> tv(0, t(.Set, int))
		when hasPointerType(T:KResult) 
		andBool hasPointerType(T':KResult)
		[structural]
	
	// if one of the pointers is null, it's also straightforward
	rule tv(NullPointer, T:KResult) == tv(N:#Nat, T':KResult)
		=> makeTruth(NullPointer ==Bool N:#Nat)
		when hasPointerType(T:KResult) 
		andBool hasPointerType(T':KResult)
		[structural]
	rule tv(NullPointer, T:KResult) != tv(N:#Nat, T':KResult)
		=> makeTruth(NullPointer =/=Bool N:#Nat)
		when hasPointerType(T:KResult) 
		andBool hasPointerType(T':KResult)
		[structural]
	rule tv(N:#Nat, T:KResult) == tv(NullPointer, T':KResult)
		=> makeTruth(NullPointer ==Bool N:#Nat)
		when hasPointerType(T:KResult) 
		andBool hasPointerType(T':KResult)
		[structural]
	rule tv(N:#Nat, T:KResult) != tv(NullPointer, T':KResult)
		=> makeTruth(NullPointer =/=Bool N:#Nat)
		when hasPointerType(T:KResult) 
		andBool hasPointerType(T':KResult)
		[structural]
		
	// otherwise, there are a number of cases.  
	// First, they are part of the same object		
	rule < k > tv(sym(Base:#Nat) +Nat Offset:#Nat, T:KResult) == tv(sym(Base:#Nat) +Nat Offset':#Nat, T':KResult) 
			=> makeTruth(Offset:#Nat ==Bool Offset':#Nat)
		...</ k >
		when hasPointerType(T:KResult) andBool hasPointerType(T':KResult)
		[structural]
	rule < k > tv(sym(Base:#Nat) +Nat Offset:#Nat, T:KResult) != tv(sym(Base:#Nat) +Nat Offset':#Nat, T':KResult) 
			=> makeTruth(Offset:#Nat =/=Bool Offset':#Nat)
		...</ k >
		when hasPointerType(T:KResult) andBool hasPointerType(T':KResult)
		[structural]
		
	// next, they are part of different objects.  
	// here, if the two objects are alive, and our pointers are in bounds, we can conclude something.  if one of the objects is dead, we can't conclude anything (the address could have been reused)
	rule [compare-eq-different-objects]: < k > tv(sym(Base:#Nat) +Nat Offset:#Nat, T:KResult) == tv(sym(Base':#Nat) +Nat Offset':#Nat, T':KResult) 
			=> tv(0, t(.Set, int))
		...</ k >
		< mem >... 
			Base:#Nat |-> memblock(mlength(Len:#Nat) _, _) 
			Base':#Nat |-> memblock(mlength(Len':#Nat) _, _) 
			...</ mem >
		when hasPointerType(T:KResult) andBool hasPointerType(T':KResult)
		andBool Base:#Nat =/=Bool Base':#Nat
		andBool Offset:#Nat <Nat Len:#Nat
		andBool Offset':#Nat <Nat Len':#Nat
		[structural]
	rule [compare-neq-different-objects]: < k > tv(sym(Base:#Nat) +Nat Offset:#Nat, T:KResult) != tv(sym(Base':#Nat) +Nat Offset':#Nat, T':KResult) 
			=> tv(1, t(.Set, int))
		...</ k >
		< mem >... 
			Base:#Nat |-> memblock(mlength(Len:#Nat) _, _) 
			Base':#Nat |-> memblock(mlength(Len':#Nat) _, _) 
			...</ mem >
		when hasPointerType(T:KResult) andBool hasPointerType(T':KResult)
		andBool Base:#Nat =/=Bool Base':#Nat
		andBool Offset:#Nat <Nat Len:#Nat
		andBool Offset':#Nat <Nat Len':#Nat
		[structural]
	
	// otherwise we can't conclude anything
		
	//- comparison of ints with pointers
	// fixme there are further restrictions on pointers
	rule [equal-null-left]:
		(tv(N:#Nat, T:KResult) => tv(NullPointer, T':KResult)) == tv(_, T':KResult)
		when hasBeenPromoted(T:KResult) 
		andBool hasPointerType(T':KResult)
		andBool N:#Nat ==Bool NullPointerConstant
		[structural]
	rule [equal-null-right]:
		tv(_, T:KResult) == (tv(N:#Nat, T':KResult) => tv(NullPointer, T:KResult))
		when hasPointerType(T:KResult) 
		andBool hasBeenPromoted(T':KResult)
		andBool N:#Nat ==Bool NullPointerConstant
		[structural]
	
	rule [nequal-null-left]: 
		(tv(N:#Nat, T:KResult) => tv(NullPointer, T':KResult)) != tv(_, T':KResult)
		when hasBeenPromoted(T:KResult) 
		andBool hasPointerType(T':KResult)
		andBool N:#Nat ==Bool NullPointerConstant
		[structural]
	rule [nequal-null-right]: 
		tv(_, T:KResult) != (tv(N:#Nat, T':KResult) => tv(NullPointer, T:KResult))
		when hasPointerType(T:KResult) 
		andBool hasBeenPromoted(T':KResult)
		andBool N:#Nat ==Bool NullPointerConstant
		[structural]
	rule
		tv(F1:#Float, T:KResult) == tv(F2:#Float, T:KResult) => makeTruth(F1:#Float ==Bool F2:#Float)
		[structural]
	rule
		tv(F1:#Float, T:KResult) != tv(F2:#Float, T:KResult) => makeTruth(F1:#Float =/=Bool F2:#Float)
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-ARITHMETIC is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
		
		
	/*@ \source[n1570]{\para{6.5.6}{2}}
	For addition, either both operands shall have arithmetic type, or one operand shall be a pointer to a complete object type and the other shall have integer type.
	
	\source[n1570]{\para{6.5.6}{3}}
	For subtraction, one of the following shall hold:
	\begin{itemize}
	\item both operands have arithmetic type;
	\item both operands are pointers to qualified or unqualified versions of compatible complete object types; or
	\item the left operand is a pointer to a complete object type and the right operand has integer type.
	\end{itemize}
(Decrementing is equivalent to subtracting 1.)
	
	\source[n1570]{\para{6.5.6}{4}}
	If both operands have arithmetic type, the usual arithmetic conversions are performed on them.
	
	\source[n1570]{\para{6.5.6}{5}}
	The result of the binary \cinline{+} operator is the sum of the operands.
	
	\source[n1570]{\para{6.5.6}{6}}
	The result of the binary \cinline{-} operator is the difference resulting from the subtraction of the
second operand from the first.
	
	\source[n1570]{\para{6.5.6}{7}}
	For the purposes of these operators, a pointer to an object that is not an element of an array behaves the same as a pointer to the first element of an array of length one with the type of the object as its element type.
	
	\source[n1570]{\para{6.5.6}{8}}
	When an expression that has integer type is added to or subtracted from a pointer, the result has the type of the pointer operand. If the pointer operand points to an element of an array object, and the array is large enough, the result points to an element offset from the original element such that the difference of the subscripts of the resulting and original array elements equals the integer expression. In other words, if the expression \cinline{P} points to the $i$-th element of an array object, the expressions \cinline{(P)+N} (equivalently, \cinline{N+(P)}) and \cinline{(P)-N} (where \cinline{N} has the value $n$) point to, respectively, the $i+n$-th and $i-n$-th elements of the array object, provided they exist. Moreover, if the expression \cinline{P} points to the last element of an array object, the expression \cinline{(P)+1} points one past the last element of the array object, and if the expression \cinline{Q} points one past the last element of an array object, the expression \cinline{(Q)-1} points to the last element of the array object. If both the pointer operand and the result point to elements of the same array object, or one past the last element of the array object, the evaluation shall not produce an overflow; otherwise, the behavior is undefined. If the result points one past the last element of the array object, it shall not be used as the operand of a unary \cinline{*} operator that is evaluated.
	*/	
	
	op addToPointer : K Type K K -> K [metadata "strict=(4)"]
	rule < k > tv(Loc:#Nat, t(S:Set, pointerType(T':KResult))) + tv(I:#Int, T:KResult)
			=> addToPointer(Loc:#Nat, t(S:Set, pointerType(T':KResult)), I:#Int, sizeofType(T':KResult))
		...</ k >
		when hasIntegerType(T:KResult)
		andBool T':KResult =/=Bool void
		[structural]
	rule < k > tv(I:#Int, T:KResult) + tv(Loc:#Nat, t(S:Set, pointerType(T':KResult)))
			=> addToPointer(Loc:#Nat, t(S:Set, pointerType(T':KResult)), I:#Int, sizeofType(T':KResult))
		...</ k >
		when hasIntegerType(T:KResult)
		andBool T':KResult =/=Bool void
		[structural]
	rule < k > tv(Loc:#Nat, t(S:Set, pointerType(T':KResult))) - tv(I:#Int, T:KResult)
			=> addToPointer(Loc:#Nat, t(S:Set, pointerType(T':KResult)), -Int I:#Int, sizeofType(T':KResult)) 
		...</ k >
		when hasIntegerType(T:KResult)
		andBool T':KResult =/=Bool void
		[structural]
			
	rule < k > addToPointer(Loc:#Nat, T:KResult, I:#Int, tv(Size:#Nat, _))
			=> tv(Loc:#Nat +Int (I:#Int *Int Size:#Nat), NEWTYPE)
		...</ k >
		when ifFromArrayInBounds(T:KResult, I:#Int)
		where NEWTYPE = newFromArray(T:KResult, I:#Int)
		[structural]
		
	declare newFromArray : KResult #Int -> KResult
	define newFromArray(t(SetItem(fromArray(Offset:#Int, Len:#Nat)), pointerType(T:KResult)), I:#Int) 
		=> t(SetItem(fromArray(Offset:#Int +Int I:#Int, Len:#Nat)), pointerType(T:KResult))
	define newFromArray(t(.Set, pointerType(T:KResult)), I:#Int) 
		=> t(.Set, pointerType(T:KResult))
		
	declare ifFromArrayInBounds : KResult #Int -> #Bool
	define ifFromArrayInBounds(t(SetItem(fromArray(Offset:#Int, Len:#Nat)), pointerType(T:KResult)), I:#Int)
		=> true
		when Offset:#Int +Int I:#Int <=Int Len:#Nat
	define ifFromArrayInBounds(t(SetItem(fromArray(Offset:#Int, Len:#Nat)), pointerType(T:KResult)), I:#Int)
		=> false
		when Offset:#Int +Int I:#Int >Int Len:#Nat
	define ifFromArrayInBounds(t(.Set, pointerType(T:KResult)), _:#Int)
		=> true
		
	/*@ \source[n1570]{\para{6.5.6}{9}}
	When two pointers are subtracted, both shall point to elements of the same array object, or one past the last element of the array object; the result is the difference of the subscripts of the two array elements. The size of the result is implementation-defined, and its type (a signed integer type) is \cinline{ptrdiff_t} defined in the \cinline{<stddef.h>} header. If the result is not representable in an object of that type, the behavior is undefined. In other words, if the expressions \cinline{P} and \cinline{Q} point to, respectively, the $i$-th and $j$-th elements of an array object, the expression \cinline{(P)-(Q)} has the value $i-j$ provided the value fits in an object of type \cinline{ptrdiff_t}. Moreover, if the expression P points either to an element of an array object or one past the last element of an array object, and the expression \cinline{Q} points to the last element of the same array object, the expression \cinline{((Q)+1)-(P)} has the same value as \cinline{((Q)-(P))+1} and as \cinline{-((P)-((Q)+1))}, and has the value zero if the expression \cinline{P} points one past the last element of the array object, even though the expression \cinline{(Q)+1} does not point to an element of the array object.
	*/

	op computePointerDifference : #Int #Int K -> K [metadata "strict=(3)"] // ptr1, ptr2, size of ptr type
	rule [start-pointer-difference]: 
		tv(I1:#Int, t(_, pointerType(T:KResult))) - tv(I2:#Int, t(_, pointerType(T:KResult)))
			=> computePointerDifference(I1:#Int, I2:#Int, sizeofType(T:KResult))
		[structural]
	rule [pointer-difference]: 
		computePointerDifference(sym(Block:#Nat) +Nat Offset1:#Nat, sym(Block:#Nat) +Nat Offset2:#Nat, tv(Size:#Nat, _))
			=> tv(_-Int_(Offset1:#Nat, Offset2:#Nat) /Int Size:#Nat, cfg:ptrdiffut)
		when _-Int_(Offset1:#Nat, Offset2:#Nat) %Int Size:#Nat ==Bool 0
		[structural]
	
		
		
	rule tv(I1:#Int, T:KResult) + tv(I2:#Int, T:KResult) => arithInterpret(T:KResult, _+Int_(I1:#Int,I2:#Int))
		when hasBeenPromoted(T:KResult)
		[structural]
	rule _-_(tv(I1:#Int, T:KResult), tv(I2:#Int, T:KResult)) => arithInterpret(T:KResult, _-Int_(I1:#Int,I2:#Int))
		when hasBeenPromoted(T:KResult)
		[structural]
	rule tv(I1:#Int, T:KResult) * tv(I2:#Int, T:KResult) => arithInterpret(T:KResult, I1:#Int *Int I2:#Int)
		when hasBeenPromoted(T:KResult)
		[structural]
	rule tv(I1:#Int, T:KResult) / tv(I2:#Int, T:KResult) => arithInterpret(T:KResult, I1:#Int /Int I2:#Int)
		when hasBeenPromoted(T:KResult)
		andBool I2:#Int =/=Bool 0
		[structural]
	rule tv(I1:#Int, T:KResult) % tv(I2:#Int, T:KResult) => arithInterpret(T:KResult, I1:#Int %Int I2:#Int)
		when hasBeenPromoted(T:KResult)
		andBool min(T:KResult) <=Int I1:#Int /Int I2:#Int andBool max(T:KResult) >=Int I1:#Int /Int I2:#Int
		andBool I2:#Int =/=Bool 0
		[structural]
	rule - tv(I1:#Int, T:KResult) => arithInterpret(T:KResult, -Int_(I1:#Int))
		when hasBeenPromoted(T:KResult)
		[structural]
		
	rule piece(unknown(N:#Nat), N:#Nat) /Int M:#Nat 
		=> piece(unknown(N:#Nat), N:#Nat)
		when M:#Nat =/=Bool 0
		andBool isConcreteNumber(M:#Nat)
		[structural anywhere]
		
	
	// floats
	// fixme
	rule tv(F1:#Float, T:KResult) + tv(F2:#Float, T:KResult) => arithInterpret(T:KResult, F1:#Float +Float F2:#Float)
		[structural]
	rule _-_(tv(F1:#Float, T:KResult), tv(F2:#Float, T:KResult)) => arithInterpret(T:KResult, _-Float_(F1:#Float, F2:#Float))
		[structural]
	rule tv(F1:#Float, T:KResult) * tv(F2:#Float, T:KResult) => arithInterpret(T:KResult, F1:#Float *Float F2:#Float)
		[structural]
	rule tv(F1:#Float, T:KResult) / tv(F2:#Float, T:KResult) => arithInterpret(T:KResult, F1:#Float /Float F2:#Float)
		[structural]
		
		
		
	/*@ \source[n1570]{\para{6.5.3.3}{2}}
	The result of the unary \cinline{+} operator is the value of its (promoted) operand. The integer promotions are performed on the operand, and the result has the promoted type.
	*/		
	rule [unaryPlus-int]: + tv(I:#Int, T:KResult) => arithInterpret(T:KResult, I:#Int)
		when hasBeenPromoted(T:KResult)
		[structural]
	rule [unaryPlus-float]: + tv(F:#Float, T:KResult) => tv(F:#Float, T:KResult)
		[structural]	
		
	/*@ \source[n1570]{\para{6.5.3.3}{3}}
	The result of the unary \cinline{-} operator is the negative of its (promoted) operand. The integer promotions are performed on the operand, and the result has the promoted type.
	*/
	rule [unaryMinus-int]: - tv(I:#Int, T:KResult) => arithInterpret(T:KResult, -Int I:#Int)
		when hasBeenPromoted(T:KResult)
		[structural]
	rule [unaryMinus-float]: - tv(F:#Float, T:KResult) => arithInterpret(T:KResult, -Float_(F:#Float))
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-MEMBERS is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.2.3}{3}}
	A postfix expression followed by the \cinline{.} operator and an identifier designates a member of a structure or union object. The value is that of the named member, and is an lvalue if the first expression is an lvalue. \broken{If the first expression has qualified type, the result has the so-qualified version of the type of the designated member.}
	*/
	
			
	// fixme tool bug, can't use L:KLabel
	rule
		< k > lv(Loc:#Nat, t(_, structType(S:#Id))) . F:#Id
			=> lv(Loc:#Nat +Nat bito(Offset:#Nat), T:KResult)
		...</ k >
		< structs >...
			S:#Id |-> aggregateInfo(_, (_ F:#Id |-> T:KResult), (_ F:#Id |-> Offset:#Nat))
		...</ structs >
		//if L:KLabel ==Bool 'structType orBool L:KLabel ==Bool 'unionType
		[structural]
	rule
		< k > lv(Loc:#Nat, t(_, unionType(S:#Id))) . F:#Id
			=> lv(Loc:#Nat +Nat bito(Offset:#Nat), t(SetItem(fromUnion(S:#Id)) Se:Set, T:K))
		...</ k >
		< structs >...
			S:#Id |-> aggregateInfo(_, (_ F:#Id |-> t(Se:Set, T:K)), (_ F:#Id |-> Offset:#Nat))
		...</ structs >
		[structural]
		
	rule
		< k > tv(L:List{K}, T:KResult) . F:#Id
			=> extractField(L:List{K}, T:KResult, F:#Id)
		...</ k >
		[structural]
		
		
	/*@ \source[n1570]{\para{6.5.2.3}{4}}
	A postfix expression followed by the \cinline{->} operator and an identifier designates a member of a structure or union object. The value is that of the named member of the object to which the first expression points, and is an lvalue. \broken{If the first expression is a pointer to a qualified type, the result has the so-qualified version of the type of the designated member.}
	*/
	macro K:K -> F:#Id = (* K:K) . F:#Id
endkm

kmod DYNAMIC-SEMANTICS-DEREFERENCE is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.3.2}{4}}
	The unary \cinline{*} operator denotes indirection. If the operand points to a function, the result is a function designator; if it points to an object, the result is an lvalue designating the object. If the operand has type ``pointer to type'', the result has type ``type''. If an invalid value has been assigned to the pointer, the behavior of the unary \cinline{*} operator is undefined.
	*/
	rule [deref]:
		< k > *(tv(Loc:#Nat, t(_, pointerType(t(S:Set, T:K)))))
			=> checkDerefLoc(Loc:#Nat)
			~> lv(Loc:#Nat, t(S:Set, T:K))
		...</ k >
		when notBool T:K ==Bool void
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-REFERENCE is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.3.2}{3}}
	The unary \cinline{&} operator yields the address of its operand. If the operand has type ``type'', the result has type ``pointer to type''. \broken{If the operand is the result of a unary \cinline{*} operator, neither that operator nor the \cinline{&} operator is evaluated and the result is as if both were omitted, except that the constraints on the operators still apply and the result is not an lvalue. Similarly, if the operand is the result of a \cinline{[]} operator, neither the \cinline{&} operator nor the unary \cinline{*} that is implied by the \cinline{[]} is evaluated and the result is as if the \cinline{&} operator were removed and the \cinline{[]} operator were changed to a \cinline{+} operator.} Otherwise, the result is a pointer to the object or function designated by its operand.
	*/

	rule [ref]:
		< k > &(lv(Loc:#Nat, T:KResult))
			=> tv(Loc:#Nat, t(.Set, pointerType(T:KResult)))
		...</ k >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-INCREMENT-AND-DECREMENT is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.3.1}{2}}
	The value of the operand of the prefix \cinline{++} operator is incremented. The result is the new value of the operand after incrementation. The expression \cinline{++E} is equivalent to \cinline{(E+=1)}. See the discussions of additive operators and compound assignment for information on constraints, types, side effects, and conversions and the effects of operations on pointers.
	*/
	rule ++ E:K => E:K += tv(1, t(.Set, int)) [structural]
	/*@ \source[n1570]{\para{6.5.3.1}{3}}
	The prefix \cinline{--} operator is analogous to the prefix \cinline{++} operator, except that the value of the operand is decremented.
	*/
	rule -- E:K => E:K -= tv(1, t(.Set, int)) [structural]

	op postOpRef : K KLabel -> K
	op postInc : K K Type -> K [metadata "strict=(2)"]
	op postDec : K K Type -> K [metadata "strict=(2)"]
	
	/*@ \source[n1570]{\para{6.5.2.4}{2}}
	The result of the postfix \cinline{++} operator is the value of the operand. As a side effect, the value of the operand object is incremented (that is, the value 1 of the appropriate type is added to it). See the discussions of additive operators and compound assignment for information on constraints, types, and conversions and the effects of operations on pointers. The value computation of the result is sequenced before the side effect of updating the stored value of the operand. With respect to an indeterminately-sequenced function call, the operation of postfix \cinline{++} is a single evaluation. Postfix \cinline{++} on an object with atomic type is a read-modify-write operation with \cinline{memory_order_seq_cst} memory order semantics.
	*/	
	rule [post-increment-start]:
		< k > lv(Loc:#Nat, T:KResult)++
			=> postInc(Loc:#Nat, read(Loc:#Nat, T:KResult), T:KResult)
		...</ k >
		[structural]
	rule [post-decrement-start]:
		< k > lv(Loc:#Nat, T:KResult)--
			=> postDec(Loc:#Nat, read(Loc:#Nat, T:KResult), T:KResult)
		...</ k >
		[structural]

	rule [post-increment]:
		< k > postInc(Loc:#Nat, tv(V:K, T:KResult), T:KResult)
			=> lv(Loc:#Nat, T:KResult) := tv(V:K, T:KResult) + tv(1, t(.Set, int))
			~> discard
			~> tv(V:K, T:KResult)
		...</ k >
		[structural]
		
	rule [post-decrement]:
		< k > postDec(Loc:#Nat, tv(V:K, T:KResult), T:KResult)
			=> lv(Loc:#Nat, T:KResult) := tv(V:K, T:KResult) - tv(1, t(.Set, int))
			~> discard
			~> tv(V:K, T:KResult)
		...</ k >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-SEQUENCING is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.17}{2}}
	The left operand of a comma operator is evaluated as a void expression; there is a sequence point between its evaluation and that of the right operand. Then the right operand is evaluated; the result has its type and value.
	*/
	rule < k > Comma(List((V:KResult,, K':K,, L:List{K}))) 
		=> sequencePoint
		~> Comma(List((K':K,, L:List{K}))) ...</ k >
		[structural]
	rule < k > Comma(List(K:K)) => K:K ...</ k >
		[structural]
endkm

kmod DYNAMIC-C-EXPRESSIONS is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE

	including DYNAMIC-SEMANTICS-COMPOUND-LITERAL
	including DYNAMIC-SEMANTICS-BOOLEAN
	including DYNAMIC-SEMANTICS-CONDITIONAL-EXPRESSION
	including DYNAMIC-SEMANTICS-SIZEOF
	including DYNAMIC-SEMANTICS-IDENTIFIERS
	including DYNAMIC-SEMANTICS-FUNCTION-CALLS
	including DYNAMIC-SEMANTICS-ARRAY-SUBSCRIPTING
	including DYNAMIC-SEMANTICS-ASSIGNMENT
	including DYNAMIC-SEMANTICS-LITERALS
	including DYNAMIC-SEMANTICS-BITWISE
	including DYNAMIC-SEMANTICS-BOOLEAN-ARITHMETIC
	including DYNAMIC-SEMANTICS-ARITHMETIC
	including DYNAMIC-SEMANTICS-MEMBERS
	including DYNAMIC-SEMANTICS-DEREFERENCE
	including DYNAMIC-SEMANTICS-REFERENCE
	including DYNAMIC-SEMANTICS-INCREMENT-AND-DECREMENT
	including DYNAMIC-SEMANTICS-SEQUENCING
endkm
