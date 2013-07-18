module C-MEMORY-WRITING-SYNTAX
     syntax KList ::= explodeToBits(KList) [function]
     syntax ListItem ::= "bwrite" "(" SymLoc "," K ")"

endmodule

module C-MEMORY-WRITING
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-EXPRESSION-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-TYPING-SYNTAX
     imports C11-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX
     
     rule [write-string]:
          writeString(Loc:SymLoc, S:String)
          => Computation((* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(ordChar(firstChar(S:String)), t(.Set, char)))
               ~> writeString(Loc +bytes 1, butFirstChar(S:String))
          when S:String =/=String ""
          [structural]
     // fixme this bare 4 needs to be updated to handle different size wchar_ts
     rule [write-wstring]:
          writeWString(Loc:SymLoc, (N:Int,, S:KList))
          => Computation((* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
               := tv(N, cfg:wcharut))
               ~> writeWString(Loc +bytes 4, S)
          [structural] 
     rule [write-empty-string]:
          writeString(Loc:SymLoc, "")
          => Computation((* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(0, t(.Set, char)))
          [structural]
     rule [write-wstring]:
          writeWString(Loc:SymLoc, .KList)
          => Computation((* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
               := tv(0, cfg:wcharut))
          [structural] 
          
     syntax K ::= writeBytes(SymLoc, K, Bool) [strict(2)] 
     syntax K ::= writeBitfield(SymLoc, Type, K) [strict(3)] 
     syntax Bool ::= isByteLoc(SymLoc) [function]
     syntax K ::= splitBytes(Value) [function]
     syntax K ::= calculateNewBytes(Int, K, K)
          [latex(\terminal{calcNewBytes(}{#1}, {#2}, {#3}\terminal{)}), strict(3)] 
     
     syntax K ::= "write-aux" "(" SymLoc "," Value "," K ")" [strict(3)]
     rule write(lv(Dest:SymLoc, T':Type), tv(V:KList, T:Type)) 
          => write-aux(Dest, tv(V, T), bitSizeofType(T)) 
          when notBool isConstType(T')
          [structural]
     
     syntax K ::= "write-specific" "(" SymLoc "," Value "," Int ")"
     
     rule [write-thread-local]:
          <k> 
               write-aux(
                    loc(N:Int @ Th:Int, Offset:Int, BitOffset:Int), 
                    tv(L:KList, T:Type), BitSize:Value)
               => write-specific(
                    loc(N @ Th, Offset, BitOffset), 
                    tv(L, T), value(BitSize))
          ...</k>
          <threadId> Th </threadId>
          [structural]
     // write global or shared data
     rule [write]:
          write-aux(
               loc(N:Int @ 0, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:Type), BitSize:Value)
          => write-specific(
               loc(N @ 0, Offset, BitOffset), 
               tv(L, T), value(BitSize))
          [ndtrans]
     // write data of "allocated" duration
     rule [write-allocated]:
          write-aux(
               loc(N:Int @ allocatedDuration, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:KResult), BitSize:Value)
          => write-specific(
               loc(N @ allocatedDuration, Offset, BitOffset), 
               tv(L, T), value(BitSize))
          [ndtrans]

     syntax Set ::= attrs(Type) [function]
     rule attrs(t(S:Set, _)) => S

     rule [write-normal]:
          write-specific(Loc:SymLoc, tv(V:KList, T:Type), BitSize:Int)
          => writeBytes(Loc, splitBytes(tv(V, T)), false)
          when (BitSize %Int cfg:bitsPerByte ==Int 0)
               andBool (isByteLoc(Loc) ==K true)
               andBool (isBitfieldType(T) =/=K true)
               andBool (notBool hasUnionMarker(T))
          [structural]
     rule [write-normal-union-field]:
          (. => makeUnknown(Loc, t(.Set, unionType(S))))
          ~> write-specific(Loc:SymLoc, 
               tv(_, t((SetItem(fromUnion(S:Id)) => .Set) _, _)), _)
          when isByteLoc(Loc)
          [structural]
          
     syntax K ::= "makeUnknown" "(" SymLoc "," Type ")" [function]
     syntax K ::= "makeUnknown-aux" "(" SymLoc "," K ")" [strict(2)]
     
     rule makeUnknown(Loc:SymLoc, T:Type)
          => makeUnknown-aux(Loc, byteSizeofType(T)) 
     rule makeUnknown-aux(Loc:SymLoc, Len:Value)
          => writeBytes(Loc, dataList(times(value(Len), 
               piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte))), true)
          [structural]
          
     syntax Bool ::= hasUnionMarker(Type) [function]
     rule hasUnionMarker(T:Type) => #hasUnionMarker(T) ==K true

     syntax Bool ::= #hasUnionMarker(Type) [function]
     rule #hasUnionMarker(t((_:Set SetItem(fromUnion(_)) _:Set), _)) => true
     
     rule [write-struct]:
          write-specific(Loc:SymLoc, 
               tv((V:K,, V':K,, L:KList), T:Type), BitSize:Int)
          => writeBytes(Loc, dataList((V,, V',, L)), false)
          when (BitSize:Int %Int cfg:bitsPerByte ==Int 0)
               andBool isByteLoc(Loc)
               andBool (V =/=K .K)
               andBool (V' =/=K .K)
               andBool (notBool isBitfieldType(T))
          [structural]
          
     syntax Value ::= justBits(Int, Type) [function]
     syntax Value ::= "justBits-aux" "(" Int "," Type ")" [function]
     rule justBits(I:Int, _) => I
          when I >=Int 0 
          
     rule justBits(I:Int, T:Type) => justBits-aux(I, T)
          when I <Int 0 
     rule justBits-aux(I:Int, T:Type)
          => justBits-aux((I +Int max(T) +Int 1), T)
          when I <Int 0 
     // fixme sNat
     rule justBits-aux(N:Int, t(_, bitfieldType(_:Type, Len:Int))) 
          => N +Int (1 <<Int (Len -Int 1))
          when Len >Int 0 andBool N >=Int 0
     
     rule [massage-bitfield]:
          write-specific(Loc:SymLoc, tv(I:Int, T:Type), BitSize:Int)
          => write-specific(Loc, tv(justBits(I, T), T), BitSize)
          when (BitSize %Int cfg:bitsPerByte =/=Int 0
               orBool notBool(isByteLoc(Loc))
               orBool isBitfieldType(T))
               andBool (I <Int 0)
          [structural]
     
     rule [write-bitfield]:
          write-specific(Loc:SymLoc, tv(I:Int, T:Type), BitSize:Int)
          => writeBitfield(
               Loc
               , T
               , calculateNewBytes(
                    getBitOffset(Loc)
                    , piece(I, BitSize)
                    , extractBytesFromMem(floorLoc(Loc), 
                         bitsToBytes(BitSize +Int getBitOffset(Loc))
                    )
               )
          )
          when (BitSize:Int %Int cfg:bitsPerByte =/=Int 0)
               orBool (notBool isByteLoc(Loc))
               orBool (isBitfieldType(T) 
                    andBool notBool hasUnionMarker(T))
               andBool (I >=Int 0)
          [structural]
          
     rule writeBitfield(Loc:SymLoc, _, dataList(L:KList))
          => writeBytes(floorLoc(Loc), dataList(L), false)
          [structural] 
          
     syntax K ::= "calculateNewBytes-aux" "(" Int "," K "," K "," KList ")"
     rule calculateNewBytes(Len:Int, N:Bits, dataList(L:KList)) 
          => calculateNewBytes-aux(Len, dataList(explodeToBits(N)),
               dataList(explodeToBits(L)), .KList)
          [structural]
     
     syntax K ::= joinBitsToBytes(KList) [function]
     syntax K ::= "joinBitsToBytes-aux" "(" K "," K ")" [function]
     
     // fixme sNat
     rule calculateNewBytes-aux(N:Int, K:K, 
               dataList((piece(Bit:Bits, 1),, L:KList)), Result:KList) 
          => calculateNewBytes-aux(N -Int 1, K, 
               dataList(L), (Result,, piece(Bit, 1))) 
          when N >Int 0
          [structural]
     
     rule calculateNewBytes-aux(0, dataList((piece(N:Bits, 1),, L:KList)), 
               dataList((piece(_, 1),, L':KList)), Result:KList) 
          => calculateNewBytes-aux(0, dataList(L), 
               dataList(L'), (Result,, piece(N, 1))) 
          [structural]
     rule calculateNewBytes-aux(0, dataList(.KList), 
               dataList(L:KList), Result:KList) 
          => joinBitsToBytes((Result:KList,, L:KList)) 
          [structural]
     
     rule joinBitsToBytes(L:KList)
          => joinBitsToBytes-aux(dataList(L:KList), dataList(.KList))
     rule joinBitsToBytes-aux(
               dataList((piece(N:Bits, Len:Int),, piece(M:Bits, 1),, L:KList)),
               dataList(R:KList))
          => joinBitsToBytes-aux(
               dataList((piece(piece(N, Len) bit:: piece(M, 1), Len +Int 1),, L)), 
               dataList(R))
          when Len <Int cfg:bitsPerByte 
          [structural]
     rule joinBitsToBytes-aux(
               dataList((piece(N:Bits, Len:Int),, L:KList)), dataList(R:KList))
          => joinBitsToBytes-aux(
               dataList(L), dataList((R,, piece(N, Len))))
          when Len ==Int cfg:bitsPerByte 
          [structural]
     rule joinBitsToBytes-aux(dataList(.KList), dataList(R:KList))
          => dataList(R) 
          [structural]
     
     rule explodeToBits((K:Bits,, L:KList))
          => (explodeToBits(K),, explodeToBits(L))
          when L =/=KList .KList
     rule explodeToBits(piece(N:Bits, Len:Int)) => splinter(N, Len)
          when Len >Int 0
          [structural]
     rule explodeToBits(piece(_:Bits, 0)) => .KList
     rule explodeToBits(.KList) => .KList
     
     syntax KList ::= splinter(Bits, Int) [function] 
     syntax KList ::= "splinter-aux" "(" Bits "," Int "," Int ")" [function]
     rule splinter(N:Bits, Len:Int) => splinter-aux(N, Len, 0)
     rule splinter-aux(_, Len:Int, Len:Int) => .KList
     rule splinter-aux(N:Bits, Len:Int, Pos:Int)
          => splinter-aux(N, Len, Pos +Int 1),, piece(bitRange(N, Pos, Pos), 1)
          when Pos <Int Len
     
     rule writeBytes(Loc:SymLoc, dataList((V:K,, L:KList)), false)
          => writeByte(Loc, V) ~> 
               writeBytes(Loc +bytes 1, dataList(L), false)
          [structural]
     rule writeBytes(Loc:SymLoc, dataList((V:K,, L:KList)), true)
          => stealthWriteByte(Loc, V) ~> 
               writeBytes(Loc +bytes 1, dataList(L), true)
          [structural]
     rule writeBytes(_, dataList(.KList), _) => .K
          [structural] 

     syntax K ::= stealthWriteByte(SymLoc, K)
     rule [write-byte-stealth]:
          <k> 
               stealthWriteByte(loc(Base:SymBase, Offset:Int, 0), V:K) => . 
          ...</k>
          <buffer>... (.List => bwrite(loc(Base, Offset, 0), V)) </buffer>
          [large, structural]

     rule [write-byte-buffer]:
          <k> writeByte(loc(Base:SymBase, Offset:Int, 0), V:K) => . ...</k>
          <buffer>...
               (.List => bwrite(loc(Base, Offset, 0), V))
          </buffer>
          <mem>... Base |-> memblock(Len:Int, Attrs:Bag, _) ...</mem>
          <locsWrittenTo>
               Locs:Bag (.Bag => BagItem(loc(Base, Offset, 0)))
          </locsWrittenTo>
          <notWritable> NotWritable:Map </notWritable>
          when (notBool BagItem(loc(Base, Offset, 0)) in Locs)
               andBool (notBool (BagItem(mconst) in Attrs))
               andBool (notBool (loc(Base, Offset, 0) in keys NotWritable))
               andBool (Offset <Int Len)
          [large, structural]
          
     rule [commit-byte]:
          <buffer>
               (bwrite(loc(Base:SymBase, Offset:Int, 0), V:Bits) => .List)
          ...</buffer>
          <mem>...
               Base |-> memblock(Len:Int, _, M:Map => M:Map[V / Offset])
          ...</mem>
          when Offset <Int Len
          [structural]
          
     // this general rule is useful for unknowns, abstracts, etc
     rule [splitBytes-other]:
          splitBytes(tv(N:Bits, T:Type))
          => dataList(piece(N, cfg:bitsPerByte))
          when isCharType(T) andBool (isInt(N) =/=K true)
     rule [splitBytes-int]:
          splitBytes(tv(I:Int, T:Type)) 
          => splitIntegerBytes(I, T, byteSizeofType(T))
          when hasIntegerType(T)
     rule [splitBytes-float]:
          splitBytes(tv(F:Float, T:Type)) 
          => splitFloatBytes(F, T, byteSizeofType(T))
          when isFloatType(T)
     rule [splitBytes-pointer]:
          splitBytes(tv(I:Ptr, t(S:Set, pointerType(T:KResult)))) 
          => splitPointerBytes(I, t(S, pointerType(T)), 
               byteSizeofType(t(.Set, pointerType(T))))
     rule [splitBytes-struct]:
          splitBytes(tv(L:KList, t(S:Set, structType(I:Id)))) 
          => splitStructBytes(dataList(L), t(S, structType(I)), 
               byteSizeofType(t(S, structType(I))))
     rule [splitBytes-union]:
          splitBytes(tv(L:KList, t(S:Set, unionType(I:Id)))) 
          => splitStructBytes(dataList(L), t(S, unionType(I)), 
               byteSizeofType(t(S, unionType(I))))
     
     syntax K ::= splitIntegerBytes(Int, Type, K) [strict(3)]
     syntax K ::= "splitIntegerBytes-aux" "(" Int "," Type "," Int "," KList ")"
          [function]
     rule splitIntegerBytes(I:Int, T:Type, Len:Value) 
          => splitIntegerBytes-aux(I, T, value(Len), .KList)
     rule splitIntegerBytes-aux(I:Int, T:Type, Len:Int, L:KList)
          => splitIntegerBytes-aux(I >>Int cfg:bitsPerByte, T, Len -Int 1, 
               (L,, lowestByte(I, T)))
          when Len >Int 0
     rule splitIntegerBytes-aux(_, _, 0, L:KList)
          => dataList(L) 
          
     syntax K ::= splitStructBytes(K, Type, K) [strict(3)]
     syntax K ::= splitStructBytes(K, Type, Int, KList) 

     rule splitStructBytes(dataList(L:KList), T:Type, Len:Value) 
          => splitStructBytes(dataList(L), T, value(Len), .KList) 
          [structural, anywhere]
     rule splitStructBytes(dataList((piece(N:Int, PieceLen:Int),, Rest:KList)),
               T:Type, Len:Int, L:KList)
          => splitStructBytes(dataList(Rest), T, Len -Int 1,
               (L,, piece(N, PieceLen)))
          when PieceLen ==Int cfg:bitsPerByte
               andBool Len >Int 0
          [structural, anywhere]
     rule splitStructBytes(_, _, 0, L:KList)
          => dataList(L) 
          [structural, anywhere]
          
     syntax K ::= splitPointerBytes(Ptr, Type, K) [strict(3)]
     syntax K ::= "splitPointerBytes-aux" "(" Ptr "," Type "," Int "," K "," KList ")"

     rule splitPointerBytes(I:Ptr, T:Type, Len:Value)
          => splitPointerBytes-aux(I, T, value(Len), 0, .KList) 
          [structural, anywhere]
     rule splitPointerBytes-aux(I:Ptr, T:Type, Len:Int, N:Int, L:KList)
          => splitPointerBytes-aux(I, T, Len -Int 1, N +Int 1,
               (L,, piece(subObject(I, N, N), cfg:bitsPerByte)))
          when Len >Int 0
          [structural, anywhere]
     rule splitPointerBytes-aux(_, _, 0, _, L:KList) 
          => dataList(L:KList)
          [structural, anywhere]
          
     syntax K ::= splitFloatBytes(Float, Type, K) [strict(3)]
     syntax K ::= splitFloatBytes(Float, Type, Int, KList)

     rule splitFloatBytes(F:Float, T:Type, Len:Value) 
          => splitFloatBytes(F, T, value(Len) -Int 1, 
               piece(encodedFloat(F), cfg:bitsPerByte)) 
          when value(Len) >Int 0
          [structural, anywhere]
     rule splitFloatBytes(F:Float, T:Type, Len:Int, L:KList) 
          => splitFloatBytes(F, T, Len -Int 1,
               (L,, piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte))) 
          when Len >Int 0
          [structural, anywhere]
     rule splitFloatBytes(_, _:Type, 0, L:KList) 
          => dataList(L) 
          [structural, anywhere]
          
     syntax Bits ::= lowestByte(Int, Type) [function]

     rule lowestByte(I:Int, T:Type) 
          => piece(I &Int byteMaskSet, cfg:bitsPerByte)
          when hasIntegerType(T) 
          [structural]
     
     syntax Int ::= "byteMaskSet" [function]

     rule byteMaskSet => (2 ^Int cfg:bitsPerByte) -Int 1
          
     rule isByteLoc(Loc:SymLoc) => getBitOffset(Loc) ==Int 0
endmodule

