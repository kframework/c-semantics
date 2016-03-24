module C-ALIGNMENT-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax Int ::= byteAlignofType(Type) [function]

     syntax KItem ::= alignofType(K) [strict]

     syntax Int ::= maxByteAlignofList(List) [function]
endmodule

module C-ALIGNMENT
     imports C-ALIGNMENT-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-ERROR-SYNTAX
     imports COMPAT-SYNTAX

     rule alignofType(T:Type) => tv(byteAlignofType(T), ut(SetItem(IntegerConstant), cfg:sizeut))
          requires isCompleteType(T) andBool notBool isFunctionType(T)
          [structural]
     rule (.K => CV("CAL1", "Trying to compute alignof of a type that is incomplete or a function type.", "6.5.3.4:1"))
          ~> alignofType(T:Type)
          requires notBool isCompleteType(T) orBool isFunctionType(T)

     // TODO(chathhorn): make configurable.
     rule byteAlignofType(t(_, _, bool)) => cfg:alignofBool
     rule byteAlignofType(t(_, _, signed-char)) => cfg:alignofSignedChar
     rule byteAlignofType(t(_, _, short-int)) => cfg:alignofShortInt
     rule byteAlignofType(t(_, _, int)) => cfg:alignofInt
     rule byteAlignofType(t(_, _, long-int)) => cfg:alignofLongInt
     rule byteAlignofType(t(_, _, long-long-int)) => cfg:alignofLongLongInt
     rule byteAlignofType(t(_, _, float)) => cfg:alignofFloat
     rule byteAlignofType(t(_, _, double)) => cfg:alignofDouble
     rule byteAlignofType(t(_, _, long-double)) => cfg:alignofLongDouble
     rule byteAlignofType(t(_, _, no-type)) => cfg:alignofMalloc

     rule byteAlignofType(t(_, _, unsigned-char))
          => byteAlignofType(type(signed-char))
     rule byteAlignofType(t(_, _, unsigned-short-int))
          => byteAlignofType(type(short-int))
     rule byteAlignofType(t(_, _, unsigned-int))
          => byteAlignofType(type(int))
     rule byteAlignofType(t(_, _, unsigned-long-int))
          => byteAlignofType(type(long-int))
     rule byteAlignofType(t(_, _, unsigned-long-long-int))
          => byteAlignofType(type(long-long-int))

     rule byteAlignofType(t(Qs::Quals, Mods::Set, enumType(_)))
          => byteAlignofType(t(Qs, Mods, cfg:enumAlias))

     syntax Int ::= "maxByteAlignofList'" "(" Int "," List ")" [function]
     rule maxByteAlignofList(L:List) => maxByteAlignofList'(1, L)
     rule maxByteAlignofList'(Sz:Int, ListItem(T:Type) LL:List)
          => maxByteAlignofList'(maxInt(Sz, byteAlignofType(T)), LL)
     rule maxByteAlignofList'(Sz:Int, ListItem(typedDeclaration(T::Type, _)) LL:List)
          => maxByteAlignofList'(maxInt(Sz, byteAlignofType(T)), LL)
     rule maxByteAlignofList'(Sz:Int, .List) => Sz

     rule byteAlignofType(T:ArrayType)  => byteAlignofType(innerType(T))
     rule byteAlignofType(t(_, _, pointerType(_))) => cfg:alignofPointer
     rule byteAlignofType(t(_, _, structType(S:StructId)))
          => byteAlignofStruct(getFieldInfo(S))
     rule byteAlignofType(t(_, _, unionType(S:StructId)))
          => byteAlignofStruct(getFieldInfo(S))

     syntax Int ::= byteAlignofStruct(FieldInfo) [function]

     rule byteAlignofStruct(fieldInfo(Decls:List, _:Int, _:Map, _:Map))
          => maxByteAlignofList(Decls)

     // TODO(dwightguth): make sure we correctly handle all the corner cases
     rule byteAlignofType(_) => 1 [owise]
endmodule
