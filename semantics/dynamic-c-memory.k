kmod DYNAMIC-MEMORY-INCLUDE is
	including DYNAMIC-INCLUDE 
	
	// returns the bytes in the order in which they are in memory
	op extractBytesFromMem : #Nat #Nat -> K // loc, size in bytes
	op encodedPointer : #Int -> #Nat
	op encodedFloat : #Float -> #Nat
	declare explodeToBits : List{K} -> List{K}
	declare reverseList : List{K} -> List{K}
	op bwrite : #Nat K -> ListItem
	declare locations : List -> Set
	op read-aux : K K K -> K
	
	declare subObject : K K K -> #Nat // object, start piece, end piece
	
	define [locations-none]: locations(.List) => .Set [structural]
	define [locations-some]: locations(bwrite(Loc:#Nat, _) L:List) => SetItem(Loc:#Nat) locations(L:List) [structural]
endkm

kmod DYNAMIC-SEMANTICS-READING is
	including DYNAMIC-MEMORY-INCLUDE 
	
	op extractBitsFromMem : #Nat #Nat -> K // loc, size in bits
	op extractByteFromMem : #Nat -> K 
	declare getBitOffset : #Nat -> #Nat 
	define getBitOffset(_:#Nat +Nat bito(M:#Nat)) => M:#Nat [structural]
	// fixme owise!!!!
	eq getBitOffset(_:#Nat) = 0 [owise]
	
	op extractBitsFromList-aux : K #Nat #Nat List{K} -> K // datalist, offset in bits into list, number of bits to extract, accumulator
	rule extractBitsFromList(dataList(L:List{K}), N:#Nat, M:#Nat) 
		=> extractBitsFromList-aux(dataList(explodeToBits(L:List{K})), N:#Nat, M:#Nat, .List{K})
		// if M:#Nat =/=Bool 10
		[structural]
	rule
		< k > extractBitsFromList-aux(dataList((piece(_:#Nat, 1),, L:List{K})), sNat(Offset:#Nat), NumBits:#Nat, .List{K})
			=> extractBitsFromList-aux(dataList(L:List{K}), Offset:#Nat, NumBits:#Nat, .List{K})
		...</ k >
		[structural] 
	rule
		< k > extractBitsFromList-aux(dataList((piece(N:#Nat, 1),, L:List{K})), 0, sNat(NumBits:#Nat), Done:List{K})
			=> extractBitsFromList-aux(dataList(L:List{K}), 0, NumBits:#Nat, (Done:List{K},, piece(N:#Nat, 1)))
		...</ k >
		[structural] 
	
	rule
		< k > extractBitsFromList-aux(_, 0, 0, Done:List{K}) => dataList(Done:List{K}) ...</ k >
		[structural] 
	
	
	context readActual(_, _, value(HOLE))
	rule read(Loc:#Nat, T:KResult) => read-aux(Loc:#Nat, T:KResult, value(bitSizeofType(T:KResult))) 
		when notBool(hasFunctionType(T:KResult))
		[structural]
	
	
	
	op readActual : K K K -> K
	
	/*@ These rules figure out whether the read should be structural or computational, depending on what is being read
	*/
	rule [read-thread-local]:
		< k > ('read-aux => 'readActual)(sym(threadId(Id:#Nat) +Nat _:#Nat) +Nat _:#Nat,, _,, _) ...</ k >
		<threadId> Id:#Nat </threadId>
		[structural ndlocal]
	rule [read-shared]: // read global or shared data
		< k > ('read-aux => 'readActual)(sym(threadId(0) +Nat _:#Nat) +Nat _:#Nat,, _,, _) ...</ k >
		[computational ndlocal]
	rule [read-allocated]: // read data of "allocated" duration
		< k > ('read-aux => 'readActual)(sym(threadId(allocatedDuration) +Nat _:#Nat) +Nat _:#Nat,, _,, _) ...</ k >
		[computational ndlocal]
	
	rule [read]:
		< k > readActual(Loc:#Nat, T:KResult, bitSize:#Nat)
			=> concretize(T:KResult, extractBytesFromMem(Loc:#Nat, bitsToBytes(bitSize:#Nat)))
		...</ k >
		when notBool hasBitfieldType(T:KResult)
		[structural]
	rule [read-bitfield]:
		< k > readActual(Loc:#Nat, T:KResult, bitSize:#Nat)
			=> concretize(T:KResult, fillToBytes(extractBitsFromMem(Loc:#Nat, bitSize:#Nat))) 
		...</ k >
		when hasBitfieldType(T:KResult)
		[structural]
	
		
	op joinIntegerBytes : Type List{K} -> K 
	rule 
		< k > concretize(T:KResult, dataList(L:List{K})) 
			=> joinIntegerBytes(T:KResult, L:List{K}) 
		...</ k >
		when hasIntegerType(T:KResult) 
		andBool notBool hasBitfieldType(T:KResult) 
		[structural]
	rule 
		< k > concretize(t(S:Set, bitfieldType(T:KResult, Len:#Nat)), dataList(L:List{K})) 
			=> joinIntegerBytes(t(S:Set, bitfieldType(T:KResult, Len:#Nat)), reverseList(L:List{K})) 
		...</ k >
		//if // hasIntegerType(T:KResult) // redundant
		//hasBitfieldType(T:KResult) 
		[structural]
		
	// FIXME very unsafe, not checking size of list or its contents
	rule < k > concretize(T:KResult, dataList((piece(encodedFloat(F:#Float), Len:#Nat),, _))) 
			=> tv(F:#Float, T:KResult)
		...</ k >
		when hasFloatType(T:KResult)
		andBool Len:#Nat ==Bool numBitsPerByte 
		[structural]

	op joinPointerBytes : Type List{K} -> K
	op joinPointerBytes-aux : Type List{K} K -> K
	// fixme should also check sizes are appropriate
	// fixme very unsafe as is.  doesn't care if other bytes were overwritten
	// rule < k > concretize(t(S:Set, pointerType(T:KResult)), dataList((piece(encodedPointer(N:#Nat), Len:#Nat),, _))) 
			// => checkValidLoc(N:#Nat)
			// ~> tv(N:#Nat, t(S:Set, pointerType(T:KResult)))
		// ...</ k >
		// when Len:#Nat ==Bool numBitsPerByte
		// [structural]
	rule < k > concretize(T:KResult, dataList(L:List{K}))
			=> joinPointerBytes(T:KResult, L:List{K})
		...</ k >
		when hasPointerType(T:KResult)
		[structural]
	rule < k > joinPointerBytes(T:KResult, (piece(N:#Nat, Len:#Nat),, L:List{K}))
			=> joinPointerBytes-aux(T:KResult, L:List{K}, N:#Nat)
		...</ k >
		when Len:#Nat ==Bool numBitsPerByte
		[structural]
	rule < k > joinPointerBytes-aux(T:KResult, (piece(subObject(N:#Nat, sNat(End:#Nat), sNat(End:#Nat)), Len:#Nat),, L:List{K}), subObject(N:#Nat, 0, End:#Nat))
			=> joinPointerBytes-aux(T:KResult, L:List{K}, subObject(N:#Nat, 0, sNat(End:#Nat)))
		...</ k >
		when Len:#Nat ==Bool numBitsPerByte
		[structural]
	rule < k > joinPointerBytes-aux(T:KResult, .List{K}, subObject(N:#Nat, 0, End:#Nat))
			=> checkValidLoc(N:#Nat)
			~> tv(N:#Nat, T:KResult)
		...</ k >
		[structural]

	rule < k > concretize(t(S:Set, structType(S:#Id)), dataList(L:List{K})) 
			=> tv(L:List{K}, t(S:Set, structType(S:#Id))) 
		...</ k >
		// if hasStructType(T:KResult)
		[structural]
	rule < k > concretize(t(S:Set, unionType(S:#Id)), dataList(L:List{K})) 
			=> tv(L:List{K}, t(S:Set, unionType(S:#Id)))
		...</ k >
		// if hasUnionType(T:KResult)
		[structural]

	// FIXME assuming bytes?
	op joinIntegerBytes-aux : Type List{K} K -> K 
	rule [joinIntegerBytes-start]:
		joinIntegerBytes(T:KResult, L:List{K}) 
			=> joinIntegerBytes-aux(T:KResult, L:List{K}, piece(0, 0)) 
		[structural]
	
	// fixme may want to consider restricting further, or loosening
	rule [joinIntegerBytes-unknown-char]:
		joinIntegerBytes-aux(T:KResult, piece(unknown(Len:#Nat), Len:#Nat), piece(0, 0))
			=> tv(piece(unknown(Len:#Nat), Len:#Nat), T:KResult)
		when hasCharType(T:KResult)
		[structural]
	
	rule [joinIntegerBytes-step]:
		joinIntegerBytes-aux(T:KResult, (L:List{K},, piece(N:#Nat, Len:#Nat)), piece(N':#Nat, Len':#Nat))
			=> joinIntegerBytes-aux(T:KResult, L:List{K}, piece(_bit::_(piece(N':#Nat, Len':#Nat), piece(N:#Nat, Len:#Nat)), Len:#Nat +Nat Len':#Nat))
		when N':#Nat >=Nat 0 // guard is here to make sure it's an actual piece
		[structural]
	rule [joinIntegerBytes-done]:
		joinIntegerBytes-aux(T:KResult, .List{K}, piece(N:#Nat, Len:#Nat)) 
			=> interpret(T:KResult, piece(N:#Nat, Len:#Nat)) 
		when N:#Nat >=Nat 0 // guard is here to make sure it's an actual piece
		[structural]
	
	rule floorLoc(sym(N:#Nat) +Nat bito(M:#Nat) +Nat R:#Nat) => sym(N:#Nat) +Nat R:#Nat [structural]
	// fixme owise!!!
	eq floorLoc(sym(N:#Nat) +Nat R:#Nat) = sym(N:#Nat) +Nat R:#Nat [owise] 
	
	rule [ceilingLoc-null]: ceilingLoc(NullPointer) => NullPointer [structural]
	rule [ceilingLoc-bito]: ceilingLoc(sym(N:#Nat) +Nat bito(M:#Nat) +Nat R:#Nat)
		=> sym(N:#Nat) +Nat absInt(floorRat(M:#Nat /Rat numBitsPerByte)) +Nat R:#Nat
		[structural]
	// fixme owise!!!
	eq [ceilingLocNormal]: ceilingLoc(sym(N:#Nat) +Nat R:#Nat) = sym(N:#Nat) +Nat R:#Nat [owise] 
	
	rule
		< k > extractBitsFromMem(Loc:#Nat, Size:#Nat)
			=> extractBitsFromList(
				extractBytesFromMem(floorLoc(Loc:#Nat), bitsToBytes(Size:#Nat +Nat getBitOffset(Loc:#Nat)))
				, getBitOffset(Loc:#Nat)
				, Size:#Nat
			)
		...</ k >
		[structural] 
	
	// context extractBytesFromMem-aux(_, _, (_,, HOLE,, _)) 
	// this next op should use Nats, but the context doesn't allow it.  See issue 54
	op extractBytesFromMem-aux : K K List{K} -> K // loc, size in bytes, aux list
	
	rule
		< k > extractBytesFromMem(Loc:#Nat, Size:#Nat) 
			=> extractBytesFromMem-aux(Loc:#Nat, Size:#Nat, .List{K}) 
		...</ k >
		[structural] 
		
	rule
		< k > extractBytesFromMem-aux(Loc:#Nat, sNat(Size:#Nat), Aux:List{K})
			=> extractByteFromMem(Loc:#Nat)
			~> extractBytesFromMem-aux(sNat(Loc:#Nat), Size:#Nat, Aux:List{K})
		...</ k >
		[structural]
	rule
		< k > (tv(V:List{K}, T:KResult) => .K)
			~> extractBytesFromMem-aux(_, _, (Aux:List{K} => (Aux:List{K},, tv(V:List{K}, T:KResult))))
		...</ k >
		[structural]		
	
	declare values : List{K} -> List{K} 
	define values((tv(K:K, _),, L:List{KResult})) => (K:K,, values(L:List{KResult})) [structural]
	define values(.List{K}) => .List{K} [structural]
	rule
		< k > extractBytesFromMem-aux(_, 0, Aux:List{KResult}) 
			=> dataList(values(Aux:List{KResult})) 
		...</ k >
		[structural] 
	
	// FIXME make sure it's a byte
	
	rule [read-byte-fast]:
		< k > extractByteFromMem(sym(Block:#Nat) +Nat Offset:#Nat)
			=> assert(notBool (sym(Block:#Nat) +Nat Offset:#Nat) in Locs:Bag, 3)
			~> assert(Offset:#Nat <Nat Size:#Nat, 2)
			~> tv(V:K, t(.Set, no-type))
		...</ k >
		< mem >... Block:#Nat |-> memblock(mlength(Size:#Nat) _, (_ Offset:#Nat |-> V:K)) ...</ mem >
		< locsWrittenTo > Locs:Bag </ locsWrittenTo >
		< buffer > .List </ buffer >
		[structural]
	rule [read-byte]:
		< k > extractByteFromMem(sym(Block:#Nat) +Nat Offset:#Nat)
			=> assert(notBool (sym(Block:#Nat) +Nat Offset:#Nat) in Locs:Bag, 3)
			~> assert(Offset:#Nat <Nat Size:#Nat, 2)
			~> tv(V:K, t(.Set, no-type))
		...</ k >
		< mem >... Block:#Nat |-> memblock(mlength(Size:#Nat) _, (_ Offset:#Nat |-> V:K)) ...</ mem >
		< locsWrittenTo > Locs:Bag </ locsWrittenTo >
		< buffer > Mem:List </ buffer >
		when notBool sym(Block:#Nat) +Nat Offset:#Nat in locations(Mem:List)
		[structural]
		
	rule [read-byte-lazy]:
		< k > extractByteFromMem(sym(Block:#Nat) +Nat Offset:#Nat) 
			=> assert(Offset:#Nat <Nat Size:#Nat, 2)
			~> tv(piece(unknown(numBitsPerByte), numBitsPerByte), t(.Set, no-type))
		...</ k >
		< mem >... 
			Block:#Nat |-> memblock(mlength(Size:#Nat) _, (M:Map => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset:#Nat])) 
		...</ mem >
		< buffer > Mem:List </ buffer >
		when notBool sym(Block:#Nat) +Nat Offset:#Nat in locations(Mem:List)
		andBool notBool $hasMapping(M:Map, Offset:#Nat)
		[structural]
		
	rule [read-byte-buffer]:
		< k > extractByteFromMem(Loc:#Nat) 
			=> assert(notBool Loc:#Nat in Locs:Bag, 3)
			~> tv(V:K, t(.Set, no-type))
		...</ k >
		< locsWrittenTo > Locs:Bag </ locsWrittenTo >
		< buffer >... bwrite(Loc:#Nat, V:K) Mem:List </ buffer >
		when notBool Loc:#Nat in locations(Mem:List)
		[structural]
		//[interpRule] // for speed in interpretation; forces local buffer to be flushed before a read

endkm

kmod DYNAMIC-SEMANTICS-WRITING is
	including DYNAMIC-MEMORY-INCLUDE 
	context alloc(_, value(HOLE)) 

	rule allocateType(Loc:#Nat, T:KResult) => alloc(Loc:#Nat, value(byteSizeofType(T:KResult))) 
		[structural]
	rule [allocateTypeIfAbsent-absent]:
		< k > allocateTypeIfAbsent(Loc:#Nat, T:KResult) 
			=> alloc(Loc:#Nat, value(byteSizeofType(T:KResult))) 
		...</ k >
		< mem > Mem:Map </ mem >
		when notBool $hasMapping(Mem:Map, Loc:#Nat)
		[structural] 
	rule [allocateTypeIfAbsent-present]:
		< k > allocateTypeIfAbsent(Loc:#Nat, T:KResult) => .K ...</ k >
		< mem >... Loc:#Nat |-> _ ...</ mem >
		[structural]

	rule [alloc-lazy]:
		< k > alloc(sym(Block:#Nat) +Nat 0, Len:#Nat) => .K ...</ k >
		< mem >... .Map => Block:#Nat |-> memblock(mlength(Len:#Nat), .Map) ...</ mem >
		[structural]
	
	op realloc-aux : K K K K K -> K
	rule [realloc-start]:
		< k > realloc(Old:K, New:K, OldLen:#Nat, NewLen:#Nat)
			=> alloc(New:K, NewLen:#Nat)
			~> realloc-aux(minNat(OldLen:#Nat, NewLen:#Nat), Old:K, New:K, OldLen:#Nat, NewLen:#Nat)
		...</ k >
		[structural]
		
	rule [realloc-found]:
		< k > realloc-aux((sNat(N:#Nat) => N:#Nat), sym(OldBlock:#Nat) +Nat 0, sym(NewBlock:#Nat) +Nat 0, _, _)
		...</ k >
		< mem >... 
			OldBlock:#Nat |-> memblock(_, (_ N:#Nat |-> K:K))
			NewBlock:#Nat |-> memblock(_, (_ (.Map => N:#Nat |-> K:K)))
		...</ mem >
		[structural]
	rule [realloc-unfound]:
		< k > realloc-aux((sNat(N:#Nat) => N:#Nat), sym(OldBlock:#Nat) +Nat 0, sym(NewBlock:#Nat) +Nat 0, _, _)
		...</ k >
		< mem >... 
			OldBlock:#Nat |-> memblock(_, M:Map)
		...</ mem >
		when notBool $hasMapping(M:Map, N:#Nat)
		[structural]
	rule [realloc-0]:
		< k > realloc-aux(0, sym(OldBlock:#Nat) +Nat 0, _, OldLen:#Nat, _)
			=> deleteSizedBlock(sym(OldBlock:#Nat) +Nat 0, OldLen:#Nat) 
		...</ k >
		[structural]	
		
	op writeBytes : #Nat K -> K [metadata "strict=(2)"] 
	op writeBitfield : #Nat Type K -> K [metadata "strict=(3)"] 
	declare isByteLoc : #Nat -> #Bool 
	declare splitBytes : Value -> K 
	declare calculateNewBytes : #Nat K K -> K [metadata "strict=(3)"] 
	
	op write-aux : K Value K -> K [metadata "strict=(2)"]
	rule write(lv(Dest:#Nat, T':KResult), tv(V:List{K}, T:KResult)) 
		=> write-aux(Dest:#Nat, tv(V:List{K}, T:KResult), value(bitSizeofType(T:KResult))) 
		when notBool hasConstType(T':KResult)
		[structural]
	context write-aux(_, _, value(HOLE))
	
	
	
	op write-specific : #Nat Value #Nat -> K
	
	rule [write-thread-local]:
		< k > write-aux(Loc, tv(L:List{K}, T:KResult), bitSize:#Nat)
			=> write-specific(Loc, tv(L:List{K}, T:KResult), bitSize:#Nat)
		...</ k >
		<threadId> Id:#Nat </threadId>
		where Loc = sym(threadId(Id:#Nat) +Nat N:#Nat) +Nat Offset:#Nat
		[structural ndlocal]
	rule [write]: // write global or shared data
		< k > write-aux(Loc, tv(L:List{K}, T:KResult), bitSize:#Nat)
			=> write-specific(Loc, tv(L:List{K}, T:KResult), bitSize:#Nat)
		...</ k >
		where Loc = sym(threadId(0) +Nat N:#Nat) +Nat Offset:#Nat
		[computational ndlocal]
	rule [write-allocated]: // write data of "allocated" duration
		< k > write-aux(Loc, tv(L:List{K}, T:KResult), bitSize:#Nat)
			=> write-specific(Loc, tv(L:List{K}, T:KResult), bitSize:#Nat)
		...</ k >
		where Loc = sym(threadId(allocatedDuration) +Nat N:#Nat) +Nat Offset:#Nat
		[computational ndlocal]
	
	rule [write-normal]:
		< k > write-specific(Loc:#Nat, tv(V:K, T:KResult), bitSize:#Nat)
			=> writeBytes(Loc:#Nat, splitBytes(tv(V:K, T:KResult)))
		...</ k >
		when bitSize:#Nat %Nat numBitsPerByte ==Bool 0
		andBool isByteLoc(Loc:#Nat)
		andBool notBool hasBitfieldType(T:KResult)
		andBool notBool hasUnionMarker(T:KResult)
		[structural]
	rule [write-normal-union-field]:
		< k > (.K => makeUnknown(Loc:#Nat, t(.Set, unionType(S:#Id))))
			~> write-specific(Loc:#Nat, tv(_, t((SetItem(fromUnion(S:#Id)) => .Set) _, _)), _:#Nat)
		...</ k >
		when isByteLoc(Loc:#Nat)
		[structural]
		
	op makeUnknown : #Nat Type -> K
	op makeUnknown-aux : #Nat Type K -> K // should be #Nat Type K
	context makeUnknown-aux(_:#Nat, _, value(HOLE))
	
	rule makeUnknown(N:#Nat, T:KResult)
		=> makeUnknown-aux(N:#Nat, T:KResult, value(byteSizeofType(T:KResult))) 
		[structural]
	rule
		< k > makeUnknown-aux(sym(Block:#Nat) +Nat Offset:#Nat, _, Len':#Nat) => .K ...</ k >
		< mem >... Block:#Nat |-> memblock(mlength(Len:#Nat) _, (M:Map => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset:#Nat to (Offset:#Nat +Nat Len':#Nat)])) ...</ mem >
		when Len:#Nat >=Nat Offset:#Nat +Nat Len':#Nat
		[structural]
		
	declare hasUnionMarker : Type -> #Bool
	define hasUnionMarker(t(SetItem(fromUnion(_:#Id)) _, _)) => true [structural]
	define hasUnionMarker(t(.Set, _)) => false [structural]
	// rule hasUnionMarker(t(_ (SetItem(L:KLabel(_:List{K})) => .Set), _))
		// when L:KLabel =/=Bool 'fromUnion
		// [structural]
	define hasUnionMarker(t(S:Set (SetItem(L:KLabel(_:List{K}))), K:K))
		=> hasUnionMarker(t(S:Set, K:K))
		when L:KLabel =/=Bool 'fromUnion
		[structural]
	
	
	rule [write-struct]:
		< k > write-specific(Loc:#Nat, tv((V:K,, V':K,, L:List{K}), T:KResult), bitSize:#Nat)
			=> writeBytes(Loc:#Nat, dataList((V:K,, V':K,, L:List{K})))
		...</ k >
		when bitSize:#Nat %Nat numBitsPerByte ==Bool 0
		andBool isByteLoc(Loc:#Nat)
		andBool notBool hasBitfieldType(T:KResult)
		[structural]
		
	define bitoffset(_:#Nat +Nat bito(N:#Nat)) => N:#Nat [structural]
	// fixme owise!!!
	eq bitoffset(_:#Nat) = 0 [owise] 
	
	// fixme owise!!!
	define byteoffset(N:#Nat +Nat bito(_:#Nat)) => N:#Nat [structural]
	eq byteoffset(N:#Nat) = N:#Nat [owise] 
		
	declare justBits : #Int Type -> Value 
	declare justBits-aux : #Int Type -> Value 
	define justBits(I:#Int, _) => I:#Int
		when I:#Int >=Int 0 
		[structural]
		
	define justBits(I:#Int, T:KResult) => justBits-aux(I:#Int, T:KResult)
		when I:#Int <Int 0 
		[structural]
	define justBits-aux(I:#Int, T:KResult) => justBits-aux((I:#Int +Int max(T:KResult) +Int 1), T:KResult)
		when I:#Int <Int 0 
		[structural]
	define justBits-aux(N:#Nat, t(_, bitfieldType(T:KResult, sNat(Len:#Nat)))) => N:#Nat +Nat (1 <<Nat Len:#Nat) [structural]
	
	rule [massage-bitfield]:
		< k > write-specific(Loc:#Nat, tv(I:#Int, T:KResult), bitSize:#Nat)
			=> write-specific(Loc:#Nat, tv(justBits(I:#Int, T:KResult), T:KResult), bitSize:#Nat)
		...</ k >
		when (bitSize:#Nat %Nat numBitsPerByte =/=Bool 0
		orBool notBool(isByteLoc(Loc:#Nat))
		orBool hasBitfieldType(T:KResult))
		andBool I:#Int <Int 0
		[structural]
	
	rule [write-bitfield]:
		< k > write-specific(Loc:#Nat, tv(N:#Nat, T:KResult), bitSize:#Nat)
			=> writeBitfield(
				Loc:#Nat
				, T:KResult
				, calculateNewBytes(
					bitoffset(Loc:#Nat)
					, piece(N:#Nat, bitSize:#Nat)
					, extractBytesFromMem(floorLoc(Loc:#Nat), bitsToBytes(bitSize:#Nat +Nat bitoffset(Loc:#Nat))
					)
				)
			)
		...</ k >
		when bitSize:#Nat %Nat numBitsPerByte =/=Bool 0
		orBool notBool(isByteLoc(Loc:#Nat))
		orBool hasBitfieldType(T:KResult)
		andBool notBool hasUnionMarker(T:KResult)
		[structural]
		
	rule
		< k > writeBitfield(Loc:#Nat, _, dataList(L:List{K}))
			=> writeBytes(byteoffset(Loc:#Nat), dataList(L:List{K}))
		...</ k >
		[structural] 
		
	declare calculateNewBytes-aux : #Nat K K List{K} -> K 
	define calculateNewBytes(Len:#Nat, N:#Nat, dataList(L:List{K})) 
		=> calculateNewBytes-aux(Len:#Nat, dataList(explodeToBits(N:#Nat)), dataList(explodeToBits(L:List{K})), .List{K})
		[structural]
	
	define reverseList(.List{K}) => .List{K} [structural]
	define reverseList((K:K,, L:List{K})) => reverseList(L:List{K}),, K:K [structural]
	
	declare joinBitsToBytes : List{K} -> K 
	declare joinBitsToBytes-aux : K K -> K 
	
	define calculateNewBytes-aux(sNat(N:#Nat), K:K, dataList((piece(Bit:#Nat, 1),, L:List{K})), Result:List{K}) 
		=> calculateNewBytes-aux(N:#Nat, K:K, dataList(L:List{K}), (Result:List{K},, piece(Bit:#Nat, 1))) 
		[structural]
	
	define calculateNewBytes-aux(0, dataList((piece(N:#Nat, 1),, L:List{K})), dataList((piece(_:#Nat, 1),, L':List{K})), Result:List{K}) 
		=> calculateNewBytes-aux(0, dataList(L:List{K}), dataList(L':List{K}), (Result:List{K},, piece(N:#Nat, 1))) 
		[structural]
	define calculateNewBytes-aux(0, dataList(.List{K}), dataList(L:List{K}), Result:List{K}) 
		=> joinBitsToBytes((Result:List{K},, L:List{K})) 
		[structural]
	
	define joinBitsToBytes(L:List{K}) => joinBitsToBytes-aux(dataList(L:List{K}), dataList(.List{K})) [structural]
	define joinBitsToBytes-aux(dataList((piece(N:#Nat, Len:#Nat),, piece(M:#Nat, 1),, L:List{K})), dataList(R:List{K}))
		=> joinBitsToBytes-aux(dataList((piece(_bit::_(piece(N:#Nat, Len:#Nat), piece(M:#Nat, 1)), sNat(Len:#Nat)),, L:List{K})), dataList(R:List{K}))
		when Len:#Nat <Nat numBitsPerByte 
		[structural]
	define joinBitsToBytes-aux(dataList((piece(N:#Nat, Len:#Nat),, L:List{K})), dataList(R:List{K}))
		=> joinBitsToBytes-aux(dataList(L:List{K}), dataList((R:List{K},, piece(N:#Nat, Len:#Nat))))
		when Len:#Nat ==Bool numBitsPerByte 
		[structural]
	define joinBitsToBytes-aux(dataList(.List{K}), dataList(R:List{K}))
		=> dataList(R:List{K}) 
		[structural]
	
	
	define explodeToBits((K:K,, L:NeList{K})) => (explodeToBits(K:K),, explodeToBits(L:NeList{K})) [structural]
	define explodeToBits(piece(N:#Nat, sNat(Len:#Nat)))
		=> splinter(N:#Nat, sNat(Len:#Nat)) 
		[structural]
	define explodeToBits(piece(N:#Nat, 0)) => .List{K} [structural]
	define explodeToBits(.List{K}) => .List{K} [structural]
	
	declare splinter : #Nat #Nat -> List{K} 
	declare splinter-aux : #Nat #Nat #Nat -> List{K} 
	define splinter(N:#Nat, Len:#Nat) => splinter-aux(N:#Nat, Len:#Nat, 0) [structural]
	define splinter-aux(_:#Nat, Len:#Nat, Len:#Nat) => .List{K} [structural]
	define splinter-aux(N:#Nat, Len:#Nat, Pos:#Nat)
		=> splinter-aux(N:#Nat, Len:#Nat, sNat(Pos:#Nat)),, piece(bitRange(N:#Nat, Pos:#Nat, Pos:#Nat), 1)
		when Pos:#Nat <Nat Len:#Nat 
		[structural]
	

	rule
		< k > writeBytes(sym(Block:#Nat) +Nat Offset:#Nat, dataList((V:K,, L:List{K})))
			=> writeByte(sym(Block:#Nat) +Nat Offset:#Nat, V:K)
			~> writeBytes(sym(Block:#Nat) +Nat sNat(Offset:#Nat), dataList(L:List{K}))
		...</ k >
		[structural]
	rule [write-byte-buffer]:
		< k > writeByte(LOC, V:K) => .K ...</ k >
		< buffer >... (.List => bwrite(LOC, V:K)) </ buffer >
		< mem >... Block:#Nat |-> memblock(mlength(Len:#Nat) Attr:Bag, _) ...</ mem >		
		< locsWrittenTo > Locs:Bag (.Bag => BagItem(LOC)) </ locsWrittenTo >
		< notWritable > NotWritable:Map </notWritable>
		when notBool LOC in Locs:Bag
		andBool Offset:#Nat <Nat Len:#Nat
		andBool notBool mconst in Attr:Bag
		andBool notBool $hasMapping(NotWritable, LOC)
		where LOC = sym(Block:#Nat) +Nat Offset:#Nat
		[structural]
		
	rule [commit-byte]:
		< blocked > false </ blocked >
		< buffer > (bwrite(sym(Block:#Nat) +Nat Offset:#Nat, V:K) => .List) ...</ buffer >
		< mem >... Block:#Nat |-> memblock(mlength(Len:#Nat) _, (M:Map => M:Map[V:K / Offset:#Nat])) ...</ mem >
		when Offset:#Nat <Nat Len:#Nat
		[structural]
	rule
		< k > writeBytes(_:#Nat, dataList(.List{K})) => .K ...</ k >
		[structural] 
		
	// this general rule is useful for unknowns, abstracts, etc
	define [splitBytes-char]:
		splitBytes(tv(N:#Nat, T:KResult))
			=> dataList(piece(N:#Nat, numBitsPerByte))
		when hasCharType(T:KResult)
		[structural] 
	define [splitBytes-int]:
		splitBytes(tv(I:#Int, T:KResult)) 
		// => splitIntegerBytes(I:#Int, T:KResult, value(byteSizeofType(T:KResult)))
			=> splitIntegerBytes(I:#Int, T:KResult, bitsToBytes(value(bitSizeofType(T:KResult))))
		when hasIntegerType(T:KResult)
		andBool (I:#Int >=Int 0 orBool I:#Int <=Int 0)
		[structural] 
	define [splitBytes-float]:
		splitBytes(tv(F:#Float, T:KResult)) 
			=> splitFloatBytes(F:#Float, T:KResult, value(byteSizeofType(T:KResult)))
		when hasFloatType(T:KResult)
		[structural] 
	define [splitBytes-pointer]:
		splitBytes(tv(I:#Int, t(S:Set, pointerType(T:KResult)))) 
			=> splitPointerBytes(I:#Int, t(S:Set, pointerType(T:KResult)), value(byteSizeofType(t(.Set, pointerType(T:KResult)))))
		[structural]
	define [splitBytes-struct]:
		splitBytes(tv(L:List{K}, t(S:Set, structType(S:#Id)))) 
			=> splitStructBytes(dataList(L:List{K}), t(S:Set, structType(S:#Id)), value(byteSizeofType(t(S:Set, structType(S:#Id)))))
		// if hasStructType(T:KResult)
		[structural]
	define [splitBytes-union]:
		splitBytes(tv(L:List{K}, t(S:Set, unionType(S:#Id)))) 
			=> splitStructBytes(dataList(L:List{K}), t(S:Set, unionType(S:#Id)), value(byteSizeofType(t(S:Set, unionType(S:#Id)))))
		[structural] 
	
	declare splitIntegerBytes : K K K -> K 
	declare splitIntegerBytes-aux : K K K List{K} -> K 
	//context splitIntegerBytes(_, _, value(HOLE)) 
	define splitIntegerBytes(I:#Int, T:KResult, Len:#Nat) => splitIntegerBytes-aux(I:#Int, T:KResult, Len:#Nat, .List{K}) [structural]
	define splitIntegerBytes-aux(I:#Int, T:KResult, sNat(Len:#Nat), L:List{K})
		=> splitIntegerBytes-aux(I:#Int >>Int numBitsPerByte, T:KResult, Len:#Nat, (L:List{K},, lowestByte(I:#Int, T:KResult))) 
		[structural]
	define splitIntegerBytes-aux(_, _, 0, L:List{K})
		=> dataList(L:List{K}) 
		[structural]
		
	declare splitStructBytes : K K K -> K 
	declare splitStructBytes : K K K List{K} -> K 
	context splitStructBytes(_, _, value(HOLE)) 
	define splitStructBytes(dataList(L:List{K}), T:KResult, Len:#Nat) 
		=> splitStructBytes(dataList(L:List{K}), T:KResult, Len:#Nat, .List{K}) 
		[structural]
	define splitStructBytes(dataList((piece(N:#Nat, PieceLen:#Nat),, Rest:List{K})), T:KResult, sNat(Len:#Nat), L:List{K})
		=> splitStructBytes(dataList(Rest:List{K}), T:KResult, Len:#Nat, (L:List{K},, piece(N:#Nat, PieceLen:#Nat))) 
		when PieceLen:#Nat ==Bool numBitsPerByte 
		[structural]
	define splitStructBytes(_, _, 0, L:List{K})
		=> dataList(L:List{K}) 
		[structural]
		
		
	declare splitPointerBytes : K K K -> K 
	declare splitPointerBytes-aux : K K K K List{K} -> K 
	context splitPointerBytes(_, _, value(HOLE))
	// define splitPointerBytes(I:#Int, T:KResult, sNat(Len:#Nat))
		// => splitPointerBytes-aux(I:#Int, T:KResult, Len:#Nat, piece(encodedPointer(I:#Int), numBitsPerByte)) 
		// [structural]
	// define splitPointerBytes-aux(I:#Int, T:KResult, sNat(Len:#Nat), L:List{K}) 
		// => splitPointerBytes-aux(I:#Int, T:KResult, Len:#Nat, (L:List{K},, piece(unknown(numBitsPerByte), numBitsPerByte)))
		// [structural]
	define splitPointerBytes(I:#Int, T:KResult, Len:#Nat)
		=> splitPointerBytes-aux(I:#Int, T:KResult, Len:#Nat, 0, .List{K}) 
		[structural]
	define splitPointerBytes-aux(I:#Int, T:KResult, sNat(Len:#Nat), N:#Nat, L:List{K})
		=> splitPointerBytes-aux(I:#Int, T:KResult, Len:#Nat, N:#Nat +Nat 1, (L:List{K},, piece(subObject(I:#Int, N:#Nat, N:#Nat), numBitsPerByte)))
		[structural]
	define splitPointerBytes-aux(_, _, 0, _, L:List{K}) 
		=> dataList(L:List{K})
		[structural]
		
		
	declare splitFloatBytes : K K K -> K 
	declare splitFloatBytes : K K K List{K} -> K 
	context splitFloatBytes(_, _, value(HOLE)) 
	define splitFloatBytes(F:#Float, T:KResult, sNat(Len:#Nat)) 
		=> splitFloatBytes(F:#Float, T:KResult, Len:#Nat, piece(encodedFloat(F:#Float), numBitsPerByte)) 
		[structural]
	define splitFloatBytes(F:#Float, T:KResult, sNat(Len:#Nat), L:List{K}) => splitFloatBytes(F:#Float, T:KResult, Len:#Nat, (L:List{K},, piece(unknown(numBitsPerByte), numBitsPerByte))) 
		[structural]
	define splitFloatBytes(_, T:KResult, 0, L:List{K}) 
		=> dataList(L:List{K}) 
		[structural]
		
	
	declare lowestByte : #Int Type -> K 
	define lowestByte(I:#Int, T:KResult) => piece(I:#Int &Int byteMaskSet, numBitsPerByte)
		when hasIntegerType(T:KResult) 
		[structural]
	
	declare byteMaskSet : -> #Nat
	define byteMaskSet => (2 ^Nat numBitsPerByte) -Int 1 [structural]
		
	define isByteLoc(_:#Nat +Nat bito(_:#Nat)) => false [structural]
	// fixme owise!!!
	eq isByteLoc(_:#Nat) = true [owise] 
endkm

kmod DYNAMIC-C-MEMORY-MISC is
	including DYNAMIC-MEMORY-INCLUDE 

	// used by calloc
	rule
		< k > zeroBlock(sym(Block:#Nat) +Nat 0) => .K ...</ k >
		< mem >... Block:#Nat |-> memblock(mlength(Len:#Nat) _, (_ => .Map[piece(0, numBitsPerByte) / 0 to Len:#Nat])) ...</ mem >
		[structural]
		
	rule
		< k > sizeofLocation(sym(Block:#Nat) +Nat _:#Nat) => tv(Len:#Nat, cfg:sizeut) ...</ k >
		< mem >... Block:#Nat |-> memblock(mlength(Len:#Nat) _, _) ...</ mem >
		[structural]
		
	rule [delete-sized-block]:
		< k > deleteSizedBlock(sym(Block:#Nat) +Nat _:#Nat, Len:#Nat) => .K ...</ k >
		< mem >... Block:#Nat |-> memblock(mlength(Len:#Nat) _, _) => .Map ...</ mem >
		< buffer > .List </ buffer > // fixme could make this more relaxed by checking of block is in buffer, not just empty
		[structural] 
	
	rule [delete-block]:
		< k > deleteBlock(sym(Block:#Nat) +Nat _:#Nat) => .K ...</ k >
		< mem >... Block:#Nat |-> _ => .Map ...</ mem >
		< buffer > .List </ buffer >
		[structural] 
	
	// c99 6.5:2 If a side effect on a scalar object is unsequenced relative to either a different side effect on the same scalar object or a value computation using the value of the same scalar object, the behavior is undefined. If there are multiple allowable orderings of the subexpressions of an expression, the behavior is undefined if such an unsequenced side effect occurs in any of the orderings
	// i take this to mean that if i write to a location twice or read from a location after being written to, then it is a problem
		
	rule [alloc-string]:
		< k > allocString(Loc:#Nat, S:#String)
			=> allocateType(Loc:#Nat, t(.Set, arrayType(t(.Set, char), lengthString(S:#String))))
			~> writeString(Loc:#Nat, S:#String)
			~> makeUnwritable(Loc:#Nat)
		...</ k >
		[structural]
	rule [alloc-wstring]:
		< k > allocWString(Loc:#Nat, S:List{K})
			=> allocateType(Loc:#Nat, t(.Set, arrayType(cfg:wcharut, 4 *Nat lengthList{K}(S:List{K}))))
			~> writeWString(Loc:#Nat, S:List{K})
			~> makeUnwritable(Loc:#Nat)
		...</ k >
		[structural] 
	
	rule [makeUnwritable-var]:
		< k > makeUnwritableVar(X:#Id) => makeUnwritable(Loc:#Nat)  ...</ k >
		< env >... X:#Id |-> Loc:#Nat ...</ env>
		[structural]
	// fixme shouldn't need both of these
	rule [makeUnwritable-subobject]:
		< k > makeUnwritableSubObject(lv(sym(Base:#Nat) +Nat Offset:#Nat, _)) => . ...</ k >
		< notWritable > M:Map => M:Map[1 / sym(Base:#Nat) +Nat Offset:#Nat] </ notWritable >
		[structural]
	rule [makeUnwritable]:
		< k > makeUnwritable(sym(Base:#Nat) +Nat 0) => .K ...</ k >
		< mem >... Base:#Nat |-> memblock((.Bag => mconst) _, _) ...</ mem >
		[structural]

	
	op checkValidLoc-aux : K -> K
	
	rule
		< k > checkValidLoc(Loc:#Nat) => checkValidLoc-aux(ceilingLoc(Loc:#Nat)) ...</ k >
		[structural]
	rule
		< k > checkDerefLoc(Loc:#Nat) => checkValidLoc(Loc:#Nat) ...</ k >
		when Loc:#Nat =/=Bool NullPointer
		[structural]
	
	rule [check-valid-loc-null]:
		< k > checkValidLoc-aux(NullPointer) => .K ...</ k >
		[structural]
	// fixme could additionally use the type to check whether that type is valid for that pointer
	rule [check-valid-loc]:
		< k > checkValidLoc-aux(sym(BASE) +Nat Offset:#Nat) => .K ...</ k >
		< mem >... BASE |-> memblock(mlength(Len:#Nat) _, _) ...</ mem >
		<threadId> MyThreadId:#Nat </threadId>
		when (PtrThreadId:#Nat ==Bool MyThreadId:#Nat 
			orBool PtrThreadId:#Nat ==Bool 0
			orBool PtrThreadId:#Nat ==Bool allocatedDuration
			// orBool PtrThreadId:#Nat ==Bool readOnly
			) // my thread, global memory, or allocated (malloced) memory
		andBool Offset:#Nat <=Nat Len:#Nat // we're allowed to address one past
		where BASE = threadId(PtrThreadId:#Nat) +Nat N:#Nat
		[structural]
endkm

kmod DYNAMIC-C-MEMORY is
	including DYNAMIC-MEMORY-INCLUDE 
	including DYNAMIC-C-MEMORY-MISC 
	including DYNAMIC-SEMANTICS-WRITING 
	including DYNAMIC-SEMANTICS-READING 
endkm
