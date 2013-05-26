require "common-c-semantics.k"

module COMMON-SEMANTICS-HELPERS-INCLUDE
	imports COMMON-NOHELPER-INCLUDE
	// require maudeLib/common-c-builtins
	// imports #COMMON-SEMANTICS-HELPERS-BUILTINS
	// op _bit::_ : K K -> K [function hook(#COMMON-SEMANTICS-HELPERS-BUILTINS:_bitList_)] .
	syntax Int ::= Int "bit::" Int
endmodule

module COMMON-SEMANTICS-HELPERS-MISC
	imports COMMON-SEMANTICS-HELPERS-INCLUDE

	syntax K ::= firstLoc(K) [function]
	rule
		firstLoc(ThreadId:Int)
			=> loc(threadId(ThreadId:Int) +Int 0, 0, 0)
	
	syntax Int ::= base(Int) [function]
	rule base(loc(Base:Int, _, _)) => Base:Int
	
	syntax Set ::= gatherInnerCells(Bag, CellLabel) [function]
	rule gatherInnerCells(((<L':CellLabel> <L:CellLabel> K:K </L:CellLabel> _ </L':CellLabel> => .Bag) _), L:CellLabel) (.Set => SetItem(K:K))
	rule gatherInnerCells(.Bag, _) => .Set
	
	syntax KList ::= stringToList(String) [function]
	syntax String ::= listToString(List) [function]
	
	rule stringToList("") => .List
	rule stringToList(S:String)
			=> ListItem(firstChar(S:String)) stringToList(butFirstChar(S:String))
		when S:String =/=String ""
		
	rule listToString(.List) => ""
	rule listToString((ListItem(S:String) L:List))
			=> S:String +String listToString(L:List)
	
	syntax Bool ::= isUnknown(K) [function]
	rule [isUnknown-piece]: isUnknown(piece(_:Int, _:Int)) => true
	rule [isUnknown-ptr]: isUnknown(loc(_:Int, _:Int, _:Int)) => false
	rule [isUnknown-int]: isUnknown(I:Int) => false
		when I:Int <=Int 0 orBool I:Int >Int 0
	
	rule loc(N:Int, M:Int, 0) <Int loc(N:Int, M':Int, 0) => true
		when M:Int <Int M':Int
		[structural]
	rule loc(N:Int, M:Int, 0) <=Int loc(N:Int, M':Int, 0) => true
		when M:Int <=Int M':Int
		[structural]
	rule loc(N:Int, M:Int, 0) >Int loc(N:Int, M':Int, 0) => true
		when M:Int >Int M':Int
		[structural]
	rule loc(N:Int, M:Int, 0) >=Int loc(N:Int, M':Int, 0) => true
		when M:Int >=Int M':Int
		[structural]
	
	syntax K ::= simplifyTruth(K) [function]
	rule simplifyTruth(K:K) => K:K != tv(0, t(.Set, int))
	
	
	syntax Bool ::= isNotTruthValue(Value) [function]
	rule isNotTruthValue(tv(V:K, t(_, T:K))) 
		=> T:K =/=K int
		orBool (
			V:K =/=K 0
			andBool V:K =/=K 1 
		)
		[structural]
	
	syntax K ::= getIdOfDeclaration(K) [function]
	syntax K ::= getIdOfName(K) [function]
	rule getIdOfDeclaration(DeclarationDefinition(InitNameGroup(_, List(K:K))))
		=> getIdOfName(K:K)
	rule getIdOfName(InitName(K:K, _)) => getIdOfName(K:K)
	rule getIdOfName(SingleName(_, K:K)) => getIdOfName(K:K)
	rule getIdOfName(Name(X:Id, _)) => X:Id
	
	// this maintains byte order
	syntax K ::= "fillToBytes-aux" "(" K "," KList ")"
	rule [fillToBytes-start]:
		fillToBytes(dataList(L:KList)) 
			=> fillToBytes-aux(dataList(L:KList), .KList) 
		[structural]
	rule [fillToBytes-foundByte]:
		fillToBytes-aux(dataList((L:KList,, piece(N:Int, Len:Int))), L':KList)
			=> fillToBytes-aux(dataList(L:KList), (piece(N:Int, Len:Int),, L':KList))
		when Len:Int ==Int numBitsPerByte
		[structural]
	
	rule [fillToBytes-addBit]:
		fillToBytes-aux(dataList(piece(N:Int, Len:Int)), L':KList)
			=> fillToBytes-aux(dataList((piece(0, 1),, piece(N:Int, Len:Int))), L':KList)
		when Len:Int <Int numBitsPerByte
		[structural]
		
	rule [fillToBytes-combineBits]:
		fillToBytes-aux(dataList((L:KList,, piece(N:Int, Len:Int),, piece(N':Int, Len':Int))), L':KList)
			=> fillToBytes-aux(dataList((L:KList,, piece(_bit::_(piece(N:Int, Len:Int), piece(N':Int, Len':Int)), Len:Int +Int Len':Int))), L':KList)
		when Len:Int +Int Len':Int <=Int numBitsPerByte
		[structural]
				
	rule [fillToBytes-done]:
		fillToBytes-aux(dataList(.KList), L:KList)
			=> dataList(L:KList)
		[structural]
		
	// coallesce bitranges that are adjacent
	rule _bit::_(piece(bitRange(N:Int, sNatTo:Int, To':Int), Len:Int), piece(bitRange(N:Int, From:Int, To:Int), Len':Int))
		=> piece(bitRange(N:Int, From:Int, To':Int), Len:Int +Int Len':Int)
		when Len:Int +Int Len':Int <=Int numBitsPerByte
		andBool sNatTo:Int ==Int To:Int +Int 1
		[structural]
	
	rule piece(N:Int bit:: N':Int, Len:Int) bit:: piece(N'':Int, Len':Int)
		=> piece((N:Int bit:: N':Int) bit:: piece(N'':Int, Len':Int), Len:Int +Int Len':Int)
		[structural]

	rule piece(N'':Int, Len':Int) bit:: piece(N:Int bit:: N':Int, Len:Int)
		=> piece((piece(N'':Int, Len':Int) bit:: N:Int) bit:: N':Int, Len:Int +Int Len':Int)
		[structural]

	rule bitRange(N:Int bit:: piece(_:Int, Len:Int), Pos:Int, Pos:Int)
		=> bitRange(N:Int, absInt(Pos:Int -Int Len:Int), absInt(Pos:Int -Int Len:Int))
		when Pos:Int >Int 0
		andBool Pos:Int -Int Len:Int >=Int 0
		[structural]
		
	rule bitRange(_:Int bit:: piece(N:Int, 1), 0, 0) => piece(N:Int, 1)
	rule bitRange(piece(N:Int, 1), 0, 0) => piece(N:Int, 1)
		
	rule bitRange(piece(bitRange(N:Int, Start:Int, End:Int), Len:Int), 0, 0)
		=> bitRange(piece(bitRange(N:Int, Start:Int, Start:Int), 1), 0, 0)
		when Start:Int +Int Len:Int ==Int End:Int +Int 1
		[structural]
	
	rule bitRange(N:Int, Pos:Int, Pos:Int) => 1 &Int (N:Int >>Int Pos:Int)
		when N:Int >=Int 0
		[structural]
	rule bitRange(piece(N:Int, 1), Pos:Int, Pos:Int) => 1 &Int (N:Int >>Int Pos:Int)
		when N:Int >=Int 0
		[structural]
		
	rule bitRange(N:Int, 0, To:Int) => N:Int
		when To:Int +Int 1 ==Int numBitsPerByte
		[structural]
	
	rule bitRange(_:Int bit:: piece(N:Int, Len:Int), Start:Int, End:Int)
		=> bitRange(piece(N:Int, Len:Int), Start:Int, End:Int)
		when End:Int +Int 1 <=Int Len:Int
		[structural]
	
	rule bitRange(piece(N:Int, sNatEnd:Int), 0, End:Int)
		=> piece(N:Int, End:Int +Int 1)
		when sNatEnd:Int ==Int End:Int +Int 1
		[structural]
	rule bitRange(_:Int bit:: piece(N:Int, sNatEnd:Int), 0, End:Int)
		=> piece(N:Int, End:Int +Int 1)
		when sNatEnd:Int ==Int End:Int +Int 1
		[structural]
		
	rule bitRange(piece(N:Int, Len:Int), Pos:Int, Pos:Int) => (N:Int >>Int Pos:Int) &Int 1
		when N:Int >=Int 0
		[structural]
	
	syntax K ::= "extractField-pre" "(" KList "," Type "," Int "," K ")" [strict(4)]
	syntax K ::= "extractField-aux" "(" KList "," Type "," Int "," Int "," KList ")"
	
	// fixme could speed things up by caching bitsizeoftype as well
	rule [extractField-start]:
		<k> extractField(L:KList, 't(_,, L:KLabel(S:Id)), F:Id)
			=> extractField-pre(L:KList, T:KResult, Offset:Int, bitSizeofType(T:KResult)) 
		...</k>
		<structs>... 
			S:Id |-> aggregateInfo(_, (_ F:Id |-> T:KResult), (_ F:Id |-> Offset:Int)) 
		...</structs>
		when L:KLabel ==KLabel 'unionType
		orBool L:KLabel ==KLabel 'structType
		[structural]

	rule
		<k> extractField-pre(L:KList, T:KResult, Offset:Int, tv(Len:Int, _))
			=> concretize(T:KResult, fillToBytes(extractBitsFromList(dataList(L:KList), Offset:Int, Len:Int)))
		...</k>
		[structural]
	
	rule isConcreteNumber(loc(_:Int, _:Int, _:Int)) => false
	rule isConcreteNumber(I:Int) => true
		when  I:Int <=Int 0 orBool I:Int >Int 0
		[structural]
	
	// this should probably go in the k prelude

	// rule K:K in (ListItem(K:K) _:List) => true
	// rule K:K in .List => false
	// rule K:K in (ListItem(K':K) L:List) => K:K in L:List
		// when K:K =/=K K':K
		// [structural]
	
	rule [discard]:
		<k> V:KResult ~> discard => .K ...</k>
		[structural]
	
	//- derived
	rule 
		bitsToBytes(N:Int) => absInt(N:Int /Int numBitsPerByte)
		when numBitsPerByte dividesInt N:Int
		[structural]
	rule 
		bitsToBytes(N:Int) => absInt((N:Int /Int numBitsPerByte) +Int 1) 
		when notBool numBitsPerByte dividesInt N:Int
		[structural]
		
	rule numBytes(t(_, unsigned-char)) => numBytes(t(.Set, signed-char))
	rule numBytes(t(_, unsigned-short-int)) => numBytes(t(.Set, short-int))
	rule numBytes(t(_, unsigned-int)) => numBytes(t(.Set, int))
	rule numBytes(t(_, unsigned-long-int)) => numBytes(t(.Set, long-int))
	rule numBytes(t(_, unsigned-long-long-int)) => numBytes(t(.Set, long-long-int))
	
	rule numBits(t(S:Set, T:K)) => numBytes(t(S:Set, T:K)) *Int numBitsPerByte
		when getKLabel(T:K) =/=KLabel 'bitfieldType
		[structural]
	rule numBits(t(_, bitfieldType(_, N:Int))) => N:Int

	rule min(t(_, bool)) => 0
	rule max(t(_, bool)) => 1
	
	rule min(t(_, signed-char)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, signed-char)), 1)))
	// rule min(t(_, signed-char)) => kccSettingInt("_KCC_SCHAR_MIN") [structural]
	rule max(t(_, signed-char)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, signed-char)), 1)), 1)
	rule min(t(_, short-int)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, short-int)), 1)))
	rule max(t(_, short-int)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, short-int)), 1)), 1)
	rule min(t(_, int)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, int)), 1)))
	rule max(t(_, int)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, int)), 1)), 1)
	rule min(t(_, long-int)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, long-int)), 1)))
	rule max(t(_, long-int)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, long-int)), 1)), 1)
	rule min(t(_, long-long-int)) => 0 -Int (2 ^Int absInt(_-Int_(numBits(t(.Set, long-long-int)), 1)))
	rule max(t(_, long-long-int)) => _-Int_(2 ^Int absInt(_-Int_(numBits(t(.Set, long-long-int)), 1)), 1)
	
	rule min(t(_, unsigned-char)) => 0
	rule max(t(_, unsigned-char)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-char))), 1)
	rule min(t(_, unsigned-short-int)) => 0
	rule max(t(_, unsigned-short-int)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-short-int))), 1)
	rule min(t(_, unsigned-int)) => 0
	rule max(t(_, unsigned-int)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-int))), 1)
	rule min(t(_, unsigned-long-int)) => 0
	rule max(t(_, unsigned-long-int)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-long-int))), 1)
	rule min(t(_, unsigned-long-long-int)) => 0
	rule max(t(_, unsigned-long-long-int)) => _-Int_(2 ^Int absInt(numBits(t(.Set, unsigned-long-long-int))), 1)
	
	
	rule stringToChar(C:Char) => C:Char
	rule asciiCharString(S:String) => asciiString(stringToChar(S:String))
	rule [firstChar]:
		firstChar(S:String) => substrString(S:String, 0, 1)
		[structural]
	rule [nthChar]:
		nthChar(S:String, N:Int) => substrString(S:String, N:Int, 1)
		[structural]
	rule [charToAscii]:
		charToAscii(C:Char) => asciiString(C:Char)
		[structural]
	rule [butFirstChar]:
		butFirstChar(S:String) => substrString(S:String, 1, lengthString(S:String))
		[structural]
		
	syntax String ::= toUpperCase(String) [function]
	syntax Char ::= toUpperCase(Char) [function]
	rule toUpperCase(S:String)
		=> toUpperCase(firstChar(S:String)) +String toUpperCase(butFirstChar(S:String))
		when S:String =/=String ""
		[structural]
	rule toUpperCase("") => ""
		
	rule toUpperCase(C:Char)
		=> C:Char
		when asciiString(C:Char) <Int asciiString("a")
		orBool asciiString(C:Char) >Int asciiString("z")
		[structural]
	rule toUpperCase(C:Char)
		=> charString(absInt(asciiString(C:Char) -Int Difference))
		when asciiString(C:Char) >=Int asciiString("a")
		andBool asciiString(C:Char) <=Int asciiString("z")
		where Difference = (asciiString("a") -Int asciiString("A"))
		[structural]
		
	// getString returns the string without the null terminator
	syntax K ::= "getString" "(" K ")"
	syntax K ::= "getString-aux" "(" K "," String ")" [strict(1)]
	rule [getString-start]: getString(K:K) => getString-aux(K:K, "") [structural anywhere]
	syntax Value ::= "str" "(" String ")"
	
	rule [getString-pre]:
		<k> (.K => read(Loc:Int, t(.Set, char)))
			~> getString-aux(tv((Loc:Int => Loc:Int +Int 1), _), S:String)
		...</k>
		[structural]
		
	rule [getString]:
		<k> tv(N:Int, _) 
			~> getString-aux(tv(Loc:Int, _), S:String)
			=> getString-aux(tv(Loc:Int, t(.Set, pointerType(t(.Set, unsigned-char)))), S:String +String charString(N:Int))
		...</k>
		when N:Int =/=Int 0
		[structural]
	rule [getString-done]:
		<k> tv(0, _) ~> getString-aux(tv(Loc:Int, _), S:String)
			=> str(S:String)
		...</k>
		[structural]
		
	// writeString and writeWString expect the user to add the '\0' to the end of the strings passed
	syntax K ::= "writeString" "(" K "," String ")" [strict(1)]
	syntax K ::= "writeWString" "(" K "," KList ")" [strict(1)]

	rule [write-string]:
		<k> writeString(tv(Loc:Int, T:KResult), S:String)
			=> Computation(*(tv(Loc:Int, t(.Set, pointerType(t(.Set, char))))) 
				:= tv(charToAscii(firstChar(S:String)), t(.Set, char)))
			~> writeString(tv(Loc:Int +Int 1, T:KResult), butFirstChar(S:String))
		...</k>
		when S:String =/=String ""
		[structural]
	// fixme this bare 4 needs to be updated to handle different size wchar_ts
	rule [write-wstring]:
		<k> writeWString(tv(Loc:Int, T:KResult), (N:Int,, S:KList))
			=> Computation(*(tv(Loc:Int, t(.Set, pointerType(cfg:wcharut)))) 
				:= tv(N:Int, cfg:wcharut))
			~> writeWString(tv(Loc:Int +Int 4, T:KResult), S:KList)
		...</k>
		[structural] 
	rule [write-empty-string]:
		<k> writeString(_, "") => .K ...</k>
		[structural]
	rule [write-empty-wstring]:
		<k> writeWString(_, .KList) => .K ...</k>
		[structural]
		
	
	// fixme might be messing things up elsewhere
	syntax String ::= pointerToString(Int) [function]
	rule [pointerToString]:
		pointerToString(loc(N:Int, M:Int, 0))
			=> "[sym(" +String subPointerToString(N:Int) +String ") + " 
			+String Int2String(M:Int) +String "]"
		[structural]
		
	syntax String ::= subPointerToString(Int) [function]
	rule [subPointerToString-auto]:
		subPointerToString(threadId(N:Int) +Int N':Int)
			=> "threadId(" +String Int2String(N:Int) +String ") +Int " 
			+String Int2String(N':Int)
		when N:Int =/=K allocatedDuration
		[structural]
	rule [sub-pointerToString-allocated]:
		subPointerToString(threadId(allocatedDuration) +Int N':Int)
			=> "threadId(allocatedDuration) +Int " +String Int2String(N':Int)
		[structural]
	
	rule [pointerToString-done]:
		pointerToString(NullPointer) => "NullPointer" [structural]
		
		
	rule N:Int to N:Int => .KList
	rule N:Int to N':Int => (N:Int,,((N:Int +Int 1) to N':Int))
		when N:Int <Int N':Int
		[structural]

	// Note: it only makes sense to memo this if the sets are just used to represent categories
	rule S:Set SetItem(K:K) contains K:K => true
	rule S:Set SetItem(K1:K) contains K2:K => S:Set contains K2:K
		when K1:K =/=K K2:K
		[structural]
	rule .Set contains K:K => false

	rule hasIntegerType(T:KResult) 
		=> hasUnsignedIntegerType(T:KResult) orBool hasSignedIntegerType(T:KResult)
		[structural]
	
	rule hasUnsignedIntegerType(t(_, T:K)) => true
		when (unsignedIntegerTypes contains T:K)
		[structural]

	rule hasUnsignedIntegerType(t(S:Set, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'bitfieldType
		andBool (setOfTypes contains l(getKLabel(T:K)) orBool isFloatType(t(S:Set, T:K)))
		[structural]
	rule hasUnsignedIntegerType(t(_, bitfieldType(T:KResult, _:Int))) => true
		when hasUnsignedIntegerType(T:KResult) ==Bool true
		[structural]
	rule hasUnsignedIntegerType(t(_, bitfieldType(T:KResult, _:Int))) => false
		when hasUnsignedIntegerType(T:KResult) ==Bool false
		[structural]
	
	rule hasSignedIntegerType(t(_, T:K)) => true
		when (signedIntegerTypes contains T:K)
		[structural]
	rule hasSignedIntegerType(t(_, enumType(_:Id))) => true // choice fixme
	rule hasSignedIntegerType(t(S:Set, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'bitfieldType
		andBool (setOfTypes contains l(getKLabel(T:K)) orBool isFloatType(t(S:Set, T:K)))
		[structural]
	rule hasSignedIntegerType(t(_, bitfieldType(T:KResult, _:Int))) => true
		when hasSignedIntegerType(T:KResult) ==Bool true
		[structural]
	rule hasSignedIntegerType(t(_, bitfieldType(T:KResult, _:Int))) => false
		when hasSignedIntegerType(T:KResult) ==Bool false
		[structural]

	rule min(t(_, bitfieldType(T:KResult, N:Int))) => 0
		when hasUnsignedIntegerType(T:KResult)
		[structural]
	rule max(t(_, bitfieldType(T:KResult, N:Int))) => _-Int_(2 ^Int absInt(N:Int), 1)
		when hasUnsignedIntegerType(T:KResult)
		[structural]
	
	rule min(t(_, bitfieldType(T:KResult, N:Int))) => 0 -Int (2 ^Int absInt(_-Int_(N:Int, 1)))
		when hasSignedIntegerType(T:KResult)
		[structural]
	rule max(t(_, bitfieldType(T:KResult, N:Int))) => _-Int_(2 ^Int absInt(_-Int_(N:Int, 1)), 1)
		when hasSignedIntegerType(T:KResult)
		[structural]
		
		
	rule NullPointerConstant => 0
	
	rule _bit::_(piece(N:Int, Len:Int), piece(N':Int, Len':Int)) 
		=> piece((N:Int <<Int Len':Int) |Int N':Int, Len:Int +Int Len':Int)
		when N:Int >=Int 0 andBool N':Int >=Int 0 
		[structural] 
	rule _bit::_(piece(0, 0), N:Int) => N:Int 
	rule piece(piece(N:Int, Len:Int), Len:Int) => piece(N:Int, Len:Int) 
	rule value(tv(V:KList, _)) => V:KList
	rule type(tv(_, T:KResult)) => T:KResult

	rule isBasicType('t(_,, K:K)) => #if (
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
		
	rule setOfTypes => Set(
		l('arrayType),, 
		l('bitfieldType),, 
		l('functionType),, 
		l('pointerType),, l('structType),, l('unionType),, 
		l('qualifiedType)
	) [structural]
	
	rule assert(true, _:Int) => .K [structural anywhere]
endmodule

module COMMON-C-BITSIZE
	imports COMMON-SEMANTICS-HELPERS-INCLUDE
	
	syntax K ::= bitSizeofList(List{KResult})
	syntax K ::= "bitSizeofList-aux" "(" K "," Int "," List{KResult} ")" [strict(1)]
	
	rule bitSizeofList(L:List{KResult}) => bitSizeofList-aux(.K, 0, L:List{KResult})
		[structural]
	rule bitSizeofList-aux((.K => bitSizeofType(T:KResult)), _:Int, ((T:KResult => .KList),, _:List{KResult}))
		[structural]
	rule bitSizeofList-aux((tv(Len':Int, _) => .K), (Len:Int => Len:Int +Int Len':Int), _)
		[structural]
	rule bitSizeofList-aux(.K, Len:Int, .KList) => tv(Len:Int, cfg:largestUnsigned)
		[structural]	
		
	syntax K ::= "maxBitSizeofList" "(" List{KResult} ")"
	syntax K ::= "maxBitSizeofList-aux" "(" List{KResult} "," Int ")"
	rule maxBitSizeofList(L:List{KResult}) => maxBitSizeofList-aux(L:List{KResult}, 0) [structural anywhere]
	rule
		<k> maxBitSizeofList-aux((T:KResult,, L:List{KResult}), N:Int)
			=> bitSizeofType(T:KResult) 
			~> maxBitSizeofList-aux(L:List{KResult}, N:Int) 
		...</k>
		[structural] 
	rule
		<k> (tv(N':Int, _) => .) 
			~> maxBitSizeofList-aux(L:List{KResult}, (N:Int => maxInt(N:Int, N':Int))) 
		...</k>
		[structural] 
	rule
		<k> maxBitSizeofList-aux(.KList, N:Int) => tv(N:Int, cfg:largestUnsigned) ...</k>
		[structural] 
	
	rule bitSizeofType(t(_, arrayType(T:KResult, N:Int))) => bitSizeofType(T:KResult) * tv(N:Int, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, flexibleArrayType(T:KResult))) => tv(0, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, functionType(_, _:List{KResult}))) => tv(numBitsPerByte, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, pointerType(_))) => tv(cfg:ptrsize *Int numBitsPerByte, cfg:largestUnsigned) [structural anywhere]
	rule bitSizeofType(t(_, bitfieldType(_, N:Int))) => tv(N:Int, cfg:largestUnsigned) [structural anywhere]
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
		
	// rule K2Int(N:Int) => N:Int

	rule getFieldOffset(F:Id, aggregateInfo(_, _, (_ F:Id |-> N:Int))) => N:Int
	rule getFieldType(F:Id, aggregateInfo(_, _, (_ F:Id |-> T:KResult))) => T:KResult

		
	rule toString(Identifier(S:String)) => S:String
	rule toString(S:String) => S:String
	rule toString(Num:Int) => Int2String(Num:Int)
	// rule Int2String(sym(N:Int)) => "sym(" +String Int2String(N:Int) +String ")"
	
	
	rule listToK(K:K) => klistToK(getKList(K:K))
	rule klistToK((K:K,, L:KList)) => K:K ~> klistToK(L:KList)
	rule klistToK(.KList) => .K
endmodule


module COMMON-C-HELPERS
	imports COMMON-SEMANTICS-HELPERS-INCLUDE
	imports COMMON-C-BITSIZE
	imports COMMON-SEMANTICS-HELPERS-MISC
endmodule
