module C-IO-BUFFERED-SYNTAX
     syntax K ::= realloc(SymLoc, SymLoc, Int, Int)

     // deletes the base object from memory, given a location
     syntax K ::= deleteBlock(SymLoc)
     // deletes the base object from memory, given a location and it size (as a
     // check)
     syntax K ::= deleteSizedBlock(SymLoc, Int)

     syntax K ::= checkWrite(SymLoc, Type)

     syntax K ::= writeByte(SymLoc, CValue)
endmodule

module C-IO-BUFFERED
     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-DECL-ZERO-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax ListItem ::= bwrite(SymLoc, K)

     rule writeBytes(Loc:SymLoc, dataList(ListItem(V:CValue) L:List), T:Type)
          => checkWrite(Loc, T) 
          ~> writeByte(Loc, V)
          ~> writeBytes(Loc +bytes 1, dataList(L), T)
          when notBool isInitializerType(T)
          [structural]
     rule writeBytes(Loc:SymLoc, dataList(ListItem(V:CValue) L:List), T:Type)
          => writeByte(Loc, V)
          ~> writeBytes(Loc +bytes 1, dataList(L), T)
          when isInitializerType(T)
          [structural]
     rule writeBytes(_, dataList(.List), _) => .
          [structural] 

     rule <k> checkWrite(loc(Base:SymBase, Offset:Int, 0), T:Type) => . ...</k>
          <mem>... Base |-> memblock(Len:Int, Attrs:Bag, _) ...</mem>
          <locs-written>
               Locs:Bag (.Bag => BagItem(loc(Base, Offset, 0)))
          </locs-written>
          <not-writable> NotWritable:Set </not-writable>
          when // Sequencing.
               (notBool BagItem(loc(Base, Offset, 0)) in Locs)
               // Bounds.
               andBool (Offset <Int Len)
               // Const.
               andBool (notBool (BagItem(mconst) in Attrs))
               andBool (notBool (loc(Base, Offset, 0) in NotWritable))
               // Volatile.
               andBool (notBool (BagItem(mvolatile) in Attrs)
                    orBool isVolatileType(T))
          [structural]

     rule <k> writeByte(loc(Base:SymBase, Offset:Int, 0), V:CValue) => . ...</k>
          <buffer>... (.List => bwrite(loc(Base, Offset, 0), V)) </buffer>
          [structural]
          
     rule <buffer>
               (bwrite(loc(Base:SymBase, Offset:Int, 0), V:K) => .List)
          ...</buffer>
          <mem>...
               Base |-> memblock(Len:Int, _, M:Map => M[V <- Offset])
          ...</mem>
          when Offset <Int Len
          [structural]

     syntax Set ::= locations(List) [function]
     rule locations(.List) => .Set
     rule locations(bwrite(Loc:SymLoc, _) L:List)
          => SetItem(Loc) locations(L)

     rule readBytes(Loc:SymLoc, Size:Int, T:Type)
          => readBytes-aux(Loc, Size, .List, T) 
          [structural] 
          
     // loc, size in bytes, aux list
     syntax K ::= "readBytes-aux" "(" SymLoc "," Int "," List "," Type ")"
     rule readBytes-aux(Loc:SymLoc, Size:Int, Aux:List, T:Type)
          => readByte(Loc, T)
          ~> readBytes-aux(Loc +bytes 1, Size -Int 1, Aux, T)
          when Size >Int 0
          [structural]
     rule (tv(V:CValue, T:Type) => .K)
          ~> readBytes-aux(_, _, 
               (Aux:List => Aux ListItem(tv(V, T))), _)
          [structural]        
     
     syntax List ::= values(List) [function]
     rule values(ListItem(tv(K:K, _)) L:List) => ListItem(K) values(L)
     rule values(.List) => .List

     rule readBytes-aux(_, 0, Aux:List, _) => dataList(values(Aux)) 
          [structural] 
     
     // FIXME make sure it's a byte

     syntax Error ::= "errorReadOutOfBounds"
                    | "errorUnseqEffects"
                    | "errorNonVolatileLVal"
     
     syntax K ::= readByte(SymLoc, Type)
     rule <k> readByte(loc(Base:SymBase, Offset:Int, 0), T:Type)
               => assert(notBool (BagItem(loc(Base, Offset, 0)) in Locs),
                    errorUnseqEffects)
               ~> assert(Offset <Int Len, errorReadOutOfBounds)
               ~> assert(notBool (BagItem(mvolatile) in Attrs) orBool isVolatileType(T),
                    errorNonVolatileLVal)
               ~> tv(V, t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, Attrs:Bag, (_ Offset:Int |-> V:K)) 
          ...</mem>
          <locs-written> Locs:Bag </locs-written>
          <buffer> .List </buffer>
          [structural]

     rule <k> readByte(loc(Base:SymBase, Offset:Int, 0), T:Type)
               => assert(notBool (BagItem(loc(Base, Offset, 0)) in Locs),
                    errorUnseqEffects)
               ~> assert(Offset <Int Len, errorReadOutOfBounds)
               ~> assert(notBool (BagItem(mvolatile) in Attrs) orBool isVolatileType(T),
                    errorNonVolatileLVal)
               ~> tv(V, t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, Attrs:Bag, (_ Offset:Int |-> V:K)) 
          ...</mem>
          <locs-written> Locs:Bag </locs-written>
          <buffer> Mem:List </buffer>
          when notBool loc(Base, Offset, 0) in locations(Mem)
          [structural]
     rule <k> readByte(loc(Base:SymBase, Offset:Int, 0), T:Type) 
               => assert(Offset:Int <Int Len:Int, errorReadOutOfBounds)
               ~> assert(notBool (BagItem(mvolatile) in Attrs) orBool isVolatileType(T), 
                   errorNonVolatileLVal)
               ~> tv(piece(trap(cfg:bitsPerByte), cfg:bitsPerByte), t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, Attrs:Bag, 
               M:Map => M[
                    piece(trap(cfg:bitsPerByte), cfg:bitsPerByte) <- Offset]) 
          ...</mem>
          <buffer> Mem:List </buffer>
          when (notBool loc(Base, Offset, 0) in locations(Mem))
               andBool (notBool Offset in (keys(M)))
               andBool (notBool isStaticDuration(loc(Base, Offset, 0)))
          [structural]
     rule <k> readByte(loc(Base:SymBase, Offset:Int, 0), T:Type) 
               => assert(Offset:Int <Int Len:Int, errorReadOutOfBounds)
               ~> assert(notBool (BagItem(mvolatile) in Attrs) orBool isVolatileType(T), 
                   errorNonVolatileLVal)
               ~> tv(piece(encode(getZero(T)), cfg:bitsPerByte), t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, Attrs:Bag, 
               // Re getZero(): not totally sure this works because it's based
               // on the type of the lvalue being read through and not the type
               // of the declaration. But hopefully all mismatches between the
               // lvalue type and the declared type should be caught by now.
               M:Map => M[piece(encode(getZero(T)), cfg:bitsPerByte) <- Offset]) 
          ...</mem>
          <buffer> Mem:List </buffer>
          when (notBool loc(Base, Offset, 0) in locations(Mem))
               andBool (notBool Offset in (keys(M)))
               andBool (isStaticDuration(loc(Base, Offset, 0))
                    orBool isThreadDuration(loc(Base, Offset, 0)))
          [structural]

     syntax Bits ::= encode(K) [function]
     rule encode(F:Float) => encodedFloat(F)
     rule encode(V:K) => V
          when isFloat(V) =/=K true

     // Resolve a linker address to a real "physical" address.
     rule <k> readByte(loc((LinkBase:SymBase => Base), _, _), _) ...</k>
          <linkings>... 
               loc(LinkBase, 0, 0) |-> loc(Base:SymBase, _, _)
          ...</linkings>
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
          => UNDEF("EIO1", "Reading outside the bounds of an object.", "6.2.4")
          [structural]
     rule errorUnseqEffects
          => UNDEF("EIO2", "Unsequenced side effect on scalar object with value computation of same object.", "6.5") 
          [structural]
     rule errorNonVolatileLVal
          => UNDEF("EIO3", "Trying to access an object declared with volatile type through a non-volatile lvalue.", "6.7.3")
          [structural]

     syntax K ::= "realloc-aux" "(" Int "," SymLoc "," SymLoc "," Int "," Int ")"
     rule <k> realloc(Old:SymLoc, New:SymLoc, OldLen:Int, NewLen:Int)
               => alloc(New, NewLen, .Bag)
                    ~> realloc-aux(minInt(OldLen, NewLen), 
                         Old, New, OldLen, NewLen)
          ...</k>
          [structural]
          
     rule <k> realloc-aux((SNatN:Int => SNatN -Int 1), 
               loc(OldBase:SymBase, _, _), 
               loc(NewBase:SymBase, _, _), _, _)
          ...</k>
          <mem>... 
               OldBase |-> memblock(_, _, (_ N:Int |-> K:K))
               NewBase |-> memblock(_, _, (_ (.Map => SNatN -Int 1 |-> K)))
          ...</mem>
          when (N ==Int SNatN -Int 1)
               andBool (SNatN >Int 0)
          [structural]   
          
     // fixme sNat
     rule <k> realloc-aux((SNatN:Int => SNatN -Int 1), 
                    loc(OldBase:SymBase, _, _), _, _, _)
          ...</k>
          <mem>... OldBase |-> memblock(_, _, M:Map) ...</mem>
          when (notBool SNatN -Int 1 in keys(M))
               andBool (SNatN >Int 0)
          [structural]
     rule realloc-aux(0,
               loc(OldBase:SymBase, _, _),
               loc(NewBase:SymBase, _, _), OldLen:Int, _)
          => copyModifiers(OldBase, NewBase)
          ~> deleteSizedBlock(loc(OldBase, 0, 0), OldLen)
          [structural]   

     syntax K ::= copyModifiers(SymBase, SymBase)
     rule <k> copyModifiers(OldBase:SymBase, NewBase:SymBase) => . ...</k>
          <mem>... 
               OldBase |-> memblock(_, Mods:Bag, _)
               NewBase |-> memblock(_, (_ => Mods), _)
          ...</mem>
          
     rule <k> deleteSizedBlock(loc(Base:SymBase, _, _), Len:Int) => . 
          ...</k>
          <mem>... Base |-> memblock(Len, _, _) => .Map ...</mem>
          // fixme could make this more relaxed by checking of block is in
          // buffer, not just empty
          <buffer> .List </buffer>
          [structural] 
     
     rule <k> deleteBlock(loc(Base:SymBase, _, _)) => .K ...</k>
          <mem>... Base |-> memblock(_, _, _) => .Map ...</mem>
          <buffer> .List </buffer>
          [structural] 

endmodule
