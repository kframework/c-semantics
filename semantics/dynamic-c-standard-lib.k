// load maudeLib/TCPSupport

kmod DYNAMIC-C-STANDARD-LIBRARY-INCLUDE is
	including DYNAMIC-INCLUDE 
	// including #SOCKET
	// including #TCP-INTERFACE
	
	op vararg : K -> C [metadata "hybrid=() strict=()"]
	op nextvarg : #Nat K -> C [metadata "strict=(2)"] // loc, type
	op vpair : K K -> C [metadata "hybrid=() strict=()"]
	op prepareBuiltin : #Id List{K} -> K
	declare incSymbolic : K -> K
	op printString : K -> K
	
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-HELPERS is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	rule reval(vararg(K:K)) => vararg(K:K) [structural]
	// fixme had to make this K because of the context bug
	op nextvarg-aux : K Type K K -> C // offset, type, length, checklength
	context nextvarg-aux(_, _, value(HOLE), _)
	context nextvarg-aux(_, _, _, value(HOLE))
	
	rule [nextvarg-start]:
		< k > nextvarg(Loc:#Nat, T:KResult)
			=> nextvarg-aux(Loc:#Nat, T:KResult, value(byteSizeofType(T:KResult)), value(sizeofLocation(Loc:#Nat)))
		...</ k >
		[structural]
	rule [nextvarg]:
		< k > nextvarg-aux(Loc:#Nat, T:KResult, Len:#Nat, Len:#Nat)
			=> vpair(read(Loc:#Nat, T:KResult), vararg(tv(inc(Loc:#Nat), t(.Set, pointerType(t(.Set, void))))))
		...</ k >
		[structural]
	

	// context 'prepareBuiltin(_:#Id,, '_::_(_:List`{K`},, (HOLE:C => reval(HOLE)),, _:List`{K`}))
	context prepareBuiltin(_:#Id, (_:List{K},, (HOLE => reval(HOLE)),, _:List{K}))
	
	declare idsFromDeclList : List{K} -> List{K}
	
	define [idsFromDeclList-one]:
		idsFromDeclList((L:List{K},, typedDeclaration(t(_, T:K), X:#Id)))
			=> idsFromDeclList(L:List{K}),, X:#Id
		when T:K =/=Bool void
		[structural]
	define [idsFromDeclList-void]:
		idsFromDeclList((L:List{K},, typedDeclaration(t(_, void), X:#Id)))
			=> idsFromDeclList(L:List{K})
		[structural]
	define [idsFromDeclList-vararg]:
		idsFromDeclList((L:List{K},, typedDeclaration(T:KResult, X:#Id),, t(_, variadic)))
			=> idsFromDeclList((L:List{K},, typedDeclaration(T:KResult, X:#Id)))
			,, vararg(incSymbolic(cast(t(.Set, pointerType(t(.Set, unsigned-char))), &(X:#Id))))
			// assumes variadic args are placed in incremental blocks
		[structural]
	define [idsFromDeclList-done]:
		idsFromDeclList(.List{K}) => .List{K} [structural]
	

	context incSymbolic((HOLE => reval(HOLE)))
	define [incSymbolic]:
		incSymbolic(tv(Loc:#Nat, T:KResult)) => tv(inc(Loc:#Nat), T:KResult)
		[structural]
		
	rule [prepareBuiltin]:
		< k > handleBuiltin(F:#Id, t(_, functionType(Return:KResult, L:List{KResult})))
			=> Return(prepareBuiltin(F:#Id, idsFromDeclList(L:List{KResult})))
		...</ k >
		[structural]
		
	rule
		< k > printString(S:#String)
			=> writeToFD(1, asciiCharString(firstChar(S:#String)))
			~> printString(butFirstChar(S:#String))
		...</ k >
		when lengthString(S:#String) >Nat 0
		[structural]
	rule
		< k > printString("") => writeToFD(1, 10) ...</ k >
		[structural]
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-MATH is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	rule [sqrt]:
		< k > prepareBuiltin((Identifier("sqrt")), tv(F:#Float, t(_, double)))
			=> tv(sqrtFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [log]:
		< k > prepareBuiltin((Identifier("log")), tv(F:#Float, t(_, double)))
			=> tv(logFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [exp]:
		< k > prepareBuiltin((Identifier("exp")), tv(F:#Float, t(_, double)))
			=> tv(expFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [atan]:
		< k > prepareBuiltin((Identifier("atan")), tv(F:#Float, t(_, double)))
			=> tv(atanFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [asin]:
		< k > prepareBuiltin((Identifier("asin")), tv(F:#Float, t(_, double)))
			=> tv(asinFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [atan2]:
		< k > prepareBuiltin((Identifier("atan2")), (tv(F:#Float, t(_, double)),, tv(F':#Float, t(_, double))))
			=> tv(atanFloat(F:#Float, F':#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [tan]:
		< k > prepareBuiltin((Identifier("tan")), tv(F:#Float, t(_, double)))
			=> tv(tanFloat(F:#Float), t(.Set, double))
		...</ k >
	[structural]

	rule [floor]:
		< k > prepareBuiltin((Identifier("floor")), tv(F:#Float, t(_, double)))
			=> tv(floorFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [cos]:
		< k > prepareBuiltin((Identifier("cos")), tv(F:#Float, t(_, double)))
			=> tv(cosFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [fmod]:
		< k > prepareBuiltin((Identifier("fmod")), (tv(F:#Float, t(_, double)),, tv(F':#Float, t(_, double))))
			=> tv(F:#Float %Float F':#Float, t(.Set, double))
		...</ k >
		[structural]

	rule [sin]:
		< k > prepareBuiltin((Identifier("sin")), tv(F:#Float, t(_, double)))
			=> tv(sinFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-SETJMP is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE

	// The (apparent) return value from setjmp indicates whether control reached that point normally or from a call to longjmp
	// fixme check bounds
	// fixme obviously need to rework configuration to make this easy
	op Bag : Bag -> K
	
	op ignoreLocals : -> K
	
	// there seems to be a problem here related to locals.  what if longjmp is never called?
	rule [ignoreLocals]:
		< k > ignoreLocals => .K ...</ k >
		< localAddresses > Locals:Set => .Set </ localAddresses >
		[structural]
	
	// fixme doesn't check if loc:#Nat is const
	rule [setjmp]:
		< k > (prepareBuiltin(Identifier("setjmp"), tv(Loc:#Nat, t(_, pointerType(t(_, structType(Identifier("__jmp_buf_tag")))))))
			=> ignoreLocals
				~> writeByte(Loc:#Nat, Bag(
					C:Bag
					< continuation > K:K </ continuation >
				))
				~> tv(0, t(.Set, int))
			)
			~> K:K
		</ k >
		< threadLocal >
			C:Bag
		</ threadLocal >
		[structural]

	op longjmp-aux : K K -> K [metadata "strict=()"]
	rule [longjmp-prepare]:
		< k > prepareBuiltin(Identifier("longjmp"), (V:KResult,, V':KResult))
			=> longjmp-aux(reval(*(V:KResult)), V':KResult)
		...</ k >
		[structural]
	
	// fixme: memory leak here with extra ignoreLocals.  needed for recursive setjmp/longjmp as in Looping.c
	rule [longjmp]:
		< k > longjmp-aux(tv(Bag(
					< continuation > K:K </ continuation >
					C:Bag
			), t(_, structType(Identifier("__jmp_buf_tag")))), tv(I:#Int, t(_, int))) ~> _
			=> ignoreLocals ~> if I:#Int ==Bool 0 then tv(1, t(.Set, int)) else tv(I:#Int, t(.Set, int)) fi ~> K:K
		</ k >
		< threadLocal >
			_ => C:Bag
		</ threadLocal >
		[structural]
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-STDARG is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
		
	////////////////////////////--
	// Stdarg.h
	////////////////////////////--
		// ,, "__va_inc"
		// ,, "__va_start"
		// ,, "__va_end"
		// ,, "__va_copy"
		
	// va_list __va_start(va_list* ap, void* pN);
	// fixme can add lots of checks here
	// tool fixme, change Value to K and unquote error
	rule [va-start]:
		< k > prepareBuiltin((Identifier("__va_start")), (ApLoc:KResult,, ArgLoc:KResult))
				=> Computation(*(ApLoc:KResult) := incSymbolic(ArgLoc:KResult))
				~> skipval
		...</ k >
		[structural]
	
	op va-inc-aux : K K K -> K // [metadata "strict=(3)"]
	context va-inc-aux(_, _, (HOLE => reval(HOLE)))
	// fixme can do lots of checks here too
	
	// this doesn't work because when we read apLoc, the object has already changed
	rule
		< k > prepareBuiltin((Identifier("__va_inc")), (ApLoc:KResult,, Size:KResult))
				=> Computation(*(ApLoc:KResult) := incSymbolic(ApLoc:KResult))
				~> ApLoc:KResult
		...</ k >
		[structural]
	
	rule [va-inc-start]:
		< k > prepareBuiltin((Identifier("__va_inc")), (ApLoc:KResult,, Size:KResult))
				=> va-inc-aux(ApLoc:KResult, Size:KResult, *ApLoc:KResult)
		...</ k >
		[structural]
				
	rule [va-inc]:
		< k > va-inc-aux(ApLoc:KResult, Size:KResult, Ap:KResult)
			=> Computation(*(ApLoc:KResult) := incSymbolic(Ap:KResult))
			~> Ap:KResult
		...</ k >
		[structural]				
		
	// fixme can do lots of checks here too
	rule [va-copy]:
		< k > prepareBuiltin((Identifier("__va_copy")), (ApLoc:KResult,, Other:KResult))
				=> Computation(*(ApLoc:KResult) := Other:KResult)
				~> skipval
		...</ k >
		[structural]
		
	// fixme can do lots of checks here too
	// tool fixme, shouldn't let me compile empty rule
	// rule
		// < k > prepareBuiltin((Identifier("__va_end")), (ApLoc:KResult))
				// ~> skipval
		// ...</ k >
		// [structural]
	rule [va-end]:
		< k > prepareBuiltin((Identifier("__va_end")), (ApLoc:KResult))
				=> skipval
		...</ k >
		[structural]
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-STDDEF is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE

	op offsetOf : K K -> K [metadata "strict=(1)"]
	rule
		< k > OffsetOf(T:KResult, K:K, F:#Id) => offsetOf(DeclType(T:KResult, K:K), F:#Id) ...</ k >
		[structural]
	// fixme should check for bitfield offset
	rule
		< k > offsetOf(t(_, structType(S:#Id)), F:#Id)
			=> tv(bitsToBytes(Offset:#Nat), cfg:sizeut)
		...</ k >
		< structs >...
			S:#Id |-> aggregateInfo(_, _, (_ F:#Id |-> Offset:#Nat))
		...</ structs >
		[structural]
	rule < k > offsetOf(t(_, unionType(_:#Id)), _) => tv(0, cfg:sizeut) ...</ k >
		[structural]
endkm


kmod DYNAMIC-C-STANDARD-LIBRARY-STDIO is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE

	rule [putchar]:
		< k > prepareBuiltin((Identifier("putchar")), tv(N:#Nat, _))
			=> writeToFD(1, N:#Nat) 
			~> tv(N:#Nat, t(.Set, int))
		...</ k >
		[structural]

	rule [fslPutc]:
		< k > prepareBuiltin((Identifier("__fslPutc")), (tv(N:#Nat, _),, tv(H:#Nat, _)))
			=> writeToFD(H:#Nat, N:#Nat)
			~> tv(N:#Nat, t(.Set, int))
		...</ k >
		[structural]

	rule [getchar]:
		< k > prepareBuiltin((Identifier("getchar")), .List{K}) 
			=> flush(1)
			~> readFromFD(0) 
		...</ k >
		[structural]

	rule [fslFGetC]:
		< k > prepareBuiltin((Identifier("__fslFGetC")), (tv(FD:#Nat, _),, tv(Offset:#Nat, _)))
			=> readFromFD(FD:#Nat)
			// => #fReadByte(FD:#Nat)
		...</ k >
		[structural]

	rule [fslCloseFile]:
		< k > prepareBuiltin((Identifier("__fslCloseFile")), tv(FD:#Nat, t(_, int))) 
			=> tv(0, t(.Set, int))
		...</ k >
		(< file >... < fid > FD:#Nat </ fid > ...</ file > => .Bag)
		[structural]

	rule [fslOpenFile-pre]:
		< k > prepareBuiltin((Identifier("__fslOpenFile")), (Filename:KResult,, Mode:KResult))
			=> fsl-open-file(getString(Filename:KResult), getString(Mode:KResult))
		...</ k >
		[structural]
	
	op fsl-open-file-aux : #String #String K -> K [metadata "strict=(3)"]
	
	rule [fslOpenFile-aux]:
		< k > fsl-open-file(str(Filename:#String), str(Mode:#String))
			=> fsl-open-file-aux("file:" +String Filename:#String, Mode:#String, #open("file:" +String Filename:#String +String "#" +String Mode:#String))
		...</ k >
		[structural]

	rule [fslOpenFile]:
		< k > fsl-open-file-aux(Name:#String, Mode:#String, tv(FD:#Nat, _)) 
			=> tv(FD:#Nat, t(.Set, int)) 
		...</ k >
		< files >...
			(.Bag => 
				<file>...
					<fid> FD:#Nat </fid>
					<uri> Name:#String </uri>
					<mode> Mode:#String </mode>
				...</file>
			)
		...</ files >
		[structural]

	op fsl-open-file : K K -> K [metadata "strict=()"]

	//////////////////////////--	

	
	//C1X Here we might want to assume different threads cannot interleave wrt printf, based on 7.1.4:5.  However, 7.1.4:4 seems to say exactly the opposite.
	// on second thought, it probably is saying that while the shared data is protected against races, it can still be interleaved
	// fixme despite the above, still need to handle interleaving of user data read during evaluation of printf.  should use something like a buffer to do this
	rule [printf]:
		< k > prepareBuiltin((Identifier("printf")), (Format:KResult,, VarArgs:KResult))
			=> new-printf-aux(formatter(getString(Format:KResult), VarArgs:KResult))
		...</ k >
		[structural]
		
	// rule [printf-done]:
		// < k > tv(0, _) ~> printf-aux(Len:#Nat, _, _) 
			// => flush(1)
			// ~> tv(Len:#Nat, t(.Set, int)) 
		// ...</ k >
		// [structural]
	rule [printf-done]:
		< k > new-printf-aux(formattedResult(S:#String))
			=> writeToFD(1, S:#String)
			~> flush(1)
			~> tv(lengthString(S:#String), t(.Set, int)) 
		...</ k >
		[structural]
	
	op sprintf : K K -> K [metadata "strict=(1)"]
	rule [sprintf]:
		< k > prepareBuiltin((Identifier("sprintf")), (Dest:KResult,, Format:KResult,, VarArgs:KResult))
			=> sprintf(formatter(getString(Format:KResult), VarArgs:KResult), Dest:KResult)
		...</ k >
		[structural]
	rule [sprintf-done]:
		< k > sprintf(formattedResult(S:#String), Dest:KResult)
			=> writeString(Dest:KResult, S:#String +String "\0")
			~> tv(lengthString(S:#String), t(.Set, int))
		...</ k >
		[structural]
	
	op snprintf : K K #Nat -> K [metadata "strict=(1)"]
	rule [snprintf]:
		< k > prepareBuiltin((Identifier("snprintf")), (Dest:KResult,, tv(Len:#Nat, _),, Format:KResult,, VarArgs:KResult))
			=> snprintf(formatter(getString(Format:KResult), VarArgs:KResult), Dest:KResult, Len:#Nat)
		...</ k >
		[structural]
	rule [snprintf-done-nz]:
		< k > snprintf(formattedResult(S:#String), Dest:KResult, Len:#Nat)
			=> writeString(Dest:KResult, substrString(S:#String, 0, Len:#Nat -Int 1) +String "\0")
			~> tv(lengthString(S:#String), t(.Set, int))
		...</ k >
		when Len:#Nat >Nat 0
		[structural]
	rule [snprintf-done-0]:
		< k > snprintf(formattedResult(S:#String), _, 0)
			=> tv(lengthString(S:#String), t(.Set, int))
		...</ k >
		[structural]
	
	op new-printf-aux : K -> K [metadata "strict=()"]
	op formatter : K K -> K [metadata "strict=(1)"]
	op formatter-aux : K -> K [metadata "strict=()"]
	op formatter-next : K -> K
	op formatter-arg : K -> K [metadata "strict=(1)"]
	rule 
		< k > formatter-next(vararg(tv(Loc:#Nat, _)))
			=> formatter-arg(nextvarg(Loc:#Nat, getFormatType))
		...</ k >
		[structural]
	rule 
		< k > formatter-arg(vpair(tv(K:K, _), V':KResult))
			=> formatter-aux(V':KResult)
		...</ k >
		<formatArg> _ => K:K </formatArg>
		[structural]

	
	op stringToList : #String -> List
	op listToString : List -> #String
	
	rule stringToList("") => .List
		[structural]
	rule stringToList(S:#String) 
			=> ListItem(firstChar(S:#String)) stringToList(butFirstChar(S:#String))
		when S:#String =/=Bool ""
		[structural]
		
	rule listToString(.List) => ""
		[structural]
	rule listToString((ListItem(S:#String) L:List))
			=> S:#String +String listToString(L:List)
		[structural]
	
	rule [format-start]:
		< k > formatter(str(S:#String), VarArgs:KResult)
			=> formatter-aux(VarArgs:KResult)
		...</ k >
		(.Bag => 
			<formatting>...
				<format> stringToList(S:#String) </format>
			...</formatting>
		)
		[structural]
	
	op formattedResult : K -> Value
	
	rule [format-done]:
		< k > formatter-aux(_) 
			=> formattedResult(listToString(Result:List))
		...</ k >
		(
			<formatting>...
				<format> .List </format>
				<formatResult> Result:List </formatResult>
				<formatState> "normal" </formatState>
				<formatModifiers> .Map </formatModifiers>
			...</formatting>
			=> .Bag
		)
		[structural]

	rule [format-normal]:
		< k > formatter-aux(_) ...</ k >
		<format> ListItem(S:#String) => .List ...</format>
		<formatResult>... .List => ListItem(S:#String) </formatResult>
		<formatState> "normal" </formatState>
		when S:#String =/=Bool "%"
		[structural]
		
	rule [format-reset]:
		< k > formatter-aux(_) ...</ k >
		<formatModifiers> _ => .Map </formatModifiers>
		<formatLength> _ => "" </formatLength>
		<formatState> "reset" => "normal" </formatState>
		[structural]

	rule [format-%]:
		< k > formatter-aux(_) ...</ k >
		<format> ListItem("%") => .List ...</format>
		<formatState> "normal" => "%" </formatState>
		[structural]

	// %[flags][width][.precision][length]type	
	
	/*@ \source[n1570]{\para{7.21.6.1}{4}}
	Each conversion specification is introduced by the character \texttt{\%}. After the \texttt{\%}, the following appear in sequence:
\begin{itemize}
\item Zero or more flags (in any order) that modify the meaning of the conversion specification.
\item An optional minimum field width. If the converted value has fewer characters than the field width, it is padded with spaces (by default) on the left (or right, if the left adjustment flag, described later, has been given) to the field width. The field width takes the form of an asterisk \texttt{*} (described later) or a nonnegative decimal integer.)
\item An optional precision that gives the minimum number of digits to appear for the \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, and \texttt{X} conversions, the number of digits to appear after the decimal-point character for \texttt{a}, \texttt{A}, \texttt{e}, \texttt{E}, \texttt{f}, and \texttt{F} conversions, the maximum number of significant digits for the \texttt{g} and \texttt{G} conversions, or the maximum number of bytes to be written for s conversions. The precision takes the form of a period (\texttt{.}) followed either by an asterisk \texttt{*} (described later) or by an optional decimal integer; if only the period is specified, the precision is taken as zero. If a precision appears with any other conversion specifier, the behavior is undefined.
\item An optional length modifier that specifies the size of the argument.
\item A conversion specifier character that specifies the type of conversion to be applied.
\end{itemize}
	*/

	/*@ \source[n1570]{\para{7.21.6.1}{5}}
	As noted above, a field width, or precision, or both, may be indicated by an asterisk. In this case, an \cinline{int} argument supplies the field width or precision. The arguments specifying field width, or precision, or both, shall appear (in that order) before the argument (if any) to be converted. A negative field width argument is taken as a \texttt{-} flag followed by a positive field width. A negative precision argument is taken as if the precision were omitted.
	*/
	
	/*@ \source[n1570]{\para{7.21.6.1}{6}}
	The flag characters and their meanings are:
\begin{description}
\item[\texttt{-}]
\broken{The result of the conversion is left-justified within the field. (It is right-justified if this flag is not specified.)}
\item[\texttt{+}]
\broken{The result of a signed conversion always begins with a plus or minus sign. (It begins with a sign only when a negative value is converted if this flag is not specified.)}
\item[\emph{space}]
\broken{If the first character of a signed conversion is not a sign, or if a signed conversion results in no characters, a space is prefixed to the result. If the \emph{space} and \texttt{+} flags both appear, the \emph{space} flag is ignored.}
\item[\texttt{\#}]
\broken{The result is converted to an ``alternative form''. For \texttt{o} conversion, it increases the precision, if and only if necessary, to force the first digit of the result to be a zero (if the value and precision are both 0, a single 0 is printed). For \texttt{x} (or \texttt{X}) conversion, a nonzero result has \texttt{0x} (or \texttt{0X}) prefixed to it. For \texttt{a}, \texttt{A}, \texttt{e}, \texttt{E}, \texttt{f}, \texttt{F}, \texttt{g}, and \texttt{G} conversions, the result of converting a floating-point number always contains a decimal-point character, even if no digits follow it. (Normally, a decimal-point character appears in the result of these conversions only if a digit follows it.) For \texttt{g} and \texttt{G} conversions, trailing zeros are \emph{not} removed from the result. For other conversions, the behavior is undefined.}
\item[\texttt{0}]
\broken{For \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, \texttt{X}, \texttt{a}, \texttt{A}, \texttt{e}, \texttt{E}, \texttt{f}, \texttt{F}, \texttt{g}, and \texttt{G} conversions, leading zeros (following any indication of sign or base) are used to pad to the field width rather than performing space padding, except when converting an infinity or NaN. If the \texttt{0} and \texttt{-} flags both appear, the \texttt{0} flag is ignored. For \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, and \texttt{X} conversions, if a precision is specified, the \texttt{0} flag is ignored.}
\end{description}
For other conversions, the behavior is undefined.
*/

	// fixme ignoring 0 flag for now
	rule [format-%0]:
		< k > formatter-aux(_) ...</ k >
		<format> ListItem("0") => .List ...</format>
		<formatState> "%" </formatState>
		[structural]
		
	// ignoring num width
	rule [format-width]:
		< k > formatter-aux(_) ...</ k >
		<format> ListItem(C:#Char) => .List ...</format>
		<formatState> "%" </formatState>
		when charToAscii(C:#Char) >Int asciiCharString("0")
		andBool charToAscii(C:#Char) <=Int asciiCharString("9")
		[structural]	

/*@ \source[n1570]{\para{7.21.6.1}{7}}
The length modifiers and their meanings are:
\begin{description}
\item[\texttt{hh}]
\broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{signed char} or \cinline{unsigned char} argument (the argument will have been promoted according to the integer promotions, but its value shall be converted to \cinline{signed char} or \cinline{unsigned char} before printing); or that a following \texttt{n} conversion specifier applies to a pointer to a \cinline{signed char} argument.}
\item[\texttt{h}]
\broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{short int} or \cinline{unsigned short int} argument (the argument will have been promoted according to the integer promotions, but its value shall be converted to \cinline{short int} or \cinline{unsigned short int} before printing); or that a following \texttt{n} conversion specifier applies to a pointer to a \cinline{short int} argument.}
\item[\texttt{l} (ell)]
Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{long int} or \cinline{unsigned long int} argument; that a following \texttt{n} conversion specifier applies to a pointer to a \cinline{long int} argument; \broken{that a following \texttt{c} conversion specifier applies to a \cinline{wint_t} argument; that a following \texttt{s} conversion specifier applies to a pointer to a \cinline{wchar_t} argument}; or has no effect on a following \texttt{a}, \texttt{A}, \texttt{e}, \texttt{E}, \texttt{f}, \texttt{F}, \texttt{g}, or \texttt{G} conversion specifier.
\item[\texttt{ll} (ell-ell)]
Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{long long int} or \cinline{unsigned long long int} argument; or that a following \texttt{n} conversion specifier applies to a pointer to a \cinline{long long int} argument.
\item[\texttt{j}]
\broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to an \cinline{intmax_t} or \cinline{uintmax_t} argument; or that a following \texttt{n} conversion specifier applies to a pointer to an \cinline{intmax_t} argument.}
\item[\texttt{z}]
\broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{size_t} or the corresponding signed integer type argument; or that a following \texttt{n} conversion specifier applies to a pointer to a signed integer type corresponding to \cinline{size_t} argument.}
\item[\texttt{t}]
\broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{ptrdiff_t} or the corresponding unsigned integer type argument; or that a following \texttt{n} conversion specifier applies to a pointer to a \cinline{ptrdiff_t} argument.}
\item[\texttt{L}]
\broken{Specifies that a following \texttt{a}, \texttt{A}, \texttt{e}, \texttt{E}, \texttt{f}, \texttt{F}, \texttt{g}, or \texttt{G} conversion specifier applies to a \cinline{long double} argument.}
\end{description}
If a length modifier appears with any conversion specifier other than as specified above, the behavior is undefined.
*/

	op getFormatType : -> K
	op getFormatType-aux : K K -> K 
	rule 
		<k> getFormatType => getFormatType-aux(State:K, Length:K) ...</k>
		<formatLength> Length:K </formatLength>
		<formatState> State:K </formatState>
		[structural]

	rule getFormatType-aux("%a", _) => t(.Set, double) [structural]
	rule getFormatType-aux("%A", _) => t(.Set, double) [structural]
	rule getFormatType-aux("%e", _) => t(.Set, double) [structural]
	rule getFormatType-aux("%E", _) => t(.Set, double) [structural]
	rule getFormatType-aux("%f", _) => t(.Set, double) [structural]
	rule getFormatType-aux("%F", _) => t(.Set, double) [structural]
	rule getFormatType-aux("%g", _) => t(.Set, double) [structural]
	rule getFormatType-aux("%G", _) => t(.Set, double) [structural]
			
	rule getFormatType-aux("%c", "") => t(.Set, int) [structural]
	rule getFormatType-aux("%s", "") => t(.Set, pointerType(t(.Set, unsigned-char))) [structural]
	
	rule getFormatType-aux("%p", "") => t(.Set, pointerType(t(.Set, void))) [structural]
	
	rule getFormatType-aux("%d", "") => t(.Set, int) [structural]
	rule getFormatType-aux("%o", "") => t(.Set, int) [structural]
	rule getFormatType-aux("%u", "") => t(.Set, unsigned-int) [structural]
	rule getFormatType-aux("%x", "") => t(.Set, unsigned-int) [structural]
	rule getFormatType-aux("%X", "") => t(.Set, unsigned-int) [structural]
	rule getFormatType-aux("%n", "") => t(.Set, pointerType(t(.Set, int))) [structural]
	
	rule getFormatType-aux("%d", "l") => t(.Set, long-int) [structural]
	rule getFormatType-aux("%o", "l") => t(.Set, long-int) [structural]
	rule getFormatType-aux("%u", "l") => t(.Set, unsigned-long-int) [structural]
	rule getFormatType-aux("%x", "l") => t(.Set, unsigned-long-int) [structural]
	rule getFormatType-aux("%X", "l") => t(.Set, unsigned-long-int) [structural]
	rule getFormatType-aux("%n", "l") => t(.Set, pointerType(t(.Set, long-int))) [structural]
	
	rule getFormatType-aux("%d", "ll") => t(.Set, long-long-int) [structural]
	rule getFormatType-aux("%o", "ll") => t(.Set, long-long-int) [structural]
	rule getFormatType-aux("%u", "ll") => t(.Set, unsigned-long-long-int) [structural]
	rule getFormatType-aux("%x", "ll") => t(.Set, unsigned-long-long-int) [structural]
	rule getFormatType-aux("%X", "ll") => t(.Set, unsigned-long-long-int) [structural]
	rule getFormatType-aux("%n", "ll") => t(.Set, pointerType(t(.Set, long-long-int))) [structural]

		
	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{d},\texttt{i}]
The \cinline{int} argument is converted to signed decimal in the style \emph{[-]dddd}. \broken{The precision specifies the minimum number of digits to appear; if the value being converted can be represented in fewer digits, it is expanded with leading zeros. The default precision is 1. The result of converting a zero value with a precision of zero is no characters.}
\end{description}
	*/
	// rule [printf-%d-arg]:
		// < k > tv(N:#Nat, _) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, _)))
			// => printf-%d(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, int)))
		// ...</ k >
		// if N:#Nat ==Bool asciiCharString("d")
		// [structural]
	// rule [printf-%d]:
		// < k > printf-%d(Len:#Nat, Loc:#Nat, vpair(tv(D:#Int, t(_, int)), V:KResult),, _)
			// => writeToFD(1, Rat2String(D:#Int, 10))
			// ~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 10)), Loc:#Nat, V:KResult)
		// ...</ k >
		// [structural]
	rule [format-%d-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem(S:#String) => .List ...</format>
		<formatState> "%" => "%d" </formatState>
		when S:#String ==Bool "d" orBool S:#String ==Bool "i"
		[structural]
	rule [format-%d]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> D:#Int => .K </formatArg>
		<formatResult>... .List => ListItem(Rat2String(D:#Int, 10)) </formatResult>
		<formatState> "%d" => "reset" </formatState>
		[structural]
		
	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{o},\texttt{u},\texttt{x},\texttt{X}]
The \cinline{unsigned int} argument is converted to unsigned octal (\texttt{o}), unsigned decimal (\texttt{u}), or unsigned hexadecimal notation (\texttt{x} or \texttt{X}) in the style \emph{dddd}; the letters \texttt{abcdef} are used for \texttt{x} conversion and the letters \texttt{ABCDEF} for \texttt{X} conversion. \broken{The precision specifies the minimum number of digits to appear; if the value being converted can be represented in fewer digits, it is expanded with leading zeros. The default precision is 1. The result of converting a zero value with a precision of zero is no characters.}
\end{description}
	*/
	rule [format-%o-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem("o") => .List ...</format>
		<formatState> "%" => "%o" </formatState>
		[structural]
	rule [format-%o]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> D:#Int => .K </formatArg>
		<formatResult>... .List => ListItem(Rat2String(D:#Int, 8)) </formatResult>
		<formatState> "%o" => "reset" </formatState>
		[structural]
	// rule [printf-%u-arg]:
		// < k > tv(N:#Nat, _) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, _)))
			// => printf-%u(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, unsigned-int)))
		// ...</ k >
		// if N:#Nat ==Bool asciiCharString("u")
		// [structural]
	// rule [printf-%u]:
		// < k > printf-%u(Len:#Nat, Loc:#Nat, vpair(tv(D:#Int, t(_, unsigned-int)), V:KResult),, _)
			// => writeToFD(1, Rat2String(D:#Int, 10))
			// ~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 10)), Loc:#Nat, V:KResult)
		// ...</ k >
		// [structural]
	rule [format-%u-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem("u") => .List ...</format>
		<formatState> "%" => "%u" </formatState>
		[structural]
	rule [format-%u]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> D:#Int => .K </formatArg>
		<formatResult>... .List => ListItem(Rat2String(D:#Int, 10)) </formatResult>
		<formatState> "%u" => "reset" </formatState>
		[structural]		
	// rule [printf-%x-arg]:
		// < k > tv(N:#Nat, _) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, _)))
			// => printf-%x(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, unsigned-int)))
		// ...</ k >
		// if N:#Nat ==Bool asciiCharString("x")
		// [structural]	
	// rule [printf-%x]:
		// < k > printf-%x(Len:#Nat, Loc:#Nat, (vpair(tv(D:#Int, t(_, unsigned-int)), V:KResult),, _))
			// => writeToFD(1, Rat2String(D:#Int, 16))
			// ~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 16)), Loc:#Nat, V:KResult)
		// ...</ k >
		// [structural]
	rule [format-%x-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem("x") => .List ...</format>
		<formatState> "%" => "%x" </formatState>
		[structural]
	rule [format-%x]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> D:#Int => .K </formatArg>
		<formatResult>... .List => ListItem(Rat2String(D:#Int, 16)) </formatResult>
		<formatState> "%x" => "reset" </formatState>
		[structural]
	// rule [printf-%X-arg]:
		// < k > tv(N:#Nat, _) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, _)))
			// => printf-%X(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, unsigned-int)))
		// ...</ k >
		// if N:#Nat ==Bool asciiCharString("X")
		// [structural]
	// rule [printf-%X]:
		// < k > printf-%X(Len:#Nat, Loc:#Nat, (vpair(tv(D:#Int, t(_, unsigned-int)), V:KResult),, _))
			// => writeToFD(1, toUpperCase(Rat2String(D:#Int, 16)))
			// ~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 16)), Loc:#Nat, V:KResult)
		// ...</ k >
		// [structural]
	rule [format-%X-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem("X") => .List ...</format>
		<formatState> "%" => "%X" </formatState>
		[structural]
	rule [format-%X]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> D:#Int => .K </formatArg>
		<formatResult>... .List => ListItem(toUpperCase(Rat2String(D:#Int, 16))) </formatResult>
		<formatState> "%X" => "reset" </formatState>
		[structural]

	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{f},\texttt{F}]
A \cinline{double} argument representing a floating-point number is converted to decimal notation in the style \emph{[-]ddd.ddd}, \broken{where the number of digits after the decimal-point character is equal to the precision specification. If the precision is missing, it is taken as 6; if the precision is zero and the \texttt{\#} flag is not specified, no decimal-point character appears. If a decimal-point character appears, at least one digit appears before it. The value is rounded to the appropriate number of digits.}

A \cinline{double} argument representing an infinity is converted in one of the styles \emph{[-]inf} or \emph{[-]infinity}---which style is implementation-defined.  A \cinline{double} argument representing a NaN is converted in one of the styles \emph{[-]nan} or \emph{[-]nan}(\emph{n-char-sequence})---which style, and the meaning of any \emph{n-char-sequence}, is implementation-defined. The \texttt{F} conversion specifier produces \cinline{INF}, \cinline{INFINITY}, or \cinline{NAN} instead of \cinline{inf}, \cinline{infinity}, or \cinline{nan}, respectively.
\end{description}
	*/		
	// rule [printf-%f-arg]:
		// < k > tv(N:#Nat, _) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, _)))
			// => printf-%f(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, double)))
		// ...</ k >
		// if N:#Nat ==Bool asciiCharString("f") orBool N:#Nat ==Bool asciiCharString("g")
		// [structural]
	// rule [printf-%f]:
		// < k > printf-%f(Len:#Nat, Loc:#Nat, (vpair(tv(D:#Float, t(_, double)), V:KResult),, _))
			// => writeToFD(1, Float2String(D:#Float))
			// ~> printf-aux(Len:#Nat +Nat lengthString(Float2String(D:#Float)), Loc:#Nat, V:KResult)
		// ...</ k >
		// [structural]
	rule [format-%f-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem("f") => .List ...</format>
		<formatState> "%" => "%f" </formatState>
		[structural]
	rule [format-%f]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> D:#Float => .K </formatArg>
		<formatResult>... .List => ListItem(Float2String(D:#Float)) </formatResult>
		<formatState> "%f" => "reset" </formatState>
		[structural]
	rule [format-%F-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem("F") => .List ...</format>
		<formatState> "%" => "%F" </formatState>
		[structural]
	rule [format-%F]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> D:#Float => .K </formatArg>
		<formatResult>... .List => ListItem(toUpperCase(Float2String(D:#Float))) </formatResult>
		<formatState> "%F" => "reset" </formatState>
		[structural]
		
	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{e},\texttt{E}]
\broken{A \cinline{double} argument representing a floating-point number is converted in the style \emph{[-]d.ddde$\pm{}$dd}, where there is one digit (which is nonzero if the argument is nonzero) before the decimal-point character and the number of digits after it is equal to the precision; if the precision is missing, it is taken as 6; if the precision is zero and the \texttt{\#} flag is not specified, no decimal-point character appears. The value is rounded to the appropriate number of digits. The \texttt{E} conversion specifier produces a number with \texttt{E} instead of e introducing the exponent. The exponent always contains at least two digits, and only as many more digits as necessary to represent the exponent. If the value is zero, the exponent is zero.}

\broken{A double argument representing an infinity or NaN is converted in the style of an \texttt{f} or \texttt{F} conversion specifier.}
\end{description}
	*/

	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{g},\texttt{G}]
A \cinline{double} argument representing a floating-point number is converted in style \texttt{f} or \texttt{e} (or in style \texttt{F} or \texttt{E} in the case of a \texttt{G} conversion specifier), depending on the value converted and the precision. \broken{Let $P$ equal the precision if nonzero, 6 if the precision is omitted, or 1 if the precision is zero.  Then, if a conversion with style \texttt{E} would have an exponent of $X$:}
\begin{itemize}
\item \broken{if $P > X = -4$, the conversion is with style \texttt{f} (or \texttt{F}) and precision $P - (X + 1)$.}
\item \broken{otherwise, the conversion is with style \texttt{e} (or \texttt{E}) and precision $P - 1$.}
\end{itemize}
\broken{Finally, unless the \texttt{\#} flag is used, any trailing zeros are removed from the fractional portion of the result and the decimal-point character is removed if there is no fractional portion remaining.}

A \cinline{double} argument representing an infinity or NaN is converted in the style of an \texttt{f} or \texttt{F} conversion specifier.
\end{description}
	*/
	rule [format-%g-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem("g") => .List ...</format>
		<formatState> "%" => "%g" </formatState>
		[structural]
	rule [format-%g]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> D:#Float => .K </formatArg>
		<formatResult>... .List => ListItem(Float2String(D:#Float)) </formatResult>
		<formatState> "%g" => "reset" </formatState>
		[structural]
	rule [format-%G-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem("G") => .List ...</format>
		<formatState> "%" => "%G" </formatState>
		[structural]
	rule [format-%G]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> D:#Float => .K </formatArg>
		<formatResult>... .List => ListItem(toUpperCase(Float2String(D:#Float))) </formatResult>
		<formatState> "%G" => "reset" </formatState>
		[structural]
	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{a},\texttt{A}]
\ldots
\end{description}
	*/

	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{c}]
If no \texttt{l} length modifier is present, the \cinline{int} argument is converted to an \cinline{unsigned char}, and the resulting character is written. 

\broken{If an \texttt{l} length modifier is present, the \cinline{wint_t} argument is converted as if by an \texttt{ls} conversion specification with no precision and an argument that points to the initial element of a two-element array of \cinline{wchar_t}, the first element containing the \cinline{wint_t} argument to the \texttt{lc} conversion specification and the second a null wide character.}
\end{description}
	*/
	// rule [printf-%c-arg]:
		// < k > tv(N:#Nat, _) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, _)))
			// => printf-%c(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, int)))
		// ...</ k >
		// if N:#Nat ==Bool asciiCharString("c")
		// [structural]
	// rule [format-%c-start]:
		// < k > formatter-aux(
			// vararg(tv(Loc:#Nat, _)) => nextvarg(Loc:#Nat, t(.Set, int))
		// )
		// ...</ k >
		// <format> ListItem("c") => .List ...</format>
		// <formatState> "%" => "%c" </formatState>
		// [structural]		
	rule [format-%c-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)
		...</ k >
		<format> ListItem("c") => .List ...</format>
		<formatState> "%" => "%c" </formatState>
		[structural]
	// // need to cast to unsigned-char
	// rule [printf-%c]:
		// < k > printf-%c(Len:#Nat, Loc:#Nat, (vpair(tv(C:#Nat, t(_, int)), V:KResult),, _))
			// => writeToFD(1, C:#Nat)
			// ~> printf-aux(Len:#Nat +Nat 1, Loc:#Nat, V:KResult)
		// ...</ k >
		// [structural]
	rule [format-%c]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> C:#Int => .K </formatArg>
		<formatResult>... .List => ListItem(charString(((C:#Int %Int 256) +Int 256) %Int 256)) </formatResult>
		<formatState> "%c" => "reset" </formatState>
		[structural]
		
	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{s}]
If no \texttt{l} length modifier is present, the argument shall be a pointer to the initial element of an array of character type. Characters from the array are written up to (but not including) the terminating null character. \broken{If the precision is specified, no more than that many bytes are written.} If the precision is not specified or is greater than the size of the array, the array shall contain a null character.

\broken{If an \texttt{l} length modifier is present, the argument shall be a pointer to the initial element of an array of \cinline{wchar_t} type. Wide characters from the array are converted to multibyte characters (each as if by a call to the \cinline{wcrtomb} function, with the conversion state described by an \cinline{mbstate_t} object initialized to zero before the first wide character is converted) up to and including a terminating null wide character. The resulting multibyte characters are written up to (but not including) the terminating null character (byte). If no precision is specified, the array shall contain a null wide character. If a precision is specified, no more than that many bytes are written (including shift sequences, if any), and the array shall contain a null wide character if, to equal the multibyte character sequence length given by the precision, the function would need to access a wide character one past the end of the array. In no case is a partial multibyte character written.}
\end{description}
	*/
	rule [format-%s-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)		
		...</ k >
		<format> ListItem("s") => .List ...</format>
		<formatState> "%" => "%s" </formatState>
		[structural]
	rule [format-%s]:
		< k > (.K => getString(Loc:#Nat))
			~> formatter-aux(_)
		...</ k >
		<formatArg> Loc:#Nat => .K </formatArg>
		<formatState> "%s" => "%s-read" </formatState>
		[structural]
	rule [format-%s-done]:
		< k > (str(S:#String) => .K)
			~> formatter-aux(_)
		...</ k >
		<formatResult>... .List => ListItem(S:#String) </formatResult>
		<formatState> "%s-read" => "reset" </formatState>
		[structural]

	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{p}]
The argument shall be a pointer to \cinline{void}. The value of the pointer is converted to a sequence of printing characters, in an implementation-defined manner.
\end{description}
	*/
	// rule [printf-%p-arg]:
		// < k > tv(N:#Nat, _) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, _)))
			// => printf-%p(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, pointerType(t(.Set, void)))))
		// ...</ k >
		// if N:#Nat ==Bool asciiCharString("p")
		// [structural]
	// rule [printf-%p]:
		// < k > printf-%p(Len:#Nat, Loc:#Nat, (vpair(tv(N':#Nat, t(_, pointerType(t(_, void)))), V:KResult),, _))
			// => writeToFD(1, pointerToString(N':#Nat))
			// ~> printf-aux(Len:#Nat +Nat lengthString(pointerToString(N':#Nat)), Loc:#Nat, V:KResult)
		// ...</ k >
		// [structural]
	rule [format-%p-start]:
		< k > formatter-aux(V:KResult)
			=> formatter-next(V:KResult)		
		...</ k >
		<format> ListItem("p") => .List ...</format>
		<formatState> "%" => "%p" </formatState>
		[structural]
	rule [format-%p]:
		< k > formatter-aux(_) ...</ k >
		<formatArg> Loc:#Nat => .K </formatArg>
		<formatResult>... .List => ListItem(pointerToString(Loc:#Nat)) </formatResult>
		<formatState> "%p" => "reset" </formatState>
		[structural]
		
	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{n}]
\broken{The argument shall be a pointer to signed integer into which is \emph{written} the number of characters written to the output stream so far by this call to \cinline{fprintf}. No argument is converted, but one is consumed. If the conversion specification includes any flags, a field width, or a precision, the behavior is undefined.}
\end{description}
	*/
	
	/*@ \source[n1570]{\para{7.21.6.1}{8}}
\begin{description}
\item[\texttt{\%}]
A \texttt{\%} character is written. No argument is converted. The complete conversion specification shall be \texttt{\%\%}.
\end{description}
	*/
	rule [format-%%]:
		< k > formatter-aux(_) ...</ k >
		<format> ListItem("%") => .List ...</format>
		<formatResult>... .List => ListItem("%") </formatResult>
		<formatState> "%" => "reset" </formatState>
		[structural]

	rule [format-%l]:
		< k > formatter-aux(_) ...</ k >
		<format> ListItem("l") => .List ...</format>
		<formatState> "%" </formatState>
		<formatLength> Length:#String => Length:#String +String "l" </formatLength>
		[structural]
endkm


kmod DYNAMIC-C-STANDARD-LIBRARY-STDLIB is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	rule [debug]:
		< k > prepareBuiltin(Identifier("__debug"), _) => skipval ...</ k >
		[interpRule]
	
	rule [exit]:
		< k > prepareBuiltin((Identifier("exit")), tv(I:#Int, t(_, int))) ~> _ 
			=> tv(I:#Int, t(.Set, int)) 
		</ k >
		[structural]

	rule [abort]:
		< k > prepareBuiltin((Identifier("abort")), .List{K}) ~> _
			=> printString("Aborted")
			~> tv(134, t(.Set, int))
		</ k >
	
	/*@ \source[n1570]{\para{7.22.3.4}{2--3}}
	The \cinline{malloc} function allocates space for an object whose size is specified by \cinline{size} and whose value is indeterminate.

The malloc function returns either a null pointer or a pointer to the allocated space.
	*/
	rule [malloc]:
		< k > prepareBuiltin((Identifier("malloc")), tv(Len:#Nat, T:KResult))
			=> alloc(Loc, Len:#Nat)
			~> tv(Loc, t(.Set, pointerType(t(.Set, void))))
		...</ k >
		< malloced >... .Map => Loc |-> Len:#Nat ...</ malloced >
		< freshNat > Fresh:#Nat => Fresh:#Nat +Nat 1 </ freshNat >
		where Loc = sym(threadId(allocatedDuration) +Nat Fresh:#Nat) +Nat 0
		[structural]
	// might want this for searching purposes
	// rule [malloc-null]:
		// < k > prepareBuiltin((Identifier("malloc")), tv(Len:#Nat, T:KResult))
			// => tv(NullPointer, t(.Set, pointerType(void)))
		// ...</ k >
		// [structural]
		
	/*@ \source[n1570]{\para{7.22.3.5}{2--4}}
	The \cinline{realloc} function deallocates the old object pointed to by \cinline|ptr| and returns a pointer to a new object that has the size specified by \cinline|size|. The contents of the new object shall be the same as that of the old object prior to deallocation, up to the lesser of the new and old sizes. Any bytes in the new object beyond the size of the old object have indeterminate values.

If \cinline|ptr| is a null pointer, the \cinline|realloc| function behaves like the \cinline|malloc| function for the specified size. Otherwise, if \cinline|ptr| does not match a pointer earlier returned by a memory management function, or if the space has been deallocated by a call to the \cinline|free| or \cinline|realloc| function, the behavior is undefined. If memory for the new object cannot be allocated, the old object is not deallocated and its value is unchanged.

The \cinline|realloc| function returns a pointer to the new object (which may have the same value as a pointer to the old object), or a null pointer if the new object could not be allocated.
	*/
	rule [realloc]:
		< k > prepareBuiltin((Identifier("realloc")), (tv(OldLoc:#Nat, _),, tv(NewLen:#Nat, T:KResult)))
			=> realloc(OldLoc:#Nat, NewLoc, OldLen:#Nat, NewLen:#Nat)
			~> tv(NewLoc, t(.Set, pointerType(t(.Set, void))))
		...</ k >
		< malloced >... (OldLoc:#Nat => NewLoc) |-> (OldLen:#Nat => NewLen:#Nat) ...</ malloced >
		< freshNat > Fresh:#Nat => Fresh:#Nat +Nat 1 </ freshNat >
		when OldLoc:#Nat =/=Bool NullPointer
		where NewLoc = sym(threadId(allocatedDuration) +Nat Fresh:#Nat) +Nat 0
		[structural]
	rule [realloc-null]:
		< k > prepareBuiltin((Identifier("realloc")), (tv(NullPointer, _),, Len:KResult))
			=> prepareBuiltin((Identifier("malloc")), Len:KResult)
		...</ k >
		[structural]

	op calloc-aux : -> K
	rule [calloc]:
		< k > prepareBuiltin((Identifier("calloc")), (tv(N:#Nat, _),, tv(Size:#Nat, _)))
			=> prepareBuiltin((Identifier("malloc")), tv(N:#Nat *Nat Size:#Nat, cfg:sizeut))
			~> calloc-aux
		...</ k >
		[structural]
	rule [calloc-aux]:
		< k > (.K => zeroBlock(Loc:#Nat)) 
			~> tv(Loc:#Nat, t(_, pointerType(t(_, void))))
			~> (calloc-aux => .K)
		...</ k >
		[structural]

	rule [free]:
		< k > prepareBuiltin((Identifier("free")), tv(Loc:#Nat, t(_, pointerType(_))))
			=> deleteSizedBlock(Loc:#Nat, Len:#Nat) 
			~> skipval
		...</ k >
		< malloced >... Loc:#Nat |-> Len:#Nat => .Map ...</ malloced >
		[structural]
		
	// Returns a pseudo-random integral number in the range 0 to RAND_MAX
	// fixme should use RAND_MAX
	rule [rand]:
		< k > prepareBuiltin((Identifier("rand")), .List{K})
			=> tv(absInt(randomRandom(Fresh:#Nat)) %Int max(t(.Set, int)), t(.Set, int))
		...</ k >
		< randNat > Fresh:#Nat => sNat(Fresh:#Nat) </ randNat >
		[structural]
		
	rule [srand]:
		< k > prepareBuiltin((Identifier("srand")), tv(N:#Nat, t(.Set, unsigned-int)))
			=> skipval
		...</ k >
		< randNat > _ => N:#Nat </ randNat >
		[structural]


endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-STRING is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	// fixme should detect overlaps
	op strcpy : K K K -> K
	rule [strcpy-start]:
		< k > prepareBuiltin((Identifier("strcpy")), (tv(Dest:#Nat, t(_, pointerType(_))),, tv(Src:#Nat, t(_, pointerType(_)))))
			=> strcpy(Dest:#Nat, Src:#Nat, Dest:#Nat)
		...</ k >
		[structural]
		
	rule [strcpy-pre]:
		< k > (.K => read(Src:#Nat, t(.Set, char)))
			~> strcpy(_, (Src:#Nat => sNat(Src:#Nat)), _)
		...</ k >
		[structural]
	
	rule [strcpy-some]:
		< k > (tv(I:#Int, T:KResult) => write(lv(Dest:#Nat, t(.Set, char)), tv(I:#Int, T:KResult)))
			~> strcpy((Dest:#Nat => sNat(Dest:#Nat)), _, _)
		...</ k >
		when I:#Int =/=Bool 0
		[structural]
	rule [strcpy-done]:
		< k > tv(0, T:KResult) ~> strcpy(Dest:#Nat, _, Orig:#Nat)
			=> write(lv(Dest:#Nat, t(.Set, char)), tv(0, T:KResult)) 
			~> tv(Orig:#Nat, t(.Set, pointerType(t(.Set, char))))
		...</ k >
		[structural]
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-THREADS is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	////////////////////////////--
	// Threads
	////////////////////////////--
	ops thrd-success thrd-error thrd-timeout thrd-busy thrd-nomem : -> #Nat
	macro thrd-success = tv(0, t(.Set, int))
	macro thrd-error = tv(1, t(.Set, int))
	macro thrd-timeout = tv(2, t(.Set, int))
	macro thrd-busy = tv(3, t(.Set, int))
	macro thrd-nomem = tv(4, t(.Set, int))
	
	ops threadRunning threadClosed : -> K
	ops threadJoining : #Nat -> K
	
	op threadId : #Nat #Nat -> #Nat // parent, new
	op spawn-aux : #Nat Value Value -> K
	// threadId(MyId:#Nat, Fresh:#Nat)
	rule [thrd-create-start]:
		< k > prepareBuiltin((Identifier("thrd_create")), (ThreadIdPointer:KResult,, ThreadFuncPointer:KResult,, ThreadArg:KResult))
			=> Computation((* ThreadIdPointer:KResult) := tv(Fresh:#Nat, t(.Set, int)))
			~> spawn-aux(Fresh:#Nat, ThreadFuncPointer:KResult, ThreadArg:KResult)
		...</ k >
		<threadId> MyId:#Nat </threadId>
		< nextThreadId > Fresh:#Nat => sNat(Fresh:#Nat) </ nextThreadId >
		[structural]
/*
See http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1521.htm
*/
		
	rule [thrd-create]:
		< thread >
			< nextLoc > _:#Nat </ nextLoc >
			< threadId > _:#Nat </ threadId >
			C:Bag
			< k > spawn-aux(ThreadId:#Nat, ThreadFuncPointer:KResult, ThreadArg:KResult) => thrd-success ...</ k >
			< threadLocal >
				< callStack > _:List </ callStack >
				C'':Bag // just calculateGoto I think
				< control >
					C':Bag
				</ control >
			</ threadLocal >
		</ thread >
		(.Bag =>
		< thread >
			< nextLoc > sym(threadId(ThreadId:#Nat) +Nat 0) +Nat 0 </ nextLoc >
			< threadId > ThreadId:#Nat </ threadId >
			C:Bag
			< k > Call(ThreadFuncPointer:KResult, List(ThreadArg:KResult)) </ k >
			< threadLocal >
				< callStack > .List </ callStack >
				< control >
					C':Bag
				</ control >
			</ threadLocal >
		</ thread >)
		< threadStatus > Status:Map => Status:Map[threadRunning / ThreadId:#Nat] </ threadStatus >
		[metadata "computational=()"]
		
	rule [thrd-current]:
		< k > prepareBuiltin((Identifier("thrd_current")), .List{K})
			=> tv(ThreadId:#Nat, t(.Set, int))
		...</ k >
		< threadId > ThreadId:#Nat </ threadId >
		[structural]
		
	op join-aux : #Nat Value -> K
		
	rule [thrd-join-start]:
		< k > prepareBuiltin((Identifier("thrd_join")), (tv(ThreadId:#Nat, t(_, int)),, ResultPointer:KResult))
			=> join-aux(ThreadId:#Nat, ResultPointer:KResult)
		...</ k >
		< threadId > MyId:#Nat </ threadId >
		< joiningMap > Joining:Map => Joining:Map[MyId:#Nat / ThreadId:#Nat] </ joiningMap >
		< detachingMap > Detaching:Map </ detachingMap >
		when notBool $hasMapping(Joining:Map, ThreadId:#Nat)
		andBool notBool $hasMapping(Detaching:Map, ThreadId:#Nat)
		[structural]
	
	rule [thrd-join-error]:
		< k > prepareBuiltin((Identifier("thrd_join")), (tv(ThreadId:#Nat, t(_, int)),, _))
			=> thrd-error
		...</ k >
		< joiningMap > Joining:Map </ joiningMap >
		< detachingMap > Detaching:Map </ detachingMap >
		when $hasMapping(Joining:Map, ThreadId:#Nat)
		orBool $hasMapping(Detaching:Map, ThreadId:#Nat)
		[metadata "computational=()"]
	
	// at this point, we've already "locked" the join/detach.  This is the blocking part
	rule [thrd-join]:
		< thread >...
			< k > join-aux(ThreadId:#Nat, ResultPointer:KResult)
				=> Computation((* ResultPointer:KResult) := cast(t(.Set, int), V:KResult))
				~> thrd-success
			...</ k >
		...</ thread >
		< thread >...
			< k > V:KResult </ k >
			< threadId > ThreadId:#Nat </ threadId >
		...</ thread >
		[metadata "computational=()"]

	op testAndSet : K K K -> K [metadata "strict=(1)"]
	rule [test-and-set-start]:
		< k > prepareBuiltin((Identifier("__test_and_set")), (Loc:KResult,, V:KResult))
			=> testAndSet(*(Loc:KResult), Loc:KResult, V:KResult)
		...</ k >
		[structural]
		
	rule [test-and-set]:
		< k > testAndSet(Retval:KResult, Loc:KResult, V:KResult)
			=> Computation((* Loc:KResult) := V:KResult)
			~> Retval:KResult
		...</ k >
		[structural]
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-TIME is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	// fixme, just a placeholder
	rule [time]:
		< k > prepareBuiltin((Identifier("time")), _:KResult)
			=> tv(0, t(.Set, long-long-int))
		...</ k >
		[structural]
	
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-MISC is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE

endkm

////////////////////////////////
//- C standard library
kmod DYNAMIC-C-STANDARD-LIBRARY is
	including DYNAMIC-INCLUDE
	including DYNAMIC-C-STANDARD-LIBRARY-HELPERS
	
	including DYNAMIC-C-STANDARD-LIBRARY-MATH
	including DYNAMIC-C-STANDARD-LIBRARY-SETJMP
	including DYNAMIC-C-STANDARD-LIBRARY-STDARG
	including DYNAMIC-C-STANDARD-LIBRARY-STDDEF
	including DYNAMIC-C-STANDARD-LIBRARY-STDIO 
	including DYNAMIC-C-STANDARD-LIBRARY-STDLIB
	including DYNAMIC-C-STANDARD-LIBRARY-STRING
	including DYNAMIC-C-STANDARD-LIBRARY-THREADS
	including DYNAMIC-C-STANDARD-LIBRARY-TIME
	
	including DYNAMIC-C-STANDARD-LIBRARY-MISC
endkm
