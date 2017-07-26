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

     syntax List ::= explodeToBits(List) [function]

     // TODO(chathhorn): For trans/symbolic-value.k
     syntax DataList ::= splitBytes(RValue) [function, klabel(splitBytesC)]

     // No null terminator.
     syntax KItem ::= writeChars(SymLoc, String)
     // Null terminates.
     syntax KItem ::= writeString(SymLoc, String)

     syntax KItem ::= writeWChars(SymLoc, List)
     syntax KItem ::= writeWString(SymLoc, List)

     syntax KItem ::= setEffectiveType(SymLoc, Type)
endmodule

module C-MEMORY-WRITING
     imports BOOL
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports COMMON-SORTS
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports FLOAT-SYNTAX
     imports INT
     imports K-EQUAL
     imports K-REFLECTION
     imports LIBC-SYNTAX
     imports MAP
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
     rule <k> write(loc((Base:SymBase => Base'), _), _, _) ...</k>
          <linkings>... Base |-> Base':SymBase ...</linkings>
          [structural]
     rule <k> write(loc((Base:SymBase => Base'), _, _), _, _) ...</k>
          <linkings>... Base |-> Base':SymBase ...</linkings>
          [structural]
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

     syntax KItem ::= writeSpecific(SymLoc, CValue, Type) [function]
     rule writeSpecific(Loc::SymLoc, V::CValue, T::Type)
          => updateEffectiveType(Loc)
          ~> writeSpecific'(Loc, stripLastAccessType(V), T)

     syntax KItem ::= "writeSpecific'" "(" SymLoc "," CValue "," Type ")"
     rule writeSpecific'(Loc:SymLoc, V:CValue, T:Type)
          => writeBytes(Loc, splitBytes(tv(V, utype(T))), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool (notBool isBitfieldType(T))
               andBool (notBool hasUnionMarker(Loc))
          [structural]

     syntax Set ::= keepUnion(Set) [function]
                  | stripUnion(Set) [function]

     rule keepUnion(.Set) => .Set
     rule keepUnion(SetItem(K:K) S:Set) =>
          #if (getKLabel(K) ==K #klabel(`fromUnion`))
          #then (SetItem(K) keepUnion(S))
          #else keepUnion(S)
          #fi

     rule stripUnion(.Set) => .Set
     rule stripUnion(SetItem(K:K) S:Set) =>
          #if (getKLabel(K) ==K #klabel(`fromUnion`))
          #then stripUnion(S)
          #else (SetItem(K) stripUnion(S))
          #fi

     rule (.K => makeUnknown(.K, keepUnion(S)))
          ~> writeSpecific'(
               loc(Base:SymBase, Offset:Int, S:Set => stripUnion(S)), _, _)
          requires hasUnionMarker(loc(Base, Offset, S))
          [structural]

     syntax KItem ::= makeUnionUnknown(SymLoc, CId, FieldInfo)
                    | makeStructUnknown(SymLoc, CId, FieldInfo, Int)
                    | makeUnknown(K, Set)

     rule makeUnknown(.K, .Set) => .K
          [structural]
     rule makeUnknown(.K, SetItem(K:K) S:Set)
          => makeUnknown(K, S)
          [structural]
     // unions
     rule makeUnknown(fromUnion(UnionLoc:SymLoc, F:CId, Fields:FieldInfo, true),
               S:Set)
          => allowInit(makeUnionUnknown(UnionLoc, F, Fields))
          ~> makeUnknown(.K, S)
          [structural]
     // structs
     rule makeUnknown(fromUnion(StructLoc:SymLoc, F:CId, Fields:FieldInfo, false),
               S:Set)
          => allowInit(makeStructUnknown(StructLoc, F, Fields, 0))
          ~> makeUnknown(.K, S)
 
     // Flag unknown from (&union + sizeof union.F) to (&union + sizeof union).
     // TODO(chathhorn): breaks open a lot of abstractions.
     rule <k> makeUnionUnknown(Loc::SymLoc, F:CId, fieldInfo(L::List, _,
               F |-> T::Type _, _, _))
          => writeBytes(resolveLinking(Loc, Linkings) +bytes byteSizeofType(T),
               dataList(times(
                    maxByteSizeofList(L) -Int byteSizeofType(T),
                    piece(unknown(max(utype(signed-char))), cfg:bitsPerByte))), T)
          ...</k>
          <linkings> Linkings::Map </linkings>
          requires maxByteSizeofList(L) >Int byteSizeofType(T)
          [structural]
     rule makeUnionUnknown(_, F::CId, fieldInfo(L::List, _, F |-> T::Type _, _, _)) => .K
          requires maxByteSizeofList(L) <=Int byteSizeofType(T)
          [structural]

     rule <k> makeStructUnknown(Loc::SymLoc, F::CId, fieldInfo(L::List, N::Int, 
               F |-> T::Type M::Map, Offsets::Map, PaddingOffs::Set), I::Int)
          => writeBytes(resolveLinking(Loc, Linkings) +bytes I,
               dataList(ListItem(piece(unknown(max(utype(signed-char))), cfg:bitsPerByte))), T)
          ~> makeStructUnknown(Loc, F, fieldInfo(L, N, F |-> T M, Offsets, PaddingOffs), I +Int 1)
          ...</k>
          <linkings> Linkings::Map </linkings>
          requires isPaddingOffset(I, fieldInfo(L, N, F |-> T M, Offsets, PaddingOffs))
               andBool I *Int cfg:bitsPerByte <Int N
     rule makeStructUnknown(Loc::SymLoc, F::CId, fieldInfo(L::List, N::Int, 
               Types::Map, Offsets::Map, PaddingOffs::Set), I::Int)
          => makeStructUnknown(Loc, F, fieldInfo(L, N, Types, Offsets, PaddingOffs), I +Int 1)
          requires notBool isPaddingOffset(I, fieldInfo(L, N, Types, Offsets, PaddingOffs))
               andBool I *Int cfg:bitsPerByte <Int N
     rule makeStructUnknown(_, _, fieldInfo(_, N::Int, _, _, _), I::Int)
          => .K
          requires I *Int cfg:bitsPerByte >=Int N



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

     rule writeSpecific'(Loc::SymLoc, I:Int, T::Type)
          => writeSpecific'(Loc, justBits(I, utype(T)), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0
               orBool isBitfieldType(T))
               andBool (I <Int 0)
          [structural]

     rule writeSpecific'(Loc::SymLoc, V:Int, T::Type)
          => writeBytes(Loc,
               calculateNewBytes(piece(V, bitSizeofType(T)),
                    readBytesForWriting(stripProv(Loc), (getBitOffset(Loc) +Int bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte, .List, T), getBitOffset(Loc)), T)
          requires ((bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0)
                    orBool isBitfieldType(T))
               andBool notBool hasUnionMarker(Loc)
               andBool (V >=Int 0)
          [structural]
     rule writeSpecific'(Loc::SymLoc, V:Pieces, T::Type)
          => writeBytes(Loc,
               calculateNewBytes(piece(V, bitSizeofType(T)),
                    readBytesForWriting(stripProv(Loc), (getBitOffset(Loc) +Int bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte, .List, T), getBitOffset(Loc)), T)
          requires ((bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0)
               orBool (isBitfieldType(T) andBool notBool hasUnionMarker(Loc)))
          [structural]

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
          => makeUnknown(splitBytes(tv(I, T)))
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
     rule splitBytes(tv(agg(L:List), T::UType))
          => splitStructBytes(dataList(L), T,
               byteSizeofType(T))
          requires isStructOrUnionType(type(T))

     syntax KItem ::= makeUnknownAux(List, List) [function]
     rule makeUnknown(dataList(L::List)) => makeUnknownAux(L, .List)
     rule makeUnknownAux((ListItem(piece(I:Int, PieceLen:Int)) => .List) L::List, _:List (.List => ListItem(piece(unknown(I), PieceLen))))
     rule makeUnknownAux(.List, L::List) => dataList(L)
     rule makeUnknownAux((ListItem(B::Bits) => .List) L::List, _:List (.List => ListItem(B))) [owise]

     syntax DataList ::= splitStructBytes(K, UType, Int) [function]
     syntax DataList ::= #splitStructBytes(K, UType, Int, List)  [function]

     rule splitStructBytes(dataList(L:List), T::UType, Len:Int)
          => #splitStructBytes(dataList(L), T, Len, .List)
     rule #splitStructBytes(
          dataList(ListItem(piece(N::BitValue, PieceLen:Int)) Rest:List),
               T::UType, Len:Int, L:List)
          => #splitStructBytes(dataList(Rest), T, Len -Int 1,
               L ListItem(piece(N, PieceLen)))
          requires PieceLen ==Int cfg:bitsPerByte
               andBool Len >Int 0
               andBool (notBool isPaddingOffset(byteSizeofType(T) -Int Len, getFieldInfo(type(T)))
                    orBool isUnknown(N))
     rule #splitStructBytes(
          dataList(ListItem(piece((N::BitValue => unknown(#if isInt(N) #then N #else 0 #fi)), _)) _),
               T::UType, Len::Int, _)
          requires isPaddingOffset(byteSizeofType(T) -Int Len, getFieldInfo(type(T)))
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

     // Set the new effective type to a last-access type attached to the
     // lvalue, if it exists.
     syntax KItem ::= updateEffectiveType(SymLoc)
     rule updateEffectiveType(Loc::SymLoc) => setEffectiveType(stripProv(Loc), getObjectType(Loc))
          requires hasObjectType(Loc)
          [structural]
     rule updateEffectiveType(Loc::SymLoc) => .K
          requires notBool hasObjectType(Loc)
          [structural]

     rule <k> setEffectiveType(loc(Base::SymBase, _), T'::Type) => .K ...</k>
          <mem>... Base |-> object(T::Type => T', _, _) ...</mem>
          requires notBool isNoType(T)
          [structural]
     // Upgrade the effective type for a malloced region to an array.
     rule <k> setEffectiveType(loc(Base::SymBase, _), T'::Type) => .K ...</k>
          <mem>... Base |-> object(T::Type => type(arrayType(T', Len /Int byteSizeofType(T'))), Len::Int, _) ...</mem>
          requires isNoType(T) andBool notBool isNoType(T') andBool notBool isFlexibleType(T')
          [structural]
     rule <k> setEffectiveType(loc(Base::SymBase, _), T'::Type) => .K ...</k>
          <mem>... Base |-> object(T::Type, _, _) ...</mem>
          requires isNoType(T) andBool isNoType(T')
          [structural]
     // Also, set the length of the flexible array member for structs in a
     // malloced region.
     rule <k> setEffectiveType(loc(Base::SymBase, _), T'::Type) => .K ...</k>
          <mem>... Base |-> object(T::Type => lockFlexibleStruct(T', Len -Int byteSizeofType(T')), Len::Int, _) ...</mem>
          requires isNoType(T) andBool isFlexibleType(T')
          [structural]
     rule <k> setEffectiveType(Loc::SymLoc, _) => .K ...</k>
          <mem> Mem:Map </mem>
          requires notBool base(Loc) in_keys(Mem)
          [structural]

     syntax Bool ::= hasObjectType(SymLoc) [function]
     rule hasObjectType(loc(_, _, _:Set SetItem(objectType(_)))) => true
     rule hasObjectType(_) => false [owise]

     syntax Type ::= getObjectType(SymLoc) [function]
     rule getObjectType(loc(_, _, _:Set SetItem(objectType(T::Type)))) => T

endmodule
