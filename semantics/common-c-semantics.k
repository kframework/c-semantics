kmod COMMON-INCOMING-MODULES is
	including K
	including C-SYNTAX 
	including COMMON-C-CONFIGURATION 
	including K-CONTEXTS 
	including K-PROPER
	
	
	sort Type 
	sort Value 
	sort List{Type} 
	subsort List{Type} < KResult 
	subsort List{Type} < List{C} 
	subsort Type < List{Type}
	subsort Type < List{C} 
	subsort Value < List{Type} 
	subsort Type < C 
	subsort Value < C 
	sort BaseValue 

	subsort Nat Int Float < BaseValue 
	subsort BaseValue < C
	subsort Value < KResult K 
	subsort Type < KResult K
	
endkm

kmod COMMON-SEMANTIC-SYNTAX is
	including COMMON-INCOMING-MODULES 
	
	op _::_ : List{Type} List{Type} -> List{Type} [ditto] 
	op Nil : -> List{Type} [ditto] 
		
	// Types
	op typedDeclaration : Type Id -> Type // would rather this be KResult, but can't get the subsorting to work
	
	op DeclType : K K -> K [metadata "strict=(1)"] // represents a type before canonicalization.  as in "int *x", first arg is "Int", second arg is "PointerType(JustBase)"
	op isAType_ : K -> Bool 
	op setOfTypes : -> Set [memo] 
	
	op usualArithmeticConversion : Type Type -> K
	op callMain-aux : K Nat Id K -> K [metadata "strict=(1)"] // having to put this out here so errors can see it
	op initFunction : K K -> K [metadata "strict=()"]
	op populateFromGlobal : -> K 
	
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
	//op bignum : -> Type 
	op sym : Nat -> Nat 
	op byteo : Nat -> Nat 
	op bito : Nat -> Nat 

	op bitoffset : Nat -> Nat 
	op byteoffset : Nat -> Nat 
	op declare : K K -> K [metadata "strict=(1)"] 
	op enumItem : Id Value -> Value 
	op resolveReferences : -> K 
	
	op toString : K -> String 
	
	op maxType : Type Type -> Type 
	
	op bitRange : Nat Nat Nat -> Nat // original number, from, to inclusive
	
	op fillToBytes : K -> K [metadata "strict=()"] 
	
	op floorLoc : Nat -> Nat // loc with possible bit offset returning base byte	
	op ceilingLoc : Nat -> Nat // loc with possible bit offset returning upperbounded byte	
	op readFunction : Nat -> K 
	
	op innerType : Type -> Type
	
	op AttributeValue : String List{C} -> KResult 
	
	op extractBitsFromList : K Nat Nat -> K [metadata "strict=(1)"] // data, offset, size in bits
	op typedef : Id -> Id 
	op unnamed : Nat -> Id 
	
	op NullPointerConstant : -> Nat 
	
	op NullPointer : -> Nat 
	
	op emptyValue : -> Value 
	op _bit::_ : Nat Nat -> Nat [assoc] 
	op allocate : Type K -> K
	
	op zero : K -> K 
	op zeroBlock : Nat -> K 
		
	op value : K -> K 
		
	op sizeofLocation : K -> K
	op type : K -> Type 
	
	
	op allocateType : Nat Type -> K 
	op allocateTypeIfAbsent : Nat Type -> K 
	op giveType : Id Type -> K 
	op addToEnv : Id Nat -> K 
	
	op read : K K -> K [metadata "strict=(2)"] // location, type
	op write : K K -> K [metadata "strict=(2)"] // location, value
	op writeByte : Nat K -> K 

	op isTypeCompatible : K K -> Bool 
	
	op hasBeenPromoted : Type -> Bool
	// op isPromotedInteger : Type -> Bool
	
	
	op bitloc : Nat Nat Nat -> Nat 
	op inc : Nat -> Nat 
	op threadId : Nat -> Nat // used for symbolic locations based on threadid
	op allocatedDuration : -> Nat // fake threadid for above when location is of allocated duration
	// op readOnly : -> Nat // fake threadid for above when location can't be written to
		
	op initialize : Id Type K -> K 
	op memblock : Nat Map -> K // length and an array from offsets to bytes
	
	op listToK : K -> K 
	op klistToK : List{K} -> K 
	op UnknownCabsLoc : -> K 
	
	
	op assert : Bool Nat -> K // check, error#
	
	
	// Basic types
	ops bool : -> Type 
	ops void bool char short-int int long-int long-long-int : -> Type 
	ops float double long-double : -> Type 
	ops signed-char unsigned-char : -> Type 
	ops unsigned-short-int unsigned-int unsigned-long-int unsigned-long-long-int : -> Type 
	op no-type : -> Type
	
	op isBasicType : K -> Bool
	
	
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

	op dataList : List{K} -> KResult 
	
	op K2Nat : K -> Nat
	op sizeofType : K -> K [metadata "strict=()"] // generates a tv(size, cfg:sizeut)
	op bitSizeofType : K -> K [metadata "strict=()"] // needs to be heated to top of K for struct and union types
	op byteSizeofType : K -> K [metadata "strict=()"] 
	op bitsToBytes : Nat -> Nat 
	op HOLE : -> Expression 
	op l : KLabel -> K [metadata "wrapper=(builtin)"] 
	op _contains_ : Set K -> Bool [memo] 
	
	
	
	
	op bind : List{C} List{Type} -> K 
	op tv : List{K} Type -> Value [metadata "latex=(renameTo \\ensuremath{{_}\\mathop{:}{_}})"]
	op concretize : Type K -> K [metadata "strict=(2)"] 
	op functionObject : Id Type K -> Value 
	op functionPrototype : Id Type -> Value 
	
	op firstChar : String -> Char 
	op nthChar : String Nat -> Char 
	op butFirstChar : String -> String 
	op charToAscii : String -> Nat 
	op stringToChar : String -> Char 
	op asciiCharString : String -> Nat 
	
	
	
	op _to_ : Nat Nat -> List{K} 
	op cast : K K -> K [metadata "strict=(1)"] // as described in 6.3 // totype, fromvalue
	context cast(_, ([HOLE] => reval([HOLE])))
	op arithInterpret : Type BaseValue -> K // interpret the result of arithmetic as in 6.5.4
	op interpret : Type K -> K // interpret the values of reading from mem
	op leftShiftInterpret : Type BaseValue K -> K 
	op rightShiftInterpret : Type BaseValue -> K 
	
	// op integerTypes : -> Set [memo] 
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
	op hasWCharType : Type -> Bool 
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
	// op hasTypedefType : Type -> Bool 
	op hasArithmeticType : Type -> Bool
	
	op aggregateInfo : List{C} Map Map -> K // first map is for type, second map is for offset
	op getFieldOffset : Id K -> Nat // these expect an aggregateInfo term as second argument
	op getFieldType : Id K -> Type
	
	op isArithBinConversionOp : KLabel -> Bool 
	op isArithUnaryOp : KLabel -> Bool 
	op kpair : K K -> K 
	op promote : K -> K 
	op argPromote : K -> K
	op extractField : List{K} K Id -> K // bytes of struct, type, field id
	op allocString : Nat String -> K 
	op allocWString : Nat List{K} -> K 
	op sequencePoint : -> K 
	
	op handleBuiltin : Id Type -> K 
	
	op min : Type -> Int [memo]
	op max : Type -> Int [memo]
	op alloc : K K -> K // should be K K 
	
	// these are also used by compound literals
	op initializerValue : Id Type K -> KResult 
	op figureInitializer : Id K K -> K [metadata "strict=(2)"] // id, type, initializer
	
		
	op append : Nat Nat Value -> K // appends a new subobject to a current object.  this is unsafe and should only be used for variadic functions
	op deleteBlock : Nat -> K // deletes the base object from memory, given a location
	op deleteSizedBlock : Nat Nat -> K // deletes the base object from memory, given a location and it size (as a check)
	
	
	op isConcreteNumber : Int -> Bool 
	op _in_ : K List -> Bool 
endkm

kmod COMMON-C-SETTINGS is
	including COMMON-SEMANTIC-SYNTAX 

	// op IdentifierSet : List{K} -> Set 
	// rule IdentifierSet((S:String,, L:List{K})) => SetItem(Identifier(S:String)) IdentifierSet(L:List{K}) [structural]
	// op builtinIdentifiers : -> Set [memo] 
	
	// // fixme bug why can't i use .List{K} here?
	// rule builtinIdentifiers => IdentifierSet((
		// "abort"
		// ,, "asin"
		// ,, "atan"
		// ,, "atan2"
		// ,, "calloc"
		// ,, "cos"
		// ,, "__debug"
		// ,, "exit"
		// ,, "exp"
		// ,, "floor"
		// ,, "fmod"
		// ,, "free"
		// ,, "fslCloseFile"
		// ,, "fslFGetC"
		// ,, "fslOpenFile"
		// ,, "fslPutc"
		// ,, "getchar"
		// ,, "log"
		// ,, "longjmp"
		// ,, "malloc"
		// ,, "printf"
		// ,, "putchar"
		// ,, "rand"
		// ,, "setjmp"
		// ,, "sin"
		// ,, "sqrt"
		// ,, "tan"
		// // <threads.h>
		// ,, "thrd_create"
		// ,, "thrd_current"
		// ,, "thrd_detach"
		// ,, "thrd_join"
		// ,, "__test_and_set"
		// ,, "__va_inc"
		// ,, "__va_start"
		// ,, "__va_end"
		// ,, "__va_copy"
	// )) [structural]
	
	// S 6.2.5 p.35 i.15.  "The implementation shall define char to have the same range, representation, and behavior as either signed char or unsigned char.  37)... Irrespective of the choice made, char is a separate type from the other two and is not compatible with either
	// fixme I'm not sure what consequence being a separate type entails, so for now it will just be rewritten to the chosen type
	rule char => signed-char 
		[structural] 

	op numBitsPerByte : -> NzNat 
	op numBytes : Type -> Nat [memo] 
	op numBits : Type -> Nat [memo] 

	rule [numBitsPerByte]: numBitsPerByte => 8 [structural]
	
	rule [numBytes-bool]: numBytes(bool) => 1 [structural]
	rule [numBytes-signed-char]: numBytes(signed-char) => 1 [structural]
	rule [numBytes-short-int]: numBytes(short-int) => 2 [structural]
	rule [numBytes-int]: numBytes(int) => 4 [structural]
	rule [numBytes-long-int]: numBytes(long-int) => 4 [structural]
	rule [numBytes-long-long-int]: numBytes(long-long-int) => 8 [structural]
	
	rule [numBytes-float]: numBytes(float) => 4 [structural]
	rule [numBytes-double]: numBytes(double) => 8 [structural]
	rule [numBytes-long-double]: numBytes(long-double) => 16 [structural]
	
	rule [numBytes-enum]: numBytes(enumType(X:Id)) => numBytes(int) [structural]
	
	op cfg:sizeut : -> Type 
	rule [cfg-size-t]: cfg:sizeut => unsigned-int [structural]
	
	op cfg:wcharut : -> Type
	rule [cfg-wchar-t]: cfg:wcharut => int [structural]
	
	op cfg:largestUnsigned : -> Type 
	rule [cfg-largestUnsigned]: cfg:largestUnsigned => unsigned-long-long-int [structural]

	op cfg:ptrsize : -> Nat 
	rule [cfg-ptrsize]: cfg:ptrsize => 4 [structural]
	
	op cfg:ptrdiffut : -> Type 
	rule [cfg-ptrdiff-t]: cfg:ptrdiffut => int [structural]
	
	rule [min]: min(enumType(?)) => min(int) [structural]
	rule [max]: max(enumType(?)) => max(int) [structural]
	
	op rank : Type -> Int 
		
	rule rank(bool) => 0 [structural]
	// rule rank(char) => 1 [structural] // not needed if char is sugar
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
	
	// rule rank(bignum) => 100 [structural] // used for internal calculation.  should be bigger than all other ranks
	
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

// load common-c-sized-operations

kmod COMMON-NOHELPER-INCLUDE is
	including COMMON-SEMANTIC-SYNTAX
	including COMMON-C-SETTINGS
endkm

load common-c-helpers

kmod COMMON-INCLUDE is
	including COMMON-NOHELPER-INCLUDE
	including COMMON-C-HELPERS
endkm

kmod COMMON-C-SEMANTICS-MISC is
	including COMMON-INCLUDE 
	
	
	rule inc(sym(N:Nat) +Nat M:Nat) => sym(N:Nat +Nat 1) +Nat M:Nat [structural]
	rule sNat(sym(N:Nat) +Nat M:Nat) => sym(N:Nat) +Nat (M:Nat +Nat 1) [structural]
	rule I:Int +Int (N:Nat +Nat sym(M:Nat))
		=> absInt(N:Nat +Int I:Int) +Nat sym(M:Nat) 
		if N:Nat +Int I:Int >=Int 0 
		[structural]
		
	// rule (N:Nat +Nat sym(M:Nat)) -Int I:Int
		// => absInt(N:Nat -Int I:Int) +Nat sym(M:Nat) 
		// if N:Nat -Int I:Int >=Int 0 
		// [structural]

	rule [unknown-loc]: CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc [structural]

	rule [expression-loc]: ExpressionLoc(K:K, ?) => K:K [structural]

	rule [CodeLoc-k]:
		< k > CodeLoc(K:K, L:CabsLoc) => K:K ...</ k >
		< currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		[structural]
		
		
	/*@ \source[n1570]{\para{6.10.6}{1}}
	A preprocessing directive of the form
	\cdisplay{# pragma pp-tokensoptnew-line}
\broken{where the preprocessing token \cinline{STDC} does not immediately follow pragma in the directive (prior to any macro replacement)} causes the implementation to behave in an implementation-defined manner. The behavior might cause translation to fail or cause the translator or the resulting program to behave in a non-conforming manner. Any such pragma that is not recognized by the implementation is ignored.
	*/
	rule [Pragma]:
		< k > Pragma(?:K) => .K ...</ k >
		[structural]
	// fixme, problem in K:  this rule takes 150 seconds to error
	// rule [Pragma]:
		// < k > Pragma(?:K) => ? ...</ k >
		// [structural]
		
	rule [Attributes]:
		< k > Attribute(S:String, L:List{C}) => AttributeValue(S:String, L:List{C}) ...</ k >
		[structural]
		
	rule AttributeWrapper(K:K, ?) => K:K [structural]
	
	rule N:Nat +Nat bito(M:Nat) => N:Nat +Nat (M:Nat /Nat numBitsPerByte) +Nat bito(M:Nat %Nat numBitsPerByte)
		if M:Nat >=Nat numBitsPerByte 
		[structural]
	
	// rule FieldName((Identifier("___missing_field_name") => AnonAggregate)) [structural]
	// rule BitFieldName((Identifier("___missing_field_name") => #NoName), ?) [structural]
	rule Identifier("___missing_field_name") => #NoName [structural]
	// #NoName [structural] 
endkm

load common-c-statements
load common-c-expressions
load common-c-declarations
load common-c-typing

kmod COMMON-C-SEMANTICS is
	including COMMON-INCLUDE 
	
	including COMMON-C-SEMANTICS-MISC
	including COMMON-C-EXPRESSIONS
	including COMMON-C-STATEMENTS
	including COMMON-C-DECLARATIONS
	including COMMON-C-TYPING
	
	op eval : K -> Bag 
	op eval : K List{K} String -> Bag
	op callMain : Nat Id K -> K
	op incomingArguments : List{K} -> K
	
	op TranslationUnitName : String -> KLabel
		
endkm
