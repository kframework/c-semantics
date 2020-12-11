module COMMON-IO-BUFFERED-SYNTAX
     imports LIST
     imports SYMLOC-SORTS

     syntax KItem ::= writeBytesBuffered(SymLoc, List)
     syntax KItem ::= bwrite(SymLoc, List) // jan.tusil: Really? I think that the K sort would be enough
     syntax Set ::= locations(List) [function]
     syntax List ::= writeNativeByte(SymLoc, K) [function]

endmodule

module COMMON-IO-BUFFERED
     imports COMMON-IO-BUFFERED-SYNTAX
     imports C-CONFIGURATION
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX

     rule <k> writeBytesBuffered(Loc::SymLoc, L::List) => .K ...</k>
          <buffer>... .List => ListItem(bwrite(Loc, L)) </buffer>
          [structural]

     //TODO(dwightguth): when we do symbolic execution we need to rework this stuff to obey the C11 memory model
     rule <buffer>
               ListItem(bwrite(loc(Base::SymBase, Offset::Int), L::List)) => .List
          ...</buffer>
          <mem> M::Map => bufferWrite(M, Base, M[Base], Offset, L) </mem>
          requires isHardwareLoc(loc(Base, Offset)) orBool notBool isNativeLoc(loc(Base, Offset))
          [structural, priority(80)]
     rule <buffer>
               ListItem(bwrite((Loc::SymLoc => Loc +bytes 1), ((ListItem(V:KItem) => writeNativeByte(Loc, V)) _::List)))
          ...</buffer>
          requires isNativeLoc(Loc) [priority(80)]
     rule <buffer>
               ListItem(bwrite(Loc::SymLoc, .List)) => .List
          ...</buffer>
          requires isNativeLoc(Loc) [priority(80)]

     rule locations(.List) => .Set
     rule locations(ListItem(bwrite(Loc::SymLoc, Bytes::List)) L::List)
          => #locations(Loc, size(Bytes)) locations(L)
     syntax Set ::= #locations(SymLoc, Int) [function]
     rule #locations(Loc::SymLoc, I:Int) => SetItem(Loc) #locations(Loc +bytes 1, I -Int 1)
          requires I >Int 0
     rule #locations(Loc::SymLoc, 0) => .Set

     syntax Map ::= bufferWrite(Map, SymBase, K, Int, List) [function]
     rule bufferWrite(M::Map, Base::SymBase, object(T::EffectiveType, Len::Int, Bytes::Array), Offset::Int, Buffer::List)
          => M[Base <- object(T, Len, updateArray(Bytes, Offset, Buffer))]


endmodule
