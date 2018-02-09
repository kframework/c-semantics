module C-MEMORY-WRITING-SYNTAX
     imports BASIC-K
     imports INT-SYNTAX
     imports STRING-SYNTAX
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     // location, value
     syntax KItem ::= write(SymLoc, CValue, Type)

     // Either buffered or unbuffered depending on whether we're executing.
     syntax KItem ::= writeBytes(SymLoc, K, Type) [strict(2), klabel(writeBytes3)]
     syntax KItem ::= writeBytes(SymLoc, List)

     syntax List ::= explodeToBits(List) [function]

     // TODO(chathhorn): For trans/symbolic-value.k
     syntax DataList ::= splitBytes(RValue) [function, klabel(splitBytesC)]

     // No null terminator.
     syntax KItem ::= writeChars(SymLoc, String)
     // Null terminates.
     syntax KItem ::= writeString(SymLoc, String)

     syntax KItem ::= writeWChars(SymLoc, List)
     syntax KItem ::= writeWString(SymLoc, List)
endmodule

module C-MEMORY-WRITING
     imports C-MEMORY-WRITING-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports FLOAT-SYNTAX
     imports INT
     imports K-EQUAL
     imports K-REFLECTION
     imports MAP
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports COMMON-SORTS
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-SYNTAX
     imports MEMORY-SYNTAX

     // Write thread-local or auto.
     rule <k> write(Loc:SymLoc, V:CValue, T:Type)
               => writeSpecific(Loc, V, T)
          ...</k>
          <initializing> false </initializing>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool notBool isConstType(T)
          [structural]
     rule <k> write(Loc:SymLoc, V:CValue, T:Type)
               => writeSpecific(Loc, V, T)
          ...</k>
          <initializing> true </initializing>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
          [structural]
     // Write global, shared data, or "allocated" duration.
     rule <k> write(Loc:SymLoc, V:CValue, T:Type)
               => writeSpecific(Loc, V, T)
          ...</k>
          <initializing> false </initializing>
          requires (isStaticDuration(Loc) orBool isAllocatedDuration(Loc))
               andBool notBool isConstType(T)
               andBool notBool isStringLoc(Loc)
               andBool notBool isLinkerLoc(Loc)
          [ndtrans]
     rule <k> write(Loc:SymLoc, V:CValue, T:Type)
               => writeSpecific(Loc, V, T)
          ...</k>
          <initializing> true </initializing>
          requires (isStaticDuration(Loc) orBool isAllocatedDuration(Loc))
               andBool notBool isLinkerLoc(Loc)
          [ndtrans]
     rule write(Loc:SymLoc, V:CValue, T:Type) => writeSpecific(Loc, V, T)
          requires isNativeLoc(Loc)
          [ndtrans]
     rule <k> (.K => CV("CMW2", "Trying to write through a const lvalue.") )
               ~> write(_, _, T:Type)
          ...</k>
          <initializing> false </initializing>
          requires isConstType(T)
          [structural]
     rule <k> (.K => UNDEF("CMW1", "Trying to modify a string literal."))
               ~> write(Loc:SymLoc, _, _)
          ...</k>
          <initializing> false </initializing>
          requires isStringLoc(Loc)
          [structural]

     syntax KItem ::= writeSpecific(SymLoc, CValue, Type)
     rule <k> writeSpecific(Loc::SymLoc, V::CValue, T::Type)
               => updateEffectiveType(Loc)
               ~> makePaddingUnknown(base(Loc), bitOffset(Loc), getEffectiveType(base(Loc)))
               ~> writeSpecific'(Loc, stripLastAccessType(V), T)
          ...</k>
          <mem> Mem::Map </mem>
          requires base(Loc) in_keys(Mem)
     rule <k> writeSpecific(Loc::SymLoc, V::CValue, T::Type)
               => writeSpecific'(Loc, stripLastAccessType(V), T)
          ...</k>
          <mem> Mem::Map </mem>
          requires notBool (base(Loc) in_keys(Mem))

     syntax KItem ::= "writeSpecific'" "(" SymLoc "," CValue "," Type ")"
     rule writeSpecific'(Loc::SymLoc, V::CValue, T::Type)
          => writeBytes(Loc, splitBytes(tv(V, utype(T))), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool (notBool isBitfieldType(T))
          [structural]
     rule writeSpecific'(Loc::SymLoc, I:Int, T::Type)
          => writeSpecific'(Loc, justBits(I, utype(T)), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0 orBool isBitfieldType(T))
               andBool (I <Int 0)
          [structural]
     rule writeSpecific'(Loc::SymLoc, V:Int, T::Type)
          => writeBytes(Loc,
               calculateNewBytes(piece(V, bitSizeofType(T)),
                    readBytesForWriting(Loc, (bitOffsetIntoLastByte(Loc) +Int bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte, .List), bitOffsetIntoLastByte(Loc)), T)
          requires ((bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0) orBool isBitfieldType(T))
               andBool (V >=Int 0)
          [structural]
     rule writeSpecific'(Loc::SymLoc, V:Pieces, T::Type)
          => writeBytes(Loc,
               calculateNewBytes(piece(V, bitSizeofType(T)),
                    readBytesForWriting(Loc, (bitOffsetIntoLastByte(Loc) +Int bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte, .List), bitOffsetIntoLastByte(Loc)), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0) orBool isBitfieldType(T)
          [structural]

     syntax KItem ::= makeUnionUnknown(SymLoc, Type, Int)
                    | makeStructUnknown(SymLoc, FieldInfo, Int)
                    | makePaddingUnknown(SymBase, Int, K) [strict(3)]
                    | makeStructUnionUnknown(SymBase, Int, Int, Type) [function]

     rule makePaddingUnknown(Base::SymBase, Offset::Int, EffT:Type)
          => makeStructUnionUnknown(Base, 0, Offset, EffT)
     rule makePaddingUnknown(Base::SymBase, Offset::Int, dynamicType(EffT::Type))
          => makeStructUnionUnknown(Base, 0, Offset, EffT)

     rule makeStructUnionUnknown(Base::SymBase, Offset::Int, RelOffset::Int, T:ArrayType)
          => makeStructUnionUnknown(Base, Offset +Int floorBitOffset(RelOffset, T),
               RelOffset %Int bitSizeofType(innerType(T)), getElementType(RelOffset, T))
     rule makeStructUnionUnknown(Base::SymBase, Offset::Int, RelOffset::Int, T:StructType)
          => allowInit(makeStructUnknown(loc(Base, Offset /Int cfg:bitsPerByte), getFields(T), 0))
          ~> makeStructUnionUnknown(Base, Offset +Int floorBitOffset(RelOffset, T), RelOffset -Int floorBitOffset(RelOffset, T), getFieldTypeAtOffset(RelOffset, T))
     rule makeStructUnionUnknown(Base::SymBase, Offset::Int, RelOffset::Int, T:UnionType)
          => allowInit(makeUnionUnknown(loc(Base, Offset /Int cfg:bitsPerByte), getActiveVariant(T), byteSizeofType(T)))
          ~> makeStructUnionUnknown(Base, Offset, RelOffset, getActiveVariant(T))
     rule makeStructUnionUnknown(_, _, _, _) => .K [owise]

     // Flag unknown from (&union + sizeof union.F) to (&union + sizeof union).
     rule (.K => makeUnknownBytes(readBytesForWriting(Loc +bytes byteSizeofType(T), Sz -Int byteSizeofType(T), .List)))
          ~> makeUnionUnknown(Loc::SymLoc, T::Type, Sz::Int)
          requires Sz >Int byteSizeofType(T) andBool notBool isNoType(T)
          [structural]
     rule dataList(Bytes::List) ~> makeUnionUnknown(Loc::SymLoc, T::Type, _)
          => writeBytes(Loc +bytes byteSizeofType(T), Bytes)
          [structural]
     rule makeUnionUnknown(_, T::Type, Sz::Int) => .K
          requires Sz <=Int byteSizeofType(T) orBool isNoType(T)
          [structural]

     rule (.K => makeUnknownBytes(readBytesForWriting(Loc +bytes I, 1, .List)))
          ~> makeStructUnknown(Loc::SymLoc, fieldInfo(_, Sz::Int, _, _, _) #as Fields::FieldInfo, I::Int)
          requires isPaddingOffset(I, Fields) andBool I *Int cfg:bitsPerByte <Int Sz
     rule (dataList(Bytes::List) => writeBytes(Loc +bytes I, Bytes))
          ~> makeStructUnknown(Loc::SymLoc, _, I::Int => I +Int 1)
     rule makeStructUnknown(Loc::SymLoc, fieldInfo(_, Sz::Int, _, _, _) #as Fields::FieldInfo, I::Int)
          => makeStructUnknown(Loc, Fields, I +Int 1)
          requires notBool isPaddingOffset(I, Fields) andBool I *Int cfg:bitsPerByte <Int Sz
     rule makeStructUnknown(_, fieldInfo(_, Sz::Int, _, _, _), I::Int)
          => .K
          requires I *Int cfg:bitsPerByte >=Int Sz

     syntax Int ::= justBits(Int, UType) [function]
     syntax Int ::= "justBits-aux" "(" Int "," UType ")" [function]
     rule justBits(I::Int, _) => I
          requires I >=Int 0

     rule justBits(I::Int, T::UType) => justBits-aux(I, T)
          requires I <Int 0
     rule justBits-aux(I::Int, T::UType)
          => justBits-aux(I +Int max(T) +Int 1, T)
          requires I <Int 0
     rule justBits-aux(N::Int, ut(_, bitfieldType(_, Len::Int)))
          => N +Int (1 <<Int (Len -Int 1))
          requires Len >Int 0 andBool N >=Int 0

     syntax KItem ::= calculateNewBytes(Bits, K, Int)
          [latex(\terminal{calcNewBytes(}{#1}, {#2}\terminal{)}), strict(2)]

     rule calculateNewBytes(N::Bits, dataList(L:List), Offset::Int)
          => calculateNewBytes-aux(dataList(explodeToBits(ListItem(N))),
               dataList(explodeToBits(L)), .List, Offset)
          [structural]

     syntax KItem ::= "calculateNewBytes-aux" "(" DataList "," DataList "," List "," Int ")"
     rule calculateNewBytes-aux(
               dataList(L::List),
               dataList(ListItem(piece(N::BitValue, 1)) L'::List),
               Result::List, Offset::Int)
          => calculateNewBytes-aux(
               dataList(L),
               dataList(L'),
               Result ListItem(piece(N, 1)), Offset -Int 1)
          requires Offset >Int 0
     rule calculateNewBytes-aux(
               dataList(ListItem(piece(N::BitValue, 1)) L::List),
               dataList(ListItem(piece(_, 1)) L'::List),
               Result::List, 0)
          => calculateNewBytes-aux(
               dataList(L),
               dataList(L'),
               Result ListItem(piece(N, 1)), 0)
          [structural]
     rule calculateNewBytes-aux(dataList(.List), dataList(L::List), Result::List, 0)
          => joinBitsToBytes(Result L)
          [structural]

     syntax KItem ::= joinBitsToBytes(List) [function]
     rule joinBitsToBytes(L:List)
          => joinBitsToBytes-aux(dataList(L), dataList(.List))

     syntax KItem ::= "joinBitsToBytes-aux" "(" K "," K ")" [function]
     rule joinBitsToBytes-aux(
               dataList(ListItem(piece(N::BitValue, Len:Int)) ListItem(piece(M::BitValue, 1)) L:List),
               dataList(R:List))
          => joinBitsToBytes-aux(
               dataList(ListItem(piece(N, Len) bit:: piece(M, 1)) L),
               dataList(R))
          requires Len <Int cfg:bitsPerByte
     rule joinBitsToBytes-aux(
               dataList(ListItem(piece(N::BitValue, Len:Int)) L:List), dataList(R:List))
          => joinBitsToBytes-aux(
               dataList(L), dataList(R ListItem(piece(N, Len))))
          requires Len ==Int cfg:bitsPerByte
     rule joinBitsToBytes-aux(dataList(.List), dataList(R:List))
          => dataList(R)

     rule explodeToBits(ListItem(K:Bits) L::List)
          => explodeToBits(ListItem(K)) explodeToBits(L)
          requires L =/=K .List
     rule explodeToBits(ListItem(piece(pieces(L::List), _)) L'::List)
          => explodeToBits(L) explodeToBits(L')
     rule explodeToBits(ListItem(piece(N::BitValue, Len::Int)))
          => splinter(N, Len)
          requires Len >Int 0 andBool notBool isPieces(N)
     rule explodeToBits(ListItem(piece(_, 0))) => .List
     rule explodeToBits(.List) => .List

     syntax List ::= splinter(BitValue, Int) [function]
     syntax List ::= "splinter-aux" "(" BitValue "," Int "," Int ")" [function]
     rule splinter(N::BitValue, Len::Int) => splinter-aux(N, Len, 0)
     rule splinter-aux(_, Len::Int, Len) => .List
     rule splinter-aux(N::BitValue, Len::Int, Pos::Int)
          => ListItem(encode(N, Pos, Pos +Int 1))
               splinter-aux(N, Len, Pos +Int 1)
          requires Pos <Int Len

     // this general rule is useful for unknowns, abstracts, etc
     rule splitBytes(tv(N:BitValue, T:UType))
          => dataList(ListItem(piece(N, cfg:bitsPerByte)))
          requires isCharType(type(T))
               andBool notBool isInt(N)
     rule splitBytes(tv(unknown(I:Int), T::UType))
          => makeUnknownBytes(splitBytes(tv(I, T)))
     rule splitBytes(tv(I:Int, T::UType))
          => splitBytes(I, byteSizeofType(T))
     rule splitBytes(tv(F:Float, T::UType))
          => splitBytes(F, byteSizeofType(T))
     rule splitBytes(tv(Loc:SymLoc, T::UType))
          => splitBytes(Loc, byteSizeofType(T))
     rule splitBytes(tv(V:Opaque, T::UType))
          => splitBytes(V, byteSizeofType(T))
     rule splitBytes(tv(V:Trap, T::UType))
          => splitBytes(V, byteSizeofType(T))
     rule splitBytes(tv(agg(L:List), T:StructOrUnionUType))
          => splitStructBytes(dataList(L), T,
               byteSizeofType(T))

     syntax KItem ::= makeUnknownBytes(K) [strict]
     rule makeUnknownBytes(dataList(L::List)) => makeUnknownAux(L, .List)

     syntax KItem ::= makeUnknownAux(List, List) [function]
     rule makeUnknownAux((ListItem(piece(I:Int, PieceLen:Int)) => .List) L::List, _:List (.List => ListItem(piece(unknown(I), PieceLen))))
     rule makeUnknownAux(.List, L::List) => dataList(L)
     rule makeUnknownAux((ListItem(B::Bits) => .List) L::List, _:List (.List => ListItem(B))) [owise]

     syntax DataList ::= splitStructBytes(K, StructOrUnionUType, Int) [function]
     syntax DataList ::= #splitStructBytes(K, StructOrUnionUType, Int, List)  [function]

     rule splitStructBytes(dataList(L:List), T::StructOrUnionUType, Len:Int)
          => #splitStructBytes(dataList(L), T, Len, .List)
     rule #splitStructBytes(
          dataList(ListItem(piece(N::BitValue, PieceLen:Int)) Rest:List),
               T::StructOrUnionUType, Len:Int, L:List)
          => #splitStructBytes(dataList(Rest), T, Len -Int 1,
               L ListItem(piece(N, PieceLen)))
          requires PieceLen ==Int cfg:bitsPerByte
               andBool Len >Int 0
               andBool (notBool isPaddingOffset(byteSizeofType(T) -Int Len, getFields(T))
                    orBool isUnknown(N))
     rule #splitStructBytes(
          dataList(ListItem(piece((N::BitValue => unknown(#if isInt(N) #then N #else 0 #fi)), _)) _),
               T::StructOrUnionUType, Len::Int, _)
          requires isPaddingOffset(byteSizeofType(T) -Int Len, getFields(T))
               andBool notBool isUnknown(N)
     rule #splitStructBytes(_, _, 0, L::List) => dataList(L)

     syntax Bool ::= isPaddingOffset(Int, K) [function]
     rule isPaddingOffset(Offset::Int, fieldInfo(_, _, _, _, PaddingOffs::Set))
          => Offset *Int cfg:bitsPerByte in PaddingOffs

     rule writeChars(Loc::SymLoc, S::String)
          => Computation(
               * tv(Loc, utype(pointerType(type(char))))
               := tv(ordChar(firstChar(S:String)), utype(char)))
               ~> writeChars(Loc +bytes 1, butFirstChar(S:String))
          requires S:String =/=String ""
          [structural]
     rule writeChars(_, "") => .K
          [structural]

     rule writeString(Loc::SymLoc, S::String)
          => Computation(
               * tv(Loc, utype(pointerType(type(char))))
               := tv(ordChar(firstChar(S)), utype(char)))
               ~> writeString(Loc +bytes 1, butFirstChar(S))
          requires S =/=String ""
          [structural]
     rule writeString(Loc::SymLoc, "")
          => Computation(
               * tv(Loc, utype(pointerType(type(char))))
               := tv(0, utype(char)))
          [structural]

     rule writeWChars(Loc::SymLoc, ListItem(N:Int) S:List)
          => Computation(
               * tv(Loc, utype(pointerType(type(cfg:wcharut))))
               := tv(N, utype(cfg:wcharut)))
               ~> writeWChars(Loc +bytes byteSizeofType(type(cfg:wcharut)), S)
          [structural]
     rule writeWChars(_, .List) => .K
          [structural]

     rule writeWString(Loc::SymLoc, ListItem(N:Int) S:List)
          => Computation(
               * tv(Loc, utype(pointerType(type(cfg:wcharut))))
               := tv(N, utype(cfg:wcharut)))
               ~> writeWString(Loc +bytes byteSizeofType(type(cfg:wcharut)), S)
          [structural]
     rule writeWString(Loc::SymLoc, .List)
          => Computation(
               * tv(Loc, utype(pointerType(type(cfg:wcharut))))
               := tv(0, utype(cfg:wcharut)))
          [structural]

endmodule
