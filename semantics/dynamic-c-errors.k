module DYNAMIC-SEMANTICS-ERRORS-INCLUDE is
	including COMMON-C-SEMANTICS

	including DYNAMIC-C-SEMANTICS-MISC
	including DYNAMIC-C-EXPRESSIONS
	including DYNAMIC-C-TYPING 
	including DYNAMIC-C-DECLARATIONS 
	including DYNAMIC-C-MEMORY 
	including DYNAMIC-C-STATEMENTS 
	including DYNAMIC-C-CONVERSIONS 
	including DYNAMIC-C-STANDARD-LIBRARY

end module

module DYNAMIC-C-ERRORS is
	including DYNAMIC-SEMANTICS-ERRORS-INCLUDE

	declare Error : String String -> K
	define Error(Name:String, Msg:String)  => 
		//"=====================================================\n"
		//+String "ERROR! KCC encountered an error while executing this program.\n"
		"Error: " 
		+String Name:String 
		+String "\n"
		+String "Description: " 
		+String Msg:String
		[structural]
	declare ICE : String String -> K
	define ICE(Name:String, Msg:String) =>
		"Error: "
		+String Name:String
		+String "\n"
		+String "Description: " 
		+String Msg:String
		+String "\n"
		+String "NOTE: Please send a test case exhibiting this bug to celliso2@illnois.edu; it could indicate an internal error in KCC."
		[structural]
	
		
	syntax CellLabel ::= "halted-k"
	syntax CellLabel ::= "halted-T"
	declare halt_ : Bag -> Bag
	define halt < k => halted-k > _:K </ k => halted-k >
	define halt < L:CellLabel > K:K </ L:CellLabel > => < L:CellLabel > K:K </ L:CellLabel > 
		when L:CellLabel =/=CellLabel k 
		[structural]
	define halt < L:CellLabel > B:Bag </ L:CellLabel > => < L:CellLabel > halt B:Bag </ L:CellLabel >
	define halt < L:CellLabel > K:Set </ L:CellLabel > => < L:CellLabel > K:Set </ L:CellLabel >
	define halt < L:CellLabel > K:Map </ L:CellLabel > => < L:CellLabel > K:Map </ L:CellLabel >
	define halt < L:CellLabel > K:List </ L:CellLabel > => < L:CellLabel > K:List </ L:CellLabel >
	define halt .Bag => .Bag
	
	// FIXME TOOL BUG removing spaces in inner cells causes kompile to lose track of ...s
	rule [halt-start]:
		< T => halted-T >...
			< threads >
				(B:Bag => halt B:Bag)
				< thread >...
					< finalComputation > _:K </ finalComputation >
				...</ thread > 
			</ threads > 
		...</ T => halted-T >
		[structural]
	
	rule [err00001]:
		< k => finalComputation > cast(t(_, T:K), emptyValue) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00001", "Casting empty value to type other than void.") </errorCell>)
		when T:K =/=K void
		[structural]
		
	rule [err00002]:
		< k => finalComputation > assert(false, 2) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00002", "Reading outside the bounds of an object.") </errorCell>)
		[structural]
	rule [err00003]:
		< k => finalComputation > assert(false, 3) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00003", "Unsequenced side effect on scalar object with value computation of same object.") </errorCell>)
		[structural]

	rule [err00005]:
		< k => finalComputation > extractByteFromMem(loc(Block:Nat, _:Nat, _:Nat)) ...</ k => finalComputation >
		<memory> M:Bag </memory>
		(.Bag => <errorCell> ICE("00005", "Referring to an object outside of its lifetime.") </errorCell>)
		// when notBool $hasMapping(M:Map, Block:Nat)
		when notBool Block:Nat in gatherInnerCells(M:Bag, basePtr)
		[structural]
	
	rule [err00006]:
		< k => finalComputation > joinIntegerBytes-aux(T:KResult, (_:List{K},, piece(unknown(Len:Nat), Len:Nat)), _:K) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00006", "Reading unspecified (possibly uninitialized) memory, or trying to read a pointer or float through an integer type.") </errorCell>)
		when notBool isCharType(T:KResult)
		[structural]
		
	rule [err00007]:
		< k => finalComputation > checkValidLoc-aux(loc(Block:Nat, _:Nat, _:Nat)) ...</ k => finalComputation >
		<memory> M:Bag </memory>
		(.Bag => <errorCell> Error("00007", "Referring to an object outside of its lifetime.") </errorCell>)
		// when notBool $hasMapping(M:Bag, Block:Nat)
		when notBool Block:Nat in gatherInnerCells(M:Bag, basePtr)
		[structural]
	
	rule [err00008]:
		< k => finalComputation > concretize(t(_, pointerType(_)), dataList((piece(unknown(Len:Nat), Len:Nat),, _))) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00008", "Reading uninitialized memory.") </errorCell>)
		[structural]
	
	rule [err00009]:
		< k => finalComputation > concretize(T:KResult, dataList((piece(unknown(Len:Nat), Len:Nat),, _))) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00009", "Reading uninitialized memory.") </errorCell>)
		when isFloatType(T:KResult)
		[structural]
		
	rule [err00010]:
		< k => finalComputation > checkValidLoc-aux(loc(Base:Nat, Offset:Nat, _:Nat)) ...</ k => finalComputation >
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
		...</object>
		(.Bag => <errorCell> Error("00010", "Found pointer that refers outside the bounds of an object + 1.") </errorCell>)
		when Offset:Nat >Int Len:Nat
		[structural]
		
		
	rule [err00011]:
		< k => finalComputation > tv(_, T:KResult) < tv(_, T':KResult) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00011", "Directly comparing an integer type with a pointer type.") </errorCell>)
		when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
		orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
		[structural]
	rule [err00012]:
		< k => finalComputation > tv(_, T:KResult) <= tv(_, T':KResult) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00012", "Directly comparing an integer type with a pointer type.") </errorCell>)
		when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
		orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
		[structural] 
	rule [err00013]:
		< k => finalComputation > tv(_, T:KResult) > tv(_, T':KResult) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00013", "Directly comparing an integer type with a pointer type.") </errorCell>)
		when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
		orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
		[structural] 
	rule [err00014]:
		< k => finalComputation > tv(_, T:KResult) >= tv(_, T':KResult) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00014", "Directly comparing an integer type with a pointer type.") </errorCell>)
		when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
		orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
		[structural] 
		
	rule [err00015]:
		< k => finalComputation > arithInterpret(T:KResult, I:Int) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00015", "Signed overflow.") </errorCell>)
		when hasSignedIntegerType(T:KResult)
		andBool notBool (min(T:KResult) <=Int I:Int andBool max(T:KResult) >=Int I:Int)
		[structural] 	
		
		
	rule [err00016]:
		< k => finalComputation > writeByte(Loc:Nat, _) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00016", "Unsequenced side effect on scalar object with side effect of same object.") </errorCell>)
		<locsWrittenTo> Locs:Bag </locsWrittenTo>
		when Loc:Nat in Locs:Bag
		[structural] 
		
	rule [err00017]:
		< k => finalComputation > tv(I1:Int, T:KResult) / tv(0, T:KResult) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00017", "Division by 0.") </errorCell>)
		when hasIntegerType(T:KResult)
		andBool isPromoted(T:KResult)
		[structural]
	
	rule [err00018]:
		< k => finalComputation > tv(I1:Int, T:KResult) % tv(0, T:KResult) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00018", "Modulus by 0.") </errorCell>)
		when hasIntegerType(T:KResult)
		andBool isPromoted(T:KResult)
		[structural]
		
	rule [err00019]:
		< k => finalComputation > tv(I1:Int, T:KResult) % tv(I2:Int, T:KResult) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00019", "Signed overflow.") </errorCell>)
		when hasIntegerType(T:KResult)
		andBool notBool (min(T:KResult) <=Int I1:Int /Int I2:Int andBool max(T:KResult) >=Int I1:Int /Int I2:Int)
		andBool isPromoted(T:KResult)
		andBool I2:Int =/=Int 0
		[structural]
		
	rule [err00020]:
		< k => finalComputation > writeByte(loc(Base:Nat, Offset:Nat, _:Nat), _) ...</ k => finalComputation >
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
		...</object>
		(.Bag => <errorCell> Error("00020", "Tried to write outside the bounds of an object.") </errorCell>)
		when notBool Offset:Nat <Int Len:Nat
		[structural] 
		
	rule [err00021]:
		< k => finalComputation > Identifier(S:String) ...</ k => finalComputation >
		<env> M:Map </env>
		(.Bag => <errorCell> Error("00021", "Trying to look up identifier  " +String S:String +String " , but no such identifier is in scope.") </errorCell>)
		when notBool $hasMapping(M:Map, Identifier(S:String))
		[structural]
		
	rule [err00022]:
		< k => finalComputation > leftShiftInterpret(T:KResult, I:Int, tv(E1:Int, T:KResult)) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00022", "Trying to left-shift a negative signed value.") </errorCell>)
		when hasSignedIntegerType(T:KResult)
		andBool E1:Int <Int 0
		[structural]
		
	rule [err00023]:
		< k => finalComputation > leftShiftInterpret(T:KResult, I:Int, tv(E1:Nat, T:KResult)) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.") </errorCell>)
		when hasSignedIntegerType(T:KResult)
		andBool notBool (I:Int <=Int (2 ^Int absInt(numBits(T:KResult))))
		[structural]
	
	rule [err00024]:
		< k => finalComputation > arithInterpret(_, I:Int &Int I':Int) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00024", "Bitwise & used on a symbolic number (address) or float.") </errorCell>)
		when notBool isConcreteNumber(I:Int) orBool notBool isConcreteNumber(I':Int)
		[structural]
		
	rule [err00025]:
		< k => finalComputation > callMain-aux(t(_, functionType(t(_, T:K), _:List{KResult})), _:Nat, _:Id, _) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00025", "Main must return an int.") </errorCell>)
		when T:K =/=K int
		[structural]
	rule [err00026]:
		< k => finalComputation > 
			callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:K), _:Id),, _:List{KResult}))), _:Nat, _:Id, _) 
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00026", "If main has arguments, the type of the first argument must be equivalent to \"int\".") </errorCell>)
		when T:K =/=K int andBool T:K =/=K void
		[structural]
		
	declare isArgvType : Type -> Bool
	
	define isArgvType(t(_, T:K)) => false
		when notBool (
			getKLabel(T:K) ==KLabel 'incompleteArrayType 
			orBool getKLabel(T:K) ==KLabel 'incompleteArrayType
		)
		
	define isArgvType(t(_, incompleteArrayType(t(_, T:K)))) => false
		when notBool getKLabel(T:K) ==KLabel 'pointerType
	define isArgvType(t(_, incompleteArrayType(t(_, pointerType(t(_, T:K)))))) => false
		when T:K =/=K char
		
	define isArgvType(t(_, pointerType(t(_, T:K)))) => false
		when notBool getKLabel(T:K) ==KLabel 'pointerType
	define isArgvType(t(_, pointerType(t(_, pointerType(t(_, T:K)))))) => false
		when T:K =/=K char
	
	rule [err00027]:
		< k => finalComputation >
			callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, int), _:Id),, typedDeclaration(T:KResult, _:Id)))), _:Nat, _:Id, _) 
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00027", "If main has arguments, the type of the second argument must be equivalent to  char** .") </errorCell>)
		when notBool isArgvType(T:KResult)
		[structural]
	rule [err00028]:
		< k => finalComputation >
			callMain-aux(t(_, functionType(t(_, int), (_:KResult,, _:KResult,, _:KResult,, _:List{KResult}))), _:Nat, _:Id, _) 
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00028", "Main can only have zero or two arguments.") </errorCell>)
		[structural]
	rule [err00029]:
		< k => finalComputation > 
			callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:K), _:Id)))), _:Nat, _:Id, _)
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00029", "Main can only have zero or two arguments.") </errorCell>)
		when T:K =/=K void
		[structural]
		
	rule [err00030]:
		< k => finalComputation > 
			tv(loc(Base:Nat, _:Nat, _:Nat), T:KResult) < tv(loc(Base':Nat, _:Nat, _:Nat), T:KResult)
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00030", "Cannot compare pointers with different base objects using '<'.") </errorCell>)
		when Base:Nat =/=K Base':Nat
		[structural]
	rule [err00031]:
		< k => finalComputation > 
			tv(loc(Base:Nat, _:Nat, _:Nat), T:KResult) > tv(loc(Base':Nat, _:Nat, _:Nat), T:KResult)
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00031", "Cannot compare pointers with different base objects using '>'.") </errorCell>)
		when Base:Nat =/=K Base':Nat
		[structural]
	rule [err00032]:
		< k => finalComputation > 
			tv(loc(Base:Nat, _:Nat, _:Nat), T:KResult) <= tv(loc(Base':Nat, _:Nat, _:Nat), T:KResult)
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00032", "Cannot compare pointers with different base objects using '<='.") </errorCell>)
		when Base:Nat =/=K Base':Nat
		[structural]
	rule [err00033]:
		< k => finalComputation > 
			tv(loc(Base:Nat, _:Nat, _:Nat), T:KResult) >= tv(loc(Base':Nat, _:Nat, _:Nat), T:KResult)
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00033", "Cannot compare pointers with different base objects using '>='.") </errorCell>)
		when Base:Nat =/=K Base':Nat
		[structural]
		
	rule [err00034]:
		< k => finalComputation > 
			cast(t(_, T:K), skipval)
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00034", "Casting void type to non-void type.") </errorCell>)
		when (T:K =/=K void)
		[structural]
		
	rule [err00035]:
		< k => finalComputation > 
			write(lv(Dest:Nat, t(SetItem(Const) _, _)), _)
		...</ k => finalComputation >
		(.Bag => <errorCell> Error("00035", "Trying to write through a const lvalue.") </errorCell>)
		[structural]
	
	rule [err00036]:
		< k => finalComputation > checkDerefLoc(NullPointer) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00036", "Trying to dereference a null pointer.") </errorCell>)
		[structural]
		
	rule [err00037]:
		< k => finalComputation > read-aux(NullPointer, _, _) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00037", "Trying to read through a null pointer.") </errorCell>)
		[structural]
		
	rule [err00038]:
		< k => finalComputation > ArrayType(T:KResult, tv(0, _), _)  ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00038", "Arrays cannot be of 0 length.") </errorCell>)
		[structural]
	
	rule [err00039]:
		< k => finalComputation > addUnion(S:Id, .List{K})  ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00039", "Unions cannot be empty.") </errorCell>)
		[structural]
	rule [err00040]:
		< k => finalComputation > addStruct(S:Id, .List{K})  ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00040", "Structs cannot be empty.") </errorCell>)
		[structural]
		
	rule [err00041]:
		< k => finalComputation > types((t(_, void),, t(_, T:K)))  ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00041", "If one of a conditional expression's branches has void type, the other must also have void type.") </errorCell>)
		when T:K =/=K void
		[structural]
	rule [err00042]:
		< k => finalComputation > types((t(_, T:K),, t(_, void)))  ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") </errorCell>)
		when T:K =/=K void
		[structural]
	rule [err00043]:
		< k => finalComputation > types((T1:KResult,, T2:KResult))  ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.") </errorCell>)
		when T1:KResult =/=K T2:KResult
		andBool (isStructType(T1:KResult) orBool isUnionType(T1:KResult))
		andBool (isStructType(T2:KResult) orBool isUnionType(T2:KResult))
		[structural]
		
	rule [err00044]:
		< k => finalComputation > addToPointer(Loc:Nat, T:KResult, I:Int, tv(Size:Nat, _))  ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00044", "An array subscript is out of range.") </errorCell>)
		when notBool ifFromArrayInBounds(T:KResult, I:Int)
		[structural]
		
	rule [err00045]:
		< k => finalComputation > writeByte(LOC, V:K)  ...</ k => finalComputation >
		<object>...
			<basePtr> Base:Nat </basePtr>
			<properties>... mconst ...</properties>
		...</object>
		(.Bag => <errorCell> Error("00045", "Trying to modify a string literal or an object declared with const type.") </errorCell>)
		where LOC = loc(Base:Nat, _:Nat, _:Nat)
		[structural]
		
	rule [err00046]:
		< k => finalComputation > concretize(T:KResult, dataList((piece(N:Nat, Len:Nat),, _))) ...</ k => finalComputation >
		(.Bag => <errorCell> Error("00046", "Trying to reinterpret integer bytes as floating bytes.") </errorCell>)
		when isFloatType(T:KResult)
		andBool N:Nat >=Int 0
		[structural]
		
	rule [err00047]:
		< k => finalComputation > writeByte(Loc:Nat, V:K)  ...</ k => finalComputation >
		<notWritable>... Loc:Nat |-> _ ...</notWritable>
		(.Bag => <errorCell> Error("00047", "Trying to modify an object declared with const type.") </errorCell>)
		[structural]
	
	syntax K ::= "datarace" "(" Nat "," Nat "," Nat "," Nat ")" [klabel(datarace)] 

	// fixme possible to miss dataraces with bitfields
	rule [read-write-race]:
		<T> 
			_ 
			<threads> 
			(	_
				<thread> _ <k> read-aux(Loc:Nat, _, BitSize:Nat) ...</k> </thread>
				<thread> _ <k> write-aux(Loc':Nat, _, BitSize':Nat) ...</k> </thread> => .Bag)
			</threads> 
		</T>
		(.Bag => <errorCell> Error("00048", "Have a read-write datarace.")
		// ~> datarace(Loc:Nat, BitSize:Nat, Loc':Nat, BitSize':Nat) 
		</errorCell>)
		when (Start1 <=Int Start2 andBool Start2 <Int End1)
		orBool (Start1 >Int Start2 andBool End2 >Int Start1)
		where Start1 = Loc:Nat
		and End1 = Loc:Nat +Int bitsToBytes(BitSize:Nat)
		and Start2 = Loc':Nat
		and End2 = Loc':Nat +Int bitsToBytes(BitSize':Nat)
		[computational]
		
	rule [write-write-race]:
		<T> 
			_ 
			<threads> 
			(	_
				<thread> _ <k> write-aux(Loc:Nat, _, BitSize:Nat) ...</k> </thread>
				<thread> _ <k> write-aux(Loc':Nat, _, BitSize':Nat) ...</k> </thread> => .Bag)
			</threads> 
		</T>
		(.Bag => <errorCell> Error("00049", "Have a write-write datarace.")
		// ~> datarace(Loc:Nat, BitSize:Nat, Loc':Nat, BitSize':Nat) 
		</errorCell>)
		when (Start1 <=Int Start2 andBool Start2 <Int End1)
		orBool (Start1 >Int Start2 andBool End2 >Int Start1)
		where Start1 = Loc:Nat
		and End1 = Loc:Nat +Int bitsToBytes(BitSize:Nat)
		and Start2 = Loc':Nat
		and End2 = Loc':Nat +Int bitsToBytes(BitSize':Nat)
		[computational]		


end module
