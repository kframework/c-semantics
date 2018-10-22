module CPP-MEMORY-ALLOC-SYNTAX
     imports INT-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= allocObject(SymBase, CPPType, Int) [klabel(allocObjectCpp)]

endmodule

module CPP-MEMORY-ALLOC
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX

     rule <k> allocObject(Base:DirectBase, T::CPPType, Len::Int) => .K ...</k>
          <mem>...
               .Map => Base |-> object(T, Len, makeEmptyArray(Len))
          ...</mem>

endmodule
