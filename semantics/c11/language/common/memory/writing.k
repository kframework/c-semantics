module C-MEMORY-WRITING-SYNTAX
     imports BASIC-K
     imports INT-SYNTAX
     imports STRING-SYNTAX
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     // location, value
     syntax KItem ::= write(SymLoc, CValue, Type)
     syntax KItem ::= init(SymLoc, CValue, Type)

     // Either buffered or unbuffered depending on whether we're executing.
     syntax KItem ::= writeBytes(SymLoc, List, Type)
     syntax KItem ::= initBytes(SymLoc, List)

     syntax List ::= explodeToBits(List) [function]

     // TODO(chathhorn): For trans/symbolic-value.k
     syntax List ::= splitBytes(RValue) [function, klabel(splitBytesC)]

     // No null terminator.
     syntax KItem ::= writeChars(SymLoc, String)
     // Null terminates.
     syntax KItem ::= writeString(SymLoc, String)
     syntax KItem ::= initString(SymLoc, String)

     syntax KItem ::= writeWChars(SymLoc, List)
     syntax KItem ::= writeWString(SymLoc, List)
     syntax KItem ::= initWString(SymLoc, List)
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
     rule write(Loc:SymLoc, V:CValue, T:Type) => writeSpecific(Loc, V, T, false)
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool notBool isConstType(T)
          [structural]
     // Write global, shared data, or "allocated" duration.
     rule write(Loc:SymLoc, V:CValue, T:Type) => writeSpecific(Loc, V, T, false)
          requires (isStaticDuration(Loc) orBool isAllocatedDuration(Loc))
               andBool notBool isConstType(T)
               andBool notBool isStringLoc(Loc)
               andBool notBool isLinkerLoc(Loc)
          [ndtrans]
     rule write(Loc:SymLoc, V:CValue, T:Type) => writeSpecific(Loc, V, T, false)
          requires isNativeLoc(Loc)
          [ndtrans]
     rule (.K => CV("CMW2", "Trying to write through a const lvalue.") )
          ~> write(_, _, T:Type)
          requires isConstType(T)
          [structural]
     rule (.K => UNDEF("CMW1", "Trying to modify a string literal."))
          ~> write(Loc:SymLoc, _, _)
          requires isStringLoc(Loc)
          [structural]

     rule init(Loc:SymLoc, V:CValue, T:Type) => writeSpecific(Loc, V, T, true)
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
          [structural]
     rule init(Loc:SymLoc, V:CValue, T:Type) => writeSpecific(Loc, V, T, true)
          requires (isStaticDuration(Loc) orBool isAllocatedDuration(Loc))
               andBool notBool isLinkerLoc(Loc)
          [ndtrans]

     syntax KItem ::= writeSpecific(SymLoc, CValue, Type, Bool)
     rule <k> writeSpecific(Loc::SymLoc, V::CValue, T::Type, IsInit::Bool)
               => updateEffectiveType(Loc)
               ~> makePaddingUnknown(base(Loc), bitOffset(Loc), getEffectiveType(base(Loc)))
               ~> writeSpecific'(Loc, stripLastAccessType(V), T, IsInit)
          ...</k>
          <mem> Mem::Map </mem>
          requires base(Loc) in_keys(Mem)
     rule <k> writeSpecific(Loc::SymLoc, V::CValue, T::Type, IsInit::Bool)
               => writeSpecific'(Loc, stripLastAccessType(V), T, IsInit)
          ...</k>
          <mem> Mem::Map </mem>
          requires notBool (base(Loc) in_keys(Mem))

     syntax KItem ::= "writeSpecific'" "(" SymLoc "," CValue "," Type "," Bool ")"
     rule writeSpecific'(Loc::SymLoc, V::CValue, T::Type, false)
          => writeBytes(Loc, splitBytes(tv(V, utype(T))), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool (notBool isBitfieldType(T))
          [structural]
     rule writeSpecific'(Loc::SymLoc, V::CValue, T::Type, true)
          => initBytes(Loc, splitBytes(tv(V, utype(T))))
          requires (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool (notBool isBitfieldType(T))
          [structural]
     rule (.K => readBytesForWriting(Loc, (bitOffsetIntoLastByte(Loc) +Int bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte, .List))
          ~> writeSpecific'(Loc::SymLoc, _, T::Type, _)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0) orBool isBitfieldType(T)
          [structural]
     rule dataList(Bytes::List) ~> writeSpecific'(Loc::SymLoc, I:Int, T::Type, IsInit::Bool)
          => dataList(Bytes) ~> writeSpecific'(Loc, justBits(I, utype(T)), T, IsInit)
          requires I <Int 0
          [structural]
     rule dataList(Bytes::List) ~> writeSpecific'(Loc::SymLoc, V:Int, T::Type, false)
          => writeBytes(Loc, calculateNewBytes(piece(V, bitSizeofType(T)), Bytes, bitOffsetIntoLastByte(Loc)), T)
          requires V >=Int 0
          [structural]
     rule dataList(Bytes::List) ~> writeSpecific'(Loc::SymLoc, V:Int, T::Type, true)
          => initBytes(Loc, calculateNewBytes(piece(V, bitSizeofType(T)), Bytes, bitOffsetIntoLastByte(Loc)))
          requires V >=Int 0
          [structural]
     rule dataList(Bytes::List) ~> writeSpecific'(Loc::SymLoc, V:Pieces, T::Type, false)
          => writeBytes(Loc, calculateNewBytes(piece(V, bitSizeofType(T)), Bytes, bitOffsetIntoLastByte(Loc)), T)
          [structural]
     rule dataList(Bytes::List) ~> writeSpecific'(Loc::SymLoc, V:Pieces, T::Type, true)
          => initBytes(Loc, calculateNewBytes(piece(V, bitSizeofType(T)), Bytes, bitOffsetIntoLastByte(Loc)))
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
          => makeStructUnknown(loc(Base, Offset /Int cfg:bitsPerByte), getFields(T), 0)
          ~> makeStructUnionUnknown(Base, Offset +Int floorBitOffset(RelOffset, T), RelOffset -Int floorBitOffset(RelOffset, T), getFieldTypeAtOffset(RelOffset, T))
     rule makeStructUnionUnknown(Base::SymBase, Offset::Int, RelOffset::Int, T:UnionType)
          => makeUnionUnknown(loc(Base, Offset /Int cfg:bitsPerByte), getActiveVariant(T), byteSizeofType(T))
          ~> makeStructUnionUnknown(Base, Offset, RelOffset, getActiveVariant(T))
     rule makeStructUnionUnknown(_, _, _, _) => .K [owise]

     // Flag unknown from (&union + sizeof union.F) to (&union + sizeof union).
     rule (.K => readBytesForWriting(Loc +bytes byteSizeofType(T), Sz -Int byteSizeofType(T), .List))
          ~> makeUnionUnknown(Loc::SymLoc, T::Type, Sz::Int)
          requires Sz >Int byteSizeofType(T) andBool notBool isNoType(T)
          [structural]
     rule dataList(Bytes::List) ~> makeUnionUnknown(Loc::SymLoc, T::Type, _)
          => initBytes(Loc +bytes byteSizeofType(T), makeUnknownBytes(Bytes))
          [structural]
     rule makeUnionUnknown(_, T::Type, Sz::Int) => .K
          requires Sz <=Int byteSizeofType(T) orBool isNoType(T)
          [structural]

     rule (.K => readBytesForWriting(Loc +bytes I, 1, .List))
          ~> makeStructUnknown(Loc::SymLoc, fieldInfo(_, Sz::Int, _, _, _) #as Fields::FieldInfo, I::Int)
          requires isPaddingOffset(I, Fields) andBool I *Int cfg:bitsPerByte <Int Sz
     rule (dataList(Bytes::List) => initBytes(Loc +bytes I, makeUnknownBytes(Bytes)))
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

     syntax List ::= calculateNewBytes(Bits, List, Int) [function]
     rule calculateNewBytes(N::Bits, L:List, Offset::Int)
          => calculateNewBytes-aux(explodeToBits(ListItem(N)), explodeToBits(L), .List, Offset)

     syntax List ::= "calculateNewBytes-aux" "(" List "," List "," List "," Int ")" [function]
     rule calculateNewBytes-aux(
               L::List,
               ListItem(piece(N::BitValue, 1)) L'::List,
               Result::List, Offset::Int)
          => calculateNewBytes-aux(
               L,
               L',
               Result ListItem(piece(N, 1)), Offset -Int 1)
          requires Offset >Int 0
     rule calculateNewBytes-aux(
               ListItem(piece(N::BitValue, 1)) L::List,
               ListItem(piece(_, 1)) L'::List,
               Result::List, 0)
          => calculateNewBytes-aux(
               L,
               L',
               Result ListItem(piece(N, 1)), 0)
     rule calculateNewBytes-aux(.List, L::List, Result::List, 0)
          => joinBitsToBytes(Result L)

     syntax List ::= joinBitsToBytes(List) [function]
     rule joinBitsToBytes((ListItem(piece(N::BitValue, Len:Int)) ListItem(piece(M::BitValue, 1))
               => ListItem(piece(N, Len) bit:: piece(M, 1))) _::List)
          requires Len <Int cfg:bitsPerByte
     rule joinBitsToBytes(ListItem(piece(N::BitValue, Len:Int)) L:List)
          => ListItem(piece(N, Len)) joinBitsToBytes(L)
          requires Len ==Int cfg:bitsPerByte
     rule joinBitsToBytes(.List) => .List

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
     rule splinter(N::BitValue, Len::Int) => splinter-aux(N, Len, 0)

     syntax List ::= "splinter-aux" "(" BitValue "," Int "," Int ")" [function]
     rule splinter-aux(_, Len::Int, Len) => .List
     rule splinter-aux(N::BitValue, Len::Int, Pos::Int)
          => ListItem(encode(N, Pos, Pos +Int 1))
               splinter-aux(N, Len, Pos +Int 1)
          requires Pos <Int Len

     // this general rule is useful for unknowns, abstracts, etc
     rule splitBytes(tv(N:BitValue, T:UType))
          => ListItem(piece(N, cfg:bitsPerByte))
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
          => splitStructBytes(L, T, byteSizeofType(T))

     syntax List ::= makeUnknownBytes(List) [function]
     rule makeUnknownBytes(ListItem(piece(I:Int, PieceLen:Int)) L::List)
          => ListItem(piece(unknown(I), PieceLen)) makeUnknownBytes(L)
     rule makeUnknownBytes(ListItem(B::Bits) L::List)
          => ListItem(B) makeUnknownBytes(L) [owise]
     rule makeUnknownBytes(.List) => .List

     syntax List ::= splitStructBytes(List, StructOrUnionUType, Int) [function]
     rule splitStructBytes(ListItem(piece(N::BitValue, PieceLen:Int)) Rest:List,
               T::StructOrUnionUType, Len:Int)
          => ListItem(piece(N, PieceLen)) splitStructBytes(Rest, T, Len -Int 1)
          requires PieceLen ==Int cfg:bitsPerByte
               andBool Len >Int 0
               andBool (notBool isPaddingOffset(byteSizeofType(T) -Int Len, getFields(T))
                    orBool isUnknown(N))
     rule splitStructBytes(ListItem(piece((N::BitValue => unknown(#if isInt(N) #then N #else 0 #fi)), _)) _,
               T::StructOrUnionUType, Len::Int)
          requires isPaddingOffset(byteSizeofType(T) -Int Len, getFields(T))
               andBool notBool isUnknown(N)
     rule splitStructBytes(_, _, 0) => .List

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

     rule initString(Loc::SymLoc, S::String)
          => Initializer(
               * tv(Loc, utype(pointerType(type(char))))
                    := tv(ordChar(firstChar(S)), utype(char)))
               ~> initString(Loc +bytes 1, butFirstChar(S))
          requires S =/=String ""
          [structural]
     rule initString(Loc::SymLoc, "")
          => Initializer(
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

     rule initWString(Loc::SymLoc, ListItem(N:Int) S:List)
          => Initializer(
               * tv(Loc, utype(pointerType(type(cfg:wcharut))))
                    := tv(N, utype(cfg:wcharut)))
               ~> initWString(Loc +bytes byteSizeofType(type(cfg:wcharut)), S)
          [structural]
     rule initWString(Loc::SymLoc, .List)
          => Initializer(
               * tv(Loc, utype(pointerType(type(cfg:wcharut))))
                    := tv(0, utype(cfg:wcharut)))
          [structural]

endmodule
