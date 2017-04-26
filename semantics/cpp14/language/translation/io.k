module CPP-TRANSLATION-IO
     imports CPP-MEMORY-READING-SYNTAX

     imports CPP-MEMORY-WRITING-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports SETTINGS-SYNTAX


     rule <k> writeBytes(loc(Base::SymBase, Offset::Int), dataList(ListItem(V::Bits) L::List), T::CPPType)
              => writeBytes(loc(Base, Offset +Int 1), dataList(L), T)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, (M::Array => M[Offset <- V]))
          ...</mem>
          requires Offset <Int Len

     rule writeBytes(_, dataList(.List), _) => .K

     rule <k> instantiate(loc(B::SymBase, _) #as Loc::SymLoc, Tr::Trace, T::CPPType)
          => pre(instantiate(Loc, Tr, T), Tr, prvalType(T)) ... </k>
          <constexpr-symbase> CS::Set</constexpr-symbase>
          requires notBool B in CS

     rule <k> instantiate(loc(B::SymBase, _) #as Loc::SymLoc, Tr::Trace, T::CPPType)
          => read(Loc, Tr, T) ... </k>
          <constexpr-symbase>CS::Set</constexpr-symbase>
          requires B in CS

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
          requires Size >Int 0 andBool Offset in_keys(M)

     rule <k> readBytes-aux(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List, T::CPPType)
              => assertInBounds(Offset, Len)
              ~> readBytes-aux(loc(Base, Offset) +bytes -1, Size -Int 1, ListItem(getUninitializedBits(loc(Base, Offset), ObjT)) Aux, T) ...</k>
          <mem>...
               Base |-> object(ObjT::CPPType, Len::Int, M::Array => M[Offset <- getUninitializedBits(loc(Base, Offset), ObjT)])
          ...</mem>
          requires Size >Int 0 andBool notBool (Offset in_keys(M))

     syntax Bits ::= getUninitializedBits(SymLoc, CPPType) [function, klabel(getUninitializedBitsCpp)]
     rule getUninitializedBits(L::SymLoc, _) => piece(trap, cfg:bitsPerByte)
          requires notBool (isStaticDuration(L) orBool isThreadDuration(L))
     rule getUninitializedBits(L::SymLoc, _) => piece(0, cfg:bitsPerByte) [owise]

     syntax Error ::= "errorReadOutOfBounds"
     syntax K ::= assertInBounds(Int, Int) [klabel(cppAssertInBounds)]

     rule assertInBounds(Offset::Int, Len::Int)
          => assert(Offset <Int Len, errorReadOutOfBounds) [macro]

     rule (.K => DRAFTING("TIO1",
               "Reading outside the bounds of an object."))
          ~> errorReadOutOfBounds
          [structural]

endmodule
