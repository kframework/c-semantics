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

	op Error : #String #String -> K
	rule Error(Name:#String, Msg:#String)  => 
		//"=====================================================\n"
		//+String "ERROR! KCC encountered an error while executing this program.\n"
		"Error: " 
		+String Name:#String 
		+String "\n"
		+String "Description: " 
		+String Msg:#String
		[structural]
	op ICE : #String #String -> K
	rule ICE(Name:#String, Msg:#String) =>
		"Error: "
		+String Name:#String
		+String "\n"
		+String "Description: " 
		+String Msg:#String
		+String "\n"
		+String "NOTE: Please send a test case exhibiting this bug to celliso2@illnois.edu; it could indicate an internal error in KCC."
		[structural]
	
		
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
		< k => finalComputation > cast(t(?, T:SimpleType), emptyValue) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00001", "Casting empty value to type other than void.") </ errorCell >)
		if T:SimpleType =/=Bool void
		[structural]
		
	rule [err00002]:
		< k => finalComputation > assert(false, 2) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00002", "Reading outside the bounds of an object.") </ errorCell >)
		[structural]
	rule [err00003]:
		< k => finalComputation > assert(false, 3) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00003", "Unsequenced side effect on scalar object with value computation of same object.") </ errorCell >)
		[structural]
		
	rule [err00005]:
		< k => finalComputation > extractByteFromMem(sym(Block:#Nat) +Nat ?) ...</ k => finalComputation >
		< mem > M:Map </ mem >
		(.Bag => < errorCell > ICE("00005", "Referring to an object outside of its lifetime.") </ errorCell >)
		if notBool $hasMapping(M:Map, Block:#Nat)
		[structural]
	
	rule [err00006]:
		< k => finalComputation > joinIntegerBytes-aux(T:Type, (?:List{K},, piece(unknown(Len:#Nat), Len:#Nat)), ?:K) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00006", "Reading unspecified (possibly uninitialized) memory, or trying to read a pointer or float through an integer type.") </ errorCell >)
		if notBool hasCharType(T:Type)
		[structural]
		
	rule [err00007]:
		< k => finalComputation > checkValidLoc-aux(sym(Block:#Nat) +Nat ?) ...</ k => finalComputation >
		< mem > M:Map </ mem >
		(.Bag => < errorCell > Error("00007", "Referring to an object outside of its lifetime.") </ errorCell >)
		if notBool $hasMapping(M:Map, Block:#Nat)
		[structural]
	
	rule [err00008]:
		< k => finalComputation > concretize(t(?, pointerType(?)), dataList((piece(unknown(Len:#Nat), Len:#Nat),, ?))) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00008", "Reading uninitialized memory.") </ errorCell >)
		[structural]
	
	rule [err00009]:
		< k => finalComputation > concretize(T:Type, dataList((piece(unknown(Len:#Nat), Len:#Nat),, ?))) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00009", "Reading uninitialized memory.") </ errorCell >)
		if hasFloatType(T:Type)
		[structural]
		
	rule [err00010]:
		< k => finalComputation > checkValidLoc-aux(sym(Block:#Nat) +Nat Offset:#Nat) ...</ k => finalComputation >
		< mem >... Block:#Nat |-> memblock(mlength(Size:#Nat) ?, ?) ...</ mem >
		(.Bag => < errorCell > Error("00010", "Found pointer that refers outside the bounds of an object + 1.") </ errorCell >)
		if Offset:#Nat >Nat Size:#Nat
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
		< k => finalComputation > arithInterpret(T:Type, I:#Int) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00015", "Signed overflow.") </ errorCell >)
		if hasSignedIntegerType(T:Type)
		andBool notBool (min(T:Type) <=Int I:#Int andBool max(T:Type) >=Int I:#Int)
		[structural] 	
		
		
	rule [err00016]:
		< k => finalComputation > writeByte(Loc:#Nat, ?) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00016", "Unsequenced side effect on scalar object with side effect of same object.") </ errorCell >)
		< locsWrittenTo > Locs:Bag </ locsWrittenTo >
		if Loc:#Nat in Locs:Bag
		[structural] 
		
	rule [err00017]:
		< k => finalComputation > tv(I1:#Int, T:Type) / tv(0, T:Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00017", "Division by 0.") </ errorCell >)
		if hasIntegerType(T:Type)
		andBool hasBeenPromoted(T:Type)
		[structural]
	
	rule [err00018]:
		< k => finalComputation > tv(I1:#Int, T:Type) % tv(0, T:Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00018", "Modulus by 0.") </ errorCell >)
		if hasIntegerType(T:Type)
		andBool hasBeenPromoted(T:Type)
		[structural]
		
	rule [err00019]:
		< k => finalComputation > tv(I1:#Int, T:Type) % tv(I2:#Int, T:Type) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00019", "Signed overflow.") </ errorCell >)
		if hasIntegerType(T:Type)
		andBool notBool (min(T:Type) <=Int I1:#Int /Int I2:#Int andBool max(T:Type) >=Int I1:#Int /Int I2:#Int)
		andBool hasBeenPromoted(T:Type)
		andBool I2:#Int =/=Bool 0
		[structural]
		
	rule [err00020]:
		< k => finalComputation > writeByte(sym(Block:#Nat) +Nat Offset:#Nat, ?) ...</ k => finalComputation >
		< mem >... Block:#Nat |-> memblock(mlength(Len:#Nat) ?, ?) ...</ mem >		
		(.Bag => < errorCell > Error("00020", "Tried to write outside the bounds of an object.") </ errorCell >)
		if notBool Offset:#Nat <Nat Len:#Nat
		[structural] 
		
	rule [err00021]:
		< k => finalComputation > Identifier(S:#String) ...</ k => finalComputation >
		< env > M:Map </ env >
		(.Bag => < errorCell > Error("00021", "Trying to look up identifier  " +String S:#String +String " , but no such identifier is in scope.") </ errorCell >)
		if notBool $hasMapping(M:Map, Identifier(S:#String))
		[structural]
		
	rule [err00022]:
		< k => finalComputation > leftShiftInterpret(T:Type, I:#Int, tv(E1:#Int, T:Type)) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00022", "Trying to left-shift a negative signed value.") </ errorCell >)
		if hasSignedIntegerType(T:Type)
		andBool E1:#Int <Int 0
		[structural]
		
	rule [err00023]:
		< k => finalComputation > leftShiftInterpret(T:Type, I:#Int, tv(E1:#Nat, T:Type)) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.") </ errorCell >)
		if hasSignedIntegerType(T:Type)
		andBool notBool (I:#Int <=Int (2 ^Nat absInt(numBits(T:Type))))
		[structural]
		
	rule [err00024]:
		< k => finalComputation > arithInterpret(?, I:#Int &Int I':#Int) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00024", "Bitwise & used on a symbolic number (address) or float.") </ errorCell >)
		if notBool isConcreteNumber(I':#Int)
		[structural]
		
	rule [err00025]:
		< k => finalComputation > callMain-aux(t(?, functionType(t(?, T:SimpleType), ?)), ?, ?, ?) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00025", "Main must return an int.") </ errorCell >)
		if T:SimpleType =/=Bool int
		[structural]
	rule [err00026]:
		< k => finalComputation > 
			callMain-aux(t(?, functionType(t(?, int), (typedDeclaration(t(?, T:SimpleType), ?),, ?:List{KResult}))), ?, ?, ?) 
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00026", "If main has arguments, the type of the first argument must be equivalent to \"int\".") </ errorCell >)
		if T:SimpleType =/=Bool int andBool T:SimpleType =/=Bool void
		[structural]
		
	op isArgvType : Type -> #Bool
	
	rule isArgvType(t(?, T:SimpleType)) => false
		if notBool (
			getKLabel(T:SimpleType) ==Bool 'incompleteArrayType 
			orBool getKLabel(T:SimpleType) ==Bool 'incompleteArrayType
		)
		[structural]
		
	rule isArgvType(t(?, incompleteArrayType(t(?, T:SimpleType)))) => false
		if notBool getKLabel(T:SimpleType) ==Bool 'pointerType
		[structural]
	rule isArgvType(t(?, incompleteArrayType(t(?, pointerType(t(?, T:SimpleType)))))) => false
		if T:SimpleType =/=Bool char
		[structural]
		
	rule isArgvType(t(?, pointerType(t(?, T:SimpleType)))) => false
		if notBool getKLabel(T:SimpleType) ==Bool 'pointerType
		[structural]
	rule isArgvType(t(?, pointerType(t(?, pointerType(t(?, T:SimpleType)))))) => false
		if T:SimpleType =/=Bool char
		[structural]
	
	rule [err00027]:
		< k => finalComputation >
			callMain-aux(t(?, functionType(t(?, int), (typedDeclaration(t(?, int), ?),, typedDeclaration(T:Type, ?)))), ?, ?, ?) 
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00027", "If main has arguments, the type of the second argument must be equivalent to  char** .") </ errorCell >)
		if notBool isArgvType(T:Type)
		[structural]
	rule [err00028]:
		< k => finalComputation >
			callMain-aux(t(?, functionType(t(?, int), (?:Type,, ?:Type,, ?:Type,, ?:List{KResult}))), ?, ?, ?) 
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00028", "Main can only have zero or two arguments.") </ errorCell >)
		[structural]
	rule [err00029]:
		< k => finalComputation > 
			callMain-aux(t(?, functionType(t(?, int), (typedDeclaration(t(?, T:SimpleType), ?)))), ?, ?, ?)
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00029", "Main can only have zero or two arguments.") </ errorCell >)
		if T:SimpleType =/=Bool void
		[structural]
		
	rule [err00030]:
		< k => finalComputation > 
			tv(sym(Base:#Nat) +Nat ?, T:Type) < tv(sym(Base':#Nat) +Nat ?, T:Type)
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00030", "Cannot compare pointers with different base objects using '<'.") </ errorCell >)
		if Base:#Nat =/=Bool Base':#Nat
		[structural]
	rule [err00031]:
		< k => finalComputation > 
			tv(sym(Base:#Nat) +Nat ?, T:Type) > tv(sym(Base':#Nat) +Nat ?, T:Type)
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00031", "Cannot compare pointers with different base objects using '>'.") </ errorCell >)
		if Base:#Nat =/=Bool Base':#Nat
		[structural]
	rule [err00032]:
		< k => finalComputation > 
			tv(sym(Base:#Nat) +Nat ?, T:Type) <= tv(sym(Base':#Nat) +Nat ?, T:Type)
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00032", "Cannot compare pointers with different base objects using '<='.") </ errorCell >)
		if Base:#Nat =/=Bool Base':#Nat
		[structural]
	rule [err00033]:
		< k => finalComputation > 
			tv(sym(Base:#Nat) +Nat ?, T:Type) >= tv(sym(Base':#Nat) +Nat ?, T:Type)
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00033", "Cannot compare pointers with different base objects using '>='.") </ errorCell >)
		if Base:#Nat =/=Bool Base':#Nat
		[structural]
		
	rule [err00034]:
		< k => finalComputation > 
			cast(t(?, T:SimpleType), skipval)
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00034", "Casting void type to non-void type.") </ errorCell >)
		if (T:SimpleType =/=Bool void)
		[structural]
		
	rule [err00035]:
		< k => finalComputation > 
			write(lv(Dest:#Nat, t(SetItem(Const) ?, ?)), ?)
		...</ k => finalComputation >
		(.Bag => < errorCell > Error("00035", "Trying to write through a const lvalue.") </ errorCell >)
		[structural]
	
	rule [err00036]:
		< k => finalComputation > checkDerefLoc(NullPointer) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00036", "Trying to dereference a null pointer.") </ errorCell >)
		[structural]
		
	rule [err00037]:
		< k => finalComputation > read-aux(NullPointer, _, _) ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00037", "Trying to read through a null pointer.") </ errorCell >)
		[structural]
		
	rule [err00038]:
		< k => finalComputation > ArrayType(T:Type, tv(0, ?), ?)  ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00038", "Arrays cannot be of 0 length.") </ errorCell >)
		[structural]
	
	rule [err00039]:
		< k => finalComputation > addUnion(S:#Id, Nil)  ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00039", "Unions cannot be empty.") </ errorCell >)
		[structural]
	rule [err00040]:
		< k => finalComputation > addStruct(S:#Id, Nil)  ...</ k => finalComputation >
		(.Bag => < errorCell > Error("00040", "Structs cannot be empty.") </ errorCell >)
		[structural]
		
	
	op datarace : #Nat #Nat #Nat #Nat -> K 

	// fixme possible to miss dataraces with bitfields
	rule [read-write-race]:
		< T > 
			? 
			< threads > 
				?
				< thread > ? < k > read-aux(Loc:#Nat, ?, BitSize:#Nat) ...</ k > </ thread >
				< thread > ? < k > write-aux(Loc':#Nat, ?, BitSize':#Nat) ...</ k > </ thread >
			</ threads > 
		</ T >
		=> < errorCell > datarace(Loc:#Nat, BitSize:#Nat, Loc':#Nat, BitSize':#Nat) </ errorCell >
		if (Start1 <=Nat Start2 andBool End1 >=Nat Start2)
		orBool (Start1 >Nat Start2 andBool Start1 <=Nat End2)
		where Start1 = Loc:#Nat
		and End1 = Loc:#Nat +Nat bitsToBytes(BitSize:#Nat)
		and Start2 = Loc':#Nat
		and End2 = Loc':#Nat +Nat bitsToBytes(BitSize':#Nat)
		[metadata "computational=()"]
		
	rule [write-write-race]:
		< T > 
			? 
			< threads > 
				?
				< thread > ? < k > write-aux(Loc:#Nat, ?, BitSize:#Nat) ...</ k > </ thread >
				< thread > ? < k > write-aux(Loc':#Nat, ?, BitSize':#Nat) ...</ k > </ thread >
			</ threads > 
		</ T >
		=> < errorCell > datarace(Loc:#Nat, BitSize:#Nat, Loc':#Nat, BitSize':#Nat) </ errorCell >
		if (Start1 <=Nat Start2 andBool End1 >=Nat Start2)
		orBool (Start1 >Nat Start2 andBool Start1 <=Nat End2)
		where Start1 = Loc:#Nat
		and End1 = Loc:#Nat +Nat bitsToBytes(BitSize:#Nat)
		and Start2 = Loc':#Nat
		and End2 = Loc':#Nat +Nat bitsToBytes(BitSize':#Nat)
		[metadata "computational=()"]		


endkm
