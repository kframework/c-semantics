module CPP-MEMORY-WRITING-SYNTAX
     imports BASIC-K
     imports STRING-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= write(SymLoc, K, CPPType) [klabel(writeCpp)]
                    | init(SymLoc, K, CPPType) [klabel(initCpp)]
                    | writeBytes(SymLoc, List, CPPType) [klabel(writeBytesCpp)]
                    | initBytes(SymLoc, List) [klabel(initBytesCpp)]

     syntax List ::= splitBytes(PRVal) [function, klabel(splitBytesCpp)]

endmodule

module CPP-MEMORY-WRITING
     imports CPP-MEMORY-WRITING-SYNTAX
     imports STRING
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     context write(_, HOLE:K, _)

     rule write(Loc::SymLoc, V:PRVal, T::CPPType)
          => writeBytes(stripProv(Loc), splitBytes(V), T)

     context init(_, HOLE:K, _)

     rule init(Loc::SymLoc, V:PRVal, _)
          => initBytes(stripProv(Loc), splitBytes(V))

     rule splitBytes(prv(V:Encodable, _, T::CPPType))
          => splitToBytes(encode(V, 0, bitSizeofType(T)))

endmodule
