require "dynamic-c-semantics.k"

module DYNAMIC-MEMORY-INCLUDE
     imports DYNAMIC-INCLUDE 
     
     // returns the bytes in the order in which they are in memory
     syntax K ::= "extractBytesFromMem" "(" SymLoc "," Int ")" // loc, size in bytes
     //syntax Bits ::= "encodedPointer" "(" Int ")"
     syntax Bits ::= "encodedFloat" "(" Float ")"
     syntax KList ::= explodeToBits(KList) [function]
     syntax KList ::= reverseList(KList) [function]
     syntax ListItem ::= "bwrite" "(" SymLoc "," K ")"
     syntax Set ::= locations(List) [function]
     syntax K ::= "read-aux" "(" SymLoc "," K "," K ")" [klabel('read-aux)]
     
     syntax Bits ::= "subObject" "(" SymLoc "," K "," K ")" // object, start piece, end piece
     //define 'isInt(subObject(_, _, _)) => true
     //define 'isInt(encodedPointer(_)) => true
     //define 'isInt(encodedFloat(_)) => true
     
     // fixme would be better to keep canonical
     syntax Int ::= getBitOffset(SymLoc) [function]
     rule getBitOffset(loc(_, _, M:Int)) => M %Int numBitsPerByte
     syntax Int ::= getByteOffset(SymLoc) [function]
     rule getByteOffset(loc(_, M:Int, N:Int)) => M +Int N /Int numBitsPerByte
     
     rule [locations-none]: locations(.List) => .Set
     rule [locations-some]: locations(bwrite(Loc:SymLoc, _) L:List) => SetItem(Loc) locations(L:List)
endmodule

module DYNAMIC-SEMANTICS-READING
     imports DYNAMIC-MEMORY-INCLUDE 
     
     syntax K ::= "extractBitsFromMem" "(" SymLoc "," Int ")" // loc, size in bits
     syntax K ::= "extractByteFromMem" "(" SymLoc ")" 
     
     syntax K ::= "extractBitsFromList-aux" "(" K "," Int "," Int "," KList ")" // datalist, offset in bits into list, number of bits to extract, accumulator
     rule extractBitsFromList(dataList(L:KList), N:Int, M:Int) 
          => extractBitsFromList-aux(dataList(explodeToBits(L:KList)), N:Int, M:Int, .KList)
          [structural]
     // fixme snat
     rule <k> extractBitsFromList-aux(dataList((piece(_, 1),, L:KList)), Offset:Int, NumBits:Int, .KList)
               => extractBitsFromList-aux(dataList(L:KList), Offset:Int -Int 1, NumBits:Int, .KList)
          ...</k>
          when Offset:Int >Int 0
          [structural] 
     rule <k> extractBitsFromList-aux(dataList((piece(N:Bits, 1),, L:KList)), 0, NumBits:Int, Done:KList)
               => extractBitsFromList-aux(dataList(L:KList), 0, NumBits:Int -Int 1, (Done:KList,, piece(N, 1)))
          ...</k>
          when NumBits >Int 0
          [structural] 
     
     rule <k> extractBitsFromList-aux(_, 0, 0, Done:KList) => dataList(Done:KList) ...</k>
          [structural] 
     
     context readActual(_, _, value(HOLE))
     rule read(Loc:SymLoc, T:KResult) => read-aux(Loc, T:KResult, value(bitSizeofType(T:KResult))) 
          when notBool(isFunctionType(T:KResult))
          [structural]
     
     syntax K ::= "readActual" "(" SymLoc "," K "," K ")" [klabel('readActual)]
     
     /*@ These rules figure out whether the read should be structural or
     computational, depending on what is being read */
     rule [read-thread-local]:
          <k> ('read-aux => 'readActual)(loc(sb(_, Id:Int), _:Int, _:Int),, _,, _) ...</k>
          <threadId> Id:Int </threadId>
          [structural, ndlocal]
     rule [read-shared]: // read global or shared data
          <k> ('read-aux => 'readActual)(loc(sb(_, 0), _:Int, _:Int),, _,, _) ...</k>
          [computational, ndlocal]
     rule [read-allocated]: // read data of "allocated" duration
          <k> ('read-aux => 'readActual)(loc(sb(_, allocatedDuration), _:Int, _:Int),, _,, _) ...</k>
          [computational, ndlocal]
     
     rule [read]:
          <k> readActual(Loc:SymLoc, T:KResult, BitSize:Int)
               => concretize(T:KResult, extractBytesFromMem(Loc, bitsToBytes(BitSize:Int)))
          ...</k>
          when notBool isBitfieldType(T)
          [structural]
     rule [read-bitfield]:
          <k> readActual(Loc:SymLoc, T:KResult, BitSize:Int)
               => concretize(T:KResult, fillToBytes(extractBitsFromMem(Loc, BitSize:Int))) 
          ...</k>
          when isBitfieldType(T)
          [structural]
     
     syntax K ::= "joinIntegerBytes" "(" Type "," KList ")"
     rule <k> concretize(T:KResult, dataList(L:KList)) 
               => joinIntegerBytes(T:KResult, L:KList) 
          ...</k>
          when hasIntegerType(T:KResult) 
               andBool notBool isBitfieldType(T:KResult) 
          [structural]
     rule <k> concretize(t(S:Set, bitfieldType(T:KResult, Len:Int)), dataList(L:KList)) 
               => joinIntegerBytes(t(S:Set, bitfieldType(T:KResult, Len:Int)), reverseList(L:KList)) 
          ...</k>
          //if // hasIntegerType(T:KResult) // redundant
          //isBitfieldType(T:KResult) 
          [structural]
          
     // FIXME very unsafe, not checking size of list or its contents
     rule <k> concretize(T:KResult, dataList((piece(encodedFloat(F:Float), Len:Int),, _))) 
               => tv(F:Float, T:KResult)
          ...</k>
          when isFloatType(T:KResult)
               andBool (Len:Int ==Int numBitsPerByte)
          [structural]

     syntax K ::= "joinPointerBytes" "(" Type "," KList ")"
     syntax K ::= "joinPointerBytes-aux" "(" Type "," KList "," K ")"
     // fixme should also check sizes are appropriate
     rule <k> concretize(T:KResult, dataList(L:KList))
               => joinPointerBytes(T:KResult, L:KList)
          ...</k>
          when isPointerType(T:KResult)
          [structural]
     rule <k> joinPointerBytes(T:KResult, (piece(N:Bits, Len:Int),, L:KList))
               => joinPointerBytes-aux(T:KResult, L:KList, N)
          ...</k>
          when Len:Int ==Int numBitsPerByte
          [structural]
     // fixme sNat
     rule <k> joinPointerBytes-aux(T:KResult, (piece(subObject(N:SymLoc, SNatEnd:Int, SNatEnd:Int), Len:Int),, L:KList), subObject(N, 0, End:Int))
               => joinPointerBytes-aux(T, L, subObject(N, 0, End +Int 1))
          ...</k>
          when (Len ==Int numBitsPerByte)
               andBool (SNatEnd ==Int End +Int 1)
          [structural]
     rule <k> joinPointerBytes-aux(T:KResult, .KList, subObject(N:SymLoc, 0, End:Int))
               => checkValidLoc(N)
               ~> tv(N, T:KResult)
          ...</k>
          [structural]

     rule <k> concretize(t(S:Set, structType(I:Id)), dataList(L:KList)) 
               => tv(L:KList, t(S:Set, structType(I:Id))) 
          ...</k>
          // if isStructType(T:KResult)
          [structural]
     rule <k> concretize(t(S:Set, unionType(I:Id)), dataList(L:KList)) 
               => tv(L:KList, t(S:Set, unionType(I:Id)))
          ...</k>
          // if isUnionType(T:KResult)
          [structural]

     // FIXME assuming bytes?
     syntax K ::= "joinIntegerBytes-aux" "(" Type "," KList "," K ")"
     rule [joinIntegerBytes-start]:
          joinIntegerBytes(T:KResult, L:KList) 
               => joinIntegerBytes-aux(T:KResult, L:KList, piece(0, 0)) 
          [structural]
     
     // fixme may want to consider restricting further, or loosening
     rule [joinIntegerBytes-unknown-char]:
          joinIntegerBytes-aux(T:KResult, piece(unknown(Len:Int), Len:Int), piece(0, 0))
               => tv(piece(unknown(Len:Int), Len:Int), T:KResult)
          when isCharType(T:KResult)
          [structural]
     
     rule [joinIntegerBytes-step]:
          joinIntegerBytes-aux(T:KResult, (L:KList,, piece(N:Bits, Len:Int)), piece(N':Int, Len':Int))
               => joinIntegerBytes-aux(T, L, piece(piece(N', Len') bit:: piece(N, Len), Len +Int Len'))
          // TODO(chathhorn): (sort check) this can be removed, but for now leaving for reference
          when N' >=Int 0 // guard is here to make sure it's an actual piece
          [structural]
     rule [joinIntegerBytes-done]:
          joinIntegerBytes-aux(T:KResult, .KList, piece(N:Int, Len:Int)) 
               => interpret(T, piece(N, Len)) 
          // TODO(chathhorn): (sort check) this can be removed, but for now leaving for reference
          when N >=Int 0 // guard is here to make sure it's an actual piece
          [structural]
     
     rule floorLoc(loc(Base:SymBase, Offset:Int, BitOffset:Int)) => loc(Base, Offset:Int, 0)
          when BitOffset:Int <Int numBitsPerByte
     // eq floorLoc(sym(N:Int) +Int R:Int) = sym(N:Int) +Int R:Int [owise] 
     
     rule [ceilingLoc-null]: ceilingLoc(NullPointer) => NullPointer
     // fixme possible bug here with new builtins
     // rule [ceilingLoc-bito]: ceilingLoc(sym(N:Int) +Int bito(M:Int) +Int R:Int)
          // => sym(N:Int) +Int absInt(floorRat(M:Int /Rat numBitsPerByte)) +Int R:Int
          // [structural]
     // fixme I don't think this is correct
     // define [ceilingLoc-base]: 
          // ceilingLoc(loc(N:Int, R:Int, 0))
               // => loc(N:Int, R:Int, 0)
     rule [ceilingLoc]:
          ceilingLoc(loc(N:SymBase, R:Int, M:Int))
          => loc(N, (M /Int numBitsPerByte) +Int R, 0)

     // fixme owise!!!
     // eq [ceilingLocNormal]: ceilingLoc(sym(N:Int) +Int R:Int) = sym(N:Int) +Int R:Int [owise] 
     
     rule <k> extractBitsFromMem(Loc:SymLoc, Size:Int)
               => extractBitsFromList(
                    extractBytesFromMem(floorLoc(Loc), bitsToBytes(Size +Int getBitOffset(Loc)))
                    , getBitOffset(Loc)
                    , Size
               )
          ...</k>
          [structural] 
     
     // context extractBytesFromMem-aux(_, _, (_,, HOLE,, _)) 
     // this next op should use Nats, but the context doesn't allow it.  See issue 54
     syntax K ::= "extractBytesFromMem-aux" "(" SymLoc "," K "," KList ")" // loc, size in bytes, aux list
     
     rule <k> extractBytesFromMem(Loc:SymLoc, Size:Int) 
               => extractBytesFromMem-aux(Loc, Size, .KList) 
          ...</k>
          [structural] 
          
     // fixme sNat
     rule <k> extractBytesFromMem-aux(Loc:SymLoc, Size:Int, Aux:KList)
               => extractByteFromMem(Loc)
               ~> extractBytesFromMem-aux(Loc +bytes 1, Size -Int 1, Aux)
          ...</k>
          when Size:Int >Int 0
          [structural]
     rule <k> (tv(V:KList, T:KResult) => .K)
               ~> extractBytesFromMem-aux(_, _, (Aux:KList => (Aux:KList,, tv(V:KList, T:KResult))))
          ...</k>
          [structural]        
     
     syntax KList ::= values(KList) [function]
     rule values((tv(K:K, _),, L:KList)) => (K:K,, values(L:KList))
     rule values(.KList) => .KList
     rule <k> extractBytesFromMem-aux(_, 0, Aux:KList) 
               => dataList(values(Aux:KList)) 
          ...</k>
          [structural] 
     
     // FIXME make sure it's a byte
     
     rule [read-byte-fast]:
          <k> extractByteFromMem(loc(Base:SymBase, Offset:Int, 0))
               => assert(notBool (BagItem(loc(Base, Offset:Int, 0)) in Locs:Bag), 3)
               ~> assert(Offset:Int <Int Len:Int, 2)
               ~> tv(V:K, t(.Set, no-type))
          ...</k>
          <br/>
          <mem>... Base |-> memblock(Len:Int, _, (_ Offset:Int |-> V:K)) ...</mem>
//          <object>...
//               <basePtr> Base </basePtr>
//               <oLength> Len:Int </oLength>
//               <bytes>... Offset:Int |-> V:K ...</bytes>
//          ...</object>
          <locsWrittenTo> Locs:Bag </locsWrittenTo>
          <buffer> .List </buffer>
          [large, structural]
     rule [read-byte]:
          <k> extractByteFromMem(loc(Base:SymBase, Offset:Int, 0))
               => assert(notBool BagItem(loc(Base, Offset:Int, 0)) in Locs:Bag, 3)
               ~> assert(Offset:Int <Int Len:Int, 2)
               ~> tv(V:K, t(.Set, no-type))
          ...</k>
          <br/>
          <mem>... Base |-> memblock(Len:Int, _, (_ Offset:Int |-> V:K)) ...</mem>
//          <object>...
//               <basePtr> Base </basePtr>
//               <oLength> Len:Int </oLength>
//               <bytes>... Offset:Int |-> V:K ...</bytes>
//          ...</object>
          <locsWrittenTo> Locs:Bag </locsWrittenTo>
          <buffer> Mem:List </buffer>
          when notBool loc(Base, Offset:Int, 0) in locations(Mem:List)
          [large, structural]
          
     rule [read-byte-lazy]:
          <k> extractByteFromMem(loc(Base:SymBase, Offset:Int, 0)) 
               => assert(Offset:Int <Int Len:Int, 2)
               ~> tv(piece(unknown(numBitsPerByte), numBitsPerByte), t(.Set, no-type))
          ...</k>
          <br/>
          <mem>... Base |-> memblock(Len:Int, _, M:Map => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset]) ...</mem>
//          <object>...
//               <basePtr> Base </basePtr>
//               <oLength> Len:Int </oLength>
//               <bytes> M:Map => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset] </bytes>
//          ...</object>
          <buffer> Mem:List </buffer>
          when notBool loc(Base, Offset:Int, 0) in locations(Mem:List)
          andBool notBool Offset:Int in keys M:Map
          [large, structural]
          
     rule [read-byte-buffer]:
          <k> extractByteFromMem(Loc:SymLoc) 
               => assert(notBool BagItem(Loc) in Locs:Bag, 3)
               ~> tv(V:K, t(.Set, no-type))
          ...</k>
          <locsWrittenTo> Locs:Bag </locsWrittenTo>
          <buffer>... bwrite(Loc, V:K) Mem:List </buffer>
          when notBool Loc in locations(Mem:List)
          [structural]
          //[interpRule] // for speed in interpretation; forces local buffer to be flushed before a read

endmodule

module DYNAMIC-SEMANTICS-WRITING
     imports DYNAMIC-MEMORY-INCLUDE 
     context alloc(_, value(HOLE)) 

     rule allocateType(Loc:SymLoc, T:KResult) 
          => alloc(Loc, value(byteSizeofType(T))) 
          [structural]
     rule [allocateTypeIfAbsent-absent]:
          <k> allocateTypeIfAbsent(Loc:SymLoc, T:KResult) 
               => alloc(Loc, value(byteSizeofType(T:KResult))) 
          ...</k>
// TODO(chathhorn): (conversion to map)
//        <memory> Mem:Bag </memory>
//        when notBool (SetItem(base(Loc)) in gatherInnerCells(Mem:Bag, basePtr))
          <mem> M:Map </mem>
          when notBool (SetItem(base(Loc)) in (keys M))
          [structural] 
     rule [allocateTypeIfAbsent-present]:
          <k> allocateTypeIfAbsent(loc(Base:SymBase, 0, 0), T:KResult) => .K ...</k>
          <mem>... Base |-> memblock(_, _, _) ...</mem>
          // <object>...
          //      <basePtr> Base </basePtr>
          // ...</object>
          [structural]

     rule [alloc-lazy]:
          <k> alloc(loc(Base:SymBase, 0, 0), Len:Int) => .K ...</k>
          <mem>... .Map => Base |-> memblock(Len, .Bag, .Map) ...</mem>
          // <memory>...
          //      (. => <object>...
          //           <basePtr> Base </basePtr>
          //           <oLength> Len </oLength>
          //           <properties> .Bag </properties>
          //      ...</object>)
          // ...</memory>
          [structural]
     
     syntax K ::= "realloc-aux" "(" K "," K "," K "," K "," K ")"
     rule [realloc-start]:
          <k> realloc(Old:K, New:K, OldLen:Int, NewLen:Int)
               => alloc(New:K, NewLen:Int)
               ~> realloc-aux(minInt(OldLen:Int, NewLen:Int), Old:K, New:K, OldLen:Int, NewLen:Int)
          ...</k>
          [structural]
          
     // fixme sNat this kind of rule might be very slow without matching on sNat (it's also ugly)
     // rule [realloc-found]:
          // <k> realloc-aux((sNat(N:Int) => N:Int), sym(OldBase:Int) +Int 0, sym(NewBase:Int) +Int 0, _, _)
          // ...</k>
          // <mem>... 
               // OldBase:Int |-> memblock(_, (_ N:Int |-> K:K))
               // NewBase:Int |-> memblock(_, (_ (.Map => N:Int |-> K:K)))
          // ...</mem>
          // [structural]
     rule [realloc-found]:
          <k> realloc-aux((SNatN:Int => SNatN:Int -Int 1), loc(OldBase:SymBase, 0, 0), loc(NewBase:SymBase, 0, 0), _, _)
          ...</k>
          <mem>... 
               OldBase |-> memblock(_, _, (_ N:Int |-> K:K))
               NewBase |-> memblock(_, _, (_ (.Map => SNatN:Int -Int 1 |-> K:K)))
          ...</mem>
          // <object>...
          //      <basePtr> OldBase </basePtr>
          //      <bytes>... N:Int |-> K:K ...</bytes>
          // ...</object>
          // <object>...
          //      <basePtr> NewBase </basePtr>
          //      <bytes>... .Map => SNatN:Int -Int 1 |-> K:K ...</bytes>
          // ...</object>
          when (N ==Int SNatN -Int 1)
               andBool (SNatN >Int 0)
          [structural]   
          
     // fixme sNat
     rule [realloc-unfound]:
          <k> realloc-aux((SNatN:Int => SNatN -Int 1), loc(OldBase:SymBase, 0, 0), loc(NewBase:SymBase, 0, 0), _, _)
          ...</k>
          <mem>... OldBase |-> memblock(_, _, M:Map) ...</mem>
          // <object>...
          //      <basePtr> OldBase </basePtr>
          //      <bytes> M:Map </bytes>
          // ...</object>
          when (notBool SNatN:Int -Int 1 in keys M:Map)
               andBool (SNatN >Int 0)
          [structural]
     rule [realloc-0]:
          <k> realloc-aux(0, loc(OldBase:SymBase, 0, 0), _, OldLen:Int, _)
               => deleteSizedBlock(loc(OldBase, 0, 0), OldLen:Int) 
          ...</k>
          [structural]   
          
     syntax K ::= "writeBytes" "(" SymLoc "," K ")" [strict(2)] 
     syntax K ::= "writeBitfield" "(" SymLoc "," Type "," K ")" [strict(3)] 
     syntax Bool ::= isByteLoc(SymLoc) [function]
     syntax K ::= splitBytes(Value) [function]
     syntax K ::= calculateNewBytes(Int, K, K) [latex(\terminal{calcNewBytes(}{#1}, {#2}, {#3}\terminal{)}), strict(3)] 
     
     syntax K ::= "write-aux" "(" K "," Value "," K ")" [strict(2)]
     rule write(lv(Dest:SymLoc, T':Type), tv(V:KList, T:KResult)) 
          => write-aux(Dest, tv(V, T), value(bitSizeofType(T))) 
          when notBool isConstType(T')
          [structural]
     context write-aux(_, _, value(HOLE))
     
     syntax K ::= "write-specific" "(" SymLoc "," Value "," Int ")"
     
     rule [write-thread-local]:
          <k> write-aux(loc(sb(N:Int, Id:Int), Offset:Int, BitOffset:Int), tv(L:KList, T:KResult), BitSize:Int)
               => write-specific(loc(sb(N, Id), Offset:Int, BitOffset:Int), tv(L:KList, T:KResult), BitSize:Int)
          ...</k>
          <threadId> Id:Int </threadId>
          [structural, ndlocal]
     rule [write]: // write global or shared data
          <k> write-aux(loc(sb(N:Int, 0), Offset:Int, BitOffset:Int), tv(L:KList, T:KResult), BitSize:Int)
               => write-specific(loc(sb(N, 0), Offset:Int, BitOffset:Int), tv(L:KList, T:KResult), BitSize:Int)
          ...</k>
          [computational, ndlocal]
     rule [write-allocated]: // write data of "allocated" duration
          <k> write-aux(loc(sb(N:Int, allocatedDuration), Offset:Int, BitOffset:Int), tv(L:KList, T:KResult), BitSize:Int)
               => write-specific(loc(sb(N, allocatedDuration), Offset:Int, BitOffset:Int), tv(L:KList, T:KResult), BitSize:Int)
          ...</k>
          [computational, ndlocal]
     
     rule [write-normal]:
          <k> write-specific(Loc:SymLoc, tv(V:K, T:KResult), BitSize:Int)
               => writeBytes(Loc, splitBytes(tv(V, T)))
          ...</k>
          when (BitSize %Int numBitsPerByte ==Int 0)
          andBool isByteLoc(Loc)
          andBool (notBool isBitfieldType(T))
          andBool (notBool hasUnionMarker(T))
          [structural]
     rule [write-normal-union-field]:
          <k> (.K => makeUnknown(Loc, t(.Set, unionType(S))))
               ~> write-specific(Loc:SymLoc, tv(_, t((SetItem(fromUnion(S:Id)) => .Set) _, _)), _:Int)
          ...</k>
          when isByteLoc(Loc)
          [structural]
          
     syntax K ::= "makeUnknown" "(" SymLoc "," Type ")"
     syntax K ::= "makeUnknown-aux" "(" SymLoc "," Type "," K ")" // should be Nat Type K
     context makeUnknown-aux(_, _, value(HOLE))
     
     rule makeUnknown(Loc:SymLoc, T:KResult)
          => makeUnknown-aux(Loc, T, value(byteSizeofType(T))) 
          [structural]
     rule
          <k> makeUnknown-aux(loc(Base:SymBase, Offset:Int, 0), _, Len':Int) => .K ...</k>
          <br/>
          <mem>... Base |-> memblock(Len:Int, _, M:Map 
                    => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset to (Offset +Int Len')]) 
          ...</mem>
          // <object>...
          //      <basePtr> Base </basePtr>
          //      <oLength> Len:Int </oLength>
          //      <bytes> M:Map => M:Map[piece(unknown(numBitsPerByte), numBitsPerByte) / Offset:Int to (Offset:Int +Int Len':Int)] </bytes>
          // ...</object>
          when Len >=Int Offset +Int Len'
          [large, structural]
          
     syntax Bool ::= hasUnionMarker(Type) [function]
     rule hasUnionMarker(t(SetItem(fromUnion(_:Id)) _, _)) => true
     rule hasUnionMarker(t(.Set, _)) => false
     rule hasUnionMarker(t(S:Set (SetItem(L:KLabel(_:KList))), K:K))
          => hasUnionMarker(t(S:Set, K:K))
          when L:KLabel =/=KLabel 'fromUnion
          [structural]
     
     rule [write-struct]:
          <k> write-specific(Loc:SymLoc, tv((V:K,, V':K,, L:KList), T:KResult), BitSize:Int)
               => writeBytes(Loc, dataList((V,, V',, L)))
          ...</k>
          when (BitSize:Int %Int numBitsPerByte ==Int 0)
               andBool isByteLoc(Loc)
               andBool (notBool isBitfieldType(T:KResult))
          [structural]
          
     // define bitoffset(_:Int +Int bito(N:Int)) => N:Int
     // // fixme owise!!!
     // eq bitoffset(_:Int) = 0 [owise] 
     
     // fixme owise!!!
     // define byteoffset(N:Int +Int bito(_:Int)) => N:Int
     // eq byteoffset(N:Int) = N:Int [owise] 
          
     syntax Value ::= justBits(Int, Type)
     syntax Value ::= "justBits-aux" "(" Int "," Type ")"
     rule justBits(I:Int, _) => I:Int
          when I:Int >=Int 0 
          [structural]
          
     rule justBits(I:Int, T:KResult) => justBits-aux(I:Int, T:KResult)
          when I:Int <Int 0 
          [structural]
     rule justBits-aux(I:Int, T:KResult) => justBits-aux((I:Int +Int max(T:KResult) +Int 1), T:KResult)
          when I:Int <Int 0 
          [structural]
     // fixme sNat
     rule justBits-aux(N:Int, t(_, bitfieldType(T:KResult, Len:Int))) 
               => N:Int +Int (1 <<Int (Len:Int -Int 1))
          when Len:Int >Int 0
          [structural]
     
     rule [massage-bitfield]:
          <k> write-specific(Loc:SymLoc, tv(I:Int, T:KResult), BitSize:Int)
               => write-specific(Loc, tv(justBits(I:Int, T:KResult), T:KResult), BitSize:Int)
          ...</k>
          when (BitSize:Int %Int numBitsPerByte =/=Int 0
               orBool notBool(isByteLoc(Loc))
               orBool isBitfieldType(T:KResult))
               andBool (I:Int <Int 0)
          [structural]
     
     rule [write-bitfield]:
          <k> write-specific(Loc:SymLoc, tv(I:Int, T:KResult), BitSize:Int)
               => writeBitfield(
                    Loc
                    , T:KResult
                    , calculateNewBytes(
                         getBitOffset(Loc)
                         , piece(I, BitSize:Int)
                         , extractBytesFromMem(floorLoc(Loc), bitsToBytes(BitSize:Int +Int getBitOffset(Loc))
                         )
                    )
               )
          ...</k>
          when (BitSize:Int %Int numBitsPerByte =/=Int 0)
               orBool (notBool(isByteLoc(Loc)))
               orBool (isBitfieldType(T:KResult) andBool notBool hasUnionMarker(T:KResult))
               andBool (I:Int >=Int 0)
          [structural]
          
     rule <k> writeBitfield(Loc:SymLoc, _, dataList(L:KList))
               // => writeBytes(getByteOffset(Loc), dataList(L:KList))
               => writeBytes(floorLoc(Loc), dataList(L))
          ...</k>
          [structural] 
          
     syntax K ::= "calculateNewBytes-aux" "(" Int "," K "," K "," KList ")"
     rule calculateNewBytes(Len:Int, N:Int, dataList(L:KList)) 
          => calculateNewBytes-aux(Len:Int, dataList(explodeToBits(N:Int)), dataList(explodeToBits(L:KList)), .KList)
          [structural]
     
     rule reverseList(.KList) => .KList
     rule reverseList((K:K,, L:KList)) => reverseList(L:KList),, K:K
     
     syntax K ::= joinBitsToBytes(KList) [function]
     syntax K ::= "joinBitsToBytes-aux" "(" K "," K ")" [function]
     
     // fixme sNat
     rule calculateNewBytes-aux(N:Int, K:K, dataList((piece(Bit:Int, 1),, L:KList)), Result:KList) 
          => calculateNewBytes-aux(N:Int -Int 1, K:K, dataList(L:KList), (Result:KList,, piece(Bit:Int, 1))) 
          when N:Int >Int 0
          [structural]
     
     rule calculateNewBytes-aux(0, dataList((piece(N:Int, 1),, L:KList)), dataList((piece(_:Int, 1),, L':KList)), Result:KList) 
          => calculateNewBytes-aux(0, dataList(L:KList), dataList(L':KList), (Result:KList,, piece(N:Int, 1))) 
          [structural]
     rule calculateNewBytes-aux(0, dataList(.KList), dataList(L:KList), Result:KList) 
          => joinBitsToBytes((Result:KList,, L:KList)) 
          [structural]
     
     rule joinBitsToBytes(L:KList) => joinBitsToBytes-aux(dataList(L:KList), dataList(.KList))
     rule joinBitsToBytes-aux(dataList((piece(N:Int, Len:Int),, piece(M:Int, 1),, L:KList)), dataList(R:KList))
          => joinBitsToBytes-aux(dataList((piece(piece(N:Int, Len:Int) bit:: piece(M:Int, 1), Len:Int +Int 1),, L:KList)), dataList(R:KList))
          when Len:Int <Int numBitsPerByte 
          [structural]
     rule joinBitsToBytes-aux(dataList((piece(N:Int, Len:Int),, L:KList)), dataList(R:KList))
          => joinBitsToBytes-aux(dataList(L:KList), dataList((R:KList,, piece(N:Int, Len:Int))))
          when Len:Int ==Int numBitsPerByte 
          [structural]
     rule joinBitsToBytes-aux(dataList(.KList), dataList(R:KList))
          => dataList(R:KList) 
          [structural]
     
     rule explodeToBits((K:Bits,, L:KList)) => (explodeToBits(K),, explodeToBits(L))
          when L =/=KList .KList
     rule explodeToBits(piece(N:Int, Len:Int))
          => splinter(N, Len)
          when Len >Int 0
          [structural]
     rule explodeToBits(piece(N:Int, 0)) => .KList
     rule explodeToBits(.KList) => .KList
     
     syntax KList ::= splinter(Int, Int) [function] 
     syntax KList ::= "splinter-aux" "(" Int "," Int "," Int ")" [function]
     rule splinter(N:Int, Len:Int) => splinter-aux(N:Int, Len:Int, 0)
     rule splinter-aux(_:Int, Len:Int, Len:Int) => .KList
     rule splinter-aux(N:Int, Len:Int, Pos:Int)
          => splinter-aux(N:Int, Len:Int, Pos:Int +Int 1),, piece(bitRange(N:Int, Pos:Int, Pos:Int), 1)
          when Pos:Int <Int Len:Int 
          [structural]
     
     rule <k> writeBytes(Loc:SymLoc, dataList((V:K,, L:KList)))
               => writeByte(Loc, V)
               ~> writeBytes(Loc +bytes 1, dataList(L))
          ...</k>
          [structural]
     rule [write-byte-buffer]:
          <k> writeByte(loc(Base:SymBase, Offset:Int, 0), V:K) => .K ...</k>
          <buffer>... (.List => bwrite(loc(Base, Offset:Int, 0), V:K)) </buffer>
          <br/>
          <mem>... Base |-> memblock(Len:Int, Attr:Bag, _) ...</mem>
          // <object>...
          //      <basePtr> Base </basePtr>
          //      <oLength> Len:Int </oLength>
          //      <properties> Attr:Bag </properties>
          // ...</object>
          <locsWrittenTo> Locs:Bag (.Bag => BagItem(loc(Base, Offset, 0))) </locsWrittenTo>
          <notWritable> NotWritable:Map </notWritable>
          when (notBool BagItem(loc(Base, Offset, 0)) in Locs:Bag)
               andBool (Offset:Int <Int Len:Int)
               andBool (notBool (mconst in Attr:Bag))
               andBool (notBool (loc(Base, Offset, 0) in keys NotWritable:Map))
          [large, structural]
          
     rule [commit-byte]:
          // <blocked> false </blocked>
          <buffer> (bwrite(loc(Base:SymBase, Offset:Int, 0), V:K) => .List) ...</buffer>
          <mem>... Base |-> memblock(Len:Int, _, M:Map => M:Map[V / Offset]) ...</mem>
          // <object>...
          //      <basePtr> Base </basePtr>
          //      <oLength> Len:Int </oLength>
          //      <bytes> M:Map => M:Map[V / Offset] </bytes>
          // ...</object>
          when Offset <Int Len
          [structural]
     rule <k> writeBytes(_, dataList(.KList)) => .K ...</k>
          [structural] 
          
     // this general rule is useful for unknowns, abstracts, etc
     rule [splitBytes-char]:
          splitBytes(tv(N:Int, T:KResult))
               => dataList(piece(N:Int, numBitsPerByte))
          when isCharType(T:KResult)
          [structural] 
     rule [splitBytes-int]:
          splitBytes(tv(I:Int, T:KResult)) 
          // => splitIntegerBytes(I:Int, T:KResult, value(byteSizeofType(T:KResult)))
               => splitIntegerBytes(I:Int, T:KResult, bitsToBytes(value(bitSizeofType(T:KResult))))
          when hasIntegerType(T:KResult)
               andBool (I:Int >=Int 0 orBool I:Int <=Int 0)
          [structural] 
     rule [splitBytes-float]:
          splitBytes(tv(F:Float, T:KResult)) 
               => splitFloatBytes(F:Float, T:KResult, value(byteSizeofType(T:KResult)))
          when isFloatType(T:KResult)
          [structural] 
     rule [splitBytes-pointer]:
          splitBytes(tv(I:SymLoc, t(S:Set, pointerType(T:KResult)))) 
               => splitPointerBytes(I, t(S:Set, pointerType(T:KResult)), value(byteSizeofType(t(.Set, pointerType(T:KResult)))))
          [structural]
     rule [splitBytes-struct]:
          splitBytes(tv(L:KList, t(S:Set, structType(I:Id)))) 
               => splitStructBytes(dataList(L:KList), t(S:Set, structType(I:Id)), value(byteSizeofType(t(S:Set, structType(I:Id)))))
          // if isStructType(T:KResult)
          [structural]
     rule [splitBytes-union]:
          splitBytes(tv(L:KList, t(S:Set, unionType(I:Id)))) 
               => splitStructBytes(dataList(L:KList), t(S:Set, unionType(I:Id)), value(byteSizeofType(t(S:Set, unionType(I:Id)))))
          [structural] 
     
     syntax K ::= splitIntegerBytes(K, K, K) [function]
     syntax K ::= "splitIntegerBytes-aux" "(" K "," K "," K "," KList ")" [function]
     //context splitIntegerBytes(_, _, value(HOLE)) 
     rule splitIntegerBytes(I:Int, T:KResult, Len:Int) => splitIntegerBytes-aux(I:Int, T:KResult, Len:Int, .KList)
     rule splitIntegerBytes-aux(I:Int, T:KResult, Len:Int, L:KList)
               => splitIntegerBytes-aux(I:Int >>Int numBitsPerByte, T:KResult, Len:Int -Int 1, (L:KList,, lowestByte(I:Int, T:KResult)))
          when Len:Int >Int 0
          [structural]
     rule splitIntegerBytes-aux(_, _, 0, L:KList)
          => dataList(L:KList) 
          [structural]
          
     syntax K ::= splitStructBytes(K, K, K)
     syntax K ::= splitStructBytes(K, K, K, KList)
     context splitStructBytes(_, _, value(HOLE)) 
     rule splitStructBytes(dataList(L:KList), T:KResult, Len:Int) 
          => splitStructBytes(dataList(L:KList), T:KResult, Len:Int, .KList) 
          [structural]
     rule splitStructBytes(dataList((piece(N:Int, PieceLen:Int),, Rest:KList)), T:KResult, Len:Int, L:KList)
               => splitStructBytes(dataList(Rest:KList), T:KResult, Len:Int -Int 1, (L:KList,, piece(N:Int, PieceLen:Int)))
          when PieceLen:Int ==Int numBitsPerByte
               andBool Len:Int >Int 0
          [structural]
     rule splitStructBytes(_, _, 0, L:KList)
          => dataList(L:KList) 
          [structural]
          
     syntax K ::= splitPointerBytes(SymLoc, K, K)
     syntax K ::= "splitPointerBytes-aux" "(" SymLoc "," K "," K "," K "," KList ")"
     context splitPointerBytes(_, _, value(HOLE))
     rule splitPointerBytes(I:SymLoc, T:KResult, Len:Int)
          => splitPointerBytes-aux(I, T, Len, 0, .KList) 
          [structural]
     rule splitPointerBytes-aux(I:SymLoc, T:KResult, Len:Int, N:Int, L:KList)
               => splitPointerBytes-aux(I, T, Len -Int 1, N +Int 1, (L ,, piece(subObject(I, N, N), numBitsPerByte)))
          when Len:Int >Int 0
          [structural]
     rule splitPointerBytes-aux(_, _, 0, _, L:KList) 
          => dataList(L:KList)
          [structural]
          
     syntax K ::= splitFloatBytes(K, K, K)
     syntax K ::= splitFloatBytes(K, K, K, KList)
     context splitFloatBytes(_, _, value(HOLE)) 
     rule splitFloatBytes(F:Float, T:KResult, Len:Int) 
          => splitFloatBytes(F:Float, T:KResult, Len:Int -Int 1, piece(encodedFloat(F:Float), numBitsPerByte)) 
          when Len:Int >Int 0
          [structural]
     rule splitFloatBytes(F:Float, T:KResult, Len:Int, L:KList) 
          => splitFloatBytes(F:Float, T:KResult, Len:Int -Int 1, (L:KList,, piece(unknown(numBitsPerByte), numBitsPerByte))) 
          when Len:Int >Int 0
          [structural]
     rule splitFloatBytes(_, T:KResult, 0, L:KList) 
          => dataList(L:KList) 
          [structural]
          
     syntax K ::= lowestByte(Int, Type) [function]
     rule lowestByte(I:Int, T:KResult) => piece(I &Int byteMaskSet, numBitsPerByte)
          when hasIntegerType(T:KResult) 
          [structural]
     
     syntax Int ::= "byteMaskSet" [function]
     rule byteMaskSet => (2 ^Int numBitsPerByte) -Int 1
          
     rule isByteLoc(Loc:SymLoc) => getBitOffset(Loc) ==Int 0
endmodule

module DYNAMIC-C-MEMORY-MISC
     imports DYNAMIC-MEMORY-INCLUDE 

     // used by calloc
     rule <k> zeroBlock(loc(Base:SymBase, 0, 0)) => .K ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _ => .Map[piece(0, numBitsPerByte) / 0 to Len]) ...</mem>
          // <object>...
          //      <basePtr> Base </basePtr>
          //      <oLength> Len:Int </oLength>
          //      <bytes> _ => .Map[piece(0, numBitsPerByte) / 0 to Len] </bytes>
          // ...</object>
          [structural]
          
     rule <k> sizeofLocation(loc(Base:SymBase, _:Int, _:Int)) => tv(Len:Int, cfg:sizeut) ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          // <object>...
          //      <basePtr> Base </basePtr>
          //      <oLength> Len:Int </oLength>
          // ...</object>
          [structural]
          
     rule [delete-sized-block]:
          <k> deleteSizedBlock(loc(Base:SymBase, _:Int, _:Int), Len:Int) => .K ...</k>
          <mem>... Base |-> memblock(Len, _, _) => .Map ...</mem>
          // (<object>...
          //      <basePtr> Base </basePtr>
          //      <oLength> Len:Int </oLength>
          // ...</object> => .Bag)
          <buffer> .List </buffer> // fixme could make this more relaxed by checking of block is in buffer, not just empty
          [structural] 
     
     rule [delete-block]:
          <k> deleteBlock(loc(Base:SymBase, _:Int, _:Int)) => .K ...</k>
          <mem>... Base |-> memblock(_, _, _) => .Map ...</mem>
          // (<object>...
          //      <basePtr> Base </basePtr>
          // ...</object> => .Bag)
          <buffer> .List </buffer>
          [structural] 
     
     // c99 6.5:2 If a side effect on a scalar object is unsequenced relative
     // to either a different side effect on the same scalar object or a value
     // computation using the value of the same scalar object, the behavior is
     // undefined. If there are multiple allowable orderings of the
     // subexpressions of an expression, the behavior is undefined if such an
     // unsequenced side effect occurs in any of the orderings
     //
     // i take this to mean that if i write to a location twice or read from a
     // location after being written to, then it is a problem
          
     rule [alloc-string]:
          <k> allocString(Loc:SymLoc, S:String)
               => allocateType(Loc, t(.Set, arrayType(t(.Set, char), lengthString(S:String))))
               ~> writeString(Loc, S:String)
               ~> makeUnwritable(Loc)
          ...</k>
          [structural]
     rule [alloc-wstring]:
          <k> allocWString(Loc:SymLoc, S:KList)
               => allocateType(Loc, t(.Set, arrayType(cfg:wcharut, 4 *Int lengthKList S:KList)))
               ~> writeWString(Loc, S:KList)
               ~> makeUnwritable(Loc)
          ...</k>
          [structural] 
     
     rule [makeUnwritable-var]:
          <k> makeUnwritableVar(X:Id) => makeUnwritable(Loc)  ...</k>
          <env>... X:Id |-> Loc:SymLoc ...</ env>
          [structural]
     // fixme shouldn't need both of these
     // fixme could do better with bitfields
     rule [makeUnwritable-subobject]:
          <k> makeUnwritableSubObject(lv(loc(Base:SymBase, Offset:Int, _), _)) => . ...</k>
          <notWritable> M:Map => M:Map[1 / loc(Base, Offset:Int, 0)] </notWritable>
          [structural]
     rule [makeUnwritable]:
          <k> makeUnwritable(loc(Base:SymBase, 0, 0)) => .K ...</k>
          <mem>... Base |-> memblock(_, (_ .Bag => mconst), _) ...</mem>
          // <object>...
          //      <basePtr> Base </basePtr>
          //      <properties>... .Bag => mconst ...</properties>
          // ...</object>
          [structural]

     syntax K ::= "checkValidLoc-aux" "(" SymLoc ")"
     
     rule <k> checkValidLoc(Loc:SymLoc) => checkValidLoc-aux(ceilingLoc(Loc)) ...</k>
          [structural]
     rule <k> checkDerefLoc(Loc:SymLoc) => checkValidLoc(Loc) ...</k>
          when Loc =/=K NullPointer
          [structural]
     
     rule [check-valid-loc-null]:
          <k> checkValidLoc-aux(NullPointer) => .K ...</k>
          [structural]
     // fixme could additionally use the type to check whether that type is
     // valid for that pointer
     rule [check-valid-loc]:
          <k> checkValidLoc-aux(loc(sb(N:Int, PtrThreadId:Int), Offset:Int, 0)) => .K ...</k>
          //<br/>
          <mem>... sb(N, PtrThreadId) |-> memblock(Len:Int, _, _) ...</mem>
          // <object>...
          //      <basePtr> sb(N, PtrThreadId) </basePtr>
          //      <oLength> Len:Int </oLength>
          // ...</object>
          <threadId> MyThreadId:Int </threadId>
          when (PtrThreadId:Int ==Int MyThreadId:Int 
               orBool (PtrThreadId:Int ==Int 0)
               orBool (PtrThreadId:Int ==K allocatedDuration)
               ) // my thread, global memory, or allocated (malloced) memory
               andBool (Offset:Int <=Int Len:Int) // we're allowed to address one past
          [structural]
endmodule

module DYNAMIC-C-MEMORY
     imports DYNAMIC-MEMORY-INCLUDE 
     imports DYNAMIC-C-MEMORY-MISC 
     imports DYNAMIC-SEMANTICS-WRITING 
     imports DYNAMIC-SEMANTICS-READING 
endmodule
