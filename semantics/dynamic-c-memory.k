kmod DYNAMIC-MEMORY-INCLUDE is
	including DYNAMIC-INCLUDE 
	
	// returns the bytes in the order in which they are in memory
	op extractBytesFromMem : Nat Nat -> K // loc, size in bytes
	op encodedPointer : Int -> Nat
	op encodedFloat : Float -> Nat
	op explodeToBits : List{K} -> List{K}
	op reverseList : List{K} -> List{K}
	op bwrite : Nat K -> ListItem
	op locations : List -> Set
	op read-aux : K K K -> K
	// fixme!!! This should be read-aux, but a bug in the K tool...
	
	
	// rule [locations-none]: locations(.List) => .Set [structural]
	// rule [locations-some]: locations(bwrite(Loc:Nat, ?) L:List) => SetItem(Loc:Nat) locations(L:List) [structural]
endkm

kmod DYNAMIC-SEMANTICS-READING is
	including DYNAMIC-MEMORY-INCLUDE 
	
	op extractBitsFromMem : Nat Nat -> K // loc, size in bits
	op extractByteFromMem : Nat -> K 
	op getBitOffset : Nat -> Nat 
	// rule getBitOffset(? +Nat bito(M:Nat)) => M:Nat [structural]
	// // fixme owise!!!!
	// eq getBitOffset(?) = 0 [owise]
	
	op extractBitsFromList-aux : K Nat Nat List{K} -> K // datalist, offset in bits into list, number of bits to extract, accumulator
	// rule extractBitsFromList(dataList(L:List{K}), N:Nat, M:Nat) 
		// => extractBitsFromList-aux(dataList(explodeToBits(L:List{K})), N:Nat, M:Nat, .List{K})
		// // if M:Nat =/=Bool 10
		// [structural]
	// rule
		// < k > extractBitsFromList-aux(dataList((piece(?, 1),, L:List{K})), sNat(Offset:Nat), NumBits:Nat, .List{K})
			// => extractBitsFromList-aux(dataList(L:List{K}), Offset:Nat, NumBits:Nat, .List{K})
		// ...</ k >
		// [structural] 
	// rule
		// < k > extractBitsFromList-aux(dataList((piece(N:Nat, 1),, L:List{K})), 0, sNat(NumBits:Nat), Done:List{K})
			// => extractBitsFromList-aux(dataList(L:List{K}), 0, NumBits:Nat, (Done:List{K},, piece(N:Nat, 1)))
		// ...</ k >
		// [structural] 
	
	// rule
		// < k > extractBitsFromList-aux(?, 0, 0, Done:List{K}) => dataList(Done:List{K}) ...</ k >
		// [structural] 
	
	
	// context read-aux(?, ?, value(`[HOLE`]:K)) 
	// rule read(Loc:Nat, T:Type) => read-aux(Loc:Nat, T:Type, value(bitSizeofType(T:Type))) 
		// if notBool(hasFunctionType(T:Type))
		// [structural]
	
	
	
	op readActual : K K K -> K
	
	/*@ These rules figure out whether the read should be structural or computational, depending on what is being read
	*/
	// rule [read-thread-local]:
		// < k > ('read-aux => 'readActual)(sym(threadId(Id:Nat) +Nat ?) +Nat ?,, ?,, ?) ...</ k >
		// <threadId> Id:Nat </threadId>
		// [structural metadata "nd=(true)"]
	// rule [read-shared]: // read global or shared data
		// < k > ('read-aux => 'readActual)(sym(threadId(0) +Nat ?) +Nat ?,, ?,, ?) ...</ k >
		// [metadata "computational=() nd=(true)"] 
	// rule [read-allocated]: // read data of "allocated" duration
		// < k > ('read-aux => 'readActual)(sym(threadId(allocatedDuration) +Nat ?) +Nat ?,, ?,, ?) ...</ k >
		// [metadata "computational=() nd=(true)"]
	// // rule [read-readonly]: // read data that is readonly (e.g., string literals)
		// // < k > ('read-aux => 'readActual)(sym(threadId(readOnly) +Nat ?) +Nat ?,, ?,, ?) ...</ k >
		// // [metadata "computational=() nd=(true)"] 
	
	// rule [read]:
		// < k > readActual(Loc:Nat, T:Type, bitSize:Nat)
			// => concretize(T:Type, extractBytesFromMem(Loc:Nat, bitsToBytes(bitSize:Nat)))
		// ...</ k >
		// if notBool hasBitfieldType(T:Type)
		// [structural]
	// rule [read-bitfield]:
		// < k > readActual(Loc:Nat, T:Type, bitSize:Nat)
			// => concretize(T:Type, fillToBytes(extractBitsFromMem(Loc:Nat, bitSize:Nat))) 
		// ...</ k >
		// if hasBitfieldType(T:Type)
		// [structural]
	
		
	op joinIntegerBytes : Type List{K} -> K 
	// rule 
		// < k > concretize(T:Type, dataList(L:List{K})) 
			// => joinIntegerBytes(T:Type, L:List{K}) 
		// ...</ k >
		// if hasIntegerType(T:Type) 
		// andBool notBool hasBitfieldType(T:Type) 
		// [structural]
	// rule 
		// < k > concretize(bitfieldType(T:Type, Len:Nat), dataList(L:List{K})) 
			// => joinIntegerBytes(bitfieldType(T:Type, Len:Nat), reverseList(L:List{K})) 
		// ...</ k >
		// //if // hasIntegerType(T:Type) // redundant
		// //hasBitfieldType(T:Type) 
		// [structural]
		
	// // FIXME very unsafe, not checking size of list or its contents
	// rule < k > concretize(T:Type, dataList((piece(encodedFloat(F:Float), Len:Nat),, ?))) 
			// => tv(F:Float, T:Type)
		// ...</ k >
		// if hasFloatType(T:Type)
		// andBool Len:Nat ==Bool numBitsPerByte 
		// [structural]

	// // fixme should also check sizes are appropriate
	// // fixme very unsafe as is.  doesn't care if other bytes were overwritten
	// rule < k > concretize(pointerType(T:Type), dataList((piece(encodedPointer(N:Nat), Len:Nat),, ?))) 
			// => checkValidLoc(N:Nat)
			// ~> tv(N:Nat, pointerType(T:Type))
		// ...</ k >
		// if Len:Nat ==Bool numBitsPerByte
		// [structural]
	// rule < k > concretize(structType(S:Id), dataList(L:List{K})) 
			// => tv(L:List{K}, structType(S:Id)) 
		// ...</ k >
		// // if hasStructType(T:Type)
		// [structural]
	// rule < k > concretize(unionType(S:Id), dataList(L:List{K})) 
			// => tv(L:List{K}, unionType(S:Id))
		// ...</ k >
		// // if hasUnionType(T:Type)
		// [structural]

	// FIXME assuming bytes?
	op joinIntegerBytes-aux : Type List{K} K -> K 
	// rule [joinIntegerBytes-start]:
		// joinIntegerBytes(T:Type, L:List{K}) 
			// => joinIntegerBytes-aux(T:Type, L:List{K}, piece(0, 0)) 
		// [structural]
	
	// // fixme may want to consider restricting further, or loosening
	// rule [joinIntegerBytes-unknown-char]:
		// joinIntegerBytes-aux(T:Type, piece(unknown(Len:Nat), Len:Nat), piece(0, 0))
			// => tv(piece(unknown(Len:Nat), Len:Nat), T:Type)
		// if hasCharType(T:Type)
		// [structural]
	
	// rule [joinIntegerBytes-step]:
		// joinIntegerBytes-aux(T:Type, (L:List{K},, piece(N:Nat, Len:Nat)), piece(N':Nat, Len':Nat))
			// => joinIntegerBytes-aux(T:Type, L:List{K}, piece(_bit::_(piece(N':Nat, Len':Nat), piece(N:Nat, Len:Nat)), Len:Nat +Nat Len':Nat))
		// if N':Nat >=Nat 0 // guard is here to make sure it's an actual piece
		// [structural]
	// rule [joinIntegerBytes-done]:
		// joinIntegerBytes-aux(T:Type, .List{K}, piece(N:Nat, Len:Nat)) 
			// => interpret(T:Type, piece(N:Nat, Len:Nat)) 
		// if N:Nat >=Nat 0 // guard is here to make sure it's an actual piece
		// [structural]
	
	// rule floorLoc(sym(N:Nat) +Nat bito(M:Nat) +Nat R:Nat) => sym(N:Nat) +Nat R:Nat [structural]
	// // fixme owise!!!
	// eq floorLoc(sym(N:Nat) +Nat R:Nat) = sym(N:Nat) +Nat R:Nat [owise] 
	
	// rule [ceilingLoc-null]: ceilingLoc(NullPointer) => NullPointer [structural]
	// rule [ceilingLoc-bito]: ceilingLoc(sym(N:Nat) +Nat bito(M:Nat) +Nat R:Nat)
		// => sym(N:Nat) +Nat absInt(floorRat(M:Nat /Rat numBitsPerByte)) +Nat R:Nat
		// [structural]
	// // fixme owise!!!
	// eq [ceilingLocNormal]: ceilingLoc(sym(N:Nat) +Nat R:Nat) = sym(N:Nat) +Nat R:Nat [owise] 
	
	// rule
		// < k > extractBitsFromMem(Loc:Nat, Size:Nat)
			// => extractBitsFromList(
				// extractBytesFromMem(floorLoc(Loc:Nat), bitsToBytes(Size:Nat +Nat getBitOffset(Loc:Nat)))
				// , getBitOffset(Loc:Nat)
				// , Size:Nat
			// )
		// ...</ k >
		// [structural] 
	
	// context extractBytesFromMem-aux(?, ?, (?,, [HOLE],, ?)) 
	// this next op should use Nats, but the context doesn't allow it.  See issue 54
	op extractBytesFromMem-aux : K K List{K} -> K // loc, size in bytes, aux list
	
	// rule
		// < k > extractBytesFromMem(Loc:Nat, Size:Nat) 
			// => extractBytesFromMem-aux(Loc:Nat, Size:Nat, .List{K}) 
		// ...</ k >
		// [structural] 
		
	// rule
		// < k > extractBytesFromMem-aux(Loc:Nat, sNat(Size:Nat), Aux:List{K})
			// => extractByteFromMem(Loc:Nat)
			// ~> extractBytesFromMem-aux(sNat(Loc:Nat), Size:Nat, Aux:List{K})
		// ...</ k >
		// [structural]
	// rule
		// < k > (tv(V:List{K}, T:Type) => .K)
			// ~> extractBytesFromMem-aux(?, ?, (Aux:List{K} => (Aux:List{K},, tv(V:List{K}, T:Type))))
		// ...</ k >
		// [structural]		
	
	op values : List{K} -> List{K} 
	// rule values((tv(K:K, ?),, L:List{KResult})) => (K:K,, values(L:List{KResult})) [structural]
	// rule values(.List{K}) => .List{K} [structural]
	// rule
		// < k > extractBytesFromMem-aux(?, 0, Aux:List{KResult}) 
			// => dataList(values(Aux:List{KResult})) 
		// ...</ k >
		// [structural] 
	
	// // FIXME make sure it's a byte
	
	// rule [read-byte-fast]:
		// < k > extractByteFromMem(sym(Block:Nat) +Nat Offset:Nat)
			// => assert(notBool (sym(Block:Nat) +Nat Offset:Nat) in Locs:Bag, 3)
			// ~> assert(Offset:Nat <Nat Size:Nat, 2)
			// ~> tv(V:K, no-type)
		// ...</ k >
		// < mem >... Block:Nat |-> memblock(Size:Nat, (? Offset:Nat |-> V:K)) ...</ mem >
		// < locsWrittenTo > Locs:Bag </ locsWrittenTo >
		// < buffer > .List </ buffer >
		// [structural]
	// rule [read-byte]:
		// < k > extractByteFromMem(sym(Block:Nat) +Nat Offset:Nat)
			// => assert(notBool (sym(Block:Nat) +Nat Offset:Nat) in Locs:Bag, 3)
			// ~> assert(Offset:Nat <Nat Size:Nat, 2)
			// ~> tv(V:K, no-type)
		// ...</ k >
		// < mem >... Block:Nat |-> memblock(Size:Nat, (? Offset:Nat |-> V:K)) ...</ mem >
		// < locsWrittenTo > Locs:Bag </ locsWrittenTo >
		// < buffer > Mem:List </ buffer >
		// if notBool sym(Block:Nat) +Nat Offset:Nat in locations(Mem:List)
		// [structural]
		
	// rule [read-byte-lazy]:
		// < k > extractByteFromMem(sym(Block:Nat) +Nat Offset:Nat) 
			// => assert(Offset:Nat <Nat Size:Nat, 2)
			// ~> tv(piece(unknown(numBitsPerByte), numBitsPerByte), no-type)
		// ...</ k >
		// < mem >... 
			// Block:Nat |-> memblock(Size:Nat, (M:Map => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset:Nat])) 
		// ...</ mem >
		// < buffer > Mem:List </ buffer >
		// if notBool sym(Block:Nat) +Nat Offset:Nat in locations(Mem:List)
		// andBool notBool $hasMapping(M:Map, Offset:Nat)
		// [structural]
		
	// rule [read-byte-buffer]:
		// < k > extractByteFromMem(Loc:Nat) 
			// => assert(notBool Loc:Nat in Locs:Bag, 3)
			// ~> tv(V:K, no-type)
		// ...</ k >
		// < locsWrittenTo > Locs:Bag </ locsWrittenTo >
		// < buffer >... bwrite(Loc:Nat, V:K) Mem:List </ buffer >
		// if notBool Loc:Nat in locations(Mem:List)
		// [metadata "computational=()"] // for speed in interpretation; forces local buffer to be flushed before a read

endkm

kmod DYNAMIC-SEMANTICS-WRITING is
	including DYNAMIC-MEMORY-INCLUDE 
	context alloc(?, value(`[HOLE`]:K)) 

	rule allocateType(Loc:Nat, T:Type) => alloc(Loc:Nat, value(byteSizeofType(T:Type))) 
		[structural]
	rule [allocateTypeIfAbsent-absent]:
		< k > allocateTypeIfAbsent(Loc:Nat, T:Type) => alloc(Loc:Nat, value(byteSizeofType(T:Type))) ...</ k >
		< mem > Mem:Map </ mem >
		if notBool $hasMapping(Mem:Map, Loc:Nat)
		[structural] 
	rule [allocateTypeIfAbsent-present]:
		< k > allocateTypeIfAbsent(Loc:Nat, T:Type) => .K ...</ k >
		< mem >... Loc:Nat |-> ? ...</ mem >
		[structural]

	rule [alloc-lazy]:
		< k > alloc(sym(Block:Nat) +Nat 0, Len:Nat) => .K ...</ k >
		< mem >... .Map => Block:Nat |-> memblock(Len:Nat, .Map) ...</ mem >
		[structural]		
		
	op writeBytes : Nat K -> K [metadata "strict=(2)"] 
	op writeBitfield : Nat Type K -> K [metadata "strict=(3)"] 
	op isByteLoc : Nat -> Bool 
	op splitBytes : Value -> K 
	op calculateNewBytes : Nat K K -> K [metadata "strict=(3)"] 
	
	op write-aux : K Value K -> K [metadata "strict=(2)"] 
	rule write(K:K, tv(V:List{K}, T:Type)) 
		=> write-aux(K:K, tv(V:List{K}, T:Type), value(bitSizeofType(T:Type))) 
		[structural]
	context write-aux(?, ?, value(`[HOLE`]))
	
	
	
	op write-specific : Nat Value Nat -> K
	
	rule [write-thread-local]:
		< k > write-aux(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
			=> write-specific(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
		...</ k >
		<threadId> Id:Nat </threadId>
		where Loc = sym(threadId(Id:Nat) +Nat N:Nat) +Nat Offset:Nat
		[structural metadata " nd=(true)"]
	rule [write]: // write global or shared data
		< k > write-aux(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
			=> write-specific(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
		...</ k >
		where Loc = sym(threadId(0) +Nat N:Nat) +Nat Offset:Nat
		[metadata "computational=() nd=(true)"]
	rule [write-allocated]: // write data of "allocated" duration
		< k > write-aux(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
			=> write-specific(Loc, tv(L:List{K}, T:Type), bitSize:Nat)
		...</ k >
		where Loc = sym(threadId(allocatedDuration) +Nat N:Nat) +Nat Offset:Nat
		[metadata "computational=() nd=(true)"]
	
	rule [write-normal]:
		< k > write-specific(Loc:Nat, tv(V:K, T:Type), bitSize:Nat)
			// => checkPossiblePointer(tv(V:K, T:Type))
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
		
	rule bitoffset(? +Nat bito(N:Nat)) => N:Nat [structural]
	// fixme owise!!!
	eq bitoffset(?) = 0 [owise] 
	
	// fixme owise!!!
	rule byteoffset(N:Nat +Nat bito(?)) => N:Nat [structural]
	eq byteoffset(N:Nat) = N:Nat [owise] 
		
	op justBits : Int Type -> Value 
	op justBits-aux : Int Type -> Value 
	rule justBits(I:Int, ?) => I:Int
		if I:Int >=Int 0 
		[structural]
		
	rule justBits(I:Int, T:Type) => justBits-aux(I:Int, T:Type)
		if I:Int <Int 0 
		[structural]
	rule justBits-aux(I:Int, T:Type) => justBits-aux((I:Int +Int max(T:Type) +Int 1), T:Type)
		if I:Int <Int 0 
		[structural]
	rule justBits-aux(N:Nat, t(?, bitfieldType(T:Type, sNat(Len:Nat)))) => N:Nat +Nat (1 <<Nat Len:Nat) [structural]
	
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
			=> writeBitfield(
				Loc:Nat
				, T:Type
				, calculateNewBytes(
					bitoffset(Loc:Nat)
					, piece(N:Nat, bitSize:Nat)
					, extractBytesFromMem(floorLoc(Loc:Nat), bitsToBytes(bitSize:Nat +Nat bitoffset(Loc:Nat))
					)
				)
			)
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
	rule calculateNewBytes(Len:Nat, N:Nat, dataList(L:List{K})) => calculateNewBytes-aux(Len:Nat, dataList(explodeToBits(N:Nat)), dataList(explodeToBits(L:List{K})), .List{K})
		[structural]
	
	rule reverseList(.List{K}) => .List{K} [structural]
	rule reverseList((K:K,, L:List{K})) => reverseList(L:List{K}),, K:K [structural]
	
	op joinBitsToBytes : List{K} -> K 
	op joinBitsToBytes-aux : K K -> K 
	
	rule calculateNewBytes-aux(sNat(N:Nat), K:K, dataList((piece(Bit:Nat, 1),, L:List{K})), Result:List{K}) 
		=> calculateNewBytes-aux(N:Nat, K:K, dataList(L:List{K}), (Result:List{K},, piece(Bit:Nat, 1))) 
		[structural]
	
	rule calculateNewBytes-aux(0, dataList((piece(N:Nat, 1),, L:List{K})), dataList((piece(?, 1),, L':List{K})), Result:List{K}) 
		=> calculateNewBytes-aux(0, dataList(L:List{K}), dataList(L':List{K}), (Result:List{K},, piece(N:Nat, 1))) 
		[structural]
	rule calculateNewBytes-aux(0, dataList(.List{K}), dataList(L:List{K}), Result:List{K}) 
		=> joinBitsToBytes((Result:List{K},, L:List{K})) 
		[structural]
	
	rule joinBitsToBytes(L:List{K}) => joinBitsToBytes-aux(dataList(L:List{K}), dataList(.List{K})) [structural]
	rule joinBitsToBytes-aux(dataList((piece(N:Nat, Len:Nat),, piece(M:Nat, 1),, L:List{K})), dataList(R:List{K}))
		=> joinBitsToBytes-aux(dataList((piece(_bit::_(piece(N:Nat, Len:Nat), piece(M:Nat, 1)), sNat(Len:Nat)),, L:List{K})), dataList(R:List{K}))
		if Len:Nat <Nat numBitsPerByte 
		[structural]
	rule joinBitsToBytes-aux(dataList((piece(N:Nat, Len:Nat),, L:List{K})), dataList(R:List{K}))
		=> joinBitsToBytes-aux(dataList(L:List{K}), dataList((R:List{K},, piece(N:Nat, Len:Nat))))
		if Len:Nat ==Bool numBitsPerByte 
		[structural]
	rule joinBitsToBytes-aux(dataList(.List{K}), dataList(R:List{K}))
		=> dataList(R:List{K}) 
		[structural]
	
	
	// rule explodeToBits((K:K,, L:NeList{K})) => (explodeToBits(K:K),, explodeToBits(L:NeList{K})) [structural]
	// rule explodeToBits(piece(N:Nat, sNat(Len:Nat)))
		// => splinter(N:Nat, sNat(Len:Nat)) 
		// [structural]
	// rule explodeToBits(piece(N:Nat, 0)) => .List{K} [structural]
	// rule explodeToBits(.List{K}) => .List{K} [structural]
	
	op splinter : Nat Nat -> List{K} 
	op splinter-aux : Nat Nat Nat -> List{K} 
	// rule splinter(N:Nat, Len:Nat) => splinter-aux(N:Nat, Len:Nat, 0) [structural]
	// rule splinter-aux(?, Len:Nat, Len:Nat) => .List{K} [structural]
	// rule splinter-aux(N:Nat, Len:Nat, Pos:Nat)
		// => splinter-aux(N:Nat, Len:Nat, sNat(Pos:Nat)),, piece(bitRange(N:Nat, Pos:Nat, Pos:Nat), 1)
		// if Pos:Nat <Nat Len:Nat 
		// [structural]
	

	// rule
		// < k > writeBytes(sym(Block:Nat) +Nat Offset:Nat, dataList((V:K,, L:List{K})))
			// => writeByte(sym(Block:Nat) +Nat Offset:Nat, V:K)
			// ~> writeBytes(sym(Block:Nat) +Nat sNat(Offset:Nat), dataList(L:List{K}))
		// ...</ k >
		// [structural]
	// rule [write-byte-buffer]:
		// < k > writeByte(LOC, V:K) => .K ...</ k >
		// < buffer >... (.List => bwrite(LOC, V:K)) </ buffer >
		// < mem >... Block:Nat |-> memblock(Len:Nat, ?) ...</ mem >		
		// < locsWrittenTo > Locs:Bag (.Bag => BagItem(LOC)) </ locsWrittenTo >
		// if notBool LOC in Locs:Bag
		// andBool Offset:Nat <Nat Len:Nat
		// where LOC = sym(Block:Nat) +Nat Offset:Nat
		// [structural] 
		// // [metadata "computational=()"]
		
	// rule [commit-byte]:
		// < blocked > false </ blocked >
		// < buffer > (bwrite(sym(Block:Nat) +Nat Offset:Nat, V:K) => .List) ...</ buffer >
		// < mem >... Block:Nat |-> memblock(Len:Nat, (M:Map => M:Map[V:K / Offset:Nat])) ...</ mem >
		// if Offset:Nat <Nat Len:Nat
		// [structural]
		// // [metadata "computational=()"]
	// rule
		// < k > writeBytes(?, dataList(.List{K})) => .K ...</ k >
		// [structural] 
		
	// // this general rule is useful for unknowns, abstracts, etc
	// rule [splitBytes-char]:
		// splitBytes(tv(N:Nat, T:Type))
			// => dataList(piece(N:Nat, numBitsPerByte))
		// if hasCharType(T:Type)
		// [structural] 
	// rule [splitBytes-int]:
		// splitBytes(tv(I:Int, T:Type)) 
			// => splitIntegerBytes(I:Int, T:Type, value(byteSizeofType(T:Type)))
		// if hasIntegerType(T:Type)
		// andBool (I:Int >=Int 0 orBool I:Int <=Int 0)
		// [structural] 
	// rule [splitBytes-float]:
		// splitBytes(tv(F:Float, T:Type)) 
			// => splitFloatBytes(F:Float, T:Type, value(byteSizeofType(T:Type)))
		// if hasFloatType(T:Type)
		// [structural] 
	// rule [splitBytes-pointer]:
		// splitBytes(tv(I:Int, pointerType(T:Type))) 
			// => splitPointerBytes(I:Int, pointerType(T:Type), value(byteSizeofType(pointerType(T:Type))))
		// [structural] 
	// // rule [splitBytes-array]:
		// // splitBytes(tv(I:Int, arrayType(T:Type, ?))) 
			// // => splitPointerBytes(I:Int, pointerType(T:Type), value(byteSizeofType(pointerType(T:Type))))
		// // [structural] 
	// rule [splitBytes-struct]:
		// splitBytes(tv(L:List{K}, T:Type)) 
			// => splitStructBytes(dataList(L:List{K}), T:Type, value(byteSizeofType(T:Type)))
		// if hasStructType(T:Type)
		// [structural] 
	
	op splitIntegerBytes : K K K -> K 
	op splitIntegerBytes : K K K List{K} -> K 
	context splitIntegerBytes(?, ?, value(`[HOLE`]:K)) 
	// rule splitIntegerBytes(I:Int, T:Type, Len:Nat) => splitIntegerBytes(I:Int, T:Type, Len:Nat, .List{K}) [structural]
	// rule splitIntegerBytes(I:Int, T:Type, sNat(Len:Nat), L:List{K})
		// => splitIntegerBytes(I:Int >>Int numBitsPerByte, T:Type, Len:Nat, (L:List{K},, lowestByte(I:Int, T:Type))) 
		// [structural]
	// rule splitIntegerBytes(?, ?, 0, L:List{K})
		// => dataList(L:List{K}) 
		// [structural]
		
	op splitStructBytes : K K K -> K 
	op splitStructBytes : K K K List{K} -> K 
	context splitStructBytes(?, ?, value(`[HOLE`]:K)) 
	// rule splitStructBytes(dataList(L:List{K}), T:Type, Len:Nat) => splitStructBytes(dataList(L:List{K}), T:Type, Len:Nat, .List{K}) 
		// [structural]
	// rule splitStructBytes(dataList((piece(N:Nat, PieceLen:Nat),, Rest:List{K})), T:Type, sNat(Len:Nat), L:List{K})
		// => splitStructBytes(dataList(Rest:List{K}), T:Type, Len:Nat, (L:List{K},, piece(N:Nat, PieceLen:Nat))) 
		// if PieceLen:Nat ==Bool numBitsPerByte 
		// [structural]
	// rule splitStructBytes(?, ?, 0, L:List{K})
		// => dataList(L:List{K}) 
		// [structural]
		
		
	op splitPointerBytes : K K K -> K 
	op splitPointerBytes : K K K List{K} -> K 
	context splitPointerBytes(?, ?, value(`[HOLE`]:K)) 
	// rule splitPointerBytes(I:Int, T:Type, sNat(Len:Nat)) 
		// => splitPointerBytes(I:Int, T:Type, Len:Nat, piece(encodedPointer(I:Int), numBitsPerByte)) 
		// [structural]
	// rule splitPointerBytes(I:Int, T:Type, sNat(Len:Nat), L:List{K}) => splitPointerBytes(I:Int, T:Type, Len:Nat, (L:List{K},, piece(unknown(numBitsPerByte), numBitsPerByte))) 
		// [structural]
	// rule splitPointerBytes(?, ?, 0, L:List{K}) 
		// => dataList(L:List{K}) 
		// [structural]
		
		
	op splitFloatBytes : K K K -> K 
	op splitFloatBytes : K K K List{K} -> K 
	context splitFloatBytes(?, ?, value(`[HOLE`]:K)) 
	// rule splitFloatBytes(F:Float, T:Type, sNat(Len:Nat)) 
		// => splitFloatBytes(F:Float, T:Type, Len:Nat, piece(encodedFloat(F:Float), numBitsPerByte)) 
		// [structural]
	// rule splitFloatBytes(F:Float, T:Type, sNat(Len:Nat), L:List{K}) => splitFloatBytes(F:Float, T:Type, Len:Nat, (L:List{K},, piece(unknown(numBitsPerByte), numBitsPerByte))) 
		// [structural]
	// rule splitFloatBytes(?, T:Type, 0, L:List{K}) 
		// => dataList(L:List{K}) 
		// [structural]
		
	
	op lowestByte : Int Type -> K 
	// rule lowestByte(I:Int, T:Type) => piece(I:Int &Int byteMaskSet, numBitsPerByte)
		// if hasIntegerType(T:Type) 
		// [structural]
	
	op byteMaskSet : -> Nat
	// rule byteMaskSet => (2 ^Nat numBitsPerByte) -Int 1 [structural]
		
	// rule isByteLoc(? +Nat bito(?)) => false [structural]
	// // fixme owise!!!
	// eq isByteLoc(?) = true [owise] 
endkm

kmod DYNAMIC-C-MEMORY-MISC is
	including DYNAMIC-MEMORY-INCLUDE 

	// // used by calloc
	// rule
		// < k > zeroBlock(sym(Block:Nat) +Nat 0) => .K ...</ k >
		// < mem >... Block:Nat |-> memblock(Len:Nat, (? => .Map[piece(0, numBitsPerByte) / 0 to Len:Nat])) ...</ mem >
		// [structural]
		
	// rule
		// < k > sizeofLocation(sym(Block:Nat) +Nat ?) => tv(Len:Nat, cfg:sizeut) ...</ k >
		// < mem >... Block:Nat |-> memblock(Len:Nat, ?) ...</ mem >
		// [structural]
		
	// rule [delete-sized-block]:
		// < k > deleteSizedBlock(sym(Block:Nat) +Nat ?, Len:Nat) => .K ...</ k >
		// < mem >... Block:Nat |-> memblock(Len:Nat, ?) => .Map ...</ mem >
		// < buffer > .List </ buffer > // fixme could make this more relaxed by checking of block is in buffer, not just empty
		// [structural] 
	
	// rule [delete-block]:
		// < k > deleteBlock(sym(Block:Nat) +Nat ?) => .K ...</ k >
		// < mem >... Block:Nat |-> ? => .Map ...</ mem >
		// < buffer > .List </ buffer >
		// [structural] 
	
	// c99 6.5:2 If a side effect on a scalar object is unsequenced relative to either a different side effect on the same scalar object or a value computation using the value of the same scalar object, the behavior is undefined. If there are multiple allowable orderings of the subexpressions of an expression, the behavior is undefined if such an unsequenced side effect occurs in any of the orderings
	// i take this to mean that if i write to a location twice or read from a location after being written to, then it is a problem
		
	op writeString : Nat String -> K
	op writeWString : Nat List{K} -> K
	// rule [alloc-string]:
		// < k > allocString(Loc:Nat, S:String)
			// => allocateType(Loc:Nat, arrayType(char, lengthString(S:String)))
			// ~> writeString(Loc:Nat, S:String)
		// ...</ k >
		// [structural]
	// rule [alloc-wstring]:
		// < k > allocWString(Loc:Nat, S:List{K})
			// => allocateType(Loc:Nat, arrayType(cfg:wcharut, 4 *Nat lengthList{K}(S:List{K})))
			// ~> writeWString(Loc:Nat, S:List{K})
		// ...</ k >
		// [structural] 
		
	// rule [write-string]:
		// < k > writeString(Loc:Nat, S:String)
			// => Computation(*(tv(Loc:Nat, pointerType(char))) := tv(charToAscii(firstChar(S:String)), char))
			// ~> writeString(sNat(Loc:Nat), butFirstChar(S:String))
		// ...</ k >
		// if S:String =/=Bool ""
		// [structural]
	// // fixme this bare 4 needs to be updated to handle different size wchar_ts
	// rule [write-wstring]:
		// < k > writeWString(Loc:Nat, (N:Nat,, S:List{K}))
			// => Computation(*(tv(Loc:Nat, pointerType(cfg:wcharut))) := tv(N:Nat, cfg:wcharut))
			// ~> writeWString(Loc:Nat +Nat 4, S:List{K})
		// ...</ k >
		// [structural] 
		
	// rule [write-empty-string]:
		// < k > writeString(Loc:Nat, "") 
			// => .K
		// ...</ k >
		// [structural]
	// rule [write-empty-wstring]:
		// < k > writeWString(Loc:Nat, .List{K}) 
			// => .K
		// ...</ k >
		// [structural]
	
	op checkValidLoc-aux : K -> K
	
	// rule
		// < k > checkValidLoc(Loc:Nat) => checkValidLoc-aux(ceilingLoc(Loc:Nat)) ...</ k >
		// [structural]
	// rule
		// < k > checkDerefLoc(Loc:Nat) => checkValidLoc(Loc:Nat) ...</ k >
		// if Loc:Nat =/=Bool NullPointer
		// [structural]
	
	// rule [check-valid-loc-null]:
		// < k > checkValidLoc-aux(NullPointer) => .K ...</ k >
		// [structural]
	// // fixme could additionally use the type to check whether that type is valid for that pointer
	// rule [check-valid-loc]:
		// < k > checkValidLoc-aux(sym(BASE) +Nat Offset:Nat) => .K ...</ k >
		// < mem >... BASE |-> memblock(Len:Nat, ?) ...</ mem >
		// <threadId> MyThreadId:Nat </threadId>
		// if (PtrThreadId:Nat ==Bool MyThreadId:Nat 
			// orBool PtrThreadId:Nat ==Bool 0
			// orBool PtrThreadId:Nat ==Bool allocatedDuration
			// // orBool PtrThreadId:Nat ==Bool readOnly
			// ) // my thread, global memory, or allocated (malloced) memory
		// andBool Offset:Nat <=Nat Len:Nat // we're allowed to address one past
		// where BASE = threadId(PtrThreadId:Nat) +Nat N:Nat
		// [structural]
endkm

kmod DYNAMIC-C-MEMORY is
	including DYNAMIC-MEMORY-INCLUDE 
	including DYNAMIC-C-MEMORY-MISC 
	including DYNAMIC-SEMANTICS-WRITING 
	including DYNAMIC-SEMANTICS-READING 
endkm
