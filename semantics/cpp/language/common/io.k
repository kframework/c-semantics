module CPP-COMMON-IO-SYNTAX
     imports INT
     imports SYMLOC-SORTS

     syntax CPPType

     syntax KItem ::= assertInBounds(Int, Int) [klabel(cppAssertInBounds)]

     syntax Bits ::= getUninitializedBits(SymLoc, CPPType) [function, klabel(getUninitializedBitsCpp)]

endmodule

module CPP-COMMON-IO
     imports CPP-COMMON-IO-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports SETTINGS-SYNTAX
     imports BITS-SYNTAX
     imports SYMLOC-SYNTAX

     rule getUninitializedBits(L::SymLoc, _) => piece(trap, cfg:bitsPerByte)
          requires notBool (isStaticDuration(L) orBool isThreadDuration(L))

     rule getUninitializedBits(L::SymLoc, _) => piece(0, cfg:bitsPerByte) [owise]

     syntax Error ::= "errorReadOutOfBounds"

     rule assertInBounds(Offset::Int, Len::Int)
          => assert(Offset <Int Len, errorReadOutOfBounds)

     rule (.K => DRAFTING("EIO1",
               "Reading outside the bounds of an object."))
          ~> errorReadOutOfBounds
          [structural]

endmodule
