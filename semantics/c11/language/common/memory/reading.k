module C-MEMORY-READING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS
     // location, type
     syntax KItem ::= read(SymLoc, Type)

     // Returns the bytes in the order in which they are in memory.
     syntax KItem ::= readBytes(SymLoc, Int, Type)
     syntax KItem ::= readBytesForWriting(SymLoc, Int, List, Type)

     syntax KItem ::= concretize(UType, K) [strict(2)]

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
     imports C-CONFIGURATION
     imports BOOL
     imports FLOAT-SYNTAX
     imports INT
     imports K-EQUAL
     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-BITS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ These rules figure out whether the read should be structural or
     computational, depending on what is being read */
     rule read(Loc::SymLoc, T::Type)
          => readActual(Loc, T)
          requires isThreadDuration(Loc) orBool isAutoDuration(Loc)
          [structural]
     // read data of "allocated" duration
     rule read(Loc::SymLoc, T::Type)
          => readActual(Loc, T)
          requires notBool isThreadDuration(Loc)
               andBool notBool isAutoDuration(Loc)
               andBool Loc =/=K NullPointer
               andBool notBool isLinkerLoc(Loc)
          [ndtrans]
     rule <k> read(loc((Base::SymBase => Base'), _), _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>
          [structural]
     rule <k> read(loc((Base::SymBase => Base'), _, _), _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>
          [structural]

     syntax KItem ::= readActual(SymLoc, Type)
     rule readActual(Loc::SymLoc, T::Type)
          => concretize(updateReadFrom(utype(T), Loc),
               readBytes(stripProv(Loc), byteSizeofType(T), T))
          requires notBool isBitfieldType(T)
          [structural]
     rule readActual(Loc::SymLoc, T:BitfieldType)
          => concretize(updateReadFrom(utype(T), Loc),
              fillToBytes(extractBitsFromMem(Loc, T)))
          [structural]

     rule concretize(T:CharUType, dataList(ListItem(piece(encodedValue(F:Float, N:Int, M:Int), _))))
          => tv(encodedValue(F, N, M), T)
     rule concretize(T:IntegerUType, dataList(L::List))
          => joinIntegerBytes(T, L)
          requires notBool isBitfieldType(type(T))
               andBool (notBool hasUnknown(L))
               andBool (notBool hasTrap(L))
               andBool (notBool hasFloat(L))
          [structural]
     rule concretize(ut(S::Set, bitfieldType(T::BitfieldFieldType, Len::Int)), dataList(L::List))
          => joinIntegerBytes(ut(S, bitfieldType(T, Len)), reverseList(L))
          requires (notBool hasUnknown(L))
               andBool (notBool hasTrap(L))
          [structural]
     rule concretize(T:FloatUType, dataList(L::List))
          => joinFloatBytes(T, L)
          requires (notBool hasUnknown(L))
               andBool (notBool hasTrap(L))
               andBool (notBool hasInt(L))
          [structural]

     rule concretize(T:PointerUType, dataList(L::List))
          => joinIntegerBytes(T, L)
          requires (notBool hasUnknown(L))
               andBool (notBool hasTrap(L))
          [structural]
     rule concretize(T::UType, dataList(L::List))
          => makeUnknown2(concretize(T, stripUnknown(dataList(L))))
          requires (hasUnknown(L) andBool notBool isPointerUType(T))
               andBool (notBool hasTrap(L))
               andBool notBool isStructOrUnionType(type(T))
          [structural]
     rule concretize(T::UType, dataList(L::List))
          => trap(T)
          requires (hasTrap(L) orBool (isPointerUType(T) andBool hasUnknown(L)))
               andBool notBool isStructOrUnionType(type(T))
          [structural]
     rule concretize(T::UType, dataList(L::List))
          => tv(agg(L), T)
          requires isStructOrUnionType(type(T))
               andBool notBool (hasTrap(L) andBool hasLint)
          [structural]

     rule (.K => UNSPEC("CMR1", "Trying to reinterpret integer bytes as floating bytes.") ) ~>
          concretize(_:FloatUType, dataList(L::List))
          requires hasInt(L)
          [structural]
     rule (.K => UNSPEC("CMR2", "Trying to reinterpret floating bytes as integer bytes.") ) ~>
          concretize(T:IntegerUType, dataList(L::List))
          requires hasFloat(L)
               andBool notBool isCharUType(T)
          [structural]

     syntax KItem ::= stripUnknownAux(List, List) [function]
     rule stripUnknown(dataList(L::List)) => stripUnknownAux(L, .List)
     rule stripUnknownAux((ListItem(piece(unknown(I:Int), PieceLen:Int)) => .List) _:List, _:List (.List => ListItem(piece(I, PieceLen))))
     rule stripUnknownAux((ListItem(B::Bits) => .List) _:List, _:List (.List => ListItem(B))) [owise]
     rule stripUnknownAux(.List, L::List) => dataList(L)

     syntax Bool ::= hasUnknown(List) [function]
     syntax Bool ::= hasTrap(List) [function]
     syntax Bool ::= hasInt(List) [function]
     syntax Bool ::= hasFloat(List) [function]

     rule hasUnknown(.List) => false
     rule hasUnknown(ListItem(piece(B::Bits, _) => B) _:List)
     rule hasUnknown((ListItem(B::Bits bit:: B'::Bits) => ListItem(B) ListItem(B')) _:List)
     rule hasUnknown(ListItem(bitRange(B::Bits, _, _) => B) _:List)
     rule hasUnknown(ListItem(unknown(_)) _:List) => true
     rule hasUnknown(ListItem(B::Bits) L:List) => hasUnknown(L) [owise]

     rule hasTrap(.List) => false
     rule hasTrap(ListItem(piece(B::Bits, _) => B) _:List)
     rule hasTrap((ListItem(B::Bits bit:: B'::Bits) => ListItem(B) ListItem(B')) _:List)
     rule hasTrap(ListItem(bitRange(B::Bits, _, _) => B) _:List)
     rule hasTrap(ListItem(trap) _:List) => true
     rule hasTrap(ListItem(B::Bits) L:List) => hasTrap(L) [owise]

     rule hasInt(.List) => false
     rule hasInt(ListItem(piece(B::Bits, _) => B) _:List)
     rule hasInt((ListItem(B::Bits bit:: B'::Bits) => ListItem(B) ListItem(B')) _:List)
     rule hasInt(ListItem(bitRange(B::Bits, _, _) => B) _:List)
     rule hasInt(ListItem(B:Int) _:List) => true
          requires B =/=Int 0
     rule hasInt(ListItem(B::Bits) L:List) => hasInt(L) [owise]

     rule hasFloat(.List) => false
     rule hasFloat(ListItem(piece(B::Bits, _) => B) _:List)
     rule hasFloat((ListItem(B::Bits bit:: B'::Bits) => ListItem(B) ListItem(B')) _:List)
     rule hasFloat(ListItem(bitRange(B::Bits, _, _) => B) _:List)
     rule hasFloat(ListItem(encodedValue(F:Float, _, _)) _:List) => true
     rule hasFloat(ListItem(B::Bits) L:List) => hasFloat(L) [owise]

     syntax RValue ::= joinFloatBytes(UType, List) [function, klabel(joinFloatBytesC)]
     syntax RValue ::= "joinFloatBytes-aux" "(" UType "," List "," K ")" [function]
     rule joinFloatBytes(T::UType, ListItem(piece(N:Bits, Len:Int)) L:List)
          => joinFloatBytes-aux(T, L, N)
          requires Len ==Int cfg:bitsPerByte
     rule joinFloatBytes-aux(T::UType,
               ListItem(piece(encodedValue(F, SNatEnd:Int, SNatEnd:Int), Len:Int))
               L:List, encodedValue(F:Float, I:Int, End:Int))
          => joinFloatBytes-aux(T, L, encodedValue(F, I, End +Int 1))
          requires (Len ==Int cfg:bitsPerByte)
               andBool (SNatEnd ==Int End +Int 1)
     rule joinFloatBytes-aux(T:UType, .List, encodedValue(F:Float, 0, N:Int))
          => tv(F, T)
          requires N ==Int byteSizeofType(T) -Int 1
     rule joinFloatBytes-aux(T:UType, .List, encodedValue(F:Float, M:Int, N:Int))
          => tv(encodedValue(F, M,  N), T)
          requires N <Int byteSizeofType(T) -Int 1 orBool M >Int 0
     rule joinFloatBytes-aux(T::UType,
               ListItem(piece(0, Len:Int)) L:List, 0)
          => joinFloatBytes-aux(T, L, 0)
          requires Len ==Int cfg:bitsPerByte
     rule joinFloatBytes-aux(T::UType, .List, 0)
          => tv(Int2CFloat(T, 0), T)

     syntax RValue ::= joinPointerBytes(UType, List) [function, klabel(joinPointerBytesC)]
     syntax RValue ::= "joinPointerBytes-aux" "(" UType "," List "," K ")" [function]
     rule joinPointerBytes(T::UType, ListItem(piece(N:Bits, Len:Int)) L:List)
          => joinPointerBytes-aux(T, L, N)
          requires Len ==Int cfg:bitsPerByte
     rule joinPointerBytes-aux(T::UType,
               ListItem(piece(encodedValue(Loc:SymLoc, SNatEnd:Int, SNatEnd:Int), Len:Int))
               L:List, encodedValue(Loc, I:Int, End:Int))
          => joinPointerBytes-aux(T, L, encodedValue(Loc, I, End +Int 1))
          requires (Len ==Int cfg:bitsPerByte)
               andBool (SNatEnd ==Int End +Int 1)
     rule joinPointerBytes-aux(T::UType, .List, encodedValue(Loc:SymLoc, 0, N:Int))
          => tv(Loc, T)
          requires N ==Int cfg:ptrsize -Int 1
     rule joinPointerBytes-aux(T::UType, .List, encodedValue(Loc:SymLoc, M:Int, N:Int))
          => tv(encodedValue(Loc, M,  N), T)
          requires N <Int cfg:ptrsize -Int 1 orBool M >Int 0
     rule joinPointerBytes-aux(T::UType,
               ListItem(piece(0, Len:Int)) L:List, 0)
          => joinPointerBytes-aux(T, L, 0)
          requires Len ==Int cfg:bitsPerByte
     rule joinPointerBytes-aux(T::UType, .List, 0)
          => tv(NullPointer, T)

     syntax RValue ::= joinIntegerBytes(UType, List) [function, klabel(joinIntegerBytesC)]
     syntax RValue ::= "joinIntegerBytes-aux" "(" UType "," List "," K ")" [function]
     rule joinIntegerBytes(T::UType, L::List)
          => joinIntegerBytes-aux(T, L, piece(0, 0))
     rule joinIntegerBytes-aux(T::UType,
               L::List ListItem(piece(encodedValue(Loc:SymLoc, Start::Int, End::Int), Len:Int)), piece(0, 0))
          => joinPointerBytes(T, L ListItem(piece(encodedValue(Loc, Start, End), Len)))
     rule joinIntegerBytes-aux(T::UType,
               L:List ListItem(piece(N:Int, Len:Int)), piece(N':Int, Len':Int))
          => joinIntegerBytes-aux(T,
               L, piece(piece(N', Len') bit:: piece(N, Len), Len +Int Len'))
     rule joinIntegerBytes-aux(T::UType, .List, piece(N:Int, Len:Int))
          => interpret(T, piece(N, Len))

     // interpret the values of reading from mem
     syntax RValue ::= interpret(UType, K) [function]
     syntax RValue ::= "interpret-aux" "(" UType "," K ")" [function]
     rule interpret(T::UType, piece(N::Int, _)) => interpret-aux(T, N)
     rule interpret-aux(T:IntegerUType, I::Int)
          => #if max(T) >=Int I #then tv(I, T) #else interpret-aux(T, I -Int (1 <<Int absInt(bitSizeofType(T)))) #fi
     rule interpret-aux(T:PointerUType, I::Int) => tv(cfg:intToPointer(I, T), T)
     rule interpret-aux(T:FloatUType, I::Int) => tv(cfg:floatFromBits(I, T), T)

     syntax KItem ::= extractBitsFromMem(SymLoc, Type)

     rule extractBitsFromMem(Loc:SymLoc, T::Type)
          => extractBitsFromList(
               readBytes(stripProv(Loc), (getBitOffset(Loc) +Int bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte, T),
               getBitOffset(Loc), bitSizeofType(T))
          [structural]

     rule extractBitsFromList(dataList(L:List), N:Int, M:Int)
          => extractBitsFromList-aux(dataList(explodeToBits(L)), N, M, .List)
          [structural]
     rule extractBitsFromList-aux(
               dataList(ListItem(piece(_, 1)) L:List),
               Offset:Int, NumBits:Int, .List)
          => extractBitsFromList-aux(
               dataList(L),
               Offset -Int 1, NumBits, .List)
          requires Offset:Int >Int 0
          [structural]
     rule extractBitsFromList-aux(
               dataList(ListItem(piece(N:Bits, 1)) L:List),
               0, NumBits:Int, Done:List)
          => extractBitsFromList-aux(
               dataList(L),
               0, NumBits -Int 1, Done ListItem(piece(N, 1)))
          requires NumBits >Int 0
          [structural]

     rule extractBitsFromList-aux(_, 0, 0, Done:List) => dataList(Done)
          [structural]

endmodule

