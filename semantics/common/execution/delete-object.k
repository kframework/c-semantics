module DELETE-OBJECT-SYNTAX
     imports SET
     imports SYMLOC-SORTS

     // deletes the base object from memory, given a location
     syntax KItem ::= deleteObject(SymBase)
     syntax KItem ::= deleteObjects(Set)
     syntax K ::= freeNativeObject(SymBase) [function]
endmodule


module DELETE-OBJECT
     imports DELETE-OBJECT-SYNTAX
     imports C-CONFIGURATION
     imports BASIC-K
     imports LIST
     imports COMMON-IO-BUFFERED-SYNTAX

     rule deleteObjects(SetItem(Base::SymBase) Locals::Set)
          => deleteObject(Base) ~> deleteObjects(Locals)
          [structural]
     rule deleteObjects(.Set) => .K
          [structural]

     rule <k> deleteObject(Base:SymBase) => freeNativeObject(Base) ...</k>
          <mem> M::Map => M[Base <- undef] </mem>
          <buffer> L::List => filterBuffer(L, Base) </buffer>
          [structural]

     syntax List ::= filterBuffer(List, SymBase) [function]
     rule filterBuffer(.List, _) => .List
     rule filterBuffer(ListItem(bwrite(loc(Base::SymBase, _), _)) L::List, Base) => filterBuffer(L, Base)
     rule filterBuffer(ListItem(K:KItem) L::List, Base::SymBase) => ListItem(K) filterBuffer(L, Base) [owise]

endmodule
