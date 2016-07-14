module CPP-MEMORY-WRITING-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports SYMLOC-SYNTAX

     syntax KItem ::= write(SymLoc, PRVal, CPPType) [klabel(writeCpp)]
                    | writeBytes(SymLoc, DataList, CPPType) [klabel(writeBytesCpp)]
     syntax DataList ::= splitBytes(PRVal) [function, klabel(splitBytesCpp)]

endmodule

module CPP-MEMORY-WRITING
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports MEMORY-SYNTAX

     rule write(Loc::SymLoc, V::PRVal, T::CPPType)
          => writeBytes(stripProv(Loc), splitBytes(V), T)

     rule splitBytes(prv(Loc:SymLoc, T::CPPType))
          => splitPointerBytes(Loc, byteSizeofType(T))

endmodule
