kmod COMMON-SEMANTICS-HELPERS-INCLUDE is
	including COMMON-NOHELPER-INCLUDE
endkm

kmod COMMON-SEMANTICS-HELPERS-MISC is
	including COMMON-SEMANTICS-HELPERS-INCLUDE

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
	
	op simplifyTruth : K -> K
	rule simplifyTruth(K:K) => K:K != tv(0, t(.Set, int)) [structural]
	
	
	op isNotTruthValue : Value -> Bool
	rule isNotTruthValue(tv(V:BaseValue, t(?, T:SimpleType))) 
		=> T:SimpleType =/=Bool int
		orBool (
			V:BaseValue =/=Bool 0
			andBool V:BaseValue =/=Bool 1 
		)
		[structural]
	
	op getIdOfDeclaration : K -> K 
	op getIdOfName : K -> K 
	rule getIdOfDeclaration(DeclarationDefinition(InitNameGroup(?, K:C))) => getIdOfName(K:C) [structural]
	rule getIdOfName(InitName(K:K, ?)) => getIdOfName(K:K) [structural]
	rule getIdOfName(SingleName(?, K:K)) => getIdOfName(K:K) [structural] 
	rule getIdOfName(Name(X:Id, ?)) => X:Id [structural]
	
	// this maintains byte order
	op fillToBytes-aux : K List{K} -> K
	rule [fillToBytes-start]:
		fillToBytes(dataList(L:List{K})) 
			=> fillToBytes-aux(dataList(L:List{K}), .List{K}) 
		[structural]
	rule [fillToBytes-foundByte]:
		fillToBytes-aux(dataList((L:List{K},, piece(N:Nat, Len:Nat))), L':List{K})
			=> fillToBytes-aux(dataList(L:List{K}), (piece(N:Nat, Len:Nat),, L':List{K}))
		if Len:Nat ==Bool numBitsPerByte
		[structural]
	
	rule [fillToBytes-addBit]:
		fillToBytes-aux(dataList(piece(N:Nat, Len:Nat)), L':List{K})
			=> fillToBytes-aux(dataList((piece(0, 1),, piece(N:Nat, Len:Nat))), L':List{K})
		if Len:Nat <Nat numBitsPerByte
		[structural]
		
	rule [fillToBytes-combineBits]:
		fillToBytes-aux(dataList((L:List{K},, piece(N:Nat, Len:Nat),, piece(N':Nat, Len':Nat))), L':List{K})
			=> fillToBytes-aux(dataList((L:List{K},, piece(_bit::_(piece(N:Nat, Len:Nat), piece(N':Nat, Len':Nat)), Len:Nat +Nat Len':Nat))), L':List{K})
		if Len:Nat +Nat Len':Nat <=Nat numBitsPerByte
		[structural]
				
	rule [fillToBytes-done]:
		fillToBytes-aux(dataList(.List{K}), L:List{K})
			=> dataList(L:List{K})
		[structural]
		
	// coallesce bitranges that are adjacent
	rule _bit::_(piece(bitRange(N:Nat, sNat(To:Nat), To':Nat), Len:Nat), piece(bitRange(N:Nat, From:Nat, To:Nat), Len':Nat))
		=> piece(bitRange(N:Nat, From:Nat, To':Nat), Len:Nat +Nat Len':Nat)
		if Len:Nat +Nat Len':Nat <=Nat numBitsPerByte
		[structural]
	
	rule piece(N:Nat bit:: N':Nat, Len:Nat) bit:: piece(N'':Nat, Len':Nat)
		=> piece(N:Nat bit:: N':Nat bit:: piece(N'':Nat, Len':Nat), Len:Nat +Nat Len':Nat)
		[structural]

	rule piece(N'':Nat, Len':Nat) bit:: piece(N:Nat bit:: N':Nat, Len:Nat)
		=> piece(piece(N'':Nat, Len':Nat) bit:: N:Nat bit:: N':Nat, Len:Nat +Nat Len':Nat)
		[structural]

	rule bitRange(N:Nat bit:: piece(?, Len:Nat), Pos:Nat, Pos:Nat)
		=> bitRange(N:Nat, absInt(Pos:Nat -Int Len:Nat), absInt(Pos:Nat -Int Len:Nat))
		if Pos:Nat >Nat 0
		andBool Pos:Nat -Int Len:Nat >=Int 0
		[structural]
		
	rule bitRange(? bit:: piece(N:Nat, 1), 0, 0) => piece(N:Nat, 1) [structural]
	rule bitRange(piece(N:Nat, 1), 0, 0) => piece(N:Nat, 1) [structural]
		
	rule bitRange(piece(bitRange(N:Nat, Start:Nat, End:Nat), Len:Nat), 0, 0)
		=> bitRange(piece(bitRange(N:Nat, Start:Nat, Start:Nat), 1), 0, 0)
		if Start:Nat +Nat Len:Nat ==Bool sNat(End:Nat)
		[structural]
	
	rule bitRange(N:Nat, Pos:Nat, Pos:Nat) => 1 &Nat (N:Nat >>Nat Pos:Nat)
		if N:Nat >=Nat 0
		[structural]
	rule bitRange(piece(N:Nat, 1), Pos:Nat, Pos:Nat) => 1 &Nat (N:Nat >>Nat Pos:Nat)
		if N:Nat >=Nat 0
		[structural]
		
	rule bitRange(N:Nat, 0, To:Nat) => N:Nat
		if sNat(To:Nat) ==Bool numBitsPerByte
		[structural]
	
	rule bitRange(? bit:: piece(N:Nat, Len:Nat), Start:Nat, End:Nat)
		=> bitRange(piece(N:Nat, Len:Nat), Start:Nat, End:Nat)
		if sNat(End:Nat) <=Nat Len:Nat
		[structural]
	
	rule bitRange(piece(N:Nat, sNat(End:Nat)), 0, End:Nat)
		=> piece(N:Nat, sNat(End:Nat))
		[structural]
	rule bitRange(? bit:: piece(N:Nat, sNat(End:Nat)), 0, End:Nat)
		=> piece(N:Nat, sNat(End:Nat))
		[structural]
		
	rule bitRange(piece(N:Nat, Len:Nat), Pos:Nat, Pos:Nat) => (N:Nat >>Nat Pos:Nat) &Nat 1
		if N:Nat >=Nat 0
		[structural]
	
	op extractField-pre : List{K} Type Nat K -> K [metadata "strict=(4)"]
	op extractField-aux : List{K} Type Nat Nat List{K} -> K
	
	// fixme could speed things up by caching bitsizeoftype as well
	rule [extractField-start]:
		< k > extractField(L:List{K}, 't(?,, L:KLabel(S:Id)), F:Id)
			=> extractField-pre(L:List{K}, T:Type, Offset:Nat, bitSizeofType(T:Type)) 
		...</ k >
		< structs >... 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), (? F:Id |-> Offset:Nat)) 
		...</ structs >
		if L:KLabel ==Bool 'unionType
		orBool L:KLabel ==Bool 'structType
		[structural]

	rule
		< k > extractField-pre(L:List{K}, T:Type, Offset:Nat, tv(Len:Nat, ?))
			=> concretize(T:Type, fillToBytes(extractBitsFromList(dataList(L:List{K}), Offset:Nat, Len:Nat)))
		...</ k >
		[structural]
	
	rule isConcreteNumber(sym(?) +Nat ?) => false [structural]
	rule isConcreteNumber(bito(?) +Nat ?) => false [structural]
	rule isConcreteNumber(I:Int) => true
		if  I:Int <=Int 0 orBool I:Int >Int 0
		[structural]
	
	// this should probably go in the k prelude

	rule K:K in (ListItem(K:K) ?) => true [structural]
	rule K:K in .List => false [structural]
	rule K:K in (ListItem(K':K) L:List) => K:K in L:List
		if K:K =/=Bool K':K
		[structural]
	
	rule [discard]:
		< k > V:Value ~> discard => .K ...</ k >
		[structural]
	
	//- derived
	rule bitsToBytes(N:Nat) => absInt(ceilingRat(N:Nat /Rat numBitsPerByte)) [structural]
		
	rule numBytes(t(?, unsigned-char)) => numBytes(t(.Set, signed-char)) [structural]
	rule numBytes(t(?, unsigned-short-int)) => numBytes(t(.Set, short-int)) [structural]
	rule numBytes(t(?, unsigned-int)) => numBytes(t(.Set, int)) [structural]
	rule numBytes(t(?, unsigned-long-int)) => numBytes(t(.Set, long-int)) [structural]
	rule numBytes(t(?, unsigned-long-long-int)) => numBytes(t(.Set, long-long-int)) [structural]
	
	rule numBits(t(S:Set, T:SimpleType)) => numBytes(t(S:Set, T:SimpleType)) *Nat numBitsPerByte
		if getKLabel(T:SimpleType) =/=Bool 'bitfieldType
		[structural]
	rule numBits(t(?, bitfieldType(?, N:Nat))) => N:Nat [structural]

	rule min(t(?, bool)) => 0 [structural]
	rule max(t(?, bool)) => 1 [structural]
	
	rule min(t(?, signed-char)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, signed-char)), 1))) [structural]
	rule max(t(?, signed-char)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, signed-char)), 1)), 1) [structural]
	rule min(t(?, short-int)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, short-int)), 1))) [structural]
	rule max(t(?, short-int)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, short-int)), 1)), 1) [structural]
	rule min(t(?, int)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, int)), 1))) [structural]
	rule max(t(?, int)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, int)), 1)), 1) [structural]
	rule min(t(?, long-int)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, long-int)), 1))) [structural]
	rule max(t(?, long-int)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, long-int)), 1)), 1) [structural]
	rule min(t(?, long-long-int)) => -Int (2 ^Nat absInt(_-Int_(numBits(t(.Set, long-long-int)), 1))) [structural]
	rule max(t(?, long-long-int)) => _-Int_(2 ^Nat absInt(_-Int_(numBits(t(.Set, long-long-int)), 1)), 1) [structural]
	
	rule min(t(?, unsigned-char)) => 0 [structural]
	rule max(t(?, unsigned-char)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-char))), 1) [structural]
	rule min(t(?, unsigned-short-int)) => 0 [structural]
	rule max(t(?, unsigned-short-int)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-short-int))), 1) [structural]
	rule min(t(?, unsigned-int)) => 0 [structural]
	rule max(t(?, unsigned-int)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-int))), 1) [structural]
	rule min(t(?, unsigned-long-int)) => 0 [structural]
	rule max(t(?, unsigned-long-int)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-long-int))), 1) [structural]
	rule min(t(?, unsigned-long-long-int)) => 0 [structural]
	rule max(t(?, unsigned-long-long-int)) => _-Int_(2 ^Nat absInt(numBits(t(.Set, unsigned-long-long-int))), 1) [structural]
	
	
	rule stringToChar(C:Char) => C:Char [structural]
	rule asciiCharString(S:String) => asciiString(stringToChar(S:String)) [structural]
	rule [firstChar]:
		firstChar(S:String) => substrString(S:String, 0, 1)
		[structural]
	rule [nthChar]:
		nthChar(S:String, N:Nat) => substrString(S:String, N:Nat, 1)
		[structural]
	rule [charToAscii]:
		charToAscii(C:Char) => asciiString(C:Char)
		[structural]
	rule [butFirstChar]:
		butFirstChar(S:String) => substrString(S:String, 1, lengthString(S:String))
		[structural]
		
	rule N:Nat to N:Nat => .List{K} [structural]
	rule N:Nat to N':Nat => (N:Nat,,((N:Nat +Nat 1) to N':Nat))
		if N:Nat <Nat N':Nat
		[structural]

	// Note: it only makes sense to memo this if the sets are just used to represent categories
	rule S:Set SetItem(K:K) contains K:K => true [structural]
	rule S:Set SetItem(K1:K) contains K2:K => S:Set contains K2:K
		if K1:K =/=Bool K2:K
		[structural]
	rule .Set contains K:K => false [structural]

	rule hasIntegerType(T:Type) 
		=> hasUnsignedIntegerType(T:Type) orBool hasSignedIntegerType(T:Type)
		[structural]
	
	rule hasUnsignedIntegerType(t(?, T:SimpleType)) => true
		if (unsignedIntegerTypes contains T:SimpleType)
		[structural]

	rule hasUnsignedIntegerType(t(S:Set, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'bitfieldType
		andBool (setOfTypes contains l(getKLabel(T:SimpleType)) orBool hasFloatType(t(S:Set, T:SimpleType)))
		[structural]
	rule hasUnsignedIntegerType(t(?, bitfieldType(T:Type, ?))) => true
		if hasUnsignedIntegerType(T:Type) ==Bool true
		[structural]
	rule hasUnsignedIntegerType(t(?, bitfieldType(T:Type, ?))) => false
		if hasUnsignedIntegerType(T:Type) ==Bool false
		[structural]
	
	rule hasSignedIntegerType(t(?, T:SimpleType)) => true
		if (signedIntegerTypes contains T:SimpleType)
		[structural]
	rule hasSignedIntegerType(t(?, enumType(?))) => true [structural] // choice fixme
	rule hasSignedIntegerType(t(S:Set, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'bitfieldType
		andBool (setOfTypes contains l(getKLabel(T:SimpleType)) orBool hasFloatType(t(S:Set, T:SimpleType)))
		[structural]
	rule hasSignedIntegerType(t(?, bitfieldType(T:Type, ?))) => true
		if hasSignedIntegerType(T:Type) ==Bool true
		[structural]
	rule hasSignedIntegerType(t(?, bitfieldType(T:Type, ?))) => false
		if hasSignedIntegerType(T:Type) ==Bool false
		[structural]

	rule min(t(?, bitfieldType(T:Type, N:Nat))) => 0
		if hasUnsignedIntegerType(T:Type)
		[structural]
	rule max(t(?, bitfieldType(T:Type, N:Nat))) => _-Int_(2 ^Nat absInt(N:Nat), 1)
		if hasUnsignedIntegerType(T:Type)
		[structural]
	
	rule min(t(?, bitfieldType(T:Type, N:Nat))) => -Int (2 ^Nat absInt(_-Int_(N:Nat, 1)))
		if hasSignedIntegerType(T:Type)
		[structural]
	rule max(t(?, bitfieldType(T:Type, N:Nat))) => _-Int_(2 ^Nat absInt(_-Int_(N:Nat, 1)), 1)
		if hasSignedIntegerType(T:Type)
		[structural]
		
		
	rule NullPointerConstant => 0 [structural]
	
	rule _bit::_(piece(N:Nat, Len:Nat), piece(N':Nat, Len':Nat)) 
		=> piece((N:Nat <<Nat Len':Nat) |Nat N':Nat, Len:Nat +Nat Len':Nat)
		if N:Nat >=Nat 0 andBool N':Nat >=Nat 0 
		[structural] 
	rule _bit::_(piece(0, 0), N:Nat) => N:Nat [structural] 
	rule piece(piece(N:Nat, Len:Nat), Len:Nat) => piece(N:Nat, Len:Nat) [structural] 
	rule value(tv(V:List{K}, ?)) => V:List{K} [structural]
	rule type(tv(?, T:Type)) => T:Type [structural]

	rule isBasicType('t(?,, K:K)) => if (
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
		
	rule setOfTypes => Set(
		l('arrayType),, 
		l('bitfieldType),, 
		l('functionType),, 
		l('pointerType),, l('structType),, l('unionType),, 
		l('qualifiedType)
	) [structural]
	
	rule bito(0) => 0 [structural] // FIXME need to check this is okay in all circumstances
	
	
	rule assert(true, ?) => .K [structural]
endkm

kmod COMMON-C-BITSIZE is
	including COMMON-SEMANTICS-HELPERS-INCLUDE
	
	// syntax K ::= bitSizeofList ( List{Type} )
	// syntax K ::= bitSizeofList-aux ( K , List{Type} ) [strict(1)]
	
	op bitSizeofList : List{Type} -> K
	op bitSizeofList-aux : K Nat List{Type} -> K [metadata "strict=(1)"]
	
	
	rule bitSizeofList(L:List{Type}) => bitSizeofList-aux(.K, 0, L:List{Type})
		[structural]
	rule bitSizeofList-aux((.K => bitSizeofType(T:Type)), ?, (T:Type => Nil) :: ?:List{Type})
		[structural]
	rule bitSizeofList-aux((tv(Len':Nat, ?) => .K), (Len:Nat => Len:Nat +Nat Len':Nat), ?)
		[structural]
	rule bitSizeofList-aux(.K, Len:Nat, Nil) => tv(Len:Nat, cfg:largestUnsigned)
		[structural]	
	
	
	// rule bitSizeofList(T:Type :: L:List{Type}) => bitSizeofType(T:Type) + bitSizeofList(L:List{Type}) 
		// [structural]
	// rule bitSizeofList(Nil) => 0 [structural]
	
	op maxBitSizeofList : List{Type} -> K 
	op maxBitSizeofList-aux : List{Type} Nat -> K 
	rule maxBitSizeofList(L:List{Type}) => maxBitSizeofList-aux(L:List{Type}, 0) [structural]
	rule
		< k > maxBitSizeofList-aux(T:Type :: L:List{Type}, N:Nat) 
			=> bitSizeofType(T:Type) ~> maxBitSizeofList-aux(L:List{Type}, N:Nat) 
		...</ k >
		[structural] 
	rule
		< k > (tv(N':Nat, ?) => .) ~> maxBitSizeofList-aux(L:List{Type}, (N:Nat => maxNat(N:Nat, N':Nat))) ...</ k >
		[structural] 
	rule
		< k > maxBitSizeofList-aux(Nil, N:Nat) => tv(N:Nat, cfg:largestUnsigned) ...</ k >
		[structural] 
	
	rule bitSizeofType(t(?, arrayType(T:Type, N:Nat))) => bitSizeofType(T:Type) * tv(N:Nat, cfg:largestUnsigned) [structural]
	rule bitSizeofType(t(?, flexibleArrayType(T:Type))) => tv(0, cfg:largestUnsigned) [structural]
	rule bitSizeofType(t(?, functionType(?, ?))) => tv(numBitsPerByte, cfg:largestUnsigned) [structural]
	rule bitSizeofType(t(?, pointerType(?))) => tv(cfg:ptrsize *Nat numBitsPerByte, cfg:largestUnsigned) [structural]
	rule bitSizeofType(t(?, bitfieldType(?, N:Nat))) => tv(N:Nat, cfg:largestUnsigned) [structural]
	rule bitSizeofType(t(?, qualifiedType(T:Type, ?))) => bitSizeofType(T:Type) [structural]
	rule bitSizeofType(T:Type) => tv(numBits(T:Type), cfg:largestUnsigned) if isBasicType(T:Type) [structural]
	rule bitSizeofType(typedDeclaration(T:Type, ?)) => bitSizeofType(T:Type) [structural]

	rule
		< k > bitSizeofType(t(?, structType(S:Id))) => bitSizeofList(L:List{Type}) ...</ k >
		< structs >... S:Id |-> aggregateInfo(L:List{Type}, ?, ?) ...</ structs >
		[structural] 
	rule
		< k > bitSizeofType(t(?, unionType(S:Id))) => maxBitSizeofList(L:List{Type}) ...</ k >
		< structs >... S:Id |-> aggregateInfo(L:List{Type}, ?, ?) ...</ structs >
		[structural]
		
	rule K2Nat(N:Nat) => N:Nat [structural]

	rule getFieldOffset(F:Id, aggregateInfo(?, ?, (? F:Id |-> N:Nat))) => N:Nat [structural]
	rule getFieldType(F:Id, aggregateInfo(?, ?, (? F:Id |-> T:Type))) => T:Type [structural]

		
	rule toString(Identifier(S:String)) => S:String [structural]
	rule toString(S:String) => S:String [structural]
	rule toString(Num:Nat) => Int2String(Num:Nat) [structural]
	rule Rat2String(sym(N:Nat), M:NzNat) => "sym(" +String Rat2String(N:Nat, M:NzNat) +String ")" [structural]
	
	
	rule listToK(K:K) => klistToK(getList{K}(K:K)) [structural]
	rule klistToK((K:K,, L:List{K})) => K:K ~> klistToK(L:List{K}) [structural]
	rule klistToK(.List{K}) => .K [structural]
endkm


kmod COMMON-C-HELPERS is
	including COMMON-SEMANTICS-HELPERS-INCLUDE
	including COMMON-C-BITSIZE
	including COMMON-SEMANTICS-HELPERS-MISC
endkm
