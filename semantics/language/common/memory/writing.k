module C-MEMORY-WRITING-SYNTAX
     // location, value
     syntax K ::= write(K, K) [strict(2)]

     // Either buffered or unbuffered depending on whether we're executing.
     // If the flag is true, then we disable checking undefinedness checking
     // (i.e., multiple, unsequenced writes to a single location). This is
     // always disabled in direct io mode.
     syntax K ::= writeBytes(SymLoc, K, Bool) [strict(2)] 
     syntax K ::= writeByte(SymLoc, CValue)

     syntax List ::= explodeToBits(List) [function]

     // TODO(chathhorn): For error.k.
     syntax K ::= "write-aux" "(" SymLoc "," Value "," CSize ")"
endmodule

module C-MEMORY-WRITING
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX
          
     syntax K ::= writeBitfield(SymLoc, Type, K) [strict(3)] 
     syntax Bool ::= isByteLoc(SymLoc) [function]
     syntax K ::= splitBytes(Value) [function]
     syntax K ::= calculateNewBytes(Int, K, K)
          [latex(\terminal{calcNewBytes(}{#1}, {#2}, {#3}\terminal{)}), strict(3)] 
     
     rule write(lv(Dest:SymLoc, T':Type), tv(V:CValue, T:Type)) 
          => write-aux(Dest, tv(V, T), bitSizeofType(T)) 
          when notBool isConstType(T')
          [structural]
     
     syntax K ::= "write-specific" "(" SymLoc "," Value "," CSize ")"
     
     // Write thread-local or auto.
     rule [write-thread-local]:
          write-aux(Loc:SymLoc, tv(V:CValue, T:Type), NBits:CSize)
          => write-specific(Loc:SymLoc, tv(V, T), NBits)
          when isThreadDuration(Loc)
          [structural]
     // Write global, shared data, or "allocated" duration.
     rule [write-allocated]:
          write-aux(Loc:SymLoc, tv(V:CValue, T:Type), NBits:CSize)
          => write-specific(Loc, tv(V, T), NBits)
          when notBool isThreadDuration(Loc)
          [ndtrans]

     syntax Set ::= attrs(Type) [function]
     rule attrs(t(S:Set, _)) => S

     rule [write-normal]:
          write-specific(Loc:SymLoc, tv(V:CValue, T:Type), NBits:Int)
          => writeBytes(Loc, splitBytes(tv(V, T)), false)
          when (NBits %Int cfg:bitsPerByte ==Int 0)
               andBool (isByteLoc(Loc) ==K true)
               andBool (isBitfieldType(T) =/=K true)
               andBool (notBool hasUnionMarker(T))
          [structural]
     rule [write-normal-union-field]:
          <k> (. => makeUnknown(Loc, t(.Set, unionType(S, bitSizeofUnion(Info), Info))))
               ~> write-specific(Loc:SymLoc, 
                    tv(_, t((SetItem(fromUnion(S:Id)) => .Set) _, _)), _)
          ...</k>
          <structs>...
               S |-> Info:FieldInfo
          ...</structs>
          when isByteLoc(Loc)
          [structural]
          
     syntax K ::= makeUnknown(SymLoc, Type) [function]
     syntax K ::= "makeUnknown-aux" "(" SymLoc "," K ")" [strict(2)]
     
     rule makeUnknown(Loc:SymLoc, T:Type)
          => makeUnknown-aux(Loc, byteSizeofType(T)) 
     rule makeUnknown-aux(Loc:SymLoc, Len:TypedValue)
          => writeBytes(Loc, dataList(times(value(Len), 
               piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte))), true)
          [structural]
          
     syntax Bool ::= hasUnionMarker(Type) [function]
     rule hasUnionMarker(T:Type) => #hasUnionMarker(T) ==K true

     syntax Bool ::= #hasUnionMarker(Type) [function]
     rule #hasUnionMarker(t((_:Set SetItem(fromUnion(_)) _:Set), _)) => true
     
     rule [write-struct]:
          write-specific(Loc:SymLoc, 
               tv(agg(ListItem(V:K) ListItem(V':K) L:List), T:Type), 
               NBits:Int)
          => writeBytes(Loc, dataList(ListItem(V) ListItem(V') L), false)
          when (NBits:Int %Int cfg:bitsPerByte ==Int 0)
               andBool isByteLoc(Loc)
               andBool (notBool isBitfieldType(T))
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
     
     rule [massage-bitfield]:
          write-specific(Loc:SymLoc, tv(I:Int, T:Type), NBits:Int)
          => write-specific(Loc, tv(justBits(I, T), T), NBits)
          when (NBits %Int cfg:bitsPerByte =/=Int 0
               orBool notBool(isByteLoc(Loc))
               orBool isBitfieldType(T))
               andBool (I <Int 0)
          [structural]
     
     rule [write-bitfield]:
          write-specific(Loc:SymLoc, tv(I:Int, T:Type), NBits:Int)
          => writeBitfield(
               Loc
               , T
               , calculateNewBytes(
                    getBitOffset(Loc)
                    , piece(I, NBits)
                    , readBytes(floorLoc(Loc), 
                         bitsToBytes(NBits +Int getBitOffset(Loc))
                    )
               )
          )
          when (NBits %Int cfg:bitsPerByte =/=Int 0)
               orBool (notBool isByteLoc(Loc))
               orBool (isBitfieldType(T) 
                    andBool notBool hasUnionMarker(T))
               andBool (I >=Int 0)
          [structural]
          
     rule writeBitfield(Loc:SymLoc, _, dataList(L:List))
          => writeBytes(floorLoc(Loc), dataList(L), false)
          [structural] 
          
     syntax K ::= "calculateNewBytes-aux" "(" Int "," K "," K "," List ")"
     rule calculateNewBytes(Len:Int, N:Bits, dataList(L:List)) 
          => calculateNewBytes-aux(Len, dataList(explodeToBits(ListItem(N))),
               dataList(explodeToBits(L)), .List)
          [structural]
     
     syntax K ::= joinBitsToBytes(List) [function]
     syntax K ::= "joinBitsToBytes-aux" "(" K "," K ")" [function]
     
     // fixme sNat
     rule calculateNewBytes-aux(N:Int, K:K, 
               dataList(ListItem(piece(Bit:Bits, 1)) L:List), Result:List) 
          => calculateNewBytes-aux(N -Int 1, K, 
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
     rule [splitBytes-other]:
          splitBytes(tv(N:Bits, T:Type))
          => dataList(ListItem(piece(N, cfg:bitsPerByte)))
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
          splitBytes(tv(I:Ptr, t(S:Set, pointerType(T:Type)))) 
          => splitPointerBytes(I, t(S, pointerType(T)), 
               byteSizeofType(t(.Set, pointerType(T))))
     rule [splitBytes-struct]:
          splitBytes(tv(agg(L:List), t(S:Set, structType(X:Id, NBits:Int, Info:FieldInfo)))) 
          => splitStructBytes(dataList(L), t(S, structType(X, NBits, Info)), 
               byteSizeofType(t(S, structType(X, NBits, Info))))
     rule [splitBytes-union]:
          splitBytes(tv(agg(L:List), t(S:Set, unionType(X:Id, NBits:Int, Info:FieldInfo)))) 
          => splitStructBytes(dataList(L), t(S, unionType(X, NBits, Info)), 
               byteSizeofType(t(S, unionType(X, NBits, Info))))
     
     syntax K ::= splitIntegerBytes(Int, Type, K) [strict(3)]
     syntax K ::= "splitIntegerBytes-aux" "(" Int "," Type "," Int "," List ")"
          [function]
     rule splitIntegerBytes(I:Int, T:Type, Len:TypedValue) 
          => splitIntegerBytes-aux(I, T, value(Len), .List)
     rule splitIntegerBytes-aux(I:Int, T:Type, Len:Int, L:List)
          => splitIntegerBytes-aux(I >>Int cfg:bitsPerByte, T, Len -Int 1, 
               L ListItem(lowestByte(I, T)))
          when Len >Int 0
     rule splitIntegerBytes-aux(_, _, 0, L:List)
          => dataList(L) 
          
     syntax K ::= splitStructBytes(K, Type, K) [strict(3)]
     syntax K ::= splitStructBytes(K, Type, Int, List) 

     rule splitStructBytes(dataList(L:List), T:Type, Len:TypedValue) 
          => splitStructBytes(dataList(L), T, value(Len), .List) 
          [structural, anywhere]
     rule splitStructBytes(
          dataList(ListItem(piece(N:Bits, PieceLen:Int)) Rest:List),
               T:Type, Len:Int, L:List)
          => splitStructBytes(dataList(Rest), T, Len -Int 1,
               L ListItem(piece(N, PieceLen)))
          when PieceLen ==Int cfg:bitsPerByte
               andBool Len >Int 0
          [structural, anywhere]
     rule splitStructBytes(_, _, 0, L:List) => dataList(L) 
          [structural, anywhere]
          
     syntax K ::= splitPointerBytes(Ptr, Type, K) [strict(3)]
     syntax K ::= "splitPointerBytes-aux" "(" Ptr "," Type "," Int "," K "," List ")"

     rule splitPointerBytes(I:Ptr, T:Type, Len:TypedValue)
          => splitPointerBytes-aux(I, T, value(Len), 0, .List) 
          [structural, anywhere]
     rule splitPointerBytes-aux(I:Ptr, T:Type, Len:Int, N:Int, L:List)
          => splitPointerBytes-aux(I, T, Len -Int 1, N +Int 1,
               L ListItem(piece(subObject(I, N, N), cfg:bitsPerByte)))
          when Len >Int 0
          [structural, anywhere]
     rule splitPointerBytes-aux(_, _, 0, _, L:List) 
          => dataList(L:List)
          [structural, anywhere]
          
     syntax K ::= splitFloatBytes(Float, Type, K) [strict(3)]
     syntax K ::= splitFloatBytes(Float, Type, Int, List)

     rule splitFloatBytes(F:Float, T:Type, Len:TypedValue) 
          => splitFloatBytes(F, T, value(Len) -Int 1, 
               ListItem(piece(encodedFloat(F), cfg:bitsPerByte)))
          when value(Len) >Int 0
          [structural, anywhere]
     rule splitFloatBytes(F:Float, T:Type, Len:Int, L:List) 
          => splitFloatBytes(F, T, Len -Int 1,
               L ListItem(piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte))) 
          when Len >Int 0
          [structural, anywhere]
     rule splitFloatBytes(_, _:Type, 0, L:List) 
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

