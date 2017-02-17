module CPP-ALIGNMENT-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-TYPING-SORTS

     syntax Int ::= getAlign(SymLoc) [function, klabel(getAlignCpp)]
                  | getAlignof(CPPType) [function]

     syntax Int ::= byteAlignofType(CPPType) [function, klabel(byteAlignofTypeCpp)]

endmodule

module CPP-ALIGNMENT
     imports C-CONFIGURATION
     imports BOOL
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax Int ::= byteAlignofType(CPPSimpleType) [klabel(byteAlignofSimpleTypeCpp), function]
     rule byteAlignofType(T:CPPClassType) => byteAlignofClass(getClassInfo(T))
     rule byteAlignofType(t(_, _, T::CPPSimpleType)) => byteAlignofType(T) [owise]

     syntax Int ::= byteAlignofClass(ClassInfo) [function]
     rule byteAlignofClass(<class>... <max-align> A::Int </max-align> ...</class>)
          => A

     rule byteAlignofType(pointerType(_)) => cfg:alignofPointer
     rule byteAlignofType(memberPointerType(_, T:CPPFunctionType)) => cfg:memberFunctionPtrAlign
     rule byteAlignofType(memberPointerType(_, T::CPPType)) => cfg:memberDataPtrAlign
          requires notBool isCPPFunctionType(T)
     rule byteAlignofType(arrayType(t(_, _, T::CPPSimpleType), _) => T)
     rule byteAlignofType(bool) => cfg:alignofBool
     rule byteAlignofType(signed-char) => cfg:alignofSignedChar
     rule byteAlignofType(unsigned-char) => cfg:alignofSignedChar
     rule byteAlignofType(char) => cfg:alignofSignedChar
     rule byteAlignofType(short) => cfg:alignofShortInt
     rule byteAlignofType(unsigned-short) => cfg:alignofShortInt
     rule byteAlignofType(int) => cfg:alignofInt
     rule byteAlignofType(unsigned) => cfg:alignofInt
     rule byteAlignofType(long) => cfg:alignofLongInt
     rule byteAlignofType(unsigned-long) => cfg:alignofLongInt
     rule byteAlignofType(long-long) => cfg:alignofLongLongInt
     rule byteAlignofType(unsigned-long-long) => cfg:alignofLongLongInt
     rule byteAlignofType(float) => cfg:alignofFloat
     rule byteAlignofType(double) => cfg:alignofDouble
     rule byteAlignofType(long-double) => cfg:alignofLongDouble
     rule byteAlignofType(T:CPPSimpleWideCharType) => byteAlignofType(underlyingType(T))
endmodule
