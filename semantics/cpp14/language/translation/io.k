module CPP-TRANSLATION-IO
     imports CPP-MEMORY-WRITING-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> writeBytes(loc(Base::SymBase, Offset::Int), dataList(ListItem(V::Bits) L::List), T::CPPType)
              => writeBytes(loc(Base, Offset +Int 1), dataList(L), T)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, (M::Array => M[Offset <- V]))
          ...</mem>
          requires Offset <Int Len

     rule writeBytes(_, dataList(.List), _) => .K

     rule instantiate(Loc::SymLoc, Tr::Trace, T::CPPType)
          => pre(instantiate(Loc, Tr, T), Tr, T)

endmodule
