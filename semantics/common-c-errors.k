kmod COMMON-SEMANTICS-ERRORS-INCLUDE is
	including COMMON-INCLUDE 
	including C-SEMANTICS-MISC 
	
	including FIXED-C-STYLE
	including FIXED-C-STYLE-TWOS-COMPLEMENT 
	
	including COMMON-C-HELPERS
	including COMMON-C-TYPING 
	including COMMON-C-DECLARATIONS 
	including COMMON-C-MEMORY 
	including COMMON-C-STATEMENTS 
	including COMMON-C-EXPRESSIONS 
	including COMMON-C-CONVERSIONS 
	including COMMON-C-STANDARD-LIBRARY 

endkm

kmod COMMON-C-ERRORS is
	including COMMON-SEMANTICS-ERRORS-INCLUDE

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
		(.Bag => < errorCell > Error("00006", "Reading uninitialized memory.") </ errorCell >)
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
		
	
	//if T:Type =/=Bool emptyValue // moduleError `[ ERROR `] Error while wrapping Syntax lists into K `( module LISTS-TO-WRAPPERS `) `[ ENDERROR `] \n To reproduce load k-prelude and then the generated module. \n \n ---K-MAUDE-GENERATED-OUTPUT-BEGIN---

endkm
