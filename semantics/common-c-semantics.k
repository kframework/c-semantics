kmod COMMON-INCOMING-MODULES is
	including K
	including C-SYNTAX 
	including COMMON-C-CONFIGURATION 
	including K-CONTEXTS 
	
	sort Type 
	sort Value 
	subsort Type < C 
	subsort Value < C 
	sort BaseValue 

	subsort #Nat #Int #Float < BaseValue 
	subsort BaseValue < C
	subsort Value < KResult K 
	subsort Type < KResult K
	
endkm

kmod COMMON-SEMANTIC-SYNTAX is
	including COMMON-INCOMING-MODULES 
	
	// these are used for runtime settings
	op kccSettingSimpleType : #String -> SimpleType
	op kccSettingNzNat : #String -> #NzNat
	op kccSettingInt : #String -> #Int
	
	op fromUnion : #Id -> K	
		
	// Types
	op typedDeclaration : Type #Id -> Type // would rather this be KResult, but can't get the subsorting to work
	
	op DeclType : K K -> K [metadata "strict=(1)"] // represents a type before canonicalization.  as in "int *x", first arg is "Int", second arg is "PointerType(JustBase)"
	op isAType_ : K -> #Bool 
	op setOfTypes : -> Set // [memo] 
	
	op usualArithmeticConversion : Type Type -> K
	op callMain-aux : K #Nat #Id K -> K [metadata "strict=(1)"] // having to put this out here so errors can see it
	op initFunction : K K -> K [metadata "strict=()"]
	op populateFromGlobal : -> K 
	
	op checkValidLoc : K -> K
	op checkDerefLoc : K -> K
	op ListItem : BagItem -> ListItem
	declare ListToK : List -> K 
	op Map : Map -> K 
	op piece : #Nat #Nat -> #Nat 
	
	op unknown : #Nat -> #Nat // [ctor] 
	
	op skipval : -> KResult 
	op debug : -> K 
	op discard : -> K 
	op File-Scope : -> #Id // [ctor] 
	op unnamedBitField : -> #Id // [ctor] 
	//op bignum : -> Type 
	op sym : #Nat -> #Nat 
	op byteo : #Nat -> #Nat 
	op bito : #Nat -> #Nat 

	declare bitoffset : #Nat -> #Nat 
	declare byteoffset : #Nat -> #Nat
	op enumItem : #Id Value -> Value 
	op resolveReferences : -> K 
	
	op toString : K -> #String 
	
	op maxType : Type Type -> Type 
	
	op bitRange : #Nat #Nat #Nat -> #Nat // original number, from, to inclusive
	
	op fillToBytes : K -> K [metadata "strict=()"] 
	
	op floorLoc : #Nat -> #Nat // loc with possible bit offset returning base byte	
	op ceilingLoc : #Nat -> #Nat // loc with possible bit offset returning upperbounded byte	
	op readFunction : #Nat -> K 
	
	declare innerType : Type -> Type
	
	// op AttributeValue : #String List{K} -> KResult 
	
	op extractBitsFromList : K #Nat #Nat -> K [metadata "strict=(1)"] // data, offset, size in bits
	op typedef : #Id -> #Id 
	op unnamed : #Nat -> #Id 
	
	op NullPointerConstant : -> #Nat 
	
	op NullPointer : -> #Nat 
	
	op emptyValue : -> Value 
	op allocate : Type K -> K
	
	op zero : K -> K 
	op zeroBlock : #Nat -> K 
		
	op value : K -> K 
		
	op sizeofLocation : K -> K
	op type : K -> Type 
	
	op flush : #Nat -> K
	
	op allocateType : #Nat Type -> K 
	op allocateTypeIfAbsent : #Nat Type -> K 
	op giveType : #Id Type -> K 
	op addToEnv : #Id #Nat -> K 
	
	op read : K K -> K [metadata "strict=(2)"] // location, type
	op write : K K -> K [metadata "strict=(2)"] // location, value
	op writeByte : #Nat K -> K 

	declare isTypeCompatible : K K -> #Bool 
	
	declare hasBeenPromoted : Type -> #Bool
	// op isPromotedInteger : Type -> #Bool
	
	
	op bitloc : #Nat #Nat #Nat -> #Nat 
	op inc : #Nat -> #Nat 
	op threadId : #Nat -> #Nat // used for symbolic locations based on threadid
	op allocatedDuration : -> #Nat // fake threadid for above when location is of allocated duration
	// op readOnly : -> #Nat // fake threadid for above when location can't be written to
		
	op initialize : #Id Type K -> K 
	op memblock : Bag Map -> K // length and an array from offsets to bytes
	op mlength : #Nat -> BagItem
	op mconst : -> BagItem
	op makeUnwritable : #Nat -> K
	op makeUnwritableSubObject : K -> K
	op makeUnwritableVar : K -> K
	context makeUnwritableSubObject((HOLE => peval(HOLE)))
	
	op listToK : K -> K 
	op klistToK : List{K} -> K 
	op UnknownCabsLoc : -> K 
	
	
	op assert : #Bool #Nat -> K // check, error#
	
	sort SimpleType 
	subsort SimpleType < K
	
	// Basic types
	ops bool : -> SimpleType 
	ops void bool char short-int int long-int long-long-int : -> SimpleType 
	ops float double long-double : -> SimpleType 
	ops signed-char unsigned-char : -> SimpleType 
	ops unsigned-short-int unsigned-int unsigned-long-int unsigned-long-long-int : -> SimpleType 
	op no-type : -> SimpleType
	
	op t : Set SimpleType -> Type
	/*
	t(S', pointerType(t(S, T:KResult)))
	pointerType(T:KResult)
	S' pointerType(S T:KResult)
	tv(5, T:KResult)
	*/
	
	op isBasicType : K -> #Bool
	
	// Composite types
	op enumType : #Id -> SimpleType // [ctor] 
	op arrayType : Type #Nat -> SimpleType // [ctor] 
	op incompleteArrayType : Type -> SimpleType // [ctor] 
	op flexibleArrayType : Type -> SimpleType // [ctor] 
	op bitfieldType : Type #Nat -> SimpleType // [ctor] 
	op functionType : Type List{KResult} -> SimpleType // [ctor] 
	op pointerType : Type -> SimpleType // [ctor] 
	op structType : #Id -> SimpleType // [ctor] 
	op unionType : #Id -> SimpleType // [ctor] 
	op qualifiedType : Type K -> SimpleType // [ctor]
	
	declare unqualifyType : K -> Type // takes a type, but sometimes things like maps give K
	declare removeStorageSpecifiers : K -> Type
	
	// these aren't real types, but are values that can appear in type contexts
	op prototype : Type -> SimpleType 
	op typedefType : #Id Type -> SimpleType 
	op variadic : -> SimpleType 

	op dataList : List{K} -> KResult 
	
	op K2Nat : K -> #Nat
	op sizeofType : K -> K [metadata "strict=()"] // generates a tv(size, cfg:sizeut)
	op bitSizeofType : K -> K [metadata "strict=()"] // needs to be heated to top of K for struct and union types
	op byteSizeofType : K -> K [metadata "strict=()"] 
	op bitsToBytes : K -> #Nat 
	// op MYHOLE : -> Expression 
	op l : KLabel -> K [metadata "wrapper=(builtin)"] 
	declare _contains_ : Set K -> #Bool // [memo] 
	
	op getModifiers : K -> Set
	
	op AllowWrite : K -> K [metadata "strict=()"]
	
	rule AllowWrite(lv(N:#Nat, T:KResult)) => lv(N:#Nat, stripConst(T:KResult)) [structural anywhere]

	declare stripConst : Type -> Type
	
	define stripConst(t((SetItem(Const) => .Set) _, _)) [structural]
	define 
		stripConst(t(S:Set, T:K)) => t(S:Set, T:K)
		when notBool Const in S:Set
		[structural]
	
	op bind : List{KResult} List{KResult} -> K 
	op tv : List{K} Type -> Value [metadata "latex=(renameTo \\ensuremath{{_}\\mathop{:}{_}})"]
	op lv : List{K} Type -> Value
	op concretize : Type K -> K [metadata "strict=(2)"] 
	op functionObject : #Id Type K -> Value 
	op functionPrototype : #Id Type -> Value 
	
	op firstChar : #String -> #Char 
	op nthChar : #String #Nat -> #Char 
	op butFirstChar : #String -> #String 
	op charToAscii : #String -> #Nat 
	op stringToChar : #String -> #Char 
	op asciiCharString : #String -> #Nat 
	
	
	
	declare _to_ : #Nat #Nat -> List{K} 
	declare cast : K K -> K [metadata "strict=()"] // as described in 6.3 // totype, fromvalue
	context cast(_, (HOLE => reval(HOLE)))
	declare arithInterpret : Type BaseValue -> K // interpret the result of arithmetic as in 6.5.4
	declare interpret : Type K -> K // interpret the values of reading from mem
	declare leftShiftInterpret : Type BaseValue K -> K 
	declare rightShiftInterpret : Type BaseValue -> K 
	
	// op integerTypes : -> Set // [memo] 
	op unsignedIntegerTypes : -> Set // [memo] 
	op signedIntegerTypes : -> Set // [memo] 
	declare hasIntegerType : Type -> #Bool // [memo] 
	declare hasFloatType : Type -> #Bool // [memo] 
	declare hasUnsignedIntegerType : Type -> #Bool // [memo] 
	declare hasSignedIntegerType : Type -> #Bool // [memo] 
	
	op typeof : K -> K 
	op writeToFD : #Nat #Nat -> K 
	op writeToFD : #Nat #String -> K 
	op readFromFD : #Nat -> K 
	op readFromFD : #Nat #Nat -> K 

	op calculateGotoMap : #Id K -> K 
	
	declare hasCharType : Type -> #Bool 
	declare hasWCharType : Type -> #Bool 
	// fixme make sure i use this everywhere instead of T:BaseType
	// op isABaseType_ : K -> #Bool 
	declare hasPointerType : Type -> #Bool 
	declare hasArrayType : Type -> #Bool 
	declare hasBoolType : Type -> #Bool 
	declare hasStructType : Type -> #Bool 
	declare hasUnionType : Type -> #Bool 
	declare hasAggregateType : Type -> #Bool 
	declare hasFunctionType : Type -> #Bool 
	declare hasFunctionPointerType : Type -> #Bool 
	declare hasBitfieldType : Type -> #Bool 
	declare hasExternType : Type -> #Bool 
	declare hasStaticType : Type -> #Bool 
	declare hasConstType : Type -> #Bool
	declare hasIncompleteType : Type -> #Bool 
	// op hasTypedefType : Type -> #Bool 
	declare hasArithmeticType : Type -> #Bool
	
	op aggregateInfo : List{K} Map Map -> K // first map is for type, second map is for offset
	declare getFieldOffset : #Id K -> #Nat // these expect an aggregateInfo term as second argument
	declare getFieldType : #Id K -> Type
	
	declare isArithBinConversionOp : KLabel -> #Bool 
	declare isArithUnaryOp : KLabel -> #Bool 
	op kpair : K K -> K 
	declare promote : K -> Type // should be K, but is Type for efficiency reasons
	declare argPromote : K -> K
	op extractField : List{K} K #Id -> K // bytes of struct, type, field id
	op allocString : #Nat #String -> K 
	op allocWString : #Nat List{K} -> K 
	op sequencePoint : -> K 
	
	op handleBuiltin : #Id Type -> K 
	
	declare min : Type -> #Int // [memo]
	declare max : Type -> #Int // [memo]
	op alloc : K K -> K // should be K K 
	op realloc : K K K K -> K // should be K K 
	
	// these are also used by compound literals
	op initializerValue : #Id Type K -> KResult 
	op figureInitializer : #Id K K -> K [metadata "strict=(2)"] // id, type, initializer
	
		
	op append : #Nat #Nat Value -> K // appends a new subobject to a current object.  this is unsafe and should only be used for variadic functions
	op deleteBlock : #Nat -> K // deletes the base object from memory, given a location
	op deleteSizedBlock : #Nat #Nat -> K // deletes the base object from memory, given a location and it size (as a check)
	
	declare isConcreteNumber : #Int -> #Bool 
	declare _in_ : K List -> #Bool 
endkm

kmod COMMON-C-SETTINGS is
	including COMMON-SEMANTIC-SYNTAX 
	
	// S 6.2.5 p.35 i.15.  "The implementation shall define char to have the same range, representation, and behavior as either signed char or unsigned char.  37)... Irrespective of the choice made, char is a separate type from the other two and is not compatible with either"
	// fixme I'm not sure what consequence being a separate type entails, so for now it will just be rewritten to the chosen type
	rule char => signed-char [structural anywhere]
	// rule char => kccSettingSimpleType("_KCC_CHAR_TYPE")

	declare numBitsPerByte : -> #NzNat 
	declare numBytes : Type -> #Nat // [memo] 
	declare numBits : Type -> #Nat // [memo] 

	define [numBitsPerByte]: numBitsPerByte => 8 [structural]
	// rule [numBitsPerByte]: numBitsPerByte => kccSettingNzNat("_KCC_BITS_PER_BYTE") [structural]
	
	define [numBytes-bool]: numBytes(t(_, bool)) => 1 [structural]
	define [numBytes-signed-char]: numBytes(t(_, signed-char)) => 1 [structural]
	define [numBytes-short-int]: numBytes(t(_, short-int)) => 2 [structural]
	// rule [numBytes-short-int]: numBytes(t(_, short-int)) => kccSettingNzNat("_KCC_SIZEOF_SHORT") [structural]
	define [numBytes-int]: numBytes(t(_, int)) => 4 [structural]
	// rule [numBytes-int]: numBytes(t(_, int)) => kccSettingNzNat("_KCC_SIZEOF_INT") [structural]
	define [numBytes-long-int]: numBytes(t(_, long-int)) => 4 [structural]
	// rule [numBytes-long-int]: numBytes(t(_, long-int)) => kccSettingNzNat("_KCC_SIZEOF_LONG") [structural]
	define [numBytes-long-long-int]: numBytes(t(_, long-long-int)) => 8 [structural]
	// rule [numBytes-long-long-int]: numBytes(t(_, long-long-int)) => kccSettingNzNat("_KCC_SIZEOF_LONG_LONG") [structural]
	
	define [numBytes-float]: numBytes(t(_, float)) => 4 [structural]
	define [numBytes-double]: numBytes(t(_, double)) => 8 [structural]
	define [numBytes-long-double]: numBytes(t(_, long-double)) => 16 [structural]
	
	define [numBytes-enum]: numBytes(t(S:Set, enumType(X:#Id))) => numBytes(t(S:Set, int)) [structural]
	
	declare cfg:sizeut : -> Type
	define [cfg-size-t]: cfg:sizeut => t(.Set, unsigned-int) [structural]
	// rule [cfg-size-t]: cfg:sizeut => t(.Set, kccSettingSimpleType("_KCC_SIZE_T")) [structural]
	
	declare cfg:wcharut : -> Type
	define [cfg-wchar-t]: cfg:wcharut => t(.Set, int) [structural]
	// rule [cfg-wchar-t]: cfg:wcharut => t(.Set, kccSettingSimpleType("_KCC_WCHAR_T")) [structural]
	
	declare simpleType : Type -> SimpleType
	define simpleType(t(_, T:K)) => T:K [structural]
	
	declare cfg:largestUnsigned : -> Type 
	define [cfg-largestUnsigned]: cfg:largestUnsigned => t(.Set, unsigned-long-long-int) [structural]

	declare cfg:ptrsize : -> #Nat 
	define [cfg-ptrsize]: cfg:ptrsize => 4 [structural]
	
	declare cfg:ptrdiffut : -> Type 
	define [cfg-ptrdiff-t]: cfg:ptrdiffut => t(.Set, int) [structural]
	
	define [min]: min(t(S:Set, enumType(_:#Id))) => min(t(S:Set, int)) [structural]
	define [max]: max(t(S:Set, enumType(_:#Id))) => max(t(S:Set, int)) [structural]
	
	declare rank : Type -> #Int 
		
	define rank(t(_, bool)) => 0 [structural]
	define rank(t(_, signed-char)) => 1 [structural]
	define rank(t(_, unsigned-char)) => 1 [structural]
	define rank(t(_, short-int)) => 2 [structural]
	define rank(t(_, unsigned-short-int)) => 2 [structural]
	define rank(t(_, int)) => 3 [structural]
	define rank(t(_, unsigned-int)) => 3 [structural]
	define rank(t(_, long-int)) => 4 [structural]
	define rank(t(_, unsigned-long-int)) => 4 [structural]
	define rank(t(_, long-long-int)) => 5 [structural]
	define rank(t(_, unsigned-long-long-int)) => 5 [structural]
	
	define rank(t(S:Set, enumType(_:#Id))) => rank(t(S:Set, int)) [structural]
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
	
	
	rule inc(sym(N:#Nat) +Nat M:#Nat) => sym(N:#Nat +Nat 1) +Nat M:#Nat [structural anywhere]
	rule sNat(sym(N:#Nat) +Nat M:#Nat) => sym(N:#Nat) +Nat (M:#Nat +Nat 1) [structural anywhere]
	rule I:#Int +Int (N:#Nat +Nat sym(M:#Nat))
		=> absInt(N:#Nat +Int I:#Int) +Nat sym(M:#Nat) 
		when N:#Nat +Int I:#Int >=Int 0 
		[structural anywhere]

	rule [unknown-loc]: CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc [structural anywhere]

	rule [expression-loc]: ExpressionLoc(K:K, _) => K:K [structural anywhere]

	rule [CodeLoc-k]:
		< k > CodeLoc(K:K, L:CabsLoc) => K:K ...</ k >
		< currentProgramLoc > _ => L:CabsLoc </ currentProgramLoc >
		[structural]
		
		
	/*@ \source[n1570]{\para{6.10.6}{1}}
	A preprocessing directive of the form
	\cdisplay{# pragma pp-tokensoptnew-line}
\broken{where the preprocessing token \cinline{STDC} does not immediately follow pragma in the directive (prior to any macro replacement)} causes the implementation to behave in an implementation-defined manner. The behavior might cause translation to fail or cause the translator or the resulting program to behave in a non-conforming manner. Any such pragma that is not recognized by the implementation is ignored.
	*/
	rule [Pragma]:
		< k > Pragma(_:K) => .K ...</ k >
		[structural]
	// fixme, problem in K:  this rule takes 150 seconds to error
	// rule [Pragma]:
		// < k > Pragma(_:K) => _ ...</ k >
		// [structural]
		
	// rule [Attributes]:
		// < k > Attribute(S:#String, List(L:List{K})) => AttributeValue(S:#String, L:List{K}) ...</ k >
		// [structural]
		
	rule AttributeWrapper(K:K, _) => K:K [structural anywhere]
	
	rule N:#Nat +Nat bito(M:#Nat) => N:#Nat +Nat (M:#Nat /Nat numBitsPerByte) +Nat bito(M:#Nat %Nat numBitsPerByte)
		when M:#Nat >=Nat numBitsPerByte 
		[structural anywhere]
	
	// rule FieldName((Identifier("___missing_field_name") => AnonAggregate)) [structural]
	// rule BitFieldName((Identifier("___missing_field_name") => #NoName), _) [structural]
	rule Identifier("___missing_field_name") => #NoName [structural anywhere]
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
	op eval : K List{K} #String -> Bag
	op callMain : #Nat #Id K -> K
	op incomingArguments : List{K} -> K
	
	op TranslationUnitName : #String -> KLabel
		
endkm
