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

	op Error : String Id K String -> K
	rule Error(Name:String, F:Id, Loc:K, Msg:String)  => 
		"Error: " +String Name:String +String "\n"
		+String printFunction(F:Id)
		+String printLoc(Loc:K)
		+String Msg:String +String "\n"
		[structural]
		
	op printFunction : Id -> String
	rule printFunction(Identifier(F:String)) => 
		"Function: " +String F:String +String "\n"
		[structural]
		
	op printLoc : K -> String
	rule printLoc(CabsLoc(File:String, LineNo:Int, Offset:Int, ?)) => 
		"File: " +String File:String +String "\n"
		+String "Line: " +String Int2String(LineNo:Int) +String "\n"
		+String "ByteOffset: " +String Int2String(Offset:Int) +String "\n"		
		[structural]
	rule printLoc(UnknownCabsLoc) => 
		"File: Unknown\n"
		+String "Line: Unknown\n"
		+String "ByteOffset: Unknown\n"
		[structural]	
		
		
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
		
		
	rule 
		< T >...
			< k > cast(T:Type, emptyValue) ...</ k > 
			<currentFunction> F:Id </currentFunction>
			<currentProgramLoc> Loc:K </currentProgramLoc>
		...</ T >
		=> < errorCell > Error("00001", F:Id, Loc:K, "Trying to cast void to some other type.  This may be caused by failing to return a value from a function that is supposed to return a value.") </ errorCell >
		//if T:Type =/=Bool emptyValue // moduleError `[ ERROR `] Error while wrapping Syntax lists into K `( module LISTS-TO-WRAPPERS `) `[ ENDERROR `] \n To reproduce load k-prelude and then the generated module. \n \n ---K-MAUDE-GENERATED-OUTPUT-BEGIN---
		if T:Type =/=Bool void
		[structural]

endkm
