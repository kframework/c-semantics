module CPP-SYMLOC-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax SymLoc ::= lnew(SymBase, CPPType) [function, klabel(lnewCpp)]
     syntax Bool ::= ifFromArrayInBounds(SymLoc, CPPType, Int) [function, klabel(ifFromArrayInBoundsCPP)]

endmodule

module CPP-SYMLOC
     imports CPP-SYMLOC-SYNTAX
     imports BOOL
     imports INT
     imports CPP-BITSIZE-SYNTAX

     rule lnew(Base::SymBase, T::CPPType)
          => loc(Base, 0, .Set)

     syntax Bool ::= #ifFromArrayInBounds(K, Int) [function, klabel(#ifFromArrayInBoundsCPP)]

     rule ifFromArrayInBounds(Loc::SymLoc, T::CPPType, I::Int) => #ifFromArrayInBounds(getProv(Loc, #klabel(`fromArray`)), byteSizeofType(innerType(T)) *Int I)
     rule #ifFromArrayInBounds(fromArray(Offset::Int, Len::Int), NewOffset::Int) => Offset +Int NewOffset >=Int 0 andBool Offset +Int NewOffset <=Int Len
     rule #ifFromArrayInBounds(.K, _) => true

endmodule
