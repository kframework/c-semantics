module C-BITSIZE-SYNTAX
     syntax Int ::= bitSizeofType(Type) [function]
     syntax Int ::= byteSizeofType(Type) [function]

     syntax Int ::= bitSizeofStruct(FieldInfo) [function]
     syntax Int ::= bitSizeofUnion(FieldInfo) [function]

     // generates a tv(size, cfg:sizeut)
     syntax K ::= sizeofType(K) [strict]
endmodule

module C-BITSIZE
     imports C-BITSIZE-SYNTAX

     imports C-BITS-SYNTAX
     imports C-ENV-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     syntax Int ::= bitSizeofList(List) [function]
     syntax Int ::= "bitSizeofList'" "(" Int "," List ")" [function]
     
     rule sizeofType(T:Type)
          => cast(cfg:sizeut, tv(byteSizeofType(T), cfg:largestUnsigned))
          [structural]

     rule byteSizeofType(T:Type)
          => bitsToBytes(bitSizeofType(T)) 

     rule bitSizeofList(L:List) => bitSizeofList'(0, L)
     rule bitSizeofList'(
          (Sz:Int => Sz +Int bitSizeofType(T)),
          (ListItem(T:Type) => .List) _:List)
     rule bitSizeofList'(Sz:Int, .List) => Sz
          
     syntax Int ::= maxBitSizeofList(List) [function]
     syntax Int ::= "maxBitSizeofList'" "(" Int "," List ")" [function]
     rule maxBitSizeofList(L:List) => maxBitSizeofList'(0, L)
     rule maxBitSizeofList'(
          (Sz:Int => maxInt(Sz, bitSizeofType(T))),
          (ListItem(T:Type) => .List) _:List)
     rule maxBitSizeofList'(Sz:Int, .List) => Sz
     
     rule bitSizeofType(t(_, arrayType(T:Type, N:Int))) 
          => bitSizeofType(T) *Int N
     rule bitSizeofType(t(_, flexibleArrayType(_))) 
          => 0
     // TODO(chathhorn): why is a functionType 8 bits?
     rule bitSizeofType(t(_, functionType(_, _))) 
          => cfg:bitsPerByte
     rule bitSizeofType(t(_, pointerType(_))) 
          => cfg:ptrsize *Int cfg:bitsPerByte
     rule bitSizeofType(t(_, bitfieldType(_, N:Int))) 
          => N
     rule bitSizeofType(t(_, qualifiedType(T:Type, _))) 
          => bitSizeofType(T:Type) 
     rule bitSizeofType(T:Type) 
          => numBits(T)
          when isBasicType(T)
     rule bitSizeofType(typedDeclaration(T:Type, _)) 
          => bitSizeofType(T)

     rule bitSizeofType(t(_, structType(_, NBits:Int, _))) 
          => NBits
     rule bitSizeofType(t(_, unionType(_, NBits:Int, _)))
          => NBits

     rule bitSizeofStruct(fieldInfo(L:List, _, _))
          => bitSizeofList(L)
     rule bitSizeofUnion(fieldInfo(L:List, _, _))
          => maxBitSizeofList(L)

endmodule
