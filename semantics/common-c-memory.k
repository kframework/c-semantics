kmod COMMON-MEMORY-INCLUDE is
	including COMMON-INCLUDE 
	
	--- returns the bytes in the order in which they are in memory
	op extractBytesFromMem : Nat Nat -> K --- loc, size in bytes
	op encodedPointer : Int -> Nat
	op encodedFloat : Float -> Nat
	op explodeToBits : List{K} -> List{K}
	op reverseList : List{K} -> List{K}
	op bwrite : Nat K -> ListItem
	op locations : List -> Set
	op read-aux : K K K -> K
	
	eq locations(.List) = .Set
	eq locations(bwrite(Loc:Nat, ?) L:List) = SetItem(Loc:Nat) locations(L:List)
endkm

kmod COMMON-SEMANTICS-READING is
	including COMMON-MEMORY-INCLUDE 
	
	op extractBitsFromMem : Nat Nat -> K --- loc, size in bits
	op extractByteFromMem : Nat -> K 
	op getBitOffset : Nat -> Nat 
	eq getBitOffset(? +Nat bito(M:Nat)) = M:Nat 
	eq getBitOffset(?) = 0 [owise] 
	
	op extractBitsFromList : K Nat Nat List{K} -> K --- datalist, offset in bits into list, number of bits to extract, accumulator
	eq extractBitsFromList(dataList(L:List{K}), N:Nat, M:Nat) 
		= extractBitsFromList(dataList(explodeToBits(L:List{K})), N:Nat, M:Nat, .List{K}) 
	rule
		< k > extractBitsFromList(dataList((piece(?, 1),, L:List{K})), sNat(Offset:Nat), NumBits:Nat, .List{K})
			=> extractBitsFromList(dataList(L:List{K}), Offset:Nat, NumBits:Nat, .List{K})
		...</ k >
		[structural] 
	rule
		< k > extractBitsFromList(dataList((piece(N:Nat, 1),, L:List{K})), 0, sNat(NumBits:Nat), Done:List{K})
			=> extractBitsFromList(dataList(L:List{K}), 0, NumBits:Nat, (Done:List{K},, piece(N:Nat, 1)))
		...</ k >
		[structural] 

	rule
		< k > extractBitsFromList(?, 0, 0, Done:List{K}) => dataList(Done:List{K}) ...</ k >
		[structural] 
	
	
	context read-aux(?, ?, value(`[HOLE`]:K)) 
	ceq read(Loc:Nat, T:Type) = read-aux(Loc:Nat, T:Type, value(bitSizeofType(T:Type))) 
		if notBool(hasFunctionType(T:Type))
	
	
	
	rule [read-thread-local]:
		< k > read-aux(Loc, T:Type, bitSize:Nat)
			=> concretize(T:Type, fillToBytes(extractBitsFromMem(Loc, bitSize:Nat))) 
		...</ k >
		<threadId> Id:Nat </threadId>
		where Loc = sym(threadId(Id:Nat) +Nat N:Nat) +Nat Offset:Nat
		[structural]
	rule [read]: --- read global or shared data
		< k > read-aux(Loc, T:Type, bitSize:Nat)
			=> concretize(T:Type, fillToBytes(extractBitsFromMem(Loc, bitSize:Nat))) 
		...</ k >
		where Loc = sym(threadId(0) +Nat N:Nat) +Nat Offset:Nat
		[metadata "computational"] 
	rule [read-allocated]: --- read data of "allocated" duration
		< k > read-aux(Loc, T:Type, bitSize:Nat)
			=> concretize(T:Type, fillToBytes(extractBitsFromMem(Loc, bitSize:Nat))) 
		...</ k >
		where Loc = sym(threadId(allocatedDuration) +Nat N:Nat) +Nat Offset:Nat
		[metadata "computational"]
	rule [read-readonly]: --- read data that is readonly (e.g., string literals)
		< k > read-aux(Loc, T:Type, bitSize:Nat)
			=> concretize(T:Type, fillToBytes(extractBitsFromMem(Loc, bitSize:Nat))) 
		...</ k >
		where Loc = sym(threadId(readOnly) +Nat N:Nat) +Nat Offset:Nat
		[metadata "computational"] 
		
	op joinIntegerBytes : Type List{K} -> K 
	ceq concretize(T:Type, dataList(L:List{K})) = joinIntegerBytes(T:Type, L:List{K})
		if hasIntegerType(T:Type) 
		--- andBool isConcreteList(L:List{K}) 
		andBool notBool hasBitfieldType(T:Type) 
	ceq concretize(T:Type, dataList(L:List{K})) = joinIntegerBytes(T:Type, reverseList(L:List{K}))
		if hasIntegerType(T:Type) 
		--- andBool isConcreteList(L:List{K}) 
		andBool hasBitfieldType(T:Type) 
		
	--- FIXME very unsafe, not checking size of list or its contents
	ceq concretize(T:Type, dataList((piece(encodedFloat(F:Float), Len:Nat),, L:List{K}))) 
		= tv(F:Float, T:Type)
		if hasFloatType(T:Type)
		andBool Len:Nat ==Bool numBitsPerByte 
		--- andBool lengthList{K}(L:List{K}) ==Bool cfg:ptrsize -Int 1 
	--- fixme should also check sizes are appropriate
	--- fixme very unsafe as is.  doesn't care if other bytes were overwritten
	ceq concretize(pointerType(T:Type), dataList((piece(encodedPointer(N:Nat), Len:Nat),, L:List{K}))) 
		= tv(N:Nat, pointerType(T:Type))
		if Len:Nat ==Bool numBitsPerByte
		andBool lengthList{K}(L:List{K}) ==Bool cfg:ptrsize -Int 1 
		
	eq concretize(structType(S:Id), dataList(L:List{K})) = tv(L:List{K}, structType(S:Id)) 
	eq concretize(unionType(S:Id), dataList(L:List{K})) = tv(L:List{K}, unionType(S:Id)) 

	--- FIXME assuming bytes?
	op joinIntegerBytes : Type List{K} K -> K 
	eq joinIntegerBytes(T:Type, L:List{K}) = joinIntegerBytes(T:Type, L:List{K}, piece(0, 0)) 
	
	--- fixme may want to consider restricting further, or loosening
	ceq joinIntegerBytes(T:Type, piece(unknown(Len:Nat), Len:Nat), piece(0, 0))
		= tv(piece(unknown(Len:Nat), Len:Nat), T:Type)
		if Len:Nat ==Bool numBitsPerByte
		andBool hasCharType(T:Type) 
	
	ceq joinIntegerBytes(T:Type, (L:List{K},, piece(N:Nat, Len:Nat)), piece(N':Nat, Len':Nat))
		= joinIntegerBytes(T:Type, L:List{K}, piece(_bit::_(piece(N':Nat, Len':Nat), piece(N:Nat, Len:Nat)), Len:Nat +Nat Len':Nat))
		if Len:Nat ==Bool numBitsPerByte
		andBool N':Nat >=Nat 0 
		--- andBool N:Nat >=Nat 0 
	ceq joinIntegerBytes(T:Type, .List{K}, piece(N:Nat, Len:Nat)) 
		= interpret(T:Type, piece(N:Nat, Len:Nat)) 
		if N:Nat >=Nat 0 
	
	op isConcreteList : List{K} -> Bool 
	ceq isConcreteList((N:Nat,, L:List{K})) = isConcreteList(L:List{K})
		if isConcreteNumber(N:Nat) 
	eq isConcreteList(.List{K}) = true 

	
	eq floorLoc(sym(N:Nat) +Nat bito(M:Nat) +Nat R:Nat) = sym(N:Nat) +Nat R:Nat 
	eq floorLoc(sym(N:Nat) +Nat R:Nat) = sym(N:Nat) +Nat R:Nat [owise] 
	
	rule
		< k > extractBitsFromMem(Loc:Nat, Size:Nat)
			=> extractBitsFromList(extractBytesFromMem(floorLoc(Loc:Nat), bitsToBytes(Size:Nat)), getBitOffset(Loc:Nat), Size:Nat) 
		...</ k >
		--- if floorLoc(Loc:Nat) ==Bool Loc:Nat
		[structural] 
	
	context extractBytesFromMem-aux(?, ?, (?,, `[HOLE`]:K,, ?)) 
	--- this next op should use Nats, but the context doesn't allow it.  See issue 54
	op extractBytesFromMem-aux : K K List{K} -> K --- loc, size in bytes, aux list
	
	rule
		< k > extractBytesFromMem(Loc:Nat, Size:Nat) => extractBytesFromMem-aux(Loc:Nat, Size:Nat, .List{K}) ...</ k >
		[structural] 
		
	rule
		< k > extractBytesFromMem-aux(Loc:Nat, sNat(Size:Nat), Aux:List{K})
			=> extractBytesFromMem-aux(sNat(Loc:Nat), Size:Nat, (Aux:List{K},, extractByteFromMem(Loc:Nat)))
		...</ k >
		[structural] 
	
	op values : List{K} -> List{K} 
	eq values((tv(K:K, ?),, L:List{KResult})) = (K:K,, values(L:List{KResult})) 
	eq values(.List{K}) = .List{K} 
	rule
		< k > extractBytesFromMem-aux(?, 0, Aux:List{KResult}) => dataList(values(Aux:List{KResult})) ...</ k >
		[structural] 
	
	--- FIXME make sure it's a byte
	rule [read-byte]:
		< k > extractByteFromMem(sym(Block:Nat) +Nat Offset:Nat) => V:K ...</ k >
		< mem >... Block:Nat |-> memblock(Size:Nat, (? Offset:Nat |-> V:K)) ...</ mem >
		< locsWrittenTo > Locs:Bag </ locsWrittenTo >
		< buffer > Mem:List </ buffer >
		if notBool (sym(Block:Nat) +Nat Offset:Nat) in Locs:Bag
		andBool Offset:Nat <Nat Size:Nat
		andBool notBool sym(Block:Nat) +Nat Offset:Nat in locations(Mem:List)
		[structural]
		
	rule [read-byte-lazy]:
		< k > extractByteFromMem(sym(Block:Nat) +Nat Offset:Nat) => piece(unknown(numBitsPerByte), numBitsPerByte) ...</ k >
		< mem >... Block:Nat |-> memblock(Size:Nat, (M:Map => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset:Nat])) ...</ mem >
		< buffer > Mem:List </ buffer >
		if Offset:Nat <Nat Size:Nat
		andBool notBool sym(Block:Nat) +Nat Offset:Nat in locations(Mem:List)
		andBool notBool $hasMapping(M:Map, Offset:Nat)
		[structural]
		
	rule [read-byte-buffer]:
		< k > extractByteFromMem(Loc:Nat) => V:K ...</ k >
		< locsWrittenTo > Locs:Bag </ locsWrittenTo >
		< buffer >... bwrite(Loc:Nat, V:K) Mem:List </ buffer >
		if notBool Loc:Nat in Locs:Bag
		andBool notBool Loc:Nat in locations(Mem:List)
		[metadata "computational"] --- for speed in interpretation; forces local buffer to be flushed before a read
		--- [structural]
endkm

kmod COMMON-SEMANTICS-WRITING is
	including COMMON-MEMORY-INCLUDE 
	context alloc(?, value(`[HOLE`]:K)) 

	rule allocateType(Loc:Nat, T:Type) => alloc(Loc:Nat, value(byteSizeofType(T:Type))) 
		[structural] 
	rule 
		< k > allocateTypeIfAbsent(Loc:Nat, T:Type) => alloc(Loc:Nat, value(byteSizeofType(T:Type))) ...</ k >
		< mem > Mem:Map </ mem >
		if notBool $hasMapping(Mem:Map, Loc:Nat)
		[structural] 
	rule 
		< k > allocateTypeIfAbsent(Loc:Nat, T:Type) => .K ...</ k >
		< mem >... Loc:Nat |-> ? ...</ mem >
		[structural] 
	
	--- rule
		--- < k > alloc(sym(Block:Nat) +Nat 0, Len:Nat) => .K ...</ k >
		--- < mem >... .Map => Block:Nat |-> memblock(Len:Nat, .Map[piece(unknown(numBitsPerByte), numBitsPerByte) / 0 to Len:Nat]) ...</ mem >
		--- [structural]	

	rule [alloc-lazy]:
		< k > alloc(sym(Block:Nat) +Nat 0, Len:Nat) => .K ...</ k >
		< mem >... .Map => Block:Nat |-> memblock(Len:Nat, .Map) ...</ mem >
		[structural]		
		
	op writeBytes : Nat K -> K [metadata "strict(2)"] 
	op writeBitfield : Nat Type K -> K [metadata "strict(3)"] 
	op isByteLoc : Nat -> Bool 
	op splitBytes : Value -> K 
	op calculateNewBytes : Nat K K -> K [metadata "strict(3)"] 
	
	op write-aux : K Value K -> K [metadata "strict(2)"] 
	ceq write(K:K, tv(V:List{K}, T:Type)) 
		= write-aux(K:K, tv(V:List{K}, T:Type), value(bitSizeofType(T:Type))) 
		if notBool(hasFunctionType(T:Type)) 
	--- FIXME should check types
	// rule
		// < k > write(Loc:Nat, tv(V:K, T:Type)) 
			// => writeByte(Loc:Nat, V:K) 
		// ...</ k >
		// if hasFunctionType(T:Type)
		// [structural]
	context write-aux(?, ?, value(`[HOLE`]))
	
	
	op datarace : Nat Nat Nat Nat -> K 
	--- fixme possible to miss dataraces with bitfields
	--- rule [read-write-race]:
		--- < T >... 
			--- < k > read-aux(Loc:Nat, ?, BitSize:Nat) ...</ k >
			--- < k > write-aux(Loc':Nat, ?, BitSize':Nat) ...</ k >
		--- ...</ T >
		--- => < errorCell > datarace(Loc:Nat, BitSize:Nat, Loc':Nat, BitSize':Nat) </ errorCell >
		--- if (Start1 <=Nat Start2 andBool End1 >=Nat Start2)
		--- orBool (Start1 >Nat Start2 andBool Start1 <=Nat End2)
		--- where Start1 = Loc:Nat
		--- and End1 = Loc:Nat +Nat (Loc:Nat +Nat bitsToBytes(BitSize:Nat))
		--- and Start2 = Loc':Nat
		--- and End2 = Loc':Nat +Nat (Loc':Nat +Nat bitsToBytes(BitSize':Nat))
		--- [metadata "computational"]
		
	rule [read-write-race]:
		< T > 
			? 
			< threads > 
				?
				< thread > ? < control > ? < k > read-aux(Loc:Nat, ?, BitSize:Nat) ...</ k > </ control > </ thread >
				< thread > ? < control > ? < k > write-aux(Loc':Nat, ?, BitSize':Nat) ...</ k > </ control > </ thread >
			</ threads > 
		</ T >
		=> < errorCell > datarace(Loc:Nat, BitSize:Nat, Loc':Nat, BitSize':Nat) </ errorCell >
		if (Start1 <=Nat Start2 andBool End1 >=Nat Start2)
		orBool (Start1 >Nat Start2 andBool Start1 <=Nat End2)
		where Start1 = Loc:Nat
		and End1 = Loc:Nat +Nat bitsToBytes(BitSize:Nat)
		and Start2 = Loc':Nat
		and End2 = Loc':Nat +Nat bitsToBytes(BitSize':Nat)
		[metadata "computational"]
		
	--- rule [write-write-race]:
		--- < T > ? <threads> ?
			--- <thread> ? < control > ? < k > write-aux(Loc:Nat, ?, BitSize:Nat) ...</ k > </ control > </thread>
			--- <thread> ? < control > ? < k > write-aux(Loc':Nat, ?, BitSize':Nat) ...</ k > </ control > </thread>
		--- </threads> </ T >
		--- => < errorCell > datarace(Loc:Nat, BitSize:Nat, Loc':Nat, BitSize':Nat) </ errorCell >
		--- if (Start1 <=Nat Start2 andBool End1 >=Nat Start2)
		--- orBool (Start1 >Nat Start2 andBool Start1 <=Nat End2)
		--- where Start1 = Loc:Nat
		--- and End1 = Loc:Nat +Nat (Loc:Nat +Nat bitsToBytes(BitSize:Nat))
		--- and Start2 = Loc':Nat
		--- and End2 = Loc':Nat +Nat (Loc':Nat +Nat bitsToBytes(BitSize':Nat))
		--- [metadata "computational"]
		
	rule [write-write-race]:
		< T > 
			? 
			< threads > 
				?
				< thread > ? < control > ? < k > write-aux(Loc:Nat, ?, BitSize:Nat) ...</ k > </ control > </ thread >
				< thread > ? < control > ? < k > write-aux(Loc':Nat, ?, BitSize':Nat) ...</ k > </ control > </ thread >
			</ threads > 
		</ T >
		=> < errorCell > datarace(Loc:Nat, BitSize:Nat, Loc':Nat, BitSize':Nat) </ errorCell >
		if (Start1 <=Nat Start2 andBool End1 >=Nat Start2)
		orBool (Start1 >Nat Start2 andBool Start1 <=Nat End2)
		where Start1 = Loc:Nat
		and End1 = Loc:Nat +Nat bitsToBytes(BitSize:Nat)
		and Start2 = Loc':Nat
		and End2 = Loc':Nat +Nat bitsToBytes(BitSize':Nat)
		[metadata "computational"]
	
	op write-specific : Nat Value Nat -> K
	
	rule [write-thread-local]:
		< k > write-aux(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
			=> write-specific(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
		...</ k >
		<threadId> Id:Nat </threadId>
		where Loc = sym(threadId(Id:Nat) +Nat N:Nat) +Nat Offset:Nat
		[structural]
	rule [write]: --- write global or shared data
		< k > write-aux(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
			=> write-specific(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
		...</ k >
		where Loc = sym(threadId(0) +Nat N:Nat) +Nat Offset:Nat
		[metadata "computational"]
	rule [write-allocated]: --- write data of "allocated" duration
		< k > write-aux(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
			=> write-specific(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
		...</ k >
		where Loc = sym(threadId(allocatedDuration) +Nat N:Nat) +Nat Offset:Nat
		[metadata "computational"]
	
	rule [write-normal]:
		< k > write-specific(Loc:Nat, tv(V:K, T:Type), bitSize:Nat)
			=> writeBytes(Loc:Nat, splitBytes(tv(V:K, T:Type)))
		...</ k >
		if bitSize:Nat %Nat numBitsPerByte ==Bool 0
		andBool isByteLoc(Loc:Nat)
		andBool notBool hasBitfieldType(T:Type)
		[structural]
	
	
	rule [write-struct]:
		< k > write-specific(Loc:Nat, tv((V:K,, V':K,, L:List{K}), T:Type), bitSize:Nat)
			=> writeBytes(Loc:Nat, dataList((V:K,, V':K,, L:List{K})))
		...</ k >
		if bitSize:Nat %Nat numBitsPerByte ==Bool 0
		andBool isByteLoc(Loc:Nat)
		andBool notBool hasBitfieldType(T:Type)
		[structural]
		
	eq bitoffset(? +Nat bito(N:Nat)) = N:Nat 
	eq bitoffset(?) = 0 [owise] 
	

	eq byteoffset(N:Nat +Nat bito(?)) = N:Nat 
	eq byteoffset(N:Nat) = N:Nat [owise] 
		
	op justBits : Int Type -> Value 
	op justBits-aux : Int Type -> Value 
	ceq justBits(I:Int, ?) = I:Int
		if I:Int >=Int 0 
		
	ceq justBits(I:Int, T:Type) = justBits-aux(I:Int, T:Type)
		if I:Int <Int 0 
	ceq justBits-aux(I:Int, T:Type) = justBits-aux((I:Int +Int max(T:Type) +Int 1), T:Type)
		if I:Int <Int 0 
	eq justBits-aux(N:Nat, bitfieldType(T:Type, sNat(Len:Nat))) = N:Nat +Nat (1 <<Nat Len:Nat) 
	
	rule [massage-bitfield]:
		< k > write-specific(Loc:Nat, tv(I:Int, T:Type), bitSize:Nat)
			=> write-specific(Loc:Nat, tv(justBits(I:Int, T:Type), T:Type), bitSize:Nat)
		...</ k >
		if (bitSize:Nat %Nat numBitsPerByte =/=Bool 0
		orBool notBool(isByteLoc(Loc:Nat))
		orBool hasBitfieldType(T:Type))
		andBool I:Int <Int 0
		[structural]
	
	rule [write-bitfield]:
		< k > write-specific(Loc:Nat, tv(N:Nat, T:Type), bitSize:Nat)
			=> writeBitfield(Loc:Nat, T:Type, calculateNewBytes(bitoffset(Loc:Nat), piece(N:Nat, bitSize:Nat), extractBytesFromMem(floorLoc(Loc:Nat), bitsToBytes(bitSize:Nat +Nat bitoffset(Loc:Nat)))))
		...</ k >
		if bitSize:Nat %Nat numBitsPerByte =/=Bool 0
		orBool notBool(isByteLoc(Loc:Nat))
		orBool hasBitfieldType(T:Type)
		[structural]
		
	rule
		< k > writeBitfield(Loc:Nat, ?, dataList(L:List{K}))
			=> writeBytes(byteoffset(Loc:Nat), dataList(L:List{K}))
		...</ k >
		[structural] 
		
	op calculateNewBytes-aux : Nat K K List{K} -> K 
	eq calculateNewBytes(Len:Nat, N:Nat, dataList(L:List{K})) = calculateNewBytes-aux(Len:Nat, dataList(explodeToBits(N:Nat)), dataList(explodeToBits(L:List{K})), .List{K}) 
	
	eq reverseList(.List{K}) = .List{K} 
	eq reverseList((K:K,, L:List{K})) = reverseList(L:List{K}),, K:K 
	
	op joinBitsToBytes : List{K} -> K 
	op joinBitsToBytes-aux : K K -> K 
	
	eq calculateNewBytes-aux(sNat(N:Nat), K:K, dataList((piece(Bit:Nat, 1),, L:List{K})), Result:List{K}) 
		= calculateNewBytes-aux(N:Nat, K:K, dataList(L:List{K}), (Result:List{K},, piece(Bit:Nat, 1))) 
	
	eq calculateNewBytes-aux(0, dataList((piece(N:Nat, 1),, L:List{K})), dataList((piece(?, 1),, L':List{K})), Result:List{K}) 
		= calculateNewBytes-aux(0, dataList(L:List{K}), dataList(L':List{K}), (Result:List{K},, piece(N:Nat, 1))) 
	eq calculateNewBytes-aux(0, dataList(.List{K}), dataList(L:List{K}), Result:List{K}) 
		= joinBitsToBytes((Result:List{K},, L:List{K})) 
	
	eq joinBitsToBytes(L:List{K}) = joinBitsToBytes-aux(dataList(L:List{K}), dataList(.List{K})) 
	ceq joinBitsToBytes-aux(dataList((piece(N:Nat, Len:Nat),, piece(M:Nat, 1),, L:List{K})), dataList(R:List{K}))
		= joinBitsToBytes-aux(dataList((piece(_bit::_(piece(N:Nat, Len:Nat), piece(M:Nat, 1)), sNat(Len:Nat)),, L:List{K})), dataList(R:List{K}))
		if Len:Nat <Nat numBitsPerByte 
	ceq joinBitsToBytes-aux(dataList((piece(N:Nat, Len:Nat),, L:List{K})), dataList(R:List{K}))
		= joinBitsToBytes-aux(dataList(L:List{K}), dataList((R:List{K},, piece(N:Nat, Len:Nat))))
		if Len:Nat ==Bool numBitsPerByte 
	eq joinBitsToBytes-aux(dataList(.List{K}), dataList(R:List{K}))
		= dataList(R:List{K}) 
	
	
	eq explodeToBits((K:K,, L:NeList{K})) = (explodeToBits(K:K),, explodeToBits(L:NeList{K})) 
	eq explodeToBits(piece(N:Nat, sNat(Len:Nat)))
		= splinter(N:Nat, sNat(Len:Nat)) 
	eq explodeToBits(piece(N:Nat, 0)) = .List{K} 
	eq explodeToBits(.List{K}) = .List{K} 
	
	op splinter : Nat Nat -> List{K} 
	op splinter-aux : Nat Nat Nat -> List{K} 
	eq splinter(N:Nat, Len:Nat) = splinter-aux(N:Nat, Len:Nat, 0) 
	eq splinter-aux(?, Len:Nat, Len:Nat) = .List{K} 
	ceq splinter-aux(N:Nat, Len:Nat, Pos:Nat)
		= splinter-aux(N:Nat, Len:Nat, sNat(Pos:Nat)),, piece(bitRange(N:Nat, Pos:Nat, Pos:Nat), 1)
		if Pos:Nat <Nat Len:Nat 
	

	rule
		< k > writeBytes(sym(Block:Nat) +Nat Offset:Nat, dataList((V:K,, L:List{K})))
			=> writeByte(sym(Block:Nat) +Nat Offset:Nat, V:K)
			~> writeBytes(sym(Block:Nat) +Nat sNat(Offset:Nat), dataList(L:List{K}))
		...</ k >
		[structural]
	rule [write-byte-buffer]:
		< k > writeByte(Loc:Nat, V:K) => .K ...</ k >
		< buffer >... (.List => bwrite(Loc:Nat, V:K)) </ buffer >
		< locsWrittenTo > Locs:Bag (.Bag => BagItem(Loc:Nat)) </ locsWrittenTo >
		if notBool Loc:Nat in Locs:Bag
		[structural] 
		--- [metadata "computational"]
		
	rule [commit-byte]:
		< blocked > false </ blocked >
		< buffer > (bwrite(sym(Block:Nat) +Nat Offset:Nat, V:K) => .List) ...</ buffer >
		< mem >... Block:Nat |-> memblock(Len:Nat, (M:Map => M:Map[V:K / Offset:Nat])) ...</ mem >
		if Offset:Nat <Nat Len:Nat
		[structural]
		--- [metadata "computational"]
	rule
		< k > writeBytes(?, dataList(.List{K})) => .K ...</ k >
		[structural] 
		
	--- this general rule is useful for unknowns, abstracts, etc
	rule splitBytes(tv(N:Nat, T:Type))
		=> dataList(piece(N:Nat, numBitsPerByte))
		if hasCharType(T:Type)
		[structural] 
	rule splitBytes(tv(I:Int, T:Type)) 
		=> splitIntegerBytes(I:Int, T:Type, value(byteSizeofType(T:Type)))
		if hasIntegerType(T:Type)
		andBool (I:Int >=Int 0 orBool I:Int <=Int 0)
		[structural] 
	rule splitBytes(tv(F:Float, T:Type)) 
		=> splitFloatBytes(F:Float, T:Type, value(byteSizeofType(T:Type)))
		if hasFloatType(T:Type)
		[structural] 
	rule splitBytes(tv(I:Int, pointerType(T:Type))) 
		=> splitPointerBytes(I:Int, pointerType(T:Type), value(byteSizeofType(pointerType(T:Type))))
		[structural] 
	rule splitBytes(tv(I:Int, arrayType(T:Type, ?))) 
		=> splitPointerBytes(I:Int, pointerType(T:Type), value(byteSizeofType(pointerType(T:Type))))
		[structural] 
	rule splitBytes(tv(L:List{K}, T:Type)) 
		=> splitStructBytes(dataList(L:List{K}), T:Type, value(byteSizeofType(T:Type)))
		if hasStructType(T:Type)
		[structural] 
	
	op splitIntegerBytes : K K K -> K 
	op splitIntegerBytes : K K K List{K} -> K 
	context splitIntegerBytes(?, ?, value(`[HOLE`]:K)) 
	eq splitIntegerBytes(I:Int, T:Type, Len:Nat) = splitIntegerBytes(I:Int, T:Type, Len:Nat, .List{K}) 
	eq splitIntegerBytes(I:Int, T:Type, sNat(Len:Nat), L:List{K})
		= splitIntegerBytes(I:Int >>Int numBitsPerByte, T:Type, Len:Nat, (L:List{K},, lowestByte(I:Int, T:Type))) 
	eq splitIntegerBytes(?, ?, 0, L:List{K})
		= dataList(L:List{K}) 
		
	op splitStructBytes : K K K -> K 
	op splitStructBytes : K K K List{K} -> K 
	context splitStructBytes(?, ?, value(`[HOLE`]:K)) 
	eq splitStructBytes(dataList(L:List{K}), T:Type, Len:Nat) = splitStructBytes(dataList(L:List{K}), T:Type, Len:Nat, .List{K}) 
	ceq splitStructBytes(dataList((piece(N:Nat, PieceLen:Nat),, Rest:List{K})), T:Type, sNat(Len:Nat), L:List{K})
		= splitStructBytes(dataList(Rest:List{K}), T:Type, Len:Nat, (L:List{K},, piece(N:Nat, PieceLen:Nat))) 
		if PieceLen:Nat ==Bool numBitsPerByte 
	eq splitStructBytes(?, ?, 0, L:List{K})
		= dataList(L:List{K}) 
		
		
	op splitPointerBytes : K K K -> K 
	op splitPointerBytes : K K K List{K} -> K 
	context splitPointerBytes(?, ?, value(`[HOLE`]:K)) 
	eq splitPointerBytes(I:Int, T:Type, sNat(Len:Nat)) 
		= splitPointerBytes(I:Int, T:Type, Len:Nat, piece(encodedPointer(I:Int), numBitsPerByte)) 
	eq splitPointerBytes(I:Int, T:Type, sNat(Len:Nat), L:List{K}) = splitPointerBytes(I:Int, T:Type, Len:Nat, (L:List{K},, piece(unknown(numBitsPerByte), numBitsPerByte))) 
	eq splitPointerBytes(?, ?, 0, L:List{K}) 
		= dataList(L:List{K}) 
		
		
	op splitFloatBytes : K K K -> K 
	op splitFloatBytes : K K K List{K} -> K 
	context splitFloatBytes(?, ?, value(`[HOLE`]:K)) 
	eq splitFloatBytes(F:Float, T:Type, sNat(Len:Nat)) 
		= splitFloatBytes(F:Float, T:Type, Len:Nat, piece(encodedFloat(F:Float), numBitsPerByte)) 
	eq splitFloatBytes(F:Float, T:Type, sNat(Len:Nat), L:List{K}) = splitFloatBytes(F:Float, T:Type, Len:Nat, (L:List{K},, piece(unknown(numBitsPerByte), numBitsPerByte))) 
	eq splitFloatBytes(?, T:Type, 0, L:List{K}) 
		= dataList(L:List{K}) 
		
	
	op lowestByte : Int Type -> K 
	ceq lowestByte(I:Int, T:Type) = piece(I:Int &Int byteMaskSet, numBitsPerByte)
		if hasIntegerType(T:Type) 
	
	op byteMaskSet : -> Nat
	eq byteMaskSet = (2 ^Nat numBitsPerByte) -Int 1 
		
	eq isByteLoc(? +Nat bito(?)) = false 
	eq isByteLoc(?) = true [owise] 
endkm

kmod COMMON-C-MEMORY-MISC is
	including COMMON-MEMORY-INCLUDE 

	--- used by calloc
	rule
		< k > zeroBlock(sym(Block:Nat) +Nat 0) => .K ...</ k >
		< mem >... Block:Nat |-> memblock(Len:Nat, (? => .Map[piece(0, numBitsPerByte) / 0 to Len:Nat])) ...</ mem >
		[structural]
		
	rule
		< k > sizeofLocation(sym(Block:Nat) +Nat ?) => tv(Len:Nat, cfg:sizeut) ...</ k >
		< mem >... Block:Nat |-> memblock(Len:Nat, ?) ...</ mem >
		[structural]
	
	--- used for variadic functions
	// rule [append-existing]:
		// < k > append(sym(Block:Nat) +Nat 0, Len:Nat, V:Value) 
			// => write(sym(Block:Nat) +Nat OldLen:Nat, V:Value)
		// ...</ k >
		// < mem >... Block:Nat |-> memblock((OldLen:Nat => OldLen:Nat +Nat Len:Nat), M:Map) ...</ mem >
		// [structural] 	
	
	rule [delete-sized-block]:
		< k > deleteSizedBlock(sym(Block:Nat) +Nat ?, Len:Nat) => .K ...</ k >
		< mem >... Block:Nat |-> memblock(Len:Nat, ?) => .Map ...</ mem >
		< buffer > .List </ buffer > --- fixme could make this more relaxed by checking of block is in buffer, not just empty
		[structural] 
	
	rule [delete-block]:
		< k > deleteBlock(sym(Block:Nat) +Nat ?) => .K ...</ k >
		< mem >... Block:Nat |-> ? => .Map ...</ mem >
		< buffer > .List </ buffer >
		[structural] 
	
	--- c99 6.5:2 If a side effect on a scalar object is unsequenced relative to either a different side effect on the same scalar object or a value computation using the value of the same scalar object, the behavior is undefined. If there are multiple allowable orderings of the subexpressions of an expression, the behavior is undefined if such an unsequenced side effect occurs in any of the orderings
	--- i take this to mean that if i write to a location twice or read from a location after being written to, then it is a problem
		
	op writeString : Nat String -> K 
	rule [alloc-string]:
		< k > allocString(Loc:Nat, S:String)
			=> allocateType(Loc:Nat, arrayType(char, lengthString(S:String)))
			~> writeString(Loc:Nat, S:String)
		...</ k >
		[structural] 
		
	rule [write-string]:
		< k > writeString(Loc:Nat, S:String)
			=> Computation(*(tv(Loc:Nat, pointerType(char))) := tv(charToAscii(firstChar(S:String)), char))
			~> writeString(sNat(Loc:Nat), butFirstChar(S:String))
		...</ k >
		if S:String =/=Bool ""
		[structural] 
		
	rule [write-empty-string]:
		< k > writeString(Loc:Nat, "") 
			=> .K
		...</ k >
		[structural]
endkm

kmod COMMON-C-MEMORY is
	including COMMON-MEMORY-INCLUDE 
	including COMMON-C-MEMORY-MISC 
	including COMMON-SEMANTICS-WRITING 
	including COMMON-SEMANTICS-READING 
endkm
