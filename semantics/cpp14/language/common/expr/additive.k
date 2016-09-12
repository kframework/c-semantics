module CPP-EXPR-ADDITIVE
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule prv(Loc::SymLoc, Tr::Trace, T:CPPPointerType) + prv(I::Int, Tr'::Trace, T':CPPIntegerType)
          => addToPointer(Loc, T, I, combine(Tr, Tr', #klabel(`_+__CPP-SYNTAX`)))
          requires isCompleteType(innerType(T)) andBool isObjectType(innerType(T))

     rule prv(I::Int, Tr::Trace, T':CPPIntegerType) + prv(Loc::SymLoc, Tr'::Trace, T:CPPPointerType)
          => addToPointer(Loc, T, I, combine(Tr, Tr', #klabel(`_+__CPP-SYNTAX`)))
          requires isCompleteType(innerType(T)) andBool isObjectType(innerType(T))

     syntax KItem ::= addToPointer(SymLoc, CPPType, Int, Trace) [klabel(addToPointerCPP)]
     rule addToPointer(Loc::SymLoc, T::CPPType, I::Int, Tr::Trace)
          => prv(newFromArray(Loc, T, I) +bytes (I *Int byteSizeofType(innerType(T))), Tr, T)
          requires ifFromArrayInBounds(Loc, T, I)

     rule (.K => UNDIAG("CEA1",
               "A pointer (or array subscript) outside the bounds of an object.",
               "5.7:4"))
          ~> addToPointer(Loc::SymLoc, T::CPPType, I::Int, _)
          requires notBool ifFromArrayInBounds(Loc, T, I)

     syntax SymLoc ::= newFromArray(SymLoc, CPPType, Int) [function, klabel(newFromArrayCpp)]
                     | #newFromArray(SymLoc, K, Int) [function, klabel(#newFromArrayCpp)]
     rule newFromArray(Loc::SymLoc, T::CPPType, I::Int) 
          => #newFromArray(Loc, getProv(Loc, #klabel(`fromArray`)), byteSizeofType(innerType(T)) *Int I)
     rule #newFromArray(Loc::SymLoc, fromArray(ArrOffset::Int, Len::Int), NewOffset::Int)
          => addProv(fromArray(ArrOffset +Int NewOffset, Len), stripProv(Loc, #klabel(`fromArray`)))
     rule #newFromArray(Loc::SymLoc, .K, _) => Loc
endmodule
