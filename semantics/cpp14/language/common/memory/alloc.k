module CPP-MEMORY-ALLOC-SYNTAX
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax KItem ::= allocObject(SymBase, CPPType, Int) [klabel(allocObjectCpp)]

endmodule

module CPP-MEMORY-ALLOC
     imports CPP-MEMORY-ALLOC-SYNTAX

     imports C-CONFIGURATION

     rule <k> allocObject(Base::SymBase, T::CPPType, Len::Int) => .K ...</k>
          <mem>...
               .Map => Base |-> object(T, Len, makeEmptyArray(Len))
          ...</mem>
          requires notBool isLinkerLoc(Base)

endmodule
