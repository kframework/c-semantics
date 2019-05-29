module C-MEMORY-READING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS
     // location, type
     syntax KItem ::= read(SymLoc, Type)

     // Returns the bytes in the order in which they are in memory.
     syntax KItem ::= readBytes(SymLoc, Int, Type)
     syntax KItem ::= readBytesForWriting(SymLoc, Int)

     syntax KItem ::= concretize(UType, K) [strict(2)]

     // data, offset, size in bits
     syntax KItem ::= extractBitsFromList(K, Int, Int) [strict(1)]

endmodule

module C-MEMORY-READING
     imports BOOL
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports FLOAT-SYNTAX
     imports INT
     imports K-EQUAL
     imports SYMLOC-SYNTAX

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

     syntax KItem ::= readActual(SymLoc, Type)
     rule readActual(Loc::SymLoc, T::Type)
          => concretize(updateReadFrom(rvalType(T), Loc),
               readBytes(Loc, byteSizeofType(T), T))
          requires notBool isBitfieldType(T)
          [structural]
     rule readActual(Loc::SymLoc, t(... st: bitfieldType(...)) #as T::Type)
          => concretize(updateReadFrom(rvalType(T), Loc),
              fillToBytes(extractBitsFromMem(Loc, T)))
          [structural]

     rule concretize(T::UType, dataList(L::List))
          => interpret(T, joinBytes(L))
          requires (notBool hasUnknown(L))
               andBool (notBool hasTrap(L))
               andBool (notBool isStructOrUnionType(type(T)))
               andBool ((isIntegerUType(T) andBool notBool isCharUType(T)) impliesBool notBool hasFloat(L))
               andBool (isFloatUType(T) impliesBool notBool hasInt(L))
          [structural]
     rule concretize(T::UType, dataList(L::List))
          => #if hasOpaque(L) #then interpret(T, joinBytes(L))
             #else tv(agg(L), T) #fi
          requires isStructOrUnionType(type(T))
               andBool notBool (hasTrap(L) andBool hasLint)
          [structural]
     rule concretize(T::UType, dataList(L::List))
          => makeUnknown(concretize(T, stripUnknownAux(L, .List)))
          requires (hasUnknown(L) andBool notBool isPointerUType(T))
               andBool (notBool hasTrap(L))
               andBool notBool isStructOrUnionType(type(T))
          [structural]
     rule concretize(T::UType, dataList(L::List))
          => trap(T)
          requires (hasTrap(L) orBool (isPointerUType(T) andBool hasUnknown(L)))
               andBool notBool isStructOrUnionType(type(T))
          [structural]

     rule (.K => UNSPEC("CMR1", "Trying to reinterpret integer bytes as floating bytes.") ) ~>
          concretize(ut(... st: _:SimpleFloatType), dataList(L::List))
          requires hasInt(L)
          [structural]
     rule (.K => UNSPEC("CMR2", "Trying to reinterpret floating bytes as integer bytes.") ) ~>
          concretize(integerUType #as T::UType, dataList(L::List))
          requires hasFloat(L)
               andBool notBool isCharUType(T)
          [structural]

     syntax KItem ::= stripUnknownAux(List, List) [function]
     rule stripUnknownAux((ListItem(piece(unknown(I::Int), PieceLen::Int)) => .List) _, _::List (.List => ListItem(piece(I, PieceLen))))
     rule stripUnknownAux((ListItem(piece(pieces(L::List), _)) => L) _, _)
     rule stripUnknownAux((ListItem(B::Bits) => .List) _, _::List (.List => ListItem(B))) [owise]
     rule stripUnknownAux(.List, L::List) => dataList(L)

     syntax Bool ::= hasUnknown(List) [function]
                   | hasTrap(List) [function]
                   | hasInt(List) [function]
                   | hasFloat(List) [function]
                   | hasOpaque(List) [function]

     rule hasUnknown(.List) => false
     rule hasUnknown(ListItem(piece(B::BitValue, _) => B) _)
     rule hasUnknown((ListItem(pieces(L::List)) => L) _)
     rule hasUnknown(ListItem(unknown(_)) _) => true
     rule hasUnknown(ListItem(encodedValue(V::EncodableValue, _, _) => V) _)
     rule hasUnknown(ListItem(_) L::List) => hasUnknown(L) [owise]

     rule hasTrap(.List) => false
     rule hasTrap(ListItem(piece(B::BitValue, _) => B) _)
     rule hasTrap((ListItem(pieces(L::List)) => L) _)
     rule hasTrap(ListItem(trap) _) => true
     rule hasTrap(ListItem(_) L::List) => hasTrap(L) [owise]

     rule hasInt(.List) => false
     rule hasInt(ListItem(piece(B::BitValue, _) => B) _)
     rule hasInt((ListItem(pieces(L::List)) => L) _)
     rule hasInt(ListItem(B:Int) _) => true
          requires B =/=Int 0
     rule hasInt(ListItem(_) L::List) => hasInt(L) [owise]

     rule hasFloat(.List) => false
     rule hasFloat(ListItem(piece(B::BitValue, _) => B) _)
     rule hasFloat((ListItem(pieces(L::List)) => L) _)
     rule hasFloat(ListItem(_:Float) _) => true
     rule hasFloat(ListItem(encodedValue(_:Float, _, _)) _) => true
     rule hasFloat(ListItem(_) L::List) => hasFloat(L) [owise]

     rule hasOpaque(.List) => false
     rule hasOpaque(ListItem(piece(B::BitValue, _) => B) _)
     rule hasOpaque((ListItem(pieces(L::List)) => L) _)
     rule hasOpaque(ListItem(encodedValue(V::EncodableValue, _, _) => V) _)
     rule hasOpaque(ListItem(_:Opaque) _) => true
     rule hasOpaque(ListItem(_) L::List) => hasOpaque(L) [owise]

     syntax KItem ::= extractBitsFromMem(SymLoc, Type)
     rule extractBitsFromMem(Loc:SymLoc, T::Type)
          => extractBitsFromList(readBytes(Loc, byteRange(Loc, bitSizeofType(T)), T),
               bitOffsetIntoLastByte(Loc), bitSizeofType(T))
          [structural]

     rule extractBitsFromList(dataList(L::List), N::Int, M::Int)
          => extractBitsFromList-aux(dataList(explodeToBits(L)), N, M, .List)
          [structural]

     // datalist, offset in bits into list, number of bits to extract, accumulator
     syntax KItem ::= "extractBitsFromList-aux" "(" K "," Int "," Int "," List ")" [function]
     rule extractBitsFromList-aux(
               dataList(ListItem(piece(_, 1)) L::List),
               Offset::Int, NumBits::Int, .List)
          => extractBitsFromList-aux(
               dataList(L),
               Offset -Int 1, NumBits, .List)
          requires Offset >Int 0
     rule extractBitsFromList-aux(
               dataList(ListItem(piece(N::BitValue, 1)) L::List),
               0, NumBits::Int, Done::List)
          => extractBitsFromList-aux(
               dataList(L),
               0, NumBits -Int 1, Done ListItem(piece(N, 1)))
          requires NumBits >Int 0
     rule extractBitsFromList-aux(_, 0, 0, Done::List) => dataList(Done)

     syntax KItem ::= interpret(UType, BitValue)
     rule interpret(integerUType #as T::UType, I:Int)
          => #if max(T) >=Int I #then tv(I, T) #else interpret(T, I -Int (1 <<Int absInt(bitSizeofType(T)))) #fi
     rule interpret(integerUType #as T::UType, encodedPtr(NullPointer, _, _)) => tv(unknown(0), T)
     rule <k> interpret(T::UType, I:Int) => interpretPointer(T, I, Mem) ...</k>
          <mem> Mem::Map </mem>
          requires isPointerUType(T)
     rule interpret(ut(... st: _:SimpleFloatType) #as T::UType, 0) => tv(zeroCFloat(T), T)
     rule interpret(ut(... st: _:SimpleFloatType) #as T::UType, encodedPtr(NullPointer, _, _)) => tv(unknown(zeroCFloat(T)), T)
     rule interpret(ut(... st: _:SimpleFloatType) #as T::UType, I:Int) => tv(cfg:floatFromBits(I, T), T)
          requires I =/=Int 0
     rule interpret(T::UType, encodedPtr(Loc:SymLoc, 0, To::Int)) => tv(Loc, T)
          requires To ==Int (cfg:ptrsize *Int cfg:bitsPerByte)
               andBool notBool ((isIntegerUType(T) orBool isFloatUType(T)) andBool Loc ==K NullPointer)
     rule interpret(T::UType, encodedValue(F:Float, 0, To::Int)) => tv(F, T)
          requires isFullFloat(F, To)
     rule interpret(T::UType, encodedValue(opaque(V::Int, T'::UType), 0, To::Int)) => tv(opaque(V, T'), T)
          requires To ==Int bitSizeofType(type(T'))
     rule interpret(T::UType, encodedValue(unknown(V::EffectiveValue), 0, To::Int)) => tv(unknown(V), T)
          requires To ==Int bitSizeofType(type(T))
     rule interpret(T::UType, V::BitValue) => tv(V, T) [owise]

     syntax RValue ::= interpretPointer(UType, Int, Map) [function]
     rule interpretPointer(T::UType, I::Int, _) => tv(cfg:intToPointer(I, T), T)
          requires isPointerUType(T)
          [owise]

endmodule
