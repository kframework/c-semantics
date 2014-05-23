module C-IO-DIRECT
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-BITS-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports COMPAT-SYNTAX

     imports DEBUG-SYNTAX

     syntax K ::= writeBytes(SymLoc, DataList)
     syntax K ::= writeByte(SymLoc, CValue)

     // In the static semantics, we only allow writing to memory during
     // initialization (of statics).
     rule writeBytes(Loc:SymLoc, D:DataList, T:Type) => writeBytes(Loc, D)
          when isInitializerType(T)
          [structural]

     rule writeBytes(_, _, T:Type) => .
          when notBool isInitializerType(T)
          [structural]

     rule writeBytes(Loc:SymLoc, dataList(ListItem(V:CValue) L:List))
          => writeByte(Loc, V) ~> 
               writeBytes(Loc +bytes 1, dataList(L))
          [structural]

     rule writeBytes(_, dataList(.List)) => .
          [structural] 

     rule <k> writeByte(loc(Base:SymBase, Offset:Int, 0), V:CValue) => . ...</k>
          <mem>... 
               Base |-> memblock(Len:Int, _, (M:Map => M:Map[V <- Offset]))
          ...</mem>
          when (Offset <Int Len) andBool notBool isSymbolic(V)
          [structural]

     rule (. => CVUB("IO1", "Non-constant initializer.", "6.6"))
          ~> writeByte(_, V:CValue)
          when isSymbolic(V)
          [structural]

     syntax K ::= readByte(SymLoc) 
     // loc, size in bytes, aux list
     syntax K ::= "readBytes-aux" "(" SymLoc "," Int "," List ")"
     
     rule readBytes(Loc:SymLoc, Size:Int, _) 
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
     
     rule <k> readByte(loc(Base:SymBase, Offset:Int, 0))
               => tv(V, t(.Set, no-type))
          ...</k>
          <mem>... 
               Base |-> memblock(_, _, (_ Offset:Int |-> V:K)) 
          ...</mem>
          [structural]
endmodule
