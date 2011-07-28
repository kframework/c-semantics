kmod DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE is
	including DYNAMIC-INCLUDE
	op assign : K K -> K
	op compoundLiteral : Nat -> Id
	
	op lvGetOffset : K K Type -> K
	op tvGetOffset : K K Type -> K

	
	// fixme Whoah!  What about char types?  What is this about?
	// If the lvalue designates an object of automatic storage duration that could have been declared with the register storage class (never had its address taken), and that object is uninitialized (not declared with an initializer and no assignment to it has been performed prior to use), the behavior is undefined.
	
	
	rule [reval-skipval]: reval(skipval) => skipval [structural]
	rule [reval-emptyval]: reval(emptyValue) => emptyValue [structural]
	rule [reval-tv-normal]: reval(tv(L:List{K}, T:Type)) => tv(L:List{K}, T:Type) if notBool hasArrayType(T:Type) andBool notBool hasFunctionType(T:Type) [structural]
	rule [peval-tv-normal]: peval(tv(V:List{K}, T:Type)) => tv(V:List{K}, T:Type) if notBool hasArrayType(T:Type) andBool notBool hasFunctionType(T:Type) [structural]
	
	/*@ \source[n1570]{\para{6.3.2.1}{2}}
	Except when it is the operand of the \cinline{sizeof} operator, the \cinline{_Alignof} operator, the unary \cinline{&} operator, the \cinline{++} operator, the \cinline{--} operator, or the left operand of the \cinline{.} operator or an assignment operator, an lvalue that does not have an array type is converted to the value stored in the designated object (and is no longer an lvalue); this is called lvalue conversion.  If the lvalue has qualified type, the value has the unqualified version of the type of the lvalue; additionally, if the lvalue has atomic type, the value has the non-atomic version of the type of the lvalue; otherwise, the value has the type of the lvalue. \ldots
	*/
	rule reval(lv(Loc:Nat, T:Type)) => read(Loc:Nat, unqualifyType(T:Type)) if notBool hasArrayType(T:Type) andBool notBool hasFunctionType(T:Type) [structural]
	rule peval(lv(Loc:Nat, T:Type)) => lv(Loc:Nat, T:Type) if notBool hasArrayType(T:Type) andBool notBool hasFunctionType(T:Type) [structural]

	
	/*@ \source[n1570]{\para{6.3.2.1}{3}}
	Except when it is the operand of the \cinline{sizeof} operator, the \cinline{_Alignof} operator, or the unary \cinline{&} operator, or is a string literal used to initialize an array, an expression that has type ``array of type'' is converted to an expression with type ``pointer to type'' that points to the initial element of the array object and is not an lvalue. If the array object has register storage class, the behavior is undefined.
	*/
	rule [reval-lv-array]: reval(lv(Loc:Nat, T:Type)) => tv(Loc:Nat, t(.Set, pointerType(innerType(T:Type)))) if hasArrayType(T:Type) [structural]
	rule [peval-lv-array]: peval(lv(Loc:Nat, T:Type)) => tv(Loc:Nat, t(.Set, pointerType(innerType(T:Type)))) if hasArrayType(T:Type) [structural]
	// should never get to the situation where we have tv(..., arrayType)
	
	
	/*@ \source[n1570]{\para{6.3.2.1}{4}}
	A function designator is an expression that has function type.  Except when it is the operand of the \cinline{sizeof} operator, the \cinline{_Alignof} operator, or the unary \cinline{&} operator, a function designator with type ``function returning T'' is converted to an expression that has type ``pointer to a function returning T''.
	*/
	rule [reval-function]: reval(lv(Loc:Nat, T:Type)) => tv(Loc:Nat, t(.Set, pointerType(T:Type))) if hasFunctionType(T:Type) [structural]
	rule [peval-function]: peval(lv(Loc:Nat, T:Type)) => tv(Loc:Nat, t(.Set, pointerType(T:Type))) if hasFunctionType(T:Type) [structural]
	
endkm

kmod DYNAMIC-SEMANTICS-COMPOUND-LITERAL is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	op handleCompoundLiteral : K -> K [metadata "strict=()"]
	
	/*@ \source[n1570]{\para{6.5.2.5}{3}}
	A postfix expression that consists of a parenthesized type name followed by a brace-enclosed list of initializers is a compound literal. It provides an unnamed object whose value is given by the initializer list.
	*/
	
	/*@ We use \kinline{compoundLiteral(N:Nat)} here as the identifier of the compound literal.
	*/
	// comes back from figureInit as initializerValue(id, type, inits)
	rule
		< k > CompoundLiteral(N:Nat, T:Type, K:K, Init:K)
			=> handleCompoundLiteral(figureInitializer(compoundLiteral(N:Nat), DeclType(T:Type, K:K), Init:K))
		...</ k >
		[structural]
		
	rule
		< k > handleCompoundLiteral(initializerValue(X:Id, T:Type, Init:K))
			=> allocateType(Loc:Nat, T:Type)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
			~> initialize(X:Id, T:Type, Init:K)
			~> X:Id
		...</ k >
		< compoundLiteralMap > M:Map => M:Map[Loc:Nat / X:Id] </ compoundLiteralMap >
		< nextLoc > Loc:Nat => inc(Loc:Nat) </ nextLoc >
		if notBool $hasMapping(M:Map, X:Id)
		[structural]
		
	rule
		< k > handleCompoundLiteral(initializerValue(X:Id, T:Type, Init:K))
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
			~> initialize(X:Id, T:Type, Init:K)
			~> X:Id
		...</ k >
		< compoundLiteralMap >... X:Id |-> Loc:Nat ...</ compoundLiteralMap >
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
		< k > tv(0, t(?, int)) && E:K
			=> tv(0, t(.Set, int))
		...</ k >
		[structural]
	rule
		< k > tv(1, t(?, int)) && E:K
			=> sequencePoint
			~> simplifyTruth(E:K)
		...</ k >
		[structural]
	rule
		< k > (V:Value => simplifyTruth(V:Value)) && ? ...</ k >
		if isNotTruthValue(V:Value)
		[structural]	
				
	/*@ \source[n1570]{\para{6.5.14}{3--4}}
	The \cinline{||} operator shall yield 1 if either of its operands compare unequal to 0; otherwise, it yields 0. The result has type \cinline{int}.

	Unlike the bitwise \cinline{|} operator, the \cinline{||} operator guarantees left-to-right evaluation; if the second operand is evaluated, there is a sequence point between the evaluations of the first and second operands. If the first operand compares unequal to 0, the second operand is not evaluated.
	*/
	rule
		< k > tv(0, t(?, int)) || E:K
			=> sequencePoint
			~> simplifyTruth(E:K)
		...</ k >
		[structural]
	rule
		< k > tv(1, t(?, int)) || E:K
			=> tv(1, t(.Set, int))
		...</ k >
		[structural]
	rule
		< k > (V:Value => V:Value != tv(0, t(.Set, int))) || ? ...</ k >
		if isNotTruthValue(V:Value)
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
	context types((?,, `[HOLE`]:K,, ?))
	op convertedType : K -> K [metadata "strict=()"]
	
	rule < k > getTypes(L:List{K}) => types(wrapWithTypeOf(L:List{K})) ...</ k > [structural]
	
	op wrapWithTypeOf : List{K} -> List{K}
	rule wrapWithTypeOf((K:K,, L:List{K})) => (retype(typeof(K:K)),, wrapWithTypeOf(L:List{K})) [structural]
	rule wrapWithTypeOf(.List{K}) => .List{K} [structural]
	
	op retype : K -> K [metadata "strict=()"]
	
	// fixme, not handling qualifiers correctly
	rule
		retype(T:Type) => t(.Set, pointerType(innerType(T:Type)))
		if hasArrayType(T:Type)
		[structural]
	rule
		retype(T:Type) => t(.Set, pointerType(T:Type))
		if hasFunctionType(T:Type)
		[structural]
	rule
		retype(T:Type) => T:Type
		if notBool (hasArrayType(T:Type) orBool hasFunctionType(T:Type))
		[structural]	
	/*@ \source[n1570]{\para{6.5.15}{4}}
	The first operand is evaluated; there is a sequence point between its evaluation and the evaluation of the second or third operand (whichever is evaluated). The second operand is evaluated only if the first compares unequal to 0; the third operand is evaluated only if the first compares equal to 0; the result is the value of the second or third operand (whichever is evaluated), converted to the type described below.
	*/

	
	rule
		< k > (.K => getTypes((E1,, E2))) ~> E:K ? E1:K : E2:K ...</ k >
		[structural]
		
	/*@ \source[n1570]{\para{6.5.15}{5}}
	If both the second and third operands have arithmetic type, the result type that would be determined by the usual arithmetic conversions, were they applied to those two operands, is the type of the result. If both the operands have structure or union type, the result has that type. If both operands have void type, the result has void type.
	*/
	rule
		< k > (types((T1:Type,, T2:Type)) => convertedType(usualArithmeticConversion(T1:Type, T2:Type)))
			~> E:K ? E1:K : E2:K
		...</ k >
		if T1:Type =/=Bool T2:Type
		andBool hasArithmeticType(T1:Type)
		andBool hasArithmeticType(T2:Type)
		[structural]
		
	/*@ \source[n1570]{\para{6.5.15}{6}}
	\broken{If both the second and third operands are pointers or one is a null pointer constant and the other is a pointer, the result type is a pointer to a type qualified with all the type qualifiers of the types referenced by both operands. Furthermore, if both operands are pointers to compatible types or to differently qualified versions of compatible types, the result type is a pointer to an appropriately qualified version of the composite type}; if one operand is a null pointer constant, the result has the type of the other operand; \broken{otherwise, one operand is a pointer to void or a qualified version of void, in which case the result type is a pointer to an appropriately qualified version of void.}
	*/
	// fixme, this is too relaxed; could be any integer zero.  need static semantics to handle this properly
	rule [conditional-left-is-null]:
		< k > (types((T1:Type,, T2:Type)) => convertedType(T2:Type))
			~> E:K ? tv(0, T1:Type) : E2:K
		...</ k >
		if hasIntegerType(T1:Type)
		andBool hasPointerType(T2:Type)
		[structural]
	rule [conditional-right-is-null]:
		< k > (types((T1:Type,, T2:Type)) => convertedType(T1:Type))
			~> E:K ? E1:K : tv(0, T2:Type)
		...</ k >
		if hasIntegerType(T2:Type)
		andBool hasPointerType(T1:Type)
		[structural]
		
	// fixme, this is wrong
	rule
		< k > (types((T1:Type,, T2:Type)) => convertedType(T1:Type))
			~> E:K ? E1:K : E2:K
		...</ k >
		if hasPointerType(T1:Type)
		andBool hasPointerType(T2:Type)
		[structural]
		
	// this should take care of the void/struct cases
	rule
		< k > (types((T:Type,, T:Type)) => convertedType(T:Type))
			~> E:K ? E1:K : E2:K
		...</ k >
		if notBool hasPointerType(T:Type)
		[structural]
	rule
		< k > convertedType(T:Type) ~> E:K ? E1:K : E2:K
			=> IfThenElse(E:K, cast(T:Type, E1:K), cast(T:Type, E2:K))
		...</ k >
		[structural]
		
endkm

kmod DYNAMIC-SEMANTICS-SIZEOF is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.3.4}{2}}
	The \cinline{sizeof} operator yields the size (in bytes) of its operand, which may be an expression or the parenthesized name of a type. The size is determined from the type of the operand. The result is an integer. If the type of the operand is a variable length array type, the operand is evaluated; otherwise, the operand is not evaluated and the result is an integer constant.
	*/
	
	rule sizeofType(T:Type) => cast(cfg:sizeut, byteSizeofType(T:Type)) [structural]
	op byteSizeofType-aux : K -> K [metadata "strict=()"]
	rule byteSizeofType(T:Type) => byteSizeofType-aux(bitSizeofType(T:Type)) [structural]
	rule byteSizeofType-aux(tv(N:Nat, T:Type)) => tv(bitsToBytes(N:Nat), T:Type)
		//if T:Type ==Bool cfg:largestUnsigned
		[structural]
	rule
		< k > SizeofExpression(E:K) => sizeofType(typeof(E:K)) ...</ k >
		[structural]
	rule
		< k > SizeofType(T:Type, K:K) => sizeofType(DeclType(T:Type, K:K)) ...</ k >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-IDENTIFIERS is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.1}{2}}
	An identifier is a primary expression, provided it has been declared as designating an object (in which case it is an lvalue) or a function (in which case it is a function designator).
	*/
	rule [lookup]:
		< k > X:Id => lv(Loc:Nat, T:Type) ...</ k >
		< env >... X:Id |-> Loc:Nat ...</ env >
		< types >... X:Id |-> T:Type ...</ types >
		[structural]
		
	rule [lookup-builtin-function-notfound]:
		< k > (.K 
				=> addToEnv(X:Id, Loc:Nat)
				~> initFunction(
					tv(Loc:Nat, t(.Set, pointerType(T:Type))),
					functionPrototype(X:Id, T:Type)
				)
			)
			~> X:Id
		...</ k >
		< env > Env:Map </ env >
		< types >... X:Id |-> T:Type ...</ types >
		< nextLoc > Loc:Nat => inc(Loc:Nat) </ nextLoc >
		if hasFunctionType(T:Type)
		andBool notBool $hasMapping(Env:Map, X:Id)
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-FUNCTION-CALLS is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE

	op application : K List{C} -> K [metadata "strict=(1)"]
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
		< k > Call(tv(Loc:Nat, t(?, pointerType(T:Type))), L:List{Type})
			=> application(readFunction(Loc:Nat), L:List{Type})
		...</ k >
		if hasFunctionType(T:Type)
		[structural]

	rule [populateFromGlobal]:
		< k > populateFromGlobal => .K ...</ k >
		< genv >... Tu:K |-> Map(G:Map) ...</ genv > < env > ? => G:Map </ env >
		< gtypes >... Tu:K |-> Map(GT:Map) ...</ gtypes > < types > ? => GT:Map </ types >
		< gstructs > GS:Map </ gstructs > < structs > ? => GS:Map </ structs >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		[structural]

	rule [builtin-application]:
		< k > application(functionPrototype(X:Id, T:Type), L:List{Type})
			=> application(functionObject(X:Id, T:Type, handleBuiltin(X:Id, T:Type)), L:List{Type})
		...</ k >
		[structural]
		
	rule [function-application]:
		< k > application(functionObject(X:Id, t(?, functionType(R:Type, P:List{Type})), B:K), L:List{Type}) ~> K:K 
			=> sequencePoint
			~> populateFromGlobal
			~> bind(L:List{Type}, P:List{Type})
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
			< currentFunction > X:Id </ currentFunction >
			< currentTranslationUnit > Tu:K </ currentTranslationUnit >
			< currentProgramLoc > CurrLoc:K </ currentProgramLoc >
		...</ control >)
		< functionTranslationUnits >... OldTu:K |-> Map((? X:Id |-> Tu:K)) ...</ functionTranslationUnits >
		[structural large]
endkm

kmod DYNAMIC-SEMANTICS-ARRAY-SUBSCRIPTING is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.2.1}{2}}
	A postfix expression followed by an expression in square brackets \cinline{[]} is a subscripted designation of an element of an array object. The definition of the subscript operator \cinline{[]} is that \cinline{E1[E2]} is identical to \cinline{(*((E1)+(E2)))}. Because of the conversion rules that apply to the binary \cinline{+} operator, if \cinline{E1} is an array object (equivalently, a pointer to the initial element of an array object) and \cinline{E2} is an integer, \cinline{E1[E2]} designates the \cinline{E2}-th element of \cinline{E1} (counting from zero).
	*/
	rule < k > E1:K[E2:K] => *(E1:K + E2:K) ...</ k >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-LITERALS is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	// here we start with a local address, put the string in memory, then change the address to be readonly
	
	rule [const-string-notfound]:
		< k > (.K => allocString(Loc:Nat, S:String +String "\0"))
			~> Constant(StringLiteral(S:String))
		...</ k >
		< nextSharedLoc > Loc:Nat => inc(Loc:Nat) </ nextSharedLoc >
		< stringLiterals >
			M:Map
			(.Map => S:String |-> lv(Loc:Nat, t(.Set, arrayType(t(.Set, char), lengthString(S:String) +Nat 1))))
		</ stringLiterals >
		if notBool($hasMapping(M:Map, S:String))
		[structural]
		
	op wstring : List{K} -> K 
	rule [const-wstring-notfound]:
		< k > (.K => allocWString(Loc:Nat, (S:List{K},, 0)))
			~> Constant(WStringLiteral(S:List{K}))
		...</ k >
		< nextSharedLoc > Loc:Nat => inc(Loc:Nat) </ nextSharedLoc >
		< stringLiterals >
			M:Map
			(.Map => wstring(S:List{K}) |-> lv(Loc:Nat, t(.Set, arrayType(cfg:wcharut, lengthList{K}(S:List{K}) +Nat 1))))
		</ stringLiterals >
		if notBool($hasMapping(M:Map, wstring(S:List{K})))
		[structural]
		
	rule [const-string-found]:
		< k > Constant(StringLiteral(S:String)) => V:Value ...</ k >
		< stringLiterals >... S:String |-> V:Value ...</ stringLiterals >
		[structural]
	rule [const-wstring-found]:
		< k > Constant(WStringLiteral(S:List{K})) => V:Value ...</ k >
		< stringLiterals >... wstring(S:List{K}) |-> V:Value ...</ stringLiterals >
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
	rule CharLiteral(N:Nat) => tv(N:Nat, t(.Set, int)) [structural]
	rule WCharLiteral(N:Nat) => tv(N:Nat, cfg:wcharut) [structural]
	rule Constant(V:Value) => V:Value [structural]
	rule [create-internal-value]: < k > N:Nat => tv(N:Nat, cfg:largestUnsigned) ...</ k >
		[structural] // for internal computations
		
	op withinRange : Int SimpleType -> Bool
	rule withinRange(I:Int, T:SimpleType) => (I:Int <=Int max(t(.Set, T:SimpleType))) andBool (I:Int >=Int min(t(.Set, T:SimpleType))) [structural]
	
	rule NoSuffix(DecimalConstant(I:Int)) =>
		if withinRange(I:Int, int) then tv(I:Int, t(.Set, int)) else
		if withinRange(I:Int, long-int) then tv(I:Int, t(.Set, long-int)) else
		if withinRange(I:Int, long-long-int) then tv(I:Int, t(.Set, long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi fi fi
		[structural]
		
	op simplifyForHex : String -> String
	rule simplifyForHex(S:String) => simplifyForHex(butFirstChar(S:String))
		if firstChar(S:String) ==Bool "0"
		andBool lengthString(S:String) >Nat 1
		[structural]
	rule simplifyForHex(S:String) => S:String
		if firstChar(S:String) =/=Bool "0"
		orBool lengthString(S:String) ==Bool 1
		[structural]
		
		
	op hexOrOctalConstant : K -> K
	rule HexConstant(S:String) => hexOrOctalConstant(String2Rat(simplifyForHex(S:String), 16)) [structural]
	rule OctalConstant(N:Nat) => hexOrOctalConstant(truncRat(String2Rat(Rat2String(N:Nat, 10), 8))) [structural] // truncRat is just for sorts
	
	rule NoSuffix(hexOrOctalConstant(I:Int)) =>
		if withinRange(I:Int, int) then tv(I:Int, t(.Set, int)) else
		if withinRange(I:Int, unsigned-int) then tv(I:Int, t(.Set, unsigned-int)) else
		if withinRange(I:Int, long-int) then tv(I:Int, t(.Set, long-int)) else
		if withinRange(I:Int, unsigned-long-int) then tv(I:Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:Int, long-long-int) then tv(I:Int, t(.Set, long-long-int)) else
		if withinRange(I:Int, unsigned-long-long-int) then tv(I:Int, t(.Set, unsigned-long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi fi fi fi fi fi
		[structural]

	rule U(hexOrOctalConstant(I:Int)) =>
		if withinRange(I:Int, unsigned-int) then tv(I:Int, t(.Set, unsigned-int)) else
		if withinRange(I:Int, unsigned-long-int) then tv(I:Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:Int, unsigned-long-long-int) then tv(I:Int, t(.Set, unsigned-long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi fi fi
		[structural]
		
	rule L(hexOrOctalConstant(I:Int)) =>
		if withinRange(I:Int, long-int) then tv(I:Int, t(.Set, long-int)) else
		if withinRange(I:Int, unsigned-long-int) then tv(I:Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:Int, long-long-int) then tv(I:Int, t(.Set, long-long-int)) else
		if withinRange(I:Int, unsigned-long-long-int) then tv(I:Int, t(.Set, unsigned-long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi fi fi fi
		[structural]
		
	rule UL(hexOrOctalConstant(I:Int)) =>
		if withinRange(I:Int, unsigned-long-int) then tv(I:Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:Int, unsigned-long-long-int) then tv(I:Int, t(.Set, unsigned-long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi fi
		[structural]
		
	rule LL(hexOrOctalConstant(I:Int)) =>
		if withinRange(I:Int, long-long-int) then tv(I:Int, t(.Set, long-long-int)) else
		if withinRange(I:Int, unsigned-long-long-int) then tv(I:Int, t(.Set, unsigned-long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi fi
		[structural]
	
	rule ULL(hexOrOctalConstant(I:Int)) =>
		if withinRange(I:Int, unsigned-long-long-int) then tv(I:Int, t(.Set, unsigned-long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi
		[structural]
		
		
	rule U(DecimalConstant(I:Int)) =>
		if withinRange(I:Int, unsigned-int) then tv(I:Int, t(.Set, unsigned-int)) else
		if withinRange(I:Int, unsigned-long-int) then tv(I:Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:Int, unsigned-long-long-int) then tv(I:Int, t(.Set, unsigned-long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi fi fi
		[structural]
	rule L(DecimalConstant(I:Int)) =>
		if withinRange(I:Int, long-int) then tv(I:Int, t(.Set, long-int)) else
		if withinRange(I:Int, long-long-int) then tv(I:Int, t(.Set, long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi fi
		[structural]
	rule UL(DecimalConstant(I:Int)) =>
		if withinRange(I:Int, unsigned-long-int) then tv(I:Int, t(.Set, unsigned-long-int)) else
		if withinRange(I:Int, unsigned-long-long-int) then tv(I:Int, t(.Set, unsigned-long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi fi		
		[structural]
	rule LL(DecimalConstant(I:Int)) =>
		if withinRange(I:Int, long-long-int) then tv(I:Int, t(.Set, long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi
		[structural]
	rule ULL(DecimalConstant(I:Int)) =>
		if withinRange(I:Int, unsigned-long-long-int) then tv(I:Int, t(.Set, unsigned-long-long-int)) else
			tv(I:Int, t(.Set, no-type))
		fi
		[structural]
	
	/*@ \source[n1570]{\para{6.4.4.2}{4}}
	An unsuffixed floating constant has type \cinline{double}. If suffixed by the letter \cinline{f} or \cinline{F}, it has type \cinline{float}. If suffixed by the letter \cinline{l} or \cinline{L}, it has type \cinline{long double}.
	*/
	
	op reducedFloat : Float -> K
	rule DecimalFloatConstant(?, ?, F:Float) => reducedFloat(F:Float) [structural]
	rule HexFloatConstant(?, ?, F:Float) => reducedFloat(F:Float) [structural]
	
	rule NoSuffix(reducedFloat(F:Float)) => tv(F:Float, t(.Set, double))
		[structural]
	rule L(reducedFloat(F:Float)) => tv(F:Float, t(.Set, long-double))
		[structural]
	rule F(reducedFloat(F:Float)) => tv(F:Float, t(.Set, float))
		[structural]

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
		< k > lv(Loc:Nat, T:Type) := RHS
			=> write(lv(Loc:Nat, T:Type), RHS)
			~> RHS
		...</ k >
		where RHS = tv(V:List{K}, T:Type)
		[structural]
	rule [convert-for-assignment]:
		< k >
			lv(?, T:Type)
			:=
			(tv(V:List{K}, T':Type) => cast(T:Type, tv(V:List{K}, T':Type)))
		...</ k >
		if T:Type =/=Bool T':Type
		[structural]
	/*@ \source[n1570]{\para{6.5.16.1}{3}}
	\broken{If the value being stored in an object is read from another object that overlaps in any way the storage of the first object, then the overlap shall be exact and the two objects shall have qualified or unqualified versions of a compatible type; otherwise, the behavior is undefined.}
	*/
	
	
	/*@ \source[n1570]{\para{6.5.16.2}{3}}
	Acompound assignment of the form \cinline{E1 op= E2} is equivalent to the simple assignment expression \cinline{E1 = E1 op (E2)}, except that the lvalue \cinline{E1} is evaluated only once, and with respect to an indeterminately-sequenced function call, the operation of a compound assignment is a single evaluation. If \cinline{E1} has an atomic type, compound assignment is a read-modify-write operation with \cinline{memory_order_seq_cst} memory order semantics.
	*/
	op compoundAssignment : KLabel K K -> K
	// these should not be nd, in order to keep the operations together
	context compoundAssignment(_, ([HOLE] => peval([HOLE])), _)
	context compoundAssignment(_, _, ([HOLE] => reval([HOLE])))
		
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
		< k > compoundAssignment(L:KLabel, V:Value, V':Value)
			=> V:Value := L:KLabel(reval(V:Value),, V':Value)
		...</ k >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-BITWISE is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.7}{3}}
	The integer promotions are performed on each of the operands. The type of the result is that of the promoted left operand. If the value of the right operand is negative or is greater than or equal to the width of the promoted left operand, the behavior is undefined
	*/
	rule tv(I:Int, T:Type) << tv(N:Nat, T':Type) => leftShiftInterpret(T:Type, I:Int <<Int N:Nat, tv(I:Int, T:Type))
		if hasBeenPromoted(T:Type)
		andBool hasBeenPromoted(T':Type)
		andBool N:Nat <Int numBits(T:Type)
		[structural]
	rule tv(I:Int, T:Type) >> tv(N:Nat, T':Type) => rightShiftInterpret(T:Type, I:Int >>Int N:Nat)
		if hasBeenPromoted(T:Type)
		andBool hasBeenPromoted(T':Type)
		andBool N:Nat <Int numBits(T:Type)
		[structural]
				
		
	/*@ \source[n1570]{\para{6.5.10}{3--4}}
	The usual arithmetic conversions are performed on the operands.
	
	The result of the binary \cinline{&} operator is the bitwise AND of the operands (that is, each bit in the result is set if and only if each of the corresponding bits in the converted operands is set).
	*/
	rule tv(I1:Int, T:Type) & tv(I2:Int, T:Type) => arithInterpret(T:Type, I1:Int &Int I2:Int)
		if hasBeenPromoted(T:Type)
		[structural]
	
	/*@ \source[n1570]{\para{6.5.11}{3--4}}
	The usual arithmetic conversions are performed on the operands.
	
	The result of the \cinline{^} operator is the bitwise exclusive OR of the operands (that is, each bit in the result is set if and only if exactly one of the corresponding bits in the converted operands is set).	
	*/
	rule tv(I1:Int, T:Type) ^ tv(I2:Int, T:Type) => arithInterpret(T:Type, I1:Int xorInt I2:Int)
		if hasBeenPromoted(T:Type)
		[structural]
		
	/*@ \source[n1570]{\para{6.5.12}{3--4}}
	The usual arithmetic conversions are performed on the operands.
	
	The result of the \cinline{|} operator is the bitwise inclusive OR of the operands (that is, each bit in the result is set if and only if at least one of the corresponding bits in the converted operands is set).
	*/
	rule tv(I1:Int, T:Type) | tv(I2:Int, T:Type) => arithInterpret(T:Type, I1:Int |Int I2:Int)
		if hasBeenPromoted(T:Type)
		[structural]

	/*@ \source[n1570]{\para{6.5.3.3}{4}}
	The result of the \cinline{\~} operator is the bitwise complement of its (promoted) operand (that is, each bit in the result is set if and only if the corresponding bit in the converted operand is not set). The integer promotions are performed on the operand, and the result has the promoted type. If the promoted type is an unsigned type, the expression \cinline{\~E} is equivalent to the maximum value representable in that type minus \cinline{E}.
	*/
	rule ~ tv(I:Int, T:Type) => arithInterpret(T:Type, ~Int I:Int)
		if hasBeenPromoted(T:Type)
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
	
	op makeTruth : Bool -> K
	rule makeTruth(B:Bool) => if B:Bool then tv(1, t(.Set, int)) else tv(0, t(.Set, int)) fi [structural]
	
	rule tv(I1:Int, T:Type) < tv(I2:Int, T:Type)
			=> makeTruth(I1:Int <Int I2:Int)
		if hasBeenPromoted(T:Type)
		orBool (hasPointerType(T:Type) andBool isConcreteNumber(I1:Int) andBool isConcreteNumber(I2:Int))
		[structural]
	rule tv(I1:Int, T:Type) <= tv(I2:Int, T:Type)
			=> makeTruth(I1:Int <=Int I2:Int)
		if hasBeenPromoted(T:Type)
		orBool (hasPointerType(T:Type) andBool isConcreteNumber(I1:Int) andBool isConcreteNumber(I2:Int))
		[structural]
	rule tv(I1:Int, T:Type) > tv(I2:Int, T:Type)
			=> makeTruth(I1:Int >Int I2:Int)
		if hasBeenPromoted(T:Type)
		orBool (hasPointerType(T:Type) andBool isConcreteNumber(I1:Int) andBool isConcreteNumber(I2:Int))
		[structural]
	rule tv(I1:Int, T:Type) >= tv(I2:Int, T:Type)
			=> makeTruth(I1:Int >=Int I2:Int)
		if hasBeenPromoted(T:Type)
		orBool (hasPointerType(T:Type) andBool isConcreteNumber(I1:Int) andBool isConcreteNumber(I2:Int))
		[structural]
	rule
		tv(F1:Float, T:Type) < tv(F2:Float, T:Type)
			=> makeTruth(F1:Float <Float F2:Float)
		[structural]
	rule
		tv(F1:Float, T:Type) <= tv(F2:Float, T:Type)
			=> makeTruth(F1:Float <=Float F2:Float)
		[structural]
	rule
		tv(F1:Float, T:Type) > tv(F2:Float, T:Type)
			=> makeTruth(F1:Float >Float F2:Float)
		[structural]
	rule
		tv(F1:Float, T:Type) >= tv(F2:Float, T:Type)
			=> makeTruth(F1:Float >=Float F2:Float)
		[structural]
	
	//- comparison of pointers
	// fixme could check 6.5.8:2
	// fixme there are further restrictions on pointers
	rule [ptr-compare-lt]: tv(sym(Base:Nat) +Nat Offset:Nat, T:Type) < tv(sym(Base:Nat) +Nat Offset':Nat, T':Type)
			=> makeTruth(Offset:Nat <Int Offset':Nat)
		if hasPointerType(T:Type) andBool hasPointerType(T':Type)
		[structural]
	rule [ptr-compare-lte]: tv(sym(Base:Nat) +Nat Offset:Nat, T:Type) <= tv(sym(Base:Nat) +Nat Offset':Nat, T':Type)
			=> makeTruth(Offset:Nat <=Int Offset':Nat)
		if hasPointerType(T:Type) andBool hasPointerType(T':Type)
		[structural]
	rule [ptr-compare-gt]: tv(sym(Base:Nat) +Nat Offset:Nat, T:Type) > tv(sym(Base:Nat) +Nat Offset':Nat, T':Type)
			=> makeTruth(Offset:Nat >Int Offset':Nat)
		if hasPointerType(T:Type) andBool hasPointerType(T':Type)
		[structural]
	rule [ptr-compare-gte]: tv(sym(Base:Nat) +Nat Offset:Nat, T:Type) >= tv(sym(Base:Nat) +Nat Offset':Nat, T':Type)
			=> makeTruth(Offset:Nat >=Int Offset':Nat)
		if hasPointerType(T:Type) andBool hasPointerType(T':Type)
		[structural]

	/*@ \source[n1570]{\para{6.5.9}{3}}
	The \cinline{==} (equal to) and \cinline{!=} (not equal to) operators are analogous to the relational operators except for their lower precedence. Each of the operators yields 1 if the specified relation is true and 0 if it is false. The result has type \cinline{int}. For any pair of operands, exactly one of the relations is true.
	*/
	
	rule tv(I1:Int, T:Type) == tv(I2:Int, T:Type)
		=> makeTruth(I1:Int ==Bool I2:Int)
		if (
			hasBeenPromoted(T:Type)
			orBool (hasPointerType(T:Type) andBool isConcreteNumber(I1:Int) andBool isConcreteNumber(I2:Int))
		) andBool notBool (isUnknown(I1:Int) orBool isUnknown(I2:Int))
		[structural]
	rule tv(I1:Int, T:Type) != tv(I2:Int, T:Type)
		=> makeTruth(I1:Int =/=Bool I2:Int)
		if (
			hasBeenPromoted(T:Type)
			orBool (hasPointerType(T:Type) andBool isConcreteNumber(I1:Int) andBool isConcreteNumber(I2:Int))
		) andBool notBool (isUnknown(I1:Int) orBool isUnknown(I2:Int))
		[structural]
		
	op isUnknown : K -> Bool
	rule [isUnknown-piece]: isUnknown(piece(?, ?)) => true [structural]
	rule [isUnknown-ptr]: isUnknown(sym(?) +Nat ?) => false [structural]
	//rule [isUnknown-bito]: isUnknown(bito(?) +Nat ?) => false [structural]
	rule [isUnknown-int]: isUnknown(I:Int) => false
		if  I:Int <=Int 0 orBool I:Int >Int 0
		[structural]
	
	// if they're identical, we know for sure they are the same
	rule tv(N:Nat, T:Type) == tv(N:Nat, T':Type)
		=> tv(1, t(.Set, int))
		if hasPointerType(T:Type) 
		andBool hasPointerType(T':Type)
		[structural]
	rule tv(N:Nat, T:Type) != tv(N:Nat, T':Type)
		=> tv(0, t(.Set, int))
		if hasPointerType(T:Type) 
		andBool hasPointerType(T':Type)
		[structural]
	
	// if one of the pointers is null, it's also straightforward
	rule tv(NullPointer, T:Type) == tv(N:Nat, T':Type)
		=> makeTruth(NullPointer ==Bool N:Nat)
		if hasPointerType(T:Type) 
		andBool hasPointerType(T':Type)
		[structural]
	rule tv(NullPointer, T:Type) != tv(N:Nat, T':Type)
		=> makeTruth(NullPointer =/=Bool N:Nat)
		if hasPointerType(T:Type) 
		andBool hasPointerType(T':Type)
		[structural]
	rule tv(N:Nat, T:Type) == tv(NullPointer, T':Type)
		=> makeTruth(NullPointer ==Bool N:Nat)
		if hasPointerType(T:Type) 
		andBool hasPointerType(T':Type)
		[structural]
	rule tv(N:Nat, T:Type) != tv(NullPointer, T':Type)
		=> makeTruth(NullPointer =/=Bool N:Nat)
		if hasPointerType(T:Type) 
		andBool hasPointerType(T':Type)
		[structural]
		
	// otherwise, there are a number of cases.  
	// First, they are part of the same object		
	rule < k > tv(sym(Base:Nat) +Nat Offset:Nat, T:Type) == tv(sym(Base:Nat) +Nat Offset':Nat, T':Type) 
			=> makeTruth(Offset:Nat ==Bool Offset':Nat)
		...</ k >
		if hasPointerType(T:Type) andBool hasPointerType(T':Type)
		[structural]
	rule < k > tv(sym(Base:Nat) +Nat Offset:Nat, T:Type) != tv(sym(Base:Nat) +Nat Offset':Nat, T':Type) 
			=> makeTruth(Offset:Nat =/=Bool Offset':Nat)
		...</ k >
		if hasPointerType(T:Type) andBool hasPointerType(T':Type)
		[structural]
		
	// next, they are part of different objects.  
	// here, if the two objects are alive, and our pointers are in bounds, we can conclude something.  if one of the objects is dead, we can't conclude anything (the address could have been reused)
	rule [compare-eq-different-objects]: < k > tv(sym(Base:Nat) +Nat Offset:Nat, T:Type) == tv(sym(Base':Nat) +Nat Offset':Nat, T':Type) 
			=> tv(0, t(.Set, int))
		...</ k >
		< mem >... 
			Base:Nat |-> memblock(Len:Nat, ?) 
			Base':Nat |-> memblock(Len':Nat, ?) 
			...</ mem >
		if hasPointerType(T:Type) andBool hasPointerType(T':Type)
		andBool Base:Nat =/=Bool Base':Nat
		andBool Offset:Nat <Nat Len:Nat
		andBool Offset':Nat <Nat Len':Nat
		[structural]
	rule [compare-neq-different-objects]: < k > tv(sym(Base:Nat) +Nat Offset:Nat, T:Type) != tv(sym(Base':Nat) +Nat Offset':Nat, T':Type) 
			=> tv(1, t(.Set, int))
		...</ k >
		< mem >... 
			Base:Nat |-> memblock(Len:Nat, ?) 
			Base':Nat |-> memblock(Len':Nat, ?) 
			...</ mem >
		if hasPointerType(T:Type) andBool hasPointerType(T':Type)
		andBool Base:Nat =/=Bool Base':Nat
		andBool Offset:Nat <Nat Len:Nat
		andBool Offset':Nat <Nat Len':Nat
		[structural]
	
	// otherwise we can't conclude anything
		
	//- comparison of ints with pointers
	// fixme there are further restrictions on pointers
	rule [equal-null-left]:
		(tv(N:Nat, T:Type) => tv(NullPointer, T':Type)) == tv(?, T':Type)
		if hasBeenPromoted(T:Type) 
		andBool hasPointerType(T':Type)
		andBool N:Nat ==Bool NullPointerConstant
		[structural]
	rule [equal-null-right]:
		tv(?, T:Type) == (tv(N:Nat, T':Type) => tv(NullPointer, T:Type))
		if hasPointerType(T:Type) 
		andBool hasBeenPromoted(T':Type)
		andBool N:Nat ==Bool NullPointerConstant
		[structural]
	
	rule [nequal-null-left]: 
		(tv(N:Nat, T:Type) => tv(NullPointer, T':Type)) != tv(?, T':Type)
		if hasBeenPromoted(T:Type) 
		andBool hasPointerType(T':Type)
		andBool N:Nat ==Bool NullPointerConstant
		[structural]
	rule [nequal-null-right]: 
		tv(?, T:Type) != (tv(N:Nat, T':Type) => tv(NullPointer, T:Type))
		if hasPointerType(T:Type) 
		andBool hasBeenPromoted(T':Type)
		andBool N:Nat ==Bool NullPointerConstant
		[structural]
	rule
		tv(F1:Float, T:Type) == tv(F2:Float, T:Type) => makeTruth(F1:Float ==Bool F2:Float)
		[structural]
	rule
		tv(F1:Float, T:Type) != tv(F2:Float, T:Type) => makeTruth(F1:Float =/=Bool F2:Float)
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
	rule < k > tv(Loc:Nat, t(S:Set, pointerType(T':Type))) + tv(I:Int, T:Type)
			=> addToPointer(Loc:Nat, t(S:Set, pointerType(T':Type)), I:Int, sizeofType(T':Type))
		...</ k >
		if hasIntegerType(T:Type)
		andBool T':Type =/=Bool void
		[structural]
	rule < k > tv(I:Int, T:Type) + tv(Loc:Nat, t(S:Set, pointerType(T':Type)))
			=> addToPointer(Loc:Nat, t(S:Set, pointerType(T':Type)), I:Int, sizeofType(T':Type))
		...</ k >
		if hasIntegerType(T:Type)
		andBool T':Type =/=Bool void
		[structural]
	rule < k > tv(Loc:Nat, t(S:Set, pointerType(T':Type))) - tv(I:Int, T:Type)
			=> addToPointer(Loc:Nat, t(S:Set, pointerType(T':Type)), -Int I:Int, sizeofType(T':Type)) 
		...</ k >
		if hasIntegerType(T:Type)
		andBool T':Type =/=Bool void
		[structural]
			
	rule < k > addToPointer(Loc:Nat, T:Type, I:Int, tv(Size:Nat, ?))
			=> tv(Loc:Nat +Int (I:Int *Int Size:Nat), T:Type)
		...</ k >
		[structural]
		
	/*@ \source[n1570]{\para{6.5.6}{9}}
	When two pointers are subtracted, both shall point to elements of the same array object, or one past the last element of the array object; the result is the difference of the subscripts of the two array elements. The size of the result is implementation-defined, and its type (a signed integer type) is \cinline{ptrdiff_t} defined in the \cinline{<stddef.h>} header. If the result is not representable in an object of that type, the behavior is undefined. In other words, if the expressions \cinline{P} and \cinline{Q} point to, respectively, the $i$-th and $j$-th elements of an array object, the expression \cinline{(P)-(Q)} has the value $i-j$ provided the value fits in an object of type \cinline{ptrdiff_t}. Moreover, if the expression P points either to an element of an array object or one past the last element of an array object, and the expression \cinline{Q} points to the last element of the same array object, the expression \cinline{((Q)+1)-(P)} has the same value as \cinline{((Q)-(P))+1} and as \cinline{-((P)-((Q)+1))}, and has the value zero if the expression \cinline{P} points one past the last element of the array object, even though the expression \cinline{(Q)+1} does not point to an element of the array object.
	*/

	op computePointerDifference : Int Int K -> K [metadata "strict=(3)"] // ptr1, ptr2, size of ptr type
	rule [start-pointer-difference]: 
		tv(I1:Int, t(?, pointerType(T:Type))) - tv(I2:Int, t(?, pointerType(T:Type)))
			=> computePointerDifference(I1:Int, I2:Int, sizeofType(T:Type))
		[structural]
	rule [pointer-difference]: 
		computePointerDifference(sym(Block:Nat) +Nat Offset1:Nat, sym(Block:Nat) +Nat Offset2:Nat, tv(Size:Nat, ?))
			=> tv(_-Int_(Offset1:Nat, Offset2:Nat) /Int Size:Nat, cfg:ptrdiffut)
		if _-Int_(Offset1:Nat, Offset2:Nat) %Int Size:Nat ==Bool 0
		[structural]
	
		
		
	rule tv(I1:Int, T:Type) + tv(I2:Int, T:Type) => arithInterpret(T:Type, _+Int_(I1:Int,I2:Int))
		if hasBeenPromoted(T:Type)
		[structural]
	rule _-_(tv(I1:Int, T:Type), tv(I2:Int, T:Type)) => arithInterpret(T:Type, _-Int_(I1:Int,I2:Int))
		if hasBeenPromoted(T:Type)
		[structural]
	rule tv(I1:Int, T:Type) * tv(I2:Int, T:Type) => arithInterpret(T:Type, I1:Int *Int I2:Int)
		if hasBeenPromoted(T:Type)
		[structural]
	rule tv(I1:Int, T:Type) / tv(I2:Int, T:Type) => arithInterpret(T:Type, I1:Int /Int I2:Int)
		if hasBeenPromoted(T:Type)
		andBool I2:Int =/=Bool 0
		[structural]
	rule tv(I1:Int, T:Type) % tv(I2:Int, T:Type) => arithInterpret(T:Type, I1:Int %Int I2:Int)
		if hasBeenPromoted(T:Type)
		andBool min(T:Type) <=Int I1:Int /Int I2:Int andBool max(T:Type) >=Int I1:Int /Int I2:Int
		andBool I2:Int =/=Bool 0
		[structural]
	rule - tv(I1:Int, T:Type) => arithInterpret(T:Type, -Int_(I1:Int))
		if hasBeenPromoted(T:Type)
		[structural]
		
	rule piece(unknown(N:Nat), N:Nat) /Int M:Nat 
		=> piece(unknown(N:Nat), N:Nat)
		if M:Nat =/=Bool 0
		andBool isConcreteNumber(M:Nat)
		[structural]
		
	
	// floats
	// fixme
	rule tv(F1:Float, T:Type) + tv(F2:Float, T:Type) => arithInterpret(T:Type, F1:Float +Float F2:Float)
		[structural]
	rule _-_(tv(F1:Float, T:Type), tv(F2:Float, T:Type)) => arithInterpret(T:Type, _-Float_(F1:Float, F2:Float))
		[structural]
	rule tv(F1:Float, T:Type) * tv(F2:Float, T:Type) => arithInterpret(T:Type, F1:Float *Float F2:Float)
		[structural]
	rule tv(F1:Float, T:Type) / tv(F2:Float, T:Type) => arithInterpret(T:Type, F1:Float /Float F2:Float)
		[structural]
		
		
		
	/*@ \source[n1570]{\para{6.5.3.3}{2}}
	The result of the unary \cinline{+} operator is the value of its (promoted) operand. The integer promotions are performed on the operand, and the result has the promoted type.
	*/		
	rule [unaryPlus-int]: + tv(I:Int, T:Type) => arithInterpret(T:Type, I:Int)
		if hasBeenPromoted(T:Type)
		[structural]
	rule [unaryPlus-float]: + tv(F:Float, T:Type) => tv(F:Float, T:Type)
		[structural]	
		
	/*@ \source[n1570]{\para{6.5.3.3}{3}}
	The result of the unary \cinline{-} operator is the negative of its (promoted) operand. The integer promotions are performed on the operand, and the result has the promoted type.
	*/
	rule [unaryMinus-int]: - tv(I:Int, T:Type) => arithInterpret(T:Type, -Int I:Int)
		if hasBeenPromoted(T:Type)
		[structural]
	rule [unaryMinus-float]: - tv(F:Float, T:Type) => arithInterpret(T:Type, -Float_(F:Float))
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-MEMBERS is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.2.3}{3}}
	A postfix expression followed by the \cinline{.} operator and an identifier designates a member of a structure or union object. The value is that of the named member, and is an lvalue if the first expression is an lvalue. \broken{If the first expression has qualified type, the result has the so-qualified version of the type of the designated member.}
	*/
	
			
	// fixme tool bug, can't use L:KLabel
	rule
		< k > lv(Loc:Nat, t(?, structType(S:Id))) . F:Id
			=> lv(Loc:Nat +Nat bito(Offset:Nat), T:Type)
		...</ k >
		< structs >...
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), (? F:Id |-> Offset:Nat))
		...</ structs >
		//if L:KLabel ==Bool 'structType orBool L:KLabel ==Bool 'unionType
		[structural]
	rule
		< k > lv(Loc:Nat, t(?, unionType(S:Id))) . F:Id
			=> lv(Loc:Nat +Nat bito(Offset:Nat), t(SetItem(fromUnion(S:Id)) Se:Set, T:SimpleType))
		...</ k >
		< structs >...
			S:Id |-> aggregateInfo(?, (? F:Id |-> t(Se:Set, T:SimpleType)), (? F:Id |-> Offset:Nat))
		...</ structs >
		[structural]
		
	rule
		< k > tv(L:List{K}, T:Type) . F:Id
			=> extractField(L:List{K}, T:Type, F:Id)
		...</ k >
		[structural]
		
		
	/*@ \source[n1570]{\para{6.5.2.3}{4}}
	A postfix expression followed by the \cinline{->} operator and an identifier designates a member of a structure or union object. The value is that of the named member of the object to which the first expression points, and is an lvalue. \broken{If the first expression is a pointer to a qualified type, the result has the so-qualified version of the type of the designated member.}
	*/
	macro K:K -> F:Id = (* K:K) . F:Id
endkm

kmod DYNAMIC-SEMANTICS-DEREFERENCE is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.3.2}{4}}
	The unary \cinline{*} operator denotes indirection. If the operand points to a function, the result is a function designator; if it points to an object, the result is an lvalue designating the object. If the operand has type ``pointer to type'', the result has type ``type''. If an invalid value has been assigned to the pointer, the behavior of the unary \cinline{*} operator is undefined.
	*/
	rule [deref]:
		< k > *(tv(Loc:Nat, t(?, pointerType(t(S:Set, T:SimpleType)))))
			=> checkDerefLoc(Loc:Nat)
			~> lv(Loc:Nat, t(S:Set, T:SimpleType))
		...</ k >
		if notBool T:SimpleType ==Bool void
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-REFERENCE is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.3.2}{3}}
	The unary \cinline{&} operator yields the address of its operand. If the operand has type ``type'', the result has type ``pointer to type''. \broken{If the operand is the result of a unary \cinline{*} operator, neither that operator nor the \cinline{&} operator is evaluated and the result is as if both were omitted, except that the constraints on the operators still apply and the result is not an lvalue. Similarly, if the operand is the result of a \cinline{[]} operator, neither the \cinline{&} operator nor the unary \cinline{*} that is implied by the \cinline{[]} is evaluated and the result is as if the \cinline{&} operator were removed and the \cinline{[]} operator were changed to a \cinline{+} operator.} Otherwise, the result is a pointer to the object or function designated by its operand.
	*/

	rule [ref]:
		< k > &(lv(Loc:Nat, T:Type))
			=> tv(Loc:Nat, t(.Set, pointerType(T:Type)))
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
		< k > lv(Loc:Nat, T:Type)++
			=> postInc(Loc:Nat, read(Loc:Nat, T:Type), T:Type)
		...</ k >
		[structural]
	rule [post-decrement-start]:
		< k > lv(Loc:Nat, T:Type)--
			=> postDec(Loc:Nat, read(Loc:Nat, T:Type), T:Type)
		...</ k >
		[structural]

	rule [post-increment]:
		< k > postInc(Loc:Nat, tv(V:BaseValue, T:Type), T:Type)
			=> lv(Loc:Nat, T:Type) := tv(V:BaseValue, T:Type) + tv(1, t(.Set, int))
			~> discard
			~> tv(V:BaseValue, T:Type)
		...</ k >
		[structural]
		
	rule [post-decrement]:
		< k > postDec(Loc:Nat, tv(V:BaseValue, T:Type), T:Type)
			=> lv(Loc:Nat, T:Type) := tv(V:BaseValue, T:Type) - tv(1, t(.Set, int))
			~> discard
			~> tv(V:BaseValue, T:Type)
		...</ k >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-SEQUENCING is
	including DYNAMIC-SEMANTICS-EXPRESSIONS-INCLUDE
	
	/*@ \source[n1570]{\para{6.5.17}{2}}
	The left operand of a comma operator is evaluated as a void expression; there is a sequence point between its evaluation and that of the right operand. Then the right operand is evaluated; the result has its type and value.
	*/
	rule < k > Comma(T:Type :: K':C :: L:List{C}) => sequencePoint ~> Comma(K':C :: L:List{C}) ...</ k >
		[structural]
	rule < k > Comma(K:C) => K:C ...</ k >
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
