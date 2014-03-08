module C-IO-DIRECT
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-BITS-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     imports DEBUG-SYNTAX

     syntax K ::= writeBytes(SymLoc, K)

     rule writeBytes(Loc:SymLoc, K:KResult, _)
          => writeBytes(Loc, K)

     rule writeBytes(Loc:SymLoc, dataList(ListItem(V:CValue) L:List))
          => writeByte(Loc, V) ~> 
               writeBytes(Loc +bytes 1, dataList(L))
          [structural]
     rule writeBytes(_, dataList(.List)) => .
          [structural] 

     rule [write-byte]:
          <k> writeByte(loc(Base:SymBase, Offset:Int, 0), V:CValue) => . ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, Attrs:Bag, M:Map => M:Map[V / Offset]) 
          ...</mem>
          <not-writable> NotWritable:Set </not-writable>
          when (notBool (BagItem(mconst) in Attrs))
               andBool (notBool (loc(Base, Offset, 0) in NotWritable))
               andBool (Offset <Int Len)
          [large, structural]

     // loc, size in bytes, aux list
     syntax K ::= "readBytes-aux" "(" SymLoc "," Int "," List ")"
     
     rule readBytes(Loc:SymLoc, Size:Int) 
          => readBytes-aux(Loc, Size, .List) 
          [structural] 
          
     // fixme sNat
     rule readBytes-aux(Loc:SymLoc, Size:Int, Aux:List)
          => readByte(Loc)
          ~> readBytes-aux(Loc +bytes 1, Size -Int 1, Aux)
          when Size:Int >Int 0
          [structural]
     rule (tv(V:CValue, T:Type) => .K)
          ~> readBytes-aux(_, _, (Aux:List => Aux ListItem(tv(V, T))))
          [structural]        
          
     syntax List ::= values(List) [function]
     rule values(ListItem(tv(K:K, _)) L:List) => ListItem(K:K) values(L:List)
     rule values(.List) => .List

     rule readBytes-aux(_, 0, Aux:List) 
          => dataList(values(Aux:List)) 
          [structural] 
     
     // FIXME make sure it's a byte
     rule [read-byte-fast]:
          <k> readByte(loc(Base:SymBase, Offset:Int, 0))
               => assert(Offset <Int Len, 2) ~> tv(V, t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, _, (_ Offset:Int |-> V:K)) 
          ...</mem>
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
          when notBool Offset in (keys M)
          [large, structural]

endmodule
