module C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax Int ::= bitSizeofType(Type) [function]
     syntax Int ::= byteSizeofType(Type) [function]

     syntax Int ::= bitSizeofStruct(FieldInfo) [function]
     syntax Int ::= bitSizeofUnion(FieldInfo) [function]

     // generates a tv(size, cfg:sizeut)
     syntax KItem ::= sizeofType(K) [strict]

     syntax Int ::= maxByteSizeofList(List) [function]
endmodule

module C-BITSIZE
     imports C-BITSIZE-SYNTAX

     imports C-BITS-SYNTAX
     imports C-ENV-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX

     imports C-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports COMPAT-SYNTAX

     rule sizeofType(T:Type)
          => cast(t(SetItem(IntegerConstant), cfg:sizeut), tv(byteSizeofType(elideDeclParams(T)), t(SetItem(IntegerConstant), cfg:largestUnsigned)))
          requires isCompleteType(T) andBool notBool isFunctionType(T)
          [structural]
     rule (.K => CV("CBS1", "Trying to compute sizeof of a type that is incomplete or a function type.", "6.5.3.4:1")) ~> sizeofType(T:Type)
          requires notBool isCompleteType(T) orBool isFunctionType(T)

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
     rule numBytes(t(_, enumType(_))) => cfg:sizeofEnum

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
     rule bitSizeofType(T:Type) => numBytes(T) *Int cfg:bitsPerByte
          requires isBasicType(T)
     rule bitSizeofType(typedDeclaration(T:Type, _))
          => bitSizeofType(T)

     rule bitSizeofType(t(_, structType(_, fieldInfo(_, NBits:Int, _, _))))
          => NBits
     rule bitSizeofType(t(_, unionType(_, fieldInfo(_, NBits:Int, _, _))))
          => NBits

     rule bitSizeofStruct(fieldInfo(_, NBits:Int, _, _))
          => NBits
     rule bitSizeofUnion(fieldInfo(_, NBits:Int, _, _))
          => NBits

     //- derived
     syntax Int ::= bitsToBytes(CSize) [function]
     rule bitsToBytes(N:Int) => absInt(N /Int cfg:bitsPerByte)
          requires cfg:bitsPerByte dividesInt N
     rule bitsToBytes(N:Int) => absInt((N /Int cfg:bitsPerByte) +Int 1)
          requires notBool cfg:bitsPerByte dividesInt N
     rule bitsToBytes(N:CSize) => N // Pass through sym values.
          requires isInt(N:CSize) =/=K true

endmodule
