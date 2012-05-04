module DYNAMIC-MEMORY-INCLUDE is
	including DYNAMIC-INCLUDE 
	
	// returns the bytes in the order in which they are in memory
	syntax K ::= "extractBytesFromMem" "(" Nat "," Nat ")" [klabel(extractBytesFromMem)] // loc, size in bytes
	syntax Nat ::= "encodedPointer" "(" Int ")" [klabel(encodedPointer)]
	syntax Nat ::= "encodedFloat" "(" Float ")" [klabel(encodedFloat)]
	declare explodeToBits : List{K} -> List{K}
	declare reverseList : List{K} -> List{K}
	syntax ListItem ::= "bwrite" "(" Nat "," K ")" [klabel(bwrite)]
	declare locations : List -> Set
	syntax K ::= "read-aux" "(" K "," K "," K ")" [klabel(read-aux)]
	
	syntax Nat ::= "subObject" "(" K "," K "," K ")" [klabel(subObject)] // object, start piece, end piece
	define 'isInt(subObject(_, _, _)) => true
	define 'isInt(encodedPointer(_)) => true
	define 'isInt(encodedFloat(_)) => true
	
	// fixme would be better to keep canonical
	declare getBitOffset : Nat -> Nat 
	define getBitOffset(loc(_:Nat, _:Nat, M:Nat)) => M:Nat %Int numBitsPerByte
	declare getByteOffset : Nat -> Nat 
	define getByteOffset(loc(_:Nat, M:Nat, N:Nat)) => M +Int N:Nat /Int numBitsPerByte
	
	define [locations-none]: locations(.List) => .Set
	define [locations-some]: locations(bwrite(Loc:Nat, _) L:List) => SetItem(Loc:Nat) locations(L:List)
end module

module DYNAMIC-SEMANTICS-READING is
	including DYNAMIC-MEMORY-INCLUDE 
	
	syntax K ::= "extractBitsFromMem" "(" Nat "," Nat ")" [klabel(extractBitsFromMem)] // loc, size in bits
	syntax K ::= "extractByteFromMem" "(" Nat ")" [klabel(extractByteFromMem)] 
	
	syntax K ::= "extractBitsFromList-aux" "(" K "," Int "," Int "," List{K} ")" [klabel(extractBitsFromList-aux)] // datalist, offset in bits into list, number of bits to extract, accumulator
	rule extractBitsFromList(dataList(L:List{K}), N:Nat, M:Nat) 
		=> extractBitsFromList-aux(dataList(explodeToBits(L:List{K})), N:Nat, M:Nat, .List{K})
		[structural]
	// fixme snat
	rule
		<k> extractBitsFromList-aux(dataList((piece(_:Nat, 1),, L:List{K})), Offset:Nat, NumBits:Nat, .List{K})
			=> extractBitsFromList-aux(dataList(L:List{K}), Offset:Nat -Int 1, NumBits:Nat, .List{K})
		...</k>
		when Offset:Nat >Int 0
		[structural] 
	rule
		<k> extractBitsFromList-aux(dataList((piece(N:Nat, 1),, L:List{K})), 0, NumBits:Nat, Done:List{K})
			=> extractBitsFromList-aux(dataList(L:List{K}), 0, NumBits:Nat -Int 1, (Done:List{K},, piece(N:Nat, 1)))
		...</k>
		when NumBits:Nat >Int 0
		[structural] 
	
	rule
		<k> extractBitsFromList-aux(_, 0, 0, Done:List{K}) => dataList(Done:List{K}) ...</k>
		[structural] 
	
	
	context readActual(_, _, value(HOLE))
	rule read(Loc:Nat, T:KResult) => read-aux(Loc:Nat, T:KResult, value(bitSizeofType(T:KResult))) 
		when notBool(isFunctionType(T:KResult))
		[structural]
	
	
	
	syntax K ::= "readActual" "(" K "," K "," K ")" [klabel(readActual)]
	
	/*@ These rules figure out whether the read should be structural or computational, depending on what is being read
	*/
	rule [read-thread-local]:
		<k> ('read-aux => 'readActual)(loc(threadId(Id:Nat) +Int _:Nat, _:Nat, _:Nat),, _,, _) ...</k>
		<threadId> Id:Nat </threadId>
		[structural ndlocal]
	rule [read-shared]: // read global or shared data
		<k> ('read-aux => 'readActual)(loc(threadId(0) +Int _:Nat, _:Nat, _:Nat),, _,, _) ...</k>
		[computational ndlocal]
	rule [read-allocated]: // read data of "allocated" duration
		<k> ('read-aux => 'readActual)(loc(threadId(allocatedDuration) +Int _:Nat, _:Nat, _:Nat),, _,, _) ...</k>
		[computational ndlocal]
	
	rule [read]:
		<k> readActual(Loc:Nat, T:KResult, bitSize:Nat)
			=> concretize(T:KResult, extractBytesFromMem(Loc:Nat, bitsToBytes(bitSize:Nat)))
		...</k>
		when notBool isBitfieldType(T:KResult)
		[structural]
	rule [read-bitfield]:
		<k> readActual(Loc:Nat, T:KResult, bitSize:Nat)
			=> concretize(T:KResult, fillToBytes(extractBitsFromMem(Loc:Nat, bitSize:Nat))) 
		...</k>
		when isBitfieldType(T:KResult)
		[structural]
	
		
	syntax K ::= "joinIntegerBytes" "(" Type "," List{K} ")" [klabel(joinIntegerBytes)] 
	rule 
		<k> concretize(T:KResult, dataList(L:List{K})) 
			=> joinIntegerBytes(T:KResult, L:List{K}) 
		...</k>
		when hasIntegerType(T:KResult) 
		andBool notBool isBitfieldType(T:KResult) 
		[structural]
	rule 
		<k> concretize(t(S:Set, bitfieldType(T:KResult, Len:Nat)), dataList(L:List{K})) 
			=> joinIntegerBytes(t(S:Set, bitfieldType(T:KResult, Len:Nat)), reverseList(L:List{K})) 
		...</k>
		//if // hasIntegerType(T:KResult) // redundant
		//isBitfieldType(T:KResult) 
		[structural]
		
	// FIXME very unsafe, not checking size of list or its contents
	rule <k> concretize(T:KResult, dataList((piece(encodedFloat(F:Float), Len:Nat),, _))) 
			=> tv(F:Float, T:KResult)
		...</k>
		when isFloatType(T:KResult)
		andBool Len:Nat ==Int numBitsPerByte 
		[structural]

	syntax K ::= "joinPointerBytes" "(" Type "," List{K} ")" [klabel(joinPointerBytes)]
	syntax K ::= "joinPointerBytes-aux" "(" Type "," List{K} "," K ")" [klabel(joinPointerBytes-aux)]
	// fixme should also check sizes are appropriate
	rule <k> concretize(T:KResult, dataList(L:List{K}))
			=> joinPointerBytes(T:KResult, L:List{K})
		...</k>
		when isPointerType(T:KResult)
		[structural]
	rule <k> joinPointerBytes(T:KResult, (piece(N:Nat, Len:Nat),, L:List{K}))
			=> joinPointerBytes-aux(T:KResult, L:List{K}, N:Nat)
		...</k>
		when Len:Nat ==Int numBitsPerByte
		[structural]
	// fixme sNat
	rule <k> joinPointerBytes-aux(T:KResult, (piece(subObject(N:Nat, sNatEnd:Nat, sNatEnd:Nat), Len:Nat),, L:List{K}), subObject(N:Nat, 0, End:Nat))
			=> joinPointerBytes-aux(T:KResult, L:List{K}, subObject(N:Nat, 0, End:Nat +Int 1))
		...</k>
		when Len:Nat ==Int numBitsPerByte
		andBool sNatEnd:Nat ==Int End:Nat +Int 1
		[structural]
	rule <k> joinPointerBytes-aux(T:KResult, .List{K}, subObject(N:Nat, 0, End:Nat))
			=> checkValidLoc(N:Nat)
			~> tv(N:Nat, T:KResult)
		...</k>
		[structural]

	rule <k> concretize(t(S:Set, structType(S:Id)), dataList(L:List{K})) 
			=> tv(L:List{K}, t(S:Set, structType(S:Id))) 
		...</k>
		// if isStructType(T:KResult)
		[structural]
	rule <k> concretize(t(S:Set, unionType(S:Id)), dataList(L:List{K})) 
			=> tv(L:List{K}, t(S:Set, unionType(S:Id)))
		...</k>
		// if isUnionType(T:KResult)
		[structural]

	// FIXME assuming bytes?
	syntax K ::= "joinIntegerBytes-aux" "(" Type "," List{K} "," K ")" [klabel(joinIntegerBytes-aux)] 
	rule [joinIntegerBytes-start]:
		joinIntegerBytes(T:KResult, L:List{K}) 
			=> joinIntegerBytes-aux(T:KResult, L:List{K}, piece(0, 0)) 
		[structural]
	
	// fixme may want to consider restricting further, or loosening
	rule [joinIntegerBytes-unknown-char]:
		joinIntegerBytes-aux(T:KResult, piece(unknown(Len:Nat), Len:Nat), piece(0, 0))
			=> tv(piece(unknown(Len:Nat), Len:Nat), T:KResult)
		when isCharType(T:KResult)
		[structural]
	
	rule [joinIntegerBytes-step]:
		joinIntegerBytes-aux(T:KResult, (L:List{K},, piece(N:Nat, Len:Nat)), piece(N':Nat, Len':Nat))
			=> joinIntegerBytes-aux(T:KResult, L:List{K}, piece(_bit::_(piece(N':Nat, Len':Nat), piece(N:Nat, Len:Nat)), Len:Nat +Int Len':Nat))
		when N':Nat >=Int 0 // guard is here to make sure it's an actual piece
		[structural]
	rule [joinIntegerBytes-done]:
		joinIntegerBytes-aux(T:KResult, .List{K}, piece(N:Nat, Len:Nat)) 
			=> interpret(T:KResult, piece(N:Nat, Len:Nat)) 
		when N:Nat >=Int 0 // guard is here to make sure it's an actual piece
		[structural]
	
	define floorLoc(loc(Base:Nat, Offset:Nat, BitOffset:Nat)) => loc(Base:Nat, Offset:Nat, 0)
		when BitOffset:Nat <Int numBitsPerByte
	// eq floorLoc(sym(N:Nat) +Int R:Nat) = sym(N:Nat) +Int R:Nat [owise] 
	
	define [ceilingLoc-null]: ceilingLoc(NullPointer) => NullPointer
	// fixme possible bug here with new builtins
	// rule [ceilingLoc-bito]: ceilingLoc(sym(N:Nat) +Int bito(M:Nat) +Int R:Nat)
		// => sym(N:Nat) +Int absInt(floorRat(M:Nat /Rat numBitsPerByte)) +Int R:Nat
		// [structural]
	// fixme I don't think this is correct
	// define [ceilingLoc-base]: 
		// ceilingLoc(loc(N:Nat, R:Nat, 0))
			// => loc(N:Nat, R:Nat, 0)
	define [ceilingLoc]:
		ceilingLoc(loc(N:Nat, R:Nat, M:Nat))
		=> loc(N:Nat, (M:Nat /Int numBitsPerByte) +Int R:Nat, 0)

	// fixme owise!!!
	// eq [ceilingLocNormal]: ceilingLoc(sym(N:Nat) +Int R:Nat) = sym(N:Nat) +Int R:Nat [owise] 
	
	rule
		<k> extractBitsFromMem(Loc:Nat, Size:Nat)
			=> extractBitsFromList(
				extractBytesFromMem(floorLoc(Loc:Nat), bitsToBytes(Size:Nat +Int getBitOffset(Loc:Nat)))
				, getBitOffset(Loc:Nat)
				, Size:Nat
			)
		...</k>
		[structural] 
	
	// context extractBytesFromMem-aux(_, _, (_,, HOLE,, _)) 
	// this next op should use Nats, but the context doesn't allow it.  See issue 54
	syntax K ::= "extractBytesFromMem-aux" "(" K "," K "," List{K} ")" [klabel(extractBytesFromMem-aux)] // loc, size in bytes, aux list
	
	rule
		<k> extractBytesFromMem(Loc:Nat, Size:Nat) 
			=> extractBytesFromMem-aux(Loc:Nat, Size:Nat, .List{K}) 
		...</k>
		[structural] 
		
	// fixme sNat
	rule
		<k> extractBytesFromMem-aux(Loc:Nat, Size:Nat, Aux:List{K})
			=> extractByteFromMem(Loc:Nat)
			~> extractBytesFromMem-aux(Loc:Nat +Int 1, Size:Nat -Int 1, Aux:List{K})
		...</k>
		when Size:Nat >Int 0
		[structural]
	rule
		<k> (tv(V:List{K}, T:KResult) => .K)
			~> extractBytesFromMem-aux(_, _, (Aux:List{K} => (Aux:List{K},, tv(V:List{K}, T:KResult))))
		...</k>
		[structural]		
	
	declare values : List{K} -> List{K} 
	define values((tv(K:K, _),, L:List{KResult})) => (K:K,, values(L:List{KResult}))
	define values(.List{K}) => .List{K}
	rule
		<k> extractBytesFromMem-aux(_, 0, Aux:List{KResult}) 
			=> dataList(values(Aux:List{KResult})) 
		...</k>
		[structural] 
	
	// FIXME make sure it's a byte
	
	rule [read-byte-fast]:
		<k> extractByteFromMem(loc(Base:Nat, Offset:Nat, 0))
			=> assert(notBool (loc(Base:Nat, Offset:Nat, 0) in Locs:Bag), 3)
			~> assert(Offset:Nat <Int Len:Nat, 2)
			~> tv(V:K, t(.Set, no-type))
		...</k>
		<br/>
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
			<bytes>... Offset:Nat |-> V:K ...</bytes>
		...</object>
		<locsWrittenTo> Locs:Bag </locsWrittenTo>
		<buffer> .List </buffer>
		[large structural]
	rule [read-byte]:
		<k> extractByteFromMem(loc(Base:Nat, Offset:Nat, 0))
			=> assert(notBool (loc(Base:Nat, Offset:Nat, 0)) in Locs:Bag, 3)
			~> assert(Offset:Nat <Int Len:Nat, 2)
			~> tv(V:K, t(.Set, no-type))
		...</k>
		<br/>
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
			<bytes>... Offset:Nat |-> V:K ...</bytes>
		...</object>
		<locsWrittenTo> Locs:Bag </locsWrittenTo>
		<buffer> Mem:List </buffer>
		when notBool loc(Base:Nat, Offset:Nat, 0) in locations(Mem:List)
		[large structural]
		
	rule [read-byte-lazy]:
		<k> extractByteFromMem(loc(Base:Nat, Offset:Nat, 0)) 
			=> assert(Offset:Nat <Int Len:Nat, 2)
			~> tv(piece(unknown(numBitsPerByte), numBitsPerByte), t(.Set, no-type))
		...</k>
		<br/>
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
			<bytes> M:Map => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset:Nat] </bytes>
		...</object>
		<buffer> Mem:List </buffer>
		when notBool loc(Base:Nat, Offset:Nat, 0) in locations(Mem:List)
		andBool notBool Offset:Nat in keys M:Map
		[large structural]
		
	rule [read-byte-buffer]:
		<k> extractByteFromMem(Loc:Nat) 
			=> assert(notBool Loc:Nat in Locs:Bag, 3)
			~> tv(V:K, t(.Set, no-type))
		...</k>
		<locsWrittenTo> Locs:Bag </locsWrittenTo>
		<buffer>... bwrite(Loc:Nat, V:K) Mem:List </buffer>
		when notBool Loc:Nat in locations(Mem:List)
		[structural]
		//[interpRule] // for speed in interpretation; forces local buffer to be flushed before a read

end module

module DYNAMIC-SEMANTICS-WRITING is
	including DYNAMIC-MEMORY-INCLUDE 
	context alloc(_, value(HOLE)) 

	rule 
		allocateType(Loc:Nat, T:KResult) 
			=> alloc(Loc:Nat, value(byteSizeofType(T:KResult))) 
		[structural]
	rule [allocateTypeIfAbsent-absent]:
		<k> allocateTypeIfAbsent(Loc:Nat, T:KResult) 
			=> alloc(Loc:Nat, value(byteSizeofType(T:KResult))) 
		...</k>
		<memory> Mem:Bag </memory>
		when notBool base(Loc:Nat) in gatherInnerCells(Mem:Bag, basePtr)
		[structural] 
	rule [allocateTypeIfAbsent-present]:
		<k> allocateTypeIfAbsent(loc(Base:Nat, 0, 0), T:KResult) => .K ...</k>
		<object>...
			<basePtr> Base:Nat </basePtr>
		...</object>
		[structural]

	rule [alloc-lazy]:
		<k> alloc(loc(Base:Nat, 0, 0), Len:Nat) => .K ...</k>
		// <mem>... .Map => Base:Nat |-> memblock(mlength(Len:Nat), .Map) ...</mem>
		<memory>...
			(.Bag => <object>...
				<basePtr> Base:Nat </basePtr>
				<oLength> Len:Nat </oLength>
				<properties> .Bag </properties>
			...</object>)
		...</memory>
		[structural]
	
	syntax K ::= "realloc-aux" "(" K "," K "," K "," K "," K ")" [klabel(realloc-aux)]
	rule [realloc-start]:
		<k> realloc(Old:K, New:K, OldLen:Nat, NewLen:Nat)
			=> alloc(New:K, NewLen:Nat)
			~> realloc-aux(minInt(OldLen:Nat, NewLen:Nat), Old:K, New:K, OldLen:Nat, NewLen:Nat)
		...</k>
		[structural]
		
	// fixme sNat this kind of rule might be very slow without matching on sNat (it's also ugly)
	// rule [realloc-found]:
		// <k> realloc-aux((sNat(N:Nat) => N:Nat), sym(OldBase:Nat) +Int 0, sym(NewBase:Nat) +Int 0, _, _)
		// ...</k>
		// <mem>... 
			// OldBase:Nat |-> memblock(_, (_ N:Nat |-> K:K))
			// NewBase:Nat |-> memblock(_, (_ (.Map => N:Nat |-> K:K)))
		// ...</mem>
		// [structural]
	rule [realloc-found]:
		<k> realloc-aux((sNatN:Nat => sNatN:Nat -Int 1), loc(OldBase:Nat, 0, 0), loc(NewBase:Nat, 0, 0), _, _)
		...</k>
		<br/>
		<object>...
			<basePtr> OldBase:Nat </basePtr>
			<bytes>... N:Nat |-> K:K ...</bytes>
		...</object>
		<object>...
			<basePtr> NewBase:Nat </basePtr>
			<bytes>... .Map => sNatN:Nat -Int 1 |-> K:K ...</bytes>
		...</object>
		when N:Nat ==Int sNatN:Nat -Int 1
		andBool sNatN:Nat >Int 0
		[large structural]	
		
	// fixme sNat
	rule [realloc-unfound]:
		<k> realloc-aux((sNatN:Nat => sNatN:Nat -Int 1), loc(OldBase:Nat, 0, 0), loc(NewBase:Nat, 0, 0), _, _)
		...</k>
		<object>...
			<basePtr> OldBase:Nat </basePtr>
			<bytes> M:Map </bytes>
		...</object>
		when notBool sNatN:Nat -Int 1 in keys M:Map
		andBool sNatN:Nat >Int 0
		[structural]
	rule [realloc-0]:
		<k> realloc-aux(0, loc(OldBase:Nat, 0, 0), _, OldLen:Nat, _)
			=> deleteSizedBlock(loc(OldBase:Nat, 0, 0), OldLen:Nat) 
		...</k>
		[structural]	
		
	syntax K ::= "writeBytes" "(" Nat "," K ")" [strict(2) klabel(writeBytes)] 
	syntax K ::= "writeBitfield" "(" Nat "," Type "," K ")" [strict(3) klabel(writeBitfield)] 
	declare isByteLoc : Nat -> Bool 
	declare splitBytes : Value -> K 
	declare calculateNewBytes : Nat K K -> K [strict(3)] 
	
	syntax K ::= "write-aux" "(" K "," Value "," K ")" [strict(2) klabel(write-aux)]
	rule write(lv(Dest:Nat, T':KResult), tv(V:List{K}, T:KResult)) 
		=> write-aux(Dest:Nat, tv(V:List{K}, T:KResult), value(bitSizeofType(T:KResult))) 
		when notBool isConstType(T':KResult)
		[structural]
	context write-aux(_, _, value(HOLE))
	
	
	
	syntax K ::= "write-specific" "(" Nat "," Value "," Nat ")" [klabel(write-specific)]
	
	rule [write-thread-local]:
		<k> write-aux(Loc, tv(L:List{K}, T:KResult), bitSize:Nat)
			=> write-specific(Loc, tv(L:List{K}, T:KResult), bitSize:Nat)
		...</k>
		<threadId> Id:Nat </threadId>
		where Loc = loc(threadId(Id:Nat) +Int N:Nat, Offset:Nat, BitOffset:Nat)
		[structural ndlocal]
	rule [write]: // write global or shared data
		<k> write-aux(Loc, tv(L:List{K}, T:KResult), bitSize:Nat)
			=> write-specific(Loc, tv(L:List{K}, T:KResult), bitSize:Nat)
		...</k>
		where Loc = loc(threadId(0) +Int N:Nat, Offset:Nat, BitOffset:Nat)
		[computational ndlocal]
	rule [write-allocated]: // write data of "allocated" duration
		<k> write-aux(Loc, tv(L:List{K}, T:KResult), bitSize:Nat)
			=> write-specific(Loc, tv(L:List{K}, T:KResult), bitSize:Nat)
		...</k>
		where Loc = loc(threadId(allocatedDuration) +Int N:Nat, Offset:Nat, BitOffset:Nat)
		[computational ndlocal]
	
	rule [write-normal]:
		<k> write-specific(Loc:Nat, tv(V:K, T:KResult), bitSize:Nat)
			=> writeBytes(Loc:Nat, splitBytes(tv(V:K, T:KResult)))
		...</k>
		when bitSize:Nat %Int numBitsPerByte ==Int 0
		andBool isByteLoc(Loc:Nat)
		andBool notBool isBitfieldType(T:KResult)
		andBool notBool hasUnionMarker(T:KResult)
		[structural]
	rule [write-normal-union-field]:
		<k> (.K => makeUnknown(Loc:Nat, t(.Set, unionType(S:Id))))
			~> write-specific(Loc:Nat, tv(_, t((SetItem(fromUnion(S:Id)) => .Set) _, _)), _:Nat)
		...</k>
		when isByteLoc(Loc:Nat)
		[structural]
		
	syntax K ::= "makeUnknown" "(" Nat "," Type ")" [klabel(makeUnknown)]
	syntax K ::= "makeUnknown-aux" "(" Nat "," Type "," K ")" [klabel(makeUnknown-aux)] // should be Nat Type K
	context makeUnknown-aux(_:Nat, _, value(HOLE))
	
	rule makeUnknown(Loc:Nat, T:KResult)
		=> makeUnknown-aux(Loc:Nat, T:KResult, value(byteSizeofType(T:KResult))) 
		[structural]
	rule
		<k> makeUnknown-aux(loc(Base:Nat, Offset:Nat, 0), _, Len':Nat) => .K ...</k>
		<br/>
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
			<bytes> M:Map => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset:Nat to (Offset:Nat +Int Len':Nat)] </bytes>
		...</object>
		when Len:Nat >=Int Offset:Nat +Int Len':Nat
		[large structural]
		
	declare hasUnionMarker : Type -> Bool
	define hasUnionMarker(t(SetItem(fromUnion(_:Id)) _, _)) => true
	define hasUnionMarker(t(.Set, _)) => false
	define hasUnionMarker(t(S:Set (SetItem(L:KLabel(_:List{K}))), K:K))
		=> hasUnionMarker(t(S:Set, K:K))
		when L:KLabel =/=KLabel 'fromUnion
		[structural]
	
	
	rule [write-struct]:
		<k> write-specific(Loc:Nat, tv((V:K,, V':K,, L:List{K}), T:KResult), bitSize:Nat)
			=> writeBytes(Loc:Nat, dataList((V:K,, V':K,, L:List{K})))
		...</k>
		when bitSize:Nat %Int numBitsPerByte ==Int 0
		andBool isByteLoc(Loc:Nat)
		andBool notBool isBitfieldType(T:KResult)
		[structural]
		
	// define bitoffset(_:Nat +Int bito(N:Nat)) => N:Nat
	// // fixme owise!!!
	// eq bitoffset(_:Nat) = 0 [owise] 
	
	// fixme owise!!!
	// define byteoffset(N:Nat +Int bito(_:Nat)) => N:Nat
	// eq byteoffset(N:Nat) = N:Nat [owise] 
		
	declare justBits : Int Type -> Value 
	declare justBits-aux : Int Type -> Value 
	define justBits(I:Int, _) => I:Int
		when I:Int >=Int 0 
		[structural]
		
	define justBits(I:Int, T:KResult) => justBits-aux(I:Int, T:KResult)
		when I:Int <Int 0 
		[structural]
	define justBits-aux(I:Int, T:KResult) => justBits-aux((I:Int +Int max(T:KResult) +Int 1), T:KResult)
		when I:Int <Int 0 
		[structural]
	// fixme sNat
	define 
		justBits-aux(N:Nat, t(_, bitfieldType(T:KResult, Len:Nat))) 
			=> N:Nat +Int (1 <<Int (Len:Nat -Int 1))
		when Len:Nat >Int 0
		[structural]
	
	rule [massage-bitfield]:
		<k> write-specific(Loc:Nat, tv(I:Int, T:KResult), bitSize:Nat)
			=> write-specific(Loc:Nat, tv(justBits(I:Int, T:KResult), T:KResult), bitSize:Nat)
		...</k>
		when (bitSize:Nat %Int numBitsPerByte =/=Int 0
		orBool notBool(isByteLoc(Loc:Nat))
		orBool isBitfieldType(T:KResult))
		andBool I:Int <Int 0
		[structural]
	
	rule [write-bitfield]:
		<k> write-specific(Loc:Nat, tv(N:Nat, T:KResult), bitSize:Nat)
			=> writeBitfield(
				Loc:Nat
				, T:KResult
				, calculateNewBytes(
					getBitOffset(Loc:Nat)
					, piece(N:Nat, bitSize:Nat)
					, extractBytesFromMem(floorLoc(Loc:Nat), bitsToBytes(bitSize:Nat +Int getBitOffset(Loc:Nat))
					)
				)
			)
		...</k>
		when bitSize:Nat %Int numBitsPerByte =/=Int 0
		orBool notBool(isByteLoc(Loc:Nat))
		orBool isBitfieldType(T:KResult)
		andBool notBool hasUnionMarker(T:KResult)
		[structural]
		
	rule
		<k> writeBitfield(Loc:Nat, _, dataList(L:List{K}))
			// => writeBytes(getByteOffset(Loc:Nat), dataList(L:List{K}))
			=> writeBytes(floorLoc(Loc:Nat), dataList(L:List{K}))
		...</k>
		[structural] 
		
	declare calculateNewBytes-aux : Int K K List{K} -> K 
	define calculateNewBytes(Len:Nat, N:Nat, dataList(L:List{K})) 
		=> calculateNewBytes-aux(Len:Nat, dataList(explodeToBits(N:Nat)), dataList(explodeToBits(L:List{K})), .List{K})
		[structural]
	
	define reverseList(.List{K}) => .List{K}
	define reverseList((K:K,, L:List{K})) => reverseList(L:List{K}),, K:K
	
	declare joinBitsToBytes : List{K} -> K 
	declare joinBitsToBytes-aux : K K -> K 
	
	// fixme sNat
	define calculateNewBytes-aux(N:Nat, K:K, dataList((piece(Bit:Nat, 1),, L:List{K})), Result:List{K}) 
		=> calculateNewBytes-aux(N:Nat -Int 1, K:K, dataList(L:List{K}), (Result:List{K},, piece(Bit:Nat, 1))) 
		when N:Nat >Int 0
		[structural]
	
	define calculateNewBytes-aux(0, dataList((piece(N:Nat, 1),, L:List{K})), dataList((piece(_:Nat, 1),, L':List{K})), Result:List{K}) 
		=> calculateNewBytes-aux(0, dataList(L:List{K}), dataList(L':List{K}), (Result:List{K},, piece(N:Nat, 1))) 
		[structural]
	define calculateNewBytes-aux(0, dataList(.List{K}), dataList(L:List{K}), Result:List{K}) 
		=> joinBitsToBytes((Result:List{K},, L:List{K})) 
		[structural]
	
	define joinBitsToBytes(L:List{K}) => joinBitsToBytes-aux(dataList(L:List{K}), dataList(.List{K}))
	define joinBitsToBytes-aux(dataList((piece(N:Nat, Len:Nat),, piece(M:Nat, 1),, L:List{K})), dataList(R:List{K}))
		=> joinBitsToBytes-aux(dataList((piece(_bit::_(piece(N:Nat, Len:Nat), piece(M:Nat, 1)), Len:Nat +Int 1),, L:List{K})), dataList(R:List{K}))
		when Len:Nat <Int numBitsPerByte 
		[structural]
	define joinBitsToBytes-aux(dataList((piece(N:Nat, Len:Nat),, L:List{K})), dataList(R:List{K}))
		=> joinBitsToBytes-aux(dataList(L:List{K}), dataList((R:List{K},, piece(N:Nat, Len:Nat))))
		when Len:Nat ==Int numBitsPerByte 
		[structural]
	define joinBitsToBytes-aux(dataList(.List{K}), dataList(R:List{K}))
		=> dataList(R:List{K}) 
		[structural]
	
	
	define explodeToBits((K:K,, L:NeList{K})) => (explodeToBits(K:K),, explodeToBits(L:NeList{K}))
	define explodeToBits(piece(N:Nat, Len:Nat))
		=> splinter(N:Nat, Len:Nat)
		when Len:Nat >Int 0
		[structural]
	define explodeToBits(piece(N:Nat, 0)) => .List{K}
	define explodeToBits(.List{K}) => .List{K}
	
	declare splinter : Nat Nat -> List{K} 
	declare splinter-aux : Nat Nat Nat -> List{K} 
	define splinter(N:Nat, Len:Nat) => splinter-aux(N:Nat, Len:Nat, 0)
	define splinter-aux(_:Nat, Len:Nat, Len:Nat) => .List{K}
	define splinter-aux(N:Nat, Len:Nat, Pos:Nat)
		=> splinter-aux(N:Nat, Len:Nat, Pos:Nat +Int 1),, piece(bitRange(N:Nat, Pos:Nat, Pos:Nat), 1)
		when Pos:Nat <Int Len:Nat 
		[structural]
	

	rule
		<k> writeBytes(Loc:Nat, dataList((V:K,, L:List{K})))
			=> writeByte(Loc:Nat, V:K)
			~> writeBytes(Loc:Nat +Int 1, dataList(L:List{K}))
		...</k>
		[structural]
	rule [write-byte-buffer]:
		<k> writeByte(LOC, V:K) => .K ...</k>
		<buffer>... (.List => bwrite(LOC, V:K)) </buffer>
		<br/>
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
			<properties> Attr:Bag </properties>
		...</object>
		<locsWrittenTo> Locs:Bag (.Bag => BagItem(LOC)) </locsWrittenTo>
		<notWritable> NotWritable:Map </notWritable>
		when notBool LOC in Locs:Bag
		andBool Offset:Nat <Int Len:Nat
		andBool notBool mconst in Attr:Bag
		andBool notBool LOC in keys NotWritable:Map
		where LOC = loc(Base:Nat, Offset:Nat, 0)
		[large structural]
		
	rule [commit-byte]:
		<blocked> false </blocked>
		<buffer> (bwrite(loc(Base:Nat, Offset:Nat, 0), V:K) => .List) ...</buffer>
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
			<bytes> M:Map => M:Map[V:K / Offset:Nat] </bytes>
		...</object>
		when Offset:Nat <Int Len:Nat
		[structural]
	rule
		<k> writeBytes(_:Nat, dataList(.List{K})) => .K ...</k>
		[structural] 
		
	// this general rule is useful for unknowns, abstracts, etc
	define [splitBytes-char]:
		splitBytes(tv(N:Nat, T:KResult))
			=> dataList(piece(N:Nat, numBitsPerByte))
		when isCharType(T:KResult)
		[structural] 
	define [splitBytes-int]:
		splitBytes(tv(I:Int, T:KResult)) 
		// => splitIntegerBytes(I:Int, T:KResult, value(byteSizeofType(T:KResult)))
			=> splitIntegerBytes(I:Int, T:KResult, bitsToBytes(value(bitSizeofType(T:KResult))))
		when hasIntegerType(T:KResult)
		andBool (I:Int >=Int 0 orBool I:Int <=Int 0)
		[structural] 
	define [splitBytes-float]:
		splitBytes(tv(F:Float, T:KResult)) 
			=> splitFloatBytes(F:Float, T:KResult, value(byteSizeofType(T:KResult)))
		when isFloatType(T:KResult)
		[structural] 
	define [splitBytes-pointer]:
		splitBytes(tv(I:Int, t(S:Set, pointerType(T:KResult)))) 
			=> splitPointerBytes(I:Int, t(S:Set, pointerType(T:KResult)), value(byteSizeofType(t(.Set, pointerType(T:KResult)))))
		[structural]
	define [splitBytes-struct]:
		splitBytes(tv(L:List{K}, t(S:Set, structType(S:Id)))) 
			=> splitStructBytes(dataList(L:List{K}), t(S:Set, structType(S:Id)), value(byteSizeofType(t(S:Set, structType(S:Id)))))
		// if isStructType(T:KResult)
		[structural]
	define [splitBytes-union]:
		splitBytes(tv(L:List{K}, t(S:Set, unionType(S:Id)))) 
			=> splitStructBytes(dataList(L:List{K}), t(S:Set, unionType(S:Id)), value(byteSizeofType(t(S:Set, unionType(S:Id)))))
		[structural] 
	
	declare splitIntegerBytes : K K K -> K 
	declare splitIntegerBytes-aux : K K K List{K} -> K 
	//context splitIntegerBytes(_, _, value(HOLE)) 
	define splitIntegerBytes(I:Int, T:KResult, Len:Nat) => splitIntegerBytes-aux(I:Int, T:KResult, Len:Nat, .List{K})
	define 
		splitIntegerBytes-aux(I:Int, T:KResult, Len:Nat, L:List{K})
			=> splitIntegerBytes-aux(I:Int >>Int numBitsPerByte, T:KResult, Len:Nat -Int 1, (L:List{K},, lowestByte(I:Int, T:KResult)))
		when Len:Nat >Int 0
		[structural]
	define splitIntegerBytes-aux(_, _, 0, L:List{K})
		=> dataList(L:List{K}) 
		[structural]
		
	declare splitStructBytes : K K K -> K 
	declare splitStructBytes : K K K List{K} -> K 
	context splitStructBytes(_, _, value(HOLE)) 
	define splitStructBytes(dataList(L:List{K}), T:KResult, Len:Nat) 
		=> splitStructBytes(dataList(L:List{K}), T:KResult, Len:Nat, .List{K}) 
		[structural]
	define 
		splitStructBytes(dataList((piece(N:Nat, PieceLen:Nat),, Rest:List{K})), T:KResult, Len:Nat, L:List{K})
			=> splitStructBytes(dataList(Rest:List{K}), T:KResult, Len:Nat -Int 1, (L:List{K},, piece(N:Nat, PieceLen:Nat)))
		when PieceLen:Nat ==Int numBitsPerByte
		andBool Len:Nat >Int 0
		[structural]
	define splitStructBytes(_, _, 0, L:List{K})
		=> dataList(L:List{K}) 
		[structural]
		
		
	declare splitPointerBytes : K K K -> K 
	declare splitPointerBytes-aux : K K K K List{K} -> K 
	context splitPointerBytes(_, _, value(HOLE))
	define splitPointerBytes(I:Int, T:KResult, Len:Nat)
		=> splitPointerBytes-aux(I:Int, T:KResult, Len:Nat, 0, .List{K}) 
		[structural]
	define 
		splitPointerBytes-aux(I:Int, T:KResult, Len:Nat, N:Nat, L:List{K})
			=> splitPointerBytes-aux(I:Int, T:KResult, Len:Nat -Int 1, N:Nat +Int 1, (L:List{K},, piece(subObject(I:Int, N:Nat, N:Nat), numBitsPerByte)))
		when Len:Nat >Int 0
		[structural]
	define splitPointerBytes-aux(_, _, 0, _, L:List{K}) 
		=> dataList(L:List{K})
		[structural]
		
		
	declare splitFloatBytes : K K K -> K 
	declare splitFloatBytes : K K K List{K} -> K 
	context splitFloatBytes(_, _, value(HOLE)) 
	define splitFloatBytes(F:Float, T:KResult, Len:Nat) 
		=> splitFloatBytes(F:Float, T:KResult, Len:Nat -Int 1, piece(encodedFloat(F:Float), numBitsPerByte)) 
		when Len:Nat >Int 0
		[structural]
	define splitFloatBytes(F:Float, T:KResult, Len:Nat, L:List{K}) 
		=> splitFloatBytes(F:Float, T:KResult, Len:Nat -Int 1, (L:List{K},, piece(unknown(numBitsPerByte), numBitsPerByte))) 
		when Len:Nat >Int 0
		[structural]
	define splitFloatBytes(_, T:KResult, 0, L:List{K}) 
		=> dataList(L:List{K}) 
		[structural]
		
	
	declare lowestByte : Int Type -> K 
	define lowestByte(I:Int, T:KResult) => piece(I:Int &Int byteMaskSet, numBitsPerByte)
		when hasIntegerType(T:KResult) 
		[structural]
	
	declare byteMaskSet : -> Nat
	define byteMaskSet => (2 ^Int numBitsPerByte) -Int 1
		
	define isByteLoc(Loc:Nat) => getBitOffset(Loc:Nat) ==Int 0
end module

module DYNAMIC-C-MEMORY-MISC is
	including DYNAMIC-MEMORY-INCLUDE 

	// used by calloc
	rule
		<k> zeroBlock(loc(Base:Nat, 0, 0)) => .K ...</k>
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
			<bytes> _ => .Map[piece(0, numBitsPerByte) / 0 to Len:Nat] </bytes>
		...</object>
		[structural]
		
	rule
		<k> sizeofLocation(loc(Base:Nat, _:Nat, _:Nat)) => tv(Len:Nat, cfg:sizeut) ...</k>
		<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
		...</object>
		[structural]
		
	rule [delete-sized-block]:
		<k> deleteSizedBlock(loc(Base:Nat, _:Nat, _:Nat), Len:Nat) => .K ...</k>
		// <memory>...
		(<object>...
			<basePtr> Base:Nat </basePtr>
			<oLength> Len:Nat </oLength>
		...</object> => .Bag)
		// ...</memory>
		<buffer> .List </buffer> // fixme could make this more relaxed by checking of block is in buffer, not just empty
		[structural] 
	
	rule [delete-block]:
		<k> deleteBlock(loc(Base:Nat, _:Nat, _:Nat)) => .K ...</k>
		// <memory>...
		(<object>...
			<basePtr> Base:Nat </basePtr>
		...</object> => .Bag)
		// ...</memory>
		<buffer> .List </buffer>
		[structural] 
	
	// c99 6.5:2 If a side effect on a scalar object is unsequenced relative to either a different side effect on the same scalar object or a value computation using the value of the same scalar object, the behavior is undefined. If there are multiple allowable orderings of the subexpressions of an expression, the behavior is undefined if such an unsequenced side effect occurs in any of the orderings
	// i take this to mean that if i write to a location twice or read from a location after being written to, then it is a problem
		
	rule [alloc-string]:
		<k> allocString(Loc:Nat, S:String)
			=> allocateType(Loc:Nat, t(.Set, arrayType(t(.Set, char), lengthString(S:String))))
			~> writeString(Loc:Nat, S:String)
			~> makeUnwritable(Loc:Nat)
		...</k>
		[structural]
	rule [alloc-wstring]:
		<k> allocWString(Loc:Nat, S:List{K})
			=> allocateType(Loc:Nat, t(.Set, arrayType(cfg:wcharut, 4 *Int lengthList{K}(S:List{K}))))
			~> writeWString(Loc:Nat, S:List{K})
			~> makeUnwritable(Loc:Nat)
		...</k>
		[structural] 
	
	rule [makeUnwritable-var]:
		<k> makeUnwritableVar(X:Id) => makeUnwritable(Loc:Nat)  ...</k>
		<env>... X:Id |-> Loc:Nat ...</ env>
		[structural]
	// fixme shouldn't need both of these
	// fixme could do better with bitfields
	rule [makeUnwritable-subobject]:
		<k> makeUnwritableSubObject(lv(loc(Base:Nat, Offset:Nat, _), _)) => . ...</k>
		<notWritable> M:Map => M:Map[1 / loc(Base:Nat, Offset:Nat, 0)] </notWritable>
		[structural]
	rule [makeUnwritable]:
		<k> makeUnwritable(loc(Base:Nat, 0, 0)) => .K ...</k>
		<object>...
			<basePtr> Base:Nat </basePtr>
			<properties>... .Bag => mconst ...</properties>
		...</object>
		[structural]

	
	syntax K ::= "checkValidLoc-aux" "(" K ")" [klabel(checkValidLoc-aux)]
	
	rule
		<k> checkValidLoc(Loc:Nat) => checkValidLoc-aux(ceilingLoc(Loc:Nat)) ...</k>
		[structural]
	rule
		<k> checkDerefLoc(Loc:Nat) => checkValidLoc(Loc:Nat) ...</k>
		when Loc:Nat =/=K NullPointer
		[structural]
	
	rule [check-valid-loc-null]:
		<k> checkValidLoc-aux(NullPointer) => .K ...</k>
		[structural]
	// fixme could additionally use the type to check whether that type is valid for that pointer
	rule [check-valid-loc]:
		<k> checkValidLoc-aux(loc(BASE, Offset:Nat, 0)) => .K ...</k>
		<br/>
		<object>...
			<basePtr> BASE </basePtr>
			<oLength> Len:Nat </oLength>
		...</object>
		<threadId> MyThreadId:Nat </threadId>
		when (PtrThreadId:Nat ==Int MyThreadId:Nat 
			orBool PtrThreadId:Nat ==Int 0
			orBool PtrThreadId:Nat ==K allocatedDuration
			) // my thread, global memory, or allocated (malloced) memory
		andBool Offset:Nat <=Int Len:Nat // we're allowed to address one past
		where BASE = threadId(PtrThreadId:Nat) +Int N:Nat
		[large structural]
end module

module DYNAMIC-C-MEMORY is
	including DYNAMIC-MEMORY-INCLUDE 
	including DYNAMIC-C-MEMORY-MISC 
	including DYNAMIC-SEMANTICS-WRITING 
	including DYNAMIC-SEMANTICS-READING 
end module
