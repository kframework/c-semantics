module COMMON-SEMANTICS-HELPERS-INCLUDE is
	// require maudeLib/common-c-builtins
	// including #COMMON-SEMANTICS-HELPERS-BUILTINS
	// op _bit::_ : K K -> K [function hook(#COMMON-SEMANTICS-HELPERS-BUILTINS:_bitList_)] .
	syntax Nat ::= Nat "bit::" Nat
	including COMMON-NOHELPER-INCLUDE
end module


module COMMON-SEMANTICS-HELPERS-MISC is
	including COMMON-SEMANTICS-HELPERS-INCLUDE

	declare base : Nat -> Nat
	define base(loc(Base:Nat, _, _)) => Base:Nat
	
	declare gatherInnerCells : Bag CellLabel -> Set
	define gatherInnerCells(((<L':CellLabel> <L:CellLabel> K:K </L:CellLabel> _ </L':CellLabel> => .Bag) _), L:CellLabel) (.Set => SetItem(K:K))
	define gatherInnerCells(.Bag, _) => .Set
	
	declare stringToList : String -> List
	declare listToString : List -> String
	
	define stringToList("") => .List
	define stringToList(S:String)
			=> ListItem(firstChar(S:String)) stringToList(butFirstChar(S:String))
		when S:String =/=String ""
		
	define listToString(.List) => ""
	define listToString((ListItem(S:String) L:List))
			=> S:String +String listToString(L:List)
	
	declare isUnknown : K -> Bool
	define [isUnknown-piece]: isUnknown(piece(_:Nat, _:Nat)) => true
	define [isUnknown-ptr]: isUnknown(loc(_:Nat, _:Nat, _:Nat)) => false
	define [isUnknown-int]: isUnknown(I:Int) => false
		when I:Int <=Int 0 orBool I:Int >Int 0
	
	define loc(N:Nat, M:Nat, 0) <Int loc(N:Nat, M':Nat, 0) => true
		when M:Nat <Int M':Nat
		[structural]
	define loc(N:Nat, M:Nat, 0) <=Int loc(N:Nat, M':Nat, 0) => true
		when M:Nat <=Int M':Nat
		[structural]
	define loc(N:Nat, M:Nat, 0) >Int loc(N:Nat, M':Nat, 0) => true
		when M:Nat >Int M':Nat
		[structural]
	define loc(N:Nat, M:Nat, 0) >=Int loc(N:Nat, M':Nat, 0) => true
		when M:Nat >=Int M':Nat
		[structural]
	
	declare simplifyTruth : K -> K
	define simplifyTruth(K:K) => K:K != tv(0, t(.Set, int))
	
	
	declare isNotTruthValue : Value -> Bool
	define isNotTruthValue(tv(V:K, t(_, T:K))) 
		=> T:K =/=K int
		orBool (
			V:K =/=K 0
			andBool V:K =/=K 1 
		)
		[structural]
	
	declare getIdOfDeclaration : K -> K 
	declare getIdOfName : K -> K 
	define getIdOfDeclaration(DeclarationDefinition(InitNameGroup(_, List(K:K))))
		=> getIdOfName(K:K)
	define getIdOfName(InitName(K:K, _)) => getIdOfName(K:K)
	define getIdOfName(SingleName(_, K:K)) => getIdOfName(K:K)
	define getIdOfName(Name(X:Id, _)) => X:Id
	
	// this maintains byte order
	declare fillToBytes-aux : K List{K} -> K
	define [fillToBytes-start]:
		fillToBytes(dataList(L:List{K})) 
			=> fillToBytes-aux(dataList(L:List{K}), .List{K}) 
		[structural]
	define [fillToBytes-foundByte]:
		fillToBytes-aux(dataList((L:List{K},, piece(N:Nat, Len:Nat))), L':List{K})
			=> fillToBytes-aux(dataList(L:List{K}), (piece(N:Nat, Len:Nat),, L':List{K}))
		when Len:Nat ==Int numBitsPerByte
		[structural]
	
	define [fillToBytes-addBit]:
		fillToBytes-aux(dataList(piece(N:Nat, Len:Nat)), L':List{K})
			=> fillToBytes-aux(dataList((piece(0, 1),, piece(N:Nat, Len:Nat))), L':List{K})
		when Len:Nat <Int numBitsPerByte
		[structural]
		
	define [fillToBytes-combineBits]:
		fillToBytes-aux(dataList((L:List{K},, piece(N:Nat, Len:Nat),, piece(N':Nat, Len':Nat))), L':List{K})
			=> fillToBytes-aux(dataList((L:List{K},, piece(_bit::_(piece(N:Nat, Len:Nat), piece(N':Nat, Len':Nat)), Len:Nat +Int Len':Nat))), L':List{K})
		when Len:Nat +Int Len':Nat <=Int numBitsPerByte
		[structural]
				
	define [fillToBytes-done]:
		fillToBytes-aux(dataList(.List{K}), L:List{K})
			=> dataList(L:List{K})
		[structural]
		
	// coallesce bitranges that are adjacent
	define _bit::_(piece(bitRange(N:Nat, sNatTo:Nat, To':Nat), Len:Nat), piece(bitRange(N:Nat, From:Nat, To:Nat), Len':Nat))
		=> piece(bitRange(N:Nat, From:Nat, To':Nat), Len:Nat +Int Len':Nat)
		when Len:Nat +Int Len':Nat <=Int numBitsPerByte
		andBool sNatTo:Nat ==Int To:Nat +Int 1
		[structural]
	
	define piece(N:Nat bit:: N':Nat, Len:Nat) bit:: piece(N'':Nat, Len':Nat)
		=> piece((N:Nat bit:: N':Nat) bit:: piece(N'':Nat, Len':Nat), Len:Nat +Int Len':Nat)
		[structural]

	define piece(N'':Nat, Len':Nat) bit:: piece(N:Nat bit:: N':Nat, Len:Nat)
		=> piece((piece(N'':Nat, Len':Nat) bit:: N:Nat) bit:: N':Nat, Len:Nat +Int Len':Nat)
		[structural]

	define bitRange(N:Nat bit:: piece(_:Nat, Len:Nat), Pos:Nat, Pos:Nat)
		=> bitRange(N:Nat, absInt(Pos:Nat -Int Len:Nat), absInt(Pos:Nat -Int Len:Nat))
		when Pos:Nat >Int 0
		andBool Pos:Nat -Int Len:Nat >=Int 0
		[structural]
		
	define bitRange(_:Nat bit:: piece(N:Nat, 1), 0, 0) => piece(N:Nat, 1)
	define bitRange(piece(N:Nat, 1), 0, 0) => piece(N:Nat, 1)
		
	define bitRange(piece(bitRange(N:Nat, Start:Nat, End:Nat), Len:Nat), 0, 0)
		=> bitRange(piece(bitRange(N:Nat, Start:Nat, Start:Nat), 1), 0, 0)
		when Start:Nat +Int Len:Nat ==Int End:Nat +Int 1
		[structural]
	
	define bitRange(N:Nat, Pos:Nat, Pos:Nat) => 1 &Int (N:Nat >>Int Pos:Nat)
		when N:Nat >=Int 0
		[structural]
	define bitRange(piece(N:Nat, 1), Pos:Nat, Pos:Nat) => 1 &Int (N:Nat >>Int Pos:Nat)
		when N:Nat >=Int 0
		[structural]
		
	define bitRange(N:Nat, 0, To:Nat) => N:Nat
		when To:Nat +Int 1 ==Int numBitsPerByte
		[structural]
	
	define bitRange(_:Nat bit:: piece(N:Nat, Len:Nat), Start:Nat, End:Nat)
		=> bitRange(piece(N:Nat, Len:Nat), Start:Nat, End:Nat)
		when End:Nat +Int 1 <=Int Len:Nat
		[structural]
	
	define bitRange(piece(N:Nat, sNatEnd:Nat), 0, End:Nat)
		=> piece(N:Nat, End:Nat +Int 1)
		when sNatEnd:Nat ==Int End:Nat +Int 1
		[structural]
	define bitRange(_:Nat bit:: piece(N:Nat, sNatEnd:Nat), 0, End:Nat)
		=> piece(N:Nat, End:Nat +Int 1)
		when sNatEnd:Nat ==Int End:Nat +Int 1
		[structural]
		
	define bitRange(piece(N:Nat, Len:Nat), Pos:Nat, Pos:Nat) => (N:Nat >>Int Pos:Nat) &Int 1
		when N:Nat >=Int 0
		[structural]
	
	syntax K ::= "extractField-pre" "(" List{K} "," Type "," Nat "," K ")" [strict(4) klabel(extractField-pre)]
	syntax K ::= "extractField-aux" "(" List{K} "," Type "," Nat "," Nat "," List{K} ")" [klabel(extractField-aux)]
	
	// fixme could speed things up by caching bitsizeoftype as well
	rule [extractField-start]:
		<k> extractField(L:List{K}, 't(_,, L:KLabel(S:Id)), F:Id)
			=> extractField-pre(L:List{K}, T:KResult, Offset:Nat, bitSizeofType(T:KResult)) 
		...</k>
		<structs>... 
			S:Id |-> aggregateInfo(_, (_ F:Id |-> T:KResult), (_ F:Id |-> Offset:Nat)) 
		...</structs>
		when L:KLabel ==KLabel 'unionType
		orBool L:KLabel ==KLabel 'structType
		[structural]

	rule
		<k> extractField-pre(L:List{K}, T:KResult, Offset:Nat, tv(Len:Nat, _))
			=> concretize(T:KResult, fillToBytes(extractBitsFromList(dataList(L:List{K}), Offset:Nat, Len:Nat)))
		...</k>
		[structural]
	
	define isConcreteNumber(loc(_:Nat, _:Nat, _:Nat)) => false
	define isConcreteNumber(I:Int) => true
		when  I:Int <=Int 0 orBool I:Int >Int 0
		[structural]
	
	// this should probably go in the k prelude

	// define K:K in (ListItem(K:K) _:List) => true
	// define K:K in .List => false
	// define K:K in (ListItem(K':K) L:List) => K:K in L:List
		// when K:K =/=K K':K
		// [structural]
	
	rule [discard]:
		<k> V:KResult ~> discard => .K ...</k>
		[structural]
	
	//- derived
	define 
		bitsToBytes(N:Nat) => absInt(N:Nat /Int numBitsPerByte)
		when numBitsPerByte dividesInt N:Nat
		[structural]
	define 
		bitsToBytes(N:Nat) => absInt((N:Nat /Int numBitsPerByte) +Int 1) 
		when notBool numBitsPerByte dividesInt N:Nat
		[structural]
		
	define numBytes(t(_, unsigned-char)) => numBytes(t(.Set, signed-char))
	define numBytes(t(_, unsigned-short-int)) => numBytes(t(.Set, short-int))
	define numBytes(t(_, unsigned-int)) => numBytes(t(.Set, int))
	define numBytes(t(_, unsigned-long-int)) => numBytes(t(.Set, long-int))
	define numBytes(t(_, unsigned-long-long-int)) => numBytes(t(.Set, long-long-int))
	
	define numBits(t(S:Set, T:K)) => numBytes(t(S:Set, T:K)) *Int numBitsPerByte
		when getKLabel(T:K) =/=KLabel 'bitfieldType
		[structural]
	define numBits(t(_, bitfieldType(_, N:Nat))) => N:Nat

	define min(t(_, bool)) => 0
	define max(t(_, bool)) => 1
	
	define min(t(_, signed-char)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, signed-char)), 1)))
	// rule min(t(_, signed-char)) => kccSettingInt("_KCC_SCHAR_MIN") [structural]
	define max(t(_, signed-char)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, signed-char)), 1)), 1)
	define min(t(_, short-int)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, short-int)), 1)))
	define max(t(_, short-int)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, short-int)), 1)), 1)
	define min(t(_, int)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, int)), 1)))
	define max(t(_, int)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, int)), 1)), 1)
	define min(t(_, long-int)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, long-int)), 1)))
	define max(t(_, long-int)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, long-int)), 1)), 1)
	define min(t(_, long-long-int)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, long-long-int)), 1)))
	define max(t(_, long-long-int)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, long-long-int)), 1)), 1)
	
	define min(t(_, unsigned-char)) => 0
	define max(t(_, unsigned-char)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-char))), 1)
	define min(t(_, unsigned-short-int)) => 0
	define max(t(_, unsigned-short-int)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-short-int))), 1)
	define min(t(_, unsigned-int)) => 0
	define max(t(_, unsigned-int)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-int))), 1)
	define min(t(_, unsigned-long-int)) => 0
	define max(t(_, unsigned-long-int)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-long-int))), 1)
	define min(t(_, unsigned-long-long-int)) => 0
	define max(t(_, unsigned-long-long-int)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-long-long-int))), 1)
	
	
	define stringToChar(C:Char) => C:Char
	define asciiCharString(S:String) => asciiString(stringToChar(S:String))
	define [firstChar]:
		firstChar(S:String) => substrString(S:String, 0, 1)
		[structural]
	define [nthChar]:
		nthChar(S:String, N:Nat) => substrString(S:String, N:Nat, 1)
		[structural]
	define [charToAscii]:
		charToAscii(C:Char) => asciiString(C:Char)
		[structural]
	define [butFirstChar]:
		butFirstChar(S:String) => substrString(S:String, 1, lengthString(S:String))
		[structural]
		
	declare toUpperCase : String -> String
	declare toUpperCase : Char -> Char
	define toUpperCase(S:String)
		=> toUpperCase(firstChar(S:String)) +String toUpperCase(butFirstChar(S:String))
		when S:String =/=String ""
		[structural]
	define toUpperCase("") => ""
		
	define toUpperCase(C:Char)
		=> C:Char
		when asciiString(C:Char) <Int asciiString("a")
		orBool asciiString(C:Char) >Int asciiString("z")
		[structural]
	define toUpperCase(C:Char)
		=> charString(absInt(asciiString(C:Char) -Int Difference))
		when asciiString(C:Char) >=Int asciiString("a")
		andBool asciiString(C:Char) <=Int asciiString("z")
		where Difference = (asciiString("a") -Int asciiString("A"))
		[structural]
		
	// getString returns the string without the null terminator
	syntax K ::= "getString" "(" K ")" [klabel(getString)]
	syntax K ::= "getString-aux" "(" K "," String ")" [strict(1) klabel(getString-aux)]
	rule [getString-start]: getString(K:K) => getString-aux(K:K, "") [structural anywhere]
	syntax Value ::= "str" "(" String ")" [klabel(str)]
	
	rule [getString-pre]:
		<k> (.K => read(Loc:Nat, t(.Set, char)))
			~> getString-aux(tv((Loc:Nat => Loc:Nat +Int 1), _), S:String)
		...</k>
		[structural]
		
	rule [getString]:
		<k> tv(N:Nat, _) 
			~> getString-aux(tv(Loc:Nat, _), S:String)
			=> getString-aux(tv(Loc:Nat, t(.Set, pointerType(t(.Set, unsigned-char)))), S:String +String charString(N:Nat))
		...</k>
		when N:Nat =/=Int 0
		[structural]
	rule [getString-done]:
		<k> tv(0, _) ~> getString-aux(tv(Loc:Nat, _), S:String)
			=> str(S:String)
		...</k>
		[structural]
		
	// writeString and writeWString expect the user to add the '\0' to the end of the strings passed
	syntax K ::= "writeString" "(" K "," String ")" [strict(1) klabel(writeString)]
	syntax K ::= "writeWString" "(" K "," List{K} ")" [strict(1) klabel(writeWString)]

	rule [write-string]:
		<k> writeString(tv(Loc:Nat, T:KResult), S:String)
			=> Computation(*(tv(Loc:Nat, t(.Set, pointerType(t(.Set, char))))) 
				:= tv(charToAscii(firstChar(S:String)), t(.Set, char)))
			~> writeString(tv(Loc:Nat +Int 1, T:KResult), butFirstChar(S:String))
		...</k>
		when S:String =/=String ""
		[structural]
	// fixme this bare 4 needs to be updated to handle different size wchar_ts
	rule [write-wstring]:
		<k> writeWString(tv(Loc:Nat, T:KResult), (N:Nat,, S:List{K}))
			=> Computation(*(tv(Loc:Nat, t(.Set, pointerType(cfg:wcharut)))) 
				:= tv(N:Nat, cfg:wcharut))
			~> writeWString(tv(Loc:Nat +Int 4, T:KResult), S:List{K})
		...</k>
		[structural] 
	rule [write-empty-string]:
		<k> writeString(_, "") => .K ...</k>
		[structural]
	rule [write-empty-wstring]:
		<k> writeWString(_, .List{K}) => .K ...</k>
		[structural]
		
	
	// fixme might be messing things up elsewhere
	declare pointerToString : Nat -> String
	define [pointerToString]:
		pointerToString(loc(N:Nat, M:Nat, 0))
			=> "[sym(" +String subPointerToString(N:Nat) +String ") + " 
			+String Int2String(M:Nat) +String "]"
		[structural]
		
	declare subPointerToString : Nat -> String
	define [subPointerToString-auto]:
		subPointerToString(threadId(N:Nat) +Int N':Nat)
			=> "threadId(" +String Int2String(N:Nat) +String ") +Int " 
			+String Int2String(N':Nat)
		when N:Nat =/=K allocatedDuration
		[structural]
	define [sub-pointerToString-allocated]:
		subPointerToString(threadId(allocatedDuration) +Int N':Nat)
			=> "threadId(allocatedDuration) +Int " +String Int2String(N':Nat)
		[structural]
	
	define [pointerToString-done]:
		pointerToString(NullPointer) => "NullPointer" [structural]
		
		
	define N:Nat to N:Nat => .List{K}
	define N:Nat to N':Nat => (N:Nat,,((N:Nat +Int 1) to N':Nat))
		when N:Nat <Int N':Nat
		[structural]

	// Note: it only makes sense to memo this if the sets are just used to represent categories
	define S:Set SetItem(K:K) contains K:K => true
	define S:Set SetItem(K1:K) contains K2:K => S:Set contains K2:K
		when K1:K =/=K K2:K
		[structural]
	define .Set contains K:K => false

	define hasIntegerType(T:KResult) 
		=> hasUnsignedIntegerType(T:KResult) orBool hasSignedIntegerType(T:KResult)
		[structural]
	
	define hasUnsignedIntegerType(t(_, T:K)) => true
		when (unsignedIntegerTypes contains T:K)
		[structural]

	define hasUnsignedIntegerType(t(S:Set, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'bitfieldType
		andBool (setOfTypes contains l(getKLabel(T:K)) orBool isFloatType(t(S:Set, T:K)))
		[structural]
	define hasUnsignedIntegerType(t(_, bitfieldType(T:KResult, _:Nat))) => true
		when hasUnsignedIntegerType(T:KResult) ==Bool true
		[structural]
	define hasUnsignedIntegerType(t(_, bitfieldType(T:KResult, _:Nat))) => false
		when hasUnsignedIntegerType(T:KResult) ==Bool false
		[structural]
	
	define hasSignedIntegerType(t(_, T:K)) => true
		when (signedIntegerTypes contains T:K)
		[structural]
	define hasSignedIntegerType(t(_, enumType(_:Id))) => true // choice fixme
	define hasSignedIntegerType(t(S:Set, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'bitfieldType
		andBool (setOfTypes contains l(getKLabel(T:K)) orBool isFloatType(t(S:Set, T:K)))
		[structural]
	define hasSignedIntegerType(t(_, bitfieldType(T:KResult, _:Nat))) => true
		when hasSignedIntegerType(T:KResult) ==Bool true
		[structural]
	define hasSignedIntegerType(t(_, bitfieldType(T:KResult, _:Nat))) => false
		when hasSignedIntegerType(T:KResult) ==Bool false
		[structural]

	define min(t(_, bitfieldType(T:KResult, N:Nat))) => 0
		when hasUnsignedIntegerType(T:KResult)
		[structural]
	define max(t(_, bitfieldType(T:KResult, N:Nat))) => _-Int_(2 ^Int absInt(N:Nat), 1)
		when hasUnsignedIntegerType(T:KResult)
		[structural]
	
	define min(t(_, bitfieldType(T:KResult, N:Nat))) => 0 -Int (2 ^Int absInt(_-Int_(N:Nat, 1)))
		when hasSignedIntegerType(T:KResult)
		[structural]
	define max(t(_, bitfieldType(T:KResult, N:Nat))) => _-Int_(2 ^Int absInt(_-Int_(N:Nat, 1)), 1)
		when hasSignedIntegerType(T:KResult)
		[structural]
		
		
	define NullPointerConstant => 0
	
	define _bit::_(piece(N:Nat, Len:Nat), piece(N':Nat, Len':Nat)) 
		=> piece((N:Nat <<Int Len':Nat) |Int N':Nat, Len:Nat +Int Len':Nat)
		when N:Nat >=Int 0 andBool N':Nat >=Int 0 
		[structural] 
	define _bit::_(piece(0, 0), N:Nat) => N:Nat 
	define piece(piece(N:Nat, Len:Nat), Len:Nat) => piece(N:Nat, Len:Nat) 
	define value(tv(V:List{K}, _)) => V:List{K}
	define type(tv(_, T:KResult)) => T:KResult

	define isBasicType('t(_,, K:K)) => #if (
		K:K ==K bool
		orBool K:K ==K void
		orBool K:K ==K char
		orBool K:K ==K short-int
		orBool K:K ==K int
		orBool K:K ==K long-int
		orBool K:K ==K long-long-int
		orBool K:K ==K float
		orBool K:K ==K double
		orBool K:K ==K long-double
		orBool K:K ==K signed-char
		orBool K:K ==K unsigned-char
		orBool K:K ==K unsigned-short-int
		orBool K:K ==K unsigned-int
		orBool K:K ==K unsigned-long-int
		orBool K:K ==K unsigned-long-long-int
		orBool K:K ==K no-type
		orBool getKLabel(K:K) ==KLabel 'enumType
		) #then true #else false #fi
		[structural]
		
	define setOfTypes => Set(
		l('arrayType),, 
		l('bitfieldType),, 
		l('functionType),, 
		l('pointerType),, l('structType),, l('unionType),, 
		l('qualifiedType)
	) [structural]
	
	rule assert(true, _:Nat) => .K [structural anywhere]
end module

module COMMON-C-BITSIZE is
	including COMMON-SEMANTICS-HELPERS-INCLUDE
	
	declare bitSizeofList : List{KResult} -> K
	declare bitSizeofList-aux : K Nat List{KResult} -> K [strict(1)]
	
	
	define bitSizeofList(L:List{KResult}) => bitSizeofList-aux(.K, 0, L:List{KResult})
		[structural]
	define bitSizeofList-aux((.K => bitSizeofType(T:KResult)), _:Nat, ((T:KResult => .List{K}),, _:List{KResult}))
		[structural]
	define bitSizeofList-aux((tv(Len':Nat, _) => .K), (Len:Nat => Len:Nat +Int Len':Nat), _)
		[structural]
	define bitSizeofList-aux(.K, Len:Nat, .List{K}) => tv(Len:Nat, cfg:largestUnsigned)
		[structural]	
	
		
	syntax K ::= "maxBitSizeofList" "(" List{KResult} ")" [klabel(maxBitSizeofList)] 
	syntax K ::= "maxBitSizeofList-aux" "(" List{KResult} "," Nat ")" [klabel(maxBitSizeofList-aux)] 
	rule maxBitSizeofList(L:List{KResult}) => maxBitSizeofList-aux(L:List{KResult}, 0) [structural anywhere]
	rule
		<k> maxBitSizeofList-aux((T:KResult,, L:List{KResult}), N:Nat)
			=> bitSizeofType(T:KResult) 
			~> maxBitSizeofList-aux(L:List{KResult}, N:Nat) 
		...</k>
		[structural] 
	rule
		<k> (tv(N':Nat, _) => .) 
			~> maxBitSizeofList-aux(L:List{KResult}, (N:Nat => maxInt(N:Nat, N':Nat))) 
		...</k>
		[structural] 
	rule
		<k> maxBitSizeofList-aux(.List{K}, N:Nat) => tv(N:Nat, cfg:largestUnsigned) ...</k>
		[structural] 
	
	rule bitSizeofType(t(_, arrayType(T:KResult, N:Nat))) => bitSizeofType(T:KResult) * tv(N:Nat, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, flexibleArrayType(T:KResult))) => tv(0, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, functionType(_, _:List{KResult}))) => tv(numBitsPerByte, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, pointerType(_))) => tv(cfg:ptrsize *Int numBitsPerByte, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, bitfieldType(_, N:Nat))) => tv(N:Nat, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, qualifiedType(T:KResult, _))) => bitSizeofType(T:KResult) [structural anywhere]
	rule bitSizeofType(T:KResult) => tv(numBits(T:KResult), cfg:largestUnsigned) when isBasicType(T:KResult) [structural anywhere]
	rule bitSizeofType(typedDeclaration(T:KResult, _:Id)) => bitSizeofType(T:KResult) [structural anywhere]

	rule
		<k> bitSizeofType(t(_, structType(S:Id))) => bitSizeofList(L:List{KResult}) ...</k>
		<structs>... S:Id |-> aggregateInfo(L:List{KResult}, _, _) ...</structs>
		[structural] 
	rule
		<k> bitSizeofType(t(_, unionType(S:Id))) => maxBitSizeofList(L:List{KResult}) ...</k>
		<structs>... S:Id |-> aggregateInfo(L:List{KResult}, _, _) ...</structs>
		[structural]
		
	// define K2Nat(N:Nat) => N:Nat

	define getFieldOffset(F:Id, aggregateInfo(_, _, (_ F:Id |-> N:Nat))) => N:Nat
	define getFieldType(F:Id, aggregateInfo(_, _, (_ F:Id |-> T:KResult))) => T:KResult

		
	define toString(Identifier(S:String)) => S:String
	define toString(S:String) => S:String
	define toString(Num:Nat) => Int2String(Num:Nat)
	// define Int2String(sym(N:Nat)) => "sym(" +String Int2String(N:Nat) +String ")"
	
	
	define listToK(K:K) => klistToK(getList{K}(K:K))
	define klistToK((K:K,, L:List{K})) => K:K ~> klistToK(L:List{K})
	define klistToK(.List{K}) => .K
end module


module COMMON-C-HELPERS is
	including COMMON-SEMANTICS-HELPERS-INCLUDE
	including COMMON-C-BITSIZE
	including COMMON-SEMANTICS-HELPERS-MISC
end module
