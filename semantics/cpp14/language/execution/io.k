module CPP-EXECUTION-IO
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-COMMON-IO-SYNTAX

     rule <k> writeBytes(Loc::SymLoc, dataList(Bytes::List), T::CPPType)
              => checkWrite(Loc, T)
              ~> writeBytes(Loc, Bytes)
          ...</k>
          <initializing> false </initializing>
          requires notBool isLinkerLoc(Loc)

     rule <k> writeBytes(Loc::SymLoc, dataList(Bytes::List), T::CPPType)
              => writeBytes(Loc, Bytes)
          ...</k>
          <initializing> true </initializing>
          requires notBool isLinkerLoc(Loc)

     rule <k> writeBytes(loc((Base::SymBase => Base'), _), _, _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>

     syntax KItem ::= checkWrite(SymLoc, CPPType) [klabel(cppCheckWrite)]
     rule checkWrite(loc(Base::SymBase, Offset::Int), T::CPPType) => .K

     syntax KItem ::= "readBytes-aux" "(" SymLoc "," Int "," List "," CPPType ")"

     rule readBytes(Loc::SymLoc, Size::Int, T::CPPType)
          => readBytes-aux(Loc +bytes (Size -Int 1), Size, .List, T)
          requires notBool isLinkerLoc(Loc)

     rule <k> readBytes(loc((Base::SymBase => Base'), _), _, _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>

     rule readBytes-aux(_, 0, Aux::List, _) => dataList(Aux)

     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::CPPType)
              => assertInBounds(Offset, Len)
              ~> readBytes-aux(loc(Base, Offset) +bytes -1, Size -Int 1, ListItem(M[Offset]) Aux, T)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, M::Array)
          ...</mem>
          <locs-written> Locs::Set </locs-written>
          <buffer> .List </buffer>
          requires Size >Int 0 andBool Offset in_keys(M)

     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::CPPType)
              => assertInBounds(Offset, Len)
              ~> readBytes-aux(loc(Base, Offset) +bytes -1, Size -Int 1, ListItem(M[Offset]) Aux, T)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, M::Array)
          ...</mem>
          <locs-written> Locs::Set </locs-written>
          <buffer> Mem::List </buffer>
          requires Size >Int 0 andBool notBool (loc(Base, Offset) in locations(Mem)) andBool Offset in_keys(M)

     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::CPPType)
              => assertInBounds(Offset, Len)
              ~> readBytes-aux(loc(Base, Offset) +bytes -1, Size -Int 1, ListItem(getUninitializedBits(loc(Base, Offset), ObjT)) Aux, T) ...</k>
          <mem>...
               Base |-> object(ObjT::CPPType, Len::Int, M::Array => M[Offset <- getUninitializedBits(loc(Base, Offset), ObjT)])
          ...</mem>
          <locs-written> Locs::Set </locs-written>
          <buffer> Mem::List </buffer>
          requires Size >Int 0 andBool notBool (loc(Base, Offset) in locations(Mem)) andBool notBool (Offset in_keys(M))

endmodule
