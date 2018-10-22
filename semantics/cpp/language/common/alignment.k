module CPP-ALIGNMENT-SYNTAX
     imports SET
     imports SYMLOC-SORTS
     imports CPP-TYPING-SORTS
     imports ALIGNMENT-SYNTAX

     syntax Int ::= getAlignas(CPPType, Set) [function, klabel(getAlignasCpp)]

     syntax Int ::= byteAlignofType(CPPType) [function, klabel(byteAlignofTypeCpp)]

endmodule

module CPP-ALIGNMENT
     imports C-CONFIGURATION
     imports BOOL
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule getAlignas(_, SetItem(Alignas(I::Int)) _) => I
     rule getAlignas(T::CPPType, _) => byteAlignofType(T) [owise]

     syntax Int ::= byteAlignofType(CPPSimpleType) [klabel(byteAlignofSimpleTypeCpp), function]
     rule byteAlignofType(t(_, _, T::CPPSimpleType)) => byteAlignofType(T)

     rule byteAlignofType(classType(C::Class)) => byteAlignofClass(getClassInfo(C))
     syntax Int ::= byteAlignofClass(ClassInfo) [function]
     rule byteAlignofClass(<class>... <align> A::Int </align> ...</class>)
          => A
     rule byteAlignofClass(#incomplete) => 0

     rule byteAlignofType(bitfieldType(T::CPPSimpleType, _) => T)
     rule byteAlignofType(pointerType(_)) => cfg:alignofPointer
     rule byteAlignofType(lvRefType(_)) => cfg:alignofReference
     rule byteAlignofType(rvRefType(_)) => cfg:alignofReference
     rule byteAlignofType(nullptr_t) => cfg:alignofNullPtrT
     rule byteAlignofType(memberPointerType(_, T:CPPFunctionType)) => cfg:memberFunctionPtrAlign
     rule byteAlignofType(memberPointerType(_, T::CPPType)) => cfg:memberDataPtrAlign
          requires notBool isCPPFunctionType(T)
     rule byteAlignofType(arrayType(t(_, _, T::CPPSimpleType), _) => T)
     rule byteAlignofType(incompleteArrayType(t(_, _, T::CPPSimpleType)) => T)
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
     rule byteAlignofType(oversized) => cfg:alignofOversizedInt
     rule byteAlignofType(unsigned-long-long) => cfg:alignofLongLongInt
     rule byteAlignofType(unsigned-oversized) => cfg:alignofOversizedInt
     rule byteAlignofType(float) => cfg:alignofFloat
     rule byteAlignofType(double) => cfg:alignofDouble
     rule byteAlignofType(long-double) => cfg:alignofLongDouble
     rule byteAlignofType(T:CPPSimpleWideCharType) => byteAlignofType(underlyingType(T))
     rule byteAlignofType(T:CPPSimpleEnumType) => byteAlignofType(underlyingType(T))
     rule byteAlignofType(functionType(...)) => 0
     rule byteAlignofType(no-type) => cfg:alignofMalloc

endmodule
