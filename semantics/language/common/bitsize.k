module C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax Int ::= bitSizeofType(UType) [function]
     syntax Int ::= bitSizeofType(Type) [function]

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

     rule bitSizeofType(T:Type) => bitSizeofType(utype(T))

     rule byteSizeofType(T:Type) => byteSizeofType(utype(T))
     rule byteSizeofType(T:UType) => bitsToBytes(bitSizeofType(T))

     syntax Int ::= numBytes(UType) [function]
     rule numBytes(ut(_, bool)) => cfg:sizeofBool
     rule numBytes(ut(_, signed-char)) => cfg:sizeofSignedChar
     rule numBytes(ut(_, short-int)) => cfg:sizeofShortInt
     rule numBytes(ut(_, int)) => cfg:sizeofInt
     rule numBytes(ut(_, long-int)) => cfg:sizeofLongInt
     rule numBytes(ut(_, long-long-int)) => cfg:sizeofLongLongInt

     rule numBytes(ut(_, float)) => cfg:sizeofFloat
     rule numBytes(ut(_, double)) => cfg:sizeofDouble
     rule numBytes(ut(_, long-double)) => cfg:sizeofLongDouble

     rule numBytes(ut(_, unsigned-char)) => numBytes(utype(signed-char))
     rule numBytes(ut(_, unsigned-short-int)) => numBytes(utype(short-int))
     rule numBytes(ut(_, unsigned-int)) => numBytes(utype(int))
     rule numBytes(ut(_, unsigned-long-int)) => numBytes(utype(long-int))
     rule numBytes(ut(_, unsigned-long-long-int)) => numBytes(utype(long-long-int))
     rule numBytes(ut(Mods::Set, enumType(_))) => numBytes(ut(Mods, cfg:enumAlias))
     rule numBytes(_) => 0 [owise]

     syntax Int ::= byteSizeofList(List) [function]
     syntax Int ::= "byteSizeofList'" "(" Int "," List ")" [function]

     rule byteSizeofList(L:List) => byteSizeofList'(0, L)
     rule byteSizeofList'(Sz:Int, ListItem(T:Type) LL:List)
          => byteSizeofList'((Sz +Int byteSizeofType(utype(T))), LL)
     rule byteSizeofList'(Sz:Int, .List) => Sz

     syntax Int ::= "maxByteSizeofList'" "(" Int "," List ")" [function]
     rule maxByteSizeofList(L:List) => maxByteSizeofList'(0, L)
     rule maxByteSizeofList'(Sz:Int, ListItem(T:Type) LL:List)
          => maxByteSizeofList'(maxInt(Sz, byteSizeofType(utype(T))), LL)
     rule maxByteSizeofList'(Sz:Int, .List) => Sz

     rule bitSizeofType(ut(_, no-type)) => 0
     rule bitSizeofType(ut(_, arrayUType(T::UType, N::Int))) => bitSizeofType(T) *Int N
     rule bitSizeofType(ut(_, flexibleArrayUType(_))) => 0
     rule bitSizeofType(ut(_, functionType(_, _))) => cfg:bitsPerByte
     rule bitSizeofType(ut(_, pointerType(_))) => cfg:ptrsize *Int cfg:bitsPerByte
     rule bitSizeofType(ut(_, bitfieldType(_, N::Int))) => N
     rule bitSizeofType(T:UType) => numBytes(T) *Int cfg:bitsPerByte
          requires isBasicType(type(T))
               andBool notBool isBitfieldType(type(T))

     rule bitSizeofType(ut(_, structType(S::StructId)))
          => bitSizeofStruct(getFieldInfo(S))
     rule bitSizeofType(ut(_, unionType(S::StructId)))
          => bitSizeofUnion(getFieldInfo(S))

     rule bitSizeofStruct(fieldInfo(_, NBits:Int, _, _)) => NBits
     rule bitSizeofUnion(fieldInfo(_, NBits:Int, _, _)) => NBits

     syntax Int ::= bitsToBytes(Int) [function]
     rule bitsToBytes(N:Int) => (absInt(N) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte

endmodule
