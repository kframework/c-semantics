module C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX

     // location, value
     syntax KItem ::= write(SymLoc, CValue, Type)

     // Either buffered or unbuffered depending on whether we're executing.
     syntax KItem ::= writeBytes(SymLoc, K, Type) [strict(2)]

     syntax List ::= explodeToBits(List) [function]

     // TODO(chathhorn): For trans/symbolic-value.k
     syntax DataList ::= splitBytes(Value) [function]
     syntax KItem ::= "write-specific" "(" SymLoc "," CValue "," Type ")"
endmodule

module C-MEMORY-WRITING
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     // Write thread-local or auto.
     rule <k> write(Loc:SymLoc, V:CValue, T:Type)
               => write-specific(Loc, V, T)
          ...</k>
          <initializing> 0 </initializing>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool notBool isConstType(T)
          [structural]
     rule <k> write(Loc:SymLoc, V:CValue, T:Type)
               => write-specific(Loc, V, T)
          ...</k>
          <initializing> I:Int </initializing>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool I >Int 0
          [structural]
     // Write global, shared data, or "allocated" duration.
     rule <k> write(Loc:SymLoc, V:CValue, T:Type)
               => write-specific(Loc, V, T)
          ...</k>
          <initializing> 0 </initializing>
          requires (isStaticDuration(Loc) orBool isAllocatedDuration(Loc))
               andBool notBool isConstType(T)
               andBool notBool isStringLoc(Loc)
          [ndtrans]
     rule <k> write(Loc:SymLoc, V:CValue, T:Type)
               => write-specific(Loc, V, T)
          ...</k>
          <initializing> I:Int </initializing>
          requires (isStaticDuration(Loc) orBool isAllocatedDuration(Loc))
               andBool I >Int 0
          [ndtrans]
     rule <k> (.K => CV("00035", "Trying to write through a const lvalue.", "6.5.16.1:1") )
               ~> write(_, _, T:Type)
          ...</k>
          <initializing> 0 </initializing>
          requires isConstType(T)
          [structural]
     rule <k> (.K => UNDEF("EIO4", "Trying to modify a string literal.", "6.4.5:7"))
               ~> write(Loc:SymLoc, _, _)
          ...</k>
          <initializing> 0 </initializing>
          requires isStringLoc(Loc)
          [structural]

     rule write-specific(Loc:SymLoc, V:CValue, T:Type)
          => writeBytes(stripProv(Loc), splitBytes(tv(V, T)), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool (isBitfieldType(T) =/=K true)
               andBool (notBool hasUnionMarker(Loc))
          [structural]

     syntax Set ::= keepUnion(Set) [function]
                  | stripUnion(Set) [function]
                  | #keepUnion(K, Set, Set) [function]
                  | #stripUnion(K, Set, Set) [function]

     rule keepUnion(.Set) => .Set
     rule keepUnion(SetItem(K:K) S:Set) => #keepUnion(K, S, .Set)

     rule #keepUnion(fromUnion(UnionLoc:SymLoc, F:CId, Fields:FieldInfo),
               .Set, S':Set)
          => SetItem(fromUnion(UnionLoc, F, Fields)) S'
     rule #keepUnion(K:K, .Set, S':Set) => S'
          requires getKLabel(K) =/=KLabel 'fromUnion
     rule #keepUnion(fromUnion(UnionLoc:SymLoc, F:CId, Fields:FieldInfo),
          SetItem(K':K) S:Set, S':Set)
          => #keepUnion(K', S:Set, SetItem(fromUnion(UnionLoc, F, Fields)) S')
     rule #keepUnion(K:K, SetItem(K':K) S:Set, S':Set)
          => #keepUnion(K', S, S')
          requires getKLabel(K) =/=KLabel 'fromUnion

     rule stripUnion(.Set) => .Set
     rule stripUnion(SetItem(K:K) S:Set) => #stripUnion(K, S, .Set)

     rule #stripUnion(fromUnion(_:SymLoc, _:CId, _:FieldInfo), .Set, S':Set)
          => S'
     rule #keepUnion(K:K, .Set, S':Set) => SetItem(K) S'
          requires getKLabel(K) =/=KLabel 'fromUnion
     rule #keepUnion(fromUnion(_:SymLoc, _:CId, _:FieldInfo),
          SetItem(K':K) S:Set, S':Set)
          => #keepUnion(K', S:Set, S')
     rule #keepUnion(K:K, SetItem(K':K) S:Set, S':Set)
          => #keepUnion(K', S, SetItem(K) S')
          requires getKLabel(K) =/=KLabel 'fromUnion

     rule (.K => makeUnionUnKnown(.K, keepUnion(S)))
          ~> write-specific(
               loc(Base:SymBase, Offset:Int, S:Set => stripUnion(S)), _, _)
          requires hasUnionMarker(loc(Base,Offset,S))
          [structural]

     syntax KItem ::= makeUnknown(SymLoc, CId, FieldInfo)
                    | makeUnionUnKnown(K, Set)

     rule makeUnionUnKnown(.K, .Set) => .K
          [structural]
     rule makeUnionUnKnown(.K, SetItem(K:K) S:Set)
          => makeUnionUnKnown(K, S)
          [structural]
     rule makeUnionUnKnown(fromUnion(UnionLoc:SymLoc, F:CId, Fields:FieldInfo),
               S:Set)
          => allowInit(makeUnknown(UnionLoc, F, Fields))
          ~> makeUnionUnKnown(.K, S)
          [structural]

     // Flag unknown from (&union + sizeof union.F) to (&union + sizeof union).
     // TODO(chathhorn): breaks open a lot of abstractions.
     rule makeUnknown(Loc:SymLoc, F:CId, fieldInfo(L:List,
               F |-> T:Type _, _))
          => writeBytes(stripProv(Loc) +bytes byteSizeofType(T),
               dataList(times(
                    maxByteSizeofList(L) -Int byteSizeofType(T),
                    piece(unknown, cfg:bitsPerByte))), T)
          requires maxByteSizeofList(L) >Int byteSizeofType(T)
          [structural]
     rule makeUnknown(_, F:CId, fieldInfo(L:List, F |-> T:Type _, _)) => .K
          requires maxByteSizeofList(L) <=Int byteSizeofType(T)
          [structural]

     rule write-specific(Loc:SymLoc,
               agg(ListItem(V:CValue) ListItem(V':CValue) L:List),
               T:Type)
          => writeBytes(stripProv(Loc), dataList(ListItem(V) ListItem(V') L), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool notBool isBitfieldType(T)
          [structural]

     syntax Int ::= justBits(Int, Type) [function]
     syntax Int ::= "justBits-aux" "(" Int "," Type ")" [function]
     rule justBits(I:Int, _) => I
          requires I >=Int 0

     rule justBits(I:Int, T:Type) => justBits-aux(I, T)
          requires I <Int 0
     rule justBits-aux(I:Int, T:Type)
          => justBits-aux(I +Int max(T) +Int 1, T)
          requires I <Int 0
     // fixme sNat
     rule justBits-aux(N:Int, t(_, bitfieldType(_:Type, Len:Int)))
          => N +Int (1 <<Int (Len -Int 1))
          requires Len >Int 0 andBool N >=Int 0

     rule write-specific(Loc:SymLoc, I:Int, T:Type)
          => write-specific(Loc, justBits(I, T), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0
               orBool isBitfieldType(T))
               andBool (I <Int 0)
          [structural]

     rule write-specific(Loc:SymLoc, V:Int, T:Type)
          => writeBytes(stripProv(Loc),
               calculateNewBytes(piece(V, bitSizeofType(T)),
                    readBytes(stripProv(Loc), byteSizeofType(T), T)), T)
          requires (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0)
               orBool (isBitfieldType(T) andBool notBool hasUnionMarker(Loc))
               andBool (V >=Int 0)
          [structural]

     syntax KItem ::= calculateNewBytes(Bits, K)
          [latex(\terminal{calcNewBytes(}{#1}, {#2}\terminal{)}), strict(2)]

     rule calculateNewBytes(N:Bits, dataList(L:List))
          => calculateNewBytes-aux(dataList(explodeToBits(ListItem(N))),
               dataList(explodeToBits(L)), .List)
          [structural]

     syntax KItem ::= "calculateNewBytes-aux" "(" DataList "," DataList "," List ")"
     rule calculateNewBytes-aux(dataList(ListItem(piece(N:Bits, 1)) L:List),
               dataList(ListItem(piece(_, 1)) L':List), Result:List)
          => calculateNewBytes-aux(dataList(L),
               dataList(L'), Result ListItem(piece(N, 1)))
          [structural]
     rule calculateNewBytes-aux(dataList(.List), dataList(L:List), Result:List)
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
          requires L =/=MSet .List
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
     rule splitBytes(tv(N:Bits, T:Type))
          => dataList(ListItem(piece(N, cfg:bitsPerByte)))
          requires hasCharType(T:Type) andBool (isInt(N:Bits) =/=K true)
     rule splitBytes(tv(unknown, T:Type))
          => dataList(splitUnknown(bitSizeofType(T)))
     rule splitBytes(tv(I:Int, T:Type))
          => splitIntegerBytes(I, T, byteSizeofType(T))
          requires hasIntegerType(T)
     rule splitBytes(tv(F:Float, T:Type))
          => splitFloatBytes(F, T, byteSizeofType(T))
          requires hasFloatType(T)
     rule splitBytes(tv(Loc:SymLoc, T:Type))
          => splitPointerBytes(Loc, T, byteSizeofType(T))
          requires isPointerType(T)
     rule splitBytes(tv(agg(L:List), t(S:Set, structType(X:CId, NBits:Int, Info:FieldInfo))))
          => splitStructBytes(dataList(L), t(S, structType(X, NBits, Info)),
               byteSizeofType(t(S, structType(X, NBits, Info))))
     rule splitBytes(tv(agg(L:List), t(S:Set, unionType(X:CId, NBits:Int, Info:FieldInfo))))
          => splitStructBytes(dataList(L), t(S, unionType(X, NBits, Info)),
               byteSizeofType(t(S, unionType(X, NBits, Info))))

     syntax List ::= splitUnknown(Int) [function]
     rule splitUnknown(N:Int)
          => ListItem(piece(unknown, cfg:bitsPerByte))
               splitUnknown(N -Int cfg:bitsPerByte)
          requires N >Int 0
     rule splitUnknown(N:Int) => .List
          requires N <=Int 0

     syntax DataList ::= splitIntegerBytes(Int, Type, Int) [function]
     syntax DataList ::= splitIntegerBytes(Int, Type, Int, List) [function]

     rule splitIntegerBytes(I:Int, T:Type, Len:Int)
          => splitIntegerBytes(I, T, Len, .List)
     rule splitIntegerBytes(I:Int, T:Type, Len:Int, L:List)
          => splitIntegerBytes(I >>Int cfg:bitsPerByte, T, Len -Int 1,
               L ListItem(lowestByte(I, T)))
          requires Len >Int 0
     rule splitIntegerBytes(_, _, 0, L:List) => dataList(L)

     syntax DataList ::= splitStructBytes(K, Type, Int) [function]
     syntax DataList ::= splitStructBytes(K, Type, Int, List)  [function]

     rule splitStructBytes(dataList(L:List), T:Type, Len:Int)
          => splitStructBytes(dataList(L), T, Len, .List)
     rule splitStructBytes(
          dataList(ListItem(piece(N:Bits, PieceLen:Int)) Rest:List),
               T:Type, Len:Int, L:List)
          => splitStructBytes(dataList(Rest), T, Len -Int 1,
               L ListItem(piece(N, PieceLen)))
          requires PieceLen ==Int cfg:bitsPerByte
               andBool Len >Int 0
     rule splitStructBytes(_, _, 0, L:List) => dataList(L)

     syntax DataList ::= splitPointerBytes(SymLoc, Type, Int) [function]
     syntax DataList ::= splitPointerBytes(SymLoc, Type, Int, K, List) [function]

     rule splitPointerBytes(Loc:SymLoc, T:Type, Len:Int)
          => splitPointerBytes(Loc, T, Len, 0, .List)
     rule splitPointerBytes(Loc:SymLoc, T:Type, Len:Int, N:Int, L:List)
          => splitPointerBytes(Loc, T, Len -Int 1, N +Int 1,
               L ListItem(piece(subObject(Loc, N, N), cfg:bitsPerByte)))
          requires Len >Int 0
     rule splitPointerBytes(_, _, 0, _, L:List) => dataList(L:List)

     syntax DataList ::= splitFloatBytes(Float, Type, Int) [function]
     syntax DataList ::= splitFloatBytes(Float, Type, Int, List) [function]

     rule splitFloatBytes(F:Float, T:Type, Len:Int)
          => splitFloatBytes(F, T, Len -Int 1,
               ListItem(piece(encodedFloat(F), cfg:bitsPerByte)))
          requires Len >Int 0
     rule splitFloatBytes(F:Float, T:Type, Len:Int, L:List)
          => splitFloatBytes(F, T, Len -Int 1,
               L ListItem(piece(encodedFloat(F), cfg:bitsPerByte)))
          requires Len >Int 0
     rule splitFloatBytes(_, _:Type, 0, L:List) => dataList(L)

     syntax Bits ::= lowestByte(Int, Type) [function]

     rule lowestByte(I:Int, T:Type)
          => piece(I &Int byteMaskSet, cfg:bitsPerByte)
          requires hasIntegerType(T)
          [structural]

     syntax Int ::= "byteMaskSet" [function]

     rule byteMaskSet => (2 ^Int cfg:bitsPerByte) -Int 1

endmodule
