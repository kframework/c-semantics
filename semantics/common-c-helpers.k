require maudeLib/common-c-builtins

kmod COMMON-SEMANTICS-HELPERS-INCLUDE is
	including #COMMON-SEMANTICS-HELPERS-BUILTINS
	including COMMON-NOHELPER-INCLUDE
endkm


kmod COMMON-SEMANTICS-HELPERS-MISC is
	including COMMON-SEMANTICS-HELPERS-INCLUDE

	define sym(N:#Nat) +Nat M:#Nat <Nat sym(N:#Nat) +Nat M':#Nat => true
		when M:#Nat <Nat M':#Nat
		[structural]
	define sym(N:#Nat) +Nat M:#Nat <=Nat sym(N:#Nat) +Nat M':#Nat => true
		when M:#Nat <=Nat M':#Nat
		[structural]
	define sym(N:#Nat) +Nat M:#Nat >Nat sym(N:#Nat) +Nat M':#Nat => true
		when M:#Nat >Nat M':#Nat
		[structural]
	define sym(N:#Nat) +Nat M:#Nat >=Nat sym(N:#Nat) +Nat M':#Nat => true
		when M:#Nat >=Nat M':#Nat
		[structural]
	
	declare simplifyTruth : K -> K
	define simplifyTruth(K:K) => K:K != tv(0, t(.Set, int)) [structural]
	
	
	declare isNotTruthValue : Value -> #Bool
	define isNotTruthValue(tv(V:K, t(_, T:K))) 
		=> T:K =/=Bool int
		orBool (
			V:K =/=Bool 0
			andBool V:K =/=Bool 1 
		)
		[structural]
	
	declare getIdOfDeclaration : K -> K 
	declare getIdOfName : K -> K 
	define getIdOfDeclaration(DeclarationDefinition(InitNameGroup(_, List(K:K)))) => getIdOfName(K:K) [structural]
	define getIdOfName(InitName(K:K, _)) => getIdOfName(K:K) [structural]
	define getIdOfName(SingleName(_, K:K)) => getIdOfName(K:K) [structural] 
	define getIdOfName(Name(X:#Id, _)) => X:#Id [structural]
	
	// this maintains byte order
	declare fillToBytes-aux : K List{K} -> K
	define [fillToBytes-start]:
		fillToBytes(dataList(L:List{K})) 
			=> fillToBytes-aux(dataList(L:List{K}), .List{K}) 
		[structural]
	define [fillToBytes-foundByte]:
		fillToBytes-aux(dataList((L:List{K},, piece(N:#Nat, Len:#Nat))), L':List{K})
			=> fillToBytes-aux(dataList(L:List{K}), (piece(N:#Nat, Len:#Nat),, L':List{K}))
		when Len:#Nat ==Bool numBitsPerByte
		[structural]
	
	define [fillToBytes-addBit]:
		fillToBytes-aux(dataList(piece(N:#Nat, Len:#Nat)), L':List{K})
			=> fillToBytes-aux(dataList((piece(0, 1),, piece(N:#Nat, Len:#Nat))), L':List{K})
		when Len:#Nat <Nat numBitsPerByte
		[structural]
		
	define [fillToBytes-combineBits]:
		fillToBytes-aux(dataList((L:List{K},, piece(N:#Nat, Len:#Nat),, piece(N':#Nat, Len':#Nat))), L':List{K})
			=> fillToBytes-aux(dataList((L:List{K},, piece(_bit::_(piece(N:#Nat, Len:#Nat), piece(N':#Nat, Len':#Nat)), Len:#Nat +Nat Len':#Nat))), L':List{K})
		when Len:#Nat +Nat Len':#Nat <=Nat numBitsPerByte
		[structural]
				
	define [fillToBytes-done]:
		fillToBytes-aux(dataList(.List{K}), L:List{K})
			=> dataList(L:List{K})
		[structural]
		
	// coallesce bitranges that are adjacent
	define _bit::_(piece(bitRange(N:#Nat, sNat(To:#Nat), To':#Nat), Len:#Nat), piece(bitRange(N:#Nat, From:#Nat, To:#Nat), Len':#Nat))
		=> piece(bitRange(N:#Nat, From:#Nat, To':#Nat), Len:#Nat +Nat Len':#Nat)
		when Len:#Nat +Nat Len':#Nat <=Nat numBitsPerByte
		[structural]
	
	define piece(N:#Nat bit:: N':#Nat, Len:#Nat) bit:: piece(N'':#Nat, Len':#Nat)
		=> piece(N:#Nat bit:: N':#Nat bit:: piece(N'':#Nat, Len':#Nat), Len:#Nat +Nat Len':#Nat)
		[structural]

	define piece(N'':#Nat, Len':#Nat) bit:: piece(N:#Nat bit:: N':#Nat, Len:#Nat)
		=> piece(piece(N'':#Nat, Len':#Nat) bit:: N:#Nat bit:: N':#Nat, Len:#Nat +Nat Len':#Nat)
		[structural]

	define bitRange(N:#Nat bit:: piece(_:#Nat, Len:#Nat), Pos:#Nat, Pos:#Nat)
		=> bitRange(N:#Nat, absInt(Pos:#Nat -Int Len:#Nat), absInt(Pos:#Nat -Int Len:#Nat))
		when Pos:#Nat >Nat 0
		andBool Pos:#Nat -Int Len:#Nat >=Int 0
		[structural]
		
	define bitRange(_:#Nat bit:: piece(N:#Nat, 1), 0, 0) => piece(N:#Nat, 1) [structural]
	define bitRange(piece(N:#Nat, 1), 0, 0) => piece(N:#Nat, 1) [structural]
		
	define bitRange(piece(bitRange(N:#Nat, Start:#Nat, End:#Nat), Len:#Nat), 0, 0)
		=> bitRange(piece(bitRange(N:#Nat, Start:#Nat, Start:#Nat), 1), 0, 0)
		when Start:#Nat +Nat Len:#Nat ==Bool sNat(End:#Nat)
		[structural]
	
	define bitRange(N:#Nat, Pos:#Nat, Pos:#Nat) => 1 &Nat (N:#Nat >>Nat Pos:#Nat)
		when N:#Nat >=Nat 0
		[structural]
	define bitRange(piece(N:#Nat, 1), Pos:#Nat, Pos:#Nat) => 1 &Nat (N:#Nat >>Nat Pos:#Nat)
		when N:#Nat >=Nat 0
		[structural]
		
	define bitRange(N:#Nat, 0, To:#Nat) => N:#Nat
		when sNat(To:#Nat) ==Bool numBitsPerByte
		[structural]
	
	define bitRange(_:#Nat bit:: piece(N:#Nat, Len:#Nat), Start:#Nat, End:#Nat)
		=> bitRange(piece(N:#Nat, Len:#Nat), Start:#Nat, End:#Nat)
		when sNat(End:#Nat) <=Nat Len:#Nat
		[structural]
	
	define bitRange(piece(N:#Nat, sNat(End:#Nat)), 0, End:#Nat)
		=> piece(N:#Nat, sNat(End:#Nat))
		[structural]
	define bitRange(_:#Nat bit:: piece(N:#Nat, sNat(End:#Nat)), 0, End:#Nat)
		=> piece(N:#Nat, sNat(End:#Nat))
		[structural]
		
	define bitRange(piece(N:#Nat, Len:#Nat), Pos:#Nat, Pos:#Nat) => (N:#Nat >>Nat Pos:#Nat) &Nat 1
		when N:#Nat >=Nat 0
		[structural]
	
	op extractField-pre : List{K} Type #Nat K -> K [metadata "strict=(4)"]
	op extractField-aux : List{K} Type #Nat #Nat List{K} -> K
	
	// fixme could speed things up by caching bitsizeoftype as well
	rule [extractField-start]:
		< k > extractField(L:List{K}, 't(_,, L:KLabel(S:#Id)), F:#Id)
			=> extractField-pre(L:List{K}, T:KResult, Offset:#Nat, bitSizeofType(T:KResult)) 
		...</ k >
		< structs >... 
			S:#Id |-> aggregateInfo(_, (_ F:#Id |-> T:KResult), (_ F:#Id |-> Offset:#Nat)) 
		...</ structs >
		when L:KLabel ==Bool 'unionType
		orBool L:KLabel ==Bool 'structType
		[structural]

	rule
		< k > extractField-pre(L:List{K}, T:KResult, Offset:#Nat, tv(Len:#Nat, _))
			=> concretize(T:KResult, fillToBytes(extractBitsFromList(dataList(L:List{K}), Offset:#Nat, Len:#Nat)))
		...</ k >
		[structural]
	
	define isConcreteNumber(sym(_:#Nat) +Nat _:#Nat) => false [structural]
	define isConcreteNumber(bito(_:#Nat) +Nat _:#Nat) => false [structural]
	define isConcreteNumber(I:#Int) => true
		when  I:#Int <=Int 0 orBool I:#Int >Int 0
		[structural]
	
	// this should probably go in the k prelude

	define K:K in (ListItem(K:K) _:List) => true [structural]
	define K:K in .List => false [structural]
	define K:K in (ListItem(K':K) L:List) => K:K in L:List
		when K:K =/=Bool K':K
		[structural]
	
	rule [discard]:
		< k > V:KResult ~> discard => .K ...</ k >
		[structural]
	
	//- derived
	define bitsToBytes(N:#Nat) => absInt(ceilingRat(N:#Nat /Rat numBitsPerByte)) [structural]
		
	define numBytes(t(_, unsigned-char)) => numBytes(t(.Set, signed-char)) [structural]
	define numBytes(t(_, unsigned-short-int)) => numBytes(t(.Set, short-int)) [structural]
	define numBytes(t(_, unsigned-int)) => numBytes(t(.Set, int)) [structural]
	define numBytes(t(_, unsigned-long-int)) => numBytes(t(.Set, long-int)) [structural]
	define numBytes(t(_, unsigned-long-long-int)) => numBytes(t(.Set, long-long-int)) [structural]
	
	define numBits(t(S:Set, T:K)) => numBytes(t(S:Set, T:K)) *Nat numBitsPerByte
		when getKLabel(T:K) =/=Bool 'bitfieldType
		[structural]
	define numBits(t(_, bitfieldType(_, N:#Nat))) => N:#Nat [structural]

	define min(t(_, bool)) => 0 [structural]
	define max(t(_, bool)) => 1 [structural]
	
	define min(t(_, signed-char)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, signed-char)), 1))) [structural]
	// rule min(t(_, signed-char)) => kccSettingInt("_KCC_SCHAR_MIN") [structural]
	define max(t(_, signed-char)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, signed-char)), 1)), 1) [structural]
	define min(t(_, short-int)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, short-int)), 1))) [structural]
	define max(t(_, short-int)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, short-int)), 1)), 1) [structural]
	define min(t(_, int)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, int)), 1))) [structural]
	define max(t(_, int)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, int)), 1)), 1) [structural]
	define min(t(_, long-int)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, long-int)), 1))) [structural]
	define max(t(_, long-int)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, long-int)), 1)), 1) [structural]
	define min(t(_, long-long-int)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, long-long-int)), 1))) [structural]
	define max(t(_, long-long-int)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, long-long-int)), 1)), 1) [structural]
	
	define min(t(_, unsigned-char)) => 0 [structural]
	define max(t(_, unsigned-char)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-char))), 1) [structural]
	define min(t(_, unsigned-short-int)) => 0 [structural]
	define max(t(_, unsigned-short-int)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-short-int))), 1) [structural]
	define min(t(_, unsigned-int)) => 0 [structural]
	define max(t(_, unsigned-int)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-int))), 1) [structural]
	define min(t(_, unsigned-long-int)) => 0 [structural]
	define max(t(_, unsigned-long-int)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-long-int))), 1) [structural]
	define min(t(_, unsigned-long-long-int)) => 0 [structural]
	define max(t(_, unsigned-long-long-int)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-long-long-int))), 1) [structural]
	
	
	define stringToChar(C:#Char) => C:#Char [structural]
	define asciiCharString(S:#String) => asciiString(stringToChar(S:#String)) [structural]
	define [firstChar]:
		firstChar(S:#String) => substrString(S:#String, 0, 1)
		[structural]
	define [nthChar]:
		nthChar(S:#String, N:#Nat) => substrString(S:#String, N:#Nat, 1)
		[structural]
	define [charToAscii]:
		charToAscii(C:#Char) => asciiString(C:#Char)
		[structural]
	define [butFirstChar]:
		butFirstChar(S:#String) => substrString(S:#String, 1, lengthString(S:#String))
		[structural]
		
	declare toUpperCase : #String -> #String
	declare toUpperCase : #Char -> #Char
	define toUpperCase(S:#String)
		=> toUpperCase(firstChar(S:#String)) +String toUpperCase(butFirstChar(S:#String))
		when S:#String =/=Bool ""
		[structural]
	define toUpperCase("") => "" [structural]
		
	define toUpperCase(C:#Char)
		=> C:#Char
		when asciiString(C:#Char) <Nat asciiString("a")
		orBool asciiString(C:#Char) >Nat asciiString("z")
		[structural]
	define toUpperCase(C:#Char)
		=> charString(absInt(asciiString(C:#Char) -Int Difference))
		when asciiString(C:#Char) >=Nat asciiString("a")
		andBool asciiString(C:#Char) <=Nat asciiString("z")
		where Difference = (asciiString("a") -Int asciiString("A"))
		[structural]
		
	// getString returns the string without the null terminator
	op getString : K -> K
	op getString-aux : K #String -> K [metadata "strict=(1)"]
	rule [getString-start]: getString(K:K) => getString-aux(K:K, "") [structural anywhere]
	op str : #String -> Value
	
	rule [getString-pre]:
		< k > (.K => read(Loc:#Nat, t(.Set, char)))
			~> getString-aux(tv((Loc:#Nat => sNat(Loc:#Nat)), _), S:#String)
		...</ k >
		[structural]
		
	rule [getString]:
		< k > tv(N:#Nat, _) 
			~> getString-aux(tv(Loc:#Nat, _), S:#String)
			=> getString-aux(tv(Loc:#Nat, t(.Set, pointerType(t(.Set, unsigned-char)))), S:#String +String charString(N:#Nat))
		...</ k >
		when N:#Nat =/=Bool 0
		[structural]
	rule [getString-done]:
		< k > tv(0, _) ~> getString-aux(tv(Loc:#Nat, _), S:#String)
			=> str(S:#String)
		...</ k >
		[structural]
		
	// writeString and writeWString expect the user to add the '\0' to the end of the strings passed
	op writeString : K #String -> K [metadata "strict=(1)"]
	op writeWString : K List{K} -> K [metadata "strict=(1)"]

	rule [write-string]:
		< k > writeString(tv(Loc:#Nat, T:KResult), S:#String)
			=> Computation(*(tv(Loc:#Nat, t(.Set, pointerType(t(.Set, char))))) 
				:= tv(charToAscii(firstChar(S:#String)), t(.Set, char)))
			~> writeString(tv(sNat(Loc:#Nat), T:KResult), butFirstChar(S:#String))
		...</ k >
		when S:#String =/=Bool ""
		[structural]
	// fixme this bare 4 needs to be updated to handle different size wchar_ts
	rule [write-wstring]:
		< k > writeWString(tv(Loc:#Nat, T:KResult), (N:#Nat,, S:List{K}))
			=> Computation(*(tv(Loc:#Nat, t(.Set, pointerType(cfg:wcharut)))) 
				:= tv(N:#Nat, cfg:wcharut))
			~> writeWString(tv(Loc:#Nat +Nat 4, T:KResult), S:List{K})
		...</ k >
		[structural] 
	rule [write-empty-string]:
		< k > writeString(_, "") => .K ...</ k >
		[structural]
	rule [write-empty-wstring]:
		< k > writeWString(_, .List{K}) => .K ...</ k >
		[structural]
		
	
	// fixme might be messing things up elsewhere
	declare pointerToString : #Nat -> #String
	define [pointerToString]:
		pointerToString(sym(N:#Nat) +Nat M:#Nat)
			=> "[sym(" +String subPointerToString(N:#Nat) +String ") + " 
			+String Rat2String(M:#Nat, 10) +String "]"
		[structural]
		
	declare subPointerToString : #Nat -> #String
	define [subPointerToString-auto]:
		subPointerToString(threadId(N:#Nat) +Nat N':#Nat)
			=> "threadId(" +String Rat2String(N:#Nat, 10) +String ") +Nat " 
			+String Rat2String(N':#Nat, 10)
		when N:#Nat =/=Bool allocatedDuration
		[structural]
	define [sub-pointerToString-allocated]:
		subPointerToString(threadId(allocatedDuration) +Nat N':#Nat)
			=> "threadId(allocatedDuration) +Nat " +String Rat2String(N':#Nat, 10)
		[structural]
	
	define [pointerToString-done]:
		pointerToString(NullPointer) => "NullPointer" [structural]
		
		
	define N:#Nat to N:#Nat => .List{K} [structural]
	define N:#Nat to N':#Nat => (N:#Nat,,((N:#Nat +Nat 1) to N':#Nat))
		when N:#Nat <Nat N':#Nat
		[structural]

	// Note: it only makes sense to memo this if the sets are just used to represent categories
	define S:Set SetItem(K:K) contains K:K => true [structural]
	define S:Set SetItem(K1:K) contains K2:K => S:Set contains K2:K
		when K1:K =/=Bool K2:K
		[structural]
	define .Set contains K:K => false [structural]

	define hasIntegerType(T:KResult) 
		=> hasUnsignedIntegerType(T:KResult) orBool hasSignedIntegerType(T:KResult)
		[structural]
	
	define hasUnsignedIntegerType(t(_, T:K)) => true
		when (unsignedIntegerTypes contains T:K)
		[structural]

	define hasUnsignedIntegerType(t(S:Set, T:K)) => false
		when getKLabel(T:K) =/=Bool 'bitfieldType
		andBool (setOfTypes contains l(getKLabel(T:K)) orBool hasFloatType(t(S:Set, T:K)))
		[structural]
	define hasUnsignedIntegerType(t(_, bitfieldType(T:KResult, _:#Nat))) => true
		when hasUnsignedIntegerType(T:KResult) ==Bool true
		[structural]
	define hasUnsignedIntegerType(t(_, bitfieldType(T:KResult, _:#Nat))) => false
		when hasUnsignedIntegerType(T:KResult) ==Bool false
		[structural]
	
	define hasSignedIntegerType(t(_, T:K)) => true
		when (signedIntegerTypes contains T:K)
		[structural]
	define hasSignedIntegerType(t(_, enumType(_:#Id))) => true [structural] // choice fixme
	define hasSignedIntegerType(t(S:Set, T:K)) => false
		when getKLabel(T:K) =/=Bool 'bitfieldType
		andBool (setOfTypes contains l(getKLabel(T:K)) orBool hasFloatType(t(S:Set, T:K)))
		[structural]
	define hasSignedIntegerType(t(_, bitfieldType(T:KResult, _:#Nat))) => true
		when hasSignedIntegerType(T:KResult) ==Bool true
		[structural]
	define hasSignedIntegerType(t(_, bitfieldType(T:KResult, _:#Nat))) => false
		when hasSignedIntegerType(T:KResult) ==Bool false
		[structural]

	define min(t(_, bitfieldType(T:KResult, N:#Nat))) => 0
		when hasUnsignedIntegerType(T:KResult)
		[structural]
	define max(t(_, bitfieldType(T:KResult, N:#Nat))) => _-Int_(2 ^Nat absInt(N:#Nat), 1)
		when hasUnsignedIntegerType(T:KResult)
		[structural]
	
	define min(t(_, bitfieldType(T:KResult, N:#Nat))) => -Int (2 ^Nat absInt(_-Int_(N:#Nat, 1)))
		when hasSignedIntegerType(T:KResult)
		[structural]
	define max(t(_, bitfieldType(T:KResult, N:#Nat))) => _-Int_(2 ^Nat absInt(_-Int_(N:#Nat, 1)), 1)
		when hasSignedIntegerType(T:KResult)
		[structural]
		
		
	define NullPointerConstant => 0 [structural]
	
	define _bit::_(piece(N:#Nat, Len:#Nat), piece(N':#Nat, Len':#Nat)) 
		=> piece((N:#Nat <<Nat Len':#Nat) |Nat N':#Nat, Len:#Nat +Nat Len':#Nat)
		when N:#Nat >=Nat 0 andBool N':#Nat >=Nat 0 
		[structural] 
	define _bit::_(piece(0, 0), N:#Nat) => N:#Nat [structural] 
	define piece(piece(N:#Nat, Len:#Nat), Len:#Nat) => piece(N:#Nat, Len:#Nat) [structural] 
	define value(tv(V:List{K}, _)) => V:List{K} [structural]
	define type(tv(_, T:KResult)) => T:KResult [structural]

	define isBasicType('t(_,, K:K)) => if (
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
		
	define setOfTypes => Set(
		l('arrayType),, 
		l('bitfieldType),, 
		l('functionType),, 
		l('pointerType),, l('structType),, l('unionType),, 
		l('qualifiedType)
	) [structural]
	
	rule bito(0) => 0 [structural anywhere] // FIXME need to check this is okay in all circumstances
	
	
	rule assert(true, _:#Nat) => .K [structural anywhere]
endkm

kmod COMMON-C-BITSIZE is
	including COMMON-SEMANTICS-HELPERS-INCLUDE
	
	declare bitSizeofList : List{KResult} -> K
	declare bitSizeofList-aux : K #Nat List{KResult} -> K [metadata "strict=(1)"]
	
	
	define bitSizeofList(L:List{KResult}) => bitSizeofList-aux(.K, 0, L:List{KResult})
		[structural]
	define bitSizeofList-aux((.K => bitSizeofType(T:KResult)), _:#Nat, ((T:KResult => .List{K}),, _:List{KResult}))
		[structural]
	define bitSizeofList-aux((tv(Len':#Nat, _) => .K), (Len:#Nat => Len:#Nat +Nat Len':#Nat), _)
		[structural]
	define bitSizeofList-aux(.K, Len:#Nat, .List{K}) => tv(Len:#Nat, cfg:largestUnsigned)
		[structural]	
	
		
	op maxBitSizeofList : List{KResult} -> K 
	op maxBitSizeofList-aux : List{KResult} #Nat -> K 
	rule maxBitSizeofList(L:List{KResult}) => maxBitSizeofList-aux(L:List{KResult}, 0) [structural anywhere]
	rule
		< k > maxBitSizeofList-aux((T:KResult,, L:List{KResult}), N:#Nat)
			=> bitSizeofType(T:KResult) 
			~> maxBitSizeofList-aux(L:List{KResult}, N:#Nat) 
		...</ k >
		[structural] 
	rule
		< k > (tv(N':#Nat, _) => .) 
			~> maxBitSizeofList-aux(L:List{KResult}, (N:#Nat => maxNat(N:#Nat, N':#Nat))) 
		...</ k >
		[structural] 
	rule
		< k > maxBitSizeofList-aux(.List{K}, N:#Nat) => tv(N:#Nat, cfg:largestUnsigned) ...</ k >
		[structural] 
	
	rule bitSizeofType(t(_, arrayType(T:KResult, N:#Nat))) => bitSizeofType(T:KResult) * tv(N:#Nat, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, flexibleArrayType(T:KResult))) => tv(0, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, functionType(_, _:List{KResult}))) => tv(numBitsPerByte, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, pointerType(_))) => tv(cfg:ptrsize *Nat numBitsPerByte, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, bitfieldType(_, N:#Nat))) => tv(N:#Nat, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, qualifiedType(T:KResult, _))) => bitSizeofType(T:KResult) [structural anywhere]
	rule bitSizeofType(T:KResult) => tv(numBits(T:KResult), cfg:largestUnsigned) when isBasicType(T:KResult) [structural anywhere]
	rule bitSizeofType(typedDeclaration(T:KResult, _:#Id)) => bitSizeofType(T:KResult) [structural anywhere]

	rule
		< k > bitSizeofType(t(_, structType(S:#Id))) => bitSizeofList(L:List{KResult}) ...</ k >
		< structs >... S:#Id |-> aggregateInfo(L:List{KResult}, _, _) ...</ structs >
		[structural] 
	rule
		< k > bitSizeofType(t(_, unionType(S:#Id))) => maxBitSizeofList(L:List{KResult}) ...</ k >
		< structs >... S:#Id |-> aggregateInfo(L:List{KResult}, _, _) ...</ structs >
		[structural]
		
	define K2Nat(N:#Nat) => N:#Nat [structural]

	define getFieldOffset(F:#Id, aggregateInfo(_, _, (_ F:#Id |-> N:#Nat))) => N:#Nat [structural]
	define getFieldType(F:#Id, aggregateInfo(_, _, (_ F:#Id |-> T:KResult))) => T:KResult [structural]

		
	define toString(Identifier(S:#String)) => S:#String [structural]
	define toString(S:#String) => S:#String [structural]
	define toString(Num:#Nat) => Int2String(Num:#Nat) [structural]
	define Rat2String(sym(N:#Nat), M:#NzNat) => "sym(" +String Rat2String(N:#Nat, M:#NzNat) +String ")" [structural]
	
	
	define listToK(K:K) => klistToK(getList{K}(K:K)) [structural]
	define klistToK((K:K,, L:List{K})) => K:K ~> klistToK(L:List{K}) [structural]
	define klistToK(.List{K}) => .K [structural]
endkm


kmod COMMON-C-HELPERS is
	including COMMON-SEMANTICS-HELPERS-INCLUDE
	including COMMON-C-BITSIZE
	including COMMON-SEMANTICS-HELPERS-MISC
endkm
