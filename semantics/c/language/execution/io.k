module C-IO-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports MAP
     imports SYMLOC-SORTS

     syntax KItem ::= realloc(SymBase, SymBase, Int, Int)
     syntax Bits ::= getUninitializedBits(SymLoc, EffectiveType) [function]

endmodule

module C-IO
     imports C-IO-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports BITS-SYNTAX
     imports SETTINGS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-TYPING-SYNTAX
     imports DELETE-OBJECT-SYNTAX
     imports COMMON-IO-BUFFERED-SYNTAX

     rule writeBytes(Loc::SymLoc, Bytes::List)
          => checkRestrict(true, Loc)
          ~> checkWrite(stripProv(Loc))
          ~> checkSeq(stripProv(Loc))
          ~> checkBounds(stripProv(Loc), size(Bytes))
          ~> writeBytesBuffered(stripProv(Loc), Bytes)
     rule writeBytesFill(Loc::SymLoc, N::Int, V::Bits)
          => checkRestrict(true, Loc)
          ~> checkWrite(stripProv(Loc))
          ~> checkSeq(stripProv(Loc))
          ~> checkBounds(stripProv(Loc), N)
          ~> fillBytesBuffered(stripProv(Loc), N, V)

     rule initBytes(Loc::SymLoc, Bytes::List)
          => writeBytesBuffered(stripProv(Loc), Bytes)
     rule initBytesFill(Loc::SymLoc, N::Int, V::Bits)
          => fillBytesBuffered(stripProv(Loc), N, V)


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

     syntax KItem ::= checkWrite(SymLoc)
     rule <k> checkWrite(loc(Base::SymBase, Offset::Int)) => .K ...</k>
          <thread-id> ThreadId::Int </thread-id>
          <mem>... Base |-> object(ObjT::EffectiveType, Len::Int, _) ...</mem>
          requires // Const.
               (notBool (Const() inQuals getQualsAtOffset(ObjT, Offset)))
               // Cross-thread writes.
               andBool notBool ((isThreadDuration(loc(Base, Offset))
                         orBool isAutoDuration(loc(Base, Offset)))
                    andBool (ThreadId =/=K getThreadId(loc(Base, Offset))))
               // Libc fixed.
               andBool (notBool isLibcFixedDuration(Base))
          [structural]
     rule checkWrite(Loc::SymLoc) => .K
          requires isNativeLoc(Loc)
     rule <k> (.K => UNDEF("EIO3",
               "Trying to modify an object declared with const type."))
               ~> checkWrite(loc(Base::SymBase, Offset::Int))
          ...</k>
          <mem>... Base |-> object(ObjT::EffectiveType, _, _) ...</mem>
          requires Const() inQuals getQualsAtOffset(ObjT, Offset)
          [structural]
     rule <k> (.K => IMPL("EIO5",
               "Trying to modify an object with thread or auto storage duration in a thread other than the one in which the object is associated."))
               ~> checkWrite(Loc::SymLoc)
          ...</k>
          <thread-id> ThreadId::Int </thread-id>
          requires (isThreadDuration(Loc) orBool isAutoDuration(Loc))
               andBool (ThreadId =/=K getThreadId(Loc))
          [structural]
     rule (.K => UNDEF("EIO11",
               "Trying to modify an unmodifiable object returned by a library function."))
          ~> checkWrite(loc(Base::SymBase, _))
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

     syntax KItem ::= fillBytesBuffered(SymLoc, Int, Bits)
     rule <k> fillBytesBuffered(Loc::SymLoc, N::Int, V::Bits) => .K ...</k>
          <buffer>... .List => ListItem(bfill(Loc, N, V)) </buffer>
          [structural]

     rule writeNativeByte(L::SymLoc, K::K) => #writeNativeByte(L, K)
     syntax List ::= #writeNativeByte(SymLoc, K) [function, hook(C_SEMANTICS.writeNativeByte), impure]

     syntax KItem ::= bfill(SymLoc, Int, Bits)
     syntax List ::= #fillNativeBytes(SymLoc, Int, K) [function, hook(C_SEMANTICS.fillNativeBytes), impure]
     rule <buffer>
               ListItem(bfill(Loc::SymLoc, N::Int, V::Bits)) => .List
          ...</buffer>
          <mem> M::Map => bufferFill(M, base(Loc), M[base(Loc)], offset(Loc), N, V) </mem>
          requires notBool isNativeLoc(Loc)
          [structural, priority(80)]
     rule <buffer>
               ListItem(bfill(Loc::SymLoc, N::Int, V::Bits)) => #fillNativeBytes(Loc, N, V)
          ...</buffer>
          requires isNativeLoc(Loc) [priority(80)]

     syntax Map ::= bufferFill(Map, SymBase, K, Int, Int, Bits) [function]
     rule bufferFill(M::Map, Base::SymBase, object(T::EffectiveType, Len::Int, Bytes::Array), Offset::Int, N::Int, V::Bits)
          => M[Base <- object(T, Len, fillArray(Bytes, Offset, N, V))]

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
          requires Size >Int 0 andBool Offset in_keys(M) andBool M[Offset] =/=K uninit
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
          requires Size >Int 0 andBool notBool (loc(Base, Offset) in locations(Mem)) andBool Offset in_keys(M) andBool M[Offset] =/=K uninit
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
               andBool (notBool (Offset in_keys(M)) orBool M[Offset] ==K uninit) [owise]
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

     rule getUninitializedBits(L::SymLoc, _) => piece(trap, cfg:bitsPerByte)
          requires notBool (isStaticDuration(L) orBool isThreadDuration(L))
     rule getUninitializedBits(L::SymLoc, dynamicType(T::Type))
          => getZeroedBits(offset(L) *Int cfg:bitsPerByte, cfg:bitsPerByte, T)
          requires isStaticDuration(L) orBool isThreadDuration(L)
     rule getUninitializedBits(L::SymLoc, t(...) #as T::Type)
          => getZeroedBits(offset(L) *Int cfg:bitsPerByte, cfg:bitsPerByte, T)
          requires isStaticDuration(L) orBool isThreadDuration(L)

     syntax Bits ::= getZeroedBits(Int, Int, Type) [function]
     rule getZeroedBits(_, N::Int, T::Type)
          => piece(0, N)
          requires isPointerType(T) orBool isArithmeticType(T) orBool N ==Int 0
     rule getZeroedBits(Offset::Int, N::Int, t(_, _, arrayType(T::Type, _)))
          => getZeroedBits(Offset %Int bitSizeofType(T), N, T)
          requires N =/=Int 0
     rule getZeroedBits(Offset::Int, N::Int, structOrUnionType #as T::Type)
          => getZeroedBits(Offset, N, T, getFlatFields(T))
          requires N =/=Int 0

     syntax Bits ::= getZeroedBits(Int, Int, Type, FieldInfo) [function, klabel(getZeroedBits2)]
     rule getZeroedBits(Offset::Int, N::Int, t(... st: unionType(_)), fieldInfo(ListItem(typedDeclaration(T::Type, _)) _, _, _, _, _))
          => getZeroedBits(Offset, N, T)
     rule getZeroedBits(Offset::Int, N::Int, t(... st: structType(_)), fieldInfo(
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

     rule getZeroedBits(Offset::Int, N::Int, BaseT::Type, fieldInfo(
            (ListItem(typedDeclaration(_, FId::CId))) Fields::List,
            SI::Int,
            Types::Map (FId |-> T::Type),
            Offsets::Map (FId |-> FOffset::Int),
            PaddingOffs::Set))
          => #if isNoName(FId) #then
               // the bits of the field in the current byte are traps, because it was unnamed
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
                 // read the remaining bits in the byte
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
          requires ((N' -Int 1) in_keys(M)) andBool M[N' -Int 1] =/=K uninit andBool (N' >Int 0)
          [structural]
     rule <k> copyBytes((N':Int => N' -Int 1), Old:SymBase, _)
          ...</k>
          <mem>... Old |-> object(_, _, M::Array) ...</mem>
          requires (notBool ((N' -Int 1) in_keys(M)) orBool M[N' -Int 1] ==K uninit) andBool (N' >Int 0)
          [structural]
     rule copyBytes(0, _, _) => .K
          [structural]

     syntax KItem ::= copyObjectType(SymBase, SymBase)
     rule <k> copyObjectType(Old::SymBase, New::SymBase) => .K ...</k>
          <mem>...
               Old |-> object(T::EffectiveType, _, _)
               New |-> object((_ => T), _, _)
          ...</mem>

     rule freeNativeObject(B::SymBase) => #freeNativeObject(B)
     syntax K ::= #freeNativeObject(SymBase) [function, hook(C_SEMANTICS.freeNativeObject)]
     rule #freeNativeObject(_) => .K [owise]

     rule readBytesForWriting(loc(Base::SymBase, Offset::Int, _) => loc(Base, Offset), _)
     rule (.K => dataList(.List)) ~> readBytesForWriting(loc(_, _), Size::Int)
          requires Size >Int 0
     rule <k> dataList(_::List (.List => ListItem(M[Offset])))
               ~> readBytesForWriting(loc(Base::SymBase, Offset::Int) #as Loc::SymLoc => Loc +bytes 1, Size::Int => Size -Int 1)
          ...</k>
          <buffer> Mem::List </buffer>
          <mem>...
               Base |-> object(_, _, M::Array)
          ...</mem>
          requires Size >Int 0
               andBool notBool (Loc in locations(Mem))
               andBool Offset in_keys(M) andBool M[Offset] =/=K uninit
          [structural]
     rule <k> dataList(_::List (.List => ListItem(getUninitializedBits(Loc, ObjT))))
               ~> readBytesForWriting(loc(Base::SymBase, Offset::Int) #as Loc::SymLoc => Loc +bytes 1, Size::Int => Size -Int 1)
          ...</k>
          <buffer> Mem::List </buffer>
          <mem>...
               Base |-> object(ObjT::EffectiveType, _, (M::Array => M[Offset <- getUninitializedBits(Loc, ObjT)]))
          ...</mem>
          requires Size >Int 0
               andBool notBool (Loc in locations(Mem))
               andBool notBool (Offset in_keys(M) andBool M[Offset] =/=K uninit)
     rule dataList(_) ~> (readBytesForWriting(_, 0) => .K)
          [structural]

     rule [err00037]:
          (.K => UNDEF("CEER1", "Trying to read through a null pointer.") ) ~>
          read(NullPointer, _)
          [structural]

endmodule
