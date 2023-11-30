module CPP-TRANSLATION-IO
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports C-CONFIGURATION
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX // Translation()
     imports CPP-TYPING-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-COMMON-IO-SYNTAX
     imports COMMON-IO-BUFFERED-SYNTAX
     imports DELETE-OBJECT-SYNTAX
     imports SYMLOC-SYNTAX

     rule freeNativeObject(_::SymBase) => .K

     rule writeNativeByte(_::SymLoc, _::K) => .List


     rule <k> initBytes(loc(Base::SymBase, Offset::Int), ListItem(V::Bits) L::List)
              => initBytes(loc(Base, Offset +Int 1), L)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, (M::Array => M[Offset <- V]))
          ...</mem>
          requires Translation() andBool Offset <Int Len

     rule initBytes(_, .List) => .K

     rule <k> instantiate(Loc::SymLoc, Tr::Trace, T::CPPType)
          => pre(instantiate(Loc, Tr, T), Tr, prvalType(T)) ... </k>
          <constexpr-symbase> CS::Set</constexpr-symbase>
          requires Translation() andBool notBool base(Loc) in CS

     rule <k> instantiate(Loc::SymLoc, Tr::Trace, T::CPPType)
          => read(Loc, Tr, T) ... </k>
          <constexpr-symbase>CS::Set</constexpr-symbase>
          requires Translation() andBool base(Loc) in CS

     syntax KItem ::= "readBytes-aux" "(" SymLoc "," Int "," List "," CPPType ")"

     rule readBytes(Loc::SymLoc, Size::Int, T::CPPType)
          => readBytes-aux(Loc +bytes (Size -Int 1), Size, .List, T)
          requires Translation() andBool notBool isLinkerLoc(Loc)

     rule <k> readBytes(loc((Base::SymBase => Base'), _), _, _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>
          requires Translation()

     rule readBytes-aux(_, 0, Aux::List, _) => dataList(Aux)
          requires Translation()

     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::CPPType)
              => assertInBounds(Offset, Len)
              ~> readBytes-aux(loc(Base, Offset) +bytes -1, Size -Int 1, ListItem(M[Offset]) Aux, T)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, M::Array)
          ...</mem>
          requires Translation() andBool Size >Int 0 andBool Offset in_keys(M)

     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::CPPType)
              => assertInBounds(Offset, Len)
              ~> readBytes-aux(loc(Base, Offset) +bytes -1, Size -Int 1, ListItem(getUninitializedBits(loc(Base, Offset), ObjT)) Aux, T) ...</k>
          <mem>...
               Base |-> object(ObjT::CPPType, Len::Int, M::Array => M[Offset <- getUninitializedBits(loc(Base, Offset), ObjT)])
          ...</mem>
          requires Translation() andBool Size >Int 0 andBool notBool (Offset in_keys(M))

endmodule
