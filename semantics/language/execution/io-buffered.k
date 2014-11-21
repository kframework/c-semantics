module C-IO-BUFFERED-SYNTAX
     syntax KItem ::= realloc(SymBase, SymBase, Int, Int)

     // deletes the base object from memory, given a location
     syntax KItem ::= deleteObject(SymBase)
     // deletes the base object from memory, given a location and it size (as a
     // check)
     syntax KItem ::= deleteSizedObject(SymBase, Int)

     syntax KItem ::= writeByte(SymLoc, CValue)
endmodule

module C-IO-BUFFERED
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
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

     syntax KItem ::= bwrite(SymLoc, K)

     syntax KItem ::=  writeBytes(SymLoc, List)
     rule <k> writeBytes(Loc:SymLoc, dataList(Bytes:List), T:Type)
               => checkWrite(Loc, T)
               // TODO(chathhorn): this is pretty inefficient -- setEff does
               // nothing if the object has a declared type and checkEff is
               // only meaningful in the case of a declared type being present.
               // Also it'd be nice to combine the checks.
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
          requires I >Int 0

     syntax KItem ::= setModified(SymLoc, Type)
     syntax KItem ::= setModified(SymLoc, Type, K, Set)
     rule <k> setModified(Loc:SymLoc, T:Type)
               => setModified(Loc, T, .K, keys(Modified))
          ...</k>
          <modified> Modified:Map </modified>

     // TODO(chathhorn): java port.
     //updateMap by an indicator 0/1 to decide which kind of update we should perform
     syntax KItem ::= updateMapInKItem(K,SymLoc,Int,Int) [function]
		    | #isInMap(K,SymLoc) [function]
     rule updateMapInKItem(map(M:Map),Loc:SymLoc,I:Int,0) 
		=> map(M[Loc <- maxInt(theMapLookup(M,Loc),I)])  
     rule updateMapInKItem(map(M:Map),Loc:SymLoc,I:Int,1) 
		=> map(M[Loc <- I])  
     rule #isInMap(map(M:Map), Loc:SymLoc) => true
          requires Loc in keys(M)
     rule #isInMap(_, _) => false [owise]

     rule <k> setModified(Loc:SymLoc, T:Type,
                (Tag:RestrictTag => .K), _)
           ...</k>
           <modified>...
                Tag |-> (MK:K => updateMapInKItem(MK,Loc,byteSizeofType(T),0))
           ...</modified>
	  requires #isInMap(MK,Loc) ==K true
     rule <k> setModified(Loc:SymLoc, T:Type,
               (Tag:RestrictTag => .K), _)
           ...</k>
           <modified>...
                Tag |-> (MK:K => updateMapInKItem(MK,Loc,byteSizeofType(T),1))
           ...</modified>
	  requires #isInMap(MK,Loc) =/=K true
     rule setModified(Loc:SymLoc, T:Type, .K, SetItem(K:K) S:Set) 
		=> setModified(Loc, T, K, S)
     rule setModified(_, _, .K, .Set) => .K

     rule writeBytes(Loc:SymLoc, ListItem(V:CValue) L:List)
          => writeByte(Loc, V)
          ~> writeBytes(Loc +bytes 1, L)
          [structural]
     rule writeBytes(_, .List) => .K
          [structural]

     syntax KItem ::= checkWrite(SymLoc, Type)
     rule <k> checkWrite(loc(Base:SymBase, Offset:Int), T:Type) => .K ...</k>
          <thread-id> ThreadId:Int </thread-id>
          <mem>... Base |-> object(ObjT:Type, Len:Int, _) ...</mem>
          <locs-written>
               Locs:List (.List => ListItem(loc(Base, Offset)))
          </locs-written>
          requires // Sequencing.
               (notBool loc(Base, Offset) in Locs)
               // Bounds.
               andBool (Offset <Int Len)
               // Const.
               andBool (notBool (Const in getQualsAtOffset(ObjT, Offset)))
               // Volatile.
               andBool ((notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T))
               // Cross-thread writes.
               andBool notBool ((isThreadDuration(loc(Base, Offset))
                         orBool isAutoDuration(loc(Base, Offset)))
                    andBool (ThreadId =/=K getThreadId(loc(Base, Offset))))
          [structural]
     rule <k> (.K => UNDEF("EIO1",
               "Unsequenced side effect on scalar object with side effect of same object.",
               "6.5") )
               ~> checkWrite(Loc:SymLoc, _)
          ...</k>
          <locs-written> Locs:List </locs-written>
          requires Loc in Locs:List
          [structural]
     // TODO(chathhorn): probably redundant.
     rule <k> (.K => UNDEF("EIO2",
               "Trying to write outside the bounds of an object.",
               "6.5.6:8"))
               ~> checkWrite(loc(Base:SymBase, Offset:Int), _)
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          requires Offset >=Int Len orBool Offset <Int 0
          [structural]
     rule <k> (.K => UNDEF("EIO3",
               "Trying to modify an object declared with const type.",
               "6.7.3"))
               ~> checkWrite(loc(Base:SymBase, Offset:Int), _)
          ...</k>
          <mem>... Base |-> object(ObjT:Type, _, _) ...</mem>
          requires (Const in getQualsAtOffset(ObjT, Offset))
          [structural]
     rule <k> (.K => UNDEF("EIO4",
               "Trying to modify an object declared with volatile type through a non-volatile lvalue.",
               "6.7.3"))
               ~> checkWrite(loc(Base:SymBase, Offset:Int), T:Type)
          ...</k>
          <mem>... Base |-> object(ObjT:Type, _, _) ...</mem>
          requires notBool isVolatileType(T)
               andBool (Volatile in getQualsAtOffset(ObjT, Offset))
          [structural]
     rule <k> (.K => UNSPEC("EIO5",
               "Trying to modify an object with thread or auto storage duration in a thread other than the one in which the object is associated.",
               "6.2.4:4-5"))
               ~> checkWrite(Loc:SymLoc, _)
          ...</k>
          <thread-id> ThreadId:Int </thread-id>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool (ThreadId =/=K getThreadId(Loc))
          [structural]

     rule <k> writeByte(loc(Base:SymBase, Offset:Int), V:CValue) => .K ...</k>
          <buffer>... (.List => ListItem(bwrite(loc(Base, Offset), V))) </buffer>
          [structural]

     rule <buffer>
               (ListItem(bwrite(loc(Base:SymBase, Offset:Int), V:K)) => .List)
          ...</buffer>
          <mem>...
               Base |-> object(_, Len:Int, M:Map => M[Offset <- V])
          ...</mem>
          requires Offset <Int Len
          [structural]

     syntax Set ::= locations(List) [function]
     rule locations(.List) => .Set
     rule locations(ListItem(bwrite(Loc:SymLoc, _)) L:List)
          => SetItem(Loc) locations(L)

     rule <k> readBytes(Loc:SymLoc, Size:Int, T:Type)
               => checkEffectiveType(T, getEffectiveType(Loc))
               ~> readBytes-aux(Loc, Size, .List, T)
          ...</k>
          <thread-id> ThreadId:Int </thread-id>
          requires notBool ((isThreadDuration(Loc) orBool isAutoDuration(Loc))
                    andBool (ThreadId =/=K getThreadId(Loc)))
          [structural]
     rule <k> (.K => UNSPEC("EIO6", "Attempting to access an object with thread or auto storage duration in a thread other than the one in which the object is associated.", "6.2.4:4-5"))
               ~> readBytes(Loc:SymLoc, _, _)
          ...</k>
          <thread-id> ThreadId:Int </thread-id>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool (ThreadId =/=K getThreadId(Loc))
          [structural]

     // loc, size in bytes, aux list
     syntax KItem ::= "readBytes-aux" "(" SymLoc "," Int "," List "," Type ")"
     rule readBytes-aux(Loc:SymLoc, Size:Int, Aux:List, T:Type)
          => readByte(Loc, T)
          ~> readBytes-aux(Loc +bytes 1, Size -Int 1, Aux, T)
          requires Size >Int 0
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

     syntax KItem ::= readByte(SymLoc, Type)
     rule <k> readByte(loc(Base:SymBase, Offset:Int), T:Type)
               // TODO(chathhorn): do we really need to check this stuff every
               // byte?
               => assert(notBool (loc(Base, Offset) in Locs),
                    errorUnseqEffects)
               ~> assert(Offset <Int Len, errorReadOutOfBounds)
               ~> assert((notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T),
                    errorNonVolatileLVal)
               ~> tv(V, t(.Set, no-type))
          ...</k>
          <mem>...
               Base |-> object(ObjT:Type, Len:Int, (_ Offset:Int |-> V:K))
          ...</mem>
          <locs-written> Locs:List </locs-written>
          <buffer> .List </buffer>
          [structural]
     rule <k> readByte(loc(Base:SymBase, Offset:Int), T:Type)
               => assert(notBool (loc(Base, Offset) in Locs),
                    errorUnseqEffects)
               ~> assert(Offset <Int Len, errorReadOutOfBounds)
               ~> assert((notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T),
                    errorNonVolatileLVal)
               ~> tv(V, t(.Set, no-type))
          ...</k>
          <mem>...
               Base |-> object(ObjT:Type, Len:Int, (_ Offset:Int |-> V:K))
          ...</mem>
          <locs-written> Locs:List </locs-written>
          <buffer> Mem:List </buffer>
          requires notBool (loc(Base, Offset) in locations(Mem))
          [structural]
     rule <k> readByte(loc(Base:SymBase, Offset:Int), T:Type)
               => assert(Offset:Int <Int Len:Int, errorReadOutOfBounds)
               ~> assert((notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T),
                    errorNonVolatileLVal)
               ~> tv(piece(trap, cfg:bitsPerByte), t(.Set, no-type))
          ...</k>
          <mem>...
               Base |-> object(ObjT:Type, Len:Int,
               M:Map => M[
                     Offset <- piece(trap, cfg:bitsPerByte)])
          ...</mem>
          <buffer> Mem:List </buffer>
          requires (notBool (loc(Base, Offset) in locations(Mem)))
               andBool (notBool (Offset in (keys(M))))
               andBool (notBool isStaticDuration(loc(Base, Offset)))
          [structural]
     rule <k> readByte(loc(Base:SymBase, Offset:Int), T:Type)
               => assert(Offset:Int <Int Len:Int, errorReadOutOfBounds)
               ~> assert((notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T),
                    errorNonVolatileLVal)
               ~> tv(piece(0, cfg:bitsPerByte), t(.Set, no-type))
          ...</k>
          <mem>...
               Base |-> object(ObjT:Type, Len:Int,
               M:Map => M[Offset <- piece(0, cfg:bitsPerByte)])
          ...</mem>
          <buffer> Mem:List </buffer>
          requires (notBool (loc(Base, Offset) in locations(Mem)))
               andBool (notBool (Offset in (keys(M))))
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
//                  => assert(notBool ListItem(Loc) in Locs:List, errorUnseqEffects)
//                  ~> tv(V:K, t(.Set, no-type))
//             ...</k>
//             <locs-written> Locs:List </locs-written>
//             <buffer>... ListItem(bwrite(Loc, V:K)) Mem:List </buffer>
//             requires notBool (Loc in locations(Mem:List))
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

     syntax KItem ::= copyBytes(Int, SymBase, SymBase)
     rule <k> copyBytes((N':Int => N' -Int 1), Old:SymBase, New:SymBase)
          ...</k>
          <mem>...
               Old |-> object(_, _, M:Map)
               New |-> object(_, _, _:Map (.Map => (N' -Int 1) |-> (M [ N' -Int 1])<:K))
          ...</mem>
          requires ((N' -Int 1) in keys(M)) andBool (N' >Int 0)
          [structural]
     rule <k> copyBytes((N':Int => N' -Int 1), Old:SymBase, _)
          ...</k>
          <mem>... Old |-> object(_, _, M:Map) ...</mem>
          requires (notBool ((N' -Int 1) in keys(M))) andBool (N' >Int 0)
          [structural]
     rule copyBytes(0, _, _) => .K
          [structural]

     syntax KItem ::= copyObjectType(SymBase, SymBase)
     rule <k> copyObjectType(Old:SymBase, New:SymBase) => .K ...</k>
          <mem>...
               Old |-> object(T:Type, _, _)
               New |-> object((_ => T), _, _)
          ...</mem>

     rule <k> deleteSizedObject(Base:SymBase, Len:Int) => .K
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

     syntax KItem ::= getEffectiveType(SymLoc)
     rule <k> getEffectiveType(loc(Base:SymBase, Offset:Int))
               => getTypeAtOffset(T, Offset)
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          requires notBool isNoType(T)
          [structural]
     rule <k> getEffectiveType(loc(Base:SymBase, Offset:Int)) => T' ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          <effective-types>...
               loc(Base, Offset) |-> T':Type
          ...</effective-types>
          requires isNoType(T)
          [structural]
     rule <k> getEffectiveType(loc(Base:SymBase, Offset:Int)) => T ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          <effective-types> EffTypes:Map </effective-types>
          requires isNoType(T)
               andBool notBool (loc(Base, Offset) in keys(EffTypes))
          [structural]

     syntax KItem ::= setEffectiveType(SymLoc, Type)
     rule <k> setEffectiveType(loc(Base:SymBase, _), T':Type) => .K
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          requires notBool isNoType(T) orBool hasCharType(T':Type)
          [structural]
     rule <k> setEffectiveType(loc(Base:SymBase, Offset:Int), T':Type) => .K
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          <effective-types> M:Map => M [ loc(Base, Offset) <- T' ] </effective-types>
          requires isNoType(T) andBool notBool hasCharType(T':Type)
          [structural]

     syntax KItem ::= checkEffectiveType(Type, K) [strict(2)]
     rule checkEffectiveType(L:Type, Eff:Type) => .K
          requires (#effectivelyCompat(L, Eff))
               orBool isNoType(Eff)
          [structural]
     rule (.K => UNDEF("EIO10", "Type of lvalue not compatible with the effective type of the object being accessed.", "6.5:7"))
          ~> checkEffectiveType(L:Type, Eff:Type)
          requires (notBool #effectivelyCompat(L, Eff))
               andBool notBool isNoType(Eff)
          [structural]

     // An  object shall have its stored value accessed only by an lvalue
     // expression that has one of
     syntax Bool ::= #effectivelyCompat(Type, Type) [function]
     // - a type compatible with the effective type of the object,
     // - a qualified version of a type compatible with the effective type of
     // the object,
     rule #effectivelyCompat(L:Type, Eff:Type) => true
          requires areCompatible(stripQualifiers(L), stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     // - a type that is the signed or unsigned type corresponding to the
     // effective type of the object,
     // - a type that is the signed or unsigned type corresponding to a
     // qualified version of the effective type of the object,
     rule #effectivelyCompat(L:Type, Eff:Type) => true
          requires areCompatible(correspondingUnsignedType(stripQualifiers(L)),
                    stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     rule #effectivelyCompat(L:Type, Eff:Type) => true
          requires areCompatible(correspondingSignedType(stripQualifiers(L)),
                    stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     // - an aggregate or union type that includes one of the aforementioned
     // types among its members (including, recursively, a member of a
     // subaggregate or contained union), or
     rule #effectivelyCompat(L:Type, Eff:Type)
          => #effectivelyCompat(L, effInnerType(Eff))
          requires isAggregateType(Eff)
               andBool notBool (areCompatible(stripQualifiers(L), stripQualifiers(Eff))
                    andBool getQualifiers(Eff) <=Set getQualifiers(L))
               andBool notBool hasCharType(L:Type)
     // TODO(chathhorn): this is where things get sketchy. Very unclear
     // about the implications of strict aliasing w/r/t unions. As it is, we
     // let it pass if we're compatible with one of the union members of the
     // effective type.
     rule #effectivelyCompat(L:Type,
     // TODO(chathhorn): some obnoxious decomposing/recomposing going on here.
               t(Mods:Set, unionType(X:CId, Sz:Int, fieldInfo(Decls:List, Types:Map, Offs:Map))))
          => effectivelyCompatWithUnion(L, values(Types))
          requires notBool (areCompatible(stripQualifiers(L),
                         stripQualifiers(t(Mods, unionType(X, Sz, fieldInfo(Decls, Types, Offs)))))
                    andBool intersectSet(Mods, typeQualifiers)
                         <=Set getQualifiers(L))
               andBool notBool hasCharType(L:Type)
     // - a character type.
     rule #effectivelyCompat(L:Type, _) => true
          requires hasCharType(L:Type)
     rule #effectivelyCompat(_, _) => false [owise]

     syntax Bool ::= effectivelyCompatWithUnion(Type, List) [function]
     rule effectivelyCompatWithUnion(T:Type, ListItem(T':Type) L:List)
          => #effectivelyCompat(T, T') ==K true
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
          requires (Offset =/=Int 0)
               andBool notBool isAggregateType(T)
     // Arrays.
     rule getTypeAtOffset(t(Mods:Set, arrayType(T:Type, _)), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T),
               Offset %Int byteSizeofType(T))
          requires Offset =/=Int 0 // We assume the offset must be in range.
     // Structs.
     rule getTypeAtOffset(t(Mods:Set, structType(SCId:CId, SI:Int, fieldInfo(
               F1List:List (ListItem(typedDeclaration(_, F1:CId))),
               F2Map:Map (F1 |-> T:Type),
               F3Map:Map (F1 |-> Offset1:Int)
          ))), Offset:Int)
          => getTypeAtOffset(t(Mods, structType(SCId, SI, fieldInfo(
               F1List,
               F2Map (F1 |-> T),
               F3Map (F1 |-> Offset1)
          ))), Offset)
          requires (Offset =/=Int 0)
               andBool (Offset1 >Int Offset)
     rule getTypeAtOffset(t(Mods:Set, structType(_, _, fieldInfo(
               _ ListItem(typedDeclaration(_, F1:CId)),
               _ F1 |-> T:Type,
               _ F1 |-> Offset1:Int
          ))), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T), Offset -Int Offset1)
          requires (Offset =/=Int 0)
               andBool (Offset1 <=Int Offset)
     //TODO(liyili2): why it is nessary here
     syntax Set ::= getQualsAtOffset(Type, Int) [function]
     rule getQualsAtOffset(T:Type, Offset:Int)
          => getQualsAtOffset(getTypeAtOffset(T, Offset))

     syntax Set ::= getQualsAtOffset(Type) [function]
     rule getQualsAtOffset(T:Type) => getQualifiers(T)
          requires notBool isAggregateType(T)
     rule getQualsAtOffset(T:Type)
          => getQualifiers(T) getQualsAtOffset(effInnerType(T))
          requires isAggregateType(T)
     // TODO(chathhorn): absolutely no idea what to do about qualifiers on
     // union members -- do we need to get the effective type of the object?

     syntax Type ::= effInnerType(K) [function]
     rule effInnerType(T:Type) => innerType(T)
          requires isArrayType(T)
     rule effInnerType(t(_, structType(_, _, fieldInfo(
               ListItem(typedDeclaration(T:Type, _)) _, _, _))))
          => T
endmodule
