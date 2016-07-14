module CPP-TRANSLATION-IO
     imports CPP-MEMORY-WRITING-SYNTAX
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-CONFIGURATION

     rule <k> writeBytes(loc(Base::SymBase, Offset::Int), dataList(ListItem(V::Bits) L::List), T::CPPType)
              => writeBytes(loc(Base, Offset +Int 1), dataList(L), T)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, (M::Array => M[Offset <- V]))
          ...</mem>
          requires Offset <Int Len

     rule writeBytes(_, dataList(.List), _) => .K

endmodule
