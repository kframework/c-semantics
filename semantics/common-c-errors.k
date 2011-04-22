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
		if Offset:Nat >=Int Size:Nat
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
		
	rule [err00005a]:
		< k => finalComputation > extractByteFromMem(sym(Block:Nat) +Nat ?) ...</ k => finalComputation >
		< mem > M:Map </ mem >
		(.Bag => < errorCell > Error("00005", "Referring to an object outside of its lifetime.") </ errorCell >)
		if notBool $hasMapping(M:Map, Block:Nat)
		[structural]
		
	rule [err00005b]:
		< k => finalComputation > checkValidLoc-aux(sym(Block:Nat) +Nat ?) ...</ k => finalComputation >
		< mem > M:Map</ mem >
		(.Bag => < errorCell > Error("00005", "Referring to an object outside of its lifetime.") </ errorCell >)
		if notBool $hasMapping(M:Map, Block:Nat)
		[structural]
	
	rule [err00006a]:
		< k => finalComputation > joinIntegerBytes-aux(T:Type, (?:List{K},, piece(unknown(Len:Nat), Len:Nat)), ?:K) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00006", "Reading uninitialized memory.") </ errorCell >)
		if notBool hasCharType(T:Type)
		[structural]	
	
	rule [err00006b]:
		< k => finalComputation > concretize(pointerType(?), dataList((piece(unknown(Len:Nat), Len:Nat),, ?))) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00006", "Reading uninitialized memory.") </ errorCell >)
		[structural]
	
	rule [err00006c]:
		< k => finalComputation > concretize(T:Type, dataList((piece(unknown(Len:Nat), Len:Nat),, ?))) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00006", "Reading uninitialized memory.") </ errorCell >)
		if hasFloatType(T:Type)
		[structural]
		
	
	//if T:Type =/=Bool emptyValue // moduleError `[ ERROR `] Error while wrapping Syntax lists into K `( module LISTS-TO-WRAPPERS `) `[ ENDERROR `] \n To reproduce load k-prelude and then the generated module. \n \n ---K-MAUDE-GENERATED-OUTPUT-BEGIN---

endkm
