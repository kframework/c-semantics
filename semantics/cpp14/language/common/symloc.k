module CPP-SYMLOC-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax SymLoc ::= lnew(SymBase, CPPType) [function, klabel(lnewCpp)]

endmodule

module CPP-SYMLOC
     imports CPP-SYMLOC-SYNTAX

     rule lnew(Base::SymBase, T::CPPType)
          => loc(Base, 0, .Set)

endmodule
