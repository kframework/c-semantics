module CPP-MEMORY-READING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= read(SymLoc, CPPType) [klabel(readCpp)]
                    | readBytes(SymLoc, Int, CPPType) [klabel(readBytesCpp)]
     syntax Expr ::= concretize(K, CPPType) [klabel(concretizeCpp), strict(1)]
     syntax CPPValue ::= joinBytes(List) [function]
     syntax PRVal ::= interpret(PRVal) [function, klabel(interpretCpp)]

endmodule

module CPP-MEMORY-READING
     imports CPP-MEMORY-READING-SYNTAX
     imports INT
     imports MEMORY-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule read(Loc::SymLoc, T::CPPType)
          => concretize(readBytes(stripProv(Loc), byteSizeofType(T), T), utype(T))

     rule concretize(dataList(L::List), T::CPPType)
          => interpret(prv(joinBytes(L), T))

     rule joinBytes(ListItem(piece(encodedValue(Loc:SymLoc, Begin::Int, End::Int), Len::Int)) L::List)
          => joinPointerBytes(L, encodedValue(Loc, Begin, End))
          requires Len ==Int cfg:bitsPerByte
     rule joinBytes(ListItem(piece(I:Int, Len::Int)) L::List)
          => joinIntegerBytes(L, piece(I, Len))
 
     rule interpret(prv(L:SymLoc, T:CPPPointerType)) => prv(L, T)
     rule interpret(prv(I:Int, T:CPPIntegerType))
          => #if max(T) >=Int I #then prv(I, T) #else interpret(prv(I -Int (1 <<Int absInt(bitSizeofType(T))), T)) #fi

endmodule
