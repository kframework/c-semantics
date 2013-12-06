module C-MEMORY-READING-SYNTAX
     // TODO(chathhorn) error check
     syntax K ::= "joinIntegerBytes-aux" "(" Type "," KList "," K ")"
     syntax K ::= "read-aux" "(" SymLoc "," Type "," K ")" [klabel('read-aux)]
     
     // datalist, offset in bits into list, number of bits to extract,
     // accumulator
     syntax K ::= "extractBitsFromList-aux" "(" K "," Int "," Int "," KList ")"
          [function]
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
     imports C11-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     // loc, size in bits
     syntax K ::= "extractBitsFromMem" "(" SymLoc "," Int ")"
     
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
     
     rule read(Loc:SymLoc, T:Type) 
          => read-aux(Loc, T, bitSizeofType(T))
          when notBool(isFunctionType(T))
          [structural]
     
     syntax K ::= "readActual" "(" SymLoc "," Type "," K ")" 
          [strict(3), klabel('readActual)]
     
     /*@ These rules figure out whether the read should be structural or
     computational, depending on what is being read */
     rule [read-thread-local]:
          ('read-aux => 'readActual)(loc(_ @ Th:Int, _:Int, _:Int),, _,, _) 
          when Th =/=Int 0
          [structural]
     rule [read-shared]: // read global or shared data
          ('read-aux => 'readActual)(loc(_ @ 0, _:Int, _:Int),, _,, _)
          [ndtrans]
     rule [read-allocated]: // read data of "allocated" duration
          ('read-aux => 'readActual)
               (loc(_ @ allocatedDuration, _:Int, _:Int),, _,, _)
          [ndtrans]
     
     rule [read]:
          readActual(Loc:SymLoc, T:Type, BitSize:TypedValue)
          => concretize(T, 
               readBytes(Loc, bitsToBytes(value(BitSize))))
          when notBool isBitfieldType(T)
          [structural]
     rule [read-bitfield]:
          readActual(Loc:SymLoc, T:Type, BitSize:TypedValue)
          => concretize(T, 
               fillToBytes(extractBitsFromMem(Loc, value(BitSize)))) 
          when isBitfieldType(T)
          [structural]
     
     syntax K ::= "joinIntegerBytes" "(" Type "," KList ")"
     rule concretize(T:Type, dataList(L:KList)) 
          => joinIntegerBytes(T, L) 
          when hasIntegerType(T) 
               andBool notBool isBitfieldType(T) 
          [structural]
     rule concretize(t(S:Set, bitfieldType(T:KResult, Len:Int)), 
               dataList(L:KList)) 
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
          when Len ==Int cfg:bitsPerByte
          [structural]

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
          => tv(L, t(S, structType(I))) 
          [structural]
     rule concretize(t(S:Set, unionType(I:Id)), dataList(L:KList)) 
          => tv(L, t(S, unionType(I)))
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
               readBytes(
                    floorLoc(Loc), bitsToBytes(Size +Int getBitOffset(Loc))), 
               getBitOffset(Loc), Size)
          [structural] 
     
endmodule

