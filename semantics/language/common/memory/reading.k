module C-MEMORY-READING-SYNTAX
     imports C-SYMLOC-SYNTAX

     // location, type
     syntax KItem ::= read(SymLoc, Type)

     // Returns the bytes in the order in which they are in memory.
     syntax KItem ::= readBytes(SymLoc, Int, Type)

     syntax KItem ::= concretize(Type, K) [strict(2)]

     // data, offset, size in bits
     syntax KItem ::= extractBitsFromList(K, Int, Int) [strict(1)]

     // datalist, offset in bits into list, number of bits to extract,
     // accumulator
     // TODO(chathhorn): used in ltlmc?
     syntax KItem ::= "extractBitsFromList-aux" "(" K "," Int "," Int "," List ")"
          [function]
endmodule

module C-MEMORY-READING
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     /*@ These rules figure out whether the read should be structural or
     computational, depending on what is being read */
     rule read(Loc:SymLoc, T:Type)
          => readActual(Loc, T)
          requires isThreadDuration(Loc) orBool isAutoDuration(Loc)
          [structural]
     // read data of "allocated" duration
     rule read(Loc:SymLoc, T:Type)
          => readActual(Loc, T)
          requires notBool isThreadDuration(Loc)
               andBool notBool isAutoDuration(Loc)
               andBool Loc =/=K NullPointer
          [ndtrans]

     syntax KItem ::= readActual(SymLoc, Type)
     rule readActual(Loc:SymLoc, T:Type)
          => concretize(T, readBytes(stripProv(Loc), byteSizeofType(T), T))
          requires notBool isBitfieldType(T)
          [structural]
     rule readActual(Loc:SymLoc, T:Type)
          => concretize(T, fillToBytes(extractBitsFromMem(Loc, T)))
          requires isBitfieldType(T)
          [structural]

     rule concretize(T:Type, dataList(L:List))
          => joinIntegerBytes(T, L)
          requires hasIntegerType(T)
               andBool notBool isBitfieldType(T)
               andBool (#hasUnknown(L) =/=K true)
               andBool (#hasTrap(L) =/=K true)
          [structural]
     rule concretize(t(S:Set, bitfieldType(T:Type, Len:CSize)), dataList(L:List))
          => joinIntegerBytes(t(S, bitfieldType(T, Len)), reverseList(L))
          requires (#hasUnknown(L) =/=K true)
               andBool (#hasTrap(L) =/=K true)
          [structural]
     rule concretize(T:Type, dataList(L:List))
          => joinFloatBytes(T, L)
          requires hasFloatType(T)
               andBool (#hasUnknown(L) =/=K true)
               andBool (#hasTrap(L) =/=K true)
          [structural]

     // fixme should also check sizes are appropriate
     rule concretize(T:Type, dataList(L:List))
          => joinPointerBytes(T, L)
          requires isPointerType(T)
               andBool (#hasUnknown(L) =/=K true)
               andBool (#hasTrap(L) =/=K true)
          [structural]
     rule concretize(T:Type, dataList(L:List))
          => tv(unknown, stripQualifiers(T))
          requires (#hasUnknown(L) ==K true)
               andBool (#hasTrap(L) =/=K true)
               andBool notBool (isStructType(T) orBool isUnionType(T))
          [structural]
     rule concretize(T:Type, dataList(L:List))
          => tv(trap, stripQualifiers(T))
          requires (#hasTrap(L) ==K true)
               andBool notBool isUCharType(T)
               andBool notBool (isStructType(T) orBool isUnionType(T))
          [structural]
     rule concretize(T:Type, dataList(L:List))
          => tv(unknown, stripQualifiers(T))
          requires (#hasTrap(L) ==K true)
               andBool isUCharType(T)
          [structural]
     rule concretize(T:Type, dataList(L:List))
          => tv(agg(L), stripQualifiers(T))
          requires isStructType(T) orBool isUnionType(T)
          [structural]

     syntax Bool ::= #hasUnknown(List) [function]
     syntax Bool ::= #hasTrap(List) [function]

     rule #hasUnknown(.List) => false
     rule #hasUnknown(ListItem(piece(unknown, _)) _:List) => true
     rule #hasUnknown(ListItem(piece(B:Bits, _)) L:List) => #hasUnknown(L)
          requires B =/=K unknown

     rule #hasTrap(.List) => false
     rule #hasTrap(ListItem(piece(trap, _)) _:List) => true
     rule #hasTrap(ListItem(piece(B:Bits, _)) L:List) => #hasTrap(L)
          requires B =/=K trap

     // TODO(chathhorn): half-assed floating point support.
     syntax TypedValue ::= joinFloatBytes(Type, List) [function]
     syntax TypedValue ::= joinFloatBytes(Type, Float, Int, List) [function]
     rule joinFloatBytes(T:Type,
               ListItem(piece(encodedFloat(F:Float), NBits:Int)) L:List)
          => joinFloatBytes(T, F, NBits, L)
     rule joinFloatBytes(T:Type,
               ListItem(piece(0, NBits:Int)) L:List)
          => joinFloatBytes(T, 0.0, NBits, L)
     rule joinFloatBytes(T:Type, F:Float, Len:Int,
               ListItem(piece(encodedFloat(_), NBits:Int)) L:List)
          => joinFloatBytes(T, F, Len +Int NBits, L)
     rule joinFloatBytes(T:Type, 0.0, Len:Int,
               ListItem(piece(0, NBits:Int)) L:List)
          => joinFloatBytes(T, 0.0, Len +Int NBits, L)
     rule joinFloatBytes(T:Type, F:Float, Len:Int, .List)
          => tv(F, stripQualifiers(T))
          requires Len ==Int bitSizeofType(T)

     syntax TypedValue ::= joinPointerBytes(Type, List) [function]
     syntax TypedValue ::= "joinPointerBytes-aux" "(" Type "," List "," K ")" [function]
     rule joinPointerBytes(T:Type, ListItem(piece(N:Bits, Len:Int)) L:List)
          => joinPointerBytes-aux(T, L, N)
          requires Len ==Int cfg:bitsPerByte
     rule joinPointerBytes-aux(T:Type,
               ListItem(piece(subObject(Loc:SymLoc, SNatEnd:Int, SNatEnd:Int), Len:Int))
               L:List, subObject(Loc, 0, End:Int))
          => joinPointerBytes-aux(T, L, subObject(Loc, 0, End +Int 1))
          requires (Len ==Int cfg:bitsPerByte)
               andBool (SNatEnd ==Int End +Int 1)
     rule joinPointerBytes-aux(T:Type, .List, subObject(Loc:SymLoc, 0, _))
          => tv(Loc, stripQualifiers(T))
     rule joinPointerBytes-aux(T:Type,
               ListItem(piece(0, Len:Int)) L:List, 0)
          => joinPointerBytes-aux(T, L, 0)
          requires (Len ==Int cfg:bitsPerByte)
     rule joinPointerBytes-aux(T:Type, .List, 0)
          => tv(NullPointer, stripQualifiers(T))

     syntax TypedValue ::= joinIntegerBytes(Type, List) [function]
     syntax TypedValue ::= "joinIntegerBytes-aux" "(" Type "," List "," K ")" [function]
     rule joinIntegerBytes(T:Type, L:List)
          => joinIntegerBytes-aux(T, L, piece(0, 0))
     rule joinIntegerBytes-aux(T:Type,
               ListItem(piece(subObject(Loc:SymLoc, Start:Int, End:Int), _)), piece(0, 0))
          => tv(subObject(Loc, Start, End), stripQualifiers(T))
          requires isUCharType(T)
     rule joinIntegerBytes-aux(T:Type,
               L:List ListItem(piece(N:Int, Len:Int)), piece(N':Int, Len':Int))
          => joinIntegerBytes-aux(T,
               L, piece(piece(N', Len') bit:: piece(N, Len), Len +Int Len'))
     rule joinIntegerBytes-aux(T:Type, .List, piece(N:Int, Len:Int))
          => interpret(stripQualifiers(T), piece(N, Len))

     // fixme not sure about this
     // interpret is used to "cast" values read from memory
     // shouldn't need to do the < min one since values start positive

     // interpret the values of reading from mem
     syntax TypedValue ::= interpret(Type, K) [function]
     syntax TypedValue ::= "interpret-aux" "(" Type "," K ")" [function]
     rule interpret(T:Type, piece(N:Int, _)) => interpret-aux(T, N)
     rule interpret-aux(T:Type, I:Int) => tv(I, stripQualifiers(T))
          requires (min(T) <=Int I)
               andBool (max(T) >=Int I)
               andBool hasIntegerType(T)
     rule interpret-aux(T:Type, I:Int)
          => interpret-aux(T, I:Int -Int (2 ^Int absInt(bitSizeofType(T))))
          requires (I:Int >Int max(T))
               andBool hasIntegerType(T)
     rule interpret-aux(T:Type, I:Int)
          => interpret-aux(T, I:Int +Int (2 ^Int absInt(bitSizeofType(T))))
          requires (I:Int <Int min(T))
               andBool hasIntegerType(T)

     // loc, size in bits
     syntax KItem ::= extractBitsFromMem(SymLoc, Type)

     rule extractBitsFromMem(Loc:SymLoc, T:Type)
          => extractBitsFromList(
               readBytes(stripProv(Loc), byteSizeofType(T), T), 0, bitSizeofType(T))
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
          requires Offset:Int >Int 0
          [structural]
     rule extractBitsFromList-aux(
               dataList(ListItem(piece(N:Bits, 1)) L:List),
               0, NumBits:Int, Done:List)
          => extractBitsFromList-aux(
               dataList(L:List),
               0, NumBits:Int -Int 1, Done:List ListItem(piece(N, 1)))
          requires NumBits >Int 0
          [structural]

     rule extractBitsFromList-aux(_, 0, 0, Done:List) => dataList(Done:List)
          [structural]

endmodule

