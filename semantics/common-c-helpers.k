kmod COMMON-SEMANTICS-HELPERS-INCLUDE is
	including COMMON-INCLUDE 

endkm


kmod COMMON-SEMANTICS-HELPERS-MISC is 
	including COMMON-SEMANTIC-SYNTAX 
	including C-SETTINGS 
	
	
	--- this maintains byte order
	op fillToBytes-aux : K List{K} -> K 
	eq fillToBytes(dataList(L:List{K})) = fillToBytes-aux(dataList(L:List{K}), .List{K}) 
	ceq fillToBytes-aux(dataList((L:List{K},, piece(N:Nat, Len:Nat))), L':List{K}) 
		= fillToBytes-aux(dataList(L:List{K}), (piece(N:Nat, Len:Nat),, L':List{K}))
		if Len:Nat ==Bool numBitsPerByte 
	
	ceq fillToBytes-aux(dataList(piece(N:Nat, Len:Nat)), L':List{K})
		= fillToBytes-aux(dataList((piece(0, 1),, piece(N:Nat, Len:Nat))), L':List{K})
		if Len:Nat <Nat numBitsPerByte 
		
	ceq fillToBytes-aux(dataList((L:List{K},, piece(N:Nat, Len:Nat),, piece(N':Nat, Len':Nat))), L':List{K}) 
		= fillToBytes-aux(dataList((L:List{K},, piece(_bit::_(piece(N:Nat, Len:Nat), piece(N':Nat, Len':Nat)), Len:Nat +Nat Len':Nat))), L':List{K})
		if Len:Nat +Nat Len':Nat <=Nat numBitsPerByte 
				
	eq fillToBytes-aux(dataList(.List{K}), L:List{K})
		= dataList(L:List{K}) 
		
	--- coallesce bitranges that are adjacent
	ceq _bit::_(piece(bitRange(N:Nat, sNat(To:Nat), To':Nat), Len:Nat), piece(bitRange(N:Nat, From:Nat, To:Nat), Len':Nat)) 
		= piece(bitRange(N:Nat, From:Nat, To':Nat), Len:Nat +Nat Len':Nat) 
		if Len:Nat +Nat Len':Nat <=Nat numBitsPerByte 
	
	eq piece(N:Nat bit:: N':Nat, Len:Nat) bit:: piece(N'':Nat, Len':Nat)
		= piece(N:Nat bit:: N':Nat bit:: piece(N'':Nat, Len':Nat), Len:Nat +Nat Len':Nat) 

	eq piece(N'':Nat, Len':Nat) bit:: piece(N:Nat bit:: N':Nat, Len:Nat)
		= piece(piece(N'':Nat, Len':Nat) bit:: N:Nat bit:: N':Nat, Len:Nat +Nat Len':Nat) 

	ceq bitRange(N:Nat bit:: piece(?, Len:Nat), Pos:Nat, Pos:Nat)
		= bitRange(N:Nat, absInt(Pos:Nat -Int Len:Nat), absInt(Pos:Nat -Int Len:Nat))
		if Pos:Nat >Nat 0
		andBool Pos:Nat -Int Len:Nat >=Int 0 
		
	eq bitRange(? bit:: piece(N:Nat, 1), 0, 0) = piece(N:Nat, 1) 
	eq bitRange(piece(N:Nat, 1), 0, 0) = piece(N:Nat, 1) 
		
	ceq bitRange(piece(bitRange(N:Nat, Start:Nat, End:Nat), Len:Nat), 0, 0)
		= bitRange(piece(bitRange(N:Nat, Start:Nat, Start:Nat), 1), 0, 0) 
		if Start:Nat +Nat Len:Nat ==Bool sNat(End:Nat) 
	
	ceq bitRange(N:Nat, Pos:Nat, Pos:Nat) = 1 &Nat (N:Nat >>Nat Pos:Nat)
		if N:Nat >=Nat 0 
	ceq bitRange(piece(N:Nat, 1), Pos:Nat, Pos:Nat) = 1 &Nat (N:Nat >>Nat Pos:Nat)
		if N:Nat >=Nat 0 
		
	ceq bitRange(N:Nat, 0, To:Nat) = N:Nat
		if sNat(To:Nat) ==Bool numBitsPerByte 
	
	ceq bitRange(? bit:: piece(N:Nat, Len:Nat), Start:Nat, End:Nat) 
		= bitRange(piece(N:Nat, Len:Nat), Start:Nat, End:Nat)
		if sNat(End:Nat) <=Nat Len:Nat 
	
	eq bitRange(piece(N:Nat, sNat(End:Nat)), 0, End:Nat)
		= piece(N:Nat, sNat(End:Nat)) 
	eq bitRange(? bit:: piece(N:Nat, sNat(End:Nat)), 0, End:Nat)
		= piece(N:Nat, sNat(End:Nat)) 
		
	ceq bitRange(piece(N:Nat, Len:Nat), Pos:Nat, Pos:Nat) = (N:Nat >>Nat Pos:Nat) &Nat 1
		if N:Nat >=Nat 0 
	
	eq calculateLength(Nil) = 0 
	eq calculateLength(T:Type :: L:List{Type}) = calculateLength(T:Type) + calculateLength(L:List{Type}) 
	eq calculateLength(typedDeclaration(T:Type, ?)) = bitSizeofType(T:Type) 
	
	op extractField-pre : List{K} Type K K -> K [metadata "strict(3 4)"] 
	op extractField-aux : List{K} Type Nat Nat List{K} -> K 
	
	--- figureOffset(loc(0, 0), calcStructSize-aux(L1:List{KResult}, 0), T:Type)
	rule [extractField-from-struct-start]:
		< k > extractField(L:List{K}, structType(S:Id), F:Id)
			=> extractField-pre(L:List{K}, T:Type, calculateLength(L:List{Type}), bitSizeofType(T:Type)) ...</ k >
		< structs >... S:Id |-> (L:List{Type} :: typedDeclaration(T:Type, F:Id) :: ?:List{Type}) ...</ structs >
		[structural] 
		
	rule [extractField-from-union-start]:
		< k > extractField(L:List{K}, unionType(S:Id), F:Id)
			=> extractField-pre(L:List{K}, T:Type, tv(0, unsigned-long-int), bitSizeofType(T:Type)) ...</ k >
		< structs >... S:Id |-> (?:List{Type} :: typedDeclaration(T:Type, F:Id) :: ?:List{Type}) ...</ structs >
		[structural] 
		
	rule
		< k > extractField-pre(L:List{K}, T:Type, tv(Offset:Nat, ?), tv(Len:Nat, ?))
			=> concretize(T:Type, fillToBytes(extractBitsFromList(dataList(L:List{K}), Offset:Nat, Len:Nat)))
		...</ k >
		[structural] 
	
	eq isConcreteNumber(sym(?) +Nat ?) = false 
	eq isConcreteNumber(bito(?) +Nat ?) = false 
	ceq isConcreteNumber(I:Int) = true
		if  I:Int <=Int 0 orBool I:Int >Int 0 
	
	--- this should probably go in the k prelude

	eq K:K in (ListItem(K:K) ?) = true 
	eq K:K in (.).List = false 
	ceq K:K in (ListItem(K':K) L:List) = K:K in L:List
		if K:K =/=Bool K':K 
	
	rule [discard]:
		< k > V:Value ~> discard => .K ...</ k >
		[structural] 
	
	---- derived
	eq bitsToBytes(N:Nat) = absInt(ceilingRat(N:Nat /Rat numBitsPerByte)) 
		
	eq numBytes(unsigned-char) = numBytes(signed-char) 
	eq numBytes(unsigned-short-int) = numBytes(short-int) 
	eq numBytes(unsigned-int) = numBytes(int) 
	eq numBytes(unsigned-long-int) = numBytes(long-int) 
	eq numBytes(unsigned-long-long-int) = numBytes(long-long-int) 
	
	ceq numBits(T:Type) = numBytes(T:Type) *Nat numBitsPerByte 
		if getKLabel(T:Type) =/=Bool 'bitfieldType
	eq numBits(bitfieldType(?, N:Nat)) = N:Nat 

	eq min(bool) = 0 
	eq max(bool) = 1 
	
	eq min(signed-char) = -Int (2 ^Nat absInt(_-Int_(numBits(signed-char), 1))) 
	eq max(signed-char) = _-Int_(2 ^Nat absInt(_-Int_(numBits(signed-char), 1)), 1) 
	eq min(short-int) = -Int (2 ^Nat absInt(_-Int_(numBits(short-int), 1))) 
	eq max(short-int) = _-Int_(2 ^Nat absInt(_-Int_(numBits(short-int), 1)), 1) 
	eq min(int) = -Int (2 ^Nat absInt(_-Int_(numBits(int), 1))) 
	eq max(int) = _-Int_(2 ^Nat absInt(_-Int_(numBits(int), 1)), 1) 
	eq min(long-int) = -Int (2 ^Nat absInt(_-Int_(numBits(long-int), 1))) 
	eq max(long-int) = _-Int_(2 ^Nat absInt(_-Int_(numBits(long-int), 1)), 1) 
	eq min(long-long-int) = -Int (2 ^Nat absInt(_-Int_(numBits(long-long-int), 1))) 
	eq max(long-long-int) = _-Int_(2 ^Nat absInt(_-Int_(numBits(long-long-int), 1)), 1) 
	
	eq min(unsigned-char) = 0 
	eq max(unsigned-char) = _-Int_(2 ^Nat absInt(numBits(unsigned-char)), 1) 
	eq min(unsigned-short-int) = 0 
	eq max(unsigned-short-int) = _-Int_(2 ^Nat absInt(numBits(unsigned-short-int)), 1) 
	eq min(unsigned-int) = 0 
	eq max(unsigned-int) = _-Int_(2 ^Nat absInt(numBits(unsigned-int)), 1) 
	eq min(unsigned-long-int) = 0 
	eq max(unsigned-long-int) = _-Int_(2 ^Nat absInt(numBits(unsigned-long-int)), 1) 
	eq min(unsigned-long-long-int) = 0 
	eq max(unsigned-long-long-int) = _-Int_(2 ^Nat absInt(numBits(unsigned-long-long-int)), 1) 
	
	
	eq stringToChar(C:Char) = C:Char 
	eq asciiCharString(S:String) = asciiString(stringToChar(S:String)) 
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
		
	eq N:Nat to N:Nat = .List{K} 
	ceq N:Nat to N':Nat = (N:Nat,,((N:Nat +Nat 1) to N':Nat))
		if N:Nat <Nat N':Nat 

	--- Note: it only makes sense to memo this if the sets are just used to represent categories
	eq S:Set SetItem(K:K) contains K:K = true 
	ceq S:Set SetItem(K1:K) contains K2:K = S:Set contains K2:K 
		if K1:K =/=Bool K2:K 
	eq (.).Set contains K:K = false 

	eq hasIntegerType(T:Type) = hasUnsignedIntegerType(T:Type) orBool hasSignedIntegerType(T:Type) 
	
	ceq hasUnsignedIntegerType(T:Type) = true
		if (unsignedIntegerTypes contains T:Type) 

	ceq hasUnsignedIntegerType(T:Type) = false 
		if getKLabel(T:Type) =/=Bool 'bitfieldType
		andBool setOfTypes contains l(getKLabel(T:Type)) 
	ceq hasUnsignedIntegerType(bitfieldType(T:Type, ?)) = true 
		if hasUnsignedIntegerType(T:Type) ==Bool true 
	ceq hasUnsignedIntegerType(bitfieldType(T:Type, ?)) = false 
		if hasUnsignedIntegerType(T:Type) ==Bool false 
	
	ceq hasSignedIntegerType(T:Type) = true
		if (signedIntegerTypes contains T:Type) 
	eq hasSignedIntegerType(enumType(?)) = true --- choice fixme
	ceq hasSignedIntegerType(T:Type) = false 
		if getKLabel(T:Type) =/=Bool 'bitfieldType
		andBool setOfTypes contains l(getKLabel(T:Type)) 
	ceq hasSignedIntegerType(bitfieldType(T:Type, ?)) = true 
		if hasSignedIntegerType(T:Type) ==Bool true 
	ceq hasSignedIntegerType(bitfieldType(T:Type, ?)) = false 
		if hasSignedIntegerType(T:Type) ==Bool false 

	ceq min(bitfieldType(T:Type, N:Nat)) = 0
		if hasUnsignedIntegerType(T:Type) 
	ceq max(bitfieldType(T:Type, N:Nat)) = _-Int_(2 ^Nat absInt(N:Nat), 1)
		if hasUnsignedIntegerType(T:Type) 
	
	ceq min(bitfieldType(T:Type, N:Nat)) = -Int (2 ^Nat absInt(_-Int_(N:Nat, 1)))
		if hasSignedIntegerType(T:Type) 
	ceq max(bitfieldType(T:Type, N:Nat)) = _-Int_(2 ^Nat absInt(_-Int_(N:Nat, 1)), 1) 
		if hasSignedIntegerType(T:Type) 
endkm

kmod COMMON-C-HELPERS is
	including COMMON-SEMANTICS-HELPERS-INCLUDE
	
	including COMMON-SEMANTICS-HELPERS-MISC
endkm
