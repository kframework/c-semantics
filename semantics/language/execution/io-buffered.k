module C-IO-BUFFERED-SYNTAX
     imports C-SYMLOC-SYNTAX

     syntax KItem ::= realloc(SymBase, SymBase, Int, Int)

     // deletes the base object from memory, given a location
     syntax KItem ::= deleteObject(SymBase)
     // deletes the base object from memory, given a location and it size (as a
     // check)
     syntax KItem ::= deleteSizedObject(SymBase, Int)
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
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     syntax KItem ::= bwrite(SymLoc, K)

     syntax KItem ::=  writeBytes(SymLoc, List)
     rule <k> writeBytes(Loc::SymLoc, dataList(Bytes::List), T::Type)
               => checkWrite(Loc, T)
               ~> setEffectiveType(Loc, T)
               ~> setModified(Loc, T)
               ~> writeBytes(Loc, Bytes)
          ...</k>
          <initializing> false </initializing>
     rule <k> writeBytes(Loc::SymLoc, dataList(Bytes::List), _)
               => writeBytes(Loc, Bytes)
          ...</k>
          <initializing> true </initializing>

     syntax KItem ::= setModified(SymLoc, Type)
     rule <k> setModified(Loc::SymLoc, T::Type)
               => setModified(Loc, byteSizeofType(T), .K, Modified)
          ...</k>
          <activeBlocks> Modified:Map </activeBlocks>

     syntax KItem ::= updateModified(K, SymLoc, Int) [function]
     rule updateModified(activity(N::Int, M::Map), Loc::SymLoc, I::Int)
          => activity(N, M[Loc <- #if Loc in_keys(M) #then maxInt(lookup(M, Loc):>Int, I) #else I #fi])

     syntax KItem ::= setModified(SymLoc, Int, K, Map)
     rule <k> setModified(Loc::SymLoc, Size::Int,
                (Tag::Scope => .K), _)
           ...</k>
           <activeBlocks>...
                Tag |-> (Offsets:K => updateModified(Offsets, Loc, Size))
           ...</activeBlocks>
     rule setModified(Loc::SymLoc, Size::Int, .K, K:K |-> _ M::Map)
          => setModified(Loc, Size, K, M)
     rule setModified(_, _, .K, .Map) => .K


     rule writeBytes(_, .List) => .K
          [structural]

     syntax KItem ::= checkWrite(SymLoc, Type)
     rule <k> checkWrite(loc(Base::SymBase, Offset::Int), T::Type) => .K ...</k>
          <thread-id> ThreadId::Int </thread-id>
          <mem>... Base |-> object(ObjT::Type, Len::Int, _, _) ...</mem>
          <locs-written>
               Locs::List (.List => ListItem(loc(Base, Offset)))
          </locs-written>
          <locs-read>
               Read::List
          </locs-read>
          requires // Sequencing.
               (notBool loc(Base, Offset) in Locs Read)
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
     rule <k> checkWrite(Loc::SymLoc, _) => .K ...</k>
          <locs-written>
               Locs::List (.List => ListItem(Loc))
          </locs-written>
          requires notBool Loc in Locs andBool isNativeLoc(Loc)
     rule <k> (.K => UNDEF("EIO1",
               "Unsequenced side effect on scalar object with side effect of same object.",
               "6.5") )
               ~> checkWrite(Loc::SymLoc, _)
          ...</k>
          <locs-written> Locs::List </locs-written>
          requires Loc in Locs
          [structural]
     rule <k> (.K => errorUnseqEffects)
              ~> checkWrite(Loc::SymLoc, _)
          ...</k>
          <locs-read> Locs::List </locs-read>
          requires Loc in Locs
     // TODO(chathhorn): probably redundant.
     rule <k> (.K => UNDEF("EIO2",
               "Trying to write outside the bounds of an object.",
               "6.5.6:8"))
               ~> checkWrite(loc(Base::SymBase, Offset::Int), _)
          ...</k>
          <mem>... Base |-> object(_, Len::Int, _, _) ...</mem>
          requires Offset >=Int Len orBool Offset <Int 0
          [structural]
     rule <k> (.K => UNDEF("EIO3",
               "Trying to modify an object declared with const type.",
               "6.7.3"))
               ~> checkWrite(loc(Base::SymBase, Offset::Int), _)
          ...</k>
          <mem>... Base |-> object(ObjT::Type, _, _, _) ...</mem>
          requires (Const in getQualsAtOffset(ObjT, Offset))
          [structural]
     rule <k> (.K => UNDEF("EIO4",
               "Trying to modify an object declared with volatile type through a non-volatile lvalue.",
               "6.7.3"))
               ~> checkWrite(loc(Base::SymBase, Offset::Int), T::Type)
          ...</k>
          <mem>... Base |-> object(ObjT::Type, _, _, _) ...</mem>
          requires notBool isVolatileType(T)
               andBool (Volatile in getQualsAtOffset(ObjT, Offset))
          [structural]
     rule <k> (.K => UNSPEC("EIO5",
               "Trying to modify an object with thread or auto storage duration in a thread other than the one in which the object is associated.",
               "6.2.4:4-5"))
               ~> checkWrite(Loc::SymLoc, _)
          ...</k>
          <thread-id> ThreadId::Int </thread-id>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool (ThreadId =/=K getThreadId(Loc))
          [structural]

     rule <k> writeBytes(loc(Base::SymBase, Offset::Int), ListItem(V::CValue) L::List) => writeBytes(loc(Base, Offset +Int 1), L) ...</k>
          <buffer>... (.List => ListItem(bwrite(loc(Base, Offset), V))) </buffer>
          [structural]

     rule <buffer>
               (ListItem(bwrite(loc(Base::SymBase, Offset::Int), V:K)) => .List)
          ...</buffer>
          <mem>...
               Base |-> object(_, Len::Int, (Bytes::Map => Bytes[Offset <- V]), _)
          ...</mem>
          requires Offset <Int Len
          [structural]

     syntax List ::= #writeNativeByte(SymLoc, K) [function, hook(C_SEMANTICS.writeNativeByte), impure]
     rule <buffer>
               ListItem(bwrite(Loc::SymLoc, V:K)) => #writeNativeByte(Loc, V)
          ...</buffer>
          requires isNativeLoc(Loc)

     syntax Set ::= locations(List) [function]
     rule locations(.List) => .Set
     rule locations(ListItem(bwrite(Loc::SymLoc, _)) L::List)
          => SetItem(Loc) locations(L)

     rule <k> readBytes(Loc::SymLoc, Size::Int, T::Type)
               => #if Loc in Locs #then errorUnseqEffects #else .K #fi
               ~> checkEffectiveType(T, getEffectiveType(Loc))
               ~> readBytes-aux(Loc, Size, .List, T)
          ...</k>
          <thread-id> ThreadId::Int </thread-id>
          <locs-read> _::List (.List => ListItem(Loc)) </locs-read>
          <locs-written> Locs::List </locs-written>
          requires notBool ((isThreadDuration(Loc) orBool isAutoDuration(Loc))
                    andBool (ThreadId =/=K getThreadId(Loc)))
          [structural]
     rule <k> (.K => UNSPEC("EIO6", "Attempting to access an object with thread or auto storage duration in a thread other than the one in which the object is associated.", "6.2.4:4-5"))
               ~> readBytes(Loc::SymLoc, _, _)
          ...</k>
          <thread-id> ThreadId::Int </thread-id>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool (ThreadId =/=K getThreadId(Loc))
          [structural]

     // loc, size in bytes, aux list
     syntax KItem ::= "readBytes-aux" "(" SymLoc "," Int "," List "," Type ")"
     rule readBytes-aux(_, 0, Aux::List, _) => dataList(Aux)
          [structural]

     syntax Error ::= "errorReadOutOfBounds"
                    | "errorUnseqEffects"
                    | "errorNonVolatileLVal"

     syntax KItem ::= readByte(SymLoc, Type)
     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::Type)
               // TODO(chathhorn): do we really need to check this stuff every
               // byte?
               => #if (loc(Base, Offset) in Locs) #then errorUnseqEffects #else
                    .K #fi
               ~> #if Offset <Int Len #then .K #else errorReadOutOfBounds #fi
               ~> #if (notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T) #then .K #else
                    errorNonVolatileLVal #fi
               ~> readBytes-aux(loc(Base, Offset) +bytes 1, Size -Int 1, Aux ListItem(V), T)
          ...</k>
          <mem>...
               Base |-> object(ObjT::Type, Len::Int, (_ Offset::Int |-> V:K), _)
          ...</mem>
          <locs-written> Locs::List </locs-written>
          <buffer> .List </buffer>
          requires Size >Int 0
          [structural]
     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::Type)
               => #if (loc(Base, Offset) in Locs) #then errorUnseqEffects #else
                    .K #fi
               ~> #if Offset <Int Len #then .K #else errorReadOutOfBounds #fi
               ~> #if (notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T) #then .K #else
                    errorNonVolatileLVal #fi
               ~> readBytes-aux(loc(Base, Offset) +bytes 1, Size -Int 1, Aux ListItem(V), T)
          ...</k>
          <mem>...
               Base |-> object(ObjT::Type, Len::Int, (_ Offset::Int |-> V:K), _)
          ...</mem>
          <locs-written> Locs::List </locs-written>
          <buffer> Mem::List </buffer>
          requires Size >Int 0 andBool notBool (loc(Base, Offset) in locations(Mem))
          [structural]
     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::Type)
               => #if Offset <Int Len #then .K #else errorReadOutOfBounds #fi
               ~> #if (notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T) #then .K #else 
                    errorNonVolatileLVal #fi
               ~> readBytes-aux(loc(Base, Offset) +bytes 1, Size -Int 1, Aux ListItem(piece(trap, cfg:bitsPerByte)), T)
          ...</k>
          <mem>...
               Base |-> object(ObjT::Type, Len::Int,
                    M::Map => M[Offset <- piece(trap, cfg:bitsPerByte)],
                    _)
          ...</mem>
          <buffer> Mem::List </buffer>
          requires Size >Int 0  andBool (notBool (loc(Base, Offset) in locations(Mem)))
               andBool (notBool (Offset in_keys(M)))
               andBool (notBool isStaticDuration(loc(Base, Offset)))
     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::Type)
               => #if Offset <Int Len #then .K #else errorReadOutOfBounds #fi
               ~> #if (notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T) #then .K #else 
                    errorNonVolatileLVal #fi
               ~> readBytes-aux(loc(Base, Offset) +bytes 1, Size -Int 1, Aux ListItem(piece(0, cfg:bitsPerByte)), T)
          ...</k>
          <mem>...
               Base |-> object(ObjT::Type, Len::Int,
                    M::Map => M[Offset <- piece(0, cfg:bitsPerByte)],
                    _)
          ...</mem>
          <buffer> Mem::List </buffer>
          requires Size >Int 0 andBool (notBool (loc(Base, Offset) in locations(Mem)))
               andBool (notBool (Offset in_keys(M)))
               andBool (isStaticDuration(loc(Base, Offset))
                    orBool isThreadDuration(loc(Base, Offset)))

     syntax CValue ::= #readNativeByte(SymLoc, Int, Type) [function, hook(C_SEMANTICS.readNativeByte), impure]
     rule <k> readBytes-aux(Loc::SymLoc, Size::Int, Aux::List, T::Type)
               => #if (Loc in Locs) #then errorUnseqEffects #else
                    .K #fi
               ~> readBytes-aux(Loc +bytes 1, Size -Int 1, Aux ListItem(#readNativeByte(Loc, size(Aux), T)), T)
          ...</k>
          <locs-written> Locs::List </locs-written>
          <buffer> Mem::List </buffer>
          requires Size >Int 0 andBool notBool (Loc in locations(Mem))
               andBool isNativeLoc(Loc)

          // TODO(chathhorn): perf, elided
//        rule [read-byte-buffer]:
//             <k> readByte(Loc:SymLoc)
//                  => #if notBool ListItem(Loc) in Locs:List #then .K #else errorUnseqEffects #fi
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
               Old |-> object(_, _, M:Map, _)
               New |-> object(_, _,
                    _:Map (.Map => (N' -Int 1) |-> (M [ N' -Int 1])<:K),
                    _)
          ...</mem>
          requires ((N' -Int 1) in_keys(M)) andBool (N' >Int 0)
          [structural]
     rule <k> copyBytes((N':Int => N' -Int 1), Old:SymBase, _)
          ...</k>
          <mem>... Old |-> object(_, _, M:Map, _) ...</mem>
          requires (notBool ((N' -Int 1) in_keys(M))) andBool (N' >Int 0)
          [structural]
     rule copyBytes(0, _, _) => .K
          [structural]

     syntax KItem ::= copyObjectType(SymBase, SymBase)
     rule <k> copyObjectType(Old:SymBase, New:SymBase) => .K ...</k>
          <mem>...
               Old |-> object(T:Type, _, _, _)
               New |-> object((_ => T), _, _, _)
          ...</mem>

     rule <k> deleteSizedObject(Base:SymBase, Len:Int) => .K
          ...</k>
          <mem>... Base |-> object(_, Len, _, _) => .Map ...</mem>
          // fixme could make this more relaxed by checking of block is in
          // buffer, not just empty
          <buffer> .List </buffer>
          [structural]

     rule <k> deleteObject(Base:SymBase) => .K ...</k>
          <mem>... Base |-> object(_, _, _, _) => .Map ...</mem>
          <buffer> .List </buffer>
          [structural]

     syntax KItem ::= getEffectiveType(SymLoc)
     rule <k> getEffectiveType(loc(Base::SymBase, Offset::Int))
               => getTypeAtOffset(T, Offset)
          ...</k>
          <mem>... Base |-> object(T::Type, _, _, _) ...</mem>
          requires notBool isNoType(T)
          [structural]
     rule <k> getEffectiveType(loc(Base::SymBase, Offset::Int)) => T' ...</k>
          <mem>...
               Base |-> object(t(_, no-type), _, _, Offset |-> T'::Type _)
          ...</mem>
          [structural]
     rule <k> getEffectiveType(loc(Base::SymBase, Offset::Int)) => T ...</k>
          <mem>... Base |-> object(T:NoType, _, _, EffTypes::Map) ...</mem>
          requires notBool (Offset in_keys(EffTypes))
          [structural]
     rule <k> getEffectiveType(Loc::SymLoc) => t(.Set, no-type) ...</k>
          <effective-types> EffTypes::Map </effective-types>
          requires isNativeLoc(Loc) andBool notBool (Loc in_keys(EffTypes))
     rule <k> getEffectiveType(Loc::SymLoc) => T ...</k>
          <effective-types>... Loc |-> T::Type ...</effective-types>
          requires isNativeLoc(Loc)

     syntax KItem ::= setEffectiveType(SymLoc, Type)
     rule <k> setEffectiveType(loc(Base::SymBase, Offset::Int), T'::Type) => checkEffectiveType(T', getEffectiveType(loc(Base, Offset)))
          ...</k>
          <mem>... Base |-> object(T::Type, _, _, _) ...</mem>
          requires notBool isNoType(T)
          [structural]
     rule <k> setEffectiveType(loc(Base::SymBase, Offset::Int), T'::Type) => .K
          ...</k>
          <mem>...
               Base |-> object(t(_, no-type), _, _, M:Map => M [ Offset <- T' ])
          ...</mem>
          requires notBool isCharType(T')
          [structural]
     rule <k> setEffectiveType(Loc::SymLoc, T::Type) => checkEffectiveType(T, getEffectiveType(Loc)) ...</k>
          <effective-types> M:Map => M [ Loc <- T ] </effective-types>
          requires notBool isCharType(T) andBool isNativeLoc(Loc)
     rule <k> setEffectiveType(Loc::SymLoc, T:CharType) => checkEffectiveType(T, getEffectiveType(Loc)) ...</k>
          [structural]


     syntax KItem ::= checkEffectiveType(Type, K) [strict(2)]
     rule checkEffectiveType(L::Type, Eff:Type) => .K
          requires (#effectivelyCompat(L, Eff))
               orBool isNoType(Eff)
          [structural]
     rule (.K => UNDEF("EIO10", "Type of lvalue not compatible with the effective type of the object being accessed.", "6.5:7"))
          ~> checkEffectiveType(L::Type, Eff:Type)
          requires (notBool #effectivelyCompat(L, Eff))
               andBool notBool isNoType(Eff)
          [structural]

     // An  object shall have its stored value accessed only by an lvalue
     // expression that has one of
     syntax Bool ::= #effectivelyCompat(Type, Type) [function]
     // - a type compatible with the effective type of the object,
     // - a qualified version of a type compatible with the effective type of
     // the object,
     rule #effectivelyCompat(L::Type, Eff::Type) => true
          requires areCompatible(stripQualifiers(L), stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     // - a type that is the signed or unsigned type corresponding to the
     // effective type of the object,
     // - a type that is the signed or unsigned type corresponding to a
     // qualified version of the effective type of the object,
     rule #effectivelyCompat(L:SignedIntegerType, Eff::Type) => true
          requires areCompatible(correspondingUnsignedType(stripQualifiers(L)),
                    stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     rule #effectivelyCompat(L:UnsignedIntegerType, Eff::Type) => true
          requires notBool isBoolType(L) 
               andBool areCompatible(correspondingSignedType(stripQualifiers(L)),
                    stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     // - an aggregate or union type that includes one of the aforementioned
     // types among its members (including, recursively, a member of a
     // subaggregate or contained union), or
     rule #effectivelyCompat(L::Type, Eff:AggregateType)
          => #effectivelyCompat(L, effInnerType(Eff))
          requires notBool (areCompatible(stripQualifiers(L), stripQualifiers(Eff))
                    andBool getQualifiers(Eff) <=Set getQualifiers(L))
               andBool notBool isCharType(L)
     // TODO(chathhorn): this is where things get sketchy. Very unclear
     // about the implications of strict aliasing w/r/t unions. As it is, we
     // let it pass if we're compatible with one of the union members of the
     // effective type.
     rule #effectivelyCompat(L::Type,
     // TODO(chathhorn): some obnoxious decomposing/recomposing going on here.
               t(Mods::Set, unionType(X::StructId)))
          => effectivelyCompatWithUnion(L, getFieldInfo(X))
          requires notBool (areCompatible(stripQualifiers(L),
                         stripQualifiers(t(Mods, unionType(X))))
                    andBool intersectSet(Mods, typeQualifiers)
                         <=Set getQualifiers(L))
               andBool notBool isCharType(L)
     // - a character type.
     rule #effectivelyCompat(_:CharType, _) => true
     rule #effectivelyCompat(_, _) => false [owise]

     syntax Bool ::= effectivelyCompatWithUnion(Type, K) [function]
     rule effectivelyCompatWithUnion(T::Type, fieldInfo(_, _, Types::Map, _))
          => #effectivelyCompatWithUnion(T, values(Types))
     syntax Bool ::= #effectivelyCompatWithUnion(Type, List) [function]
     rule #effectivelyCompatWithUnion(T::Type, ListItem(T'::Type) L::List)
          => #effectivelyCompat(T, T') ==K true
               orElseBool #effectivelyCompatWithUnion(T, L)
     rule #effectivelyCompatWithUnion(_, .List) => false

     syntax Set ::= getQualsAtOffset(Type, Int) [function, klabel(getQualsAtOffset2)]
     rule getQualsAtOffset(T::Type, Offset::Int)
          => getQualsAtOffset(getTypeAtOffset(T, Offset))

     syntax Set ::= getQualsAtOffset(Type) [function]
     rule getQualsAtOffset(T::Type) => getQualifiers(T)
          requires notBool isAggregateType(T)
     rule getQualsAtOffset(T:AggregateType)
          => getQualifiers(T) getQualsAtOffset(effInnerType(T))
     // TODO(chathhorn): absolutely no idea what to do about qualifiers on
     // union members -- do we need to get the effective type of the object?

     syntax Type ::= effInnerType(K) [function]
     rule effInnerType(T:ArrayType) => innerType(T)
     rule effInnerType(t(_, structType(S::StructId)))
          => effInnerType(getFieldInfo(S))
     rule effInnerType(fieldInfo(ListItem(typedDeclaration(T::Type, _)) _, _, _, _))
          => T

endmodule
