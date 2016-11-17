module CPP-MEMORY-READING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= read(SymLoc, Trace, CPPType) [klabel(readCpp)]
                    | readBytes(SymLoc, Int, CPPType) [klabel(readBytesCpp)]
     syntax Expr ::= concretize(K, Trace, CPPType) [klabel(concretizeCpp), strict(1)]
     syntax PRVal ::= interpret(PRVal) [function, klabel(interpretCpp)]

endmodule

module CPP-MEMORY-READING
     imports CPP-MEMORY-READING-SYNTAX
     imports INT
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule read(Loc::SymLoc, Tr::Trace, T::CPPType)
          => concretize(readBytes(stripProv(Loc), byteSizeofType(T), T), Tr, utype(T))

     rule concretize(dataList(L::List), Tr::Trace, T::CPPType)
          => interpret(prv(joinBytes(L), Tr, prvalType(T)))

     rule interpret(prv(encodedValue(L:SymLoc, 0, To::Int), Tr::Trace, T:CPPPointerType)) => prv(L, Tr, T)
          requires To ==Int (cfg:ptrsize *Int cfg:bitsPerByte)
     rule interpret(prv(encodedValue(F:Float, 0, To::Int), Tr::Trace, T:CPPFloatingType)) => prv(F, Tr, T)
          requires isFullFloat(F, To)
     rule interpret(prv(I:Int, Tr::Trace, T:CPPIntegerType))
          => #if max(T) >=Int I #then prv(I, Tr, T) #else interpret(prv(I -Int (1 <<Int absInt(bitSizeofType(T))), Tr, T)) #fi
     rule interpret(prv(encodedValue(nullptrVal, 0, To::Int), Tr::Trace, T:CPPNullPtrTType)) => prv(nullptrVal, Tr, T)
          requires To ==Int (cfg:ptrsize *Int cfg:bitsPerByte)
     rule interpret(prv(encodedValue(NullMemberFunctionPointer, 0, To::Int), Tr::Trace, T:CPPMemberFunctionPointerType)) => prv(NullMemberFunctionPointer, Tr, T)
          requires To ==Int (cfg:memberFunctionPtrSize *Int cfg:bitsPerByte)
     rule interpret(prv(encodedValue(NullMemberPointer, 0, To::Int), Tr::Trace, T:CPPMemberPointerType)) => prv(NullMemberPointer, Tr, T)
          requires notBool(isCPPMemberFunctionPointerType(T))
               andBool To ==Int (cfg:memberDataPtrSize *Int cfg:bitsPerByte)

     rule interpret(prv(0, Tr::Trace, T:CPPNullPtrTType)) => prv(nullptrVal, Tr, T)
     rule interpret(prv(0, Tr::Trace, T:CPPPointerType)) => prv(NullPointer, Tr, T)

     syntax PRVal ::= interpretEnum(PRVal, CPPEnumType)
     rule interpret(prv(I:Int, Tr::Trace, T:CPPEnumType)) => interpretEnum(interpret(prv(I, Tr, underlyingType(T))), T)
     rule interpretEnum(prv(I:Int, Tr::Trace, T:CPPIntegerType), E:CPPEnumType) => prv(I, Tr, E)

endmodule
