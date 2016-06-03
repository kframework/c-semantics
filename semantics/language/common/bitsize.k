module C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax Int ::= bitSizeofType(UType) [function]
     syntax Int ::= bitSizeofType(Type) [function]
     syntax Int ::= bitSizeofType(SimpleType) [function, klabel(bitSizeofSimpleType)]
     syntax Int ::= bitSizeofType(SimpleUType) [function, klabel(bitSizeofSimpleType)]

     syntax Int ::= byteSizeofType(UType) [function]
     syntax Int ::= byteSizeofType(Type) [function]

     syntax Int ::= bitSizeofStruct(FieldInfo) [function]
     syntax Int ::= bitSizeofUnion(FieldInfo) [function]

     syntax KItem ::= sizeof(K) [strict]

     syntax Int ::= maxByteSizeofList(List) [function]
endmodule

module C-BITSIZE
     imports C-BITSIZE-SYNTAX

     imports C-BITS-SYNTAX
     imports C-ENV-SYNTAX
     imports C-CONVERSION-SYNTAX

     imports C-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports COMPAT-SYNTAX

     rule sizeof(V:KResult => type(V))
          requires notBool isType(V)
          [structural]
     rule sizeof(T:Type => stabilizeVLA(T))
          requires isVariableLengthArrayType(T)
          [structural]
     rule sizeof(T:Type)
          => Cast(t(noQuals, SetItem(IntegerConstant), cfg:sizeut),
               tv(byteSizeofType(T), ut(SetItem(IntegerConstant), cfg:largestUnsigned)))
          requires notBool isVariableLengthArrayType(T)
          [structural]

     rule bitSizeofType(t(_, _, T::SimpleType)) => bitSizeofType(T)
     rule bitSizeofType(ut(_, T::SimpleUType)) => bitSizeofType(T)

     rule byteSizeofType(t(_, _, T::SimpleType)) => (bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte
     rule byteSizeofType(ut(_, T::SimpleUType)) => (bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte

     syntax Int ::= numBytes(SimpleType) [function]
     rule numBytes(bool) => cfg:sizeofBool
     rule numBytes(signed-char) => cfg:sizeofSignedChar
     rule numBytes(short-int) => cfg:sizeofShortInt
     rule numBytes(int) => cfg:sizeofInt
     rule numBytes(long-int) => cfg:sizeofLongInt
     rule numBytes(long-long-int) => cfg:sizeofLongLongInt

     rule numBytes(float) => cfg:sizeofFloat
     rule numBytes(double) => cfg:sizeofDouble
     rule numBytes(long-double) => cfg:sizeofLongDouble

     rule numBytes(unsigned-char) => numBytes(signed-char)
     rule numBytes(unsigned-short-int) => numBytes(short-int)
     rule numBytes(unsigned-int) => numBytes(int)
     rule numBytes(unsigned-long-int) => numBytes(long-int)
     rule numBytes(unsigned-long-long-int) => numBytes(long-long-int)
     rule numBytes(enumType(_)) => numBytes(cfg:enumAlias)
     rule numBytes(_) => 0 [owise]

     syntax Int ::= "maxByteSizeofList'" "(" Int "," List ")" [function]
     rule maxByteSizeofList(L:List) => maxByteSizeofList'(0, L)
     rule maxByteSizeofList'(Sz:Int, ListItem(T:Type) LL:List)
          => maxByteSizeofList'(maxInt(Sz, byteSizeofType(utype(T))), LL)
     rule maxByteSizeofList'(Sz:Int, ListItem(typedDeclaration(T::Type, _)) LL:List)
          => maxByteSizeofList'(maxInt(Sz, byteSizeofType(utype(T))), LL)
     rule maxByteSizeofList'(Sz:Int, .List) => Sz

     rule bitSizeofType(no-type) => 0
     rule bitSizeofType(arrayUType(T::UType, N::Int)) => bitSizeofType(T) *Int N
     rule bitSizeofType(arrayType(T::Type, N::Int)) => bitSizeofType(T) *Int N
     rule bitSizeofType(flexibleArrayType(_)) => 0
     rule bitSizeofType(flexibleArrayUType(_)) => 0
     rule bitSizeofType(functionType(_, _)) => cfg:bitsPerByte
     rule bitSizeofType(pointerType(_)) => cfg:ptrsize *Int cfg:bitsPerByte
     rule bitSizeofType(bitfieldType(_, N::Int)) => N
     rule bitSizeofType(T::SimpleType) => numBytes(T) *Int cfg:bitsPerByte [owise]

     rule bitSizeofType(structType(S::StructId))
          => bitSizeofStruct(getFieldInfo(S))
     rule bitSizeofType(unionType(S::StructId))
          => bitSizeofUnion(getFieldInfo(S))

     rule bitSizeofStruct(fieldInfo(_, NBits:Int, _, _)) => NBits
     rule bitSizeofUnion(fieldInfo(_, NBits:Int, _, _)) => NBits

endmodule
