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
     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
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

     syntax K ::= checkWrite(SymLoc, Type)
     rule <k> checkWrite(loc(Base:SymBase, Offset:Int), T:Type) => . ...</k>
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
          [structural]
     rule <k> (. => UNDEF("EIO1", "Unsequenced side effect on scalar object with side effect of same object.", "6.5") )
               ~> checkWrite(Loc:SymLoc, _) 
          ...</k>
          <locs-written> Locs:Bag </locs-written>
          when BagItem(Loc) in Locs:Bag
          [structural] 
     // TODO(chathhorn): probably redundant.
     rule <k> (. => UNDEF("EIO2", "Trying to write outside the bounds of an object.", "6.2.4"))
               ~> checkWrite(loc(Base:SymBase, Offset:Int), _) 
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          when Offset >=Int Len orBool Offset <Int 0
          [structural] 
     rule <k> (. => UNDEF("EIO3", "Trying to modify a string literal or an object declared with const type.", "6.4.5, 6.7.3"))
               ~> checkWrite(loc(Base:SymBase, Offset:Int), _)
          ...</k>
          <mem>... Base |-> object(ObjT:Type, _, _) ...</mem>
          when Const in getQualsAtOffset(ObjT, Offset)
          [structural]
     rule <k> (. => UNDEF("EIO4", "Trying to modify an object declared with volatile type through a non-volatile lvalue.", "6.7.3"))
               ~> checkWrite(loc(Base:SymBase, Offset:Int), T:Type)
          ...</k>
          <mem>... Base |-> object(ObjT:Type, _, _) ...</mem>
          when notBool isVolatileType(T)
               andBool Volatile in getQualsAtOffset(ObjT, Offset)
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
     rule readBytes-aux(_, 0, Aux:List, _) => dataList(values(Aux)) 
          [structural] 
     rule (tv(V:CValue, T:Type) => .K)
          ~> readBytes-aux(_, _, 
               (Aux:List => Aux ListItem(tv(V, T))), _)
          [structural]        
     
     syntax List ::= values(List) [function]
     rule values(ListItem(tv(K:K, _)) L:List) => ListItem(K) values(L)
     rule values(.List) => .List

     // FIXME make sure it's a byte

     syntax Error ::= "errorReadOutOfBounds"
                    | "errorUnseqEffects"
                    | "errorNonVolatileLVal"
     
     syntax K ::= readByte(SymLoc, Type)
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
          => UNDEF("EIO5", "Reading outside the bounds of an object.", "6.2.4")
          [structural]
     rule errorUnseqEffects
          => UNDEF("EIO6", "Unsequenced side effect on scalar object with value computation of same object.", "6.5") 
          [structural]
     rule errorNonVolatileLVal
          => UNDEF("EIO7", "Trying to access an object declared with volatile type through a non-volatile lvalue.", "6.7.3")
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

endmodule
