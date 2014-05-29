module C-BITSIZE-SYNTAX
     syntax Int ::= bitSizeofType(Type) [function]
     syntax Int ::= byteSizeofType(Type) [function]

     syntax Int ::= bitSizeofStruct(FieldInfo) [function]
     syntax Int ::= bitSizeofUnion(FieldInfo) [function]

     // generates a tv(size, cfg:sizeut)
     syntax K ::= sizeofType(K) [strict]

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
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports COMPAT-SYNTAX

     rule sizeofType(T:Type)
          => cast(cfg:sizeut, tv(byteSizeofType(elideDeclParams(T)), cfg:largestUnsigned))
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
     rule numBytes(t(_, enumType(_))) => cfg:sizeofEnum

     syntax Int ::= byteSizeofList(List) [function]
     syntax Int ::= "byteSizeofList'" "(" Int "," List ")" [function]

     rule byteSizeofList(L:List) => byteSizeofList'(0, L)
     rule byteSizeofList'(
          (Sz:Int => Sz +Int byteSizeofType(T)),
          (ListItem(T:Type) => .List) _)
     rule byteSizeofList'(Sz:Int, .List) => Sz
          
     syntax Int ::= "maxByteSizeofList'" "(" Int "," List ")" [function]
     rule maxByteSizeofList(L:List) => maxByteSizeofList'(0, L)
     rule maxByteSizeofList'(
          (Sz:Int => maxInt(Sz, byteSizeofType(T))),
          (ListItem(T:Type) => .List) _:List)
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
          when isBasicType(T)
     rule bitSizeofType(typedDeclaration(T:Type, _)) 
          => bitSizeofType(T)

     rule bitSizeofType(t(_, structType(_, NBits:Int, _))) 
          => NBits
     rule bitSizeofType(t(_, unionType(_, NBits:Int, _)))
          => NBits

     rule bitSizeofStruct(fieldInfo(Decls:List, _, _))
          => byteSizeofList(Decls) *Int cfg:bitsPerByte
     rule bitSizeofUnion(fieldInfo(Decls:List, _, _))
          => maxByteSizeofList(Decls) *Int cfg:bitsPerByte

     //- derived
     syntax Int ::= bitsToBytes(CSize) [function]
     rule bitsToBytes(N:Int) => absInt(N /Int cfg:bitsPerByte)
          when cfg:bitsPerByte dividesInt N
     rule bitsToBytes(N:Int) => absInt((N /Int cfg:bitsPerByte) +Int 1) 
          when notBool cfg:bitsPerByte dividesInt N
     rule bitsToBytes(N:CSize) => N // Pass through sym values.
          when isInt(N) =/=K true

endmodule
