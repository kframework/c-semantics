module CPP-MEMORY-READING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= read(SymLoc, Trace, CPPType) [klabel(readCpp)]
                    | readBytes(SymLoc, Int, CPPType) [klabel(readBytesCpp)]
     syntax Expr ::= concretize(K, Trace, CPPType) [klabel(concretizeCpp), strict(1)]
     syntax CPPValue ::= joinBytes(List) [function]
     syntax PRVal ::= interpret(PRVal) [function, klabel(interpretCpp)]

endmodule

module CPP-MEMORY-READING
     imports CPP-MEMORY-READING-SYNTAX
     imports INT
     imports MEMORY-SYNTAX
     imports SETTINGS-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule read(Loc::SymLoc, Tr::Trace, T::CPPType)
          => concretize(readBytes(stripProv(Loc), byteSizeofType(T), T), Tr, utype(T))

     rule concretize(dataList(L::List), Tr::Trace, T::CPPType)
          => interpret(prv(joinBytes(L), Tr, T))

     rule joinBytes(ListItem(piece(encodedValue(Loc:SymLoc, Begin::Int, End::Int), Len::Int)) L::List)
          => joinPointerBytes(L, encodedValue(Loc, Begin, End))
          requires Len ==Int cfg:bitsPerByte
     rule joinBytes(ListItem(piece(I:Int, Len::Int)) L::List)
          => joinIntegerBytes(L, piece(I, Len))
 
     rule interpret(prv(L:SymLoc, Tr::Trace, T:CPPPointerType)) => prv(L, Tr, T)
     rule interpret(prv(I:Int, Tr::Trace, T:CPPIntegerType))
          => #if max(T) >=Int I #then prv(I, Tr, T) #else interpret(prv(I -Int (1 <<Int absInt(bitSizeofType(T))), Tr, T)) #fi

endmodule
