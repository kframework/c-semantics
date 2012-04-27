kmod COMMON-INCOMING-MODULES is
	including K
	including C-SYNTAX 
	including COMMON-C-CONFIGURATION 
	including K-CONTEXTS 
	
endkm

kmod COMMON-SEMANTIC-SYNTAX is
	including COMMON-INCOMING-MODULES 
	
	syntax BaseValue ::= Nat | Int | Float
	syntax C ::= BaseValue | Type | Value
	syntax KResult ::= Value | Type
	
	// fixme super sketchy
	define true orBool _ => true
	define _ orBool true => true
	define false andBool _ => false
	define _ andBool false => false

	// these are used for runtime settings
	syntax SimpleType ::= "kccSettingSimpleType" "(" String ")" [klabel(kccSettingSimpleType)]
	syntax #NzNat ::= "kccSettingNzNat" "(" String ")" [klabel(kccSettingNzNat)]
	syntax Int ::= "kccSettingInt" "(" String ")" [klabel(kccSettingInt)]
	
	syntax K	 ::= "fromUnion" "(" Id ")" [klabel(fromUnion)]
		
	// Types
	syntax Type ::= "typedDeclaration" "(" Type "," Id ")" [klabel(typedDeclaration)] // would rather this be KResult, but can't get the subsorting to work
	
	syntax K ::= "DeclType" "(" K "," K ")" [metadata "strict=(1)" klabel(DeclType)] // represents a type before canonicalization.  as in "int *x", first arg is "Int", second arg is "PointerType(JustBase)"
	// op 'isTypeResult_ : K -> Bool 
	syntax Set ::= "setOfTypes" [klabel(setOfTypes)] // [memo] 
	
	syntax K ::= "usualArithmeticConversion" "(" Type "," Type ")" [klabel(usualArithmeticConversion)]
	syntax K ::= "callMain-aux" "(" K "," Nat "," Id "," K ")" [metadata "strict=(1)" klabel(callMain-aux)] // having to put this out here so errors can see it
	syntax K ::= "initFunction" "(" K "," K ")" [metadata "strict=()" klabel(initFunction)]
	syntax K ::= "populateFromGlobal" [klabel(populateFromGlobal)] 
	
	syntax K ::= "checkValidLoc" "(" K ")" [klabel(checkValidLoc)]
	syntax K ::= "checkDerefLoc" "(" K ")" [klabel(checkDerefLoc)]
	syntax ListItem ::= "ListItem" "(" BagItem ")" [klabel(ListItem)]
	declare ListToK : List -> K 
	syntax K ::= "Map" "(" Map ")" [klabel(Map)] 
	syntax Nat ::= "piece" "(" Nat "," Nat ")" [klabel(piece)] 
	define 'isInt(piece(_, _)) => true
	
	syntax Nat ::= "unknown" "(" Nat ")" [klabel(unknown)] // [ctor] 
	define 'isInt(unknown(_)) => true
	
	syntax KResult ::= "skipval" [klabel(skipval)]
	syntax K ::= "debug" [klabel(debug)] 
	syntax K ::= "debug-m" "(" K ")" [klabel(debug-m)]
	syntax K ::= "discard" [klabel(discard)] 
	syntax Id ::= "File-Scope" [klabel(File-Scope)] // [ctor] 
	syntax Id ::= "unnamedBitField" [klabel(unnamedBitField)] // [ctor] 
	//syntax Type ::= "bignum" [klabel(bignum)] 

	// define 'isNat(sym(N:Nat) +Int M:Nat) => true
	// define 'isInt(sym(N:Nat) +Int M:Nat) => true
	// define 'isNat((sym(N:Nat) +Int bito(N':Nat)) +Int M:Nat) => true
	// define 'isInt((sym(N:Nat) +Int bito(N':Nat)) +Int M:Nat) => true
	syntax Nat ::= "loc" "(" K "," K "," K ")" [klabel(loc)] // Base, byte offset, bit offset
	define 'isInt(loc(_, _, _)) => true
	// syntax Nat ::= "sym" "(" Nat ")" [klabel(sym)]
	// syntax K ::= "bito" "(" Nat ")" [klabel(bito)]
	
	// fixme maybe if we keep it reduced here, things can go faster
	declare _+bits_ : K K -> K
	define loc(Base:Nat, Offset:Nat, BitOffset:Nat) +bits N:Nat
		=> loc(Base:Nat, Offset:Nat, BitOffset:Nat +Int N:Nat)

	//declare bitoffset : Nat -> Nat 
	//declare byteoffset : Nat -> Nat
	syntax Value ::= "enumItem" "(" Id "," Value ")" [klabel(enumItem)] 
	syntax K ::= "resolveReferences" [klabel(resolveReferences)] 
	
	syntax String ::= "toString" "(" K ")" [klabel(toString)] 
	
	syntax Type ::= "maxType" "(" Type "," Type ")" [klabel(maxType)] 
	
	syntax Nat ::= "bitRange" "(" Nat "," Nat "," Nat ")" [klabel(bitRange)] // original number, from, to inclusive
	
	syntax K ::= "fillToBytes" "(" K ")" [metadata "strict=()" klabel(fillToBytes)] 
	
	syntax Nat ::= "floorLoc" "(" Nat ")" [klabel(floorLoc)] // loc with possible bit offset returning base byte	
	syntax Nat ::= "ceilingLoc" "(" Nat ")" [klabel(ceilingLoc)] // loc with possible bit offset returning upperbounded byte	
	syntax K ::= "readFunction" "(" Nat ")" [klabel(readFunction)] 
	
	declare innerType : Type -> Type
	
	// syntax KResult ::= "AttributeValue" "(" String "," List{K} ")" [klabel(AttributeValue)] 
	
	syntax K ::= "extractBitsFromList" "(" K "," Nat "," Nat ")" [metadata "strict=(1)" klabel(extractBitsFromList)] // data, offset, size in bits
	syntax Id ::= "typedef" "(" Id ")" [klabel(typedef)] 
	syntax Id ::= "unnamed" "(" Nat ")" [klabel(unnamed)] 
	
	syntax Nat ::= "NullPointerConstant" [klabel(NullPointerConstant)] 
	define 'isInt(NullPointerConstant) => true
	
	syntax Nat ::= "NullPointer" [klabel(NullPointer)] 
	define 'isInt(NullPointer) => true
	
	syntax Value ::= "emptyValue" [klabel(emptyValue)] 
	syntax K ::= "allocate" "(" Type "," K ")" [klabel(allocate)]
	
	syntax K ::= "zero" "(" K ")" [klabel(zero)] 
	syntax K ::= "zeroBlock" "(" Nat ")" [klabel(zeroBlock)] 
		
	syntax K ::= "value" "(" K ")" [klabel(value)] 
		
	syntax K ::= "sizeofLocation" "(" K ")" [klabel(sizeofLocation)]
	syntax Type ::= "type" "(" K ")" [klabel(type)] 
	
	syntax K ::= "flush" "(" Nat ")" [klabel(flush)]
	
	syntax K ::= "allocateType" "(" Nat "," Type ")" [klabel(allocateType)] 
	syntax K ::= "allocateTypeIfAbsent" "(" Nat "," Type ")" [klabel(allocateTypeIfAbsent)] 
	syntax K ::= "giveType" "(" Id "," Type ")" [klabel(giveType)] 
	syntax K ::= "addToEnv" "(" Id "," Nat ")" [klabel(addToEnv)] 
	
	syntax K ::= "read" "(" K "," K ")" [metadata "strict=(2)" klabel(read)] // location, type
	syntax K ::= "write" "(" K "," K ")" [metadata "strict=(2)" klabel(write)] // location, value
	syntax K ::= "writeByte" "(" Nat "," K ")" [klabel(writeByte)] 

	declare isTypeCompatible : K K -> Bool 
	
	declare hasBeenPromoted : Type -> Bool
	// syntax Bool ::= "isPromotedInteger" "(" Type ")" [klabel(isPromotedInteger)]
	
	
	syntax Nat ::= "inc" "(" Nat ")" [klabel(inc)] 
	
	define 'isNat(threadId(N:Nat) +Int M:Nat) => true [structural]
	define 'isNat(allocatedDuration +Int M:Nat) => true [structural]
	syntax Nat ::= "threadId" "(" Nat ")" [klabel(threadId)] // used for symbolic locations based on threadid
	syntax Nat ::= "allocatedDuration" [klabel(allocatedDuration)] // fake threadid for above when location is of allocated duration
	// syntax Nat ::= "readOnly" [klabel(readOnly)] // fake threadid for above when location can't be written to
		
	syntax K ::= "initialize" "(" Id "," Type "," K ")" [klabel(initialize)] 
	syntax K ::= "memblock" "(" Bag "," Map ")" [klabel(memblock)] // length and an array from offsets to bytes
	syntax BagItem ::= "mlength" "(" Nat ")" [klabel(mlength)]
	syntax BagItem ::= "mconst" [klabel(mconst)]
	syntax K ::= "makeUnwritable" "(" Nat ")" [klabel(makeUnwritable)]
	syntax K ::= "makeUnwritableSubObject" "(" K ")" [klabel(makeUnwritableSubObject)]
	syntax K ::= "makeUnwritableVar" "(" K ")" [klabel(makeUnwritableVar)]
	context makeUnwritableSubObject((HOLE => peval(HOLE)))
	
	syntax K ::= "listToK" "(" K ")" [klabel(listToK)] 
	syntax K ::= "klistToK" "(" List{K} ")" [klabel(klistToK)] 
	syntax K ::= "UnknownCabsLoc" [klabel(UnknownCabsLoc)] 
	
	
	syntax K ::= "assert" "(" Bool "," Nat ")" [klabel(assert)] // check, error#
	
	// Basic types
	syntax SimpleType ::= "bool"
	syntax SimpleType ::= "void" | "bool" | "char" | "short-int" | "int" | "long-int" | "long-long-int"
	syntax SimpleType ::= "float" | "double" | "long-double"
	syntax SimpleType ::= "signed-char" | "unsigned-char"
	syntax SimpleType ::= "unsigned-short-int" | "unsigned-int" | "unsigned-long-int" | "unsigned-long-long-int"
	syntax SimpleType ::= "no-type" [klabel(no-type)]
	
	syntax Type ::= "t" "(" Set "," SimpleType ")" [klabel(t)]
	/*
	t(S', pointerType(t(S, T:KResult)))
	pointerType(T:KResult)
	S' pointerType(S T:KResult)
	tv(5, T:KResult)
	*/
	
	syntax Bool ::= "isBasicType" "(" K ")" [klabel(isBasicType)]
	
	// Composite types
	syntax SimpleType ::= "enumType" "(" Id ")" [klabel(enumType)] // [ctor] 
	syntax SimpleType ::= "arrayType" "(" Type "," Int ")" [klabel(arrayType)] // [ctor] 
	syntax SimpleType ::= "incompleteArrayType" "(" Type ")" [klabel(incompleteArrayType)] // [ctor] 
	syntax SimpleType ::= "flexibleArrayType" "(" Type ")" [klabel(flexibleArrayType)] // [ctor] 
	syntax SimpleType ::= "bitfieldType" "(" Type "," Nat ")" [klabel(bitfieldType)] // [ctor] 
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
	syntax SimpleType ::= "variadic" [klabel(variadic)] 

	syntax KResult ::= "dataList" "(" List{K} ")" [klabel(dataList)] 
	
	syntax Nat ::= "K2Nat" "(" K ")" [klabel(K2Nat)]
	syntax K ::= "sizeofType" "(" K ")" [metadata "strict=()" klabel(sizeofType)] // generates a tv(size, cfg:sizeut)
	syntax K ::= "bitSizeofType" "(" K ")" [metadata "strict=()" klabel(bitSizeofType)] // needs to be heated to top of K for struct and union types
	syntax K ::= "byteSizeofType" "(" K ")" [metadata "strict=()" klabel(byteSizeofType)] 
	syntax Nat ::= "bitsToBytes" "(" K ")" [klabel(bitsToBytes)] 
	// syntax Expression ::= "MYHOLE" [klabel(MYHOLE)] 
	syntax K ::= "l" "(" KLabel ")" [metadata "wrapper=(builtin)" klabel(l)] 
	declare _contains_ : Set K -> Bool // [memo] 
	
	syntax Set ::= "getModifiers" "(" K ")" [klabel(getModifiers)]
	
	syntax K ::= "AllowWrite" "(" K ")" [metadata "strict=()" klabel(AllowWrite)]
	
	rule AllowWrite(lv(N:Nat, T:KResult)) => lv(N:Nat, stripConst(T:KResult)) [structural anywhere]

	declare stripConst : Type -> Type
	
	define stripConst(t((SetItem(Const) => .Set) _, _)) [structural]
	define 
		stripConst(t(S:Set, T:K)) => t(S:Set, T:K)
		when notBool Const in S:Set
		[structural]
	
	syntax K ::= "bind" "(" List{KResult} "," List{KResult} ")" [klabel(bind)] 
	syntax Value ::= "tv" "(" List{K} "," Type ")" [metadata "latex=(renameTo \\ensuremath{{_}\\mathop{:}{_}})" klabel(tv)]
	syntax Value ::= "lv" "(" List{K} "," Type ")" [klabel(lv)]
	syntax K ::= "concretize" "(" Type "," K ")" [metadata "strict=(2)" klabel(concretize)] 
	syntax Value ::= "functionObject" "(" Id "," Type "," K ")" [klabel(functionObject)] 
	syntax Value ::= "functionPrototype" "(" Id "," Type ")" [klabel(functionPrototype)] 
	
	syntax Char ::= "firstChar" "(" String ")" [klabel(firstChar)] 
	syntax Char ::= "nthChar" "(" String "," Nat ")" [klabel(nthChar)] 
	syntax String ::= "butFirstChar" "(" String ")" [klabel(butFirstChar)] 
	syntax Nat ::= "charToAscii" "(" String ")" [klabel(charToAscii)] 
	syntax Char ::= "stringToChar" "(" String ")" [klabel(stringToChar)] 
	syntax Nat ::= "asciiCharString" "(" String ")" [klabel(asciiCharString)] 
	
	
	
	declare _to_ : Nat Nat -> List{K} 
	declare cast : K K -> K [metadata "strict=()"] // as described in 6.3 // totype, fromvalue
	context cast(_, (HOLE => reval(HOLE)))
	declare arithInterpret : Type BaseValue -> K // interpret the result of arithmetic as in 6.5.4
	declare interpret : Type K -> K // interpret the values of reading from mem
	declare leftShiftInterpret : Type BaseValue K -> K 
	declare rightShiftInterpret : Type BaseValue -> K 
	
	// syntax Set ::= "integerTypes" [klabel(integerTypes)] // [memo] 
	syntax Set ::= "unsignedIntegerTypes" [klabel(unsignedIntegerTypes)] // [memo] 
	syntax Set ::= "signedIntegerTypes" [klabel(signedIntegerTypes)] // [memo] 
	declare hasIntegerType : Type -> Bool // [memo] 
	declare isFloatType : Type -> Bool // [memo] 
	declare hasUnsignedIntegerType : Type -> Bool // [memo] 
	declare hasSignedIntegerType : Type -> Bool // [memo] 
	
	syntax K ::= "typeof" "(" K ")" [klabel(typeof)] 
	syntax K ::= "writeToFD" "(" Nat "," Nat ")" [klabel(writeToFD)] 
	syntax K ::= "writeToFD" "(" Nat "," String ")" [klabel(writeToFD)] 
	syntax K ::= "readFromFD" "(" Nat ")" [klabel(readFromFD)] 
	syntax K ::= "readFromFD" "(" Nat "," Nat ")" [klabel(readFromFD)] 

	syntax K ::= "calculateGotoMap" "(" Id "," K ")" [klabel(calculateGotoMap)] 
	
	declare isCharType : Type -> Bool 
	declare isWCharType : Type -> Bool 
	// fixme make sure i use this everywhere instead of T:BaseType
	// op isABaseType_ : K -> Bool 
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
	// syntax Bool ::= "hasTypedefType" "(" Type ")" [klabel(hasTypedefType)] 
	declare isArithmeticType : Type -> Bool
	
	syntax K ::= "aggregateInfo" "(" List{K} "," Map "," Map ")" [klabel(aggregateInfo)] // first map is for type, second map is for offset
	declare getFieldOffset : Id K -> Nat // these expect an aggregateInfo term as second argument
	declare getFieldType : Id K -> Type
	
	declare isArithBinConversionOp : KLabel -> Bool 
	declare isArithUnaryOp : KLabel -> Bool 
	syntax K ::= "kpair" "(" K "," K ")" [klabel(kpair)] 
	declare promote : K -> Type // should be K, but is Type for efficiency reasons
	declare argPromote : K -> K
	syntax K ::= "extractField" "(" List{K} "," K "," Id ")" [klabel(extractField)] // bytes of struct, type, field id
	syntax K ::= "allocString" "(" Nat "," String ")" [klabel(allocString)] 
	syntax K ::= "allocWString" "(" Nat "," List{K} ")" [klabel(allocWString)] 
	syntax K ::= "sequencePoint" [klabel(sequencePoint)] 
	
	syntax K ::= "handleBuiltin" "(" Id "," Type ")" [klabel(handleBuiltin)] 
	
	declare min : Type -> Int // [memo]
	declare max : Type -> Int // [memo]
	syntax K ::= "alloc" "(" K "," K ")" [klabel(alloc)] // should be K K 
	syntax K ::= "realloc" "(" K "," K "," K "," K ")" [klabel(realloc)] // should be K K 
	
	// these are also used by compound literals
	syntax KResult ::= "initializerValue" "(" Id "," Type "," K ")" [klabel(initializerValue)] 
	syntax K ::= "figureInitializer" "(" Id "," K "," K ")" [metadata "strict=(2)" klabel(figureInitializer)] // id, type, initializer
	
		
	syntax K ::= "append" "(" Nat "," Nat "," Value ")" [klabel(append)] // appends a new subobject to a current object.  this is unsafe and should only be used for variadic functions
	syntax K ::= "deleteBlock" "(" Nat ")" [klabel(deleteBlock)] // deletes the base object from memory, given a location
	syntax K ::= "deleteSizedBlock" "(" Nat "," Nat ")" [klabel(deleteSizedBlock)] // deletes the base object from memory, given a location and it size (as a check)
	
	declare isConcreteNumber : Int -> Bool 
	//declare _in_ : K List -> Bool 
endkm

kmod COMMON-C-SETTINGS is
	including COMMON-SEMANTIC-SYNTAX 
	
	// S 6.2.5 p.35 i.15.  "The implementation shall define char to have the same range, representation, and behavior as either signed char or unsigned char.  37)... Irrespective of the choice made, char is a separate type from the other two and is not compatible with either"
	// fixme I'm not sure what consequence being a separate type entails, so for now it will just be rewritten to the chosen type
	rule char => signed-char [structural anywhere]
	// rule char => kccSettingSimpleType("_KCC_CHAR_TYPE")

	declare numBitsPerByte : -> #NzNat 
	declare numBytes : Type -> Nat // [memo] 
	declare numBits : Type -> Nat // [memo] 

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
	
	define [numBytes-enum]: numBytes(t(S:Set, enumType(X:Id))) => numBytes(t(S:Set, int)) [structural]
	
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

	declare cfg:ptrsize : -> Nat 
	define [cfg-ptrsize]: cfg:ptrsize => 4 [structural]
	
	declare cfg:ptrdiffut : -> Type 
	define [cfg-ptrdiff-t]: cfg:ptrdiffut => t(.Set, int) [structural]
	
	define [min]: min(t(S:Set, enumType(_:Id))) => min(t(S:Set, int)) [structural]
	define [max]: max(t(S:Set, enumType(_:Id))) => max(t(S:Set, int)) [structural]
	
	declare rank : Type -> Int 
	
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
	
	define loc(Base:Nat, ByOff:Nat, BiOff:Nat) +Int Offset:Int
		=> loc(Base:Nat, ByOff:Nat +Int Offset:Int, BiOff:Nat)
	// define (sym(Base:Nat) +Int Offset:Int) +Int Offset':Int 
		// => sym(Base:Nat) +Int (Offset:Int +Int Offset':Int)
		// [structural]
	// define (sym(Base:Nat) +Int Offset:Int) +Int bito(I:Int)
		// => (sym(Base:Nat) +Int bito(I:Int)) +Int Offset:Int
		// [structural]
	// define loc(Base:Nat, ByOff:Nat, BiOff:Nat) +Int bito(Offset:Int)
		// => loc(Base:Nat, ByOff:Nat, BiOff:Nat +Int Offset:Int)
	define (threadId(N:Int) +Int M:Int) +Int N':Int
		=> threadId(N:Int) +Int (M:Int +Int N':Int)
	define (allocatedDuration +Int M:Int) +Int N':Int
		=> allocatedDuration +Int (M:Int +Int N':Int)
	define inc(loc(N:Nat, M:Nat, M':Nat)) => loc(N:Nat +Int 1, M:Nat, M':Nat)
	// rule I:Int +Int (N:Nat +Int sym(M:Nat))
		// => sym(M:Nat) +Int absInt(N:Nat +Int I:Int)
		// when N:Nat +Int I:Int >=Int 0 
		// [structural anywhere]

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
		// < k > Attribute(S:String, List(L:List{K})) => AttributeValue(S:String, L:List{K}) ...</ k >
		// [structural]
		
	rule AttributeWrapper(K:K, _) => K:K [structural anywhere]
	
	// rule N:Nat +Int bito(M:Nat) => N:Nat +Int (M:Nat /Int numBitsPerByte) +Int bito(M:Nat %Int numBitsPerByte)
		// when M:Nat >=Int numBitsPerByte 
		// [structural anywhere]
	define loc(Base:Nat, Offset:Nat, BitOffset:Nat)
		=> loc(Base:Nat, Offset:Nat +Int BitOffset:Nat /Int numBitsPerByte, BitOffset:Nat %Int numBitsPerByte)
		when BitOffset:Nat >=Int numBitsPerByte
	
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
	
	syntax Bag ::= "eval" "(" K ")" [klabel(eval)] 
	syntax Bag ::= "eval" "(" K "," List{K} "," String "," Int ")" [klabel(eval)]
	syntax K ::= "callMain" "(" Nat "," Id "," K ")" [klabel(callMain)]
	syntax K ::= "incomingArguments" "(" List{K} ")" [klabel(incomingArguments)]
	
	syntax KLabel ::= "TranslationUnitName" "(" String ")" [klabel(TranslationUnitName)]
		
endkm
