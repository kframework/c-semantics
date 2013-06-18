require "dynamic-c-semantics.k"

module DYNAMIC-MEMORY-INCLUDE
     imports DYNAMIC-INCLUDE 
     
     // returns the bytes in the order in which they are in memory
     // loc, size in bytes
     syntax K ::= "extractBytesFromMem" "(" SymLoc "," Int ")"
     syntax Bits ::= "encodedFloat" "(" Float ")"
     syntax KList ::= explodeToBits(KList) [function]
     syntax KList ::= reverseList(KList) [function]
     syntax ListItem ::= "bwrite" "(" SymLoc "," K ")"
     syntax Set ::= locations(List) [function]
     syntax K ::= "read-aux" "(" SymLoc "," K "," K ")" [klabel('read-aux)]

     // object, start piece, end piece
     syntax Bits ::= "subObject" "(" Ptr "," K "," K ")"
     
     // fixme would be better to keep canonical
     syntax Int ::= getBitOffset(SymLoc) [function]
     rule getBitOffset(loc(_, _, M:Int)) => M %Int numBitsPerByte
     syntax Int ::= getByteOffset(SymLoc) [function]
     rule getByteOffset(loc(_, M:Int, N:Int)) => M +Int N /Int numBitsPerByte
     
     rule [locations-none]: locations(.List) => .Set
     rule [locations-some]: locations(bwrite(Loc:SymLoc, _) L:List)
          => SetItem(Loc) locations(L:List)
endmodule

module DYNAMIC-SEMANTICS-READING
     imports DYNAMIC-MEMORY-INCLUDE 
     
     // loc, size in bits
     syntax K ::= "extractBitsFromMem" "(" SymLoc "," Int ")"
     syntax K ::= "extractByteFromMem" "(" SymLoc ")" 
     
     // datalist, offset in bits into list, number of bits to extract, accumulator
     syntax K ::= "extractBitsFromList-aux" "(" K "," Int "," Int "," KList ")"
     rule extractBitsFromList(dataList(L:KList), N:Int, M:Int) 
          => extractBitsFromList-aux(dataList(explodeToBits(L:KList)), N:Int, M:Int, .KList)
          [structural]
     // fixme snat
     rule extractBitsFromList-aux(dataList((piece(_, 1),, L:KList)), Offset:Int, NumBits:Int, .KList)
          => extractBitsFromList-aux(dataList(L:KList), Offset:Int -Int 1, NumBits:Int, .KList)
          when Offset:Int >Int 0
          [structural] 
     rule extractBitsFromList-aux(dataList((piece(N:Bits, 1),, L:KList)), 0, NumBits:Int, Done:KList)
          => extractBitsFromList-aux(dataList(L:KList), 0, NumBits:Int -Int 1, (Done:KList,, piece(N, 1)))
          when NumBits >Int 0
          [structural] 
     
     rule extractBitsFromList-aux(_, 0, 0, Done:KList) => dataList(Done:KList)
          [structural] 
     
     context readActual(_, _, value(HOLE))
     rule read(Loc:SymLoc, T:KResult) => read-aux(Loc, T:KResult, value(bitSizeofType(T:KResult))) 
          when notBool(isFunctionType(T:KResult))
          [structural]
     
     syntax K ::= "readActual" "(" SymLoc "," K "," K ")" [klabel('readActual)]
     
     /*@ These rules figure out whether the read should be structural or
     computational, depending on what is being read */
     rule [read-thread-local]:
          <k> ('read-aux => 'readActual)(loc(_ @ Th:Int, _:Int, _:Int),, _,, _) ...</k>
          <threadId> Th </threadId>
          [structural, ndlocal]
     rule [read-shared]: // read global or shared data
          ('read-aux => 'readActual)(loc(_ @ 0, _:Int, _:Int),, _,, _)
          [computational, ndlocal]
     rule [read-allocated]: // read data of "allocated" duration
          ('read-aux => 'readActual)(loc(_ @ allocatedDuration, _:Int, _:Int),, _,, _)
          [computational, ndlocal]
     
     rule [read]:
          readActual(Loc:SymLoc, T:KResult, BitSize:Int)
          => concretize(T:KResult, extractBytesFromMem(Loc, bitsToBytes(BitSize:Int)))
          when notBool isBitfieldType(T)
          [structural]
     rule [read-bitfield]:
          readActual(Loc:SymLoc, T:KResult, BitSize:Int)
          => concretize(T:KResult, fillToBytes(extractBitsFromMem(Loc, BitSize:Int))) 
          when isBitfieldType(T)
          [structural]
     
     syntax K ::= "joinIntegerBytes" "(" Type "," KList ")"
     rule concretize(T:KResult, dataList(L:KList)) 
          => joinIntegerBytes(T:KResult, L:KList) 
          when hasIntegerType(T:KResult) 
               andBool notBool isBitfieldType(T:KResult) 
          [structural]
     rule concretize(t(S:Set, bitfieldType(T:KResult, Len:Int)), dataList(L:KList)) 
          => joinIntegerBytes(t(S:Set, bitfieldType(T:KResult, Len:Int)), reverseList(L:KList)) 
          [structural]
          
     // FIXME very unsafe, not checking size of list or its contents
     rule concretize(T:KResult, dataList((piece(encodedFloat(F:Float), Len:Int),, _))) 
          => tv(F:Float, T:KResult)
          when isFloatType(T:KResult)
               andBool (Len:Int ==Int numBitsPerByte)
          [structural]

     syntax K ::= "joinPointerBytes" "(" Type "," KList ")"
     syntax K ::= "joinPointerBytes-aux" "(" Type "," KList "," K ")"
     // fixme should also check sizes are appropriate
     rule concretize(T:Type, dataList(L:KList)) 
          => joinPointerBytes(T, L)
          when isPointerType(T)
          [structural]
     rule joinPointerBytes(T:Type, (piece(N:Bits, Len:Int),, L:KList))
          => joinPointerBytes-aux(T, L, N)
          when Len:Int ==Int numBitsPerByte
          [structural]
     // fixme sNat
     rule joinPointerBytes-aux(T:Type, (piece(subObject(N:Ptr, SNatEnd:Int, SNatEnd:Int), Len:Int),, L:KList), subObject(N, 0, End:Int))
          => joinPointerBytes-aux(T, L, subObject(N, 0, End +Int 1))
          when (Len ==Int numBitsPerByte)
               andBool (SNatEnd ==Int End +Int 1)
          [structural]
     rule joinPointerBytes-aux(T:KResult, .KList, subObject(N:SymLoc, 0, _:Int))
          => checkValidLoc(N) ~> tv(N, T:KResult)
          [structural]

     rule concretize(t(S:Set, structType(I:Id)), dataList(L:KList)) 
          => tv(L:KList, t(S:Set, structType(I:Id))) 
          [structural]
     rule concretize(t(S:Set, unionType(I:Id)), dataList(L:KList)) 
          => tv(L:KList, t(S:Set, unionType(I:Id)))
          [structural]

     // FIXME assuming bytes?
     syntax K ::= "joinIntegerBytes-aux" "(" Type "," KList "," K ")"
     rule [joinIntegerBytes-start]:
          joinIntegerBytes(T:Type, L:KList) 
          => joinIntegerBytes-aux(T, L, piece(0, 0)) 
          [structural]
     
     // fixme may want to consider restricting further, or loosening
     rule [joinIntegerBytes-unknown-char]:
          joinIntegerBytes-aux(T:Type, piece(unknown(Len:Int), Len:Int), piece(0, 0))
          => tv(piece(unknown(Len), Len), T)
          when isCharType(T)
          [structural]
     
     rule [joinIntegerBytes-step]:
          joinIntegerBytes-aux(T:Type, (L:KList,, piece(N:Int, Len:Int)), piece(N':Int, Len':Int))
          => joinIntegerBytes-aux(T, L, piece(piece(N', Len') bit:: piece(N, Len), Len +Int Len'))
          when N' >=Int 0
          [structural]
     rule [joinIntegerBytes-done]:
          joinIntegerBytes-aux(T:Type, .KList, piece(N:Int, Len:Int)) 
          => interpret(T, piece(N, Len)) 
          when N >=Int 0
          [structural]
     
     rule floorLoc(loc(Base:SymBase, Offset:Int, BitOffset:Int))
          => loc(Base, Offset:Int, 0)
          when BitOffset <Int numBitsPerByte
     
     rule [ceilingLoc-null]: ceilingLoc(NullPointer) => NullPointer

     rule [ceilingLoc]:
          ceilingLoc(loc(N:SymBase, R:Int, M:Int))
          => loc(N, (M /Int numBitsPerByte) +Int R, 0)

     rule extractBitsFromMem(Loc:SymLoc, Size:Int)
          => extractBitsFromList(
               extractBytesFromMem(
                    floorLoc(Loc), bitsToBytes(Size +Int getBitOffset(Loc))), 
               getBitOffset(Loc), Size)
          [structural] 
     
     // loc, size in bytes, aux list
     syntax K ::= "extractBytesFromMem-aux" "(" SymLoc "," Int "," KList ")"
     
     rule extractBytesFromMem(Loc:SymLoc, Size:Int) 
          => extractBytesFromMem-aux(Loc, Size, .KList) 
          [structural] 
          
     // fixme sNat
     rule extractBytesFromMem-aux(Loc:SymLoc, Size:Int, Aux:KList)
          => extractByteFromMem(Loc)
          ~> extractBytesFromMem-aux(Loc +bytes 1, Size -Int 1, Aux)
          when Size:Int >Int 0
          [structural]
     rule (tv(V:KList, T:KResult) => .K)
               ~> extractBytesFromMem-aux(_, _, 
                    (Aux:KList => (Aux:KList,, tv(V:KList, T:KResult))))
          [structural]        
     
     syntax KList ::= values(KList) [function]
     rule values((tv(K:K, _),, L:KList)) => (K:K,, values(L:KList))
     rule values(.KList) => .KList
     rule extractBytesFromMem-aux(_, 0, Aux:KList) 
          => dataList(values(Aux:KList)) 
          [structural] 
     
     // FIXME make sure it's a byte
     
     rule [read-byte-fast]:
          <k> extractByteFromMem(loc(Base:SymBase, Offset:Int, 0))
               => assert(notBool (BagItem(loc(Base, Offset:Int, 0)) in Locs:Bag), 3)
                    ~> assert(Offset:Int <Int Len:Int, 2)
                    ~> tv(V:K, t(.Set, no-type))
          ...</k>
          <br/>
          <mem>... 
               Base |-> memblock(Len:Int, _, (_ Offset:Int |-> V:K)) 
          ...</mem>
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
          <mem>... 
               Base |-> memblock(Len:Int, _, (_ Offset:Int |-> V:K)) 
          ...</mem>
          <locsWrittenTo> Locs:Bag </locsWrittenTo>
          <buffer> Mem:List </buffer>
          when notBool loc(Base, Offset:Int, 0) in locations(Mem:List)
          [large, structural]
          
     rule [read-byte-lazy]:
          <k> extractByteFromMem(loc(Base:SymBase, Offset:Int, 0)) 
               => assert(Offset:Int <Int Len:Int, 2)
                    ~> tv(piece(unknown(numBitsPerByte), numBitsPerByte), 
                         t(.Set, no-type))
          ...</k>
          <br/>
          <mem>... 
               Base |-> memblock(Len:Int, _, 
                    M:Map => M:Map[
                         piece(unknown(numBitsPerByte), numBitsPerByte) 
                         / Offset]) 
          ...</mem>
          <buffer> Mem:List </buffer>
          when notBool loc(Base, Offset:Int, 0) in locations(Mem:List)
               andBool notBool Offset:Int in keys M:Map
          [large, structural]
          
          // TODO(chathhorn): perf, elided
//       rule [read-byte-buffer]:
//            <k> extractByteFromMem(Loc:SymLoc) 
//                 => assert(notBool BagItem(Loc) in Locs:Bag, 3)
//                 ~> tv(V:K, t(.Set, no-type))
//            ...</k>
//            <locsWrittenTo> Locs:Bag </locsWrittenTo>
//            <buffer>... bwrite(Loc, V:K) Mem:List </buffer>
//            when notBool Loc in locations(Mem:List)
//            [structural]
//            // for speed in interpretation; forces local buffer to be flushed
//            // before a read
//            //[interpRule] 

endmodule

module DYNAMIC-SEMANTICS-WRITING
     imports DYNAMIC-MEMORY-INCLUDE 
     context alloc(_, value(HOLE)) 

     rule allocateType(Loc:SymLoc, T:KResult) 
          => alloc(Loc, value(byteSizeofType(T))) 
          [structural]
     rule [allocateTypeIfAbsent-absent]:
          <k> 
               allocateTypeIfAbsent(Loc:SymLoc, T:KResult) 
               => alloc(Loc, value(byteSizeofType(T:KResult))) 
          ...</k>
          <mem> M:Map </mem>
          when notBool (SetItem(base(Loc)) in (keys M))
          [structural] 
     rule [allocateTypeIfAbsent-present]:
          <k> 
               allocateTypeIfAbsent(loc(Base:SymBase, 0, 0), _:KResult) => .K 
          ...</k>
          <mem>... Base |-> memblock(_, _, _) ...</mem>
          [structural]

     rule [alloc-lazy]:
          <k> alloc(loc(Base:SymBase, 0, 0), Len:Int) => .K ...</k>
          <mem>... .Map => Base |-> memblock(Len, .Bag, .Map) ...</mem>
          [structural]
     
     syntax K ::= "realloc-aux" "(" K "," K "," K "," K "," K ")"
     rule [realloc-start]:
          <k> 
               realloc(Old:K, New:K, OldLen:Int, NewLen:Int)
               => alloc(New:K, NewLen:Int)
                    ~> realloc-aux(minInt(OldLen:Int, NewLen:Int),
                         Old:K, New:K, OldLen:Int, NewLen:Int)
          ...</k>
          [structural]
          
     rule [realloc-found]:
          <k> 
               realloc-aux((SNatN:Int => SNatN:Int -Int 1), 
                    loc(OldBase:SymBase, 0, 0), 
                    loc(NewBase:SymBase, 0, 0), _, _)
          ...</k>
          <mem>... 
               OldBase |-> memblock(_, _, (_ N:Int |-> K:K))
               NewBase |-> memblock(_, _, (_ (.Map => SNatN:Int -Int 1 |-> K:K)))
          ...</mem>
          when (N ==Int SNatN -Int 1)
               andBool (SNatN >Int 0)
          [structural]   
          
     // fixme sNat
     rule [realloc-unfound]:
          <k> 
               realloc-aux((SNatN:Int => SNatN -Int 1), 
                    loc(OldBase:SymBase, 0, 0), loc(_:SymBase, 0, 0), _, _)
          ...</k>
          <mem>... OldBase |-> memblock(_, _, M:Map) ...</mem>
          when (notBool SNatN:Int -Int 1 in keys M:Map)
               andBool (SNatN >Int 0)
          [structural]
     rule [realloc-0]:
          realloc-aux(0, loc(OldBase:SymBase, 0, 0), _, OldLen:Int, _)
          => deleteSizedBlock(loc(OldBase, 0, 0), OldLen:Int) 
          [structural]   
          
     syntax K ::= "writeBytes" "(" SymLoc "," K ")" [strict(2)] 
     syntax K ::= "writeBitfield" "(" SymLoc "," Type "," K ")" [strict(3)] 
     syntax Bool ::= isByteLoc(SymLoc) [function]
     syntax K ::= splitBytes(Value) [function]
     syntax K ::= calculateNewBytes(Int, K, K)
          [latex(\terminal{calcNewBytes(}{#1}, {#2}, {#3}\terminal{)}), strict(3)] 
     
     syntax K ::= "write-aux" "(" K "," Value "," K ")" [strict(2)]
     rule write(lv(Dest:SymLoc, T':Type), tv(V:KList, T:KResult)) 
          => write-aux(Dest, tv(V, T), value(bitSizeofType(T))) 
          when notBool isConstType(T')
          [structural]
     context write-aux(_, _, value(HOLE))
     
     syntax K ::= "write-specific" "(" SymLoc "," Value "," Int ")"
     
     rule [write-thread-local]:
          <k> 
               write-aux(
                    loc(N:Int @ Th:Int, Offset:Int, BitOffset:Int), 
                    tv(L:KList, T:KResult), BitSize:Int)
               => write-specific(
                    loc(N @ Th, Offset:Int, BitOffset:Int), 
                    tv(L:KList, T:KResult), BitSize:Int)
          ...</k>
          <threadId> Th </threadId>
          [structural, ndlocal]
     // write global or shared data
     rule [write]:
          write-aux(
               loc(N:Int @ 0, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:KResult), BitSize:Int)
          => write-specific(
               loc(N @ 0, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:KResult), BitSize:Int)
          [computational, ndlocal]
     // write data of "allocated" duration
     rule [write-allocated]:
          write-aux(
               loc(N:Int @ allocatedDuration, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:KResult), BitSize:Int)
          => write-specific(
               loc(N @ allocatedDuration, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:KResult), BitSize:Int)
          [computational, ndlocal]
     
     rule [write-normal]:
          write-specific(Loc:SymLoc, tv(V:K, T:KResult), BitSize:Int)
          => writeBytes(Loc, splitBytes(tv(V, T)))
          when (BitSize %Int numBitsPerByte ==Int 0)
               andBool isByteLoc(Loc)
               andBool (notBool isBitfieldType(T))
               andBool (notBool hasUnionMarker(T))
          [structural]
     rule [write-normal-union-field]:
          (. => makeUnknown(Loc, t(.Set, unionType(S))))
          ~> write-specific(Loc:SymLoc, 
               tv(_, t((SetItem(fromUnion(S:Id)) => .Set) _, _)), _:Int)
          when isByteLoc(Loc)
          [structural]
          
     syntax K ::= "makeUnknown" "(" SymLoc "," Type ")"
     syntax K ::= "makeUnknown-aux" "(" SymLoc "," Type "," K ")"
     context makeUnknown-aux(_, _, value(HOLE))
     
     rule makeUnknown(Loc:SymLoc, T:KResult)
          => makeUnknown-aux(Loc, T, value(byteSizeofType(T))) 
          [structural]
     rule <k>
               makeUnknown-aux(loc(Base:SymBase, Offset:Int, 0), _, Len':Int)
               => .
          ...</k>
          <br/>
          <mem>... 
               Base |-> memblock(Len:Int, _, 
               M:Map => M:Map[
                    piece(unknown(numBitsPerByte), numBitsPerByte) 
                    / Offset to (Offset +Int Len')]) 
          ...</mem>
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
          write-specific(Loc:SymLoc, 
               tv((V:K,, V':K,, L:KList), T:KResult), BitSize:Int)
          => writeBytes(Loc, dataList((V,, V',, L)))
          when (BitSize:Int %Int numBitsPerByte ==Int 0)
               andBool isByteLoc(Loc)
               andBool (notBool isBitfieldType(T:KResult))
          [structural]
          
     syntax Value ::= justBits(Int, Type) [function]
     syntax Value ::= "justBits-aux" "(" Int "," Type ")" [function]
     rule justBits(I:Int, _) => I
          when I >=Int 0 
          
     rule justBits(I:Int, T:Type) => justBits-aux(I, T)
          when I <Int 0 
     rule justBits-aux(I:Int, T:Type)
          => justBits-aux((I +Int max(T) +Int 1), T)
          when I <Int 0 
     // fixme sNat
     rule justBits-aux(N:Int, t(_, bitfieldType(_:Type, Len:Int))) 
          => N +Int (1 <<Int (Len -Int 1))
          when Len >Int 0 andBool N >=Int 0
     
     rule [massage-bitfield]:
          write-specific(Loc:SymLoc, tv(I:Int, T:Type), BitSize:Int)
          => write-specific(Loc, tv(justBits(I, T), T), BitSize)
          when (BitSize %Int numBitsPerByte =/=Int 0
               orBool notBool(isByteLoc(Loc))
               orBool isBitfieldType(T))
               andBool (I <Int 0)
          [structural]
     
     rule [write-bitfield]:
          write-specific(Loc:SymLoc, tv(I:Int, T:KResult), BitSize:Int)
          => writeBitfield(
               Loc
               , T:KResult
               , calculateNewBytes(
                    getBitOffset(Loc)
                    , piece(I, BitSize:Int)
                    , extractBytesFromMem(floorLoc(Loc), 
                         bitsToBytes(BitSize:Int +Int getBitOffset(Loc))
                    )
               )
          )
          when (BitSize:Int %Int numBitsPerByte =/=Int 0)
               orBool (notBool(isByteLoc(Loc)))
               orBool (isBitfieldType(T:KResult) 
                    andBool notBool hasUnionMarker(T:KResult))
               andBool (I:Int >=Int 0)
          [structural]
          
     rule writeBitfield(Loc:SymLoc, _, dataList(L:KList))
          => writeBytes(floorLoc(Loc), dataList(L))
          [structural] 
          
     syntax K ::= "calculateNewBytes-aux" "(" Int "," K "," K "," KList ")"
     rule calculateNewBytes(Len:Int, N:Bits, dataList(L:KList)) 
          => calculateNewBytes-aux(Len:Int, dataList(explodeToBits(N)),
               dataList(explodeToBits(L:KList)), .KList)
          [structural]
     
     rule reverseList(.KList) => .KList
     rule reverseList((K:K,, L:KList)) => reverseList(L:KList),, K:K
     
     syntax K ::= joinBitsToBytes(KList) [function]
     syntax K ::= "joinBitsToBytes-aux" "(" K "," K ")" [function]
     
     // fixme sNat
     rule calculateNewBytes-aux(N:Int, K:K, 
               dataList((piece(Bit:Bits, 1),, L:KList)), Result:KList) 
          => calculateNewBytes-aux(N -Int 1, K, 
               dataList(L), (Result,, piece(Bit, 1))) 
          when N >Int 0
          [structural]
     
     rule calculateNewBytes-aux(0, dataList((piece(N:Bits, 1),, L:KList)), 
               dataList((piece(_, 1),, L':KList)), Result:KList) 
          => calculateNewBytes-aux(0, dataList(L), 
               dataList(L'), (Result,, piece(N, 1))) 
          [structural]
     rule calculateNewBytes-aux(0, dataList(.KList), 
               dataList(L:KList), Result:KList) 
          => joinBitsToBytes((Result:KList,, L:KList)) 
          [structural]
     
     rule joinBitsToBytes(L:KList)
          => joinBitsToBytes-aux(dataList(L:KList), dataList(.KList))
     rule joinBitsToBytes-aux(
               dataList((piece(N:Bits, Len:Int),, piece(M:Bits, 1),, L:KList)),
               dataList(R:KList))
          => joinBitsToBytes-aux(
               dataList((piece(piece(N, Len) bit:: piece(M, 1), Len +Int 1),, L)), 
               dataList(R))
          when Len <Int numBitsPerByte 
          [structural]
     rule joinBitsToBytes-aux(
               dataList((piece(N:Bits, Len:Int),, L:KList)), dataList(R:KList))
          => joinBitsToBytes-aux(
               dataList(L), dataList((R,, piece(N, Len))))
          when Len ==Int numBitsPerByte 
          [structural]
     rule joinBitsToBytes-aux(dataList(.KList), dataList(R:KList))
          => dataList(R) 
          [structural]
     
     rule explodeToBits((K:Bits,, L:KList))
          => (explodeToBits(K),, explodeToBits(L))
          when L =/=KList .KList
     rule explodeToBits(piece(N:Bits, Len:Int)) => splinter(N, Len)
          when Len >Int 0
          [structural]
     rule explodeToBits(piece(_:Bits, 0)) => .KList
     rule explodeToBits(.KList) => .KList
     
     syntax KList ::= splinter(Bits, Int) [function] 
     syntax KList ::= "splinter-aux" "(" Bits "," Int "," Int ")" [function]
     rule splinter(N:Bits, Len:Int) => splinter-aux(N, Len, 0)
     rule splinter-aux(_, Len:Int, Len:Int) => .KList
     rule splinter-aux(N:Bits, Len:Int, Pos:Int)
          => splinter-aux(N, Len, Pos +Int 1),, piece(bitRange(N, Pos, Pos), 1)
          when Pos <Int Len
     
     rule <k> writeBytes(Loc:SymLoc, dataList((V:K,, L:KList)))
               => writeByte(Loc, V)
               ~> writeBytes(Loc +bytes 1, dataList(L))
          ...</k>
          [structural]
     rule [write-byte-buffer]:
          <k> writeByte(loc(Base:SymBase, Offset:Int, 0), V:K) => .K ...</k>
          <buffer>...
               (.List => bwrite(loc(Base, Offset:Int, 0), V:K))
          </buffer>
          <br/>
          <mem>... Base |-> memblock(Len:Int, Attr:Bag, _) ...</mem>
          <locsWrittenTo>
               Locs:Bag (.Bag => BagItem(loc(Base, Offset, 0)))
          </locsWrittenTo>
          <notWritable> NotWritable:Map </notWritable>
          when (notBool BagItem(loc(Base, Offset, 0)) in Locs:Bag)
               andBool (Offset:Int <Int Len:Int)
               andBool (notBool (mconst in Attr:Bag))
               andBool (notBool (loc(Base, Offset, 0) in keys NotWritable:Map))
          [large, structural]
          
     rule [commit-byte]:
          <buffer>
               (bwrite(loc(Base:SymBase, Offset:Int, 0), V:K) => .List)
          ...</buffer>
          <mem>...
               Base |-> memblock(Len:Int, _, M:Map => M:Map[V / Offset])
          ...</mem>
          when Offset <Int Len
          [structural]
     rule <k> writeBytes(_, dataList(.KList)) => .K ...</k>
          [structural] 
          
     // this general rule is useful for unknowns, abstracts, etc
     rule [splitBytes-char]:
          splitBytes(tv(N:Bits, T:Type))
          => dataList(piece(N, numBitsPerByte))
          when isCharType(T) andBool (isInt(N) ==K false)
          [structural] 
     rule [splitBytes-int]:
          splitBytes(tv(I:Int, T:Type)) 
          => splitIntegerBytes(I, T, bitsToBytes(value(bitSizeofType(T))))
          when hasIntegerType(T)
          [structural] 
     rule [splitBytes-float]:
          splitBytes(tv(F:Float, T:Type)) 
          => splitFloatBytes(F, T, value(byteSizeofType(T)))
          when isFloatType(T)
          [structural] 
     rule [splitBytes-pointer]:
          splitBytes(tv(I:Ptr, t(S:Set, pointerType(T:KResult)))) 
          => splitPointerBytes(I, t(S, pointerType(T)), 
               value(byteSizeofType(t(.Set, pointerType(T)))))
          [structural]
     rule [splitBytes-struct]:
          splitBytes(tv(L:KList, t(S:Set, structType(I:Id)))) 
          => splitStructBytes(dataList(L), t(S, structType(I)), 
               value(byteSizeofType(t(S, structType(I)))))
          [structural]
     rule [splitBytes-union]:
          splitBytes(tv(L:KList, t(S:Set, unionType(I:Id)))) 
          => splitStructBytes(dataList(L), t(S, unionType(I)), 
               value(byteSizeofType(t(S, unionType(I)))))
          [structural] 
     
     syntax K ::= splitIntegerBytes(Int, Type, Int) [function]
     syntax K ::= "splitIntegerBytes-aux" "(" Int "," Type "," Int "," KList ")"
          [function]
     rule splitIntegerBytes(I:Int, T:Type, Len:Int) 
          => splitIntegerBytes-aux(I, T, Len, .KList)
     rule splitIntegerBytes-aux(I:Int, T:Type, Len:Int, L:KList)
          => splitIntegerBytes-aux(I >>Int numBitsPerByte, T, Len -Int 1, 
               (L,, lowestByte(I, T)))
          when Len >Int 0
     rule splitIntegerBytes-aux(_, _, 0, L:KList)
          => dataList(L) 
          
     syntax K ::= splitStructBytes(K, K, K)
     syntax K ::= splitStructBytes(K, K, K, KList)
     context splitStructBytes(_, _, value(HOLE)) 
     rule splitStructBytes(dataList(L:KList), T:KResult, Len:Int) 
          => splitStructBytes(dataList(L:KList), T:KResult, Len:Int, .KList) 
          [structural, anywhere]
     rule splitStructBytes(dataList((piece(N:Int, PieceLen:Int),, Rest:KList)),
               T:KResult, Len:Int, L:KList)
          => splitStructBytes(dataList(Rest:KList), T:KResult, Len:Int -Int 1,
               (L:KList,, piece(N:Int, PieceLen:Int)))
          when PieceLen:Int ==Int numBitsPerByte
               andBool Len:Int >Int 0
          [structural, anywhere]
     rule splitStructBytes(_, _, 0, L:KList)
          => dataList(L:KList) 
          [structural, anywhere]
          
     syntax K ::= splitPointerBytes(Ptr, K, K)
     syntax K ::= "splitPointerBytes-aux" "(" Ptr "," K "," K "," K "," KList ")"
     context splitPointerBytes(_, _, value(HOLE))
     rule splitPointerBytes(I:Ptr, T:KResult, Len:Int)
          => splitPointerBytes-aux(I, T, Len, 0, .KList) 
          [structural, anywhere]
     rule splitPointerBytes-aux(I:Ptr, T:KResult, Len:Int, N:Int, L:KList)
          => splitPointerBytes-aux(I, T, Len -Int 1, N +Int 1,
               (L,, piece(subObject(I, N, N), numBitsPerByte)))
          when Len >Int 0
          [structural, anywhere]
     rule splitPointerBytes-aux(_, _, 0, _, L:KList) 
          => dataList(L:KList)
          [structural, anywhere]
          
     syntax K ::= splitFloatBytes(K, K, K)
     syntax K ::= splitFloatBytes(K, K, K, KList)
     context splitFloatBytes(_, _, value(HOLE)) 
     rule splitFloatBytes(F:Float, T:KResult, Len:Int) 
          => splitFloatBytes(F:Float, T:KResult, Len:Int -Int 1,
               piece(encodedFloat(F:Float), numBitsPerByte)) 
          when Len:Int >Int 0
          [structural, anywhere]
     rule splitFloatBytes(F:Float, T:KResult, Len:Int, L:KList) 
          => splitFloatBytes(F:Float, T:KResult, Len:Int -Int 1,
               (L:KList,, piece(unknown(numBitsPerByte), numBitsPerByte))) 
          when Len:Int >Int 0
          [structural, anywhere]
     rule splitFloatBytes(_, _:KResult, 0, L:KList) 
          => dataList(L:KList) 
          [structural, anywhere]
          
     syntax Bits ::= lowestByte(Int, Type) [function]
     rule lowestByte(I:Int, T:Type) => piece(I &Int byteMaskSet, numBitsPerByte)
          when hasIntegerType(T) 
          [structural]
     
     syntax Int ::= "byteMaskSet" [function]
     rule byteMaskSet => (2 ^Int numBitsPerByte) -Int 1
          
     rule isByteLoc(Loc:SymLoc) => getBitOffset(Loc) ==Int 0
endmodule

module DYNAMIC-C-MEMORY-MISC
     imports DYNAMIC-MEMORY-INCLUDE 

     // used by calloc
     rule <k> zeroBlock(loc(Base:SymBase, 0, 0)) => . ...</k>
          <mem>...
               Base |-> memblock(Len:Int, _, 
                    _ => Map((0 to Len) |-> piece(0, numBitsPerByte)))
          ...</mem>
          [structural]
          
     rule <k> 
               sizeofLocation(loc(Base:SymBase, _:Int, _:Int)) 
               => tv(Len:Int, cfg:sizeut)
          ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          [structural]
          
     rule [delete-sized-block]:
          <k>
               deleteSizedBlock(loc(Base:SymBase, _:Int, _:Int), Len:Int) => . 
          ...</k>
          <mem>... Base |-> memblock(Len, _, _) => .Map ...</mem>
          // fixme could make this more relaxed by checking of block is in
          // buffer, not just empty
          <buffer> .List </buffer>
          [structural] 
     
     rule [delete-block]:
          <k> deleteBlock(loc(Base:SymBase, _:Int, _:Int)) => .K ...</k>
          <mem>... Base |-> memblock(_, _, _) => .Map ...</mem>
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
          allocString(Loc:SymLoc, S:String)
          => allocateType(Loc, 
               t(.Set, arrayType(t(.Set, char), lengthString(S:String))))
               ~> writeString(Loc, S:String) ~> makeUnwritable(Loc)
          [structural]
     rule [alloc-wstring]:
          allocWString(Loc:SymLoc, S:KList)
          => allocateType(Loc, 
               t(.Set, arrayType(cfg:wcharut, 4 *Int lengthKList S:KList)))
               ~> writeWString(Loc, S:KList) ~> makeUnwritable(Loc)
          [structural] 
     
     rule [makeUnwritable-var]:
          <k> makeUnwritableVar(X:Id) => makeUnwritable(Loc)  ...</k>
          <env>... X:Id |-> Loc:SymLoc ...</ env>
          [structural]
     // fixme shouldn't need both of these
     // fixme could do better with bitfields
     rule [makeUnwritable-subobject]:
          <k> 
               makeUnwritableSubObject(
                    lval(loc(Base:SymBase, Offset:Int, _), _)) 
               => . 
          ...</k>
          <notWritable> 
               M:Map => M:Map[1 / loc(Base, Offset:Int, 0)] 
          </notWritable>
          [structural]
     rule [makeUnwritable]:
          <k> makeUnwritable(loc(Base:SymBase, 0, 0)) => .K ...</k>
          <mem>... Base |-> memblock(_, (_ .Bag => mconst), _) ...</mem>
          [structural]

     syntax K ::= "checkValidLoc-aux" "(" SymLoc ")"
     
     rule checkValidLoc(Loc:SymLoc) => checkValidLoc-aux(ceilingLoc(Loc)) 
          [structural]
     rule checkDerefLoc(Loc:SymLoc) => checkValidLoc(Loc) 
          when Loc =/=K NullPointer
          [structural]
     
     rule [check-valid-loc-null]:
          checkValidLoc-aux(NullPointer) => . 
          [structural]
     // fixme could additionally use the type to check whether that type is
     // valid for that pointer
     rule [check-valid-loc]:
          <k> 
               checkValidLoc-aux(
                    loc(N:Int @ PtrThreadId:ThreadId, Offset:Int, 0)) 
               => . 
          ...</k>
          <mem>... N @ PtrThreadId |-> memblock(Len:Int, _, _) ...</mem>
          <threadId> MyThreadId:ThreadId </threadId>
          when (PtrThreadId ==K MyThreadId
               orBool (PtrThreadId ==K 0)
               orBool (PtrThreadId ==K allocatedDuration)
               ) // my thread, global memory, or allocated (malloced) memory
               andBool (Offset <=Int Len) // we're allowed to address one past
          [structural]
endmodule

module DYNAMIC-C-MEMORY
     imports DYNAMIC-MEMORY-INCLUDE 
     imports DYNAMIC-C-MEMORY-MISC 
     imports DYNAMIC-SEMANTICS-WRITING 
     imports DYNAMIC-SEMANTICS-READING 
endmodule
