module C-IO-BUFFERED-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports MAP
     imports SYMLOC-SORTS

     syntax KItem ::= realloc(SymBase, SymBase, Int, Int)

     // deletes the base object from memory, given a location
     syntax KItem ::= deleteObject(SymBase)
     syntax KItem ::= deleteObjects(Set)

     syntax Set ::= locations(List) [function]

     syntax Quals ::= getQualsAtOffset(List) [function]

     syntax KItem ::= writeBytesBuffered(SymLoc, List)

endmodule

module C-IO-BUFFERED
     imports C-IO-BUFFERED-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports BITS-SYNTAX
     imports SETTINGS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-CHECK-LOC-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-BUILTIN-SYNTAX

     rule writeBytes(Loc::SymLoc, Bytes::List, T::Type)
          => checkRestrict(true, Loc)
          ~> checkWrite(stripProv(Loc), T)
          ~> checkSeq(stripProv(Loc))
          ~> checkBounds(stripProv(Loc), size(Bytes))
          ~> writeBytesBuffered(stripProv(Loc), Bytes)

     rule initBytes(Loc::SymLoc, Bytes::List)
          => writeBytesBuffered(stripProv(Loc), Bytes)

     syntax KItem ::= checkSeq(SymLoc)
     rule <k> checkSeq(Loc::SymLoc) => .K ...</k>
          <locs-written>
               Locs::Set (.Set => SetItem(Loc))
          </locs-written>
          requires notBool Loc in Locs
          [structural]
     rule <k> (.K => UNDEF("EIO8",
               "Unsequenced side effect on scalar object with side effect of same object.") )
               ~> checkSeq(Loc::SymLoc)
          ...</k>
          <locs-written> Locs::Set </locs-written>
          requires Loc in Locs
          [structural]

     syntax KItem ::= checkWrite(SymLoc, Type)
     rule <k> checkWrite(loc(Base::SymBase, Offset::Int), T::Type) => .K ...</k>
          <thread-id> ThreadId::Int </thread-id>
          <mem>... Base |-> object(ObjT::EffectiveType, Len::Int, _) ...</mem>
          requires // Const.
               (notBool (Const() inQuals getQualsAtOffset(ObjT, Offset)))
               // Volatile.
               andBool ((notBool (Volatile() inQuals getQualsAtOffset(ObjT, Offset)))
                    orBool isVolatileType(T))
               // Cross-thread writes.
               andBool notBool ((isThreadDuration(loc(Base, Offset))
                         orBool isAutoDuration(loc(Base, Offset)))
                    andBool (ThreadId =/=K getThreadId(loc(Base, Offset))))
               // Libc fixed.
               andBool (notBool isLibcFixedDuration(Base))
          [structural]
     rule checkWrite(Loc::SymLoc, _) => .K
          requires isNativeLoc(Loc)
     rule <k> (.K => UNDEF("EIO3",
               "Trying to modify an object declared with const type."))
               ~> checkWrite(loc(Base::SymBase, Offset::Int), _)
          ...</k>
          <mem>... Base |-> object(ObjT::EffectiveType, _, _) ...</mem>
          requires Const() inQuals getQualsAtOffset(ObjT, Offset)
          [structural]
     rule <k> (.K => UNDEF("EIO4",
               "Trying to modify an object declared with volatile type through a non-volatile lvalue."))
               ~> checkWrite(loc(Base::SymBase, Offset::Int), T::Type)
          ...</k>
          <mem>... Base |-> object(ObjT::EffectiveType, _, _) ...</mem>
          requires notBool isVolatileType(T)
               andBool (Volatile() inQuals getQualsAtOffset(ObjT, Offset))
          [structural]
     rule <k> (.K => IMPL("EIO5",
               "Trying to modify an object with thread or auto storage duration in a thread other than the one in which the object is associated."))
               ~> checkWrite(Loc::SymLoc, _)
          ...</k>
          <thread-id> ThreadId::Int </thread-id>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool (ThreadId =/=K getThreadId(Loc))
          [structural]
     rule (.K => UNDEF("EIO11",
               "Trying to modify an unmodifiable object returned by a library function."))
          ~> checkWrite(loc(Base::SymBase, _), _)
          requires isLibcFixedDuration(Base)
          [structural]

     // TODO(chathhorn): probably redundant.
     syntax KItem ::= checkBounds(SymLoc, Int)
     rule <k> checkBounds(loc(Base::SymBase, Offset::Int), Size::Int) => .K ...</k>
          <mem>... Base |-> object(_, Len::Int, _) ...</mem>
          requires // Bounds.
               (Offset +Int Size -Int 1 <Int Len)
               andBool Offset >=Int 0
     rule <k> checkBounds(Loc::SymLoc, _) => .K ...</k>
          requires isNativeLoc(Loc)
     rule <k> (.K => UNDEF("EIO2",
               "Trying to write outside the bounds of an object."))
               ~> checkBounds(loc(Base::SymBase, Offset::Int), Size::Int)
          ...</k>
          <mem>... Base |-> object(_, Len::Int, _) ...</mem>
          requires Offset +Int Size -Int 1 >=Int Len orBool Offset <Int 0
          [structural]

     syntax KItem ::= bwrite(SymLoc, List)
     rule <k> writeBytesBuffered(loc(Base::SymBase, Offset::Int), L::List) => .K ...</k>
          <buffer>... .List => ListItem(bwrite(loc(Base, Offset), L)) </buffer>
          [structural]

     //TODO(dwightguth): when we do symbolic execution we need to rework this stuff to obey the C11 memory model
     rule <buffer>
               ListItem(bwrite(loc(Base::SymBase, Offset::Int), L::List)) => .List
          ...</buffer>
          <mem> M::Map => writeBuffer(M, Base, M[Base], Offset, L) </mem>
          requires notBool isNativeLoc(loc(Base, Offset))
          [structural]

     syntax Map ::= writeBuffer(Map, SymBase, K, Int, List) [function]
     rule writeBuffer(M::Map, Base::SymBase, object(T::EffectiveType, Len::Int, Bytes::Array), Offset::Int, Buffer::List)
          => M[Base <- object(T, Len, updateArray(Bytes, Offset, Buffer))]

     syntax List ::= #writeNativeByte(SymLoc, K) [function, hook(C_SEMANTICS.writeNativeByte), impure]
     rule <buffer>
               ListItem(bwrite((Loc::SymLoc => Loc +bytes 1), ((ListItem(V:K) => #writeNativeByte(Loc, V)) _::List)))
          ...</buffer>
          requires isNativeLoc(Loc)
     rule <buffer>
               ListItem(bwrite(Loc::SymLoc, .List)) => .List
          ...</buffer>
          requires isNativeLoc(Loc)

     rule locations(.List) => .Set
     rule locations(ListItem(bwrite(Loc::SymLoc, Bytes::List)) L::List)
          => #locations(Loc, size(Bytes)) locations(L)
     syntax Set ::= #locations(SymLoc, Int) [function]
     rule #locations(Loc::SymLoc, I:Int) => SetItem(Loc) #locations(Loc +bytes 1, I -Int 1)
          requires I >Int 0
     rule #locations(Loc::SymLoc, 0) => .Set

     rule readBytes(loc(Base::SymBase, Offset::Int) => loc(Base, Offset, .Set), _, _)
          [structural]
     rule <k> readBytes(loc(Base::SymBase, _, _) #as Loc::SymLoc, Size::Int, T::Type)
               => checkRestrict(false, Loc)
               ~> readBytes-aux(stripProv(Loc) +bytes (Size -Int 1), Size, .List, T, ObjT, Len, M, Locs, Mem, false, false, false, false)
          ...</k>
          <thread-id> ThreadId::Int </thread-id>
          <mem>...
               Base |-> object(ObjT::EffectiveType, Len::Int, M::Array)
          ...</mem>
          <locs-written> Locs::Set </locs-written>
          <buffer> Mem::List </buffer>
          requires notBool ((isThreadDuration(Loc) orBool isAutoDuration(Loc))
                    andBool (ThreadId =/=K getThreadId(Loc)))
          [structural]
     rule <k> readBytes(loc(_, _, _) #as Loc::SymLoc, Size::Int, T::Type)
               => checkRestrict(false, Loc)
               ~> readBytes-aux(stripProv(Loc) +bytes (Size -Int 1), Size, .List, T, .K, .K, .K, Locs, Mem, false, false, false, false)
          ...</k>
          <thread-id> ThreadId::Int </thread-id>
          <locs-written> Locs::Set </locs-written>
          <buffer> Mem::List </buffer>
          requires notBool ((isThreadDuration(Loc) orBool isAutoDuration(Loc))
                    andBool (ThreadId =/=K getThreadId(Loc)))
               andBool isNativeLoc(Loc)

     rule <k> (.K => IMPL("EIO6", "Attempting to access an object with thread or auto storage duration in a thread other than the one in which the object is associated."))
               ~> readBytes(loc(_, _, _) #as Loc::SymLoc, _, _)
          ...</k>
          <thread-id> ThreadId::Int </thread-id>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool (ThreadId =/=K getThreadId(Loc))
          [structural]

     syntax Error ::= "errorReadOutOfBounds"
                    | "errorUnseqEffects"
                    | "errorNonVolatileLVal"
                    | "errorUninit"

     syntax Bool ::= assertInBounds(Int, Int)
     syntax Bool ::= assertSeq(SymLoc, Set)
     syntax Bool ::= assertVolatile(EffectiveType, Int, Type)
     syntax Bool ::= assertUninit(SymLoc)

     rule assertInBounds(Offset::Int, Len::Int)
          => Offset >=Int Len [macro]
     rule assertSeq(Loc::SymLoc, Locs::Set)
          => (Loc in Locs) [macro]
     rule assertVolatile(ObjT::EffectiveType, Offset::Int, T::Type)
          => ((Volatile() inQuals getQualsAtOffset(ObjT, Offset)))
               andBool notBool isVolatileType(T) [macro]
     rule assertUninit(L::SymLoc)
          => hasLint andBool (isStaticDuration(L) orBool isThreadDuration(L)) [macro]

     // loc, size in bytes, aux list
     syntax K ::= "readBytes-aux" "(" SymLoc "," Int "," List "," Type "," K "," K "," K "," Set "," List "," Bool "," Bool "," Bool "," Bool ")" [function]
     rule readBytes-aux(loc(Base::SymBase, Offset::Int) => loc(Base, Offset) +bytes -1, 
                        Size::Int => Size -Int 1,
                        Aux::List => ListItem(M[Offset]) Aux,
                        T::Type,
                        ObjT::EffectiveType,
                        Len:Int,
                        M::Array,
                        Locs::Set,
                        .List,
                        Seq:Bool => Seq orBool assertSeq(loc(Base, Offset), Locs),
                        InBounds:Bool => InBounds orBool assertInBounds(Offset, Len),
                        VolatileErr:Bool => VolatileErr orBool assertVolatile(ObjT, Offset, T),
                        _)
          requires Size >Int 0 andBool Offset in_keys(M)
     rule readBytes-aux(loc(Base::SymBase, Offset::Int) => loc(Base, Offset) +bytes -1, 
                        Size::Int => Size -Int 1,
                        Aux::List => ListItem(M[Offset]) Aux,
                        T::Type,
                        ObjT::EffectiveType,
                        Len:Int,
                        M::Array,
                        Locs::Set,
                        Mem::List,
                        Seq:Bool => Seq orBool assertSeq(loc(Base, Offset), Locs),
                        InBounds:Bool => InBounds orBool assertInBounds(Offset, Len),
                        VolatileErr:Bool => VolatileErr orBool assertVolatile(ObjT, Offset, T),
                        _)
          requires Size >Int 0 andBool notBool (loc(Base, Offset) in locations(Mem)) andBool Offset in_keys(M)
     rule readBytes-aux(loc(Base::SymBase, Offset::Int) => loc(Base, Offset) +bytes -1, 
                        Size::Int => Size -Int 1,
                        Aux::List => ListItem(getUninitializedBits(loc(Base, Offset), ObjT)) Aux,
                        T::Type,
                        ObjT::EffectiveType,
                        Len:Int,
                        M::Array,
                        Locs::Set,
                        Mem::List,
                        _,
                        InBounds:Bool => InBounds orBool assertInBounds(Offset, Len),
                        VolatileErr:Bool => VolatileErr orBool assertVolatile(ObjT, Offset, T),
                        Uninit:Bool => Uninit orBool assertUninit(loc(Base, Offset)))
          requires Size >Int 0 andBool (notBool (loc(Base, Offset) in locations(Mem)))
               andBool (notBool (Offset in_keys(M))) [owise]
     syntax CValue ::= #readNativeByte(SymLoc) [function, hook(C_SEMANTICS.readNativeByte), impure]
     rule readBytes-aux(Loc::SymLoc => Loc +bytes -1,
                        Size::Int => Size -Int 1,
                        Aux::List => ListItem(#readNativeByte(Loc)) Aux,
                        T::Type,
                        .K,
                        .K,
                        .K,
                        Locs::Set,
                        Mem::List,
                        Seq:Bool => Seq orBool assertSeq(Loc, Locs),
                        _,
                        _,
                        _)
          requires Size >Int 0 andBool notBool (Loc in locations(Mem))
     rule readBytes-aux(_, 0, Aux::List, _, _, _, _, _, _, Seq:Bool, InBounds:Bool, VolatileErr:Bool, Uninit:Bool) 
          => #if Seq #then errorUnseqEffects #else .K #fi ~> 
             #if InBounds #then errorReadOutOfBounds #else .K #fi ~>
             #if VolatileErr #then errorNonVolatileLVal #else .K #fi ~>
             #if Uninit #then errorUninit #else .K #fi ~>
             dataList(Aux)
          [structural]

     syntax Bits ::= getUninitializedBits(SymLoc, EffectiveType) [function]
     rule getUninitializedBits(L::SymLoc, _) => piece(trap, cfg:bitsPerByte)
          requires notBool (isStaticDuration(L) orBool isThreadDuration(L))
     rule getUninitializedBits(L::SymLoc, dynamicType(T::Type)) => getUninitializedBits(L, T)
          requires isStaticDuration(L) orBool isThreadDuration(L)
     rule getUninitializedBits(L::SymLoc, T:Type)
          => getZeroedBits(offset(L) *Int cfg:bitsPerByte, cfg:bitsPerByte, T)
          requires isStaticDuration(L)
     rule getUninitializedBits(L::SymLoc, T:Type)
          => getZeroedBits(offset(L) *Int cfg:bitsPerByte, cfg:bitsPerByte, T)
          requires isThreadDuration(L)

     syntax Bits ::= getZeroedBits(Int, Int, Type) [function]
     rule getZeroedBits(_, N::Int, T::Type)
          => piece(0, N)
          requires isPointerType(T) orBool isArithmeticType(T) orBool N ==Int 0
     rule getZeroedBits(Offset::Int, N::Int, t(_, _, arrayType(T::Type, _)))
          => getZeroedBits(Offset %Int bitSizeofType(T), N, T)
          requires N =/=Int 0
     rule getZeroedBits(Offset::Int, N::Int, T:StructOrUnionType)
          => getZeroedBits(Offset, N, T, getFlatFields(T))
          requires N =/=Int 0

     syntax Bits ::= getZeroedBits(Int, Int, Type, FieldInfo) [function, klabel(getZeroedBits2)]
     rule getZeroedBits(Offset::Int, N::Int, _:UnionType, fieldInfo(ListItem(typedDeclaration(T::Type, _)) _, _, _, _, _))
          => getZeroedBits(Offset, N, T)
     rule getZeroedBits(Offset::Int, N::Int, _:StructType, fieldInfo(
            ((ListItem(typedDeclaration(_, FId::CId))) => .List) _,
            _,
            _::Map (FId |-> T::Type),
            _::Map (FId |-> FOffset::Int), _))
          requires FOffset +Int bitSizeofType(T) <=Int Offset orBool Offset +Int N <=Int FOffset
     rule getZeroedBits(_, 0, _, _)
          => piece(0, 0)
     // this happens when we are reading padding bits, which are zeroed.
     // bit fields never contain padding in between two bit fields in the same byte,
     // so doing this at the end should be safe
     rule getZeroedBits(_, N::Int, _, fieldInfo(.List, _, _, _, _))
          => piece(0, N)

     rule getZeroedBits(Offset::Int, N::Int, BaseT::StructType, fieldInfo(
            (ListItem(typedDeclaration(_, FId::CId))) Fields::List,
            SI::Int,
            Types::Map (FId |-> T::Type),
            Offsets::Map (FId |-> FOffset::Int),
            PaddingOffs::Set))
          => #if isNoName(FId) #then
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
             #fi
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
                   Offsets (FId |-> FOffset),
                   PaddingOffs))
          [owise]

          // TODO(chathhorn): perf, elided
//        syntax KItem ::= readByte(SymLoc, Type)
//        rule [read-byte-buffer]:
//             <k> readByte(Loc:SymLoc)
//                  => assertSeq(Loc, Locs)
//                  ~> tv(V:K, utype(no-type))
//             ...</k>
//             <locs-written> Locs:Set </locs-written>
//             <buffer>... ListItem(bwrite(Loc, V:K)) Mem:List </buffer>
//             requires notBool (Loc in locations(Mem:List))
//             [structural]
//             // for speed in interpretation; forces local buffer to be flushed
//             // before a read
//             //[interpRule]

     rule (.K => UNDEF("EIO7",
               "Reading outside the bounds of an object."))
          ~> errorReadOutOfBounds
          [structural]
     // read outo f bounds becomes a trap by the above rule
     rule (.K => UNDEF("EIO8",
               "Unsequenced side effect on scalar object with value computation of same object."))
          ~> errorUnseqEffects
          [structural]
     rule (.K => UNDEF("EIO9",
               "Trying to access an object declared with volatile type through a non-volatile lvalue."))
          ~> errorNonVolatileLVal
          [structural]

     rule <k> realloc(Old:SymBase, New:SymBase, OldLen:Int, NewLen:Int)
               => alloc(New, type(no-type), NewLen)
               ~> copyBytes(minInt(OldLen, NewLen), Old, New)
               ~> copyObjectType(Old, New)
               ~> deleteObject(Old)
          ...</k>
          [structural]

     syntax KItem ::= copyBytes(Int, SymBase, SymBase)
     rule <k> copyBytes((N':Int => N' -Int 1), Old:SymBase, New:SymBase)
          ...</k>
          <mem>...
               Old |-> object(_, _, M::Array)
               New |-> object(_, _,
                    M'::Array => M'[N' -Int 1 <- M[N' -Int 1] ])
          ...</mem>
          requires ((N' -Int 1) in_keys(M)) andBool (N' >Int 0)
          [structural]
     rule <k> copyBytes((N':Int => N' -Int 1), Old:SymBase, _)
          ...</k>
          <mem>... Old |-> object(_, _, M::Array) ...</mem>
          requires (notBool ((N' -Int 1) in_keys(M))) andBool (N' >Int 0)
          [structural]
     rule copyBytes(0, _, _) => .K
          [structural]

     syntax KItem ::= copyObjectType(SymBase, SymBase)
     rule <k> copyObjectType(Old::SymBase, New::SymBase) => .K ...</k>
          <mem>...
               Old |-> object(T::EffectiveType, _, _)
               New |-> object((_ => T), _, _)
          ...</mem>

     syntax K ::= #freeNativeObject(SymBase) [function, hook(C_SEMANTICS.freeNativeObject)]
     rule #freeNativeObject(_) => .K [owise]

     rule deleteObjects(SetItem(Base::SymBase) Locals::Set)
          => deleteObject(Base) ~> deleteObjects(Locals)
          [structural]
     rule deleteObjects(.Set) => .K
          [structural]

     rule <k> deleteObject(Base:SymBase) => #freeNativeObject(Base) ...</k>
          <mem> M::Map => M[Base <- undef] </mem>
          <buffer> L::List => filterBuffer(L, Base) </buffer>
          [structural]

     syntax List ::= filterBuffer(List, SymBase) [function]
     rule filterBuffer(.List, _) => .List
     rule filterBuffer(ListItem(bwrite(loc(Base::SymBase, _), _)) L::List, Base) => filterBuffer(L, Base)
     rule filterBuffer(ListItem(K:K) L::List, Base::SymBase) => ListItem(K) filterBuffer(L, Base) [owise]

     rule readBytesForWriting(loc(Base::SymBase, Offset::Int, _) => loc(Base, Offset), _, _)
     rule <k> readBytesForWriting(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List)
              => readBytesForWriting(loc(Base, Offset) +bytes 1, Size -Int 1, Aux ListItem(M[Offset]))
          ...</k>
          <buffer> Mem::List </buffer>
          <mem>...
               Base |-> object(_, _, M::Array)
          ...</mem>
          requires Size >Int 0 andBool notBool (loc(Base, Offset) in locations(Mem)) andBool Offset in_keys(M) [structural]
     rule <k> readBytesForWriting(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List)
              => readBytesForWriting(loc(Base, Offset) +bytes 1, Size -Int 1, Aux ListItem(getUninitializedBits(loc(Base, Offset), ObjT)))
          ...</k>
          <buffer> Mem::List </buffer>
          <mem>...
               Base |-> object(ObjT::EffectiveType, _, (M::Array => M[Offset <- getUninitializedBits(loc(Base, Offset), ObjT)]))
          ...</mem>
          requires Size >Int 0 andBool (notBool (Offset in_keys(M)))
               andBool notBool (loc(Base, Offset) in locations(Mem))
     rule readBytesForWriting(_, 0, Aux::List) => dataList(Aux)
          [structural]

     syntax Quals ::= getQualsAtOffset(EffectiveType, Int) [function, klabel(getQualsAtOffset2)]
     rule getQualsAtOffset(dynamicType(T::Type), Offset::Int) => getQualsAtOffset(T, Offset)
     rule getQualsAtOffset(T:Type, Offset::Int)
          => getQualsAtOffset(getTypesAtOffset(T, Offset *Int cfg:bitsPerByte))
     rule getQualsAtOffset(_, _) => noQuals [owise]

     rule getQualsAtOffset(ListItem(T:Type) Ts:List)
          => getQualifiers(T) +Quals getQualsAtOffset(Ts)
     rule getQualsAtOffset(.List) => noQuals

     rule [err00037]:
          (.K => UNDEF("CEER1", "Trying to read through a null pointer.") ) ~>
          read(NullPointer, _)
          [structural]

     // TODO(chathhorn): Silly way to do things. Probably need to allow
     // multiple error cells at least. Also, add more details (loc?).
     // FIXME possible to miss dataraces with bitfields
     rule [read-write-race]:
          <k> (.K => UNDEF("CEER4", "Have a read-write datarace.")) ~>
               read(Loc:SymLoc, T:Type)
          ...</k>
          <k> (.K => UNDEF("CEER4", "Have a read-write datarace.")) ~>
               write(Loc':SymLoc, _, T':Type)
          ...</k>
          requires sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc'
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc'
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]

      rule [write-write-race]:
          <k> (.K => UNDEF("CEER5", "Have a write-write datarace.")) ~>
               write(Loc:SymLoc, _, T:Type)
          ...</k>
          <k> (.K => UNDEF("CEER5", "Have a write-write datarace.")) ~>
               write(Loc':SymLoc, _, T':Type)
          ...</k>
          requires sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc'
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc'
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]

endmodule
