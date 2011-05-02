kmod INCOMING-MODULES is
	including K 
	including C-SYNTAX 
	including C-CONFIGURATION 
	including K-CONTEXTS 
	including K-PROPER
endkm

kmod STATIC-SEMANTIC-SYNTAX is
	including INCOMING-MODULES 
	
	
	op usualArithmeticConversion : Type Type -> K
	op callMain-aux : K Nat Id K -> K [strict(1)] // having to put this out here so errors can see it
	op initFunction : K K -> K [strict]
	
	op checkValidLoc : K -> K
	op checkDerefLoc : K -> K
	op ListItem : BagItem -> ListItem
	op ListToK : List -> K 
	op Map : Map -> K 
	op piece : Nat Nat -> Nat 
	
	op unknown : Nat -> Nat [ctor] 
	
	op skipval : -> KResult 
	op debug : -> K 
	op discard : -> K 
	op File-Scope : -> Id [ctor] 
	op unnamedBitField : -> Id [ctor] 
	op bignum : -> Type 
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
	
	op isArithBinConversionOp : KLabel -> Bool 
	op isArithUnaryOp : KLabel -> Bool 
	op kpair : K K -> K 
	op promote : K -> K 
	op argPromote : K -> K
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

kmod COMMON-INCLUDE is
	including INCOMING-MODULES 
	// including C-SETTINGS 
	including STATIC-SEMANTIC-SYNTAX
	// including FIXED-WIDTH-SYNTAX
endkm

kmod STATIC-C-SEMANTICS is
	including COMMON-INCLUDE 
	// including C-SEMANTICS-MISC 
	
	
	rule listToK(K:K) => klistToK(getList{K}(K:K)) [structural]
	rule klistToK((K:K,, L:List{K})) => K:K ~> klistToK(L:List{K}) [structural]
	rule klistToK(.List{K}) => .K [structural]
	
	op incomingArguments : List{K} -> K
	op incomingArguments-aux : List{K} Nat -> K
	
	rule incomingArguments(L:List{K}) 
			=> incomingArguments-aux(L:List{K}, 0) 
		[structural]
	rule incomingArguments-aux((S:String,, L:List{K}), N:Nat) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:Nat] := StringLiteral(S:String))
			~> incomingArguments-aux(L:List{K}, sNat(N:Nat))
		[structural]
	rule incomingArguments-aux(.List{K}, N:Nat) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:Nat] := NullPointer)
		[structural]

/*@ \source{C99 5.1.2.2.1:1}
The function called at program startup is named main. The implementation declares no prototype for this function. It shall be defined with a return type of int and with no parameters:
\clisting{int main(void) { ... }}
or with two parameters (referred to here as \cinline{argc} and \cinline{argv}, though any names may be used, as they are local to the function in which they are declared):
\clisting{int main(int argc, char *argv[]) { ... }}
or equivalent;9) or in some other implementation-defined manner
*/

	//@ this bit of indirection is used to check that the main prototype is correct, and to call it with the appropriate arguments
	op callMain : Nat Id K -> K
	
	rule < k > callMain(N:Nat, X:Id, Args:K)
			=> callMain-aux(typeof(Identifier("main")), N:Nat, X:Id, Args:K)
		...</ k >
		< functionTranslationUnits >... Tu:K |-> Map((? Identifier("main") |-> Tu:K)) ...</ functionTranslationUnits >
		< currentTranslationUnit > ? => Tu:K </ currentTranslationUnit >
		[structural]
	
	// FIXME i think these are slightly different
	// fixme void isn't supposed to have a name
	// fixme figure out type of string
	rule callMain-aux(functionType(int, typedDeclaration(void, ?)), N:Nat, X:Id, ?) => Call(Identifier("main"), Nil) [structural]
	rule callMain-aux(functionType(int, Nil), N:Nat, X:Id, ?) => Call(Identifier("main"), Nil) [structural]
	rule callMain-aux(functionType(int, (typedDeclaration(int, ?) :: typedDeclaration(incompleteArrayType(pointerType(T:Type)), ?))), N:Nat, X:Id, Args:K)
		=> Args:K ~> Call(Identifier("main"), N:Nat :: X:Id)
		if T:Type ==Bool char
		[structural]
	rule callMain-aux(functionType(int, (typedDeclaration(int, ?) :: typedDeclaration(pointerType(pointerType(T:Type)), ?))), N:Nat, X:Id, Args:K)
		=> Args:K ~> Call(Identifier("main"), N:Nat :: X:Id)
		if T:Type ==Bool char
		[structural]

	op syntaxNat : Nat -> K
	rule syntaxNat(N:Nat) => Constant(IntLiteral(NoSuffix(DecimalConstant(N:Nat)))) [structural]
	
	rule eval(K:K) => eval(K:K, .List{K}, "") [structural]
	rule eval(Program(P:List{C}), L:List{K}, Input:String) =>
		< T >
			< threads >
				< thread >
					< control >
						< k > listToK(P:List{C})
							~> DeclarationDefinition(InitNameGroup(Specifier(Char), InitName(Name(Identifier("#incomingArgumentsArray"), PointerType(ArrayType(JustBase, syntaxNat(sNat(lengthList{K} L:List{K}))))), NoInit)))
							~> resolveReferences					
							// ~> incomingArguments(L:List{K})
							~> callMain(lengthList{K}(L:List{K}), Identifier("#incomingArgumentsArray"), incomingArguments(L:List{K}))
						</ k >
						< currentFunction > File-Scope </ currentFunction >
						< currentProgramLoc > UnknownCabsLoc </ currentProgramLoc >
					...</ control >
					< threadId > 1 </ threadId >
					< nextLoc > sym(threadId(1) +Nat 0) +Nat 0 </ nextLoc >
				...</ thread >
			</ threads >
			<nextSharedLoc> sym(threadId(0) +Nat 0) +Nat 0 </nextSharedLoc>
			< nextFile > 3 </ nextFile >
			< openFiles >
				0 |-> "stdin" // stdin
				1 |-> "stdout" // stdout
				2 |-> "stdout" // stderr
			</ openFiles >
		...</ T >
		< files > 
			"stdin" |-> Input:String
			"stdout" |-> ""
		</ files >
		< xmessages > .K </ xmessages >
		[structural]
		

	// fixme I'm not sure threads clean up their memory
	
	rule [terminate]:
		(< T >... < threads >... < thread >... 
			< threadId > 1 </ threadId > // main's thread, not the global "thread"
			< k > V:Value </ k >
		...</ thread > ...</ threads > ...</ T >
			=> < resultValue > V:Value </ resultValue >)
		< files >...
			"stdin" |-> S1:String	"stdout" |-> S2:String => .Map
		...</ files >
		(.Bag => < input > S1:String </ input >	< output > S2:String </ output >)
	
	
	
	
	// including FIXED-C-STYLE
	// including FIXED-C-STYLE-TWOS-COMPLEMENT 
	
	// including COMMON-C-HELPERS
	// including COMMON-C-TYPING 
	// including COMMON-C-DECLARATIONS 
	// including COMMON-C-MEMORY 
	// including COMMON-C-STATEMENTS 
	// including COMMON-C-EXPRESSIONS 
	// including COMMON-C-CONVERSIONS 
	// including COMMON-C-STANDARD-LIBRARY 
	// including COMMON-C-ERRORS
	
	op eval : K -> Bag 
	op eval : K List{K} String -> Bag
	
	op TranslationUnitName : String -> KLabel
endkm
