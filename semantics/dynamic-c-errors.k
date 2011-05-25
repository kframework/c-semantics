kmod DYNAMIC-SEMANTICS-ERRORS-INCLUDE is
	including COMMON-C-SEMANTICS

	including DYNAMIC-C-SEMANTICS-MISC
	including DYNAMIC-C-EXPRESSIONS
	including DYNAMIC-C-TYPING 
	including DYNAMIC-C-DECLARATIONS 
	including DYNAMIC-C-MEMORY 
	including DYNAMIC-C-STATEMENTS 
	including DYNAMIC-C-CONVERSIONS 
	including DYNAMIC-C-STANDARD-LIBRARY

endkm

kmod DYNAMIC-C-ERRORS is
	including DYNAMIC-SEMANTICS-ERRORS-INCLUDE

	op Error : String String -> K
	rule Error(Name:String, Msg:String)  => 
		//"=====================================================\n"
		//+String "ERROR! KCC encountered an error while executing this program.\n"
		"Error: " 
		+String Name:String 
		+String "\n"
		+String "Description: " 
		+String Msg:String
		[structural]
		
	// op printFunction : Id -> String
	// rule printFunction(Identifier(F:String)) => 
		// "Function: " +String F:String +String "\n"
		// [structural]
		
	// op printLoc : K -> String
	// rule printLoc(CabsLoc(File:String, LineNo:Int, ?, ?)) => 
		// "File: " +String File:String +String "\n"
		// +String "Line: " +String Int2String(LineNo:Int) +String "\n"
		// //+String "ByteOffset: " +String Int2String(Offset:Int) +String "\n"		
		// [structural]
	// rule printLoc(UnknownCabsLoc) => 
		// "File: Unknown\n"
		// +String "Line: Unknown\n"
		// +String "ByteOffset: Unknown\n"
		// [structural]
		
		
	// rule 
		// < T >... 
			// < k > cast(T:Type, emptyValue) ...</ k > 
			// // <currentFunction> F:Id </currentFunction>
			// // <currentProgramLoc> Loc:K </currentProgramLoc>
		// ...</ T >
		// => 
		// .Bag
		// // <errorCell> 
			// // ""
			// // // Error("00001", F:Id, Loc:K, "Trying to cast void to some other type.  This is probably caused by failing to return a value from a function that is supposed to return a value.")
		// // </errorCell>		
		// if T:Type =/=Bool emptyValue
		// [structural]
		
	op halted-k : -> CellLabel 
	op halted-T : -> CellLabel
	op halt_ : Bag -> Bag
	rule halt < k => halted-k > _:K </ k => halted-k > [structural]
	rule halt < L:CellLabel > K:K </ L:CellLabel > => < L:CellLabel > K:K </ L:CellLabel > 
		if L:CellLabel =/=Bool k 
		[structural]
	rule halt < L:CellLabel > B:Bag </ L:CellLabel > => < L:CellLabel > halt B:Bag </ L:CellLabel > [structural]
	rule halt < L:CellLabel > K:Set </ L:CellLabel > => < L:CellLabel > K:Set </ L:CellLabel > [structural]
	rule halt < L:CellLabel > K:Map </ L:CellLabel > => < L:CellLabel > K:Map </ L:CellLabel > [structural]
	rule halt < L:CellLabel > K:List </ L:CellLabel > => < L:CellLabel > K:List </ L:CellLabel > [structural]
	rule halt .Bag => .Bag [structural]
	
	rule [halt-start]:
		< T => halted-T >...
			< threads > 
				(B:Bag => halt B:Bag)
				< thread >...
					< finalComputation > ?:K </ finalComputation >
				...</ thread > 
			</ threads > 
		...</ T => halted-T >
		[structural]
	
	rule [err00001]:
		< k => finalComputation > cast(T:Type, emptyValue) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00001", "Casting void to some other type.") </ errorCell >)
		if T:Type =/=Bool void
		[structural]
		
	rule [err00002]:
		< k => finalComputation > extractByteFromMem(sym(Block:Nat) +Nat Offset:Nat) ...</ k => finalComputation >
		< mem >... Block:Nat |-> memblock(Size:Nat, ?) ...</ mem >
		(.Bag => < errorCell > Error("00002", "Reading outside the bounds of an object.") </ errorCell >)
		if Offset:Nat >=Nat Size:Nat
		[structural]
		
	rule [err00003]:
		< k => finalComputation > extractByteFromMem(Loc:Nat) ...</ k => finalComputation >
		< locsWrittenTo >... BagItem(Loc:Nat) ...</ locsWrittenTo >
		(.Bag => < errorCell > Error("00003", "Unsequenced side effect on scalar object with value computation of same object.") </ errorCell >)
		[structural]
	
	// rule [err00004]:
		// < k => finalComputation > extractByteFromMem(Loc:Int) ...</ k => finalComputation >
		// (.Bag => < errorCell > Error("00004", "Trying to read memory at a location that is not based on a pointer.") </ errorCell >)
		// if Loc:Int >=Int 0 // if it can compare to 0, then it is not a symbolic location
		// [structural]
		
	rule [err00005]:
		< k => finalComputation > extractByteFromMem(sym(Block:Nat) +Nat ?) ...</ k => finalComputation >
		< mem > M:Map </ mem >
		(.Bag => < errorCell > Error("00005", "Referring to an object outside of its lifetime.") </ errorCell >)
		if notBool $hasMapping(M:Map, Block:Nat)
		[structural]
	
	rule [err00006]:
		< k => finalComputation > joinIntegerBytes-aux(T:Type, (?:List{K},, piece(unknown(Len:Nat), Len:Nat)), ?:K) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00006", "Reading uninitialized memory, or trying to read a pointer or float through an integer type.") </ errorCell >)
		if notBool hasCharType(T:Type)
		[structural]
		
	rule [err00007]:
		< k => finalComputation > checkValidLoc-aux(sym(Block:Nat) +Nat ?) ...</ k => finalComputation >
		< mem > M:Map </ mem >
		(.Bag => < errorCell > Error("00007", "Referring to an object outside of its lifetime.") </ errorCell >)
		if notBool $hasMapping(M:Map, Block:Nat)
		[structural]
	
	rule [err00008]:
		< k => finalComputation > concretize(pointerType(?), dataList((piece(unknown(Len:Nat), Len:Nat),, ?))) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00008", "Reading uninitialized memory.") </ errorCell >)
		[structural]
	
	rule [err00009]:
		< k => finalComputation > concretize(T:Type, dataList((piece(unknown(Len:Nat), Len:Nat),, ?))) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00009", "Reading uninitialized memory.") </ errorCell >)
		if hasFloatType(T:Type)
		[structural]
		
	rule [err00010]:
		< k => finalComputation > checkValidLoc-aux(sym(Block:Nat) +Nat Offset:Nat) ...</ k => finalComputation >
		< mem >... Block:Nat |-> memblock(Size:Nat, ?) ...</ mem >
		(.Bag => < errorCell > Error("00010", "Found pointer that refers outside the bounds of an object + 1.") </ errorCell >)
		if Offset:Nat >Nat Size:Nat
		[structural]
		
		
	rule [err00011]:
		< k => finalComputation > tv(?, T:Type) < tv(?, T':Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00011", "Directly comparing an integer type with a pointer type.") </ errorCell >)
		if (hasIntegerType(T:Type) andBool hasPointerType(T':Type))
		orBool (hasPointerType(T:Type) andBool hasIntegerType(T':Type))
		[structural]
	rule [err00012]:
		< k => finalComputation > tv(?, T:Type) <= tv(?, T':Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00012", "Directly comparing an integer type with a pointer type.") </ errorCell >)
		if (hasIntegerType(T:Type) andBool hasPointerType(T':Type))
		orBool (hasPointerType(T:Type) andBool hasIntegerType(T':Type))
		[structural] 
	rule [err00013]:
		< k => finalComputation > tv(?, T:Type) > tv(?, T':Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00013", "Directly comparing an integer type with a pointer type.") </ errorCell >)
		if (hasIntegerType(T:Type) andBool hasPointerType(T':Type))
		orBool (hasPointerType(T:Type) andBool hasIntegerType(T':Type))
		[structural] 
	rule [err00014]:
		< k => finalComputation > tv(?, T:Type) >= tv(?, T':Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00014", "Directly comparing an integer type with a pointer type.") </ errorCell >)
		if (hasIntegerType(T:Type) andBool hasPointerType(T':Type))
		orBool (hasPointerType(T:Type) andBool hasIntegerType(T':Type))
		[structural] 
		
	rule [err00015]:
		< k => finalComputation > arithInterpret(T:Type, I:Int) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00015", "Signed overflow.") </ errorCell >)
		if hasSignedIntegerType(T:Type)
		andBool notBool (min(T:Type) <=Int I:Int andBool max(T:Type) >=Int I:Int)
		[structural] 	
		
		
	rule [err00016]:
		< k => finalComputation > writeByte(Loc:Nat, ?) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00016", "Unsequenced side effect on scalar object with side effect of same object.") </ errorCell >)
		< locsWrittenTo > Locs:Bag </ locsWrittenTo >
		if Loc:Nat in Locs:Bag
		[structural] 
		
	rule [err00017]:
		< k => finalComputation > tv(I1:Int, T:Type) / tv(0, T:Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00017", "Division by 0.") </ errorCell >)
		if hasIntegerType(T:Type)
		andBool hasBeenPromoted(T:Type)
		[structural]
	
	rule [err00018]:
		< k => finalComputation > tv(I1:Int, T:Type) % tv(0, T:Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00018", "Modulus by 0.") </ errorCell >)
		if hasIntegerType(T:Type)
		andBool hasBeenPromoted(T:Type)
		[structural]
		
	rule [err00019]:
		< k => finalComputation > tv(I1:Int, T:Type) % tv(I2:Int, T:Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00019", "Signed overflow.") </ errorCell >)
		if hasIntegerType(T:Type)
		andBool notBool (min(T:Type) <=Int I1:Int /Int I2:Int andBool max(T:Type) >=Int I1:Int /Int I2:Int)
		andBool hasBeenPromoted(T:Type)
		andBool I2:Int =/=Bool 0
		[structural]
		
	rule [err00020]:
		< k => finalComputation > writeByte(sym(Block:Nat) +Nat Offset:Nat, ?) ...</ k => finalComputation >
		< mem >... Block:Nat |-> memblock(Len:Nat, ?) ...</ mem >		
		(.Bag => < errorCell > Error("00020", "Tried to write outside the bounds of an object.") </ errorCell >)
		if notBool Offset:Nat <Nat Len:Nat
		[structural] 
		
	rule [err00021]:
		< k => finalComputation > Identifier(S:String) ...</ k => finalComputation >
		< env > M:Map </ env >
		(.Bag => < errorCell > Error("00021", "Trying to look up identifier  " +String S:String +String " , but no such identifier is in scope.") </ errorCell >)
		if notBool $hasMapping(M:Map, Identifier(S:String))
		[structural]
		
	rule [err00022]:
		< k => finalComputation > leftShiftInterpret(T:Type, I:Int, tv(E1:Int, T:Type)) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00022", "Trying to left-shift a negative signed value.") </ errorCell >)
		if hasSignedIntegerType(T:Type)
		andBool E1:Int <Int 0
		[structural]
		
	rule [err00023]:
		< k => finalComputation > leftShiftInterpret(T:Type, I:Int, tv(E1:Nat, T:Type)) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.") </ errorCell >)
		if hasSignedIntegerType(T:Type)
		andBool notBool (I:Int <=Int (2 ^Nat absInt(numBits(T:Type))))
		[structural]
		
	rule [err00025]:
		< k => finalComputation > callMain-aux(functionType(T:Type, ?), ?, ?, ?) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00025", "Main must return an int.") </ errorCell >)
		if T:Type =/=Bool int
		[structural]
	rule [err00026]:
		< k => finalComputation > 
			callMain-aux(functionType(int, (typedDeclaration(T:Type, ?) :: ?:List{Type})), ?, ?, ?) 
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00026", "If main has arguments, the type of the first argument must be equivalent to \"int\".") </ errorCell >)
		if T:Type =/=Bool int andBool T:Type =/=Bool void
		[structural]
		
	op isArgvType : Type -> Bool
	
	rule isArgvType(T:Type) => false
		if notBool (
			getKLabel(T:Type) ==Bool 'incompleteArrayType 
			orBool getKLabel(T:Type) ==Bool 'incompleteArrayType
		)
		[structural]
		
	rule isArgvType(incompleteArrayType(T:Type)) => false
		if notBool getKLabel(T:Type) ==Bool 'pointerType
		[structural]
	rule isArgvType(incompleteArrayType(pointerType(T:Type))) => false
		if T:Type =/=Bool char
		[structural]
		
	rule isArgvType(pointerType(T:Type)) => false
		if notBool getKLabel(T:Type) ==Bool 'pointerType
		[structural]
	rule isArgvType(pointerType(pointerType(T:Type))) => false
		if T:Type =/=Bool char
		[structural]
	
	rule [err00027]:
		< k => finalComputation >
			callMain-aux(functionType(int, (typedDeclaration(int, ?) :: typedDeclaration(T:Type, ?))), ?, ?, ?) 
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00027", "If main has arguments, the type of the second argument must be equivalent to  char** .") </ errorCell >)
		if notBool isArgvType(T:Type)
		[structural]
	rule [err00028]:
		< k => finalComputation >
			callMain-aux(functionType(int, (?:Type :: ?:Type :: ?:Type :: ?:List{Type})), ?, ?, ?) 
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00028", "Main can only have zero or two arguments.") </ errorCell >)
		[structural]
	rule [err00029]:
		< k => finalComputation > 
			callMain-aux(functionType(int, (typedDeclaration(T:Type, ?))), ?, ?, ?)
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00029", "Main can only have zero or two arguments.") </ errorCell >)
		if T:Type =/=Bool void
		[structural]
		

		
		
	//if T:Type =/=Bool emptyValue // moduleError `[ ERROR `] Error while wrapping Syntax lists into K `( module LISTS-TO-WRAPPERS `) `[ ENDERROR `] \n To reproduce load k-prelude and then the generated module. \n \n ---K-MAUDE-GENERATED-OUTPUT-BEGIN---

endkm
