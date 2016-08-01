module CPP-EXECUTION-IO
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports BOOL
     imports INT
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-CONFIGURATION
     imports C-IO-BUFFERED-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> writeBytes(Loc::SymLoc, dataList(Bytes::List), T::CPPType)
              => checkWrite(Loc, T)
              ~> setModified(Loc, T)
              ~> writeBytes(Loc, Bytes)
          ...</k>
          <initializing> false </initializing>

     rule <k> writeBytes(Loc::SymLoc, dataList(Bytes::List), T::CPPType)
              => writeBytes(Loc, Bytes)
          ...</k>
          <initializing> true </initializing>

     syntax KItem ::= checkWrite(SymLoc, CPPType) [klabel(cppCheckWrite)]
     rule <k> checkWrite(loc(Base::SymBase, Offset::Int), T::CPPType) => .K ...</k>
          <locs-written>
               Locs::Set (.Set => SetItem(loc(Base, Offset)))
          </locs-written>
          requires notBool loc(Base, Offset) in Locs
     rule <k> (.K => UNDIAG("PEIO1",
               "Unsequenced side effect on scalar object with side effect of same object.",
               "1.9:15"))
              ~> checkWrite(Loc::SymLoc, _)
          ...</k>
          <locs-written> Locs::Set </locs-written>
          requires Loc in Locs

     syntax KItem ::= setModified(SymLoc, CPPType) [klabel(cppSetModified)]
     rule <k> setModified(Loc::SymLoc, T::CPPType)
              => setModified(Loc, byteSizeofType(T), .K, Modified)
          ...</k>
          <active-blocks> Modified::Map </active-blocks>

     syntax KItem ::= "readBytes-aux" "(" SymLoc "," Int "," List "," CPPType ")"
     syntax K ::= cppAssertSeq(SymLoc, Set)
     syntax Error ::= "errorUnseqEffects"

     rule cppAssertSeq(Loc::SymLoc, Locs::Set)
          => assert(notBool (Loc in Locs), errorUnseqEffects) [macro]

     rule readBytes(Loc::SymLoc, Size::Int, T::CPPType)
          => readBytes-aux(Loc +bytes (Size -Int 1), Size, .List, T)

     rule readBytes-aux(_, 0, Aux::List, _) => dataList(Aux)

     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::CPPType)
              => cppAssertSeq(loc(Base, Offset), Locs)
              ~> readBytes-aux(loc(Base, Offset) +bytes -1, Size -Int 1, ListItem(M[Offset]) Aux, T)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, M::Array)
          ...</mem>
          <locs-written> Locs::Set </locs-written>
          <buffer> .List </buffer>
          requires Size >Int 0 andBool Offset in_keys(M)
     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::CPPType)
              => cppAssertSeq(loc(Base, Offset), Locs)
              ~> readBytes-aux(loc(Base, Offset) +bytes -1, Size -Int 1, ListItem(M[Offset]) Aux, T)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, M::Array)
          ...</mem>
          <locs-written> Locs::Set </locs-written>
          <buffer> Mem::List </buffer>
          requires Size >Int 0 andBool notBool (loc(Base, Offset) in locations(Mem)) andBool Offset in_keys(M)

     rule (.K => UNDIAG("PEIO2",
           "Unsequenced side effect on scalar object with value computation of same object.",
           "1.9:15"))
          ~> errorUnseqEffects

     rule getQualsAtOffset(ListItem(t(Q::Quals, _, _)) Ts::List)
          => Q +Quals getQualsAtOffset(Ts)

endmodule
