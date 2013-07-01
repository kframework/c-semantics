module C-MEMORY-READING-SYNTAX
     // returns the bytes in the order in which they are in memory
     syntax K ::= "extractBytesFromMem" "(" SymLoc "," Int ")"

     // TODO(chathhorn) error check
     syntax K ::= "extractByteFromMem" "(" SymLoc ")" 
     syntax K ::= "joinIntegerBytes-aux" "(" Type "," KList "," K ")"
     syntax K ::= "read-aux" "(" SymLoc "," K "," K ")" [klabel('read-aux)]
     
endmodule

module C-MEMORY-READING
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C11-ERROR-SYNTAX
     imports C11-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     syntax Set ::= locations(List) [function]
     rule [locations-none]: locations(.List) => .Set
     rule [locations-some]: locations(bwrite(Loc:SymLoc, _) L:List)
          => SetItem(Loc) locations(L:List)

     // loc, size in bits
     syntax K ::= "extractBitsFromMem" "(" SymLoc "," Int ")"
     
     // datalist, offset in bits into list, number of bits to extract,
     // accumulator
     syntax K ::= "extractBitsFromList-aux" "(" K "," Int "," Int "," KList ")"
     rule extractBitsFromList(dataList(L:KList), N:Int, M:Int) 
          => extractBitsFromList-aux(
               dataList(explodeToBits(L:KList)), N:Int, M:Int, .KList)
          [structural]
     // fixme snat
     rule extractBitsFromList-aux(
               dataList((piece(_, 1),, L:KList)), 
               Offset:Int, NumBits:Int, .KList)
          => extractBitsFromList-aux(
               dataList(L:KList), 
               Offset:Int -Int 1, NumBits:Int, .KList)
          when Offset:Int >Int 0
          [structural] 
     rule extractBitsFromList-aux(
               dataList((piece(N:Bits, 1),, L:KList)), 
               0, NumBits:Int, Done:KList)
          => extractBitsFromList-aux(
               dataList(L:KList), 
               0, NumBits:Int -Int 1, (Done:KList,, piece(N, 1)))
          when NumBits >Int 0
          [structural] 
     
     rule extractBitsFromList-aux(_, 0, 0, Done:KList) => dataList(Done:KList)
          [structural] 
     
     context readActual(_, _, value(HOLE))
     rule read(Loc:SymLoc, T:KResult) 
          => read-aux(Loc, T:KResult, value(bitSizeofType(T:KResult))) 
          when notBool(isFunctionType(T:KResult))
          [structural]
     
     syntax K ::= "readActual" "(" SymLoc "," K "," K ")" [klabel('readActual)]
     
     /*@ These rules figure out whether the read should be structural or
     computational, depending on what is being read */
     rule [read-thread-local]:
          <k> 
               ('read-aux => 'readActual)(loc(_ @ Th:Int, _:Int, _:Int),, _,, _) 
          ...</k>
          <threadId> Th </threadId>
          [structural, ndlocal]
     rule [read-shared]: // read global or shared data
          ('read-aux => 'readActual)(loc(_ @ 0, _:Int, _:Int),, _,, _)
          [computational, ndlocal]
     rule [read-allocated]: // read data of "allocated" duration
          ('read-aux => 'readActual)
               (loc(_ @ allocatedDuration, _:Int, _:Int),, _,, _)
          [computational, ndlocal]
     
     rule [read]:
          readActual(Loc:SymLoc, T:KResult, BitSize:Int)
          => concretize(T:KResult, 
               extractBytesFromMem(Loc, bitsToBytes(BitSize:Int)))
          when notBool isBitfieldType(T)
          [structural]
     rule [read-bitfield]:
          readActual(Loc:SymLoc, T:KResult, BitSize:Int)
          => concretize(T:KResult, 
               fillToBytes(extractBitsFromMem(Loc, BitSize:Int))) 
          when isBitfieldType(T)
          [structural]
     
     syntax K ::= "joinIntegerBytes" "(" Type "," KList ")"
     rule concretize(T:KResult, dataList(L:KList)) 
          => joinIntegerBytes(T:KResult, L:KList) 
          when hasIntegerType(T:KResult) 
               andBool notBool isBitfieldType(T:KResult) 
          [structural]
     rule concretize(t(S:Set, bitfieldType(T:KResult, Len:Int)), 
               dataList(L:KList)) 
          => joinIntegerBytes(t(S:Set, bitfieldType(T:KResult, Len:Int)), 
               reverseList(L:KList)) 
          [structural]
          
     // FIXME very unsafe, not checking size of list or its contents
     rule concretize(T:KResult, 
               dataList((piece(encodedFloat(F:Float), Len:Int),, _))) 
          => tv(F:Float, T:KResult)
          when isFloatType(T:KResult)
               andBool (Len:Int ==Int cfg:bitsPerByte)
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
          when Len:Int ==Int cfg:bitsPerByte
          [structural]
     // fixme sNat
     rule joinPointerBytes-aux(T:Type, 
               (piece(subObject(N:Ptr, SNatEnd:Int, SNatEnd:Int), Len:Int),, 
               L:KList), subObject(N, 0, End:Int))
          => joinPointerBytes-aux(T, L, subObject(N, 0, End +Int 1))
          when (Len ==Int cfg:bitsPerByte)
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
     rule [joinIntegerBytes-start]:
          joinIntegerBytes(T:Type, L:KList) 
          => joinIntegerBytes-aux(T, L, piece(0, 0)) 
          [structural]
     
     // fixme may want to consider restricting further, or loosening
     rule [joinIntegerBytes-unknown-char]:
          joinIntegerBytes-aux(T:Type, 
               piece(unknown(Len:Int), Len:Int), piece(0, 0))
          => tv(piece(unknown(Len), Len), T)
          when isCharType(T)
          [structural]
     
     rule [joinIntegerBytes-step]:
          joinIntegerBytes-aux(T:Type, 
               (L:KList,, piece(N:Int, Len:Int)), piece(N':Int, Len':Int))
          => joinIntegerBytes-aux(T, 
               L, piece(piece(N', Len') bit:: piece(N, Len), Len +Int Len'))
          [structural]
     rule [joinIntegerBytes-done]:
          joinIntegerBytes-aux(T:Type, .KList, piece(N:Int, Len:Int)) 
          => interpret(T, piece(N, Len)) 
          [structural]
     
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
               => assert(notBool (BagItem(loc(Base, Offset, 0)) in Locs), 3)
                    ~> assert(Offset <Int Len, 2)
                    ~> tv(V, t(.Set, no-type))
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
               => assert(notBool 
                    (BagItem(loc(Base, Offset, 0)) in Locs), 3)
                    ~> assert(Offset <Int Len, 2)
                    ~> tv(V, t(.Set, no-type))
          ...</k>
          <br/>
          <mem>... 
               Base |-> memblock(Len:Int, _, (_ Offset:Int |-> V:K)) 
          ...</mem>
          <locsWrittenTo> Locs:Bag </locsWrittenTo>
          <buffer> Mem:List </buffer>
          when notBool loc(Base, Offset, 0) in locations(Mem)
          [large, structural]
          
     rule [read-byte-lazy]:
          <k> extractByteFromMem(loc(Base:SymBase, Offset:Int, 0)) 
               => assert(Offset:Int <Int Len:Int, 2)
                    ~> tv(piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte), 
                         t(.Set, no-type))
          ...</k>
          <br/>
          <mem>... 
               Base |-> memblock(Len:Int, _, 
                    M:Map => M:Map[
                         piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte) 
                         / Offset]) 
          ...</mem>
          <buffer> Mem:List </buffer>
          when notBool loc(Base, Offset:Int, 0) in locations(Mem:List)
               andBool notBool Offset in (keys M)
          [large, structural]
          
          // TODO(chathhorn): perf, elided
//        rule [read-byte-buffer]:
//             <k> extractByteFromMem(Loc:SymLoc) 
//                  => assert(notBool BagItem(Loc) in Locs:Bag, 3)
//                  ~> tv(V:K, t(.Set, no-type))
//             ...</k>
//             <locsWrittenTo> Locs:Bag </locsWrittenTo>
//             <buffer>... bwrite(Loc, V:K) Mem:List </buffer>
//             when notBool Loc in locations(Mem:List)
//             [structural]
//             // for speed in interpretation; forces local buffer to be flushed
//             // before a read
//             //[interpRule] 

endmodule

