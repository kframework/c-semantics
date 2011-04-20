kmod INCOMING-MODULES is
	including K 
	including C-SYNTAX 
	including C-CONFIGURATION 
	including K-CONTEXTS 
	including K-PROPER
endkm

kmod COMMON-SEMANTIC-SYNTAX is
	including INCOMING-MODULES 

	op initFunction : K K -> K [seqstrict]
	
	op checkValidLoc : K -> K
	op checkDerefLoc : K -> K
	op ListItem : BagItem -> ListItem
	op ListToK : List -> K 
	op Map : Map -> K 
	op piece : Nat Nat -> Nat 
	
	op unknown : Nat -> Nat [ctor] 
	
	op skipval : -> KResult 
	op debugK : -> K 
	op discard : -> K 
	op File-Scope : -> Id [ctor] 
	op unnamedBitField : -> Id [ctor] 
	op bignum : -> Type 
	op debug : -> K 
	op sym : Nat -> Nat 
	op byteo : Nat -> Nat 
	op bito : Nat -> Nat 
	rule bito(0) => 0 [structural] // FIXME need to check this is okay in all circumstances
	op bitoffset : Nat -> Nat 
	op byteoffset : Nat -> Nat 
	op declare : K K -> K [strict(1)] 
	op enumItem : Id Value -> Value 
	op resolveReferences : -> K 
	
	op toString : K -> String 
	
	op maxType : Type Type -> Type 
	
	op bitRange : Nat Nat Nat -> Nat // original number, from, to inclusive
	
	op fillToBytes : K -> K [strict] 
	
	op floorLoc : Nat -> Nat // loc with possible bit offset returning base byte	
	op ceilingLoc : Nat -> Nat // loc with possible bit offset returning upperbounded byte	
	op readFunction : Nat -> K 
	
	rule _bit::_(piece(N:Nat, Len:Nat), piece(N':Nat, Len':Nat)) 
		=> piece((N:Nat <<Nat Len':Nat) |Nat N':Nat, Len:Nat +Nat Len':Nat)
		if N:Nat >=Nat 0 andBool N':Nat >=Nat 0 
		[structural] 
	rule _bit::_(piece(0, 0), N:Nat) => N:Nat [structural] 
	rule piece(piece(N:Nat, Len:Nat), Len:Nat) => piece(N:Nat, Len:Nat) [structural] 
	
	op innerType : Type -> Type
	
	op AttributeValue : String List{C} -> KResult 
	
	op extractBitsFromList : K Nat Nat -> K [strict(1)] // data, offset, size in bits
	op typedef : Id -> Id 
	op unnamed : Nat -> Id 
	
	op NullPointerConstant : -> Nat 
	rule NullPointerConstant => 0 [structural]
	op NullPointer : -> Nat 
	
	op emptyValue : -> Value 
	op _bit::_ : Nat Nat -> Nat [assoc] 
	op allocate : Type K -> K
	
	op zero : K -> K 
	op zeroBlock : Nat -> K 
		
	op value : K -> K 
	rule value(tv(V:List{K}, ?)) => V:List{K} [structural]
	
	op sizeofLocation : K -> K
	op type : K -> Type 
	rule type(tv(?, T:Type)) => T:Type [structural]
	
	op allocateType : Nat Type -> K 
	op allocateTypeIfAbsent : Nat Type -> K 
	op giveType : Id Type -> K 
	op addToEnv : Id Nat -> K 
	
	op read : K K -> K [strict(2)] // location, type
	op write : K K -> K [strict(2)] // location, value
	op writeByte : Nat K -> K 

	op isTypeCompatible : K K -> Bool 
	
	op hasBeenPromoted : Type -> Bool 
	
	op bitloc : Nat Nat Nat -> Nat 
	op inc : Nat -> Nat 
	op threadId : Nat -> Nat // used for symbolic locations based on threadid
	op allocatedDuration : -> Nat // fake threadid for above when location is of allocated duration
	op readOnly : -> Nat // fake threadid for above when location can't be written to
		
	op initialize : Id Type K -> K 
	op memblock : Nat Map -> K // length and an array from offsets to bytes
	
	op listToK : K -> K 
	op klistToK : List{K} -> K 
	op UnknownCabsLoc : -> K 
	
	// Basic types
	ops bool : -> Type 
	ops void bool char short-int int long-int long-long-int : -> Type 
	ops float double long-double : -> Type 
	ops signed-char unsigned-char : -> Type 
	ops unsigned-short-int unsigned-int unsigned-long-int unsigned-long-long-int : -> Type 
	op no-type : -> Type
	
	op isBasicType : K -> Bool
	rule isBasicType(K:K) => if (
		K:K ==Bool bool
		orBool K:K ==Bool void
		orBool K:K ==Bool char
		orBool K:K ==Bool short-int
		orBool K:K ==Bool int
		orBool K:K ==Bool long-int
		orBool K:K ==Bool long-long-int
		orBool K:K ==Bool float
		orBool K:K ==Bool double
		orBool K:K ==Bool long-double
		orBool K:K ==Bool signed-char
		orBool K:K ==Bool unsigned-char
		orBool K:K ==Bool unsigned-short-int
		orBool K:K ==Bool unsigned-int
		orBool K:K ==Bool unsigned-long-int
		orBool K:K ==Bool unsigned-long-long-int
		orBool K:K ==Bool no-type
		orBool getKLabel(K:K) ==Bool 'enumType
		) then true else false fi
		[structural]
	// rule isBasicType(K:K) => false
		// if notBool(
			// K:K ==Bool bool
			// orBool K:K ==Bool void
			// orBool K:K ==Bool char
			// orBool K:K ==Bool short-int
			// orBool K:K ==Bool int
			// orBool K:K ==Bool long-int
			// orBool K:K ==Bool long-long-int
			// orBool K:K ==Bool float
			// orBool K:K ==Bool double
			// orBool K:K ==Bool long-double
			// orBool K:K ==Bool signed-char
			// orBool K:K ==Bool unsigned-char
			// orBool K:K ==Bool unsigned-short-int
			// orBool K:K ==Bool unsigned-int
			// orBool K:K ==Bool unsigned-long-int
			// orBool K:K ==Bool unsigned-long-long-int
			// orBool K:K ==Bool no-type
			// orBool getKLabel(K:K) ==Bool 'enumType
		// )
		// [structural]
	
	// Composite types
	op enumType : Id -> Type [ctor] 
	op arrayType : Type Nat -> Type [ctor] 
	op incompleteArrayType : Type -> Type [ctor] 
	op flexibleArrayType : Type -> Type [ctor] 
	op bitfieldType : Type Nat -> Type [ctor] 
	op functionType : Type List{Type} -> Type [ctor] 
	op pointerType : Type -> Type [ctor] 
	op structType : Id -> Type [ctor] 
	op unionType : Id -> Type [ctor] 
	op qualifiedType : Type K -> Type [ctor]
	// op t : Type Set -> Type
	// tv(5, t(pointerType(t(int)), const))
	
	
	op unqualifyType : K -> Type // takes a type, but sometimes things like maps give K
	
	// these aren't real types, but are values that can appear in type contexts
	op prototype : Type -> Type 
	op typedefType : Id Type -> Type 
	op variadic : -> Type 

	subsort Type < C 
	subsort Value < C 
	sort BaseValue 

	subsort Nat Int Float < BaseValue 
	subsort BaseValue < C
	op dataList : List{K} -> KResult 
	subsort Value < KResult K 
	subsort Type < KResult K
	
	op sizeofType : K -> K [strict] // generates a tv(size, cfg:sizeut)
	op bitSizeofType : K -> K [strict] // needs to be heated to top of K for struct and union types
	op byteSizeofType : K -> K [strict] 
	op bitsToBytes : Nat -> Nat 
	op HOLE : -> Expression 
	op l : KLabel -> K [metadata "builtin wrapper"] 
	op _contains_ : Set K -> Bool [memo] 
	// Types
	op typedDeclaration : Type Id -> Type // would rather this be KResult, but can't get the subsorting to work
	
	sort Type 
	sort Value 
	sort List{Type} 
	subsort List{Type} < KResult 
	subsort List{Type} < List{C} 
	subsort Type < List{Type}
	subsort Type < List{C} 
	subsort Value < List{Type} 
	op _::_ : List{Type} List{Type} -> List{Type} [ditto metadata "ditto"] 
	op Nil : -> List{Type} [ditto] 
	
	
		
	// op myFreezer : KLabel -> K
	
	// rule < k > reval(K:KProper) => K:KProper ~> myFreezer('reval) ...</ k > [structural]
	// rule < k > peval(K:KProper) => K:KProper ~> myFreezer('peval) ...</ k > [structural]
	// rule < k > K:KResult ~> myFreezer(L:KLabel) => L:KLabel(K:KResult) ...</ k > [structural]
	
	
	// op myListFreezer : -> KLabel
	// op myList : K List{Type} List{C} -> K
	// rule 
		// < k > C:C :: L:List{C} => myList(.K, Nil, (C:C :: L:List{C})) ...</ k > 
		// [structural]
	// rule 
		// < k > myList(.K, L:List{Type}, Nil) => L:List{Type} ...</ k >
		// [structural]

	// rule 
		// < k > (.K => K:K) ~> myList((K:K => .K), ?, ?) ...</ k >
		// [structural]
	// rule 
		// < k > (T:Type => .K) ~> myList(.K, (L:List{Type} => (L:List{Type} :: T:Type)), ?) ...</ k >
		// [structural]
	// rule 
		// < k > myList((.K => C:C), ?, (C:C => Nil) :: L:List{C}) ...</ k >
		// [structural]
	
	
	op DeclType : K K -> K [strict(1)] // represents a type before canonicalization.  as in "int *x", first arg is "Int", second arg is "PointerType(JustBase)"
	
	
	op setOfTypes : -> Set [memo] 
	rule setOfTypes => Set(
		l('arrayType),, 
		l('bitfieldType),, 
		l('functionType),, 
		l('pointerType),, l('structType),, l('unionType),, 
		l('qualifiedType)
	) [structural]
	
	//ceq TranslationUnit(S:String, L:List{C}, S':String) = TranslationUnit(S:String, L:List{C}, "") if S':String =/=Bool ""
	
	op bind : List{C} List{Type} -> K 
	op tv : List{K} Type -> Value 
	// op lv : List{K} Type -> Value
	op concretize : Type K -> K [strict(2)] 
	op functionObject : Id Type K -> Value 
	op functionPrototype : Id Type -> Value 
	
	op firstChar : String -> Char 
	op nthChar : String Nat -> Char 
	op butFirstChar : String -> String 
	op charToAscii : String -> Nat 
	op stringToChar : String -> Char 
	op asciiCharString : String -> Nat 
	
	op _to_ : Nat Nat -> List{K} 
	op cast : K K -> K [strict(1)] // as described in 6.3 // totype, fromvalue
	context cast(_, ([HOLE] => reval([HOLE])))
	op arithInterpret : Type BaseValue -> K // interpret the result of arithmetic as in 6.5.4
	op interpret : Type K -> K // interpret the values of reading from mem
	op leftShiftInterpret : Type BaseValue K -> K 
	op rightShiftInterpret : Type BaseValue -> K 
	
	op integerTypes : -> Set [memo] 
	op unsignedIntegerTypes : -> Set [memo] 
	op signedIntegerTypes : -> Set [memo] 
	op hasIntegerType : Type -> Bool [memo] 
	op hasFloatType : Type -> Bool [memo] 
	op hasUnsignedIntegerType : Type -> Bool [memo] 
	op hasSignedIntegerType : Type -> Bool [memo] 
	
	op typeof : K -> K 
	op writeToFD : Nat Nat -> K 
	op writeToFD : Nat String -> K 
	op readFromFD : Nat -> K 
	op readFromFD : Nat Nat -> K 

	op calculateLength : List{Type} -> K 
	op calculateGotoMap : Id K -> K 
	
	op hasCharType : Type -> Bool 
	// fixme make sure i use this everywhere instead of T:BaseType
	// op isABaseType_ : K -> Bool 
	op hasPointerType : Type -> Bool 
	op hasArrayType : Type -> Bool 
	op hasBoolType : Type -> Bool 
	op hasStructType : Type -> Bool 
	op hasUnionType : Type -> Bool 
	op hasAggregateType : Type -> Bool 
	op hasFunctionType : Type -> Bool 
	op hasFunctionPointerType : Type -> Bool 
	op hasBitfieldType : Type -> Bool 
	op hasExternType : Type -> Bool 
	op hasStaticType : Type -> Bool 
	op hasIncompleteType : Type -> Bool 
	op hasTypedefType : Type -> Bool 
	
	op aggregateInfo : List{C} Map Map -> K // first map is for type, second map is for offset
	op getFieldOffset : Id K -> Nat // these expect an aggregateInfo term as second argument
	op getFieldType : Id K -> Type
	rule getFieldOffset(F:Id, aggregateInfo(?, ?, (? F:Id |-> N:Nat))) => N:Nat [structural]
	rule getFieldType(F:Id, aggregateInfo(?, ?, (? F:Id |-> T:Type))) => T:Type [structural]
	
	op kpair : K K -> K 
	op promote : K -> K 
	op extractField : List{K} K Id -> K // bytes of struct, type, field id
	op allocString : Nat String -> K 
	op sequencePoint : -> K 
	
	op handleBuiltin : Id Type -> K 
	
	op min : Type -> Int [memo]
	op max : Type -> Int [memo]
	op alloc : K K -> K // should be K K 
	
	// these are also used by compound literals
	op initializerValue : Id Type K -> KResult 
	op figureInitializer : Id K K -> K [strict(2)] // id, type, initializer
	
		
	op append : Nat Nat Value -> K // appends a new subobject to a current object.  this is unsafe and should only be used for variadic functions
	op deleteBlock : Nat -> K // deletes the base object from memory, given a location
	op deleteSizedBlock : Nat Nat -> K // deletes the base object from memory, given a location and it size (as a check)
	
	
	op isConcreteNumber : Int -> Bool 
	op _in_ : K List -> Bool 
endkm

kmod C-SETTINGS is
	including INCOMING-MODULES 
	including COMMON-SEMANTIC-SYNTAX 

	op IdentifierSet : List{K} -> Set 
	rule IdentifierSet((S:String,, L:List{K})) => SetItem(Identifier(S:String)) IdentifierSet(L:List{K}) [structural]
	op builtinIdentifiers : -> Set [memo] 
	
	// fixme bug why can't i use .List{K} here?
	rule builtinIdentifiers => IdentifierSet((
		"abort"
		,, "asin"
		,, "atan"
		,, "atan2"
		,, "calloc"
		,, "cos"
		,, "debug"
		,, "exit"
		,, "exp"
		,, "floor"
		,, "fmod"
		,, "free"
		,, "fslCloseFile"
		,, "fslFGetC"
		,, "fslOpenFile"
		,, "fslPutc"
		,, "getchar"
		,, "log"
		,, "longjmp"
		,, "malloc"
		,, "printf"
		,, "putchar"
		,, "rand"
		,, "setjmp"
		,, "sin"
		,, "sqrt"
		,, "tan"
		// <threads.h>
		,, "thrd_create"
		,, "thrd_current"
		,, "thrd_detach"
		,, "thrd_join"
		,, "__test_and_set"
		,, "__va_inc"
		,, "__va_start"
		,, "__va_end"
		,, "__va_copy"
	)) [structural]
	
	// S 6.2.5 p.35 i.15.  "The implementation shall define char to have the same range, representation, and behavior as either signed char or unsigned char.  37)... Irrespective of the choice made, char is a separate type from the other two and is not compatible with either
	// fixme I'm not sure what consequence being a separate type entails, so for now it will just be rewritten to the chosen type
	rule char => signed-char 
		[structural] 

	op numBitsPerByte : -> NzNat 
	op numBytes : Type -> Nat [memo] 
	op numBits : Type -> Nat [memo] 

	rule numBitsPerByte => 8 [structural]
	
	rule numBytes(bool) => 1 [structural]
	rule numBytes(signed-char) => 1 [structural]
	rule numBytes(short-int) => 2 [structural]
	rule numBytes(int) => 4 [structural]
	rule numBytes(long-int) => 4 [structural]
	rule numBytes(long-long-int) => 8 [structural]
	
	rule numBytes(float) => 4 [structural]
	rule numBytes(double) => 8 [structural]
	rule numBytes(long-double) => 16 [structural]
	
	rule numBytes(enumType(X:Id)) => numBytes(int) [structural]
	
	op cfg:sizeut : -> Type 
	rule cfg:sizeut => unsigned-long-int [structural]
	
	op cfg:largestUnsigned : -> Type 
	rule cfg:largestUnsigned => unsigned-long-long-int [structural]

	op cfg:ptrsize : -> Nat 
	rule cfg:ptrsize => 4 [structural]
	
	op cfg:ptrdiffut : -> Type 
	rule cfg:ptrdiffut => int [structural]
	
	rule min(enumType(?)) => min(int) [structural]
	rule max(enumType(?)) => max(int) [structural]
	
	op rank : Type -> Int 
		
	rule rank(bool) => 0 [structural]
	rule rank(char) => 1 [structural]
	rule rank(signed-char) => 1 [structural]
	rule rank(unsigned-char) => 1 [structural]
	rule rank(short-int) => 2 [structural]
	rule rank(unsigned-short-int) => 2 [structural]
	rule rank(int) => 3 [structural]
	rule rank(unsigned-int) => 3 [structural]
	rule rank(long-int) => 4 [structural]
	rule rank(unsigned-long-int) => 4 [structural]
	rule rank(long-long-int) => 5 [structural]
	rule rank(unsigned-long-long-int) => 5 [structural]
	
	rule rank(bignum) => 100 [structural] // used for internal calculation.  should be bigger than all other ranks
	
	rule rank(enumType(?)) => rank(int) [structural]
	//C99 6.3.1.1
	
	/*
	// no two signed are the same
	rank of signed shall be greater than rank of signed with less precision
	rank(long-long-int) > rank(long int) > rank(int) > rank(short int) > rank(signed-char)
	rank unsigned is same as signed
	rank(char) == rank(signed char) == rank(unsigned-char)
	rank(_Bool) < rank(char)
	rank(enumType) == rank compatible int type
	transitive
	*/
endkm

load common-c-sized-operations

kmod COMMON-INCLUDE is
	including INCOMING-MODULES 
	including C-SETTINGS 
	including COMMON-SEMANTIC-SYNTAX
	including FIXED-WIDTH-SYNTAX
endkm

kmod C-SEMANTICS-MISC is
	including COMMON-INCLUDE 
	
	rule sym(N:Nat) +Nat M:Nat <Nat sym(N:Nat) +Nat M':Nat => true
		if M:Nat <Nat M':Nat
		[structural]
	rule sym(N:Nat) +Nat M:Nat <=Nat sym(N:Nat) +Nat M':Nat => true
		if M:Nat <=Nat M':Nat
		[structural]
	rule sym(N:Nat) +Nat M:Nat >Nat sym(N:Nat) +Nat M':Nat => true
		if M:Nat >Nat M':Nat
		[structural]
	rule sym(N:Nat) +Nat M:Nat >=Nat sym(N:Nat) +Nat M':Nat => true
		if M:Nat >=Nat M':Nat
		[structural]
		
	
	rule inc(sym(N:Nat) +Nat M:Nat) => sym(N:Nat +Nat 1) +Nat M:Nat [structural]
	rule sNat(sym(N:Nat) +Nat M:Nat) => sym(N:Nat) +Nat (M:Nat +Nat 1) [structural]
	rule I:Int +Int (N:Nat +Nat sym(M:Nat))
		=> absInt(N:Nat +Int I:Int) +Nat sym(M:Nat) 
		if N:Nat +Int I:Int >=Int 0 
		[structural]
		
	rule (N:Nat +Nat sym(M:Nat)) -Int I:Int
		=> absInt(N:Nat -Int I:Int) +Nat sym(M:Nat) 
		if N:Nat -Int I:Int >=Int 0 
		[structural]
		
	rule
		< k > sequencePoint => .K ...</ k >
		< locsWrittenTo > ? => .Bag </ locsWrittenTo >
		[structural] 
		
	// //C99 6.5.3.2 (p79) footnote 90) Thus, &*E == E; &(E1[E2]) == (E1 + E2)
	
	// //C99 6.5.3.2 90) ... It is always true that if E is a function designator or an lvalue that is a valid operand of the u of the unary & operator, *&E is a function designator or an lvalue equal to E

				
	// fixme these should be computational, unless I handle that at a higher level
	rule [writeToFD-char]:
		< k > writeToFD(FD:Nat, N:Nat) => .K ...</ k >
		< openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		< files >... Filename:String |-> (S:String => S:String +String charString(N:Nat %Nat 256)) ...</ files >
		[structural]
		// [metadata "computational"]
	rule [writeToFD-string]:
		< k > writeToFD(FD:Nat, S':String) => .K ...</ k >
		< openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		< files >... Filename:String |-> (S:String => S:String +String S':String) ...</ files >
		[structural]
		// [metadata "computational"]
	rule [readFromFD-char]:
		< k > readFromFD(FD:Nat) => tv(charToAscii(firstChar(S:String)), int)  ...</ k >
		< openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		< files >... Filename:String |-> (S:String => butFirstChar(S:String)) ...</ files >
		if S:String =/=Bool ""
		[structural]
		// [metadata "computational"]
	rule [readFromFD-char-eof]:
		< k > readFromFD(FD:Nat) => tv(-1, int) ...</ k > // -1 should be EOF
		< openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		< files >... Filename:String |-> (S:String => butFirstChar(S:String)) ...</ files >
		if S:String ==Bool ""
		[structural]
		// [metadata "computational"]
		
	// rule
		// < k > readFromFD(FD:Nat, Offset:Nat) 
			// => tv(charToAscii(nthChar(S:String, Offset:Nat)), int)
		// ...</ k >
		// < openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		// < files >... Filename:String |-> S:String ...</ files >
		// if lengthString(S:String) >Nat Offset:Nat
		// [structural] 
	// rule
		// < k > readFromFD(FD:Nat, Offset:Nat) => tv(-1, int)  ...</ k >
		// < openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		// < files >... Filename:String |-> S:String ...</ files >
		// if lengthString(S:String) <=Nat Offset:Nat
		// [structural] 

	rule listToK(K:K) => klistToK(getList{K}(K:K)) [structural]
	rule klistToK((K:K,, L:List{K})) => K:K ~> klistToK(L:List{K}) [structural]
	rule klistToK(.List{K}) => .K [structural]
	
	rule CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc [structural]
	
	
	// TODO nicely handle loc range instead of ignoring L2
	// fixme feature i'd like to say ? instead of k, but context transformers don't work that way
	rule
		< k > DefinitionLocRange(K:K, L1:CabsLoc, L2:CabsLoc) => K:K ...</ k >
		< currentProgramLoc > ? => L1:CabsLoc </ currentProgramLoc >
		[structural] 
	rule [DefinitionLoc-k]:
		< k > DefinitionLoc(K:K, L:CabsLoc) => K:K ...</ k >
		< currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		[structural] 
	rule [StatementLoc-k]:
		< k > StatementLoc(K:K, L:CabsLoc) => K:K ...</ k >
		< currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		[structural] 
	rule [EnumItemLoc-k]:
		< k > EnumItemLoc(K:K, L:CabsLoc) => K:K ...</ k >
		< currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		[structural] 
		
	rule [Attributes]:
		< k > Attribute(S:String, L:List{C}) => AttributeValue(S:String, L:List{C}) ...</ k >
		[structural]
		
	rule AttributeWrapper(K:K, ?) => K:K [structural]
	rule NameLoc(K:K, ?) => K:K [structural]
	
	rule N:Nat +Nat bito(M:Nat) => N:Nat +Nat (M:Nat /Nat numBitsPerByte) +Nat bito(M:Nat %Nat numBitsPerByte)
		if M:Nat >=Nat numBitsPerByte 
		[structural]
	
		
	rule Identifier("___missing_field_name") => #NoName [structural]
endkm

load common-c-conversions
load common-c-expressions
load common-c-statements
load common-c-standard-lib
load common-c-typing
load common-c-memory
load common-c-declarations
load common-c-helpers

kmod COMMON-C-SEMANTICS is
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
	
	op eval : K -> Bag 
	op eval : K List{K} String -> Bag
endkm
