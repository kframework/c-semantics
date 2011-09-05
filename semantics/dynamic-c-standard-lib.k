// load maudeLib/TCPSupport
require /modules/uris

kmod DYNAMIC-C-STANDARD-LIBRARY-INCLUDE is
	including DYNAMIC-INCLUDE 
	including URIS
	// including #SOCKET
	// including #TCP-INTERFACE
	
	op vararg : K -> C [metadata "hybrid=() strict=()"]
	op nextvarg : #Nat Type -> C
	op vpair : K K -> C [metadata "hybrid=() strict=()"]
	op prepareBuiltin : #Id List{C} -> K
	op incSymbolic : K -> K
	op printString : K -> K
	
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-HELPERS is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	rule reval(vararg(K:K)) => vararg(K:K) [structural]
	// fixme had to make this K because of the context bug
	op nextvarg-aux : K Type K K -> C // offset, type, length
	context nextvarg-aux(?, ?, value(`[HOLE`]:K), ?)
	context nextvarg-aux(?, ?, ?, value(`[HOLE`]:K))
	
	rule [nextvarg-start]:
		< k > nextvarg(Loc:#Nat, T:Type)
			=> nextvarg-aux(Loc:#Nat, T:Type, value(byteSizeofType(T:Type)), value(sizeofLocation(Loc:#Nat)))
		...</ k >
		[structural]
	rule [nextvarg]:
		< k > nextvarg-aux(Loc:#Nat, T:Type, Len:#Nat, Len:#Nat)
			=> vpair(read(Loc:#Nat, T:Type), vararg(tv(inc(Loc:#Nat), t(.Set, pointerType(t(.Set, void))))))
		...</ k >
		[structural]
	

	context 'prepareBuiltin(_:K,, '_::_(_:List`{K`},, (`[HOLE`]:C => reval(`[HOLE`]:C)),, _:List`{K`}))
	
	op idsFromDeclList : List{C} -> List{C}
	
	rule [idsFromDeclList-one]:
		idsFromDeclList(L:List{C} :: typedDeclaration(t(?, T:SimpleType), X:#Id))
			=> idsFromDeclList(L:List{C}) :: X:#Id
		if T:SimpleType =/=Bool void
		[structural]
	rule [idsFromDeclList-void]:
		idsFromDeclList(L:List{C} :: typedDeclaration(t(?, void), X:#Id))
			=> idsFromDeclList(L:List{C})
		[structural]
	rule [idsFromDeclList-vararg]:
		idsFromDeclList(L:List{C} :: typedDeclaration(T:Type, X:#Id) :: t(?, variadic))
			=> idsFromDeclList(L:List{C} :: typedDeclaration(T:Type, X:#Id))
			:: vararg(incSymbolic(cast(t(.Set, pointerType(t(.Set, unsigned-char))), &(X:#Id))))
			// assumes variadic args are placed in incremental blocks
		[structural]
	rule [idsFromDeclList-done]:
		idsFromDeclList(Nil) => Nil [structural]
	

	context incSymbolic(([HOLE] => reval([HOLE])))
	rule [incSymbolic]:
		incSymbolic(tv(Loc:#Nat, T:Type)) => tv(inc(Loc:#Nat), T:Type)
		[structural]
		
	rule [prepareBuiltin]:
		< k > handleBuiltin(F:#Id, t(?, functionType(Return:Type, L:List{Type})))
			=> Return(prepareBuiltin(F:#Id, idsFromDeclList(L:List{Type})))
		...</ k >
		[structural]
		
	rule
		< k > printString(S:#String)
			=> writeToFD(1, asciiCharString(firstChar(S:#String)))
			~> printString(butFirstChar(S:#String))
		...</ k >
		if lengthString(S:#String) >Nat 0
		[structural]
	rule
		< k > printString("") => writeToFD(1, 10) ...</ k >
		[structural]
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-MATH is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	rule [sqrt]:
		< k > prepareBuiltin((Identifier("sqrt")), tv(F:#Float, t(?, double)))
			=> tv(sqrtFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [log]:
		< k > prepareBuiltin((Identifier("log")), tv(F:#Float, t(?, double)))
			=> tv(logFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [exp]:
		< k > prepareBuiltin((Identifier("exp")), tv(F:#Float, t(?, double)))
			=> tv(expFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [atan]:
		< k > prepareBuiltin((Identifier("atan")), tv(F:#Float, t(?, double)))
			=> tv(atanFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [asin]:
		< k > prepareBuiltin((Identifier("asin")), tv(F:#Float, t(?, double)))
			=> tv(asinFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [atan2]:
		< k > prepareBuiltin((Identifier("atan2")), (tv(F:#Float, t(?, double)) :: tv(F':#Float, t(?, double))))
			=> tv(atanFloat(F:#Float, F':#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [tan]:
		< k > prepareBuiltin((Identifier("tan")), tv(F:#Float, t(?, double)))
			=> tv(tanFloat(F:#Float), t(.Set, double))
		...</ k >
	[structural]

	rule [floor]:
		< k > prepareBuiltin((Identifier("floor")), tv(F:#Float, t(?, double)))
			=> tv(floorFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [cos]:
		< k > prepareBuiltin((Identifier("cos")), tv(F:#Float, t(?, double)))
			=> tv(cosFloat(F:#Float), t(.Set, double))
		...</ k >
		[structural]

	rule [fmod]:
		< k > prepareBuiltin((Identifier("fmod")), (tv(F:#Float, t(?, double)) :: tv(F':#Float, t(?, double))))
			=> tv(F:#Float %Float F':#Float, t(.Set, double))
		...</ k >
		[structural]

	rule [sin]:
		< k > prepareBuiltin((Identifier("sin")), tv(F:#Float, t(?, double)))
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
		< k > (prepareBuiltin(Identifier("setjmp"), tv(Loc:#Nat, t(?, pointerType(t(?, structType(Identifier("__jmp_buf_tag")))))))
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
		< k > prepareBuiltin(Identifier("longjmp"), (V:Value :: V':Value))
			=> longjmp-aux(reval(*(V:Value)), V':Value)
		...</ k >
		[structural]
	
	// fixme: memory leak here with extra ignoreLocals.  needed for recursive setjmp/longjmp as in Looping.c
	rule [longjmp]:
		< k > longjmp-aux(tv(Bag(
					< continuation > K:K </ continuation >
					C:Bag
			), t(?, structType(Identifier("__jmp_buf_tag")))), tv(I:#Int, t(?, int))) ~> ?
			=> ignoreLocals ~> if I:#Int ==Bool 0 then tv(1, t(.Set, int)) else tv(I:#Int, t(.Set, int)) fi ~> K:K
		</ k >
		< threadLocal >
			? => C:Bag
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
	rule [va_start]:
		< k > prepareBuiltin((Identifier("__va_start")), (ApLoc:Value :: ArgLoc:Value))
				=> Computation(*(ApLoc:Value) := incSymbolic(ArgLoc:Value))
				~> skipval
		...</ k >
		[structural]
	
	op va-inc-aux : K K K -> K // [metadata "strict=(3)"]
	context va-inc-aux(_, _, ([HOLE] => reval([HOLE])))
	// fixme can do lots of checks here too
	
	// this doesn't work because when we read apLoc, the object has already changed
	rule
		< k > prepareBuiltin((Identifier("__va_inc")), (ApLoc:Value :: Size:Value))
				=> Computation(*(ApLoc:Value) := incSymbolic(ApLoc:Value))
				~> ApLoc:Value
		...</ k >
		[structural]
	
	rule [va_inc-start]:
		< k > prepareBuiltin((Identifier("__va_inc")), (ApLoc:Value :: Size:Value))
				=> va-inc-aux(ApLoc:Value, Size:Value, *ApLoc:Value)
		...</ k >
		[structural]
				
	rule [va_inc]:
		< k > va-inc-aux(ApLoc:Value, Size:Value, Ap:Value)
			=> Computation(*(ApLoc:Value) := incSymbolic(Ap:Value))
			~> Ap:Value
		...</ k >
		[structural]				
		
	// fixme can do lots of checks here too
	rule [va_copy]:
		< k > prepareBuiltin((Identifier("__va_copy")), (ApLoc:Value :: Other:Value))
				=> Computation(*(ApLoc:Value) := Other:Value)
				~> skipval
		...</ k >
		[structural]
		
	// fixme can do lots of checks here too
	// tool fixme, shouldn't let me compile empty rule
	// rule
		// < k > prepareBuiltin((Identifier("__va_end")), (ApLoc:Value))
				// ~> skipval
		// ...</ k >
		// [structural]
	rule [va_end]:
		< k > prepareBuiltin((Identifier("__va_end")), (ApLoc:Value))
				=> skipval
		...</ k >
		[structural]
endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-STDDEF is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE

	op offsetOf : K K -> K [metadata "strict=(1)"]
	rule
		< k > OffsetOf(T:Type, K:K, F:#Id) => offsetOf(DeclType(T:Type, K:K), F:#Id) ...</ k >
		[structural]
	// fixme should check for bitfield offset
	rule
		< k > offsetOf(t(?, structType(S:#Id)), F:#Id)
			=> tv(bitsToBytes(Offset:#Nat), cfg:sizeut)
		...</ k >
		< structs >...
			S:#Id |-> aggregateInfo(?, ?, (? F:#Id |-> Offset:#Nat))
		...</ structs >
		[structural]
	rule < k > offsetOf(t(?, unionType(?)), ?) => tv(0, cfg:sizeut) ...</ k >
		[structural]
endkm


kmod DYNAMIC-C-STANDARD-LIBRARY-STDIO is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE

	// fixme doesn't cast to int
	rule [putchar]:
		< k > prepareBuiltin((Identifier("putchar")), tv(N:#Nat, ?))
			=> writeToFD(1, N:#Nat) 
			~> tv(N:#Nat, t(.Set, int))
		...</ k >
		[structural]

	// fixme doesn't cast to int
	rule [fslPutc]:
		< k > prepareBuiltin((Identifier("__fslPutc")), (tv(N:#Nat, ?) :: tv(H:#Nat, ?)))
			=> writeToFD(H:#Nat, N:#Nat)
			~> tv(N:#Nat, t(.Set, int))
		...</ k >
		[structural]

	rule [getchar]:
		< k > prepareBuiltin((Identifier("getchar")), Nil) => readFromFD(0) ...</ k >
		[structural]

	rule [fslFGetC]:
		< k > prepareBuiltin((Identifier("__fslFGetC")), (tv(FD:#Nat, ?) :: tv(Offset:#Nat, ?)))
			// => readFromFD(FD:#Nat)
			=> #fReadByte(FD:#Nat)
		...</ k >
		[structural]
		
	rule [read-eof]:
		< k > String2Int(errorTCPSyntax("EOF")) => tv(-1, t(.Set, int)) ...</ k >
		[structural]	

	rule [fslCloseFile]:
		< k > prepareBuiltin((Identifier("__fslCloseFile")), tv(FD:#Nat, t(?, int))) 
			=> tv(0, t(.Set, int))
		...</ k >
		< openFiles >... FD:#Nat |-> ? => .Map ...</ openFiles >
		[structural]

	rule [fslOpenFile-pre]:
		< k > prepareBuiltin((Identifier("__fslOpenFile")), Loc:Value)
			=> fsl-open-file(getString(Loc:Value))
		...</ k >
		[structural]
	
	op fsl-open-file-aux : #String K -> K [metadata "strict=(2)"]
	
	// rule [fslOpenFile-aux]:
		// < k > fsl-open-file(str(S:#String), FD:#Nat)
			// => fsl-open-file-aux(S:#String, FD:#Nat, readFile(S:#String))
		// ...</ k >
		// [structural]
	rule [fslOpenFile-aux]:
		< k > fsl-open-file(str(S:#String))
			=> fsl-open-file-aux("file:" +String S:#String, #open("file:" +String S:#String +String "#r"))
		...</ k >
		[structural]

	// rule [fslOpenFile]:
		// < k > fsl-open-file-aux(Name:#String, FD:#Nat, Data:#String) => tv(0, t(.Set, int)) ...</ k >
		// < openFiles > M:Map => M:Map[Name:#String / FD:#Nat] </ openFiles >
		// < files > M':Map => M':Map[Data:#String / Name:#String] </ files >
		// if lengthString(Data:#String) >=Nat 0 // if it's a real string
		// [structural]
	rule [fslOpenFile]:
		< k > fsl-open-file-aux(Name:#String, tv(FD:#Nat, ?)) => tv(FD:#Nat, t(.Set, int)) ...</ k >
		< openFiles > M:Map => M:Map[Name:#String / FD:#Nat] </ openFiles >
		//< files > M':Map => M':Map[Data:#String / Name:#String] </ files >
		//if lengthString(Data:#String) >=Nat 0 // if it's a real string
		[structural]

	op fsl-open-file : K -> K [metadata "strict=(1)"]
	op getString : K -> K
	op getString-aux : K #String -> K [metadata "strict=(1)"]
	rule [getString-start]: getString(K:K) => getString-aux(K:K, "") [structural]
	op str : #String -> Value
	
	rule [getString-pre]:
		< k > (.K => read(Loc:#Nat, t(.Set, char)))
			~> getString-aux(tv((Loc:#Nat => sNat(Loc:#Nat)), t(?, pointerType(T:Type))), S:#String)
		...</ k >
		[structural]
		
	rule [getString]:
		< k > tv(N:#Nat, ?) 
			~> getString-aux(tv(Loc:#Nat, t(?, pointerType(T:Type))), S:#String)
			=> getString-aux(tv(Loc:#Nat, t(.Set, pointerType(T:Type))), S:#String +String charString(N:#Nat))
		...</ k >
		if N:#Nat =/=Bool 0
		[structural]
	rule [getString-done]:
		< k > tv(0, ?) ~> getString-aux(tv(Loc:#Nat, t(?, pointerType(?))), S:#String)
			=> str(S:#String)
		...</ k >
		[structural]
	//////////////////////////--	
	
	op printf-aux : #Nat #Nat List{C} -> K
	op printf-string : #Nat #Nat -> K
	op printf-% : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%l : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%ld : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%ll : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%llu : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%lld : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%llx : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%llX : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%x : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%X : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%d : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%f : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%u : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%s : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%c : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	op printf-%p : K K List{C} -> K [metadata "strict=(3)"] // K not nat, for context bug
	
	
	//C1X Here we might want to assume different threads cannot interleave wrt printf, based on 7.1.4:5.  However, 7.1.4:4 seems to say exactly the opposite.
	// on second thought, it probably is saying that while the shared data is protected against races, it can still be interleaved
	// fixme despite the above, still need to handle interleaving of user data read during evaluation of printf.  should use something like a buffer to do this
	rule [printf]:
		< k > prepareBuiltin((Identifier("printf")), (tv(Loc:#Nat, t(?, pointerType(?))) :: L:List{C})) => printf-aux(0, Loc:#Nat, L:List{C}) ...</ k >
		[structural]
		
		
	rule [printf-prepare-string]:
		< k > (.K => read(Loc:#Nat, t(.Set, char))) ~> printf-string(Len:#Nat, (Loc:#Nat => sNat(Loc:#Nat))) ...</ k >
		[structural]
		
	rule [printf-string]:
		< k > tv(N:#Nat, ?) ~> printf-string(Len:#Nat, Loc:#Nat)
			=> writeToFD(1, N:#Nat)
			~> printf-string(sNat(Len:#Nat), Loc:#Nat)
		...</ k >
		if N:#Nat =/=Bool 0
		[structural]
	
	rule [printf-string-done]:
		< k > tv(0, ?) ~> printf-string(Len:#Nat, Loc:#Nat) => tv(Len:#Nat, t(.Set, int)) ...</ k >
		[structural]
	
	rule [printf-prepare-normal]:
		< k > (.K => read(Loc:#Nat, t(.Set, char))) ~> printf-aux(Len:#Nat, (Loc:#Nat => sNat(Loc:#Nat)), L:List{C}) ...</ k >
		[structural]
	
	//fixme why do i have to have the 0--255 check?
	rule [printf-normal]:
		< k > tv(N:#Nat, ?) ~> printf-aux(Len:#Nat, Loc:#Nat, L:List{C})
			=> writeToFD(1, N:#Nat) ~> printf-aux(sNat(Len:#Nat), Loc:#Nat, L:List{C})
		...</ k >
		if N:#Nat =/=Bool asciiCharString("%")
		andBool N:#Nat =/=Bool 0
		andBool N:#Nat >=Nat 0
		andBool N:#Nat <=Nat 255
		[structural]
	
	rule [printf-done]:
		< k > tv(0, ?) ~> printf-aux(Len:#Nat, ?, ?) => tv(Len:#Nat, t(.Set, int)) ...</ k >
		[structural]
		
	rule [printf-%]:
		< k > tv(N:#Nat, ?) ~> printf-aux(Len:#Nat, Loc:#Nat, L:List{C})
			=> printf-%(Len:#Nat, Loc:#Nat, L:List{C})
		...</ k >
		if (N:#Nat ==Bool asciiCharString("%"))
		[structural]
		
	rule [printf-prepare-%]:
		< k > (.K => read(Loc:#Nat, t(.Set, char))) ~> printf-%(Len:#Nat, (Loc:#Nat => sNat(Loc:#Nat)), L:List{C}) ...</ k >
		[structural]

	rule [printf-%%]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, L:List{C})
			=> writeToFD(1, N:#Nat)
			~> printf-aux(sNat(Len:#Nat), Loc:#Nat, L:List{C}) ...</ k >
		if N:#Nat ==Bool asciiCharString("%")
		[structural]
		
	// fixme ignoring 0 flag for now
	rule [printf-0]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, L:List{C})
			=> printf-%(Len:#Nat, Loc:#Nat, L:List{C})
		...</ k >
		if N:#Nat ==Bool asciiCharString("0")
		[structural]
		
	// ignoring num width
	rule [printf-width]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, L:List{C})
			=> printf-%(Len:#Nat, Loc:#Nat, L:List{C})
		...</ k >
		if N:#Nat >Int asciiCharString("0")
		andBool N:#Nat <=Int asciiCharString("9")
		[structural]
	
	rule [printf-%x-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%x(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, unsigned-int)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("x")
		[structural]
	rule [printf-%X-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%X(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, unsigned-int)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("X")
		[structural]
		
	rule [printf-%x]:
		< k > printf-%x(Len:#Nat, Loc:#Nat, (vpair(tv(D:#Int, t(?, unsigned-int)), V:Value) :: ?))
			=> writeToFD(1, Rat2String(D:#Int, 16))
			~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 16)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
	rule [printf-%X]:
		< k > printf-%X(Len:#Nat, Loc:#Nat, (vpair(tv(D:#Int, t(?, unsigned-int)), V:Value) :: ?))
			=> writeToFD(1, toUpperCase(Rat2String(D:#Int, 16)))
			~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 16)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
		
	op toUpperCase : #String -> #String
	op toUpperCase : #Char -> #Char
	rule toUpperCase(S:#String)
		=> toUpperCase(firstChar(S:#String)) +String toUpperCase(butFirstChar(S:#String))
		if S:#String =/=Bool ""
		[structural]
	rule toUpperCase("") => "" [structural]
		
	rule toUpperCase(C:#Char)
		=> C:#Char
		if asciiString(C:#Char) <Nat asciiString("a")
		orBool asciiString(C:#Char) >Nat asciiString("z")
		[structural]
	rule toUpperCase(C:#Char)
		=> charString(absInt(asciiString(C:#Char) -Int Difference))
		if asciiString(C:#Char) >=Nat asciiString("a")
		andBool asciiString(C:#Char) <=Nat asciiString("z")
		where Difference = (asciiString("a") -Int asciiString("A"))
		[structural]
	
	// fixme might be messing things up elsewhere
	op pointerToString : #Nat -> #String
	rule [pointerToString]:
		pointerToString(sym(N:#Nat) +Nat M:#Nat)
			=> "[sym(" +String subPointerToString(N:#Nat) +String ") + " +String Rat2String(M:#Nat, 10) +String "]"
		[structural]
	op subPointerToString : #Nat -> #String
	
	// allocatedDuration
	
	// eq subPointerToString(N:#Nat) = Rat2String(N:#Nat, 10)
	rule [subPointerToString-auto]:
		subPointerToString(threadId(N:#Nat) +Nat N':#Nat)
			=> "threadId(" +String Rat2String(N:#Nat, 10) +String ") +Nat " +String Rat2String(N':#Nat, 10)
		if N:#Nat =/=Bool allocatedDuration
		[structural]
	rule [sub-pointerToString-allocated]:
		subPointerToString(threadId(allocatedDuration) +Nat N':#Nat)
			=> "threadId(allocatedDuration) +Nat " +String Rat2String(N':#Nat, 10)
		[structural]
	
	
	rule [pointerToString-done]:
		pointerToString(NullPointer) => "NullPointer" [structural]
		
	rule [printf-%p-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%p(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, pointerType(t(.Set, void)))))
		...</ k >
		if N:#Nat ==Bool asciiCharString("p")
		[structural]
	rule [printf-%p]:
		< k > printf-%p(Len:#Nat, Loc:#Nat, (vpair(tv(N':#Nat, t(?, pointerType(t(?, void)))), V:Value) :: ?))
			=> writeToFD(1, pointerToString(N':#Nat))
			~> printf-aux(Len:#Nat +Nat lengthString(pointerToString(N':#Nat)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
		
	rule [printf-%d-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%d(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, int)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("d")
		[structural]
	rule [printf-%d]:
		< k > printf-%d(Len:#Nat, Loc:#Nat, vpair(tv(D:#Int, t(?, int)), V:Value) :: ?)
			=> writeToFD(1, Rat2String(D:#Int, 10))
			~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 10)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
	
	rule [printf-%u-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%u(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, unsigned-int)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("u")
		[structural]
	rule [printf-%u]:
		< k > printf-%u(Len:#Nat, Loc:#Nat, vpair(tv(D:#Int, t(?, unsigned-int)), V:Value) :: ?)
			=> writeToFD(1, Rat2String(D:#Int, 10))
			~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 10)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
		
	rule [printf-%l]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, L:List{C})
			=> printf-%l(Len:#Nat, Loc:#Nat, L:List{C})
		...</ k >
		if N:#Nat ==Bool asciiCharString("l")
		[structural]
		
	rule [printf-prepare-%l]:
		< k > (.K => read(Loc:#Nat, t(.Set, char)))
			~> printf-%l(Len:#Nat, (Loc:#Nat => sNat(Loc:#Nat)), L:List{C}) 
		...</ k >
		[structural]
	
	rule [printf-%ld-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%l(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%ld(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, long-int)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("d")
		[structural]
	rule [printf-%ld]:
		< k > printf-%ld(Len:#Nat, Loc:#Nat, vpair(tv(D:#Int, t(?, long-int)), V:Value) :: ?)
			=> writeToFD(1, Rat2String(D:#Int, 10))
			~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 10)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
	
	rule [printf-%ll]:
		< k > tv(N:#Nat, ?) ~> printf-%l(Len:#Nat, Loc:#Nat, L:List{C})
			=> printf-%ll(Len:#Nat, Loc:#Nat, L:List{C})
		...</ k >
		if N:#Nat ==Bool asciiCharString("l")
		[structural]
		
	rule [printf-prepare-%ll]:
		< k > (.K => read(Loc:#Nat, t(.Set, char))) ~> printf-%ll(Len:#Nat, (Loc:#Nat => sNat(Loc:#Nat)), L:List{C}) ...</ k >
		[structural]
		
	rule [printf-%llx-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%ll(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%llx(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, unsigned-long-long-int)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("x")
		[structural]
		
	rule [printf-%llu-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%ll(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%llu(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, unsigned-long-long-int)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("u")
		[structural]
		
	rule [printf-%lld-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%ll(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%lld(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, long-long-int)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("d")
		[structural]
		
	rule [printf-%llu]:
		< k > printf-%llu(Len:#Nat, Loc:#Nat, vpair(tv(D:#Int, t(?, unsigned-long-long-int)), V:Value) :: ?)
			=> writeToFD(1, Rat2String(D:#Int, 10))
			~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 10)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
	rule [printf-%lld]:
		< k > printf-%lld(Len:#Nat, Loc:#Nat, vpair(tv(D:#Int, t(?, long-long-int)), V:Value) :: ?)
			=> writeToFD(1, Rat2String(D:#Int, 10))
			~> printf-aux(Len:#Nat +Nat lengthString(Rat2String(D:#Int, 10)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
	rule [printf-%llx]:
		< k > printf-%llx(Len:#Nat, Loc:#Nat, vpair(tv(D:#Int, t(?, unsigned-long-long-int)), V:Value) :: ?)
			=> writeToFD(1, (if (lengthString(Rat2String(D:#Int, 16)) ==Bool 1) then
				"0" +String Rat2String(D:#Int, 16)
			else
				Rat2String(D:#Int, 16)
			fi)) ~> printf-aux(Len:#Nat +Nat lengthString((if (lengthString(Rat2String(D:#Int, 16)) ==Bool 1) then
				"0" +String Rat2String(D:#Int, 16)
			else
				Rat2String(D:#Int, 16)
			fi)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
		
	rule [printf-%c-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%c(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, int)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("c")
		[structural]
	// need to cast to unsigned-char
	rule [printf-%c]:
		< k > printf-%c(Len:#Nat, Loc:#Nat, (vpair(tv(C:#Nat, t(?, int)), V:Value) :: ?))
			=> writeToFD(1, C:#Nat)
			~> printf-aux(Len:#Nat +Nat 1, Loc:#Nat, V:Value)
		...</ k >
		[structural]
	
	rule [printf-%f-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%f(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, double)))
		...</ k >
		if N:#Nat ==Bool asciiCharString("f") orBool N:#Nat ==Bool asciiCharString("g")
		[structural]
	rule [printf-%f]:
		< k > printf-%f(Len:#Nat, Loc:#Nat, (vpair(tv(D:#Float, t(?, double)), V:Value) :: ?))
			=> writeToFD(1, Float2String(D:#Float))
			~> printf-aux(Len:#Nat +Nat lengthString(Float2String(D:#Float)), Loc:#Nat, V:Value)
		...</ k >
		[structural]
		
		
	op addPrintfString : -> K
	
	rule [printf-%s-arg]:
		< k > tv(N:#Nat, ?) ~> printf-%(Len:#Nat, Loc:#Nat, vararg(tv(Loc':#Nat, ?)))
			=> printf-%s(Len:#Nat, Loc:#Nat, nextvarg(Loc':#Nat, t(.Set, pointerType(t(.Set, unsigned-char)))))
		...</ k >
		if N:#Nat ==Bool asciiCharString("s")
		[structural]
	rule [printf-%s]:
		< k > printf-%s(Len:#Nat, Loc:#Nat, (vpair(tv(S:#Nat, t(?, pointerType(t(?, unsigned-char)))), V:Value) :: ?))
			=> printf-string(0, S:#Nat)
			~> addPrintfString
			~> printf-aux(Len:#Nat, Loc:#Nat, V:Value)
		...</ k >
		[structural]

	rule [printf-%s-done]:
		< k > tv(Len':#Nat, t(?, int)) ~> addPrintfString ~> printf-aux(Len:#Nat, Loc:#Nat, L:List{C})
			=> printf-aux(Len:#Nat +Nat Len':#Nat, Loc:#Nat, L:List{C})
		...</ k >
		[structural]	
	
endkm


kmod DYNAMIC-C-STANDARD-LIBRARY-STDLIB is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	rule [debug]:
		< k > prepareBuiltin(Identifier("__debug"), ?) => skipval ...</ k >
		[interpRule]
	
	rule [exit]:
		< k > prepareBuiltin((Identifier("exit")), tv(I:#Int, t(?, int))) ~> ? 
			=> tv(I:#Int, t(.Set, int)) 
		</ k >
		[structural]

	rule [abort]:
		< k > prepareBuiltin((Identifier("abort")), Nil) ~> ?
			=> printString("Aborted")
			~> tv(134, t(.Set, int))
		</ k >
	
	rule [malloc]:
		< k > prepareBuiltin((Identifier("malloc")), tv(N:#Nat, T:Type))
			=> alloc(Loc, N:#Nat)
			~> tv(Loc, t(.Set, pointerType(t(.Set, void))))
		...</ k >
		< malloced >... .Map => Loc |-> N:#Nat ...</ malloced >
		< freshNat > Fresh:#Nat => Fresh:#Nat +Nat 1 </ freshNat >
		if T:Type ==Bool cfg:sizeut
		where Loc = sym(threadId(allocatedDuration) +Nat Fresh:#Nat) +Nat 0
		[structural]

	op calloc-aux : -> K
	rule [calloc]:
		< k > prepareBuiltin((Identifier("calloc")), (tv(N:#Nat, ?) :: tv(Size:#Nat, ?)))
			=> prepareBuiltin((Identifier("malloc")), tv(N:#Nat *Nat Size:#Nat, cfg:sizeut))
			~> calloc-aux
		...</ k >
		[structural]
	rule [calloc-aux]:
		< k > (.K => zeroBlock(Loc:#Nat)) 
			~> tv(Loc:#Nat, t(?, pointerType(t(?, void))))
			~> (calloc-aux => .K)
		...</ k >
		[structural]

	rule [free]:
		< k > prepareBuiltin((Identifier("free")), tv(Loc:#Nat, t(?, pointerType(?))))
			=> deleteSizedBlock(Loc:#Nat, Len:#Nat) 
			~> skipval
		...</ k >
		< malloced >... Loc:#Nat |-> Len:#Nat => .Map ...</ malloced >
		[structural]
		
	// Returns a pseudo-random integral number in the range 0 to RAND_MAX
	// fixme should use RAND_MAX
	rule [rand]:
		< k > prepareBuiltin((Identifier("rand")), Nil)
			=> tv(absInt(randomRandom(Fresh:#Nat)) %Int max(t(.Set, int)), t(.Set, int))
		...</ k >
		< freshNat > Fresh:#Nat => sNat(Fresh:#Nat) </ freshNat >
		[structural]


endkm

kmod DYNAMIC-C-STANDARD-LIBRARY-STRING is
	including DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
	
	// fixme should detect overlaps
	op strcpy : K K K -> K
	rule [strcpy-start]:
		< k > prepareBuiltin((Identifier("strcpy")), (tv(Dest:#Nat, t(?, pointerType(?))) :: tv(Src:#Nat, t(?, pointerType(?)))))
			=> strcpy(Dest:#Nat, Src:#Nat, Dest:#Nat)
		...</ k >
		[structural]
		
	rule [strcpy-pre]:
		< k > (.K => read(Src:#Nat, t(.Set, char)))
			~> strcpy(?, (Src:#Nat => sNat(Src:#Nat)), ?)
		...</ k >
		[structural]
	
	rule [strcpy-some]:
		< k > (tv(I:#Int, T:Type) => write(lv(Dest:#Nat, t(.Set, char)), tv(I:#Int, T:Type)))
			~> strcpy((Dest:#Nat => sNat(Dest:#Nat)), ?, ?)
		...</ k >
		if I:#Int =/=Bool 0
		[structural]
	rule [strcpy-done]:
		< k > tv(0, T:Type) ~> strcpy(Dest:#Nat, ?, Orig:#Nat)
			=> write(lv(Dest:#Nat, t(.Set, char)), tv(0, T:Type)) 
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
	rule [thrd_create-start]:
		< k > prepareBuiltin((Identifier("thrd_create")), (ThreadIdPointer:Value :: ThreadFuncPointer:Value :: ThreadArg:Value))
			=> Computation((* ThreadIdPointer:Value) := tv(Fresh:#Nat, t(.Set, int)))
			~> spawn-aux(Fresh:#Nat, ThreadFuncPointer:Value, ThreadArg:Value)
		...</ k >
		<threadId> MyId:#Nat </threadId>
		< nextThreadId > Fresh:#Nat => sNat(Fresh:#Nat) </ nextThreadId >
		[structural]
/*
See http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1521.htm
*/
		
	rule [thrd_create]:
		< thread >
			< nextLoc > ?:#Nat </ nextLoc >
			< threadId > ?:#Nat </ threadId >
			C:Bag
			< k > spawn-aux(ThreadId:#Nat, ThreadFuncPointer:Value, ThreadArg:Value) => thrd-success ...</ k >
			< threadLocal >
				< callStack > ?:List </ callStack >
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
			< k > Call(ThreadFuncPointer:Value, ThreadArg:Value) </ k >
			< threadLocal >
				< callStack > .List </ callStack >
				< control >
					C':Bag
				</ control >
			</ threadLocal >
		</ thread >)
		< threadStatus > Status:Map => Status:Map[threadRunning / ThreadId:#Nat] </ threadStatus >
		[metadata "computational=()"]
		
	rule [thrd_current]:
		< k > prepareBuiltin((Identifier("thrd_current")), Nil)
			=> tv(ThreadId:#Nat, t(.Set, int))
		...</ k >
		< threadId > ThreadId:#Nat </ threadId >
		[structural]
		
	op join-aux : #Nat Value -> K
		
	rule [thrd_join-start]:
		< k > prepareBuiltin((Identifier("thrd_join")), (tv(ThreadId:#Nat, t(?, int)) :: ResultPointer:Value))
			=> join-aux(ThreadId:#Nat, ResultPointer:Value)
		...</ k >
		< threadId > MyId:#Nat </ threadId >
		< joiningMap > Joining:Map => Joining:Map[MyId:#Nat / ThreadId:#Nat] </ joiningMap >
		< detachingMap > Detaching:Map </ detachingMap >
		if notBool $hasMapping(Joining:Map, ThreadId:#Nat)
		andBool notBool $hasMapping(Detaching:Map, ThreadId:#Nat)
		[structural]
	
	rule [thrd_join-error]:
		< k > prepareBuiltin((Identifier("thrd_join")), (tv(ThreadId:#Nat, t(?, int)) :: ?))
			=> thrd-error
		...</ k >
		< joiningMap > Joining:Map </ joiningMap >
		< detachingMap > Detaching:Map </ detachingMap >
		if $hasMapping(Joining:Map, ThreadId:#Nat)
		orBool $hasMapping(Detaching:Map, ThreadId:#Nat)
		[metadata "computational=()"]
	
	// at this point, we've already "locked" the join/detach.  This is the blocking part
	rule [thrd_join]:
		< thread >...
			< k > join-aux(ThreadId:#Nat, ResultPointer:Value)
				=> Computation((* ResultPointer:Value) := cast(t(.Set, int), V:Value))
				~> thrd-success
			...</ k >
		...</ thread >
		< thread >...
			< k > V:Value </ k >
			< threadId > ThreadId:#Nat </ threadId >
		...</ thread >
		[metadata "computational=()"]

	op testAndSet : K K K -> K [metadata "strict=(1)"]
	rule [test-and-set-start]:
		< k > prepareBuiltin((Identifier("__test_and_set")), (Loc:Value :: V:Value))
			=> testAndSet(*(Loc:Value), Loc:Value, V:Value)
		...</ k >
		[structural]
		
	rule [test-and-set]:
		< k > testAndSet(Retval:Value, Loc:Value, V:Value)
			=> Computation((* Loc:Value) := V:Value)
			~> Retval:Value
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
	
	including DYNAMIC-C-STANDARD-LIBRARY-MISC
endkm
