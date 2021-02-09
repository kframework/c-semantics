module C-BITSIZE-SYNTAX
     imports BASIC-K
     imports LIST
     imports C-TYPING-SORTS

     syntax Int ::= bitSizeofType(UType) [function]
     syntax Int ::= bitSizeofType(Type) [function]

     syntax Int ::= byteSizeofType(UType) [function]
     syntax Int ::= byteSizeofType(Type) [function]

     syntax KItem ::= sizeof(KItem) [strict]

     syntax Int ::= maxByteSizeofList(List) [function]
endmodule

module C-BITSIZE
     imports C-BITSIZE-SYNTAX
     imports INT
     imports COMMON-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

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

     rule byteSizeofType(t(...) #as T::Type) => (bitSizeofType(T) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte
     rule byteSizeofType(ut(...) #as T::UType) => (bitSizeofType(type(T)) +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte

     rule bitSizeofType(t(...) #as T::Type) => bitSizeofType(utype(T))
     rule bitSizeofType(structOrUnionUType #as T::UType) => bitSizeofFields(getFields(T))
     rule bitSizeofType(ut(_, T'::SimpleUType) #as T::UType) => bitSizeofSimpleType(T')
          requires notBool isStructOrUnionType(type(T))

     syntax Int ::= bitSizeofSimpleType(SimpleUType) [function]
     rule bitSizeofSimpleType(arrayUType(T::UType, N::Int)) => bitSizeofType(T) *Int N
     rule bitSizeofSimpleType(functionType(_, _)) => cfg:bitsPerByte
     rule bitSizeofSimpleType(pointerType(_)) => cfg:ptrsize *Int cfg:bitsPerByte
     rule bitSizeofSimpleType(bitfieldType(_, N::Int)) => N
     rule bitSizeofSimpleType(enumType(S::TagId)) => bitSizeofSimpleType(getEnumAlias(S))
     rule bitSizeofSimpleType(T::SimpleUType) => 0
          requires notBool isCompleteType(type(T))
     rule bitSizeofSimpleType(T::SimpleUType) => numBytesArithmetic(T) *Int cfg:bitsPerByte [owise]

     syntax Int ::= "maxByteSizeofList'" "(" Int "," List ")" [function]
     rule maxByteSizeofList(L:List) => maxByteSizeofList'(0, L)
     rule maxByteSizeofList'(Sz:Int, ListItem(T:Type) LL:List)
          => maxByteSizeofList'(maxInt(Sz, byteSizeofType(utype(T))), LL)
     rule maxByteSizeofList'(Sz:Int, ListItem(typedDeclaration(T::Type, _)) LL:List)
          => maxByteSizeofList'(maxInt(Sz, byteSizeofType(utype(T))), LL)
     rule maxByteSizeofList'(Sz:Int, .List) => Sz

     syntax Int ::= bitSizeofFields(FieldInfo) [function]
     rule bitSizeofFields(fieldInfo(_, NBits:Int, _, _, _, _)) => NBits
     rule bitSizeofFields(_) => 0 [owise]

endmodule
