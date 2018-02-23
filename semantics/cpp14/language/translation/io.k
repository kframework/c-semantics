module CPP-TRANSLATION-IO
     imports CPP-MEMORY-WRITING-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> initBytes(loc(Base::SymBase, Offset::Int), ListItem(V::Bits) L::List)
              => initBytes(loc(Base, Offset +Int 1), L)
          ...</k>
          <mem>...
               Base |-> object(_, Len::Int, (M::Array => M[Offset <- V]))
          ...</mem>
          requires Offset <Int Len

     rule initBytes(_, .List) => .K

     rule instantiate(Loc::SymLoc, Tr::Trace, T::CPPType)
          => pre(instantiate(Loc, Tr, T), Tr, prvalType(T))

endmodule
