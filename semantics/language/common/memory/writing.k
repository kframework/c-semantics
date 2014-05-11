module C-MEMORY-WRITING-SYNTAX
     // location, value
     syntax K ::= write(SymLoc, CValue, Type)

     // Either buffered or unbuffered depending on whether we're executing.
     syntax K ::= writeBytes(SymLoc, DataList, Type)

     syntax List ::= explodeToBits(List) [function]

     // TODO(chathhorn): For trans/symbolic-value.k
     syntax DataList ::= splitBytes(Value) [function]
     syntax K ::= "write-specific" "(" SymLoc "," CValue "," Type ")"
     syntax K ::= writeBitfield(SymLoc, K, Type) [strict(2)] 
endmodule

module C-MEMORY-WRITING
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     
     // Write thread-local or auto.
     rule write(Loc:SymLoc, V:CValue, T:Type)
          => write-specific(Loc, V, T)
          when isThreadDuration(Loc)
               andBool notBool isConstType(T)
          [structural]
     // Write global, shared data, or "allocated" duration.
     rule write(Loc:SymLoc, V:CValue, T:Type)
          => write-specific(Loc, V, T)
          when notBool isThreadDuration(Loc)
               andBool notBool isConstType(T)
          [ndtrans]

     rule write-specific(Loc:SymLoc, V:CValue, T:Type)
          => writeBytes(Loc, splitBytes(tv(V, T)), T)
          when (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool (isByteLoc(Loc) ==K true)
               andBool (isBitfieldType(T) =/=K true)
               andBool (notBool hasUnionMarker(T))
          [structural]
     rule (. => makeUnknown(UnionLoc, F, Fields))
          ~> write-specific(Loc:SymLoc, _,
               t((SetItem(fromUnion(UnionLoc:SymLoc, F:Id, Fields:FieldInfo))
                    => .Set) _, _))
          when isByteLoc(Loc)
          [structural]
          
     syntax K ::= makeUnknown(SymLoc, Id, FieldInfo)

     // Zero from (&union + sizeof union.F) to (&union + sizeof union).
     // TODO(chathhorn): breaks open a lot of abstractions.
     rule makeUnknown(Loc:SymLoc, F:Id, fieldInfo(L:List,
               F |-> T:Type _, _))
          => writeBytes(Loc +bits roundUpToByte(bitSizeofType(T)),
               dataList(times(bitsToBytes(
                    maxBitSizeofList(L) -Int roundUpToByte(bitSizeofType(T))), 
                    piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte))), 
                    initializerType(T))
          when maxBitSizeofList(L) >Int roundUpToByte(bitSizeofType(T))
     rule makeUnknown(_, F:Id, fieldInfo(L:List, F |-> T:Type _, _)) => .
          when maxBitSizeofList(L) <=Int roundUpToByte(bitSizeofType(T))

     rule write-specific(Loc:SymLoc,
               agg(ListItem(V:CValue) ListItem(V':CValue) L:List),
               T:Type)
          => writeBytes(Loc, dataList(ListItem(V) ListItem(V') L), T)
          when (bitSizeofType(T) %Int cfg:bitsPerByte ==Int 0)
               andBool isByteLoc(Loc)
               andBool notBool isBitfieldType(T)
          [structural]
          
     syntax Int ::= justBits(Int, Type) [function]
     syntax Int ::= "justBits-aux" "(" Int "," Type ")" [function]
     rule justBits(I:Int, _) => I
          when I >=Int 0 
          
     rule justBits(I:Int, T:Type) => justBits-aux(I, T)
          when I <Int 0 
     rule justBits-aux(I:Int, T:Type)
          => justBits-aux(I +Int max(T) +Int 1, T)
          when I <Int 0 
     // fixme sNat
     rule justBits-aux(N:Int, t(_, bitfieldType(_:Type, Len:Int))) 
          => N +Int (1 <<Int (Len -Int 1))
          when Len >Int 0 andBool N >=Int 0
     
     rule write-specific(Loc:SymLoc, I:Int, T:Type)
          => write-specific(Loc, justBits(I, T), T)
          when (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0
               orBool notBool(isByteLoc(Loc))
               orBool isBitfieldType(T))
               andBool (I <Int 0)
          [structural]
     
     rule write-specific(Loc:SymLoc, I:Int, T:Type)
          => writeBitfield(Loc,
               calculateNewBytes(getBitOffset(Loc), piece(I, bitSizeofType(T)),
                    readBytes(floorLoc(Loc),
                         bitsToBytes(bitSizeofType(T) +Int getBitOffset(Loc)), T)), T)
          when (bitSizeofType(T) %Int cfg:bitsPerByte =/=Int 0)
               orBool (notBool isByteLoc(Loc))
               orBool (isBitfieldType(T) andBool notBool hasUnionMarker(T))
               andBool (I >=Int 0)
          [structural]
          
     rule writeBitfield(Loc:SymLoc, dataList(L:List), T:Type)
          => writeBytes(floorLoc(Loc), dataList(L), T)
          [structural] 

     syntax K ::= calculateNewBytes(Int, Bits, K)
          [latex(\terminal{calcNewBytes(}{#1}, {#2}, {#3}\terminal{)}), strict(3)] 
          
     syntax K ::= "calculateNewBytes-aux" "(" Int "," DataList "," DataList "," List ")"
     rule calculateNewBytes(Len:Int, N:Bits, dataList(L:List)) 
          => calculateNewBytes-aux(Len, dataList(explodeToBits(ListItem(N))),
               dataList(explodeToBits(L)), .List)
          [structural]
     
     syntax K ::= joinBitsToBytes(List) [function]
     syntax K ::= "joinBitsToBytes-aux" "(" K "," K ")" [function]
     
     // fixme sNat
     rule calculateNewBytes-aux(N:Int, D:DataList, 
               dataList(ListItem(piece(Bit:Bits, 1)) L:List), Result:List) 
          => calculateNewBytes-aux(N -Int 1, D, 
               dataList(L), Result ListItem(piece(Bit, 1)))
          when N >Int 0
          [structural]
     
     rule calculateNewBytes-aux(0, dataList(ListItem(piece(N:Bits, 1)) L:List), 
               dataList(ListItem(piece(_, 1)) L':List), Result:List) 
          => calculateNewBytes-aux(0, dataList(L), 
               dataList(L'), Result ListItem(piece(N, 1)))
          [structural]
     rule calculateNewBytes-aux(0, dataList(.List), dataList(L:List), Result:List) 
          => joinBitsToBytes(Result L) 
          [structural]
     
     rule joinBitsToBytes(L:List)
          => joinBitsToBytes-aux(dataList(L), dataList(.List))
     rule joinBitsToBytes-aux(
               dataList(ListItem(piece(N:Bits, Len:Int)) ListItem(piece(M:Bits, 1)) L:List),
               dataList(R:List))
          => joinBitsToBytes-aux(
               dataList(ListItem(piece(piece(N, Len) bit:: piece(M, 1), Len +Int 1)) L), 
               dataList(R))
          when Len <Int cfg:bitsPerByte 
          [structural]
     rule joinBitsToBytes-aux(
               dataList(ListItem(piece(N:Bits, Len:Int)) L:List), dataList(R:List))
          => joinBitsToBytes-aux(
               dataList(L), dataList(R ListItem(piece(N, Len))))
          when Len ==Int cfg:bitsPerByte 
          [structural]
     rule joinBitsToBytes-aux(dataList(.List), dataList(R:List))
          => dataList(R) 
          [structural]
     
     rule explodeToBits(ListItem(K:Bits) L:List)
          => explodeToBits(ListItem(K)) explodeToBits(L)
          when L =/=List .List
     rule explodeToBits(ListItem(piece(N:Bits, Len:Int))) 
          => splinter(N, Len)
          when Len >Int 0
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
          when Pos <Int Len
          
     // this general rule is useful for unknowns, abstracts, etc
     rule splitBytes(tv(N:Bits, T:Type))
          => dataList(ListItem(piece(N, cfg:bitsPerByte)))
          when isCharType(T) andBool (isInt(N) =/=K true)
     rule splitBytes(tv(I:Int, T:Type)) 
          => splitIntegerBytes(I, T, byteSizeofType(T))
          when hasIntegerType(T)
     rule splitBytes(tv(F:Float, T:Type)) 
          => splitFloatBytes(F, T, byteSizeofType(T))
          when isFloatType(T)
     rule splitBytes(tv(I:Ptr, T:Type))
          => splitPointerBytes(I, T, byteSizeofType(T))
          when isPointerType(T)
     rule splitBytes(tv(agg(L:List), t(S:Set, structType(X:Id, NBits:Int, Info:FieldInfo)))) 
          => splitStructBytes(dataList(L), t(S, structType(X, NBits, Info)), 
               byteSizeofType(t(S, structType(X, NBits, Info))))
     rule splitBytes(tv(agg(L:List), t(S:Set, unionType(X:Id, NBits:Int, Info:FieldInfo)))) 
          => splitStructBytes(dataList(L), t(S, unionType(X, NBits, Info)), 
               byteSizeofType(t(S, unionType(X, NBits, Info))))
     
     syntax DataList ::= splitIntegerBytes(Int, Type, Int) [function]
     syntax DataList ::= splitIntegerBytes(Int, Type, Int, List) [function]

     rule splitIntegerBytes(I:Int, T:Type, Len:Int) 
          => splitIntegerBytes(I, T, Len, .List)
     rule splitIntegerBytes(I:Int, T:Type, Len:Int, L:List)
          => splitIntegerBytes(I >>Int cfg:bitsPerByte, T, Len -Int 1, 
               L ListItem(lowestByte(I, T)))
          when Len >Int 0
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
          when PieceLen ==Int cfg:bitsPerByte
               andBool Len >Int 0
     rule splitStructBytes(_, _, 0, L:List) => dataList(L) 
          
     syntax DataList ::= splitPointerBytes(Ptr, Type, Int) [function]
     syntax DataList ::= splitPointerBytes(Ptr, Type, Int, K, List) [function]

     rule splitPointerBytes(I:Ptr, T:Type, Len:Int)
          => splitPointerBytes(I, T, Len, 0, .List) 
     rule splitPointerBytes(I:Ptr, T:Type, Len:Int, N:Int, L:List)
          => splitPointerBytes(I, T, Len -Int 1, N +Int 1,
               L ListItem(piece(subObject(I, N, N), cfg:bitsPerByte)))
          when Len >Int 0
     rule splitPointerBytes(_, _, 0, _, L:List) => dataList(L:List)
          
     syntax DataList ::= splitFloatBytes(Float, Type, Int) [function]
     syntax DataList ::= splitFloatBytes(Float, Type, Int, List) [function]

     rule splitFloatBytes(F:Float, T:Type, Len:Int) 
          => splitFloatBytes(F, T, Len -Int 1, 
               ListItem(piece(encodedFloat(F), cfg:bitsPerByte)))
          when Len >Int 0
     rule splitFloatBytes(F:Float, T:Type, Len:Int, L:List) 
          => splitFloatBytes(F, T, Len -Int 1,
               L ListItem(piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte))) 
          when Len >Int 0
     rule splitFloatBytes(_, _:Type, 0, L:List) => dataList(L) 
          
     syntax Bits ::= lowestByte(Int, Type) [function]

     rule lowestByte(I:Int, T:Type) 
          => piece(I &Int byteMaskSet, cfg:bitsPerByte)
          when hasIntegerType(T) 
          [structural]
     
     syntax Int ::= "byteMaskSet" [function]

     rule byteMaskSet => (2 ^Int cfg:bitsPerByte) -Int 1
          
endmodule
