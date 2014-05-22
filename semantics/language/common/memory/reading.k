module C-MEMORY-READING-SYNTAX
     // location, type
     syntax K ::= read(SymLoc, Type)

     // Returns the bytes in the order in which they are in memory.
     syntax K ::= readBytes(SymLoc, Int, Type)

     syntax K ::= concretize(Type, K) [strict(2)] 

     // data, offset, size in bits
     syntax K ::= extractBitsFromList(K, Int, Int) [strict(1)]

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

     syntax K ::= readActual(SymLoc, Type) [klabel('readActual)]
     
     /*@ These rules figure out whether the read should be structural or
     computational, depending on what is being read */
     rule read(Loc:SymLoc, T:Type) => readActual(Loc, T)
          when isThreadDuration(Loc)
          [structural]
     rule  // read data of "allocated" duration
          read(Loc:SymLoc, T:Type) => readActual(Loc, T)
          when notBool isThreadDuration(Loc)
               andBool Loc =/=K NullPointer
          [ndtrans]
     
     rule readActual(Loc:SymLoc, T:Type)
          => concretize(T, readBytes(Loc, byteSizeofType(T), T))
          when notBool isBitfieldType(T)
          [structural]
     rule readActual(Loc:SymLoc, T:Type)
          => concretize(T, fillToBytes(extractBitsFromMem(Loc, T))) 
          when isBitfieldType(T)
          [structural]
     
     rule concretize(T:Type, dataList(L:List)) 
          => joinIntegerBytes(T, L)
          when hasIntegerType(T) 
               andBool notBool isBitfieldType(T) 
               andBool (#hasUnknown(L) =/=K true)
               andBool (#hasTrap(L) =/=K true)
          [structural]
     rule concretize(t(S:Set, bitfieldType(T:KResult, Len:CSize)), dataList(L:List)) 
          => joinIntegerBytes(t(S, bitfieldType(T, Len)), reverseList(L)) 
          when (#hasUnknown(L) =/=K true)
               andBool (#hasTrap(L) =/=K true)
          [structural]
     // FIXME very unsafe, not checking size of list or its contents
     rule concretize(T:Type, dataList(
               ListItem(piece(encodedFloat(F:Float), Len:Int)) L:List)) 
          => tv(F:Float, stripQualifiers(T))
          when hasFloatType(T)
               andBool (Len ==Int cfg:bitsPerByte)
               andBool (#hasUnknown(L) =/=K true)
               andBool (#hasTrap(L) =/=K true)
          [structural]
     // fixme should also check sizes are appropriate
     rule concretize(T:Type, dataList(L:List)) 
          => joinPointerBytes(T, L)
          when isPointerType(T)
               andBool (#hasUnknown(L) =/=K true)
               andBool (#hasTrap(L) =/=K true)
          [structural]
     rule concretize(T:Type, dataList(L:List))
          => tv(unknown(bitSizeofType(T)), stripQualifiers(T))
          when (#hasUnknown(L) ==K true)
               andBool (#hasTrap(L) =/=K true)
               andBool notBool (isStructType(T) orBool isUnionType(T))
          [structural]
     rule concretize(T:Type, dataList(L:List))
          => tv(trap(bitSizeofType(T)), stripQualifiers(T))
          when (#hasTrap(L) ==K true)
               andBool notBool isUCharType(T)
               andBool notBool (isStructType(T) orBool isUnionType(T))
          [structural]
     rule concretize(T:Type, dataList(L:List))
          => tv(unknown(bitSizeofType(T)), stripQualifiers(T))
          when (#hasTrap(L) ==K true)
               andBool isUCharType(T)
          [structural]
     rule concretize(T:Type, dataList(L:List)) 
          => tv(agg(L), stripQualifiers(T))
          when isStructType(T) orBool isUnionType(T)
          [structural]

     syntax Bool ::= "#hasUnknown" "(" List ")" [function]
     syntax Bool ::= "#hasTrap" "(" List ")" [function]

     rule #hasUnknown(_ ListItem(piece(unknown(_), _)) _) => true
     rule #hasTrap(_ ListItem(piece(trap(_), _)) _) => true

     rule joinPointerBytes(T:Type, ListItem(piece(N:Bits, Len:Int)) L:List)
          => joinPointerBytes-aux(T, L, N)
          when Len ==Int cfg:bitsPerByte
          [structural]

     syntax K ::= joinPointerBytes(Type, List)
     syntax K ::= "joinPointerBytes-aux" "(" Type "," List "," K ")"
     rule joinPointerBytes-aux(T:Type, 
               ListItem(piece(subObject(N:Ptr, SNatEnd:Int, SNatEnd:Int), Len:Int))
               L:List, subObject(N, 0, End:Int))
          => joinPointerBytes-aux(T, L, subObject(N, 0, End +Int 1))
          when (Len ==Int cfg:bitsPerByte)
               andBool (SNatEnd ==Int End +Int 1)
          [structural]
     rule joinPointerBytes-aux(T:Type, .List, subObject(N:SymLoc, 0, _:Int))
          => tv(N, stripQualifiers(T))
          [structural]

     // FIXME assuming bytes?
     syntax K ::= joinIntegerBytes(Type, List)
     syntax K ::= "joinIntegerBytes-aux" "(" Type "," List "," K ")"
     rule joinIntegerBytes(T:Type, L:List)
          => joinIntegerBytes-aux(T, L, piece(0, 0)) 
          [structural]
     rule joinIntegerBytes-aux(T:Type, ListItem(piece(subObject(_, _, _), _)), piece(0, 0)) 
          => tv(unknown(bitSizeofType(T)), stripQualifiers(T))
          when hasCharType(T)
          [structural]
     rule joinIntegerBytes-aux(T:Type, 
               L:List ListItem(piece(N:Int, Len:Int)), piece(N':Int, Len':Int))
          => joinIntegerBytes-aux(T, 
               L, piece(piece(N', Len') bit:: piece(N, Len), Len +Int Len'))
          [structural]
     rule joinIntegerBytes-aux(T:Type, .List, piece(N:Int, Len:Int)) 
          => interpret(stripQualifiers(T), piece(N, Len)) 
          [structural]

     // fixme not sure about this
     // interpret is used to "cast" values read from memory
     // shouldn't need to do the < min one since values start positive

     // interpret the values of reading from mem
     syntax K ::= interpret(Type, K) [function]
     syntax K ::= "interpret-aux" "(" Type "," K ")" [function]
     rule interpret(T:Type, piece(N:Int, _)) => interpret-aux(T, N)
     rule interpret-aux(T:Type, I:Int) => tv(I, stripQualifiers(T))
          when (min(T) <=Int I) 
               andBool (max(T) >=Int I)
               andBool hasIntegerType(T)
     rule interpret-aux(T:Type, I:Int) 
          => interpret-aux(T, I:Int -Int (2 ^Int absInt(numBits(T))))
          when (I:Int >Int max(T))
               andBool hasIntegerType(T)
     rule interpret-aux(T:Type, I:Int) 
          => interpret-aux(T, I:Int +Int (2 ^Int absInt(numBits(T))))
          when (I:Int <Int min(T))
               andBool hasIntegerType(T)
     
     // loc, size in bits
     syntax K ::= extractBitsFromMem(SymLoc, Type)
     
     rule extractBitsFromMem(Loc:SymLoc, T:Type)
          => extractBitsFromList(
               readBytes(
                    floorLoc(Loc), bitsToBytes(bitSizeofType(T) +Int
                    getBitOffset(Loc)), T), 
               getBitOffset(Loc), bitSizeofType(T))
          [structural] 

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
     
endmodule

