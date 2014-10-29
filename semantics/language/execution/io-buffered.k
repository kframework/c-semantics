module C-IO-BUFFERED-SYNTAX
     syntax K ::= realloc(SymBase, SymBase, Int, Int)

     // deletes the base object from memory, given a location
     syntax K ::= deleteObject(SymBase)
     // deletes the base object from memory, given a location and it size (as a
     // check)
     syntax K ::= deleteSizedObject(SymBase, Int)

     syntax K ::= writeByte(SymLoc, CValue)
endmodule

module C-IO-BUFFERED
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-CHECK-LOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     syntax ListItem ::= bwrite(SymLoc, K)

     syntax K ::=  writeBytes(SymLoc, List)
     rule <k> writeBytes(Loc:SymLoc, dataList(Bytes:List), T:Type)
               => checkWrite(Loc, T)  
               // TODO(chathhorn): this is pretty inefficient -- setEff does nothing
               // if the object has a declared type and checkEff is only meaningful
               // in the case of a declared type being present. Also it'd be nice to
               // combine the checks.
               ~> setEffectiveType(Loc, T)
               ~> checkEffectiveType(T, getEffectiveType(Loc))
               ~> setModified(Loc, T)
               ~> writeBytes(Loc, Bytes)
          ...</k>
          <initializing> 0 </initializing>
     rule <k> writeBytes(Loc:SymLoc, dataList(Bytes:List), _)
               => writeBytes(Loc, Bytes)
          ...</k>
          <initializing> I:Int </initializing>
          when I >Int 0

     syntax K ::= setModified(SymLoc, Type)
     syntax K ::= setModified(SymLoc, Type, Set)
     rule <k> setModified(Loc:SymLoc, T:Type)
               => setModified(Loc, T, keys(Modified))
          ...</k>
          <activeBlocks> Modified:Map </activeBlocks>

     rule <k> setModified(Loc:SymLoc, T:Type,
               (SetItem(Tag:RestrictTag) => .Set) _)
          ...</k>
          <activeBlocks>...
               Tag |-> activity(_, _
                    Loc |-> (NBytes:Int => maxInt(NBytes, byteSizeofType(T))))
          ...</activeBlocks>
     rule <k> setModified(Loc:SymLoc, T:Type,
               (SetItem(Tag:RestrictTag) => .Set) _)
          ...</k>
          <activeBlocks>...
               Tag |-> activity(_, Modified:Map
                    (.Map => Loc |-> byteSizeofType(T)))
          ...</activeBlocks>
          when notBool Loc in keys(Modified)
     rule setModified(_, _, .Set) => .

     rule writeBytes(Loc:SymLoc, ListItem(V:CValue) L:List)
          => writeByte(Loc, V)
          ~> writeBytes(Loc +bytes 1, L)
          [structural]
     rule writeBytes(_, .List) => .
          [structural] 

     syntax K ::= checkWrite(SymLoc, Type)
     rule <k> checkWrite(loc(Base:SymBase, Offset:Int), T:Type) => . ...</k>
          <thread-id> ThreadId:Int </thread-id>
          <mem>... Base |-> object(ObjT:Type, Len:Int, _) ...</mem>
          <locs-written>
               Locs:Bag (.Bag => BagItem(loc(Base, Offset)))
          </locs-written>
          when // Sequencing.
               (notBool BagItem(loc(Base, Offset)) in Locs)
               // Bounds.
               andBool (Offset <Int Len)
               // Const.
               andBool (notBool Const in getQualsAtOffset(ObjT, Offset))
               // Volatile.
               andBool ((notBool Volatile in getQualsAtOffset(ObjT, Offset))
                    orBool isVolatileType(T))
               // Cross-thread writes.
               andBool notBool ((isThreadDuration(loc(Base, Offset))
                         orBool isAutoDuration(loc(Base, Offset)))
                    andBool (ThreadId =/=K getThreadId(loc(Base, Offset))))
          [structural]
     rule <k> (. => UNDEF("EIO1",
               "Unsequenced side effect on scalar object with side effect of same object.",
               "6.5") )
               ~> checkWrite(Loc:SymLoc, _) 
          ...</k>
          <locs-written> Locs:Bag </locs-written>
          when BagItem(Loc) in Locs:Bag
          [structural] 
     // TODO(chathhorn): probably redundant.
     rule <k> (. => UNDEF("EIO2",
               "Trying to write outside the bounds of an object.",
               "6.5.6:8"))
               ~> checkWrite(loc(Base:SymBase, Offset:Int), _) 
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          when Offset >=Int Len orBool Offset <Int 0
          [structural] 
     rule <k> (. => UNDEF("EIO3",
               "Trying to modify an object declared with const type.",
               "6.7.3"))
               ~> checkWrite(loc(Base:SymBase, Offset:Int), _)
          ...</k>
          <mem>... Base |-> object(ObjT:Type, _, _) ...</mem>
          when Const in getQualsAtOffset(ObjT, Offset)
          [structural]
     rule <k> (. => UNDEF("EIO4",
               "Trying to modify an object declared with volatile type through a non-volatile lvalue.",
               "6.7.3"))
               ~> checkWrite(loc(Base:SymBase, Offset:Int), T:Type)
          ...</k>
          <mem>... Base |-> object(ObjT:Type, _, _) ...</mem>
          when notBool isVolatileType(T)
               andBool Volatile in getQualsAtOffset(ObjT, Offset)
          [structural]
     rule <k> (. => UNSPEC("EIO5",
               "Trying to modify an object with thread or auto storage duration in a thread other than the one in which the object is associated.",
               "6.2.4:4-5"))
               ~> checkWrite(Loc:SymLoc, _)
          ...</k>
          <thread-id> ThreadId:Int </thread-id>
          when (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool (ThreadId =/=K getThreadId(Loc))
          [structural]

     rule <k> writeByte(loc(Base:SymBase, Offset:Int), V:CValue) => . ...</k>
          <buffer>... (.List => bwrite(loc(Base, Offset), V)) </buffer>
          [structural]

     rule <buffer>
               (bwrite(loc(Base:SymBase, Offset:Int), V:K) => .List)
          ...</buffer>
          <mem>...
               Base |-> object(_, Len:Int, M:Map => M[V <- Offset])
          ...</mem>
          when Offset <Int Len
          [structural]

     syntax Set ::= locations(List) [function]
     rule locations(.List) => .Set
     rule locations(bwrite(Loc:SymLoc, _) L:List)
          => SetItem(Loc) locations(L)

     rule <k> readBytes(Loc:SymLoc, Size:Int, T:Type)
               => checkEffectiveType(T, getEffectiveType(Loc))
               ~> readBytes-aux(Loc, Size, .List, T) 
          ...</k>
          <thread-id> ThreadId:Int </thread-id>
          when notBool ((isThreadDuration(Loc) orBool isAutoDuration(Loc))
                    andBool (ThreadId =/=K getThreadId(Loc)))
          [structural] 
     rule <k> (. => UNSPEC("EIO6", "Attempting to access an object with thread or auto storage duration in a thread other than the one in which the object is associated.", "6.2.4:4-5"))
               ~> readBytes(Loc:SymLoc, _, _)
          ...</k>
          <thread-id> ThreadId:Int </thread-id>
          when (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool (ThreadId =/=K getThreadId(Loc))
          [structural]

     // loc, size in bytes, aux list
     syntax K ::= "readBytes-aux" "(" SymLoc "," Int "," List "," Type ")"
     rule readBytes-aux(Loc:SymLoc, Size:Int, Aux:List, T:Type)
          => readByte(Loc, T)
          ~> readBytes-aux(Loc +bytes 1, Size -Int 1, Aux, T)
          when Size >Int 0
          [structural]
     rule readBytes-aux(_, 0, Aux:List, _) => dataList(bvalues(Aux)) 
          [structural]
     rule (tv(V:CValue, T:Type) => .K)
          ~> readBytes-aux(_, _, 
               (Aux:List => Aux ListItem(tv(V, T))), _)
          [structural]

     syntax List ::= bvalues(List) [function]
     rule bvalues(ListItem(tv(K:K, _)) L:List) => ListItem(K) bvalues(L)
     rule bvalues(.List) => .List

     syntax Error ::= "errorReadOutOfBounds"
                    | "errorUnseqEffects"
                    | "errorNonVolatileLVal"

     syntax K ::= readByte(SymLoc, Type)
     rule <k> readByte(loc(Base:SymBase, Offset:Int), T:Type)
               // TODO(chathhorn): do we really need to check this stuff every
               // byte?
               => assert(notBool (BagItem(loc(Base, Offset)) in Locs),
                    errorUnseqEffects)
               ~> assert(Offset <Int Len, errorReadOutOfBounds)
               ~> assert((notBool Volatile in getQualsAtOffset(ObjT, Offset))
                    orBool isVolatileType(T),
                    errorNonVolatileLVal)
               ~> tv(V, t(.Set, no-type))
          ...</k>
          <mem>...
               Base |-> object(ObjT:Type, Len:Int, (_ Offset:Int |-> V:K)) 
          ...</mem>
          <locs-written> Locs:Bag </locs-written>
          <buffer> .List </buffer>
          [structural]
     rule <k> readByte(loc(Base:SymBase, Offset:Int), T:Type)
               => assert(notBool (BagItem(loc(Base, Offset)) in Locs),
                    errorUnseqEffects)
               ~> assert(Offset <Int Len, errorReadOutOfBounds)
               ~> assert((notBool Volatile in getQualsAtOffset(ObjT, Offset))
                    orBool isVolatileType(T),
                    errorNonVolatileLVal)
               ~> tv(V, t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> object(ObjT:Type, Len:Int, (_ Offset:Int |-> V:K)) 
          ...</mem>
          <locs-written> Locs:Bag </locs-written>
          <buffer> Mem:List </buffer>
          when notBool loc(Base, Offset) in locations(Mem)
          [structural]
     rule <k> readByte(loc(Base:SymBase, Offset:Int), T:Type) 
               => assert(Offset:Int <Int Len:Int, errorReadOutOfBounds)
               ~> assert((notBool Volatile in getQualsAtOffset(ObjT, Offset))
                    orBool isVolatileType(T), 
                    errorNonVolatileLVal)
               ~> tv(piece(trap, cfg:bitsPerByte), t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> object(ObjT:Type, Len:Int,
               M:Map => M[
                    piece(trap, cfg:bitsPerByte) <- Offset]) 
          ...</mem>
          <buffer> Mem:List </buffer>
          when (notBool loc(Base, Offset) in locations(Mem))
               andBool (notBool Offset in (keys(M)))
               andBool (notBool isStaticDuration(loc(Base, Offset)))
          [structural]
     rule <k> readByte(loc(Base:SymBase, Offset:Int), T:Type) 
               => assert(Offset:Int <Int Len:Int, errorReadOutOfBounds)
               ~> assert((notBool Volatile in getQualsAtOffset(ObjT, Offset))
                    orBool isVolatileType(T), 
                    errorNonVolatileLVal)
               ~> tv(piece(0, cfg:bitsPerByte), t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> object(ObjT:Type, Len:Int, 
               M:Map => M[piece(0, cfg:bitsPerByte) <- Offset]) 
          ...</mem>
          <buffer> Mem:List </buffer>
          when (notBool loc(Base, Offset) in locations(Mem))
               andBool (notBool Offset in (keys(M)))
               andBool (isStaticDuration(loc(Base, Offset))
                    orBool isThreadDuration(loc(Base, Offset)))
          [structural]

     // Resolve a linker address to a real "physical" address.
     rule <k> readByte(loc((LinkBase:SymBase => Base), _), _) ...</k>
          <linkings>... LinkBase |-> Base:SymBase ...</linkings>
          [structural]

          // TODO(chathhorn): perf, elided
//        rule [read-byte-buffer]:
//             <k> readByte(Loc:SymLoc) 
//                  => assert(notBool BagItem(Loc) in Locs:Bag, errorUnseqEffects)
//                  ~> tv(V:K, t(.Set, no-type))
//             ...</k>
//             <locs-written> Locs:Bag </locs-written>
//             <buffer>... bwrite(Loc, V:K) Mem:List </buffer>
//             when notBool Loc in locations(Mem:List)
//             [structural]
//             // for speed in interpretation; forces local buffer to be flushed
//             // before a read
//             //[interpRule] 

     rule errorReadOutOfBounds
          => UNDEF("EIO7",
               "reading outside the bounds of an object.",
               "6.2.4")
          [structural]
     rule errorUnseqEffects
          => UNDEF("EIO8",
               "unsequenced side effect on scalar object with value computation of same object.",
               "6.5")
          [structural]
     rule errorNonVolatileLVal
          => UNDEF("EIO9",
               "trying to access an object declared with volatile type through a non-volatile lvalue.",
               "6.7.3")
          [structural]

     rule <k> realloc(Old:SymBase, New:SymBase, OldLen:Int, NewLen:Int)
               => alloc(New, t(.Set, no-type), NewLen)
               ~> copyBytes(minInt(OldLen, NewLen), Old, New)
               ~> copyObjectType(Old, New)
               ~> deleteSizedObject(Old, OldLen)
          ...</k>
          [structural]

     syntax K ::= copyBytes(Int, SymBase, SymBase)
     rule <k> copyBytes((N':Int => N' -Int 1), Old:SymBase, New:SymBase)
          ...</k>
          <mem>... 
               Old |-> object(_, _, _ N:Int |-> K:K)
               New |-> object(_, _, _ (.Map => (N' -Int 1) |-> K))
          ...</mem>
          when (N' ==Int N +Int 1) andBool (N' >Int 0)
          [structural]   
     rule <k> copyBytes((N':Int => N' -Int 1), Old:SymBase, _)
          ...</k>
          <mem>... Old |-> object(_, _, M:Map) ...</mem>
          when (notBool (N' -Int 1) in keys(M)) andBool (N' >Int 0)
          [structural]
     rule copyBytes(0, _, _) => .
          [structural]   

     syntax K ::= copyObjectType(SymBase, SymBase)
     rule <k> copyObjectType(Old:SymBase, New:SymBase) => . ...</k>
          <mem>... 
               Old |-> object(T:Type, _, _)
               New |-> object((_ => T), _, _)
          ...</mem>

     rule <k> deleteSizedObject(Base:SymBase, Len:Int) => . 
          ...</k>
          <mem>... Base |-> object(_, Len, _) => .Map ...</mem>
          // fixme could make this more relaxed by checking of block is in
          // buffer, not just empty
          <buffer> .List </buffer>
          [structural] 

     rule <k> deleteObject(Base:SymBase) => .K ...</k>
          <mem>... Base |-> object(_, _, _) => .Map ...</mem>
          <buffer> .List </buffer>
          [structural] 

     syntax K ::= getEffectiveType(SymLoc)
     rule <k> getEffectiveType(loc(Base:SymBase, Offset:Int))
               => getTypeAtOffset(T, Offset)
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          when notBool isNoType(T)
          [structural]
     rule <k> getEffectiveType(loc(Base:SymBase, Offset:Int)) => T' ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          <effective-types>...
               loc(Base, Offset) |-> T':Type
          ...</effective-types>
          when isNoType(T)
          [structural]
     rule <k> getEffectiveType(loc(Base:SymBase, Offset:Int)) => T ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          <effective-types> EffTypes:Map </effective-types>
          when isNoType(T)
               andBool notBool (loc(Base, Offset) in keys(EffTypes))
          [structural]

     syntax K ::= setEffectiveType(SymLoc, Type)
     rule <k> setEffectiveType(loc(Base:SymBase, _), T':Type) => .
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          when notBool isNoType(T) orBool hasCharType(T')
          [structural]
     rule <k> setEffectiveType(loc(Base:SymBase, Offset:Int), T':Type) => .
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          <effective-types>...
               .Map => loc(Base, Offset) |-> T'
          ...</effective-types>
          when isNoType(T) andBool notBool hasCharType(T')
          [structural]

     syntax K ::= checkEffectiveType(Type, K) [strict(2)]
     rule checkEffectiveType(L:Type, Eff:Type) => .
          when (#effectivelyCompat(L, Eff) ==K true)
               orBool isNoType(Eff)
          [structural]
     rule (. => UNDEF("EIO10", "Type of lvalue not compatible with the effective type of the object being accessed.", "6.5:7"))
          ~> checkEffectiveType(L:Type, Eff:Type)
          when (#effectivelyCompat(L, Eff) =/=K true)
               andBool notBool isNoType(Eff)
          [structural]

     // An  object shall have its stored value accessed only by an lvalue
     // expression that has one of
     syntax Bool ::= "#effectivelyCompat" "(" Type "," Type ")" [function]
     // - a type compatible with the effective type of the object,
     // - a qualified version of a type compatible with the effective type of
     // the object,
     rule #effectivelyCompat(L:Type, Eff:Type) => true
          when areCompatible(stripQualifiers(L), stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     // - a type that is the signed or unsigned type corresponding to the
     // effective type of the object,
     // - a type that is the signed or unsigned type corresponding to a
     // qualified version of the effective type of the object,
     rule #effectivelyCompat(L:Type, Eff:Type) => true
          when areCompatible(correspondingUnsignedType(stripQualifiers(L)),
                    stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     rule #effectivelyCompat(L:Type, Eff:Type) => true
          when areCompatible(correspondingSignedType(stripQualifiers(L)),
                    stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     // - an aggregate or union type that includes one of the aforementioned
     // types among its members (including, recursively, a member of a
     // subaggregate or contained union), or
     rule #effectivelyCompat(L:Type, Eff:Type)
          => #effectivelyCompat(L, effInnerType(Eff))
          when isAggregateType(Eff)
               andBool notBool (areCompatible(stripQualifiers(L), stripQualifiers(Eff))
                    andBool getQualifiers(Eff) <=Set getQualifiers(L))
               andBool notBool hasCharType(L)
     // TODO(chathhorn): this is where things get sketchy. Very unclear
     // about the implications of strict aliasing w/r/t unions. As it is, we
     // let it pass if we're compatible with one of the union members of the
     // effective type.
     rule #effectivelyCompat(L:Type,
     // TODO(chathhorn): some obnoxious decomposing/recomposing going on here.
               t(Mods:Set, unionType(X:CId, Sz:Int, fieldInfo(Decls:List, Types:Map, Offs:Map))))
          => effectivelyCompatWithUnion(L, values(Types))
          when notBool (areCompatible(stripQualifiers(L),
                         stripQualifiers(t(Mods, unionType(X, Sz, fieldInfo(Decls, Types, Offs)))))
                    andBool intersectSet(Mods, typeQualifiers)
                         <=Set getQualifiers(L))
               andBool notBool hasCharType(L)
     // - a character type.
     rule #effectivelyCompat(L:Type, _) => true
          when hasCharType(L)

     syntax Bool ::= effectivelyCompatWithUnion(Type, List) [function]
     rule effectivelyCompatWithUnion(T:Type, ListItem(T':Type) L:List)
          => #effectivelyCompat(T, T')
               orElseBool effectivelyCompatWithUnion(T, L)
     rule effectivelyCompatWithUnion(_, .List) => false

     // Returns the "biggest" type at that offset -- i.e., for a struct, union,
     // or array, it'll return the struct/union/array type and not the type of
     // its first member. Returns no-type when nothing seems to be aligned at
     // that offset.
     syntax Type ::= getTypeAtOffset(Type, Int) [function]
     rule getTypeAtOffset(T:Type, 0) => T
     // Preserve the qualifiers.
     rule getTypeAtOffset(T:Type, Offset:Int) => t(getModifiers(T), no-type)
          when (Offset =/=Int 0)
               andBool notBool isAggregateType(T)
     // Arrays.
     rule getTypeAtOffset(t(Mods:Set, arrayType(T:Type, _)), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T),
               Offset %Int byteSizeofType(T))
          when Offset =/=Int 0 // We assume the offset must be in range.
     // Structs.
     rule getTypeAtOffset(t(Mods:Set, structType(_, _, fieldInfo(
               _ ListItem(typedDeclaration(_, F1:CId))
                 ListItem(typedDeclaration(_, F2:CId)) _,
               _ F1 |-> T:Type,
               _ F1 |-> Offset1:Int F2 |-> Offset2:Int
          ))), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T), Offset -Int Offset1)
          when (Offset =/=Int 0)
               andBool (Offset1 <=Int Offset)
               andBool (Offset2 >Int Offset)
     rule getTypeAtOffset(t(Mods:Set, structType(_, _, fieldInfo(
               _ ListItem(typedDeclaration(_, F1:CId)),
               _ F1 |-> T:Type,
               _ F1 |-> Offset1:Int
          ))), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T), Offset -Int Offset1)
          when (Offset =/=Int 0)
               andBool (Offset1 <=Int Offset)

     syntax Set ::= getQualsAtOffset(Type, Int) [function]
     rule getQualsAtOffset(T:Type, Offset:Int)
          => getQualsAtOffset(getTypeAtOffset(T, Offset))

     syntax Set ::= getQualsAtOffset(Type) [function]
     rule getQualsAtOffset(T:Type) => getQualifiers(T)
          when notBool isAggregateType(T)
     rule getQualsAtOffset(T:Type)
          => getQualifiers(T) getQualsAtOffset(effInnerType(T))
          when isAggregateType(T)
     // TODO(chathhorn): absolutely no idea what to do about qualifiers on
     // union members -- do we need to get the effective type of the object?

     syntax Type ::= effInnerType(K) [function]
     rule effInnerType(T:Type) => innerType(T)
          when isArrayType(T)
     rule effInnerType(t(_, structType(_, _, fieldInfo(
               ListItem(typedDeclaration(T:Type, _)) _, _, _))))
          => T
endmodule
