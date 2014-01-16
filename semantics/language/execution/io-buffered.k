module C-IO-BUFFERED-SYNTAX
     syntax K ::= realloc(SymLoc, SymLoc, Int, Int)

     // deletes the base object from memory, given a location
     syntax K ::= deleteBlock(SymLoc)
     // deletes the base object from memory, given a location and it size (as a
     // check)
     syntax K ::= deleteSizedBlock(SymLoc, Int)
endmodule

module C-IO-BUFFERED
     imports C-IO-BUFFERED-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-BITS-SYNTAX
     imports C11-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     imports DEBUG-SYNTAX

     syntax ListItem ::= "bwrite" "(" SymLoc "," K ")"

     rule writeBytes(Loc:SymLoc, dataList((V:K,, L:KList)), false)
          => writeByte(Loc, V) ~> 
               writeBytes(Loc +bytes 1, dataList(L), false)
          [structural]
     rule writeBytes(Loc:SymLoc, dataList((V:K,, L:KList)), true)
          => stealthWriteByte(Loc, V) ~> 
               writeBytes(Loc +bytes 1, dataList(L), true)
          [structural]
     rule writeBytes(_, dataList(.KList), _) => .K
          [structural] 

     syntax K ::= stealthWriteByte(SymLoc, K)
     rule [write-byte-stealth]:
          <k> 
               stealthWriteByte(loc(Base:SymBase, Offset:Int, 0), V:K) => . 
          ...</k>
          <buffer>... (.List => bwrite(loc(Base, Offset, 0), V)) </buffer>
          [large, structural]

     rule [write-byte-buffer]:
          <k> writeByte(loc(Base:SymBase, Offset:Int, 0), V:K) => . ...</k>
          <buffer>...
               (.List => bwrite(loc(Base, Offset, 0), V))
          </buffer>
          <mem>... Base |-> memblock(Len:Int, Attrs:Bag, _) ...</mem>
          <locsWrittenTo>
               Locs:Bag (.Bag => BagItem(loc(Base, Offset, 0)))
          </locsWrittenTo>
          <notWritable> NotWritable:Map </notWritable>
          when (notBool BagItem(loc(Base, Offset, 0)) in Locs)
               andBool (notBool (BagItem(mconst) in Attrs))
               andBool (notBool (loc(Base, Offset, 0) in keys NotWritable))
               andBool (Offset <Int Len)
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

     syntax Set ::= locations(List) [function]
     rule [locations-none]: locations(.List) => .Set
     rule [locations-some]: locations(bwrite(Loc:SymLoc, _) L:List)
          => SetItem(Loc) locations(L:List)

     // loc, size in bytes, aux list
     syntax K ::= "readBytes-aux" "(" SymLoc "," Int "," KList ")"
     
     rule readBytes(Loc:SymLoc, Size:Int) 
          => readBytes-aux(Loc, Size, .KList) 
          [structural] 
          
     // fixme sNat
     rule readBytes-aux(Loc:SymLoc, Size:Int, Aux:KList)
          => readByte(Loc)
          ~> readBytes-aux(Loc +bytes 1, Size -Int 1, Aux)
          when Size:Int >Int 0
          [structural]
     rule (tv(V:KList, T:Type) => .K)
               ~> readBytes-aux(_, _, 
                    (Aux:KList => (Aux,, tv(V, T))))
          [structural]        
     
     syntax KList ::= values(KList) [function]
     rule values((tv(K:K, _),, L:KList)) => (K:K,, values(L:KList))
     rule values(.KList) => .KList
     rule readBytes-aux(_, 0, Aux:KList) 
          => dataList(values(Aux:KList)) 
          [structural] 
     
     // FIXME make sure it's a byte
     
     rule [read-byte-fast]:
          <k> readByte(loc(Base:SymBase, Offset:Int, 0))
               => assert(notBool (BagItem(loc(Base, Offset, 0)) in Locs), 3)
                    ~> assert(Offset <Int Len, 2)
                    ~> tv(V, t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, _, (_ Offset:Int |-> V:K)) 
          ...</mem>
          <locsWrittenTo> Locs:Bag </locsWrittenTo>
          <buffer> .List </buffer>
          [large, structural]

     rule [read-byte]:
          <k> readByte(loc(Base:SymBase, Offset:Int, 0))
               => assert(notBool 
                    (BagItem(loc(Base, Offset, 0)) in Locs), 3)
                    ~> assert(Offset <Int Len, 2)
                    ~> tv(V, t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, _, (_ Offset:Int |-> V:K)) 
          ...</mem>
          <locsWrittenTo> Locs:Bag </locsWrittenTo>
          <buffer> Mem:List </buffer>
          when notBool loc(Base, Offset, 0) in locations(Mem)
          [large, structural]
          
     rule [read-byte-lazy]:
          <k> readByte(loc(Base:SymBase, Offset:Int, 0)) 
               => assert(Offset:Int <Int Len:Int, 2)
                    ~> tv(piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte), 
                         t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, _, 
                    M:Map => M:Map[
                         piece(unknown(cfg:bitsPerByte), cfg:bitsPerByte) 
                         / Offset]) 
          ...</mem>
          <buffer> Mem:List </buffer>
          when (notBool loc(Base, Offset, 0) in locations(Mem))
               andBool (notBool Offset in (keys M))
          [large, structural]
          
          // TODO(chathhorn): perf, elided
//        rule [read-byte-buffer]:
//             <k> readByte(Loc:SymLoc) 
//                  => assert(notBool BagItem(Loc) in Locs:Bag, 3)
//                  ~> tv(V:K, t(.Set, no-type))
//             ...</k>
//             <locsWrittenTo> Locs:Bag </locsWrittenTo>
//             <buffer>... bwrite(Loc, V:K) Mem:List </buffer>
//             when notBool Loc in locations(Mem:List)
//             [structural]
//             // for speed in interpretation; forces local buffer to be flushed
//             // before a read
//             //[interpRule] 

     syntax K ::= "realloc-aux" "(" Int "," SymLoc "," SymLoc "," Int "," Int ")"
     rule [realloc-start]:
          <k> 
               realloc(Old:SymLoc, New:SymLoc, OldLen:Int, NewLen:Int)
               => alloc(New, NewLen)
                    ~> realloc-aux(minInt(OldLen, NewLen), 
                         Old, New, OldLen, NewLen)
          ...</k>
          [structural]
          
     rule [realloc-found]:
          <k> 
               realloc-aux((SNatN:Int => SNatN:Int -Int 1), 
                    loc(OldBase:SymBase, 0, 0), 
                    loc(NewBase:SymBase, 0, 0), _, _)
          ...</k>
          <mem>... 
               OldBase |-> memblock(_, _, (_ N:Int |-> K:K))
               NewBase |-> memblock(_, _, (_ (.Map => SNatN:Int -Int 1 |-> K:K)))
          ...</mem>
          when (N ==Int SNatN -Int 1)
               andBool (SNatN >Int 0)
          [structural]   
          
     // fixme sNat
     rule [realloc-unfound]:
          <k> 
               realloc-aux((SNatN:Int => SNatN -Int 1), 
                    loc(OldBase:SymBase, 0, 0), loc(_:SymBase, 0, 0), _, _)
          ...</k>
          <mem>... OldBase |-> memblock(_, _, M:Map) ...</mem>
          when (notBool SNatN:Int -Int 1 in keys M:Map)
               andBool (SNatN >Int 0)
          [structural]
     rule [realloc-0]:
          realloc-aux(0, loc(OldBase:SymBase, 0, 0), _, OldLen:Int, _)
          => deleteSizedBlock(loc(OldBase, 0, 0), OldLen:Int) 
          [structural]   
          
     rule [delete-sized-block]:
          <k>
               deleteSizedBlock(loc(Base:SymBase, _:Int, _:Int), Len:Int) => . 
          ...</k>
          <mem>... Base |-> memblock(Len, _, _) => .Map ...</mem>
          // fixme could make this more relaxed by checking of block is in
          // buffer, not just empty
          <buffer> .List </buffer>
          [structural] 
     
     rule [delete-block]:
          <k> deleteBlock(loc(Base:SymBase, _:Int, _:Int)) => .K ...</k>
          <mem>... Base |-> memblock(_, _, _) => .Map ...</mem>
          <buffer> .List </buffer>
          [structural] 

endmodule
