module C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX

     // location, value
     syntax KItem ::= write(SymLoc, CValue, Type)

     // Either buffered or unbuffered depending on whether we're executing.
     syntax KItem ::= writeBytes(SymLoc, K, Type) [strict(2), klabel(writeBytes3)]

     syntax List ::= explodeToBits(List) [function]

     // TODO(chathhorn): For trans/symbolic-value.k
     syntax DataList ::= splitBytes(RValue) [function]

     syntax KItem ::= writeString(SymLoc, String)
     syntax KItem ::= writeWString(SymLoc, List)

     syntax KItem ::= setEffectiveType(SymLoc, Type)
endmodule

module C-MEMORY-WRITING
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

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
     rule <k> (.K => CV("CMW2", "Trying to write through a const lvalue.", "6.5.16.1:1") )
               ~> write(_, _, T:Type)
          ...</k>
          <initializing> false </initializing>
          requires isConstType(T)
          [structural]
     rule <k> (.K => UNDEF("CMW1", "Trying to modify a string literal.", "6.4.5:7, J.2:1 item 33"))
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
          => writeBytes(stripProv(Loc), splitBytes(tv(V, utype(T))), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool (isBitfieldType(T) =/=K true)
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

     rule (.K => makeUnionUnknown(.K, keepUnion(S)))
          ~> writeSpecific'(
               loc(Base:SymBase, Offset:Int, S:Set => stripUnion(S)), _, _)
          requires hasUnionMarker(loc(Base, Offset, S))
          [structural]

     syntax KItem ::= makeUnknown(SymLoc, CId, FieldInfo)
                    | makeUnionUnknown(K, Set)

     rule makeUnionUnknown(.K, .Set) => .K
          [structural]
     rule makeUnionUnknown(.K, SetItem(K:K) S:Set)
          => makeUnionUnknown(K, S)
          [structural]
     rule makeUnionUnknown(fromUnion(UnionLoc:SymLoc, F:CId, Fields:FieldInfo),
               S:Set)
          => allowInit(makeUnknown(UnionLoc, F, Fields))
          ~> makeUnionUnknown(.K, S)
          [structural]

     // Flag unknown from (&union + sizeof union.F) to (&union + sizeof union).
     // TODO(chathhorn): breaks open a lot of abstractions.
     rule makeUnknown(Loc:SymLoc, F:CId, fieldInfo(L:List, _,
               F |-> T::Type _, _))
          => writeBytes(stripProv(Loc) +bytes byteSizeofType(T),
               dataList(times(
                    maxByteSizeofList(L) -Int byteSizeofType(T),
                    piece(unknown(max(utype(signed-char))), cfg:bitsPerByte))), T)
          requires maxByteSizeofList(L) >Int byteSizeofType(T)
          [structural]
     rule makeUnknown(_, F:CId, fieldInfo(L:List, _, F |-> T:Type _, _)) => .K
          requires maxByteSizeofList(L) <=Int byteSizeofType(T)
          [structural]

     syntax Int ::= justBits(Int, UType) [function]
     syntax Int ::= "justBits-aux" "(" Int "," UType ")" [function]
     rule justBits(I::Int, _) => I
          requires I >=Int 0

     rule justBits(I::Int, T::UType) => justBits-aux(I, T)
          requires I <Int 0
     rule justBits-aux(I::Int, T::UType)
          => justBits-aux(I +Int max(T) +Int 1, T)
          requires I <Int 0
     // fixme sNat
     rule justBits-aux(N:Int, ut(_, bitfieldType(_, Len:Int)))
          => N +Int (1 <<Int (Len -Int 1))
          requires Len >Int 0 andBool N >=Int 0

     rule writeSpecific'(Loc::SymLoc, I:Int, T::Type)
          => writeSpecific'(Loc, justBits(I, utype(T)), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0
               orBool isBitfieldType(T))
               andBool (I <Int 0)
          [structural]

     rule writeSpecific'(Loc::SymLoc, V:Int, T::Type)
          => writeBytes(stripProv(Loc),
               calculateNewBytes(piece(V, bitSizeofType(T)),
                    readBytesForWriting(stripProv(Loc), (getBitOffset(Loc) +Int bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte, .List, T), getBitOffset(Loc)), T)
          requires ((bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0)
               orBool (isBitfieldType(T) andBool notBool hasUnionMarker(Loc)))
               andBool (V >=Int 0)
          [structural]

     syntax KItem ::= calculateNewBytes(Bits, K, Int)
          [latex(\terminal{calcNewBytes(}{#1}, {#2}\terminal{)}), strict(2)]

     rule calculateNewBytes(N:Bits, dataList(L:List), Offset:Int)
          => calculateNewBytes-aux(dataList(explodeToBits(ListItem(N))),
               dataList(explodeToBits(L)), .List, Offset)
          [structural]

     syntax KItem ::= "calculateNewBytes-aux" "(" DataList "," DataList "," List "," Int ")"
     rule calculateNewBytes-aux(dataList(L:List),
               dataList(ListItem(piece(N:Bits, 1)) L':List), Result:List, Offset:Int)
          => calculateNewBytes-aux(dataList(L),
               dataList(L'), Result ListItem(piece(N, 1)), Offset -Int 1)
     rule calculateNewBytes-aux(dataList(ListItem(piece(N:Bits, 1)) L:List),
               dataList(ListItem(piece(_, 1)) L':List), Result:List, 0)
          => calculateNewBytes-aux(dataList(L),
               dataList(L'), Result ListItem(piece(N, 1)), 0)
          [structural]
     rule calculateNewBytes-aux(dataList(.List), dataList(L:List), Result:List, 0)
          => joinBitsToBytes(Result L)
          [structural]

     syntax KItem ::= joinBitsToBytes(List) [function]
     rule joinBitsToBytes(L:List)
          => joinBitsToBytes-aux(dataList(L), dataList(.List))

     syntax KItem ::= "joinBitsToBytes-aux" "(" K "," K ")" [function]
     rule joinBitsToBytes-aux(
               dataList(ListItem(piece(N:Bits, Len:Int)) ListItem(piece(M:Bits, 1)) L:List),
               dataList(R:List))
          => joinBitsToBytes-aux(
               dataList(ListItem(piece(piece(N, Len) bit:: piece(M, 1), Len +Int 1)) L),
               dataList(R))
          requires Len <Int cfg:bitsPerByte
     rule joinBitsToBytes-aux(
               dataList(ListItem(piece(N:Bits, Len:Int)) L:List), dataList(R:List))
          => joinBitsToBytes-aux(
               dataList(L), dataList(R ListItem(piece(N, Len))))
          requires Len ==Int cfg:bitsPerByte
     rule joinBitsToBytes-aux(dataList(.List), dataList(R:List))
          => dataList(R)

     rule explodeToBits(ListItem(K:Bits) L:List)
          => explodeToBits(ListItem(K)) explodeToBits(L)
          requires L =/=K .List
     rule explodeToBits(ListItem(N:Bits bit:: N':Bits))
          => explodeToBits(ListItem(N)) explodeToBits(ListItem(N'))
     rule explodeToBits(ListItem(piece(N:Bits, Len:Int)))
          => splinter(N, Len)
          requires Len >Int 0
          [structural]
     rule explodeToBits(ListItem(piece(_:Bits, 0))) => .List
     rule explodeToBits(.List) => .List

     syntax List ::= splinter(Bits, Int) [function]
     syntax List ::= "splinter-aux" "(" Bits "," Int "," Int ")" [function]
     rule splinter(N:Bits, Len:Int) => splinter-aux(N, Len, 0)
     rule splinter-aux(_, Len:Int, Len:Int) => .List
     rule splinter-aux(N:Bits, Len:Int, Pos:Int)
          => splinter-aux(N, Len, Pos +Int 1)
               ListItem(piece(bitRange(N, Pos, Pos), 1))
          requires Pos <Int Len

     // this general rule is useful for unknowns, abstracts, etc
     rule splitBytes(tv(N:Bits, T:UType))
          => dataList(ListItem(piece(N, cfg:bitsPerByte)))
          requires isCharType(type(T))
               andBool (isInt(N:Bits) =/=K true)
     rule splitBytes(tv(unknown(I:Int), T::UType))
          => makeUnknown(splitBytes(tv(I, T)))
     rule splitBytes(tv(I:Int, T::UType))
          => splitIntegerBytes(I, T, byteSizeofType(T))
     rule splitBytes(tv(F:Float, T::UType))
          => splitFloatBytes(F, T, byteSizeofType(T))
     rule splitBytes(tv(Loc:SymLoc, T::UType))
          => splitPointerBytes(Loc, byteSizeofType(T))
     rule splitBytes(tv(agg(L:List), T::UType))
          => splitStructBytes(dataList(L), T,
               byteSizeofType(T))
          requires isStructOrUnionType(type(T))

     syntax KItem ::= makeUnknownAux(List, List) [function]
     rule makeUnknown(dataList(L::List)) => makeUnknownAux(L, .List)
     rule makeUnknownAux((ListItem(piece(I:Int, PieceLen:Int)) => .List) L::List, _:List (.List => ListItem(piece(unknown(I), PieceLen))))
     rule makeUnknownAux(.List, L::List) => dataList(L)
     rule makeUnknownAux((ListItem(B::Bits) => .List) L::List, _:List (.List => ListItem(B))) [owise]

     syntax DataList ::= splitIntegerBytes(Int, UType, Int) [function]
     syntax DataList ::= #splitIntegerBytes(Int, UType, Int, List) [function]

     rule splitIntegerBytes(I:Int, T::UType, Len:Int)
          => #splitIntegerBytes(I, T, Len, .List)
     rule #splitIntegerBytes(I:Int, T::UType, Len:Int, L:List)
          => #splitIntegerBytes(I >>Int cfg:bitsPerByte, T, Len -Int 1,
               L ListItem(lowestByte(I)))
          requires Len >Int 0
     rule #splitIntegerBytes(_, _, 0, L:List) => dataList(L)

     syntax DataList ::= splitStructBytes(K, UType, Int) [function]
     syntax DataList ::= #splitStructBytes(K, UType, Int, List)  [function]

     rule splitStructBytes(dataList(L:List), T::UType, Len:Int)
          => #splitStructBytes(dataList(L), T, Len, .List)
     rule #splitStructBytes(
          dataList(ListItem(piece(N:Bits, PieceLen:Int)) Rest:List),
               T::UType, Len:Int, L:List)
          => #splitStructBytes(dataList(Rest), T, Len -Int 1,
               ListItem(piece(N, PieceLen)) L)
          requires PieceLen ==Int cfg:bitsPerByte
               andBool Len >Int 0
               andBool (notBool isPaddingOffset(byteSizeofType(T) -Int Len, getFieldInfo(type(T)))
                    orBool isUnknown(N))
     rule #splitStructBytes(
          dataList(ListItem(piece((N:Bits => unknown(#if isInt(N) #then N #else 0 #fi:>Int)), _:Int)) _:List),
               T::UType, Len:Int, _:List)
          requires isPaddingOffset(byteSizeofType(T) -Int Len, getFieldInfo(type(T)))
               andBool notBool isUnknown(N)
     rule #splitStructBytes(_, _, 0, L:List) => dataList(reverseList(L))

     syntax Bool ::= isPaddingOffset(Int, K) [function]
     rule isPaddingOffset(Offset:Int, fieldInfo(Decls:List, _, Types:Map, Offsets:Map))
          => notBool isNonPaddingOffset(Offset *Int cfg:bitsPerByte, Decls, Types, Offsets)
     syntax Bool ::= isNonPaddingOffset(Int, List, Map, Map) [function]
     rule isNonPaddingOffset(Offset:Int, ListItem(typedDeclaration(_, F:CId)) Decls:List, Types:Map, Offsets:Map)
          => (Offsets[F]:>Int <=Int Offset andBool Offset <Int Offsets[F]:>Int +Int
               bitSizeofType(Types[F]:>Type))
          orBool isNonPaddingOffset(Offset, Decls, Types, Offsets)
     rule isNonPaddingOffset(_, .List, _, _) => false

     syntax DataList ::= splitPointerBytes(SymLoc, Int) [function]
     syntax DataList ::= splitPointerBytes(SymLoc, Int, K, List) [function, klabel(splitPointerBytes2)]

     rule splitPointerBytes(Loc:SymLoc, Len:Int)
          => splitPointerBytes(Loc, Len, 0, .List)
     rule splitPointerBytes(Loc:SymLoc, Len:Int, N:Int, L:List)
          => splitPointerBytes(Loc, Len -Int 1, N +Int 1,
               L ListItem(piece(subObject(Loc, N, N), cfg:bitsPerByte)))
          requires Len >Int 0
     rule splitPointerBytes(_, 0, _, L:List) => dataList(L:List)

     syntax DataList ::= splitFloatBytes(Float, UType, Int) [function]
     syntax DataList ::= splitFloatBytes(Float, UType, Int, List) [function, klabel(splitFloatBytes2)]

     rule splitFloatBytes(F:Float, T::UType, Len:Int)
          => splitFloatBytes(F, T, Len -Int 1,
               ListItem(piece(encodedFloat(F, Len -Int 1, Len -Int 1, T), cfg:bitsPerByte)))
          requires Len >Int 0
     rule splitFloatBytes(F:Float, T::UType, Len:Int, L:List)
          => splitFloatBytes(F, T, Len -Int 1,
               ListItem(piece(encodedFloat(F, Len -Int 1, Len -Int 1, T), cfg:bitsPerByte)) L)
          requires Len >Int 0
     rule splitFloatBytes(_, _, 0, L:List) => dataList(L)

     syntax Bits ::= lowestByte(Int) [function]
     rule lowestByte(I:Int) => piece(I &Int byteMaskSet, cfg:bitsPerByte)
          [structural]

     syntax Int ::= "byteMaskSet" [function]

     rule byteMaskSet => (1 <<Int cfg:bitsPerByte) -Int 1

     rule writeString(Loc:SymLoc, S:String)
          => Computation(
               * tv(Loc, utype(pointerType(type(char))))
               := tv(ordChar(firstChar(S:String)), utype(char)))
               ~> writeString(Loc +bytes 1, butFirstChar(S:String))
          requires S:String =/=String ""
          [structural]
     // TODO this bare 4 needs to be updated to handle different size wchar_ts
     rule writeWString(Loc:SymLoc, ListItem(N:Int) S:List)
          => Computation(
               * tv(Loc, utype(pointerType(type(cfg:wcharut))))
               := tv(N, utype(cfg:wcharut)))
               ~> writeWString(Loc +bytes 4, S)
          [structural]
     rule writeString(Loc:SymLoc, "")
          => Computation(
               * tv(Loc, utype(pointerType(type(char))))
               := tv(0, utype(char)))
          [structural]
     rule writeWString(Loc:SymLoc, .List)
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
          <mem>... Base |-> object(_ => T', _, _) ...</mem>
          [structural]
     rule <k> setEffectiveType(Loc::SymLoc, _) => .K ...</k>
          <mem> Mem:Map </mem>
          requires notBool isNativeLoc(Loc) andBool notBool base(Loc) in_keys(Mem)
          [structural]

     syntax Bool ::= hasObjectType(SymLoc) [function]
     rule hasObjectType(loc(_, _, _:Set SetItem(objectType(_)))) => true
     rule hasObjectType(_) => false [owise]

     syntax Type ::= getObjectType(SymLoc) [function]
     rule getObjectType(loc(_, _, _:Set SetItem(objectType(T::Type)))) => T

endmodule
