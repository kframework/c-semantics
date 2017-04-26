module CPP-COMMON-IO-SYNTAX
     imports INT
     imports SYMLOC-SYNTAX

     syntax CPPType
     syntax K ::= assertInBounds(Int, Int) [klabel(cppAssertInBounds)]
     syntax Bits ::= getUninitializedBits(SymLoc, CPPType) [function, klabel(getUninitializedBitsCpp)]

endmodule

module CPP-COMMON-IO
     imports CPP-COMMON-IO-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports SETTINGS-SYNTAX
     imports BITS-SYNTAX

     rule getUninitializedBits(L::SymLoc, _) => piece(trap, cfg:bitsPerByte)
          requires notBool (isStaticDuration(L) orBool isThreadDuration(L))
     rule getUninitializedBits(L::SymLoc, _) => piece(0, cfg:bitsPerByte) [owise]

     syntax Error ::= "errorReadOutOfBounds"

     rule assertInBounds(Offset::Int, Len::Int)
          => assert(Offset <Int Len, errorReadOutOfBounds) [macro]

     rule (.K => DRAFTING("TIO1",
               "Reading outside the bounds of an object."))
          ~> errorReadOutOfBounds
          [structural]

endmodule
