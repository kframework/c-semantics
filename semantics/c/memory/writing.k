module C-MEMORY-WRITING-SYNTAX
     syntax KList ::= explodeToBits(KList) [function]
     syntax ListItem ::= "bwrite" "(" SymLoc "," K ")"

endmodule

module C-MEMORY-WRITING
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-HELPERS-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-EXPRESSION-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-TYPING-SYNTAX
     
     // writeString and writeWString expect the user to add the '\0' to the end
     // of the strings passed
     rule [write-string]:
          writeString(Loc:SymLoc, S:String)
          => Computation((* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(asciiString(firstChar(S:String)), t(.Set, char)))
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
          writeString(_, "") => .
          [structural]
     rule [write-empty-wstring]:
          writeWString(_, .KList) => .
          [structural]
          
     syntax K ::= "writeBytes" "(" SymLoc "," K ")" [strict(2)] 
     syntax K ::= "writeBitfield" "(" SymLoc "," Type "," K ")" [strict(3)] 
     syntax Bool ::= isByteLoc(SymLoc) [function]
     syntax K ::= splitBytes(Value) [function]
     syntax K ::= calculateNewBytes(Int, K, K)
          [latex(\terminal{calcNewBytes(}{#1}, {#2}, {#3}\terminal{)}), strict(3)] 
     
     syntax K ::= "write-aux" "(" K "," Value "," K ")" [strict(2)]
     rule write(lv(Dest:SymLoc, T':Type), tv(V:KList, T:KResult)) 
          => write-aux(Dest, tv(V, T), value(bitSizeofType(T))) 
          when notBool isConstType(T')
          [structural]
     context write-aux(_, _, value(HOLE))
     
     syntax K ::= "write-specific" "(" SymLoc "," Value "," Int ")"
     
     rule [write-thread-local]:
          <k> 
               write-aux(
                    loc(N:Int @ Th:Int, Offset:Int, BitOffset:Int), 
                    tv(L:KList, T:KResult), BitSize:Int)
               => write-specific(
                    loc(N @ Th, Offset:Int, BitOffset:Int), 
                    tv(L:KList, T:KResult), BitSize:Int)
          ...</k>
          <threadId> Th </threadId>
          [structural, ndlocal]
     // write global or shared data
     rule [write]:
          write-aux(
               loc(N:Int @ 0, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:KResult), BitSize:Int)
          => write-specific(
               loc(N @ 0, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:KResult), BitSize:Int)
          [computational, ndlocal]
     // write data of "allocated" duration
     rule [write-allocated]:
          write-aux(
               loc(N:Int @ allocatedDuration, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:KResult), BitSize:Int)
          => write-specific(
               loc(N @ allocatedDuration, Offset:Int, BitOffset:Int), 
               tv(L:KList, T:KResult), BitSize:Int)
          [computational, ndlocal]
     
     rule [write-normal]:
          write-specific(Loc:SymLoc, tv(V:K, T:KResult), BitSize:Int)
          => writeBytes(Loc, splitBytes(tv(V, T)))
          when (BitSize %Int cfg:bitsPerByte ==Int 0)
               andBool isByteLoc(Loc)
               andBool (notBool isBitfieldType(T))
               andBool (notBool hasUnionMarker(T))
          [structural]
     rule [write-normal-union-field]:
          (. => makeUnknown(Loc, t(.Set, unionType(S))))
          ~> write-specific(Loc:SymLoc, 
               tv(_, t((SetItem(fromUnion(S:Id)) => .Set) _, _)), _:Int)
          when isByteLoc(Loc)
          [structural]
          
     syntax K ::= "makeUnknown" "(" SymLoc "," Type ")"
     syntax K ::= "makeUnknown-aux" "(" SymLoc "," Type "," K ")"
     context makeUnknown-aux(_, _, value(HOLE))
     
     rule makeUnknown(Loc:SymLoc, T:KResult)
          => makeUnknown-aux(Loc, T, value(byteSizeofType(T))) 
          [structural]
     rule <k>
               makeUnknown-aux(loc(Base:SymBase, Offset:Int, 0), _, Len':Int)
               => .
          ...</k>
          <br/>
          <mem>... 
               Base |-> memblock(Len:Int, _, 
               M:Map => M:Map[
                    piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte) 
                    / Offset to (Offset +Int Len')]) 
          ...</mem>
          when Len >=Int Offset +Int Len'
          [large, structural]
          
     syntax Bool ::= hasUnionMarker(Type) [function]
     rule hasUnionMarker(t(SetItem(fromUnion(_:Id)) _, _)) => true
     rule hasUnionMarker(t(.Set, _)) => false
     rule hasUnionMarker(t(S:Set (SetItem(L:KLabel(_:KList))), K:K))
          => hasUnionMarker(t(S:Set, K:K))
          when L:KLabel =/=KLabel 'fromUnion
          [structural]
     
     rule [write-struct]:
          write-specific(Loc:SymLoc, 
               tv((V:K,, V':K,, L:KList), T:KResult), BitSize:Int)
          => writeBytes(Loc, dataList((V,, V',, L)))
          when (BitSize:Int %Int cfg:bitsPerByte ==Int 0)
               andBool isByteLoc(Loc)
               andBool (notBool isBitfieldType(T:KResult))
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
          write-specific(Loc:SymLoc, tv(I:Int, T:KResult), BitSize:Int)
          => writeBitfield(
               Loc
               , T:KResult
               , calculateNewBytes(
                    getBitOffset(Loc)
                    , piece(I, BitSize:Int)
                    , extractBytesFromMem(floorLoc(Loc), 
                         bitsToBytes(BitSize:Int +Int getBitOffset(Loc))
                    )
               )
          )
          when (BitSize:Int %Int cfg:bitsPerByte =/=Int 0)
               orBool (notBool(isByteLoc(Loc)))
               orBool (isBitfieldType(T:KResult) 
                    andBool notBool hasUnionMarker(T:KResult))
               andBool (I:Int >=Int 0)
          [structural]
          
     rule writeBitfield(Loc:SymLoc, _, dataList(L:KList))
          => writeBytes(floorLoc(Loc), dataList(L))
          [structural] 
          
     syntax K ::= "calculateNewBytes-aux" "(" Int "," K "," K "," KList ")"
     rule calculateNewBytes(Len:Int, N:Bits, dataList(L:KList)) 
          => calculateNewBytes-aux(Len:Int, dataList(explodeToBits(N)),
               dataList(explodeToBits(L:KList)), .KList)
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
     
     rule <k> writeBytes(Loc:SymLoc, dataList((V:K,, L:KList)))
               => writeByte(Loc, V)
               ~> writeBytes(Loc +bytes 1, dataList(L))
          ...</k>
          [structural]
     rule [write-byte-buffer]:
          <k> writeByte(loc(Base:SymBase, Offset:Int, 0), V:K) => . ...</k>
          <buffer>...
               (.List => bwrite(loc(Base, Offset:Int, 0), V:K))
          </buffer>
          <br/>
          <mem>... Base |-> memblock(Len:Int, Attrs:Bag, _) ...</mem>
          <locsWrittenTo>
               Locs:Bag (.Bag => BagItem(loc(Base, Offset, 0)))
          </locsWrittenTo>
          <notWritable> NotWritable:Map </notWritable>
          when (notBool BagItem(loc(Base, Offset, 0)) in Locs:Bag)
               andBool (Offset:Int <Int Len:Int)
               andBool (notBool (BagItem(mconst) in Attrs))
               andBool (notBool (loc(Base, Offset, 0) in keys NotWritable:Map))
          [large, structural]
          
     rule [commit-byte]:
          <buffer>
               (bwrite(loc(Base:SymBase, Offset:Int, 0), V:K) => .List)
          ...</buffer>
          <mem>...
               Base |-> memblock(Len:Int, _, M:Map => M:Map[V / Offset])
          ...</mem>
          when Offset <Int Len
          [structural]
     rule writeBytes(_, dataList(.KList)) => .K
          [structural] 
          
     // this general rule is useful for unknowns, abstracts, etc
     rule [splitBytes-other]:
          splitBytes(tv((N:Bits,, .KList), T:Type))
          => dataList(piece(N, cfg:bitsPerByte))
          when isCharType(T)
     rule [splitBytes-char]:
          splitBytes(tv(N:Bits, T:Type))
          => dataList(piece(N, cfg:bitsPerByte))
          when isCharType(T) andBool (isInt(N) ==K false)
     rule [splitBytes-int]:
          splitBytes(tv(I:Int, T:Type)) 
          => splitIntegerBytes(I, T, bitsToBytes(value(bitSizeofType(T))))
          when hasIntegerType(T)
     rule [splitBytes-float]:
          splitBytes(tv(F:Float, T:Type)) 
          => splitFloatBytes(F, T, value(byteSizeofType(T)))
          when isFloatType(T)
     rule [splitBytes-pointer]:
          splitBytes(tv(I:Ptr, t(S:Set, pointerType(T:KResult)))) 
          => splitPointerBytes(I, t(S, pointerType(T)), 
               value(byteSizeofType(t(.Set, pointerType(T)))))
     rule [splitBytes-struct]:
          splitBytes(tv(L:KList, t(S:Set, structType(I:Id)))) 
          => splitStructBytes(dataList(L), t(S, structType(I)), 
               value(byteSizeofType(t(S, structType(I)))))
     rule [splitBytes-union]:
          splitBytes(tv(L:KList, t(S:Set, unionType(I:Id)))) 
          => splitStructBytes(dataList(L), t(S, unionType(I)), 
               value(byteSizeofType(t(S, unionType(I)))))
     
     syntax K ::= splitIntegerBytes(Int, Type, Int) [function]
     syntax K ::= "splitIntegerBytes-aux" "(" Int "," Type "," Int "," KList ")"
          [function]
     rule splitIntegerBytes(I:Int, T:Type, Len:Int) 
          => splitIntegerBytes-aux(I, T, Len, .KList)
     rule splitIntegerBytes-aux(I:Int, T:Type, Len:Int, L:KList)
          => splitIntegerBytes-aux(I >>Int cfg:bitsPerByte, T, Len -Int 1, 
               (L,, lowestByte(I, T)))
          when Len >Int 0
     rule splitIntegerBytes-aux(_, _, 0, L:KList)
          => dataList(L) 
          
     syntax K ::= splitStructBytes(K, K, K)
     syntax K ::= splitStructBytes(K, K, K, KList)
     context splitStructBytes(_, _, value(HOLE)) 
     rule splitStructBytes(dataList(L:KList), T:KResult, Len:Int) 
          => splitStructBytes(dataList(L:KList), T:KResult, Len:Int, .KList) 
          [structural, anywhere]
     rule splitStructBytes(dataList((piece(N:Int, PieceLen:Int),, Rest:KList)),
               T:KResult, Len:Int, L:KList)
          => splitStructBytes(dataList(Rest:KList), T:KResult, Len:Int -Int 1,
               (L:KList,, piece(N:Int, PieceLen:Int)))
          when PieceLen:Int ==Int cfg:bitsPerByte
               andBool Len:Int >Int 0
          [structural, anywhere]
     rule splitStructBytes(_, _, 0, L:KList)
          => dataList(L:KList) 
          [structural, anywhere]
          
     syntax K ::= splitPointerBytes(Ptr, K, K)
     syntax K ::= "splitPointerBytes-aux" "(" Ptr "," K "," K "," K "," KList ")"
     context splitPointerBytes(_, _, value(HOLE))
     rule splitPointerBytes(I:Ptr, T:KResult, Len:Int)
          => splitPointerBytes-aux(I, T, Len, 0, .KList) 
          [structural, anywhere]
     rule splitPointerBytes-aux(I:Ptr, T:KResult, Len:Int, N:Int, L:KList)
          => splitPointerBytes-aux(I, T, Len -Int 1, N +Int 1,
               (L,, piece(subObject(I, N, N), cfg:bitsPerByte)))
          when Len >Int 0
          [structural, anywhere]
     rule splitPointerBytes-aux(_, _, 0, _, L:KList) 
          => dataList(L:KList)
          [structural, anywhere]
          
     syntax K ::= splitFloatBytes(K, K, K)
     syntax K ::= splitFloatBytes(K, K, K, KList)
     context splitFloatBytes(_, _, value(HOLE)) 
     rule splitFloatBytes(F:Float, T:KResult, Len:Int) 
          => splitFloatBytes(F:Float, T:KResult, Len:Int -Int 1,
               piece(encodedFloat(F:Float), cfg:bitsPerByte)) 
          when Len:Int >Int 0
          [structural, anywhere]
     rule splitFloatBytes(F:Float, T:KResult, Len:Int, L:KList) 
          => splitFloatBytes(F:Float, T:KResult, Len:Int -Int 1,
               (L:KList,, piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte))) 
          when Len:Int >Int 0
          [structural, anywhere]
     rule splitFloatBytes(_, _:KResult, 0, L:KList) 
          => dataList(L:KList) 
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

