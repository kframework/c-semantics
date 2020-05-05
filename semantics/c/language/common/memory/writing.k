module C-MEMORY-WRITING-SYNTAX
     imports BASIC-K
     imports INT-SYNTAX
     imports STRING-SYNTAX
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS
     imports BITS-SYNTAX

     // location, value
     syntax KItem ::= write(SymLoc, CValue, Type)
     syntax KItem ::= init(SymLoc, CValue, Type)

     // Either buffered or unbuffered depending on whether we're executing.
     syntax KItem ::= writeBytes(SymLoc, List)
     syntax KItem ::= writeBytesFill(SymLoc, Int, Bits)
     syntax KItem ::= initBytes(SymLoc, List)
     syntax KItem ::= initBytesFill(SymLoc, Int, Bits)

     // Traps padding and unnamed bit-fields in a struct or union.
     syntax KItem ::= initPadding(SymLoc, Type, CId)

     syntax KItem ::= setBytes(SymLoc, KItem, Int) [strict(2)]

     // TODO(chathhorn): For trans/symbolic-value.k
     syntax List ::= splitBytes(RValue) [function, klabel(splitBytesC)]

     syntax List ::= splitPartialBytes(RValue) [function, klabel(splitPartialBytesC)]
     syntax List ::= partialBytesToBytes(List) [function, klabel(partialBytesToBytesC)]

     // No null terminator.
     syntax KItem ::= writeChars(SymLoc, String)
     // Null terminates.
     syntax KItem ::= writeString(SymLoc, String)
     syntax KItem ::= initString(SymLoc, String)

     syntax KItem ::= writeWChars(SymLoc, List)
     syntax KItem ::= writeWString(SymLoc, List)
     syntax KItem ::= initWString(SymLoc, List)

     syntax Quals ::= getQualsAtOffset(List) [function]
     syntax Quals ::= getQualsAtOffset(EffectiveType, Int) [function, klabel(getQualsAtOffset2)]

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
               ~> checkVolatile(Loc, getEffectiveType(base(Loc)), T)
               ~> writeSpecific'(Loc, stripLastAccessType(V), T, IsInit)
          ...</k>
          <mem> Mem::Map </mem>
          requires base(Loc) in_keys(Mem)
     rule <k> writeSpecific(Loc::SymLoc, V::CValue, T::Type, IsInit::Bool)
               => writeSpecific'(Loc, stripLastAccessType(V), T, IsInit)
          ...</k>
          <mem> Mem::Map </mem>
          requires notBool (base(Loc) in_keys(Mem))

     syntax KItem ::= checkVolatile(SymLoc, KItem, Type) [strict(2)]
     rule (.K => UNDEF("EIO4", "Trying to modify an object declared with volatile type through a non-volatile lvalue."))
          ~> checkVolatile(Loc::SymLoc, ObjT:EffectiveType, T::Type)
          requires notBool isVolatileType(T)
               andBool (Volatile() inQuals getQualsAtOffset(ObjT, offset(Loc)))
          [structural]
     rule checkVolatile(Loc::SymLoc, ObjT:EffectiveType, T::Type) => .K
          requires isVolatileType(T)
               orBool notBool (Volatile() inQuals getQualsAtOffset(ObjT, offset(Loc)))
          [structural]

     syntax KItem ::= "writeSpecific'" "(" SymLoc "," CValue "," Type "," Bool ")"
     rule writeSpecific'(Loc::SymLoc, V::CValue, T::Type, false)
          => writeBytes(Loc, splitBytes(tv(V, utype(T))))
          requires (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool (bitOffset(Loc) %Int cfg:bitsPerByte ==Int 0)
          [structural]
     rule writeSpecific'(Loc::SymLoc, V::CValue, T::Type, true)
          => initBytes(Loc, splitBytes(tv(V, utype(T))))
          requires (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool (bitOffset(Loc) %Int cfg:bitsPerByte ==Int 0)
          [structural]
     rule writeSpecific'(Loc::SymLoc, V::CValue, T::Type, IsInit::Bool)
          => writeUnalignedBits(Loc, toBits(V, T), IsInit)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0)
               orBool (bitOffset(Loc) %Int cfg:bitsPerByte =/=Int 0)
          [structural]

     syntax List ::= toBits(CValue, Type) [function]
     rule toBits(V:Int, T::Type) => explodeToBits(ListItem(piece(justBits(V, utype(T)), bitSizeofType(T))))
     rule toBits(V:Pieces, T::Type) => explodeToBits(ListItem(piece(V, bitSizeofType(T))))

     syntax KItem ::= makeInactiveVariantUnknown(SymLoc, Type, Int)
                    | makePaddingUnknown(SymBase, Int, KItem) [strict(3)]
     syntax K ::= makeStructUnionUnknown(SymBase, Int, Int, Type) [function]

     rule makePaddingUnknown(Base::SymBase, Offset::Int, EffT:Type)
          => makeStructUnionUnknown(Base, 0, Offset, EffT)
     rule makePaddingUnknown(Base::SymBase, Offset::Int, dynamicType(EffT::Type))
          => makeStructUnionUnknown(Base, 0, Offset, EffT)

     rule makeStructUnionUnknown(Base::SymBase, Offset::Int, RelOffset::Int, t(... st: _:SimpleArrayType) #as T::Type)
          => makeStructUnionUnknown(Base, Offset +Int floorBitOffset(RelOffset, T),
               RelOffset %Int bitSizeofType(innerType(T)), getElementType(RelOffset, T))
     rule makeStructUnionUnknown(Base::SymBase, Offset::Int, RelOffset::Int, t(... st: structType(_)) #as T::Type)
          => initStructPadding(loc(Base, Offset /Int cfg:bitsPerByte), getFields(T), false)
          ~> initFieldPadding(loc(Base, Offset /Int cfg:bitsPerByte), T, getFieldAtOffset(RelOffset, T), false)
          ~> makeStructUnionUnknown(Base, Offset +Int floorBitOffset(RelOffset, T), RelOffset -Int floorBitOffset(RelOffset, T), getFieldTypeAtOffset(RelOffset, T))
     rule makeStructUnionUnknown(Base::SymBase, Offset::Int, RelOffset::Int, t(... st: unionType(_)) #as T::Type)
          => initStructPadding(loc(Base, Offset /Int cfg:bitsPerByte), getFields(T), false)
          ~> initFieldPadding(loc(Base, Offset /Int cfg:bitsPerByte), T, getFieldAtOffset(RelOffset, T), false)
          ~> makeInactiveVariantUnknown(loc(Base, Offset /Int cfg:bitsPerByte), getActiveVariant(T), byteSizeofType(T))
          ~> makeStructUnionUnknown(Base, Offset, RelOffset, getActiveVariant(T))
     rule makeStructUnionUnknown(_, _, _, _) => .K [owise]

     rule initPadding(Loc::SymLoc, T::Type, F::CId)
          => initStructPadding(Loc, getFields(T), true)
          ~> initFieldPadding(Loc, T, F, true)
          ~> trapUnnamed(Loc, findUnnamedBitfields(T), T)

     syntax K ::= trapUnnamed(SymLoc, List, Type) [function]
     rule trapUnnamed(Loc::SymLoc, ListItem(F::CId) Fs::List, T::Type)
          => initPaddingBits(Loc +bits findFieldOffset(F, T), bitSizeofType(findFieldType(F, T)), true)
          ~> trapUnnamed(Loc, Fs, T)
     rule trapUnnamed(_, .List, _) => .K

     // Flag unknown from (&union + sizeof union.F) to (&union + sizeof union).
     rule (.K => readBytesForWriting(Loc +bytes byteSizeofType(T), Sz -Int byteSizeofType(T)))
          ~> makeInactiveVariantUnknown(Loc::SymLoc, T::Type, Sz::Int)
          requires Sz >Int byteSizeofType(T) andBool notBool isNoType(T)
          [structural]
     rule dataList(Bytes::List) ~> makeInactiveVariantUnknown(Loc::SymLoc, T::Type, _)
          => initBytes(Loc +bytes byteSizeofType(T), makeUnknownBytes(Bytes))
          [structural]
     rule makeInactiveVariantUnknown(_, T::Type, Sz::Int) => .K
          requires Sz <=Int byteSizeofType(T) orBool isNoType(T)
          [structural]

     syntax KItem ::= initStructPadding(SymLoc, FieldInfo, Bool)
     rule (.K => initPaddingByte(Loc +bits I, Trap))
          ~> initStructPadding(Loc::SymLoc, fieldInfo(_, Sz::Int, _, _, (SetItem(I::Int) => .Set) _), Trap::Bool)
     rule initStructPadding(_, fieldInfo(_, _, _, _, .Set), _) => .K

     syntax K ::= initFieldPadding(SymLoc, Type, CId, Bool) [function]
     rule initFieldPadding(Loc::SymLoc, T::Type, F::CId, Trap::Bool)
          => initPaddingByte(Loc +bits (getFieldOffset(F, T) +Int bitSizeofType(getFieldType(F, T))), Trap)
          requires isBitfieldType(getFieldType(F, T))
               andBool (getFieldOffset(F, T) +Int bitSizeofType(getFieldType(F, T))
                    =/=Int ceilBitOffset(getFieldOffset(F, T), T))
     rule initFieldPadding(_, _, _, _) => .K [owise]

     // Set the bits at a certain offset into a byte to either unknown or trap.
     // Loc (with bit offset set), true for trap, false for unknown.
     syntax KItem ::= initPaddingByte(SymLoc, Bool)
     rule initPaddingByte(Loc::SymLoc, Trap::Bool)
          => initPaddingBits(Loc, cfg:bitsPerByte -Int bitOffsetIntoLastByte(Loc), Trap)

     // Loc (with bit offset set), number of bits, true for trap, false for unknown
     syntax KItem ::= initPaddingBits(SymLoc, Int, Bool)
     rule (.K => readBytesForWriting(Loc, byteRange(Loc, N)))
          ~> initPaddingBits(Loc::SymLoc, N::Int, false)
     rule dataList(Bytes::List) ~> initPaddingBits(Loc::SymLoc, N::Int, _)
          => initBytes(Loc, joinBitsToBytes(
               calculateNewBits(
                    range(explodeToBits(makeUnknownBytes(Bytes)), bitOffsetIntoLastByte(Loc),
                         size(explodeToBits(Bytes)) -Int bitOffsetIntoLastByte(Loc) -Int N),
                    explodeToBits(Bytes),
                    bitOffsetIntoLastByte(Loc))
          ))
     rule initPaddingBits(Loc::SymLoc, N::Int, true)
          => writeUnalignedBits(Loc, explodeToBits(ListItem(piece(trap, N))), true)

     syntax KItem ::= ooga(Int, Int, List, List, List, List)

     // Loc, list of bit values, true for init
     syntax KItem ::= writeUnalignedBits(SymLoc, List, Bool)
     rule (.K => readBytesForWriting(Loc, byteRange(Loc, size(Bits))))
          ~> writeUnalignedBits(Loc::SymLoc, Bits::List, _)
     rule dataList(Bytes::List) ~> writeUnalignedBits(Loc::SymLoc, Bits::List, false)
          => writeBytes(Loc, joinBitsToBytes(calculateNewBits(Bits, explodeToBits(Bytes), bitOffsetIntoLastByte(Loc))))
     rule dataList(Bytes::List) ~> writeUnalignedBits(Loc::SymLoc, Bits::List, true)
          => initBytes(Loc, joinBitsToBytes(calculateNewBits(Bits, explodeToBits(Bytes), bitOffsetIntoLastByte(Loc))))

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

     syntax List ::= calculateNewBits(List, List, Int) [function]
     rule calculateNewBits(L::List, ListItem(piece(N::BitValue, 1)) L'::List, Offset::Int)
          => ListItem(piece(N, 1)) calculateNewBits(L, L', Offset -Int 1)
          requires Offset >Int 0
     rule calculateNewBits(ListItem(piece(N::BitValue, 1)) L::List, ListItem(piece(_, 1)) L'::List, 0)
          => ListItem(piece(N, 1)) calculateNewBits(L, L', 0)
     rule calculateNewBits(.List, L::List, 0) => L

     syntax List ::= joinBitsToBytes(List) [function]
     rule joinBitsToBytes((ListItem(piece(N::BitValue, Len:Int)) ListItem(piece(M::BitValue, 1))
               => ListItem(piece(N, Len) bit:: piece(M, 1))) _::List)
          requires Len <Int cfg:bitsPerByte
     rule joinBitsToBytes(ListItem(piece(N::BitValue, Len:Int)) L:List)
          => ListItem(piece(N, Len)) joinBitsToBytes(L)
          requires Len ==Int cfg:bitsPerByte
     rule joinBitsToBytes(.List) => .List

     rule splitBytes(tv(V:Encodable, T:UType))
          => splitToBytes(encode(V, 0, bitSizeofType(T)))
          requires notBool isUnknown(V)
     rule splitBytes(tv(V:EncodedPtr, T:UType))
          => splitToBytes(piece(V, bitSizeofType(T)))
     rule splitBytes(tv(V:EncodedValue, T:UType))
          => splitToBytes(piece(V, bitSizeofType(T)))
     rule splitBytes(tv(unknown(I:Int), T::UType))
          => makeUnknownBytes(splitBytes(tv(I, T)))
     rule splitBytes(tv(agg(L:List), structOrUnionUType #as T::UType))
          => splitStructBytes(L, T, byteSizeofType(T))

     rule splitPartialBytes(tv(V:Encodable, T:UType))
          => splitToPartialBytes(encode(V, 0, bitSizeofType(T)))
          requires notBool isUnknown(V)
     rule splitPartialBytes(tv(V:EncodedPtr, T:UType))
          => splitToPartialBytes(piece(V, bitSizeofType(T)))
     rule splitPartialBytes(tv(V:EncodedValue, T:UType))
          => splitToPartialBytes(piece(V, bitSizeofType(T)))
     rule splitPartialBytes(tv(unknown(I:Int), T::UType))
          => makeUnknownBytes(splitPartialBytes(tv(I, T)))
     rule splitPartialBytes(tv(agg(L:List), structOrUnionUType #as T::UType))
          => splitStructPartialBytes(L, T, bitSizeofType(T))

     rule partialBytesToBytes(L:List) => #partialBytesToBytes(L, piece(0, 0))

     syntax Int ::= byteMask() [function]
     rule byteMask() => (1 <<Int cfg:bitsPerByte) -Int 1

     syntax List ::= #partialBytesToBytes(List, Bits) [function]
     rule #partialBytesToBytes(L:List, piece(Previous:Int, PreviousLen:Int))
          => ListItem(piece(Previous &Int byteMask(), cfg:bitsPerByte))
             #partialBytesToBytes(L, piece(Previous >>Int cfg:bitsPerByte, PreviousLen -Int cfg:bitsPerByte))
          requires PreviousLen >=Int cfg:bitsPerByte
     rule #partialBytesToBytes(ListItem(piece(Item:BitValue, _:Int) #as Current:Bits) L:List, piece(_:Int, PreviousLen:Int) #as Previous::Bits)
          => #partialBytesToBytes(L, Previous bit:: Current)
          requires PreviousLen <Int cfg:bitsPerByte andBool isInt(Item)
     rule #partialBytesToBytes(ListItem(piece(Item:BitValue, PieceLen:Int) #as Current::Bits) L:List, piece(Previous:Int, PreviousLen:Int))
          => ListItem(Current) #partialBytesToBytes(L, piece(0, 0))
          requires PreviousLen ==Int 0 andBool PieceLen ==Int cfg:bitsPerByte andBool notBool isInt(Item)
     rule #partialBytesToBytes(.List, piece(_, 0)) => .List

     syntax List ::= makeUnknownBytes(List) [function]
     rule makeUnknownBytes(ListItem(piece(I:Int, PieceLen:Int)) L::List)
          => ListItem(piece(unknown(I), PieceLen)) makeUnknownBytes(L)
     rule makeUnknownBytes(ListItem(B::Bits) L::List)
          => ListItem(B) makeUnknownBytes(L) [owise]
     rule makeUnknownBytes(.List) => .List

     syntax List ::= splitStructBytes(List, UType, Int) [function]
     rule splitStructBytes(ListItem(piece(N::BitValue, PieceLen:Int)) Rest:List,
               T::UType, Len:Int)
          => ListItem(piece(N, PieceLen)) splitStructBytes(Rest, T, Len -Int 1)
          requires PieceLen ==Int cfg:bitsPerByte
               andBool Len >Int 0
               andBool (notBool isPaddingOffset(byteSizeofType(T) -Int Len, getFields(T))
                    orBool isUnknown(N))
     rule splitStructBytes(ListItem(piece((N::BitValue => unknown(#if isInt(N) #then N #else 0 #fi)), _)) _,
               T::UType, Len::Int)
          requires isPaddingOffset(byteSizeofType(T) -Int Len, getFields(T))
               andBool notBool isUnknown(N)
     rule splitStructBytes(_, _, 0) => .List

     syntax List ::= splitStructPartialBytes(List, UType, Int) [function]
     rule splitStructPartialBytes(ListItem(piece(N::BitValue, PieceLen:Int)) Rest:List,
               T::UType, Len:Int)
          => ListItem(piece(N, PieceLen)) splitStructPartialBytes(Rest, T, Len -Int PieceLen)
          requires PieceLen <=Int cfg:bitsPerByte
               andBool Len >Int 0
               andBool (notBool isPaddingOffset(byteSizeofType(T) -Int Len, getFields(T))
                    orBool isUnknown(N))
     rule splitStructPartialBytes(ListItem(piece((N::BitValue => unknown(#if isInt(N) #then N #else 0 #fi)), _)) _,
               T::UType, Len::Int)
          requires isPaddingOffset(byteSizeofType(T) -Int Len, getFields(T))
               andBool notBool isUnknown(N)
     rule splitStructPartialBytes(_, _, 0) => .List

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

     rule getQualsAtOffset(dynamicType(T::Type), Offset::Int) => getQualsAtOffset(T, Offset)
     rule getQualsAtOffset(T:Type, Offset::Int)
          => getQualsAtOffset(getTypesAtOffset(T, Offset *Int cfg:bitsPerByte))
     rule getQualsAtOffset(_, _) => noQuals [owise]

     rule getQualsAtOffset(ListItem(T:Type) Ts:List)
          => getQualifiers(T) +Quals getQualsAtOffset(Ts)
     rule getQualsAtOffset(.List) => noQuals

endmodule
