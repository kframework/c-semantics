module C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax Int ::= bitSizeofType(Type) [function]
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
          => Cast(t(SetItem(IntegerConstant), cfg:sizeut),
               tv(byteSizeofType(T), t(SetItem(IntegerConstant), cfg:largestUnsigned)))
          requires notBool isVariableLengthArrayType(T)
          [structural]

     rule byteSizeofType(T:Type)
          => bitsToBytes(bitSizeofType(T))

     syntax Int ::= numBytes(Type) [function]
     rule numBytes(t(_, bool)) => cfg:sizeofBool
     rule numBytes(t(_, signed-char)) => cfg:sizeofSignedChar
     rule numBytes(t(_, short-int)) => cfg:sizeofShortInt
     rule numBytes(t(_, int)) => cfg:sizeofInt
     rule numBytes(t(_, long-int)) => cfg:sizeofLongInt
     rule numBytes(t(_, long-long-int)) => cfg:sizeofLongLongInt

     rule numBytes(t(_, float)) => cfg:sizeofFloat
     rule numBytes(t(_, double)) => cfg:sizeofDouble
     rule numBytes(t(_, long-double)) => cfg:sizeofLongDouble

     rule numBytes(t(_, unsigned-char)) => numBytes(t(.Set, signed-char))
     rule numBytes(t(_, unsigned-short-int)) => numBytes(t(.Set, short-int))
     rule numBytes(t(_, unsigned-int)) => numBytes(t(.Set, int))
     rule numBytes(t(_, unsigned-long-int)) => numBytes(t(.Set, long-int))
     rule numBytes(t(_, unsigned-long-long-int))
          => numBytes(t(.Set, long-long-int))
     rule numBytes(t(S:Set, enumType(_))) => numBytes(t(S, cfg:enumAlias))
     rule numBytes(_) => 0 [owise]

     syntax Int ::= byteSizeofList(List) [function]
     syntax Int ::= "byteSizeofList'" "(" Int "," List ")" [function]

     rule byteSizeofList(L:List) => byteSizeofList'(0, L)
     rule byteSizeofList'(Sz:Int, ListItem(T:Type) LL:List)
          => byteSizeofList'((Sz +Int byteSizeofType(T)), LL)
     rule byteSizeofList'(Sz:Int, .List) => Sz

     syntax Int ::= "maxByteSizeofList'" "(" Int "," List ")" [function]
     rule maxByteSizeofList(L:List) => maxByteSizeofList'(0, L)
     rule maxByteSizeofList'(Sz:Int, ListItem(T:Type) LL:List)
          => maxByteSizeofList'(maxInt(Sz, byteSizeofType(T)), LL)
     rule maxByteSizeofList'(Sz:Int, .List) => Sz

     rule bitSizeofType(t(_, no-type))
          => 0
     rule bitSizeofType(t(_, arrayType(T:Type, N:Int)))
          => bitSizeofType(T) *Int N
     rule bitSizeofType(t(_, flexibleArrayType(_)))
          => 0
     rule bitSizeofType(t(_, functionType(_, _)))
          => cfg:bitsPerByte
     rule bitSizeofType(t(_, pointerType(_)))
          => cfg:ptrsize *Int cfg:bitsPerByte
     rule bitSizeofType(t(_, bitfieldType(_, N:Int)))
          => N
     rule bitSizeofType(T:BasicType) => numBytes(T) *Int cfg:bitsPerByte
          requires notBool isTypedDeclaration(T)
               andBool notBool isBitfieldType(T)
     rule bitSizeofType(typedDeclaration(T:Type, _))
          => bitSizeofType(T)

     rule bitSizeofType(t(_, structType(S:StructId)))
          => bitSizeofStruct(getFieldInfo(S))
     rule bitSizeofType(t(_, unionType(S:StructId)))
          => bitSizeofUnion(getFieldInfo(S))

     rule bitSizeofStruct(fieldInfo(_, NBits:Int, _, _))
          => NBits
     rule bitSizeofUnion(fieldInfo(_, NBits:Int, _, _))
          => NBits

     syntax Int ::= bitsToBytes(Int) [function]
     rule bitsToBytes(N:Int) => (absInt(N) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte

endmodule
