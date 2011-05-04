// this file is an experiment in progress.  please ignore it if you're looking to read the semantics.

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
	rule cfg:sizeut => unsigned-int [structural]
	
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

kmod COMMON-INCLUDE is
	including INCOMING-MODULES 
	// including C-SETTINGS 
	including STATIC-SEMANTIC-SYNTAX
	// including FIXED-WIDTH-SYNTAX
endkm


kmod COMMON-SEMANTICS-DECLARATIONS-INCLUDE is
	including COMMON-INCLUDE 
	op figureInitializer-aux : Id Type K -> K [strict(3)] // id, type, initializer
	op declarationObject : Type K K -> K // type, translation unit it was defined in, definition
	
	op external : -> K 
	op internal : -> K 
	op noLinkage : -> K 
	
	op initializer : K -> KResult 
	op startInitializer : Type Id K -> K 
endkm

kmod COMMON-SEMANTICS-DECLARATIONS-BINDING is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 

	// empty binding
	// fixme not really a sequence point
	
	op bind-aux : Nat List{C} List{Type} -> K 
	rule
		< k > bind(L:List{C}, L':List{Type}) => bind-aux(NullPointer, L:List{C}, L':List{Type}) ...</ k > 
		[structural] 
	
	rule [bind-empty-void]:
		< k > bind-aux(?, Nil, typedDeclaration(void, ?)) => sequencePoint ...</ k > 
		[structural] 
	rule [bind-empty]:
		< k > bind-aux(?, Nil, Nil) => sequencePoint ...</ k > 
		[structural] 
		
		
	// n1494 6.5.2.2:6 If the expression that denotes the called function has a type that does not include a prototype, the integer promotions are performed on each argument, and arguments that have type float are promoted to double. These are called the default argument promotions. If the number of arguments does not equal the number of parameters, the behavior is undefined. If the function is defined with a type that includes a prototype, and either the prototype ends with an ellipsis (, ...) or the types of the arguments after promotion are not compatible with the types of the parameters, the behavior is undefined. If the function is defined with a type that does not include a prototype, and the types of the arguments after promotion are not compatible with those of the parameters after promotion, the behavior is undefined, except for the following cases: 
	// -- one promoted type is a signed integer type, the other promoted type is the corresponding unsigned integer type, and the value is representable in both types;
	// -- both types are pointers to qualified or unqualified versions of a character type or void
	
	rule [bind-coerce-array]:
		bind-aux(
			?
			, L:List{C}
			, (
				?:List{Type}
				:: typedDeclaration(
					(arrayType(T:Type, ?) => pointerType(T:Type))
					, X:Id
				)
				:: ?:List{Type}
			)
		)
		[structural] 
	rule [bind-coerce-incompleteArray]:
		bind-aux(
			?
			, L:List{C}
			, (
				?:List{Type} 
				:: typedDeclaration(
					(incompleteArrayType(T:Type) => pointerType(T:Type))
					, X:Id
				) 
				:: ?:List{Type})
		)
		[structural] 
		
	rule [bind-one]:
		< k > true ~> bind-aux(?, (tv(V:List{K}, T':Type) :: L:List{C}), (typedDeclaration(T:Type, X:Id) :: P:List{Type}))
			=> allocateType(Loc:Nat, T:Type)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
			~> initialize(X:Id, T:Type, Computation(X:Id := tv(V:List{K}, T':Type)))
			~> bind-aux(Loc:Nat, L:List{C}, P:List{Type}) 
		...</ k > 
		< nextLoc > Loc:Nat => inc(Loc:Nat) </ nextLoc >
		< localAddresses >... .Set => SetItem(Loc:Nat) ...</ localAddresses >
		if notBool hasArrayType(T:Type)
		[structural] 
		
	rule [bind-one-check-type]:
		< k > (. => isTypeCompatible(T:Type, T':Type)) ~> bind-aux(?, (tv(V:List{K}, T':Type) :: L:List{C}), (typedDeclaration(T:Type, X:Id) :: P:List{Type}))
		...</ k > 
		[structural] 
	
	op promoteList : List{C} -> List{K} 
	rule promoteList((tv(V:List{K}, T:Type) :: L:List{C})) => (cast(argPromote(T:Type), tv(V:List{K}, T:Type)),, promoteList(L:List{C}))
		if ((rank(T:Type) <Int rank(int) orBool hasBitfieldType(T:Type)) andBool hasIntegerType(T:Type)) 
		orBool T:Type ==Bool float 
		[structural]
	rule promoteList((tv(V:List{K}, T:Type) :: L:List{C})) => (tv(V:List{K}, T:Type),, promoteList(L:List{C}))
		if (notBool(hasIntegerType(T:Type)) 
			andBool notBool T:Type ==Bool float
			andBool notBool hasArrayType(T:Type)
		) 
		orBool rank(T:Type) >=Int rank(int)
		orBool T:Type ==Bool double 
		orBool T:Type ==Bool long-double
		[structural]
		
	rule promoteList((tv(?, (arrayType(T:Type, ?) => pointerType(T:Type))) :: ?)) 
		[structural] 
		
	op bindVariadic : K List{KResult} -> K 
	op bindVariadic-pre : K List{K} -> K 
	rule promoteList(Nil) => .List{K} [structural]
	
	// the idea here is that there should have been a previous argument, so we can use its address to append all of the variadic arguments	
	rule [bind-variadic-pre]:
		< k > bind-aux(Loc:Nat, L:List{C}, variadic)
			=> bindVariadic-pre(Loc:Nat, promoteList(L:List{C}))
		...</ k >
		[structural] 

	rule [bind-variadic-start]:
		< k > bindVariadic-pre(Loc:Nat, L:List{KResult}) 
			=> bindVariadic(Loc:Nat, L:List{KResult})
		...</ k >
		[structural]
	
	// fixme don't forget to get rid of append
	
	// this rule assumes it will be run immediately after other normal bindings for the same function.  This is all wrong if it is computational instead of structural because of other threads interleaving
	rule [bind-variadic]:
		< k > (.K 
				=> allocateType(Loc:Nat, Type)
				~> Computation(*(tv(Loc:Nat, pointerType(Type))) := V:Value)
			) 
			~> bindVariadic(?, ((V:Value => .List{K}),, ?:List{KResult})) 
		...</ k >
		< nextLoc > Loc:Nat => inc(Loc:Nat) </ nextLoc >
		< localAddresses >... .Set => SetItem(Loc:Nat) ...</ localAddresses >
		where Type = type(V:Value)
		[structural]
	
	rule [bind-variadic-done]:
		< k > bindVariadic(?, .List{K}) => sequencePoint ...</ k > 
		[structural]
endkm

kmod COMMON-SEMANTICS-DECLARATIONS-GENERAL is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 

	// c99 6.7.8:9 Except where explicitly stated otherwise, for the purposes of this subclause unnamed members of objects of structure and union type do not participate in initialization.  Unnamed members of structure objects have indeterminate value even after initialization
	// c99 6.7.8:10 If an object that has automatic storage duration is not initialized explicitly, its value is indeterminate. If an object that has static storage duration is not initialized explicitly, then:
	// -- if it has pointer type, it is initialized to a null pointer;
	// -- if it has arithmetic type, it is initialized to (positive or unsigned) zero;
	// if it is an aggregate, every member is initialized (recursively) according to these rules;
	// -- if it is a union, the first named member is initialized (recursively) according to these rules

	op defineType : K -> K [strict] 
	context DeclarationDefinition(InitNameGroup(`[HOLE`]:K, ?)) 
	context Typedef(NameGroup(`[HOLE`]:K, ?)) 
	
	// rule
		// < k > LocalDefinition(DefinitionLoc(K:K, Loc:K)) => DefinitionLoc(K:K, Loc:K) ...</ k >
		// [structural] 
	
	rule
		< k > figureInitializer(X:Id, T:Type, CodeLoc(K:K, L:K)) 
			=> CodeLoc(.K, L:K)
			~> figureInitializer(X:Id, T:Type, K:K) 
		...</ k >
		[structural]
		
	
	// aggregates
	rule
		< k > figureInitializer(X:Id, T:Type, CompoundInit(L:List{C}))
			=> giveType(X:Id, T:Type)
			~> figureInitializer-aux(X:Id, T:Type, startInitializer(T:Type, X:Id, CompoundInit(L:List{C})))
		...</ k >
		if (hasAggregateType(T:Type) orBool hasUnionType(T:Type)) 
		//andBool notBool hasIncompleteType(T:Type)
		[structural] 
	rule
		< k > figureInitializer(X:Id, arrayType(T:Type, Len:Nat), SingleInit(Constant(StringLiteral(S:String)))) 
			=> figureInitializer(X:Id, arrayType(T:Type, Len:Nat), CompoundInit(InitFragment(NextInit, SingleInit(Constant(StringLiteral(S:String))))))
		...</ k >
		if hasCharType(T:Type)
		andBool lengthString(S:String) <=Nat Len:Nat
		[structural] 
	
	rule
		< k > figureInitializer(X:Id, (incompleteArrayType(T:Type) => arrayType(T:Type, lengthString(S:String) +Nat 1)), SingleInit(Constant(StringLiteral(S:String)))) ...</ k >
		if hasCharType(T:Type)
		[structural] 
		
	rule
		< k > figureInitializer(X:Id, incompleteArrayType(T:Type), CompoundInit(InitFragment(NextInit, SingleInit(Constant(StringLiteral(S:String))))))
			=> figureInitializer(X:Id, incompleteArrayType(T:Type), SingleInit(Constant(StringLiteral(S:String))))
		...</ k >
		[structural] 
		
	// this comes from function declarations.  should probably adjust this
	rule
		< k > figureInitializer(X:Id, T:Type, initializer(K:K))
			=> figureInitializer-aux(X:Id, T:Type, initializer(K:K))
		...</ k >
		[structural] 

	rule
		< k > figureInitializer-aux(X:Id, T:Type, initializer(K:K))
			=> initializerValue(X:Id, T:Type, K:K)
		...</ k >
		//< currentProgramLoc > L:CabsLoc </ currentProgramLoc >
		if notBool hasIncompleteType(T:Type) // I'd like to get rid of this cleanly
		[structural]
	
	// base types
	rule
		< k > figureInitializer(X:Id, T:Type, SingleInit(K:K))
			=> figureInitializer-aux(X:Id, T:Type, initializer(Computation(X:Id := K:K)))
		...</ k >
		if notBool hasArrayType(T:Type)
		[structural] 
	// c1x 6.7.8:11
	rule
		< k > figureInitializer(X:Id, T:Type, CompoundInit(InitFragment(NextInit, SingleInit(K:K))))
			=> figureInitializer-aux(X:Id, T:Type, initializer(Computation(X:Id := K:K)))
		...</ k >
		if notBool (hasAggregateType(T:Type) orBool hasUnionType(T:Type))
		[structural] 
		
	rule DeclarationDefinition(InitNameGroup(T:Type, (K:C :: K':C :: L:List{C}))) 
		=> DeclarationDefinition(InitNameGroup(T:Type, K:C)) 
		~> DeclarationDefinition(InitNameGroup(T:Type, K':C :: L:List{C})) 
		[structural]
	rule DeclarationDefinition(InitNameGroup(T:Type, InitName(Name:K, Exp:K))) => declare(SingleName(T:Type, Name:K), Exp:K) [structural]
			
	rule Typedef(NameGroup(T:Type, (K:C :: K':C :: L:List{C}))) => Typedef(NameGroup(T:Type, K:C)) ~> Typedef(NameGroup(T:Type, K':C :: L:List{C})) [structural]
	rule Typedef(NameGroup(T:Type, Name:C)) => defineType(SingleName(T:Type, Name:C)) [structural]
		
	op initialize-aux : Id Type K -> K 
		
	// c1x 6.7.8:21 ... the remainder of the aggregate shall be initialized implicitly the same as objects that have static storage duration
	rule
		< k > initialize(X:Id, T:Type, K:K)
			=> if (F:Id ==Bool File-Scope) then zero(X:Id) else (.) fi 
			~> K:K
			~> sequencePoint
		...</ k >
		< currentFunction > F:Id </ currentFunction >
		[structural] 

	rule
		< k > zero(Name:K) => zeroType(Name:K, unqualifyType(T:Type)) ...</ k >
		< types >... Name:K |-> T:Type ...</ types >
		[structural] 
		
	op zeroType : K Type -> K 
	
	rule
		< k > zeroType(Name:K, T:Type) => Computation(Name:K := tv(0, int)) ...</ k >
		if hasIntegerType(T:Type)
		[structural] 
	rule
		< k > zeroType(Name:K, T:Type) => Computation(Name:K := tv(0.0, float)) ...</ k >
		if hasFloatType(T:Type)
		[structural] 
		
	op zeroStruct : K List{C} -> K 
	
	// c1x 6.7.9:10 If an object that has automatic storage duration is not initialized explicitly, its value is indeterminate. If an object that has static or thread storage duration is not initialized explicitly, then:
	// -- if it has pointer type, it is initialized to a null pointer;
	// -- if it has arithmetic type, it is initialized to (positive or unsigned) zero;
	// -- if it is an aggregate, every member is initialized (recursively) according to these rules, and any padding is initialized to zero bits;
	// -- if it is a union, the first named member is initialized (recursively) according to these rules, and any padding is initialized to zero bits;
	
	rule
		< k > zeroType(Name:K, structType(S:Id)) 
			=> zeroStruct(Name:K, Fields:List{Type})
		...</ k >
		< structs >... S:Id |-> aggregateInfo(Fields:List{Type}, ?, ?) ...</ structs > 
		[structural] 
		
	rule
		< k > zeroType(Name:K, unionType(S:Id)) 
			=> zeroType(Name:K . F:Id, T:Type)
		...</ k >
		< structs >... 
			S:Id |-> aggregateInfo((typedDeclaration(T:Type, F:Id) :: ?), ?, ?) 
		...</ structs > 
		[structural] 
		
	rule
		< k > zeroStruct(Name:K, (typedDeclaration(T:Type, F:Id) :: L:List{C})) 
			=> zeroType(Name:K . F:Id, T:Type)
			~> zeroStruct(Name:K, L:List{C}) 
		...</ k >
		[structural] 
	rule
		< k > zeroStruct(Name:K, Nil) => .K ...</ k >
		[structural] 
		
	// rule
		// < k > zeroType(Name:K, T:Type) => initFunction(Name:K, tv(NullPointer, T:Type)) ...</ k >
		// if hasFunctionType(T:Type)
		// orBool hasPointerType(T:Type)
		// [structural]
	rule
		< k > zeroType(Name:K, T:Type) => Computation(Name:K := tv(NullPointer, T:Type)) ...</ k >
		if hasPointerType(T:Type)
		[structural]
	rule
		< k > zeroType(Name:K, T:Type) => .K ...</ k >
		if hasFunctionType(T:Type)
		[structural]
		
	rule
		< k > zeroType(Name:K, arrayType(T:Type, sNat(Len:Nat))) 
			=> zeroType(Name:K[Len:Nat], T:Type)
			~> zeroType(Name:K, arrayType(T:Type, Len:Nat)) 
		...</ k >
		[structural] 
	rule
		< k > zeroType(Name:K, arrayType(T:Type, 0)) => .K ...</ k >
		[structural] 

	rule
		< k > zeroType(Name:K, flexibleArrayType(T:Type))
			=> .K
		...</ k >
		[structural]
	
	rule
		< k > defineType(typedDeclaration(T:Type, X:Id)) => giveType(typedef(X:Id), T:Type) ...</ k >
		[structural] 
			
	op declareFunction : Id Type K -> K 
	op declareExternalVariable : Id Type K -> K 
	op declareInternalVariable : Id Type K -> K 
	
	// function definition
	rule
		< k > declare(typedDeclaration(T:Type, X:Id), K:K) 
			=> declareFunction(X:Id, T:Type, K:K)
		...</ k >
		< currentFunction > File-Scope </ currentFunction >
		if notBool hasIncompleteType(T:Type) // I'd like to get rid of this cleanly
		andBool hasFunctionType(T:Type)
		[structural] 
		
	// fixme there are still no nested functions though, right?
	rule
		< k > declare(typedDeclaration(T:Type, X:Id), NoInit) 
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:Type))
		...</ k >
		< externalLocations >... X:Id |-> Loc:Nat ...</ externalLocations > 
		< currentFunction > F:K </ currentFunction >
		if notBool hasIncompleteType(T:Type) // I'd like to get rid of this cleanly
		andBool hasFunctionType(T:Type)
		andBool F:K =/=Bool File-Scope
		[structural] 
	rule
		< k > declare(typedDeclaration(T:Type, X:Id), K:K)
			=> declareExternalVariable(X:Id, T:Type, if K:K ==Bool NoInit then NoInit else CodeLoc(K:K, L:CabsLoc) fi)
		...</ k >
		< currentFunction > File-Scope </ currentFunction >
		< currentProgramLoc > L:CabsLoc </ currentProgramLoc >
		// if notBool hasIncompleteType(T:Type) // I'd like to get rid of this cleanly
		if notBool hasFunctionType(T:Type)
		[structural] 
	rule
		< k > declare(typedDeclaration(T:Type, X:Id), K:K) 
			=> declareInternalVariable(X:Id, T:Type, K:K)
		...</ k >
		< currentFunction > F:K </ currentFunction >
		// if notBool hasIncompleteType(T:Type) // I'd like to get rid of this cleanly
		if notBool hasFunctionType(T:Type)
		andBool F:K =/=Bool File-Scope
		[structural] 
		
	//- external variables
	// feature request : nice to have MapList
	
	// function definition
	rule
		< k > declareFunction(X:Id, T:Type, K:K)
			=> declareWithLinkage(X:Id, T:Type, K:K, external)
		...</ k >
		if notBool hasStaticType(T:Type)
		andBool K:K =/=Bool NoInit
		[structural] 

	rule
		< k > declareFunction(X:Id, T:Type, NoInit)
			=> declareWithLinkage(X:Id, prototype(T:Type), NoInit, external)
		...</ k >
		if notBool hasStaticType(T:Type)
		[structural] 
		
	// fixme not handling internal prototypes
	rule
		< k > declareFunction(X:Id, T:Type, K:K)
			=> declareWithLinkage(X:Id, T:Type, K:K, internal)
		...</ k >
		< currentFunction > File-Scope </ currentFunction >
		if hasStaticType(T:Type)
		[structural] 
		
		
	
	op declareWithLinkage : Id Type K K -> K // id, type, possible init, linkage (external, internal, noLinkage)
	
	//- internal variables
	
	// fixme need to look for bad use
	rule
		< k > declareInternalVariable(X:Id, T:Type, K:K)
			=> declareWithLinkage(X:Id, T:Type, K:K, noLinkage)
		...</ k >
		if notBool hasStaticType(T:Type)
		andBool notBool hasExternType(T:Type)
		[structural] 
		
	rule
		< k > declareInternalVariable(X:Id, T:Type, NoInit)
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:Type))
		...</ k >
		< internalLocations >... Tu:K |-> Map((? kpair(X:Id, BlockNum:Nat) |-> Loc:Nat)) ...</ internalLocations >
		< blockHistory > ListItem(BlockNum:Nat) ...</ blockHistory >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if hasStaticType(T:Type)
		andBool notBool hasExternType(T:Type)
		[structural] 
	rule
		< k > declareInternalVariable(X:Id, T:Type, NoInit)
			=> allocateType(Loc:Nat, T:Type)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:Type))
			~> zero(X:Id)
		...</ k >
		< internalLocations >... Tu:K |-> Map((Locs:Map => Locs:Map[Loc:Nat / kpair(X:Id, BlockNum:Nat)])) ...</ internalLocations >
		< blockHistory > ListItem(BlockNum:Nat) ...</ blockHistory >
		< nextSharedLoc > Loc:Nat => inc(Loc:Nat) </ nextSharedLoc >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if hasStaticType(T:Type)
		andBool notBool hasExternType(T:Type)
		andBool notBool $hasMapping(Locs:Map, kpair(X:Id, BlockNum:Nat))
		[structural] 
		
	rule
		< k > declareInternalVariable(X:Id, T:Type, K:K)
			=> defineAndInit(X:Id, unqualifyType(T:Type), figureInitializer(X:Id, unqualifyType(T:Type), K:K), Loc:Nat)
		...</ k >
		< internalLocations >... Tu:K |-> Map((Locs:Map => Locs:Map[Loc:Nat / kpair(X:Id, BlockNum:Nat)])) ...</ internalLocations >
		< blockHistory > ListItem(BlockNum:Nat) ...</ blockHistory >
		< nextSharedLoc > Loc:Nat => inc(Loc:Nat) </ nextSharedLoc >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if hasStaticType(T:Type)
		andBool notBool hasExternType(T:Type)
		andBool K:K =/=Bool NoInit
		andBool notBool $hasMapping(Locs:Map, kpair(X:Id, BlockNum:Nat))
		[structural] 
		
	op restoreShouldInit : Bool -> K 
	rule
		< k > restoreShouldInit(OldShouldValue:Bool) => . ...</ k >
		< shouldInit > ? => OldShouldValue:Bool </ shouldInit >
		[structural] 
		
	// statics should only be initialized once.  if we've already seen it, we still need to calculate type, but don't init
	// rule
		// < k > declareInternalVariable(X:Id, T:Type, K:K)
			// => defineAndInit(X:Id, unqualifyType(T:Type), figureInitializer(X:Id, unqualifyType(T:Type), K:K), Loc:Nat)
			// ~> restoreShouldInit(OldShouldValue:Bool)
		// ...</ k >
		// < internalLocations >... Tu:K |-> Map((? kpair(X:Id, BlockNum:Nat) |-> Loc:Nat)) ...</ internalLocations >
		// < blockHistory > ListItem(BlockNum:Nat) ...</ blockHistory >
		// < currentTranslationUnit > Tu:K </ currentTranslationUnit >
		// < shouldInit > OldShouldValue:Bool => false </ shouldInit >
		// if hasStaticType(T:Type)
		// andBool notBool hasExternType(T:Type)
		// andBool K:K =/=Bool NoInit
		// [structural] 
		
	// this is essentially defineandinit, but that checks if type has been seen for allocation
	op reseenStatic : Id Type K Nat -> K [strict(3)] 
	rule
		< k > declareInternalVariable(X:Id, T:Type, K:K)
			=> reseenStatic(X:Id, unqualifyType(T:Type), figureInitializer(X:Id, unqualifyType(T:Type), K:K), Loc:Nat)
		...</ k >
		< internalLocations >... Tu:K |-> Map((? kpair(X:Id, BlockNum:Nat) |-> Loc:Nat)) ...</ internalLocations >
		< blockHistory > ListItem(BlockNum:Nat) ...</ blockHistory >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if hasStaticType(T:Type)
		andBool notBool hasExternType(T:Type)
		andBool K:K =/=Bool NoInit
		[structural] 
		
	rule
		< k > reseenStatic(X:Id, ?, initializerValue(X:Id, T:Type, ?), Loc:Nat)
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
		...</ k >
		[structural] 
		
		
	rule
		< k > declareInternalVariable(X:Id, T:Type, NoInit)
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:Type))
		...</ k >
		< externalLocations >... X:Id |-> Loc:Nat ...</ externalLocations >
		if notBool hasIncompleteType(T:Type)
		andBool notBool hasStaticType(T:Type)
		andBool hasExternType(T:Type)
		[structural] 
		
	
	//- external variables
	rule
		< k > declareExternalVariable(X:Id, T:Type, K:K)
			=> declareWithLinkage(X:Id, T:Type, K:K, external)
		...</ k >
		if notBool hasStaticType(T:Type)
		andBool notBool hasExternType(T:Type)
		[structural] 
	rule
		< k > declareExternalVariable(X:Id, T:Type, K:K)
			=> declareWithLinkage(X:Id, T:Type, K:K, external)
		...</ k >
		< preLinkage >... Tu:K |-> Map(Linkage:Map) ...</ preLinkage >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if notBool hasStaticType(T:Type)
		andBool hasExternType(T:Type)
		andBool notBool $hasMapping(Linkage:Map, X:Id)
		[structural] 
	rule
		< k > declareExternalVariable(X:Id, T:Type, K:K)
			=> declareWithLinkage(X:Id, T:Type, K:K, Linkage:Map(X:Id))
		...</ k >
		< preLinkage >... Tu:K |-> Map(Linkage:Map) ...</ preLinkage >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if notBool hasStaticType(T:Type)
		andBool hasExternType(T:Type)
		andBool $hasMapping(Linkage:Map, X:Id)
		[structural] 
	rule
		< k > declareExternalVariable(X:Id, T:Type, K:K)
			=> declareWithLinkage(X:Id, T:Type, K:K, internal)
		...</ k >
		if hasStaticType(T:Type)
		andBool notBool hasExternType(T:Type)
		[structural] 
		
	op declareOnly : Id Type K -> K 
	op declareAndDefine : Id Type K K -> K 

	rule
		< k > declareWithLinkage(X:Id, T:Type, NoInit, L:K) => declareOnly(X:Id, T:Type, L:K) ...</ k >
		< declarationOrder >... Tu:K |-> ListToK(? (. => ListItem(X:Id))) ...</ declarationOrder >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if L:K =/=Bool noLinkage
		[structural] 
	rule
		< k > declareWithLinkage(X:Id, T:Type, K:K, L:K) => declareAndDefine(X:Id, T:Type, K:K, L:K) ...</ k >
		< declarationOrder >... Tu:K |-> ListToK(? (. => ListItem(X:Id))) ...</ declarationOrder >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if K:K =/=Bool NoInit
		andBool L:K =/=Bool noLinkage
		[structural] 
		
	// fixme this terribly needs to be refactored.  I'm duplicating the above two rules so I don't add locals to the declaration order
	rule
		< k > declareWithLinkage(X:Id, T:Type, NoInit, L:K) => declareOnly(X:Id, T:Type, L:K) ...</ k >
		// < declarationOrder >... Tu:K |-> ListToK(? (. => ListItem(X:Id))) ...</ declarationOrder >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if L:K ==Bool noLinkage
		[structural] 
	rule
		< k > declareWithLinkage(X:Id, T:Type, K:K, L:K) => declareAndDefine(X:Id, T:Type, K:K, L:K) ...</ k >
		// < declarationOrder >... Tu:K |-> ListToK(? (. => ListItem(X:Id))) ...</ declarationOrder >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if K:K =/=Bool NoInit
		andBool L:K ==Bool noLinkage
		[structural] 
	
	// extern functions are no different than functions
	// fixme dangerous if someone marks it as static and extern.  can't tell
	rule qualifiedType(T:Type, Extern) => T:Type
		if hasFunctionType(T:Type) 
		[structural]
	
	// fixme clean these up, they are so redundant
	// fixme unqualifying these is probably unsafe
	rule
		< k > declareOnly(X:Id, T:Type, external)
			=> .K
		...</ k >
		< declarations >... .Set => SetItem(X:Id) ...</ declarations >
		< preLinkage >... Tu:K |-> Map((Linkage:Map => Linkage:Map[external / X:Id])) ...</ preLinkage >
		< preTypes >... Tu:K |-> Map((Types:Map => Types:Map[T:Type / X:Id])) ...</ preTypes >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if (notBool $hasMapping(Linkage:Map, X:Id) 
				orBool Linkage:Map(X:Id) ==Bool external
			)
			andBool (
				notBool $hasMapping(Types:Map, X:Id)
				// orBool Types:Map(X:Id) ==Bool prototype(T:Type)
				orBool isTypeCompatible(unqualifyType(Types:Map(X:Id)), unqualifyType(T:Type))
			)
		[structural] 
		
	rule
		< k > declareOnly(X:Id, prototype(T:Type), external)
			=> .K
		...</ k >
		< preLinkage >... Tu:K |-> Map((Linkage:Map => Linkage:Map[external / X:Id])) ...</ preLinkage >
		< preTypes >... Tu:K |-> Map(Types:Map) ...</ preTypes >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if (notBool $hasMapping(Linkage:Map, X:Id) 
				orBool Linkage:Map(X:Id) ==Bool external
			)
			andBool isTypeCompatible(unqualifyType(Types:Map(X:Id)), unqualifyType(T:Type))
		[structural]
	
	// fixme haven't thought about this much, is it right?
	rule
		< k > declareOnly(X:Id, T:Type, internal)
			=> .K
		...</ k >
		< declarations >... .Set => SetItem(X:Id) ...</ declarations >
		< preLinkage >... Tu:K |-> Map((Linkage:Map => Linkage:Map[internal / X:Id])) ...</ preLinkage >
		< preTypes >... Tu:K |-> Map((Types:Map => Types:Map[T:Type / X:Id])) ...</ preTypes >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if notBool $hasMapping(Linkage:Map, X:Id) 
		orBool Linkage:Map(X:Id) ==Bool internal
		[structural] 
	rule
		< k > declareOnly(X:Id, T:Type, noLinkage)
			=> allocateType(Loc:Nat, T:Type)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
		...</ k >
		< nextLoc > Loc:Nat => inc(Loc:Nat) </ nextLoc >
		< localVariables > Vars:List (. => ListItem(X:Id)) </ localVariables >
		< localAddresses >... .Set => SetItem(Loc:Nat) ...</ localAddresses >
		if notBool hasIncompleteType(T:Type)
		andBool notBool hasStaticType(T:Type)
		andBool notBool hasExternType(T:Type)
		andBool notBool X:Id in Vars:List // this should be here statically, but not dynamically
		[structural]
	rule // same as above, but for the case where the variable has already been declared.  this is seen if we goto earlier in the same block
		< k > declareOnly(X:Id, T:Type, noLinkage)
			=> .K
		...</ k >
		< localVariables >... ListItem(X:Id) ...</ localVariables >
		if notBool hasIncompleteType(T:Type)
		andBool notBool hasStaticType(T:Type)
		andBool notBool hasExternType(T:Type)
		[structural] 
	
	// exception to multiple definitions for functions since we consider prototypes to be definitions to some extent
	rule
		< k > declareAndDefine(X:Id, T:Type, K:K, external)
			=> .K
		...</ k >
		< declarations >... .Set => SetItem(X:Id) ...</ declarations >
		< externalDefinitions > Def:Map => Def:Map (X:Id |-> declarationObject(unqualifyType(T:Type), Tu:K, K:K)) </ externalDefinitions >
		< preLinkage >... Tu:K |-> Map((Linkage:Map => Linkage:Map[external / X:Id])) ...</ preLinkage >
		< preTypes >... Tu:K |-> Map((Types:Map => Types:Map[T:Type / X:Id])) ...</ preTypes >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if (notBool $hasMapping(Def:Map, X:Id) orBool hasFunctionType(T:Type))
		andBool (notBool $hasMapping(Linkage:Map, X:Id) orBool Linkage:Map(X:Id) ==Bool external)
		[structural] 
		
	rule
		< k > declareAndDefine(X:Id, T:Type, K:K, internal)
			=> .K
		...</ k >
		< declarations >... .Set => SetItem(X:Id) ...</ declarations >
		< internalDefinitions >... Tu:K |-> Map((Def:Map => Def:Map[declarationObject(unqualifyType(T:Type), Tu:K, K:K) / X:Id])) ...</ internalDefinitions >
		< preLinkage >... Tu:K |-> Map((Linkage:Map => Linkage:Map[internal / X:Id])) ...</ preLinkage >
		< preTypes >... Tu:K |-> Map((Types:Map => Types:Map[T:Type / X:Id])) ...</ preTypes >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		if notBool $hasMapping(Def:Map, X:Id)
		andBool (notBool $hasMapping(Linkage:Map, X:Id) orBool Linkage:Map(X:Id) ==Bool internal)
		[structural] 
	op defineAndInit : Id Type K Nat -> K [strict(3)] 
	rule
		< k > declareAndDefine(X:Id, T:Type, K:K, noLinkage)
			=> defineAndInit(X:Id, T:Type, figureInitializer(X:Id, T:Type, K:K), Loc:Nat)
		...</ k >
		< nextLoc > Loc:Nat => inc(Loc:Nat) </ nextLoc >
		< localVariables > Vars:List (. => ListItem(X:Id)) </ localVariables >
		< localAddresses >... .Set => SetItem(Loc:Nat) ...</ localAddresses >
		if notBool X:Id in Vars:List // again, this should be needed statically, but not dynamically
		[structural] 
	rule // this happens when we jump before a variable declaration with an initialization in the same block
		< k > declareAndDefine(X:Id, T:Type, K:K, noLinkage)
			=> justInit(figureInitializer(X:Id, T:Type, K:K))
		...</ k >
		< localVariables >... ListItem(X:Id) ...</ localVariables >
		[structural] 
		
	op justInit : K -> K [strict(1)]
	
	rule
		< k > justInit(initializerValue(X:Id, T:Type, K:K)) => initialize(X:Id, T:Type, K:K) ...</ k >
		[structural]
		
	rule
		< k > defineAndInit(X:Id, ?, initializerValue(X:Id, T:Type, K:K), Loc:Nat)
			=> allocateTypeIfAbsent(Loc:Nat, T:Type)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
			~> initialize(X:Id, T:Type, K:K)
		...</ k >
		< shouldInit > true </ shouldInit >
		[structural] 
		
	rule
		< k > defineAndInit(X:Id, ?, initializerValue(X:Id, T:Type, ?), Loc:Nat)
			=> allocateTypeIfAbsent(Loc:Nat, T:Type)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
			// ~> initialize(X:Id, T:Type, K:K)
		...</ k >
		< shouldInit > false </ shouldInit >
		[structural]
		
	rule
		< k > figureInitializer-aux(?, (incompleteArrayType(T:Type) => arrayType(T:Type, N:Nat)), initializer(K:K))
		...</ k >
		< incompleteLength > N:Nat </ incompleteLength >
		[structural] 

	op allocateAndZeroIfAbsent : Type Id -> K 
	op addToLinkage : Id Type -> K 
	op addToGlobalEnv : K Nat -> K 
	op addToLocalEnv : K Nat -> K 
	
	rule
		< k > addToEnv(X:Id, Loc:Nat) => addToGlobalEnv(X:Id, Loc:Nat) ...</ k >
		< currentFunction > File-Scope </ currentFunction >
		[structural] 
	rule
		< k > addToEnv(X:Id, Loc:Nat) => addToLocalEnv(X:Id, Loc:Nat) ...</ k >
		< currentFunction > F:K </ currentFunction >
		if F:K =/=Bool File-Scope
		[structural] 
		
	rule
		< k > addToGlobalEnv(X:Id, Loc:Nat) => . ...</ k >
		< genv >... Tu:K |-> Map((M':Map => M':Map[Loc:Nat / X:Id])) ...</ genv >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		< env > E:Map => E:Map[Loc:Nat / X:Id] </ env >
		[structural] 
	rule
		< k > addToLocalEnv(X:Id, Loc:Nat) => . ...</ k >
		< env > E:Map => E:Map[Loc:Nat / X:Id] </ env >
		[structural] 
			
	rule
		< k > DeclarationDefinition(InitNameGroup(T:Type, Nil)) => .K ...</ k >
		[structural] 
	
	op defineUsingOldDeclaration : Type Id K -> K 
	
	// op defineFunctionUsingOldDeclaration : Type Id K -> K 
	// FIXME check prototypes
	rule [function-definition]:
		< k > FunctionDefinition(typedDeclaration(T:Type, X:Id), Block:K) 
			=> declareFunction(X:Id, T:Type, initializer(initFunction(X:Id, functionObject(X:Id, unqualifyType(T:Type), Block:K))))
			~> calculateGotoMap(X:Id, Block:K)
		...</ k >
		if hasFunctionType(T:Type)
		[structural] 
endkm

kmod COMMON-SEMANTICS-DECLARATIONS-INITIALIZATIONS is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
	
	op te : K Type -> K 
	op getInitializer : -> K 
	op fillInitializer : K -> K 
	op fillInitializer-aux : K -> K 
	op fillInitializer : List{C} -> K 
	op completeInitializerFragment : K K -> C 
	op initializerFragment : K -> KResult 
	
	rule
		< k > getInitializer => initializer(K:C) ...</ k >
		< savedInitialization > K:C => . </ savedInitialization > 
		< currentObject > ?:List => . </ currentObject > 
		< currentSubObject > ?:List => . </ currentSubObject > 
		[structural] 

	rule
		< k > startInitializer(T:Type, X:Id, CompoundInit(L:List{C}))
			=> fillInitializer(L:List{C}) ~> getInitializer
		...</ k >
		< incompleteLength > ? => 0 </ incompleteLength >
		< currentSubObject > . => ListItem(te(X:Id, T:Type)) </ currentSubObject >
		< currentObject > . => ListItem(te(X:Id, T:Type)) </ currentObject >
		< savedInitialization >... . => zero(X:Id) </ savedInitialization > 
		if hasUnionType(T:Type) orBool hasAggregateType(T:Type)
		[structural] 
	
	rule
		< k > fillInitializer(InitFragment(K:K, Exp:K) :: L:List{C})
		=> fillInitializer(InitFragment(K:K, Exp:K)) ~> fillInitializer(L:List{C})
		...</ k >
		[structural] 
	rule
		< k > fillInitializer(Nil) => . ...</ k >
		[structural] 
	
	op next : -> ListItem 
	op block : -> ListItem 
	
	rule
		< currentSubObject > 
			ListItem(te(K:K, arrayType(T:Type, Len:Nat)))
			=> ListItem(te(K:K[0], T:Type)) ListItem(te(K:K, arrayType(T:Type, Len:Nat)))
		...</ currentSubObject >
		[structural] 
	rule
		< currentSubObject > 
			ListItem(te(K:K, incompleteArrayType(T:Type)))
			=> ListItem(te(K:K[0], T:Type)) ListItem(te(K:K, incompleteArrayType(T:Type)))
		...</ currentSubObject >
		[structural] 
	rule
		< currentSubObject > 
			ListItem(te(K:K, structType(S:Id)))
			=> ListItem(te(K:K . F:Id, T:Type)) ListItem(te(K:K, structType(S:Id)))
		...</ currentSubObject >
		< structs >... 
			S:Id |-> aggregateInfo((typedDeclaration(T:Type, F:Id) :: ?), ?, ?)
		...</ structs > 
		[structural] 
		
	// fixme these are terrible!
	rule
		< currentSubObject > 
			ListItem(te(K:K, unionType(S:Id)))
			=> ListItem(te(K:K . F:Id, T:Type)) ListItem(te(K:K, unionType(S:Id)))
		...</ currentSubObject >
		< structs >... 
			S:Id |-> aggregateInfo((typedDeclaration(T:Type, F:Id) :: ?), ?, ?) 
		...</ structs > 
		[structural] 
		
	// fixme should i worry about basetype here?
	rule [init-next-array-element]:
		< currentSubObject > 
			(next ListItem(te(K:K[N:Nat], T:Type)) => ListItem(te(K:K[sNat(N:Nat)], T:Type)))
			ListItem(te(K:K, arrayType(?, Len:Nat)))
		...</ currentSubObject >
		if Len:Nat >Nat sNat(N:Nat)
		[structural] 
	rule [init-next-array-element-done]:
		< currentSubObject >
			next (ListItem(te(K:K[N:Nat], T:Type)) => .) ListItem(te(K:K, arrayType(?, Len:Nat)))
		...</ currentSubObject >
		if notBool Len:Nat >Nat sNat(N:Nat)
		[structural] 
	
	rule [init-next-incomplete-array-element]:
		< currentSubObject >
			(next ListItem(te(K:K[N:Nat], T:Type)) => ListItem(te(K:K[sNat(N:Nat)], T:Type))) 
			ListItem(te(K:K, incompleteArrayType(?)))
		...</ currentSubObject >
		//< incompleteLength > N':Nat => maxNat(sNat(N:Nat), N':Nat) </ incompleteLength >
		[structural] 
	
	rule [init-next-struct-element]:
		< currentSubObject >
			next ListItem(te(K:K . F:Id, T:Type)) ListItem(te(K:K, structType(S:Id)))
			=> ListItem(te(K:K . F':Id, T':Type)) ListItem(te(K:K, structType(S:Id)))
		...</ currentSubObject >
		< structs >...
			S:Id |-> aggregateInfo((? :: typedDeclaration(T:Type, F:Id) :: typedDeclaration(T':Type, F':Id) :: ?), ?, ?)
		...</ structs > 
		if F':Id =/=Bool #NoName
		[structural] 
	 
	rule [init-next-struct-element-noname]:
		< currentSubObject >
			next ListItem(te(K:K . F:Id, T:Type)) ListItem(te(K:K, structType(S:Id)))
			=> ListItem(te(K:K . F':Id, T':Type)) ListItem(te(K:K, structType(S:Id)))
		...</ currentSubObject >
		< structs >...
			S:Id |-> aggregateInfo((? :: typedDeclaration(T:Type, F:Id) :: typedDeclaration(?, #NoName) :: typedDeclaration(T':Type, F':Id) :: ?), ?, ?)
		...</ structs >
		[structural] 
		
	rule [init-next-struct-element-done]:
		< currentSubObject >
			next (ListItem(te(K:K . F:Id, T:Type)) => .) ListItem(te(K:K, structType(S:Id)))
		...</ currentSubObject >
		< structs >...
			S:Id |-> aggregateInfo((? :: typedDeclaration(T:Type, F:Id)), ?, ?)
		...</ structs > 
		[structural] 
	rule [init-next-struct-element-done-noname]:
		< currentSubObject >
			next (ListItem(te(K:K . F:Id, T:Type)) => .) ListItem(te(K:K, structType(S:Id)))
		...</ currentSubObject >
		< structs >...
			S:Id |-> aggregateInfo((? :: typedDeclaration(T:Type, F:Id) :: typedDeclaration(?, #NoName)), ?, ?)
		...</ structs > 
		[structural] 
		
	rule [init-next-union-element-done]:
		< currentSubObject >
			next (ListItem(te(K:K . ?, T:Type)) => .) ListItem(te(K:K, unionType(S:Id)))
		...</ currentSubObject >
		[structural] 
		
	rule
		< k > fillInitializer(InitFragment(NextInit, Exp:K)) => fillInitializer(Exp:K) ...</ k >
		[structural] 
		
	op finishCompoundInit : List -> K 
	rule
		< k > fillInitializer(CompoundInit(L:List{C})) 
			=> fillInitializer(L:List{C})
			// ~> debug
			~> finishCompoundInit(next ListItem(te(K:K, T:Type)) Remainder:ListItem)
		...</ k >
		< currentSubObject > (?:List => .) ListItem(te(K:K, T:Type)) (Remainder:ListItem => .) </ currentSubObject >
		< currentObject > (. => ListItem(te(K:K, T:Type))) ...</ currentObject >
		if hasAggregateType(T:Type) orBool hasUnionType(T:Type)
		[metadata "computational"] // fixme computational to make sure all the other equations have applied first
	rule
		< k > finishCompoundInit(L:List) => 
			. 
			// debug
		...</ k >
		< currentObject > (ListItem(te(K:K, T:Type)) => .) ...</ currentObject >
		< currentSubObject > (? => L:List) </ currentSubObject >
		[structural] 
			
	context fillInitializer(InitFragment(`[HOLE`]:K, ?)) 
	op buildDesignator : K -> K 
	
	// note that these clear the current subobject cell, because it will be repopulated when building the designator
	rule
		< k > fillInitializer(InitFragment(InFieldInit(F:Id, K':K), Exp:K))
			=> fillInitializer(InitFragment(buildDesignator(InFieldInit(F:Id, K':K)), Exp:K))
		...</ k >
		< currentObject > ListItem(te(K:K, T:Type)) ...</ currentObject >
		< currentSubObject > ?:List => block ListItem(te(K:K, T:Type)) </ currentSubObject >
		if hasStructType(T:Type) orBool hasUnionType(T:Type)
		[structural] 
	// fixme does this need to worry about incompleteLength?
	rule
		< k > fillInitializer(InitFragment(AtIndexInit(Index:K, K':K), Exp:K))
			=> fillInitializer(InitFragment(buildDesignator(AtIndexInit(Index:K, K':K)), Exp:K))
		...</ k >
		< currentObject > ListItem(te(K:K, T:Type)) ...</ currentObject >
		< currentSubObject > ?:List => block ListItem(te(K:K, T:Type)) </ currentSubObject >
		if hasArrayType(T:Type)
		[structural] 
		
	
	// fixme these are also too restrictive on type.  if we try to assign an int to a long-int field, it will fail
	// i don't think this is true anymore
	rule
		< k > buildDesignator(InFieldInit(F:Id, More:K)) 
			=> buildDesignator(More:K)
		...</ k >
		< currentSubObject > block (. => ListItem(te(K:K . F:Id, T:Type))) ListItem('te(K:K,, KL:KLabel(S:Id))) ...</ currentSubObject >
		< structs >... 
			// S:Id |-> ? :: typedDeclaration(T:Type, F:Id) :: ? 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), ?)
		...</ structs >
		if KL:KLabel ==Bool 'structType 
		orBool KL:KLabel ==Bool 'unionType
		[structural] 
		
	rule
		< k > buildDesignator(NextInit) => NextInit ...</ k >
		< currentSubObject > (block => .) ...</ currentSubObject >
		[structural] 
		
	rule innerType(arrayType(T:Type, ?)) => T:Type [structural]
	rule innerType(incompleteArrayType(T:Type)) => T:Type [structural]
	rule innerType(qualifiedType(T:Type, ?)) => innerType(T:Type) [structural]
	rule innerType(pointerType(T:Type)) => T:Type [structural]

	context buildDesignator(AtIndexInit(([HOLE] => reval([HOLE])), ?)) 
	rule
		< k > buildDesignator(AtIndexInit(tv(N:Nat, ?), More:K)) 
			=> buildDesignator(More:K)
		...</ k >
		< currentSubObject > block (. => ListItem(te(K:K[N:Nat], innerType(T:Type)))) ListItem(te(K:K, T:Type)) ...</ currentSubObject >
		if hasArrayType(T:Type)
		[structural] 
	
	op popInit : -> K
	
	op getTopArrayUse : K -> Nat 
	rule getTopArrayUse(X:Id) => 0 [structural]
	rule getTopArrayUse(X:Id[N:Nat]) => sNat(N:Nat) [structural] // +1 for length instead of index
	rule getTopArrayUse(K:K . F:Id) => getTopArrayUse(K:K) [structural]
	rule getTopArrayUse((K:K[N:Nat])[?]) => getTopArrayUse(K:K[N:Nat]) [structural]
	rule getTopArrayUse((K:K . F:Id)[?]) => getTopArrayUse(K:K) [structural]
	
	op initializeSingleInit : K -> K 
		
	rule
		< k > (. => typeof(K:K)) ~> initializeSingleInit(K:K) ...</ k >
		[structural] 
	
	// fixme want to exclude strings, but not normal arrays
	rule
		< k > T':Type ~> initializeSingleInit(K':K) => . ...</ k >
		< currentSubObject > (. => next) ListItem(te(K:K, T:Type)) ...</ currentSubObject >
		< incompleteLength > N:Nat => maxNat(N:Nat, getTopArrayUse(K:K)) </ incompleteLength >
		< savedInitialization >... . => Computation(K:K := K':K) </ savedInitialization > 
		if (isBasicType(T:Type) orBool hasPointerType(T:Type) orBool hasBitfieldType(T:Type))
		andBool notBool hasStructType(T':Type)
		andBool notBool hasUnionType(T':Type)
		[structural] 
		
	// this is used to have an aggregate on the RHS of a compound init
	// fixme want to exclude strings, but not normal arrays
	op initFromAggregateRHS : K Type -> K 
	rule
		< k > T:Type ~> initializeSingleInit(K:K) => initFromAggregateRHS(K:K, T:Type) ...</ k >
		// if hasAggregateType(T:Type) 		
		if hasStructType(T:Type)
		orBool hasUnionType(T:Type)
		[structural] 
		
	op initFromStructRHS : K Type -> K 
	rule
		< k > initFromAggregateRHS(K:K, structType(S:Id)) 
			=> initFromStructRHS(K:K, structType(S:Id)) 
		...</ k >
		< currentSubObject > . => findStruct(structType(S:Id)) ...</ currentSubObject >
		[structural] 
		
	op findStruct : Type -> ListItem 
		
	rule
		< currentSubObject > findStruct(T:Type) (ListItem(te(?, T':Type)) => .) ...</ currentSubObject >
		if T:Type =/=Bool T':Type
		[structural] 
		
	// fixme unsafe, might have started to initialize other things
	rule
		< k > initFromStructRHS(K':K, structType(S:Id))
			=> .K
		...</ k >
		< currentSubObject > findStruct(structType(S:Id)) ListItem(te(K:K, structType(S:Id))) => next ...</ currentSubObject >
		< incompleteLength > N:Nat => maxNat(N:Nat, getTopArrayUse(K:K)) </ incompleteLength >
		< savedInitialization >... . => Computation(K:K := K':K) </ savedInitialization > 
		[structural] 
	
	rule
		< k > fillInitializer(SingleInit(K:K)) => initializeSingleInit(K:K) ...</ k >
		if getKLabel(K:K) =/=Bool 'Constant
		[structural] 
	rule
		< k > fillInitializer(SingleInit(Constant(K:K))) => initializeSingleInit(Constant(K:K)) ...</ k >
		if getKLabel(K:K) =/=Bool 'StringLiteral
		andBool getKLabel(K:K) =/=Bool 'WStringLiteral
		[structural] 

	rule
		< k > fillInitializer(SingleInit(Constant(StringLiteral(S:String))))
			=> fillInitializer-aux(SingleInit(Constant(StringLiteral(S:String))))
		...</ k >
		< currentSubObject > ListItem(te(K:K, T:Type)) ListItem(te(?, arrayType(T:Type, Len:Nat))) ...</ currentSubObject >
		if hasCharType(T:Type)
		andBool lengthString(S:String) ==Bool Len:Nat
		[structural] 
	rule
		< k > fillInitializer(SingleInit(Constant(StringLiteral(S:String))))
			=> fillInitializer(SingleInit(Constant(StringLiteral(S:String +String "\0"))))
		...</ k >
		< currentSubObject > ListItem(te(K:K, T:Type)) ListItem(te(?, arrayType(T:Type, Len:Nat))) ...</ currentSubObject >
		if hasCharType(T:Type)
		andBool lengthString(S:String) <Int Len:Nat
		[structural] 
	rule
		< k > fillInitializer(SingleInit(Constant(StringLiteral(S:String))))
			=> fillInitializer-aux(SingleInit(Constant(StringLiteral(S:String +String "\0"))))
		...</ k >
		< currentSubObject > ListItem(te(K:K, T:Type)) ListItem(te(?, incompleteArrayType(T:Type))) ...</ currentSubObject >
		if hasCharType(T:Type)
		[structural] 
		
	rule
		< k > fillInitializer-aux(SingleInit(Constant(StringLiteral(S:String))))
			=> fillInitializer(SingleInit(tv(charToAscii(firstChar(S:String)), char))) 
			~> fillInitializer-aux(SingleInit(Constant(StringLiteral(butFirstChar(S:String))))) 
		...</ k >
		< currentSubObject > ListItem(te(K:K, T:Type)) ...</ currentSubObject >
		if S:String =/=Bool ""
		andBool hasCharType(T:Type)
		[structural] 
	// fixme not sure what happens in the case of   char *x = "";
	rule
		< k > fillInitializer-aux(SingleInit(Constant(StringLiteral("")))) => . ...</ k >
		// if hasCharType(T:Type)
		[structural] 
		
	// this rule assumes all unrollings have already occurred, so it needs to be a rule
	// alternatively, i've added the condition below which might be enough
	rule
		< k > fillInitializer(SingleInit(Constant(StringLiteral(S:String))))
			=> initializeSingleInit(Constant(StringLiteral(S:String)))
		...</ k >
		< currentSubObject > ListItem(te(K:K, T:Type)) ...</ currentSubObject >
		if notBool hasCharType(T:Type)
		andBool (isBasicType(T:Type) orBool hasPointerType(T:Type) orBool hasBitfieldType(T:Type))
		[structural] 
endkm


kmod COMMON-SEMANTICS-DECLARATIONS-RESOLUTION is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
	
	op canonicalizeTranslationUnitVariables : -> K 
	rule
		< k > TranslationUnit(Name:String, K:K, P:String) 
			=> klistToK(eraseKLabel('StmtCons, K:K))
		...</ k >
		< currentTranslationUnit > ? => Name:String </ currentTranslationUnit >
		< declarationOrder > DeclOrder:Map => DeclOrder:Map[ListToK(.List) / Name:String] </ declarationOrder >
		< internalLocations > ExtLoc:Map => ExtLoc:Map[Map(.) / Name:String] </ internalLocations >
		< functionTranslationUnits > Funs:Map => Funs:Map[Map(.) / Name:String] </ functionTranslationUnits > 
		< translationUnits >... . => BagItem(Name:String) ...</ translationUnits >
		< preLinkage > Linkage:Map => Linkage:Map[Map(.) / Name:String] </ preLinkage >
		< preTypes > Types:Map => Types:Map[Map(.) / Name:String] </ preTypes >
		< internalDefinitions > Def:Map => Def:Map[Map(.) / Name:String] </ internalDefinitions >
		< genv > Env:Map => Env:Map[Map(.) / Name:String] </ genv >
		< gtypes > Gtypes:Map => Gtypes:Map[Map(.) / Name:String]</ gtypes >
		< programText > M:Map => M:Map[P:String / Name:String] </ programText >
		if notBool $hasMapping(Env:Map, Name:String)
		[structural] 
	
	op resolve : K -> K 
	rule
		< k > (. => resolve(Tu:K)) ~> resolveReferences ...</ k >
		< translationUnits >... BagItem(Tu:K) => .Bag ...</ translationUnits >
		[structural] 
		
	/* this is what I want, but it doesn't compile
	rule
		< k > resolveReferences => .K ...</ k >
		(< staticSemantics >...
			< translationUnits > .Bag </ translationUnits >
		...</ staticSemantics >) => .Bag
		[structural]
	*/
	rule
		< k > resolveReferences => .K ...</ k >
		// < staticSemantics >...
			< translationUnits > .Bag </ translationUnits >
		// ...</ staticSemantics >
		[structural] 
		
	op resolveInternal : Id K K -> K 
	op resolveExternal : Id K Bag K -> K 
	op resolveExternal-aux : Id K Bag K Nat K -> K [strict(6)] 
	
	op recordFunctionTranslationUnitInformation : K Type K K -> K // name, type, context, where defined
	rule
		< k > recordFunctionTranslationUnitInformation(X:Id, T:Type, Tu:K, DefTu:K) => . ...</ k >
		< functionTranslationUnits >... Tu:K |-> Map((Funs:Map => Funs:Map[DefTu:K / X:Id])) ...</ functionTranslationUnits >
		if hasFunctionType(T:Type)
		[structural] 
	rule
		< k > recordFunctionTranslationUnitInformation(?, T:Type, ?, ?) => . ...</ k >
		if notBool hasFunctionType(T:Type)
		[structural] 
	
	// fixme
	// should be adding to env after figuring initializer
	// should be changing env to be correct env before figuring initializer
	op allocateWithInit : K Nat -> K [strict] 
	op noAllocateWithInit : K Nat -> K [strict] 
	op resolveInternal-aux : Id K K K -> K [strict(4)] 
	rule
		< k > resolveInternal(X:Id, Tu:K, declarationObject(T:Type, Tu:K, K:K))
			=> resolveInternal-aux(X:Id, Tu:K, declarationObject(T:Type, Tu:K, K:K), figureInitializer(X:Id, T:Type, K:K))
		...</ k >
		< currentTranslationUnit > ? => Tu:K </ currentTranslationUnit >
		[structural] 
	rule
		< k > resolveInternal-aux(X:Id, Tu:K, declarationObject(?, Tu:K, ?), initializerValue(X:Id, T:Type, K:K))
			=> allocateType(Loc:Nat, T:Type)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
			~> initialize(X:Id, T:Type, K:K)
			~> recordFunctionTranslationUnitInformation(X:Id, T:Type, Tu:K, Tu:K)
		...</ k >
		< nextSharedLoc > Loc:Nat => inc(Loc:Nat) </ nextSharedLoc >
		< currentTranslationUnit > ? => Tu:K </ currentTranslationUnit >
		[structural] 
			
	rule
		< k > resolveExternal(X:Id, Tu:K, Units:Bag, declarationObject(T:Type, DefTu:K, K:K))
			=> resolveExternal-aux(X:Id, Tu:K, Units:Bag, declarationObject(T:Type, DefTu:K, K:K), Loc:Nat, figureInitializer(X:Id, T:Type, K:K))
		...</ k >
		< nextSharedLoc > Loc:Nat => inc(Loc:Nat) </ nextSharedLoc >
		[structural] 
	rule
		< k > ( .K
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
			~> recordFunctionTranslationUnitInformation(X:Id, T:Type, Tu':K, DefTu:K)
			) ~> resolveExternal-aux(X:Id, Tu:K, ((BagItem(Tu':K) => .) Units:Bag), declarationObject(?, DefTu:K, ?), Loc:Nat, initializerValue(X:Id, T:Type, K:K))
		...</ k >
		< currentTranslationUnit > ? => Tu':K </ currentTranslationUnit >
		< preLinkage >... Tu':K |-> Map((? (X:Id |-> external => .))) ...</ preLinkage >
		[structural] 
	rule
		< k > resolveExternal-aux(X:Id, Tu:K, .Bag, declarationObject(?, DefTu:K, ?), Loc:Nat, initializerValue(X:Id, T:Type, K:K))
			=> allocateType(Loc:Nat, T:Type)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:Type)
			~> initialize(X:Id, T:Type, K:K)
			~> recordFunctionTranslationUnitInformation(X:Id, T:Type, Tu:K, DefTu:K)
		...</ k >
		< currentTranslationUnit > ? => Tu:K </ currentTranslationUnit >
		< externalLocations > Locs:Map => Locs:Map[Loc:Nat / X:Id] </ externalLocations >
		if notBool $hasMapping(Locs:Map, X:Id)
		[structural] 
	rule
		< k > resolveExternal-aux(X:Id, ?, ((BagItem(Tu:K) => .) Units:Bag), ?, ?, ?) ...</ k >
		< preLinkage >... Tu:K |-> Map(M:Map) ...</ preLinkage >
		if notBool $hasMapping(M:Map, X:Id)
		[structural] 
	rule
		< k > resolveExternal-aux(X:Id, ?, ((BagItem(Tu:K) => .) Units:Bag), ?, ?, ?) ...</ k >
		< preLinkage >... Tu:K |-> Map((? X:Id |-> internal)) ...</ preLinkage >
		[structural] 
	
	// 
	rule
		< k > (. => resolveInternal(X:Id, Tu:K, K:K)) ~> resolve(Tu:K) ...</ k >
		< preLinkage >... Tu:K |-> Map((? (X:Id |-> internal => .))) ...</ preLinkage >
		< internalDefinitions >... Tu:K |-> Map((? (X:Id |-> K:K => .))) ...</ internalDefinitions >
		< declarationOrder >... Tu:K |-> ListToK((ListItem(X:Id) => .) ?) ...</ declarationOrder >
		[structural] 
		
	// static variable without an initializer
	rule
		< k > (. => resolveInternal(X:Id, Tu:K, declarationObject(unqualifyType(T:Type), Tu:K, initializer(zero(X:Id))))) ~> resolve(Tu:K) ...</ k >
		< preLinkage >... Tu:K |-> Map((? (X:Id |-> internal => .))) ...</ preLinkage >
		< internalDefinitions >... Tu:K |-> Map(Defs:Map) ...</ internalDefinitions >
		< declarationOrder >... Tu:K |-> ListToK((ListItem(X:Id) => .) ?) ...</ declarationOrder >
		< preTypes >... Tu:K |-> Map((? (X:Id |-> T:Type => .))) ...</ preTypes >
		if notBool $hasMapping(Defs:Map, X:Id)
		[structural] 
		
	rule
		< k > (. => resolveExternal(X:Id, Tu:K, Units:Bag, K:K)) ~> resolve(Tu:K) ...</ k >
		< preLinkage >... Tu:K |-> Map((? (X:Id |-> external => .))) ...</ preLinkage >
		< externalDefinitions > ExtDefs:Map (X:Id |-> K:K => .) </ externalDefinitions >
		< declarationOrder >... Tu:K |-> ListToK((ListItem(X:Id) => .) ?) ...</ declarationOrder >
		< translationUnits > Units:Bag </ translationUnits >
		if notBool $hasMapping(ExtDefs:Map, X:Id)
		[structural] 

	rule toString(Identifier(S:String)) => S:String [structural]
	rule toString(S:String) => S:String [structural]
	rule toString(Num:Nat) => Int2String(Num:Nat) [structural]
	rule Rat2String(sym(N:Nat), M:NzNat) => "sym(" +String Rat2String(N:Nat, M:NzNat) +String ")" [structural]
	
	// fixme this means we've declared it twice (like a prototype maybe?), but already handled it.  happening with getc in clib.c
	rule
		< k > resolve(Tu:K) ...</ k >
		< preLinkage >... Tu:K |-> Map(Linkage:Map) ...</ preLinkage >
		< declarationOrder >... Tu:K |-> ListToK((ListItem(X:Id) => .) ?) ...</ declarationOrder >
		< externalDefinitions > ExtDefs:Map </ externalDefinitions >
		< internalDefinitions > IntDefs:Map </ internalDefinitions >
		if notBool $hasMapping(Linkage:Map, X:Id)
		andBool notBool $hasMapping(ExtDefs:Map, X:Id)
		andBool notBool $hasMapping(IntDefs:Map, X:Id)
		[structural] 
	
	// function prototypes
	rule
		< k > (.K => 
				giveType(X:Id, T:Type)
				~> recordFunctionTranslationUnitInformation(X:Id, T:Type, Tu:K, Tu:K)  // fixme fake Tu
			)
			~> resolve(Tu:K) 
		...</ k >
		< currentTranslationUnit > ? => Tu:K </ currentTranslationUnit >
		< preLinkage >... Tu:K |-> Map((? (X:Id |-> external => .))) ...</ preLinkage >
		< preTypes >... Tu:K |-> Map((? X:Id |-> prototype(T:Type))) ...</ preTypes >
		< declarationOrder >... Tu:K |-> ListToK((ListItem(X:Id) => .) ?) ...</ declarationOrder >
		< externalDefinitions > Defs:Map </ externalDefinitions >
		if hasFunctionType(T:Type)
		andBool notBool $hasMapping(Defs:Map, X:Id)
		[structural] 
		
	// c1x 6.9.2:2 A declaration of an identifier for an object that has file scope without an initializer, and without a storage-class specifier or with the storage-class specifier static, constitutes a tentative definition. If a translation unit contains one or more tentative definitions for an identifier, and the translation unit contains no external definition for that identifier, then the behavior is exactly as if the translation unit contains a file scope declaration of that identifier, with the composite type as of the end of the translation unit, with an initializer equal to 0
	rule
		< k > (. 
			=> allocateType(Loc:Nat, unqualifyType(T:Type))
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:Type))
			~> zero(X:Id)
			) ~> resolve(Tu:K)
		...</ k >
		< preLinkage >... Tu:K |-> Map((? (X:Id |-> external => .))) ...</ preLinkage >
		< preTypes >... Tu:K |-> Map((? X:Id |-> T:Type)) ...</ preTypes >
		< declarationOrder >... Tu:K |-> ListToK((ListItem(X:Id) => .) ?) ...</ declarationOrder >
		< externalDefinitions > Defs:Map </ externalDefinitions >
		< currentTranslationUnit > ? => Tu:K </ currentTranslationUnit >
		< nextSharedLoc > Loc:Nat => inc(Loc:Nat) </ nextSharedLoc >
		< externalLocations > Locs:Map => Locs:Map[Loc:Nat / X:Id] </ externalLocations >
		if notBool $hasMapping(Locs:Map, X:Id)
		andBool notBool hasFunctionType(T:Type)
		andBool notBool hasIncompleteType(T:Type)
		andBool notBool hasExternType(T:Type)
		andBool notBool $hasMapping(Defs:Map, X:Id)
		[structural] 
	rule
		< k > resolve(Tu:K) ...</ k >
		< preLinkage >... Tu:K |-> Map((? (X:Id |-> external => .))) ...</ preLinkage >
		< preTypes >... Tu:K |-> Map((? X:Id |-> T:Type)) ...</ preTypes >
		< declarationOrder >... Tu:K |-> ListToK((ListItem(X:Id) => .) ?) ...</ declarationOrder >
		< externalDefinitions > Defs:Map </ externalDefinitions >
		if notBool hasFunctionType(T:Type)
		andBool hasExternType(T:Type)
		andBool notBool $hasMapping(Defs:Map, X:Id)
		[structural] 
		
	rule
		< k > resolve(Tu:K) => . ...</ k >
		< preLinkage >... Tu:K |-> Map(.) ...</ preLinkage >
		< internalDefinitions >... Tu:K |-> Map(.) ...</ internalDefinitions >
		< declarationOrder >... Tu:K |-> ListToK(.List) ...</ declarationOrder >
		[structural] 
				
	// need to worry about things that don't have definitions that may override externs
	// want to make it so env is always correct local env, so need to have a set of global envs, one for each tu
	
	
	
	
	rule [initialize-function]:
		< k > initFunction(tv(Loc:Nat, T:Type), Fun:Value) => .K ...</ k >
		< functions > M:Map => M:Map[Fun:Value / Loc:Nat] </ functions >
		if hasFunctionType(T:Type)
		andBool notBool $hasMapping(M:Map, Loc:Nat)
		[structural]
		
	rule
		< k > readFunction(Loc:Nat) => Fun:Value  ...</ k >
		< functions >... Loc:Nat |-> Fun:Value ...</ functions >
		[structural]
		
	// rule
		// < k > write(Loc:Nat, tv(V:K, T:Type)) 
			// => writeByte(Loc:Nat, V:K)
		// ...</ k >
		// if hasFunctionType(T:Type)
		// [structural]
	
	
endkm

kmod COMMON-SEMANTICS-DECLARATIONS-ENUMS is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
	
	op fillEnums : K -> K 
	op fillEnums-aux : K K -> K 
	rule
		< k > EnumDef(X:Id, L:List{C}) => fillEnums(EnumDef(X:Id, L:List{C})) ...</ k >
		[structural] 
	rule 
		< k > fillEnums(K:K) => fillEnums-aux(K:K, 0) ...</ k > 
		[structural]
	rule
		< k > fillEnums-aux(EnumDef(X:Id, EnumItem(E:Id) :: L:List{C}), K:K) 
			=> declare(typedDeclaration(int, E:Id), SingleInit(K:K))
			~> fillEnums-aux(EnumDef(X:Id, L:List{C}), K:K + tv(1, int))
		...</ k >
		[structural] 
	rule
		< k > fillEnums-aux(EnumDef(X:Id, EnumItemInit(E:Id, Exp:K) :: L:List{C}), ?)
			=> declare(typedDeclaration(int, E:Id), SingleInit(Exp:K))
			~> fillEnums-aux(EnumDef(X:Id, L:List{C}), Exp:K + 1)
		...</ k >
		if Exp:K =/=Bool NothingExpression
		[structural] 
	rule
		< k > fillEnums-aux(EnumDef(X:Id, Nil), ?) => .K ...</ k > 
		[structural] 
endkm

kmod COMMON-C-DECLARATIONS is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
	
	including COMMON-SEMANTICS-DECLARATIONS-BINDING 
	including COMMON-SEMANTICS-DECLARATIONS-GENERAL 
	including COMMON-SEMANTICS-DECLARATIONS-INITIALIZATIONS 
	including COMMON-SEMANTICS-DECLARATIONS-ENUMS 
	including COMMON-SEMANTICS-DECLARATIONS-RESOLUTION 
endkm

kmod COMMON-SEMANTICS-TYPE-INCLUDE is
	including COMMON-INCLUDE 
	
	//op addAggregate : Id List{Type} -> K 
	op addStruct : Id List{Type} -> K 
	op addUnion : Id List{Type} -> K 
	op canonicalizeType : Bag -> K 
	op isAType_ : K -> Bool 
	op extractActualType : Type -> Type // rules that use specifier should be careful to use extractActualType if going to be used in a typed name
	op evalToType : -> K 
	
	op typeStrictUnaryOperators : -> Set [memo] 
	rule typeStrictUnaryOperators => Set(
		l('-_),, l('+_),, l('*_),, l('&_),, l('~_)
	)
	[structural]
	
	op typeStrictBinaryOperators : -> Set [memo] 
	rule typeStrictBinaryOperators => Set(
		l('_*_),, l('_/_),, l('_%_),,
		l('_+_),, l('_-_),,
		l('_<_),, l('_>_),, l('_<=_),, l('_>=_),,
		l('_&_),, l('_|_),, l('_^_),,
		l('_`[_`])
	)
	[structural]
	
	op typeStrictLeftBinaryOperators : -> Set [memo] 
	rule typeStrictLeftBinaryOperators => Set(
		l('_<<_),, l('_>>_),,
		l('_*=_),, l('_/=_),, l('_%=_),, l('_+=_),, l('_-=_),, 
		l('_<<=_),, l('_>>=_),, l('_&=_),, l('_^=_),, l('_|=_),,
		l('_++),, l('_--),, l('--_),, l('++_)
	) 
	[structural]
endkm

kmod COMMON-SEMANTICS-TYPE-DECLARATIONS is
	including COMMON-SEMANTICS-TYPE-INCLUDE 

	op giveGlobalType : K Type -> K 
	op giveLocalType : K Type -> K 
	
	// FIXME these are here until I decide how to handle qualified types
	rule qualifiedType(T:Type, Volatile) => T:Type [structural]
	rule qualifiedType(T:Type, Restrict) => T:Type [structural]
	rule qualifiedType(T:Type, Const) => T:Type [structural]
	rule qualifiedType(T:Type, Auto) => T:Type [structural]
	rule qualifiedType(T:Type, Register) => T:Type [structural]
	
	
	rule
		< k > giveType(X:Id, T:Type) => 
			if (Fun:Id ==Bool File-Scope) then giveGlobalType(X:Id, T:Type) else giveLocalType(X:Id, T:Type) fi
			...</ k >
		< currentFunction > Fun:Id </ currentFunction >
		if notBool hasStaticType(T:Type)
		[structural] 
		
	rule
		< k > giveGlobalType(X:Id, T:Type) => .K ...</ k >
		< types > M:Map => M:Map[T:Type / X:Id] </ types >
		< gtypes >... Tu:K |-> Map((M':Map => M':Map[T:Type / X:Id])) ...</ gtypes >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		[structural] 
	rule
		< k > giveLocalType(X:Id, T:Type) => .K ...</ k >
		< types > M:Map => M:Map[T:Type / X:Id] </ types >
		[structural]	
endkm

kmod COMMON-SEMANTICS-TYPE-STRICTNESS is
	including COMMON-SEMANTICS-TYPE-INCLUDE

	op waitingOnDeclType : -> K 
	rule [type-Cast-heat]:
		< k > (. => DeclType(Specifier:K, DeclType:K)) ~> evalToType ...</ k >
		< type > Cast(Specifier:K, DeclType:K, ?) => waitingOnDeclType ...</ type >
		[structural] 
		
	rule [type-Cast-cool]:
		< k > (T:Type => .) ~> evalToType ...</ k >
		< type > waitingOnDeclType => T:Type ...</ type >
		[structural] 
	
	rule [type-arrow-heat]:
		< type > K:K -> F:Id => K:K ~> HOLE -> F:Id ...</ type >
		if notBool isAType(K:K)
		[structural] 
	rule [type-arrow-cool]:
		< type > T:Type ~> HOLE -> F:Id => T:Type -> F:Id ...</ type >
		[structural] 
		
	rule [type-ternary-heat-left]:
		< type > K1:K ? K2:K : K3:K => K2:K ~> K1:K ? HOLE : K3:K ...</ type >
		if notBool isAType(K2:K)
		[structural] 
	rule [type-ternary-cool-left]:
		< type > T:Type ~> K1:K ? HOLE : K3:K => K1:K ? T:Type : K3:K ...</ type >
		if isAType(T:Type)
		[structural] 
	rule [type-ternary-heat-right]:
		< type > K1:K ? K2:K : K3:K => K3:K ~> K1:K ? K2:K : HOLE ...</ type >
		if notBool isAType(K3:K)
		[structural] 
	rule [type-ternary-cool-right]:
		< type > T:Type ~> K1:K ? K2:K : HOLE => K1:K ? K2:K : T:Type ...</ type >
		if isAType(T:Type)
		[structural] 
		
	rule [type-bin-arith-heat-left]:
		< type > L:KLabel(K:K,, K':K) => K:K ~> L:KLabel(HOLE,, K':K) ...</ type >
		if notBool isAType(K:K)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-arith-cool-left]:
		< type > T:Type ~> L:KLabel(HOLE,, K:K) => L:KLabel(T:Type,, K:K) ...</ type >
		if isAType(T:Type)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-arith-heat-right]:
		< type > L:KLabel(K:K,, K':K) => K':K ~> L:KLabel(K:K,, HOLE) ...</ type >
		if notBool isAType(K':K)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-arith-cool-right]:
		< type > T:Type ~> L:KLabel(K:K,, HOLE) => L:KLabel(K:K,, T:Type) ...</ type >
		if isAType(T:Type)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
		
	rule [type-unary-arith-heat]:
		< type > L:KLabel(K:K) => K:K ~> L:KLabel(HOLE) ...</ type >
		if notBool isAType(K:K)
		andBool typeStrictUnaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-unary-arith-cool]:
		< type > T:Type ~> L:KLabel(HOLE) => L:KLabel(T:Type) ...</ type >
		if isAType(T:Type)
		andBool typeStrictUnaryOperators contains l(L:KLabel)
		[structural] 
		
	rule [type-bin-left-arith-heat]:
		< type > L:KLabel(K:K,, Args:List{K}) => K:K ~> L:KLabel(HOLE,, Args:List{K}) ...</ type >
		if notBool isAType(K:K)
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-left-arith-cool]:
		< type > T:Type ~> L:KLabel(HOLE,, Args:List{K}) => L:KLabel(T:Type,, Args:List{K}) ...</ type >
		if isAType(T:Type)
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural] 

		
	rule [type-dot-heat]:
		< type > K:K . X:Id => K:K ~> HOLE . X:Id ...</ type >
		if notBool isAType(K:K)
		[structural] 
	rule [type-dot-cool]:
		< type > T:Type ~> HOLE . X:Id => T:Type . X:Id ...</ type >
		if isAType(T:Type)
		[structural]
		
	rule [type-call-heat]:
		< type > Call(K:K, L:List{C}) => K:K ~> Call(HOLE, L:List{C}) ...</ type >
		if notBool isAType(K:K)
		[structural] 
	rule [type-call-cool]:
		< type > T:Type ~> Call(HOLE, L:List{C}) => Call(T:Type, L:List{C}) ...</ type >
		if isAType(T:Type)
		[structural] 
	// mb context Call(?:K,, (?,, `[HOLE`]:K,, ?)) 
endkm

kmod COMMON-SEMANTICS-TYPE-CANONICALIZATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	
	op canonicalizeType : Bag K Bag Bag Bag -> K [strict(2)] 
		
	rule
		< k > canonicalizeType(B:Bag) => canonicalizeType(B:Bag, .K, .Bag, .Bag, .Bag) ...</ k >
		[structural] 
		
	// specifier, modifier, storage
	rule
		< k > canonicalizeType((B:Bag (BagItem(T:K) => .Bag)), ?, (? (.Bag => BagItem(T:K))), ?, ?) ...</ k >
		if false
		orBool (T:K ==Bool Void)
		orBool (T:K ==Bool Bool)
		orBool (T:K ==Bool Char)
		orBool (T:K ==Bool Short)
		orBool (T:K ==Bool Int)
		orBool (T:K ==Bool Long)
		orBool (T:K ==Bool Float)
		orBool (T:K ==Bool Double)
		orBool (T:K ==Bool Signed)
		orBool (T:K ==Bool Unsigned)
		orBool (getKLabel(T:K) ==Bool 'StructDef)
		orBool (getKLabel(T:K) ==Bool 'UnionDef)
		orBool (getKLabel(T:K) ==Bool 'EnumDef)
		orBool (getKLabel(T:K) ==Bool 'StructRef)
		orBool (getKLabel(T:K) ==Bool 'UnionRef)
		orBool (getKLabel(T:K) ==Bool 'EnumRef)
		orBool (getKLabel(T:K) ==Bool 'Named)
		orBool (getKLabel(T:K) ==Bool 'AttributeValue)
		[structural] 
	rule
		< k > canonicalizeType(B:Bag (BagItem(T:K) => .Bag), ?, ?, (? .Bag => BagItem(T:K)), ?) ...</ k >
		if (T:K ==Bool SpecTypedef)
		orBool (T:K ==Bool Inline)
		[structural] 

	rule
		< k > canonicalizeType(B:Bag (BagItem(T:K) => .Bag), ?, ?, ?, (? .Bag => BagItem(T:K))) ...</ k >
		if T:K ==Bool Extern
		orBool T:K ==Bool Static
		orBool T:K ==Bool Const
		orBool T:K ==Bool Volatile
		orBool T:K ==Bool Restrict
		orBool T:K ==Bool Auto
		orBool T:K ==Bool Register
		[structural] 
		
	rule
		< k > canonicalizeType(.Bag, (T:Type => qualifiedType(T:Type, Q:K)), .Bag, .Bag, (? BagItem(Q:K) => .Bag)) ...</ k >
		if Q:K ==Bool Extern
		orBool Q:K ==Bool Static
		orBool Q:K ==Bool Const
		orBool Q:K ==Bool Volatile
		orBool Q:K ==Bool Restrict
		orBool Q:K ==Bool Auto
		orBool Q:K ==Bool Register
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(Named(X:Id)))
			=> typedefType(X:Id, T:Type)
		...</ k >
		< types >... typedef(X:Id) |-> T:Type ...</ types >
		if X:Id =/=Bool Identifier("")
		[structural] 
		
	rule
		< k > canonicalizeSpecifier(BagItem(StructRef(X:Id)))
			=> structType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(EnumRef(X:Id)))
			=> enumType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(UnionRef(X:Id)))
			=> unionType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
		
	rule
		< k > canonicalizeSpecifier(BagItem(EnumDef(X:Id, L:List{C})))
			=> EnumDef(X:Id, L:List{C})
			~> enumType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(L:KLabel(((Identifier("") => unnamed(N:Nat)),, L:List{C})))) ...</ k >
		< freshNat > N:Nat => sNat(N:Nat) </ freshNat >
		if L:KLabel ==Bool 'StructDef
		orBool L:KLabel ==Bool 'EnumDef
		orBool L:KLabel ==Bool 'UnionDef
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(StructDef(X:Id, L:List{C})))
			=> StructDef(X:Id, L:List{C})
			~> structType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(UnionDef(X:Id, L:List{C})))
			=> UnionDef(X:Id, L:List{C})
			~> unionType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
		
		
	// FIXME what good is this?
	rule BagItem(SpecTypedef) => .Bag [structural]
	// fixme ignoring inlines since they shouldn't change the semantics?
	rule BagItem(Inline) => .Bag [structural]
	// fixme should save these for later use
	rule BagItem(AttributeValue(?, ?)) => .Bag [structural]

	rule 
		< k > canonicalizeType(.Bag, (.K => canonicalizeSpecifier(B:Bag)), (B:Bag => .Bag), ?, ?) ...</ k >
		if B:Bag =/=Bool .Bag
		[structural] 
	// fixme not sure where this is specified, but if i say "static x;" i think it means int
	rule 
		< k > canonicalizeType(.Bag, (.K => canonicalizeSpecifier(BagItem(Int))), .Bag, ?, ?) ...</ k >
		[structural] 
		
	rule
		< k > canonicalizeType(.Bag, T:Type, .Bag, .Bag, .Bag) => T:Type ...</ k >
		[structural] 
		
	op canonicalizeSpecifier : Bag -> K 
	// C99 6.7.2:2
	rule canonicalizeSpecifier(BagItem(Void)) => void [structural]
	rule canonicalizeSpecifier(BagItem(Bool)) => bool [structural]
	rule canonicalizeSpecifier(BagItem(Char)) => char [structural]
	rule canonicalizeSpecifier(BagItem(Signed) BagItem(Char)) => signed-char [structural]
	rule canonicalizeSpecifier(BagItem(Unsigned) BagItem(Char)) => unsigned-char [structural]
	
	rule canonicalizeSpecifier(BagItem(Double)) => double [structural]
	rule canonicalizeSpecifier(BagItem(Float)) => float [structural]
	rule canonicalizeSpecifier(BagItem(Long) BagItem(Double)) => long-double [structural]
	
	rule canonicalizeSpecifier(B:Bag) => short-int
		if B:Bag ==Bool BagItem(Short)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Short)
		orBool B:Bag ==Bool BagItem(Short) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Short) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => unsigned-short-int
		if B:Bag ==Bool BagItem(Unsigned) BagItem(Short)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Short) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => int
		if B:Bag ==Bool BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => unsigned-int
		if B:Bag ==Bool BagItem(Unsigned)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => long-int
		if B:Bag ==Bool BagItem(Long)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => unsigned-long-int
		if B:Bag ==Bool BagItem(Unsigned) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => long-long-int
		if B:Bag ==Bool BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Long) BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => unsigned-long-long-int
		if B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
endkm

kmod COMMON-SEMANTICS-TYPE-INTERPRETATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 

	op structDefType : Id List{Type} -> Type 
	
	op BitFieldType : K K -> K [seqstrict] 
	
	rule
		< k > Specifier(L:List{Type}) => canonicalizeType(Bag(getList{K}(L:List{Type}))) ...</ k >
		[structural] 
	rule
		< k > StructRef(X:Id) => structType(X:Id) ...</ k >
		[structural] 
		
	rule BitFieldType(T:Type, tv(N:Nat, ?)) => bitfieldType(T:Type, N:Nat) [structural]
	
	op makeArrayType : Nat -> KLabel 
	op makeFunctionType : List{Type} -> KLabel 
	op pushTypeDown : Type KLabel -> Type 
	
	rule ArrayType(T:Type, tv(N:Nat, ?)) => pushTypeDown(T:Type, makeArrayType(N:Nat)) [structural]
	rule ArrayType(T:Type, emptyValue) => pushTypeDown(T:Type, 'incompleteArrayType) [structural]
	rule PointerType(T:Type) => pushTypeDown(T:Type, 'pointerType) [structural]
	// fixme I'm assuming functiontype is always below a prototype in the ast
	rule FunctionType(T:Type) => T:Type [structural]
	rule Prototype(T:Type, L:List{Type}, false) => pushTypeDown(T:Type, makeFunctionType(L:List{Type})) [structural]
	rule Prototype(T:Type, L:List{Type}, true) => pushTypeDown(T:Type, makeFunctionType((L:List{Type} :: variadic))) [structural]
	
	rule pushTypeDown(arrayType(T:Type, N:Nat), K:KLabel) => arrayType(pushTypeDown(T:Type, K:KLabel), N:Nat) [structural]
	rule pushTypeDown(incompleteArrayType(T:Type), K:KLabel) => incompleteArrayType(pushTypeDown(T:Type, K:KLabel)) [structural]
	rule pushTypeDown(pointerType(T:Type), K:KLabel) => pointerType(pushTypeDown(T:Type, K:KLabel)) [structural]
	rule pushTypeDown(qualifiedType(T:Type, K:K), K:KLabel) => qualifiedType(pushTypeDown(T:Type, K:KLabel), K:K) [structural]
	rule pushTypeDown(functionType(T:Type, L:List{Type}), K:KLabel) => functionType(pushTypeDown(T:Type, K:KLabel), L:List{Type}) [structural]
	rule pushTypeDown(flexibleArrayType(T:Type), K:KLabel) => flexibleArrayType(pushTypeDown(T:Type, K:KLabel)) [structural]
	rule pushTypeDown(structType(X:Id), K:KLabel) => K:KLabel(structType(X:Id)) [structural]
	rule pushTypeDown(unionType(X:Id), K:KLabel) => K:KLabel(unionType(X:Id)) [structural]
	rule pushTypeDown(enumType(X:Id), K:KLabel) => K:KLabel(enumType(X:Id)) [structural]
	
	rule pushTypeDown(typedefType(X:Id, T:Type), K:KLabel) => K:KLabel(T:Type) [structural]
	
	rule pushTypeDown(T:Type, K:KLabel) => K:KLabel(T:Type) 
		if isBasicType(T:Type)
		[structural]
	
	rule makeArrayType(N:Nat)(T:Type) => arrayType(T:Type, N:Nat) [structural]
	rule makeFunctionType(L:List{Type})(T:Type) => functionType(T:Type, L:List{Type}) [structural]
			
	
	rule 
		< k > JustBase => T:Type ...</ k >
		< declarationTypeHolder > T:Type => . ...</ declarationTypeHolder >
		[structural] 

	op extractActualTypeFreezer : -> K 
	rule
		< k > DeclType(T:Type, K:K) => K:K ~> extractActualTypeFreezer ...</ k >
		< declarationTypeHolder > (. => T:Type) ...</ declarationTypeHolder >
		[structural] 
	
	rule
		< k > T:Type ~> extractActualTypeFreezer 
			=> extractActualType(T:Type)
		...</ k >
		[structural] 
		
	op fillBitHoles : List{Type} -> List{Type} 
	op fillBitHoles : Nat List{Type} -> List{Type} 
	rule fillBitHoles(Nil) => Nil [structural]
	// if we haven't seen bitfields
	rule fillBitHoles((typedDeclaration(T:Type, X:Id) :: L:List{Type})) 
		=> typedDeclaration(T:Type, X:Id) :: fillBitHoles(L:List{Type})
		if notBool hasBitfieldType(T:Type) 
		[structural]
	
	rule fillBitHoles((typedDeclaration(T:Type, X:Id) :: L:List{Type})) 
		=> fillBitHoles(0, typedDeclaration(T:Type, X:Id) :: L:List{Type})
		if hasBitfieldType(T:Type) 
		[structural]
	
	// if we have seen bitfields
	rule fillBitHoles(N:Nat, (typedDeclaration(T:Type, X:Id) :: L:List{Type})) 
		=> typedDeclaration(bitfieldType(unsigned-int, absInt(numBitsPerByte -Int (N:Nat %Nat numBitsPerByte)) %Nat numBitsPerByte), #NoName)
		:: fillBitHoles(typedDeclaration(T:Type, X:Id) :: L:List{Type})
		if notBool hasBitfieldType(T:Type) 
		[structural]
	
	rule fillBitHoles(N:Nat, (typedDeclaration(bitfieldType(T:Type, N':Nat), X:Id) :: L:List{Type})) 
		=> typedDeclaration(bitfieldType(T:Type, N':Nat), X:Id)
		:: fillBitHoles(N:Nat +Nat N':Nat, L:List{Type})
		if N':Nat =/=Bool 0 
		[structural]
		
	rule fillBitHoles(N:Nat, (typedDeclaration(bitfieldType(T:Type, N':Nat), ?) :: L:List{Type})) 
		=> typedDeclaration(bitfieldType(unsigned-int, absInt(numBitsPerByte -Int (N:Nat %Nat numBitsPerByte)) %Nat numBitsPerByte), #NoName)
		:: fillBitHoles(L:List{Type})
		if N':Nat ==Bool 0 
	
	rule fillBitHoles(N:Nat, Nil) => typedDeclaration(bitfieldType(unsigned-int, absInt(numBitsPerByte -Int (N:Nat %Nat numBitsPerByte)) %Nat numBitsPerByte), #NoName) 
		[structural]

	
	rule typedDeclaration(bitfieldType(?, N:Nat), #NoName) :: typedDeclaration(bitfieldType(?, N':Nat), #NoName) 
		=> typedDeclaration(bitfieldType(unsigned-int, N:Nat +Nat N':Nat), #NoName) 
		[structural]
	
	// fixme chould check for some struct contraints here
	op incompleteToFlexibleArrayMember : List{Type} -> List{Type} 
	rule incompleteToFlexibleArrayMember(typedDeclaration(T:Type, X:Id) :: L:List{Type}) 
		=> typedDeclaration(T:Type, X:Id) :: incompleteToFlexibleArrayMember(L:List{Type}) 
		if notBool hasIncompleteType(T:Type) 
		[structural]
	rule incompleteToFlexibleArrayMember(typedDeclaration(incompleteArrayType(T:Type), X:Id)) => typedDeclaration(flexibleArrayType(T:Type), X:Id) [structural]
	rule incompleteToFlexibleArrayMember(Nil) => Nil [structural]
	
	rule
		< k > StructDef(X:Id, L:List{Type})
			=> addStruct(X:Id, fillBitHoles(incompleteToFlexibleArrayMember(L:List{Type})))
			~> giveType(X:Id, structType(X:Id))
		...</ k >
		[structural] 
	rule
		< k > UnionDef(X:Id, L:List{Type})
			=> addUnion(X:Id, L:List{Type})
			~> giveType(X:Id, unionType(X:Id))
		...</ k >
		[structural] 

	// the K will resolve to a type, so throw it away
	rule
		< k > OnlyTypedef(K:K) => K:K ~> discard ...</ k >
		[structural] 
		
			
	rule
		NameAndType(X:Id, T:Type) => typedDeclaration(T:Type, X:Id)
		[structural] 
		
	rule extractActualType(T:Type) => T:Type if isBasicType(T:Type) [structural]
	rule extractActualType(enumType(X:Id)) => enumType(X:Id) [structural]
	rule extractActualType(structType(X:Id)) => structType(X:Id) [structural]
	rule extractActualType(unionType(X:Id)) => unionType(X:Id) [structural]
	rule extractActualType(arrayType(T:Type, N:Nat)) => arrayType(extractActualType(T:Type), N:Nat) [structural]
	rule extractActualType(incompleteArrayType(T:Type)) => incompleteArrayType(extractActualType(T:Type)) [structural]
	rule extractActualType(flexibleArrayType(T:Type)) => flexibleArrayType(extractActualType(T:Type)) [structural]
	rule extractActualType(bitfieldType(T:Type, N:Nat)) => bitfieldType(extractActualType(T:Type), N:Nat)[structural]
	rule extractActualType(functionType(T:Type, List:List{Type})) => functionType(extractActualType(T:Type), List:List{Type}) [structural]
	rule extractActualType(pointerType(T:Type)) => pointerType(extractActualType(T:Type)) [structural]
	rule extractActualType(qualifiedType(T:Type, K:K)) => qualifiedType(extractActualType(T:Type), K:K) [structural]
	rule extractActualType(prototype(T:Type)) => prototype(extractActualType(T:Type)) [structural]
	rule extractActualType(typedefType(?, T:Type)) => extractActualType(T:Type) [structural]
		
	op NameAndType : K K -> K [strict(2)] 
	
	rule
		SingleName(T:Type, Name(X:Id, K:K)) => NameAndType(X:Id, DeclType(T:Type, K:K))
		[structural] 
	rule [Separate-FieldGroups]:
		FieldGroup(K:K, (C:C :: C':C :: L:List{C})) => FieldGroup(K:K, C:C) :: FieldGroup(K:K, (C':C :: L:List{C}))
		[structural] 
	rule
		FieldGroup(K:K, Nil) => Nil
		[structural] 
	rule
		FieldGroup(T:Type, Name(X:Id, K:K)) => NameAndType(X:Id, DeclType(T:Type, K:K))
		[structural] 
	rule
		FieldGroup(T:Type, BitFieldName(Name(X:Id, K:K), Size:K))
		=> NameAndType(X:Id, DeclType(T:Type, BitFieldType(K:K, Size:K)))
		[structural] 
	rule FieldName(K:K) => K:K [structural]
endkm

kmod COMMON-SEMANTICS-TYPE-EXPRESSIONS is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	
	op HOLE : -> K 
	rule
		< k > typeof(E:Expression) => evalToType ~> typeof(HOLE) ...</ k >
		(.Bag => < type > E:Expression </ type >)
		[structural] 
	rule
		< k > evalToType ~> typeof(HOLE) => T:Type ...</ k >
		(< type > T:Type </ type > => .Bag)
		if isAType T:Type
		[structural] 

	rule
		< type > emptyValue => void ...</ type > 
		[structural] 
		
	rule
		< type > functionObject(?, T:Type, ?) => T:Type ...</ type >
		[structural] 

	rule
		< type > T:Type << ? => T:Type ...</ type >
		[structural] 
	rule
		< type > T:Type >> ? => T:Type ...</ type >
		[structural] 
		
	rule
		< type > tv(?, T:Type) => T:Type ...</ type >
		[structural] 
	
	rule
		< type > SizeofExpression(?) => cfg:sizeut ...</ type >
		[structural] 

	rule < type > E1:K[E2:K] => *(E1:K + E2:K) ...</ type > 
		[structural] 
	// rule
		// < type > arrayType(T:Type, ?)[T':Type] => T:Type ...</ type >
		// if hasIntegerType(T':Type)
		// [structural] 
	// rule
		// < type > pointerType(T:Type)[T':Type] => T:Type ...</ type >
		// if hasIntegerType(T':Type)
		// [structural] 
	rule 
		< type > arithInterpret(T:Type, ?) => T:Type ...</ type >
	rule
		< type > pointerType(T:Type) + T':Type => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > T':Type + pointerType(T:Type) => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > pointerType(T:Type) - T':Type => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > pointerType(T:Type) - pointerType(T':Type) => cfg:ptrdiffut ...</ type >
		[structural]
	rule
		< type > arrayType(T:Type, ?) + T':Type => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > T':Type + arrayType(T:Type, ?) => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > arrayType(T:Type, ?) - T':Type => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural]

	// c99 6.4.5
	rule
		< type > Constant(StringLiteral(S:String)) => arrayType(char, lengthString(S:String) +Nat 1) </ type >
		[structural] 
	rule
		< type > K:K => T:Type ...</ type >
		< types >... K:K |-> T:Type ...</ types >
		[structural] 
		
	rule
		< type > Comma(L:List{C} :: K:C) => K:C ...</ type >
		[structural] 

	rule [type-call-func]:
		< type > Call(functionType(T:Type, ?), L:List{C}) => T:Type ...</ type >
		[structural] 
	rule [type-call-func-ptr]:
		< type > Call(pointerType(functionType(T:Type, ?)), ?) => T:Type ...</ type >
		[structural] 
		 		
	rule [type-struct-dot]:
		< type > structType(S:Id) . F:Id => T:Type ...</ type >
		< structs >... 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), ?)
		...</ structs >
		[structural] 
	rule [type-union-dot]:
		< type > unionType(S:Id) . F:Id => T:Type ...</ type >
		< structs >... 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), ?)
		...</ structs >
		[structural] 
		
	rule [type-struct-arrow]:
		< type > pointerType(structType(S:Id)) -> F:Id => T:Type ...</ type >
		< structs >... 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), ?)
		...</ structs >
		[structural] 
	rule [type-union-arrow]:
		< type > pointerType(unionType(S:Id)) -> F:Id => T:Type ...</ type >
		< structs >... 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), ?)
		...</ structs >
		[structural] 

	// internal numbers, not literals
	rule < type > N:Nat => cfg:largestUnsigned ...</ type > 
		[structural] 

	rule [type-deref-type]:
		< type > *(pointerType(T:Type)) => T:Type ...</ type >
		[structural] 
	rule [type-deref-array-type]:
		< type > *(arrayType(T:Type, ?)) => T:Type ...</ type >
		[structural] 

	rule [type-compound-literal]:
		< type > CompoundLiteral(?, Specifier:K, DeclType:K, ?)
			=> Cast(Specifier:K, DeclType:K, emptyValue)  // sort of hackish, assumes cast will evaluate to type
		...</ type >
		[structural] 
	
	rule [type-assignment]:
		< type > L:KLabel(K:K,, ?) 
			=> K:K
		...</ type >
		if Set(
			l('_:=_),, l('_*=_),, l('_/=_),, l('_%=_),, l('_+=_),, l('_-=_),, 
			l('_<<=_),, l('_>>=_),, l('_&=_),, l('_^=_),, l('_|=_)
		) contains l(L:KLabel)
		[structural]
	
	// rule 
		// < type > L:KLabel(T:Type,, T':Type) => maxType(T:Type, T':Type) ...</ type >
		// if typeStrictBinaryOperators contains l(L:KLabel)
		// andBool hasIntegerType(T:Type)
		// andBool hasIntegerType(T':Type)
		// [structural] 
	rule 
		< type > L:KLabel(T:Type,, T':Type) => usualArithmeticConversion(T:Type, T':Type) ...</ type >
		if isArithBinConversionOp(L:KLabel)
		andBool (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type))
		[structural] 
		
	rule 
		< type > ?:K ? T:Type : T':Type => usualArithmeticConversion(T:Type, T':Type) ...</ type >
		if (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type))
		[structural]
	rule 
		< type > ?:K ? T:Type : T:Type => T:Type ...</ type >
		if isAType(T:Type)
		andBool notBool hasArrayType(T:Type)
		[structural]
		
	rule < type > ?:K ? (arrayType(T:Type, ?) => pointerType(T:Type)) : ? ...</ type > [structural]
	rule < type > ?:K ? ?:K : (arrayType(T:Type, ?) => pointerType(T:Type)) ...</ type > [structural]
		
	rule // not safe, could be incompatible types
		< type > ?:K ? pointerType(T:Type) : pointerType(T':Type) => pointerType(T:Type) ...</ type >
		[structural]

	rule
		< type > L:KLabel(T:Type) => promote(T:Type) ...</ type > 
		if isArithUnaryOp(L:KLabel)
		andBool (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		[structural]
	
	rule 
		< type > L:KLabel(T:Type,, ?:List{K}) => promote(T:Type) ...</ type >
		if (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural]
		
	rule 
		< type > L:KLabel(T:Type) => T:Type ...</ type >
		if hasPointerType(T:Type)
		andBool (
			L:KLabel ==Bool ('_++)
			orBool L:KLabel ==Bool ('_--)
			orBool L:KLabel ==Bool ('--_)
			orBool L:KLabel ==Bool ('++_)
		)
		[structural]
		
	rule
		< type > L:KLabel(?:K,, ?:K) => int ...</ type >
		if L:KLabel ==Bool '_==_
		orBool L:KLabel ==Bool '_!=_
		orBool L:KLabel ==Bool '_&&_
		orBool L:KLabel ==Bool '_||_
		[structural]
		
	rule [type-address]:
		< type > & T:Type => pointerType(T:Type) ...</ type >
		if isAType(T:Type)
		[structural]
		
endkm

kmod COMMON-C-TYPING is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	including COMMON-SEMANTICS-TYPE-STRICTNESS 
	including COMMON-SEMANTICS-TYPE-DECLARATIONS 
	including COMMON-SEMANTICS-TYPE-CANONICALIZATION 
	including COMMON-SEMANTICS-TYPE-INTERPRETATION 
	including COMMON-SEMANTICS-TYPE-EXPRESSIONS 
	
	rule [ExpressionLoc-type]:
		< type > ExpressionLoc(K:K, L:CabsLoc) => K:K ...</ type >
		< currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		[structural] 
	
	rule isTypeCompatible(T:Type, T:Type) 
		=> true 
		[structural]
	rule isTypeCompatible(T:Type, T':Type) 
		=> true 
		if hasIntegerType(T:Type)
		andBool hasIntegerType(T':Type) 
		[structural]
	rule isTypeCompatible(pointerType(?), pointerType(?))
		=> true 
		[structural]
	rule isTypeCompatible(pointerType(?), T:Type)
		=> true
		if hasIntegerType(T:Type) 
		[structural]
	rule isTypeCompatible(T:Type, pointerType(?))
		=> true
		if hasIntegerType(T:Type)
		[structural]
		
	rule isTypeCompatible(typedDeclaration(T:Type, ?), typedDeclaration(T':Type, ?))
		=> isTypeCompatible(T:Type, T':Type) 
		[structural]
	rule isTypeCompatible(prototype(T:Type), prototype(T':Type)) 
		=> isTypeCompatible(T:Type, T':Type) 
		[structural]

	rule isTypeCompatible(T:Type, arrayType(T':Type, ?))
		=> isTypeCompatible(T:Type, pointerType(T':Type)) 
		[structural]
	rule isTypeCompatible(arrayType(T:Type, ?), T':Type)
		=> isTypeCompatible(pointerType(T:Type), T':Type) 
		[structural]
	
	rule isTypeCompatible(T:Type, incompleteArrayType(T':Type))
		=> isTypeCompatible(T:Type, pointerType(T':Type)) 
		[structural]
	rule isTypeCompatible(incompleteArrayType(T:Type), T':Type)
		=> isTypeCompatible(pointerType(T:Type), T':Type) 
		[structural]

	rule isTypeCompatible(functionType(T1:Type, typedDeclaration(void, ?)), functionType(T2:Type, Nil))
		=> isTypeCompatible(T1:Type, T2:Type) 
		[structural]
	rule isTypeCompatible(functionType(T1:Type, Nil), functionType(T2:Type, typedDeclaration(void, ?)))
		=> isTypeCompatible(T1:Type, T2:Type) 
		[structural]
	rule isTypeCompatible(functionType(T1:Type, (T':Type :: L:List{Type})), functionType(T2:Type, (T'':Type :: L':List{Type})))
		=> isTypeCompatible(functionType(T1:Type, L:List{Type}), functionType(T2:Type, L':List{Type}))
		andBool isTypeCompatible(T':Type, T'':Type) 
		[structural]
	rule isTypeCompatible(functionType(T1:Type, Nil), functionType(T2:Type, Nil))
		=> isTypeCompatible(T1:Type, T2:Type) 
		[structural]
	rule isTypeCompatible(T:Type, T':Type) => true
		if (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type)) 
		[structural]
	rule 
		< k > Cast(T:Type, K:K, V:Value) => cast(DeclType(T:Type, K:K), V:Value) ...</ k >
		[structural] 
			
	op addGlobalAggregate : Id K -> K 
	op addLocalAggregate : Id K -> K 
	
	op addStruct-aux : Id List{Type} K Map Map List{Type} -> K [strict(3)]
	op addUnion-aux : Id List{Type} Map Map List{Type} -> K
	rule
		< k > addStruct(S:Id, L:List{Type}) 
			=> addStruct-aux(S:Id, L:List{Type}, tv(0, cfg:largestUnsigned), .Map, .Map, L:List{Type})
		...</ k >
		[structural]
	rule
		< k > addStruct-aux(
				S:Id
				, (typedDeclaration(T:Type, Field:Id) :: L:List{Type})
				, V:Value
				, Types:Map
				, Offsets:Map
				, L':List{Type}
			) 
			=> addStruct-aux(S:Id, L:List{Type}, V:Value + bitSizeofType(T:Type), Types:Map[T:Type / Field:Id], Offsets:Map[value(V:Value) / Field:Id], L':List{Type})
		...</ k >
		[structural]
	rule
		< k > addStruct-aux(S:Id, Nil, ?, Types:Map, Offsets:Map, L:List{Type}) 
			=> if (F:Id ==Bool File-Scope) then 
				(addGlobalAggregate(S:Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map))) 
			else
				(addLocalAggregate(S:Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map)))
			fi
		...</ k >
		< currentFunction > F:Id </ currentFunction >
		[structural]
		
		
	rule
		< k > addUnion(S:Id, L:List{Type}) 
			=> addUnion-aux(S:Id, L:List{Type}, .Map, .Map, L:List{Type})
		...</ k >
		[structural]
	rule
		< k > addUnion-aux(
				S:Id
				, (typedDeclaration(T:Type, Field:Id) :: L:List{Type})
				, Types:Map
				, Offsets:Map
				, L':List{Type}
			) 
			=> addUnion-aux(S:Id, L:List{Type}, Types:Map[T:Type / Field:Id], Offsets:Map[0 / Field:Id], L':List{Type})
		...</ k >
		[structural]
	rule
		< k > addUnion-aux(S:Id, Nil, Types:Map, Offsets:Map, L:List{Type}) 
			=> if (F:Id ==Bool File-Scope) then 
				(addGlobalAggregate(S:Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map))) 
			else
				(addLocalAggregate(S:Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map)))
			fi
		...</ k >
		< currentFunction > F:Id </ currentFunction >
		[structural]
	// fixme looks like i don't actually need global and local, although possibly with vlas in structs?
	// rule
		// < k > addAggregate-aux(X:Id, L:List{Type}) 
			// => if (F:Id ==Bool File-Scope) then 
				// (addGlobalAggregate(X:Id, L:List{Type})) 
			// else
				// (addLocalAggregate(X:Id, L:List{Type}))
			// fi
		// ...</ k >
		// < currentFunction > F:Id </ currentFunction >
		// [structural] 
	rule
		< k > addGlobalAggregate(X:Id, K:K) => . ...</ k >
		< structs > M':Map => M':Map[K:K / X:Id] </ structs >
		< gstructs > M:Map => M:Map[K:K / X:Id] </ gstructs >
		[structural] 
	rule
		< k > addLocalAggregate(X:Id, K:K) => . ...</ k >
		< structs > M:Map => M:Map[K:K / X:Id] </ structs >
		[structural] 
		
	rule isAType T:Type => true
		if setOfTypes contains l(getKLabel(T:Type)) 
		[structural]
	rule isAType T:Type => true if isBasicType(T:Type) [structural]
	rule isAType K:K => false
		if notBool setOfTypes contains l(getKLabel(K:K))
		andBool notBool isBasicType(K:K) [structural]
			

	// FIXME most of these don't take into consideration modifiers

	rule hasFloatType(float) => true [structural]
	rule hasFloatType(double) => true [structural]
	rule hasFloatType(long-double) => true [structural]
	rule hasFloatType(T:Type) => false
		if T:Type =/=Bool float
		andBool T:Type =/=Bool double
		andBool T:Type =/=Bool long-double
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType
		[structural]
	
	rule hasCharType(char) => true [structural]
	rule hasCharType(unsigned-char) => true [structural]
	rule hasCharType(signed-char) => true [structural]
	rule hasCharType(T:Type) => false
		if T:Type =/=Bool char
		andBool T:Type =/=Bool unsigned-char
		andBool T:Type =/=Bool signed-char
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
	
	rule hasPointerType(pointerType(?)) => true [structural]
	rule hasPointerType(qualifiedType(T:Type, ?)) => hasPointerType(T:Type) [structural]
	rule hasPointerType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'pointerType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
	
	rule hasTypedefType(typedefType(?, ?)) => true [structural]
	rule hasTypedefType(qualifiedType(T:Type, ?)) => hasTypedefType(T:Type) [structural]
	rule hasTypedefType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'typedefType 
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
	
	rule hasBoolType(bool) => true [structural]
	rule hasBoolType(qualifiedType(T:Type, ?)) => hasBoolType(T:Type) [structural]
	rule hasBoolType(T:Type) => false
		if T:Type =/=Bool bool 
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
	
	rule hasArrayType(arrayType(?, ?)) => true [structural]
	rule hasArrayType(incompleteArrayType(?)) => true [structural]
	rule hasArrayType(qualifiedType(T:Type, ?)) => hasArrayType(T:Type) [structural]
	rule hasArrayType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'arrayType 
		andBool getKLabel(T:Type) =/=Bool 'incompleteArrayType 
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasAggregateType(T:Type) => hasArrayType(T:Type) orBool hasStructType(T:Type) [structural]
		
	rule hasStructType(structType(?)) => true [structural]
	rule hasStructType(qualifiedType(T:Type, ?)) => hasStructType(T:Type) [structural]
	rule hasStructType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'structType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasUnionType(unionType(?)) => true [structural]
	rule hasUnionType(qualifiedType(T:Type, ?)) => hasUnionType(T:Type) [structural]
	rule hasUnionType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'unionType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]

	rule hasIncompleteType(incompleteArrayType(?)) => true [structural]
	rule hasIncompleteType(qualifiedType(T:Type, ?)) => hasIncompleteType(T:Type) [structural]
	rule hasIncompleteType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'incompleteArrayType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasExternType(qualifiedType(T:Type, K:K)) => if (K:K ==Bool Extern) then (true) else (hasExternType(T:Type)) fi 
		[structural]
	rule hasExternType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasStaticType(qualifiedType(T:Type, K:K)) => if (K:K ==Bool Static) then (true) else (hasStaticType(T:Type)) fi 
		[structural]
	rule hasStaticType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasBitfieldType(bitfieldType(?, ?)) => true [structural]
	rule hasBitfieldType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'bitfieldType
		[structural]
		
	rule hasFunctionType(functionType(?, ?)) => true [structural]
	rule hasFunctionType(prototype(T:Type)) => hasFunctionType(T:Type) [structural]
	rule hasFunctionType(qualifiedType(T:Type, ?)) => hasFunctionType(T:Type) [structural]
	rule hasFunctionType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'functionType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType
		andBool getKLabel(T:Type) =/=Bool 'prototype 
		[structural]
		
	rule hasFunctionPointerType(pointerType(functionType(?, ?))) => true [structural]
	rule hasFunctionPointerType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'pointerType 
		[structural]
	rule hasFunctionPointerType(pointerType(T:Type)) => false
		if getKLabel(T:Type) =/=Bool 'functionType 
		[structural]
		
		
	rule unqualifyType(qualifiedType(T:Type, ?)) => T:Type [structural]
	rule unqualifyType(T:Type) => T:Type
		if getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
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
	
	
	rule reval(emptyValue) => emptyValue [structural]
	
	// including FIXED-C-STYLE
	// including FIXED-C-STYLE-TWOS-COMPLEMENT 
	
	// including COMMON-C-HELPERS
	including COMMON-C-TYPING 
	including COMMON-C-DECLARATIONS 
	// including COMMON-C-MEMORY 
	// including COMMON-C-STATEMENTS 
	// including COMMON-C-EXPRESSIONS 
	// including COMMON-C-CONVERSIONS 
	// including COMMON-C-STANDARD-LIBRARY 
	// including COMMON-C-ERRORS
	rule Nop => . 
		[structural] 
	rule AttributeWrapper(K:K, ?) => K:K [structural]
	rule [CodeLoc-k]:
		< k > CodeLoc(K:K, L:CabsLoc) => K:K ...</ k >
		< currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		[structural]
	op eval : K -> Bag 
	op eval : K List{K} String -> Bag
	
	op TranslationUnitName : String -> KLabel
endkm
