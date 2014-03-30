module C-MEMORY-READING-SYNTAX
     // location, type
     syntax K ::= read(SymLoc, K) [strict(2)]

     // Returns the bytes in the order in which they are in memory.
     syntax K ::= readBytes(SymLoc, Int) 
     syntax K ::= readByte(SymLoc) 

     syntax K ::= concretize(Type, K) [strict(2)] 

     // data, offset, size in bits
     syntax K ::= extractBitsFromList(K, Int, Int) [strict(1)]

     // TODO(chathhorn) used error check?
     syntax K ::= "joinIntegerBytes-aux" "(" Type "," List "," K ")"
     syntax K ::= "read-aux" "(" SymLoc "," Type "," CSize ")"
          [klabel('read-aux)]
     
     // datalist, offset in bits into list, number of bits to extract,
     // accumulator
     // TODO(chathhorn): used in ltlmc?
     syntax K ::= "extractBitsFromList-aux" "(" K "," Int "," Int "," List ")"
          [function]
endmodule

module C-MEMORY-READING
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     // loc, size in bits
     syntax K ::= extractBitsFromMem(SymLoc, CSize)
     
     rule extractBitsFromList(dataList(L:List), N:Int, M:Int) 
          => extractBitsFromList-aux(
               dataList(explodeToBits(L:List)), N:Int, M:Int, .List)
          [structural]
     // fixme snat
     rule extractBitsFromList-aux(
               dataList(ListItem(piece(_, 1)) L:List), 
               Offset:Int, NumBits:Int, .List)
          => extractBitsFromList-aux(
               dataList(L:List), 
               Offset:Int -Int 1, NumBits:Int, .List)
          when Offset:Int >Int 0
          [structural] 
     rule extractBitsFromList-aux(
               dataList(ListItem(piece(N:Bits, 1)) L:List), 
               0, NumBits:Int, Done:List)
          => extractBitsFromList-aux(
               dataList(L:List), 
               0, NumBits:Int -Int 1, Done:List ListItem(piece(N, 1)))
          when NumBits >Int 0
          [structural] 
     
     rule extractBitsFromList-aux(_, 0, 0, Done:List) => dataList(Done:List)
          [structural] 
     
     rule read(Loc:SymLoc, T:Type) 
          => read-aux(Loc, T, bitSizeofType(T))
          when notBool(isFunctionType(T))
          [structural]
     
     syntax K ::= readActual(SymLoc, Type, CSize) [klabel('readActual)]
     
     /*@ These rules figure out whether the read should be structural or
     computational, depending on what is being read */
     rule [read-thread-local]:
          read-aux(Loc:SymLoc, T:Type, Len:CSize) => readActual(Loc, T, Len)
          when isThreadDuration(Loc)
          [structural]
     rule [read-allocated]: // read data of "allocated" duration
          read-aux(Loc:SymLoc, T:Type, Len:CSize) => readActual(Loc, T, Len)
          when notBool isThreadDuration(Loc)
          [ndtrans]
     
     rule [read]:
          readActual(Loc:SymLoc, T:Type, N:CSize)
          => concretize(T, readBytes(Loc, bitsToBytes(N)))
          when notBool isBitfieldType(T)
          [structural]
     rule [read-bitfield]:
          readActual(Loc:SymLoc, T:Type, N:CSize)
          => concretize(T, fillToBytes(extractBitsFromMem(Loc, N))) 
          when isBitfieldType(T)
          [structural]
     
     syntax K ::= joinIntegerBytes(Type, List)
     rule concretize(T:Type, dataList(L:List)) 
          => joinIntegerBytes(T, L) 
          when hasIntegerType(T) 
               andBool notBool isBitfieldType(T) 
          [structural]
     rule concretize(t(S:Set, bitfieldType(T:KResult, Len:CSize)), dataList(L:List)) 
          => joinIntegerBytes(t(S, bitfieldType(T, Len)), reverseList(L)) 
          [structural]
          
     // fixme not sure about this
     // interpret is used to "cast" values read from memory
     // shouldn't need to do the < min one since values start positive

     // interpret the values of reading from mem
     syntax K ::= interpret(Type, K) [function]
     syntax K ::= "interpret-aux" "(" Type "," K ")" [function]
     
     rule [interpret-start]:
          interpret(T:Type, piece(N:Int, _)) => interpret-aux(T, N)
     
     rule [interpret-done]:
          interpret-aux(T:Type, I:Int) => tv(I, T)
          when (min(T) <=Int I) 
               andBool (max(T) >=Int I)
               andBool hasIntegerType(T)
     rule [interpret-too-big]:
          interpret-aux(T:Type, I:Int) 
          => interpret-aux(T, I:Int -Int (2 ^Int absInt(numBits(T))))
          when (I:Int >Int max(T))
               andBool hasIntegerType(T)
     rule [interpret-too-little]:
          interpret-aux(T:Type, I:Int) 
          => interpret-aux(T, I:Int +Int (2 ^Int absInt(numBits(T))))
          when (I:Int <Int min(T))
               andBool hasIntegerType(T)
          
     // FIXME very unsafe, not checking size of list or its contents
     rule concretize(T:KResult, dataList(
               ListItem(piece(encodedFloat(F:Float), Len:Int)) _:List)) 
          => tv(F:Float, T:KResult)
          when isFloatType(T:KResult)
               andBool (Len:Int ==Int cfg:bitsPerByte)
          [structural]

     syntax K ::= joinPointerBytes(Type, List)
     syntax K ::= "joinPointerBytes-aux" "(" Type "," List "," K ")"
     // fixme should also check sizes are appropriate
     rule concretize(T:Type, dataList(L:List)) 
          => joinPointerBytes(T, L)
          when isPointerType(T)
          [structural]
     rule joinPointerBytes(T:Type, ListItem(piece(N:Bits, Len:Int)) L:List)
          => joinPointerBytes-aux(T, L, N)
          when Len ==Int cfg:bitsPerByte
          [structural]

     rule joinPointerBytes-aux(T:Type, 
               ListItem(piece(subObject(N:Ptr, SNatEnd:Int, SNatEnd:Int), Len:Int))
               L:List, subObject(N, 0, End:Int))
          => joinPointerBytes-aux(T, L, subObject(N, 0, End +Int 1))
          when (Len ==Int cfg:bitsPerByte)
               andBool (SNatEnd ==Int End +Int 1)
          [structural]
     rule joinPointerBytes-aux(T:KResult, .List, subObject(N:SymLoc, 0, _:Int))
          => checkValidLoc(N) ~> tv(N, T:KResult)
          [structural]

     rule concretize(t(S:Set, structType(X:Id, NBits:Int, Info:AggInfo)), dataList(L:List)) 
          => tv(agg(L), t(S, structType(X, NBits, Info))) 
          [structural]
     rule concretize(t(S:Set, unionType(X:Id, NBits:Int, Info:AggInfo)), dataList(L:List)) 
          => tv(agg(L), t(S, unionType(X, NBits, Info)))
          [structural]

     // FIXME assuming bytes?
     rule [joinIntegerBytes-start]:
          joinIntegerBytes(T:Type, L:List) 
          => joinIntegerBytes-aux(T, L, piece(0, 0)) 
          [structural]
     
     // fixme may want to consider restricting further, or loosening
     rule [joinIntegerBytes-unknown-char]:
          joinIntegerBytes-aux(T:Type, 
               ListItem(piece(unknown(Len:Int), Len:Int)), piece(0, 0))
          => tv(piece(unknown(Len), Len), T)
          when isCharType(T)
          [structural]
     
     rule [joinIntegerBytes-step]:
          joinIntegerBytes-aux(T:Type, 
               L:List ListItem(piece(N:Int, Len:Int)), piece(N':Int, Len':Int))
          => joinIntegerBytes-aux(T, 
               L, piece(piece(N', Len') bit:: piece(N, Len), Len +Int Len'))
          [structural]
     rule [joinIntegerBytes-done]:
          joinIntegerBytes-aux(T:Type, .List, piece(N:Int, Len:Int)) 
          => interpret(T, piece(N, Len)) 
          [structural]
     
     rule extractBitsFromMem(Loc:SymLoc, Size:Int)
          => extractBitsFromList(
               readBytes(
                    floorLoc(Loc), bitsToBytes(Size +Int getBitOffset(Loc))), 
               getBitOffset(Loc), Size)
          [structural] 
     
endmodule

