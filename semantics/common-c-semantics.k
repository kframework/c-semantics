module COMMON-INCOMING-MODULES is
	including K
	including C-SYNTAX 
	including COMMON-C-CONFIGURATION 
	including K-CONTEXTS 
	
end module

module COMMON-SEMANTIC-SYNTAX is
	including COMMON-INCOMING-MODULES 
	
	syntax BaseValue ::= Int | Float
	syntax C ::= BaseValue | Type | Value
	syntax KResult ::= Value | Type
	
	// fixme super sketchy
	define true orBool _ => true
	define _ orBool true => true
	define false andBool _ => false
	define _ andBool false => false

	// these are used for runtime settings
	// syntax SimpleType ::= "kccSettingSimpleType" "(" String ")" [klabel(kccSettingSimpleType)]
	// syntax #NzNat ::= "kccSettingNzNat" "(" String ")" [klabel(kccSettingNzNat)]
	// syntax Int ::= "kccSettingInt" "(" String ")" [klabel(kccSettingInt)]
	
	syntax K	 ::= "fromUnion" "(" Id ")" [klabel(fromUnion)]
		
	// Types
	syntax Type ::= "typedDeclaration" "(" Type "," Id ")" [latex "\terminal{typedDecl}\!({#1},{#2}\!)" klabel(typedDeclaration)] // would rather this be KResult, but can't get the subsorting to work
	
	syntax K ::= "DeclType" "(" K "," K ")" [strict(1) klabel(DeclType)] // represents a type before canonicalization.  as in "int *x", first arg is "Int", second arg is "PointerType(JustBase)"
	// op 'isTypeResult_ : K -> Bool 
	syntax Set ::= "setOfTypes"
	
	syntax K ::= "usualArithmeticConversion" "(" Type "," Type ")" [klabel(usualArithmeticConversion)]
	syntax K ::= "callMain-aux" "(" K "," Int "," Id "," K ")" [strict(1) klabel(callMain-aux)] // having to put this out here so errors can see it
	syntax K ::= "initFunction" "(" K "," K ")" [strict klabel(initFunction)]
	syntax K ::= "populateFromGlobal"
	
	syntax K ::= "checkValidLoc" "(" K ")" [klabel(checkValidLoc)]
	syntax K ::= "checkDerefLoc" "(" K ")" [klabel(checkDerefLoc)]
	syntax ListItem ::= "ListItem" "(" Bag ")" [klabel(ListItem)]
	declare ListToK : List -> K 
	syntax K ::= "Map" "(" Map ")" [klabel(Map)] 
	syntax Int ::= "piece" "(" Int "," Int ")" [klabel(piece)] 
	define 'isInt(piece(_, _)) => true
	
	syntax Int ::= "unknown" "(" Int ")" [klabel(unknown)] // [ctor] 
	define 'isInt(unknown(_)) => true
	
	syntax KResult ::= "skipval"
	syntax K ::= "debug"
	syntax K ::= "debug-m" "(" K ")" [klabel(debug-m)]
	syntax K ::= "discard"
	syntax Id ::= "File-Scope" // [ctor] 
	syntax Id ::= "unnamedBitField" // [ctor] 

	syntax Int ::= "loc" "(" K "," K "," K ")" [klabel(loc)] // Base, byte offset, bit offset
	define 'isInt(loc(_, _, _)) => true
	
	// fixme maybe if we keep it reduced here, things can go faster
	declare _+bits_ : K K -> K
	define loc(Base:Int, Offset:Int, BitOffset:Int) +bits N:Int
		=> loc(Base:Int, Offset:Int, BitOffset:Int +Int N:Int)

	//declare bitoffset : Int -> Int 
	//declare byteoffset : Int -> Int
	syntax Value ::= "enumItem" "(" Id "," Value ")" [klabel(enumItem)] 
	syntax K ::= "resolveReferences"
	
	syntax String ::= "toString" "(" K ")" [klabel(toString)] 
	
	syntax Type ::= "maxType" "(" Type "," Type ")" [klabel(maxType)] 
	
	syntax Int ::= "bitRange" "(" Int "," Int "," Int ")" [klabel(bitRange)] // original number, from, to inclusive
	
	syntax K ::= "fillToBytes" "(" K ")" [strict klabel(fillToBytes)] 
	
	syntax Int ::= "floorLoc" "(" Int ")" [klabel(floorLoc)] // loc with possible bit offset returning base byte	
	syntax Int ::= "ceilingLoc" "(" Int ")" [klabel(ceilingLoc)] // loc with possible bit offset returning upperbounded byte	
	syntax K ::= "readFunction" "(" Int ")" [klabel(readFunction)] 
	
	declare innerType : Type -> Type
	
	// syntax KResult ::= "AttributeValue" "(" String "," List{K} ")" [klabel(AttributeValue)] 
	
	syntax K ::= "extractBitsFromList" "(" K "," Int "," Int ")" [strict(1) klabel(extractBitsFromList)] // data, offset, size in bits
	syntax Id ::= "typedef" "(" Id ")" [klabel(typedef)] 
	syntax Id ::= "unnamed" "(" Int ")" [klabel(unnamed)] 
	
	syntax Int ::= "NullPointerConstant" [klabel(NullPointerConstant)] 
	define 'isInt(NullPointerConstant) => true
	
	syntax Int ::= "NullPointer"
	define 'isInt(NullPointer) => true
	
	syntax Value ::= "emptyValue" [klabel(emptyValue)] 
	syntax K ::= "allocate" "(" Type "," K ")" [klabel(allocate)]
	
	syntax K ::= "zero" "(" K ")" [klabel(zero)] 
	syntax K ::= "zeroBlock" "(" Int ")" [klabel(zeroBlock)] 
		
	syntax K ::= "value" "(" K ")" [klabel(value)] 
		
	syntax K ::= "sizeofLocation" "(" K ")" [klabel(sizeofLocation)]
	syntax Type ::= "type" "(" K ")" [klabel(type)] 
	
	syntax K ::= "flush" "(" Int ")" [klabel(flush)]
	
	syntax K ::= "allocateType" "(" Int "," Type ")" [klabel(allocateType)] 
	syntax K ::= "allocateTypeIfAbsent" "(" Int "," Type ")" [klabel(allocateTypeIfAbsent)] 
	syntax K ::= "giveType" "(" Id "," Type ")" [klabel(giveType)] 
	syntax K ::= "addToEnv" "(" Id "," Int ")" [klabel(addToEnv)] 
	
	syntax K ::= "read" "(" K "," K ")" [strict(2) klabel(read)] // location, type
	syntax K ::= "write" "(" K "," K ")" [strict(2) klabel(write)] // location, value
	syntax K ::= "writeByte" "(" Int "," K ")" [klabel(writeByte)] 

	declare isTypeCompatible : K K -> Bool 
	
	declare isPromoted : Type -> Bool
	// syntax Bool ::= "isPromotedInteger" "(" Type ")" [klabel(isPromotedInteger)]
	
	
	syntax Int ::= "inc" "(" Int ")" [klabel(inc)] 
	
	define 'isInt(threadId(N:Int) +Int M:Int) => true
	define 'isInt(allocatedDuration +Int M:Int) => true
	syntax Int ::= "threadId" "(" Int ")" [klabel(threadId)] // used for symbolic locations based on threadid
	syntax Int ::= "allocatedDuration" [klabel(allocatedDuration)] // fake threadid for above when location is of allocated duration
	// syntax Int ::= "readOnly" [klabel(readOnly)] // fake threadid for above when location can't be written to
		
	syntax K ::= "initialize" "(" Id "," Type "," K ")" [klabel(initialize)] 
	// syntax K ::= "memblock" "(" Bag "," Map ")" [klabel(memblock)] // length and an array from offsets to bytes
	syntax BagItem ::= "mlength" "(" Int ")" [klabel(mlength)]
	syntax BagItem ::= "mconst"
	syntax K ::= "makeUnwritable" "(" Int ")" [klabel(makeUnwritable)]
	syntax K ::= "makeUnwritableSubObject" "(" K ")" [klabel(makeUnwritableSubObject)]
	syntax K ::= "makeUnwritableVar" "(" K ")" [klabel(makeUnwritableVar)]
	context makeUnwritableSubObject((HOLE => peval(HOLE)))
	
	syntax K ::= "listToK" "(" K ")" [klabel(listToK)] 
	syntax K ::= "klistToK" "(" List{K} ")" [klabel(klistToK)] 
	syntax K ::= "UnknownCabsLoc"
	
	
	syntax K ::= "assert" "(" Bool "," Int ")" [klabel(assert)] // check, error#
	
	// Basic types
	syntax SimpleType ::= "bool"
	syntax SimpleType ::= "void" | "bool" | "char" | "short-int" | "int" | "long-int" | "long-long-int"
	syntax SimpleType ::= "float" | "double" | "long-double"
	syntax SimpleType ::= "signed-char" | "unsigned-char"
	syntax SimpleType ::= "unsigned-short-int" | "unsigned-int" | "unsigned-long-int" | "unsigned-long-long-int"
	syntax SimpleType ::= "no-type"
	
	syntax Type ::= "t" "(" Set "," SimpleType ")" [klabel(t)]
	
	syntax Bool ::= "isBasicType" "(" K ")" [klabel(isBasicType)]
	
	// Composite types
	syntax SimpleType ::= "enumType" "(" Id ")" [klabel(enumType)] // [ctor] 
	syntax SimpleType ::= "arrayType" "(" Type "," Int ")" [klabel(arrayType)] // [ctor] 
	syntax SimpleType ::= "incompleteArrayType" "(" Type ")" [klabel(incompleteArrayType)] // [ctor] 
	syntax SimpleType ::= "flexibleArrayType" "(" Type ")" [klabel(flexibleArrayType)] // [ctor] 
	syntax SimpleType ::= "bitfieldType" "(" Type "," Int ")" [klabel(bitfieldType)] // [ctor] 
	syntax SimpleType ::= "functionType" "(" Type "," List{KResult} ")" [klabel(functionType)] // [ctor] 
	syntax SimpleType ::= "pointerType" "(" Type ")" [klabel(pointerType)] // [ctor] 
	syntax SimpleType ::= "structType" "(" Id ")" [klabel(structType)] // [ctor] 
	syntax SimpleType ::= "unionType" "(" Id ")" [klabel(unionType)] // [ctor] 
	syntax SimpleType ::= "qualifiedType" "(" Type "," K ")" [klabel(qualifiedType)] // [ctor]
	
	declare unqualifyType : K -> Type // takes a type, but sometimes things like maps give K
	declare removeStorageSpecifiers : K -> Type
	
	// these aren't real types, but are values that can appear in type contexts
	syntax SimpleType ::= "prototype" "(" Type ")" [klabel(prototype)] 
	syntax SimpleType ::= "typedefType" "(" Id "," Type ")" [klabel(typedefType)] 
	syntax SimpleType ::= "variadic"

	syntax KResult ::= "dataList" "(" List{K} ")" [klabel(dataList)] 
	
	// syntax Int ::= "K2Int" "(" K ")" [klabel(K2Int)]
	syntax K ::= "sizeofType" "(" K ")" [strict klabel(sizeofType)] // generates a tv(size, cfg:sizeut)
	syntax K ::= "bitSizeofType" "(" K ")" [strict klabel(bitSizeofType)] // needs to be heated to top of K for struct and union types
	syntax K ::= "byteSizeofType" "(" K ")" [strict klabel(byteSizeofType)] 
	syntax Int ::= "bitsToBytes" "(" K ")" [klabel(bitsToBytes)] 
	syntax K ::= "l" "(" KLabel ")" [klabel(l)]
	// metadata "wrapper=(builtin)"
	declare _contains_ : Set K -> Bool
	
	syntax Set ::= "assignmentLabels"
	macro 
		assignmentLabels = Set(
			l('_:=_),, l('_*=_),, l('_/=_),, l('_%=_),, l('_+=_),, l('_-=_),, 
			l('_<<=_),, l('_>>=_),, l('_&=_),, l('_^=_),, l('_|=_)
		)
	
	syntax Set ::= "getModifiers" "(" K ")" [klabel(getModifiers)]
	
	syntax K ::= "AllowWrite" "(" K ")" [strict klabel(AllowWrite)]
	
	rule AllowWrite(lv(N:Int, T:KResult)) => lv(N:Int, stripConst(T:KResult)) [structural anywhere]

	declare stripConst : Type -> Type
	
	define stripConst(t((SetItem(Const) => .Set) _, _))
	define 
		stripConst(t(S:Set, T:K)) => t(S:Set, T:K)
		when notBool Const in S:Set
		[structural]
	
	syntax K ::= "bind" "(" List{KResult} "," List{KResult} ")" [klabel(bind)] 
	syntax Value ::= "tv" "(" List{K} "," Type ")" [metadata "latex=(renameTo \\ensuremath{{_}\\mathop{:}{_}})" klabel(tv)]
	syntax Value ::= "lv" "(" List{K} "," Type ")" [klabel(lv)]
	syntax K ::= "concretize" "(" Type "," K ")" [strict(2) klabel(concretize)] 
	syntax Value ::= "functionObject" "(" Id "," Type "," K ")" [klabel(functionObject)] 
	syntax Value ::= "functionPrototype" "(" Id "," Type ")" [klabel(functionPrototype)] 
	
	syntax Char ::= "firstChar" "(" String ")" [klabel(firstChar)] 
	syntax Char ::= "nthChar" "(" String "," Int ")" [klabel(nthChar)] 
	syntax String ::= "butFirstChar" "(" String ")" [klabel(butFirstChar)] 
	syntax Int ::= "charToAscii" "(" String ")" [klabel(charToAscii)] 
	syntax Char ::= "stringToChar" "(" String ")" [klabel(stringToChar)] 
	syntax Int ::= "asciiCharString" "(" String ")" [klabel(asciiCharString)] 
	
	
	
	declare _to_ : Int Int -> List{K} 
	declare cast : K K -> K [strict] // as described in 6.3 // totype, fromvalue
	context cast(_, (HOLE => reval(HOLE)))
	declare arithInterpret : Type BaseValue -> K // interpret the result of arithmetic as in 6.5.4
	declare interpret : Type K -> K // interpret the values of reading from mem
	
	// syntax Set ::= "integerTypes" [klabel(integerTypes)]
	syntax Set ::= "unsignedIntegerTypes" [klabel(unsignedIntegerTypes)]
	syntax Set ::= "signedIntegerTypes" [klabel(signedIntegerTypes)]
	declare hasIntegerType : Type -> Bool
	declare isFloatType : Type -> Bool
	declare hasUnsignedIntegerType : Type -> Bool
	declare hasSignedIntegerType : Type -> Bool
	
	syntax K ::= "typeof" "(" K ")" [klabel(typeof)] 
	syntax K ::= "writeToFD" "(" Int "," Int ")" [klabel(writeToFD)] 
	syntax K ::= "writeToFD" "(" Int "," String ")" [klabel(writeToFD)] 
	syntax K ::= "readFromFD" "(" Int ")" [klabel(readFromFD)] 
	syntax K ::= "readFromFD" "(" Int "," Int ")" [klabel(readFromFD)] 

	syntax K ::= "calculateGotoMap" "(" Id "," K ")" [klabel(calculateGotoMap)] 
	
	declare isCharType : Type -> Bool 
	declare isWCharType : Type -> Bool 
	declare isPointerType : Type -> Bool 
	declare isArrayType : Type -> Bool 
	declare isBoolType : Type -> Bool 
	declare isStructType : Type -> Bool 
	declare isUnionType : Type -> Bool 
	declare isAggregateType : Type -> Bool 
	declare isFunctionType : Type -> Bool 
	declare isFunctionPointerType : Type -> Bool 
	declare isBitfieldType : Type -> Bool 
	declare isExternType : Type -> Bool 
	declare isStaticType : Type -> Bool 
	declare isConstType : Type -> Bool
	declare isIncompleteType : Type -> Bool 
	declare isArithmeticType : Type -> Bool
	
	syntax K ::= "aggregateInfo" "(" List{K} "," Map "," Map ")" [klabel(aggregateInfo)] // first map is for type, second map is for offset
	declare getFieldOffset : Id K -> Int // these expect an aggregateInfo term as second argument
	declare getFieldType : Id K -> Type
	
	declare isArithBinConversionOp : KLabel -> Bool 
	declare isArithUnaryOp : KLabel -> Bool 
	syntax K ::= "kpair" "(" K "," K ")" [klabel(kpair)] 
	declare promote : K -> Type // should be K, but is Type for efficiency reasons
	declare argPromote : K -> K
	syntax K ::= "extractField" "(" List{K} "," K "," Id ")" [klabel(extractField)] // bytes of struct, type, field id
	syntax K ::= "allocString" "(" Int "," String ")" [klabel(allocString)] 
	syntax K ::= "allocWString" "(" Int "," List{K} ")" [klabel(allocWString)] 
	syntax K ::= "sequencePoint"
	
	syntax K ::= "handleBuiltin" "(" Id "," Type ")" [klabel(handleBuiltin)] 
	
	declare min : Type -> Int
	declare max : Type -> Int
	syntax K ::= "alloc" "(" K "," K ")" [klabel(alloc)] // should be K K 
	syntax K ::= "realloc" "(" K "," K "," K "," K ")" [klabel(realloc)] // should be K K 
	
	// these are also used by compound literals
	syntax KResult ::= "initValue" "(" Id "," Type "," K ")" [klabel(initValue)] 
	syntax K ::= "figureInit" "(" Id "," K "," K ")" [strict(2) klabel(figureInit)] // id, type, initializer
	
		
	syntax K ::= "append" "(" Int "," Int "," Value ")" [klabel(append)] // appends a new subobject to a current object.  this is unsafe and should only be used for variadic functions
	syntax K ::= "deleteBlock" "(" Int ")" [klabel(deleteBlock)] // deletes the base object from memory, given a location
	syntax K ::= "deleteSizedBlock" "(" Int "," Int ")" [klabel(deleteSizedBlock)] // deletes the base object from memory, given a location and it size (as a check)
	
	declare isConcreteNumber : Int -> Bool
end module

module COMMON-C-SETTINGS is
	including COMMON-SEMANTIC-SYNTAX 
	
	// S 6.2.5 p.35 i.15.  "The implementation shall define char to have the same range, representation, and behavior as either signed char or unsigned char.  37)... Irrespective of the choice made, char is a separate type from the other two and is not compatible with either"
	// fixme I'm not sure what consequence being a separate type entails, so for now it will just be rewritten to the chosen type
	rule char => signed-char [structural anywhere]

	declare numBitsPerByte : -> Int
	declare numBytes : Type -> Int
	declare numBits : Type -> Int

	define [numBitsPerByte]: numBitsPerByte => 8
	
	define [numBytes-bool]: numBytes(t(_, bool)) => 1
	define [numBytes-signed-char]: numBytes(t(_, signed-char)) => 1
	define [numBytes-short-int]: numBytes(t(_, short-int)) => 2
	define [numBytes-int]: numBytes(t(_, int)) => 4
	define [numBytes-long-int]: numBytes(t(_, long-int)) => 4
	define [numBytes-long-long-int]: numBytes(t(_, long-long-int)) => 8
	
	define [numBytes-float]: numBytes(t(_, float)) => 4
	define [numBytes-double]: numBytes(t(_, double)) => 8
	define [numBytes-long-double]: numBytes(t(_, long-double)) => 16
	
	define [numBytes-enum]: numBytes(t(S:Set, enumType(X:Id))) => numBytes(t(S:Set, int))
	
	declare cfg:mtxPlain : -> Int
	define [cfg-mtxPlain]: cfg:mtxPlain => 0
	
	declare cfg:sizeut : -> Type
	define [cfg-size-t]: cfg:sizeut => t(.Set, unsigned-int)
	
	declare cfg:wcharut : -> Type
	define [cfg-wchar-t]: cfg:wcharut => t(.Set, int)
	
	declare simpleType : Type -> SimpleType
	define simpleType(t(_, T:K)) => T:K
	
	declare cfg:largestUnsigned : -> Type 
	define [cfg-largestUnsigned]: cfg:largestUnsigned => t(.Set, unsigned-long-long-int)

	declare cfg:ptrsize : -> Int 
	define [cfg-ptrsize]: cfg:ptrsize => 4
	
	declare cfg:ptrdiffut : -> Type 
	define [cfg-ptrdiff-t]: cfg:ptrdiffut => t(.Set, int)
	
	define [min]: min(t(S:Set, enumType(_:Id))) => min(t(S:Set, int))
	define [max]: max(t(S:Set, enumType(_:Id))) => max(t(S:Set, int))
	
	declare rank : Type -> Int 
	
end module

// load common-c-sized-operations

module COMMON-NOHELPER-INCLUDE is
	including COMMON-SEMANTIC-SYNTAX
	including COMMON-C-SETTINGS
end module

load common-c-helpers

module COMMON-INCLUDE is
	including COMMON-NOHELPER-INCLUDE
	including COMMON-C-HELPERS
end module

module COMMON-C-SEMANTICS-MISC is
	including COMMON-INCLUDE 
	
	define loc(Base:Int, ByOff:Int, BiOff:Int) +Int Offset:Int
		=> loc(Base:Int, ByOff:Int +Int Offset:Int, BiOff:Int)
	define (threadId(N:Int) +Int M:Int) +Int N':Int
		=> threadId(N:Int) +Int (M:Int +Int N':Int)
	define (allocatedDuration +Int M:Int) +Int N':Int
		=> allocatedDuration +Int (M:Int +Int N':Int)
	define inc(loc(N:Int, M:Int, M':Int)) => loc(N:Int +Int 1, M:Int, M':Int)

	rule [unknown-loc]: CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc [structural anywhere]

	rule [expression-loc]: ExpressionLoc(K:K, _) => K:K [structural anywhere]

	rule [CodeLoc-k]:
		<k> CodeLoc(K:K, L:CabsLoc) => K:K ...</k>
		<currentProgramLoc> _ => L:CabsLoc </currentProgramLoc>
		[structural]
		
		
	/*@ \fromStandard{\source[n1570]{\para{6.10.6}{1}}}{
	A preprocessing directive of the form
	\cdisplay{# pragma pp-tokensoptnew-line}
\broken{where the preprocessing token \cinline{STDC} does not immediately follow pragma in the directive (prior to any macro replacement)} causes the implementation to behave in an implementation-defined manner. The behavior might cause translation to fail or cause the translator or the resulting program to behave in a non-conforming manner. Any such pragma that is not recognized by the implementation is ignored.
	}*/
	rule [Pragma]:
		<k> Pragma(_:K) => .K ...</k>
		[structural]
		
	rule AttributeWrapper(K:K, _) => K:K [structural anywhere]
	
	define loc(Base:Int, Offset:Int, BitOffset:Int)
		=> loc(Base:Int, Offset:Int +Int BitOffset:Int /Int numBitsPerByte, BitOffset:Int %Int numBitsPerByte)
		when BitOffset:Int >=Int numBitsPerByte
	
	rule Identifier("___missing_field_name") => #NoName [structural anywhere]
end module

load common-c-statements
load common-c-expressions
load common-c-declarations
load common-c-typing

module COMMON-C-SEMANTICS is
	including COMMON-INCLUDE 
	
	including COMMON-C-SEMANTICS-MISC
	including COMMON-C-EXPRESSIONS
	including COMMON-C-STATEMENTS
	including COMMON-C-DECLARATIONS
	including COMMON-C-TYPING
	
	syntax Bag ::= "eval" "(" K ")" [klabel(eval)] 
	syntax Bag ::= "eval" "(" K "," List{K} "," String "," Int ")" [klabel(eval)]
	syntax K ::= "callMain" "(" Int "," K ")" [klabel(callMain)]
	syntax K ::= "incomingArguments" "(" List{K} ")" [klabel(incomingArguments)]
	
	syntax KLabel ::= "TranslationUnitName" "(" String ")" [klabel(TranslationUnitName)]
		
end module
