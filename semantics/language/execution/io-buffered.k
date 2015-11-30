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
               => checkWrite(Loc, T, size(Bytes))
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

     syntax KItem ::= checkWrite(SymLoc, Type, Int)
     rule <k> checkWrite(loc(Base::SymBase, Offset::Int), T::Type, Size::Int) => .K ...</k>
          <thread-id> ThreadId::Int </thread-id>
          <mem>... Base |-> object(ObjT::Type, Len::Int, _, _) ...</mem>
          <locs-written>
               Locs::List (.List => ListItem(loc(Base, Offset)))
          </locs-written>
          requires // Sequencing.
               (notBool loc(Base, Offset) in Locs)
               // Bounds.
               andBool (Offset +Int Size -Int 1 <Int Len)
               andBool Offset >=Int 0
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
     rule <k> checkWrite(Loc::SymLoc, _, _) => .K ...</k>
          <locs-written>
               Locs::List (.List => ListItem(Loc))
          </locs-written>
          requires notBool Loc in Locs andBool isNativeLoc(Loc)
     rule <k> (.K => UNDEF("EIO8",
               "Unsequenced side effect on scalar object with side effect of same object.",
               "6.5:2, J.2:1 item 35") )
               ~> checkWrite(Loc::SymLoc, _, _)
          ...</k>
          <locs-written> Locs::List </locs-written>
          requires Loc in Locs::List
          [structural]
     // TODO(chathhorn): probably redundant.
     rule <k> (.K => UNDEF("EIO2",
               "Trying to write outside the bounds of an object.",
               "6.5.6:8, J.2:1 item 47"))
               ~> checkWrite(loc(Base::SymBase, Offset::Int), _, Size::Int)
          ...</k>
          <mem>... Base |-> object(_, Len::Int, _, _) ...</mem>
          requires Offset +Int Size -Int 1 >=Int Len orBool Offset <Int 0
          [structural]
     // if there is an undefined behavior associated with the write, we just eat it
     // this is somewhat less safe than some of our other error recovery options,
     // but all error recovery is essentially unsound anyway, so it should be fine
     rule <k> (.K => UNDEF("EIO3",
               "Trying to modify an object declared with const type.",
               "6.7.3:6, J.2:1 item 64"))
               ~> checkWrite(loc(Base::SymBase, Offset::Int), _, _)
          ...</k>
          <mem>... Base |-> object(ObjT::Type, _, _, _) ...</mem>
          requires (Const in getQualsAtOffset(ObjT, Offset))
          [structural]
     rule <k> (.K => UNDEF("EIO4",
               "Trying to modify an object declared with volatile type through a non-volatile lvalue.",
               "6.7.3:6, J.2:1 item 65"))
               ~> checkWrite(loc(Base::SymBase, Offset::Int), T::Type, _)
          ...</k>
          <mem>... Base |-> object(ObjT::Type, _, _, _) ...</mem>
          requires notBool isVolatileType(T)
               andBool (Volatile in getQualsAtOffset(ObjT, Offset))
          [structural]
     rule <k> (.K => IMPL("EIO5",
               "Trying to modify an object with thread or auto storage duration in a thread other than the one in which the object is associated.",
               "6.2.4:4, 6.2.4:5, J.3.13:1 item 2"))
               ~> checkWrite(Loc::SymLoc, _, _)
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

     syntax List ::= #writeNativeByte(SymLoc, K) [function, hook(C_SEMANTICS.writeNativeByte), impure, canTakeSteps]
     rule <buffer>
               ListItem(bwrite(Loc::SymLoc, V:K)) => #writeNativeByte(Loc, V)
          ...</buffer>
          requires isNativeLoc(Loc)

     syntax Set ::= locations(List) [function]
     rule locations(.List) => .Set
     rule locations(ListItem(bwrite(Loc::SymLoc, _)) L::List)
          => SetItem(Loc) locations(L)

     rule <k> readBytes(Loc::SymLoc, Size::Int, T::Type)
               => checkEffectiveType(T, getEffectiveType(Loc))
               ~> readBytes-aux(Loc, Size, .List, T)
          ...</k>
          <thread-id> ThreadId::Int </thread-id>
          requires notBool ((isThreadDuration(Loc) orBool isAutoDuration(Loc))
                    andBool (ThreadId =/=K getThreadId(Loc)))
          [structural]
     rule <k> (.K => IMPL("EIO6", "Attempting to access an object with thread or auto storage duration in a thread other than the one in which the object is associated.", "6.2.4:4, 6.2.4:5, J.3.13:1 item 2"))
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

     syntax K ::= assertInBounds(Int, Int)
     syntax K ::= assertSeq(SymLoc, List)
     syntax K ::= assertVolatile(Type, Int, Type)

     rule assertInBounds(Offset::Int, Len::Int)
          => assert(Offset <Int Len, errorReadOutOfBounds) [macro]
     rule assertSeq(Loc::SymLoc, Locs::List)
          => assert(notBool (Loc in Locs), errorUnseqEffects) [macro]
     rule assertVolatile(ObjT::Type, Offset::Int, T::Type)
          => assert((notBool (Volatile in getQualsAtOffset(ObjT, Offset)))
               orBool isVolatileType(T), errorNonVolatileLVal) [macro]

     syntax KItem ::= readByte(SymLoc, Type)
     //TODO(dwightguth): make these rules look a little better once we have partial compilation
     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::Type)
               // TODO(chathhorn): do we really need to check this stuff every
               // byte?
               => assertSeq(loc(Base, Offset), Locs)
               ~> assertInBounds(Offset, Len)
               ~> assertVolatile(ObjT, Offset, T)
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
               => assertSeq(loc(Base, Offset), Locs)
               ~> assertInBounds(Offset, Len)
               ~> assertVolatile(ObjT, Offset, T)
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
               => assertInBounds(Offset, Len)
               ~> assertVolatile(ObjT, Offset, T)
               ~> readBytes-aux(loc(Base, Offset) +bytes 1, Size -Int 1, Aux ListItem(getUninitializedBits(loc(Base, Offset), ObjT)), T)
          ...</k>
          <mem>...
               Base |-> object(ObjT::Type, Len::Int,
                    M::Map => M[Offset <- getUninitializedBits(loc(Base, Offset), ObjT)],
                    _)
          ...</mem>
          <buffer> Mem::List </buffer>
          requires Size >Int 0 andBool (notBool (loc(Base, Offset) in locations(Mem)))
               andBool (notBool (Offset in_keys(M)))

     syntax Bits ::= getUninitializedBits(SymLoc, Type) [function]
     rule getUninitializedBits(L::SymLoc, _) => piece(trap, cfg:bitsPerByte)
          requires notBool (isStaticDuration(L) orBool isThreadDuration(L))
     rule getUninitializedBits(loc(_, Offset::Int), T::Type) => getZeroedBits(Offset *Int cfg:bitsPerByte, cfg:bitsPerByte, T) [owise]
     syntax Bits ::= getZeroedBits(Int, Int, Type) [function]
     rule getZeroedBits(_, N::Int, T::Type) => piece(0, N)
          requires isPointerType(T) orBool isArithmeticType(T) orBool N ==Int 0
     rule getZeroedBits(Offset::Int, N::Int, t(_, arrayType(T::Type, _))) =>getZeroedBits(Offset %Int bitSizeofType(T), N, T)
          requires N =/=Int 0
     rule getZeroedBits(Offset::Int, N::Int, T:StructOrUnionType) => getZeroedBits(Offset, N, T, getFieldInfo(T))
          requires N =/=Int 0
     syntax Bits ::= getZeroedBits(Int, Int, Type, FieldInfo) [function, klabel(getZeroedBits2)]
     rule getZeroedBits(Offset::Int, N::Int, _:UnionType, fieldInfo(ListItem(typedDeclaration(T::Type, _)) _, _, _, _)) => getZeroedBits(Offset, N, T)
     rule getZeroedBits(Offset::Int, N::Int, _:StructType, fieldInfo(
            ((ListItem(typedDeclaration(_, FId::CId))) => .List) _,
            _,
            _::Map (FId |-> T::Type),
            _::Map (FId |-> FOffset::Int)))
          requires FOffset +Int bitSizeofType(T) <=Int Offset orBool Offset +Int N <=Int FOffset
     rule getZeroedBits(_, 0, _, _) => piece(0, 0)
     // this happens when we are reading padding bits, which are zeroed.
     // bit fields never contain padding in between two bit fields in the same byte,
     // so doing this at the end should be safe
     rule getZeroedBits(_, N::Int, _, fieldInfo(.List, _, _, _)) => piece(0, N)

     rule getZeroedBits(Offset::Int, N::Int, BaseT::StructType, fieldInfo(
            (ListItem(typedDeclaration(_, FId::CId))) Fields::List,
            SI::Int,
            Types::Map (FId |-> T::Type),
            Offsets::Map (FId |-> FOffset::Int)))
          => #if FId ==K #NoName #then
               //the bits of the field in the current byte are traps, because it was unnamed
               piece(trap, minInt(FOffset +Int bitSizeofType(T),
                                  Offset +Int N) -Int
                           maxInt(FOffset, Offset))
             #else
               // read the bits of the field that overlap the current byte
               getZeroedBits(maxInt(FOffset, Offset) -Int FOffset,
                             (minInt(FOffset +Int bitSizeofType(T),
                                     Offset +Int N) -Int
                              maxInt(FOffset, Offset)), T)
             #fi:>Bits
               bit::
                 //read the remaining bits in the byte
                 getZeroedBits(minInt(FOffset +Int bitSizeofType(T),
                                      Offset +Int N), N -Int
                   (minInt(FOffset +Int bitSizeofType(T),
                           Offset +Int N) -Int
                    maxInt(FOffset, Offset)), BaseT, fieldInfo(
                   Fields,
                   SI,
                   Types (FId |-> T),
                   Offsets (FId |-> FOffset)))
     [owise]

     syntax CValue ::= #readNativeByte(SymLoc, Int, Type) [function, hook(C_SEMANTICS.readNativeByte), impure, canTakeSteps]
     rule <k> readBytes-aux(Loc::SymLoc, Size::Int, Aux::List, T::Type)
               => assertSeq(Loc, Locs)
               ~> readBytes-aux(Loc +bytes 1, Size -Int 1, Aux ListItem(#readNativeByte(Loc, size(Aux), T)), T)
          ...</k>
          <locs-written> Locs::List </locs-written>
          <buffer> Mem::List </buffer>
          requires Size >Int 0 andBool notBool (Loc in locations(Mem))
               andBool isNativeLoc(Loc)

          // TODO(chathhorn): perf, elided
//        rule [read-byte-buffer]:
//             <k> readByte(Loc:SymLoc)
//                  => assertSeq(Loc, Locs)
//                  ~> tv(V:K, t(.Set, no-type))
//             ...</k>
//             <locs-written> Locs:List </locs-written>
//             <buffer>... ListItem(bwrite(Loc, V:K)) Mem:List </buffer>
//             requires notBool (Loc in locations(Mem:List))
//             [structural]
//             // for speed in interpretation; forces local buffer to be flushed
//             // before a read
//             //[interpRule]

     rule (.K => UNDEF("EIO7",
               "Reading outside the bounds of an object.",
               "6.3.2.1:1, J.2:1 item 19"))
          ~> errorReadOutOfBounds
          [structural]
     // read outo f bounds becomes a trap by the above rule
     rule (.K => UNDEF("EIO8",
               "Unsequenced side effect on scalar object with value computation of same object.",
               "6.5:2, J.2:1 item 35"))
          ~> errorUnseqEffects
          [structural]
     rule (.K => UNDEF("EIO9",
               "Trying to access an object declared with volatile type through a non-volatile lvalue.",
               "6.7.3:6, J.2:1 item 65"))
          ~> errorNonVolatileLVal
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
               => getTypeAtOffset(T, Offset *Int cfg:bitsPerByte)
          ...</k>
          <mem>... Base |-> object(T::Type, _, _, _) ...</mem>
          requires notBool isNoType(getTypeAtOffset(T, Offset *Int cfg:bitsPerByte))
          [structural]
     rule <k> getEffectiveType(loc(Base::SymBase, Offset::Int)) => T' ...</k>
          <mem>...
               Base |-> object(T::Type, _, _, Offset |-> T'::Type _)
          ...</mem>
          requires isNoType(getTypeAtOffset(T, Offset *Int cfg:bitsPerByte))
          [structural]
     rule <k> getEffectiveType(loc(Base::SymBase, Offset::Int)) => t(getModifiers(T), no-type) ...</k>
          <mem>... Base |-> object(T::Type, _, _, EffTypes::Map) ...</mem>
          requires notBool (Offset in_keys(EffTypes)) andBool isNoType(getTypeAtOffset(T, Offset *Int cfg:bitsPerByte))
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
          requires notBool isNoType(getTypeAtOffset(T, Offset *Int cfg:bitsPerByte))
          [structural]
     rule <k> setEffectiveType(loc(Base::SymBase, Offset::Int), T'::Type) => .K
          ...</k>
          <mem>...
               Base |-> object(T::Type, _, _, M:Map => M [ Offset <- T' ])
          ...</mem>
          requires notBool isCharType(T') andBool isNoType(getTypeAtOffset(T, Offset *Int cfg:bitsPerByte))
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
     rule (.K => UNDEF("EIO10", "Type of lvalue not compatible with the effective type of the object being accessed.", "6.5:7, J.2:1 item 37"))
          ~> checkEffectiveType(L::Type, Eff:Type)
          requires (notBool #effectivelyCompat(L, Eff))
               andBool notBool isNoType(Eff)
          [structural]

     // An  object shall have its stored value accessed only by an lvalue
     // expression that has one of the following types:
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
     rule #effectivelyCompat(L:ArrayType, Eff::Type)
          => #effectivelyCompat(innerType(L), Eff)
          requires notBool (areCompatible(stripQualifiers(L), stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L))
     rule #effectivelyCompat(L:StructOrUnionType, Eff::Type)
          => effectivelyCompatWithField(getFieldInfo(L), Eff)
          requires notBool (areCompatible(stripQualifiers(L), stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L))

     // TODO(chathhorn): should track the active variant of unions.
     rule #effectivelyCompat(L::Type, Eff:UnionType)
          => effectivelyCompatWithField(L, getFieldInfo(Eff))
          requires notBool (areCompatible(stripQualifiers(L), stripQualifiers(Eff))
                    andBool getQualifiers(Eff) <=Set getQualifiers(L))
               andBool notBool isAggregateOrUnionType(L)
               andBool notBool isCharType(L)
     // - a character type.
     rule #effectivelyCompat(_:CharType, _) => true

     // Included because we can't distinguish the offset of an aggregate or
     // union from the offset of its first member.
     rule #effectivelyCompat(L::Type, Eff:AggregateType)
          => #effectivelyCompat(L, effInnerType(Eff))
          requires notBool (areCompatible(stripQualifiers(L), stripQualifiers(Eff))
                    andBool getQualifiers(Eff) <=Set getQualifiers(L))
               andBool notBool isAggregateOrUnionType(L)
               andBool notBool isCharType(L)

     rule #effectivelyCompat(_, _) => false [owise]

     syntax Bool ::= effectivelyCompatWithField(Type, FieldInfo) [function]
     rule effectivelyCompatWithField(T::Type, fieldInfo(_, _, Types::Map, _))
          => #effectivelyCompatWithField(T, values(Types))
     syntax Bool ::= #effectivelyCompatWithField(Type, List) [function]
     rule #effectivelyCompatWithField(T::Type, ListItem(T'::Type) L::List)
          => #effectivelyCompat(T, T') ==K true
               orElseBool #effectivelyCompatWithField(T, L)
     rule #effectivelyCompatWithField(_, .List) => false

     syntax Bool ::= effectivelyCompatWithField(FieldInfo, Type) [function]
     rule effectivelyCompatWithField(fieldInfo(_, _, Types::Map, _), T::Type)
          => #effectivelyCompatWithField(values(Types), T)
     syntax Bool ::= #effectivelyCompatWithField(List, Type) [function]
     rule #effectivelyCompatWithField(ListItem(T::Type) L::List, T'::Type)
          => #effectivelyCompat(T, T') ==K true
               orElseBool #effectivelyCompatWithField(L, T')
     rule #effectivelyCompatWithField(.List, _) => false

     syntax Set ::= getQualsAtOffset(Type, Int) [function, klabel(getQualsAtOffset2)]
     rule getQualsAtOffset(T::Type, Offset::Int)
          => getQualsAtOffset(getTypeAtOffset(T, Offset *Int cfg:bitsPerByte))

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
