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

     rule alignofType(T:Type) => tv(byteAlignofType(T), t(SetItem(IntegerConstant), cfg:sizeut))
          requires isCompleteType(T) andBool notBool isFunctionType(T)
          [structural]
     rule (.K => CV("CAL1", "Trying to compute alignof of a type that is incomplete or a function type.", "6.5.3.4:1")) ~> alignofType(T:Type)
         requires notBool isCompleteType(T) orBool isFunctionType(T)

     // TODO(chathhorn): make configurable.
     rule byteAlignofType(t(_, bool)) => cfg:alignofBool
     rule byteAlignofType(t(_, signed-char)) => cfg:alignofSignedChar
     rule byteAlignofType(t(_, short-int)) => cfg:alignofShortInt
     rule byteAlignofType(t(_, int)) => cfg:alignofInt
     rule byteAlignofType(t(_, long-int)) => cfg:alignofLongInt
     rule byteAlignofType(t(_, long-long-int)) => cfg:alignofLongLongInt
     rule byteAlignofType(t(_, float)) => cfg:alignofFloat
     rule byteAlignofType(t(_, double)) => cfg:alignofDouble
     rule byteAlignofType(t(_, long-double)) => cfg:alignofLongDouble

     rule byteAlignofType(t(_, unsigned-char)) => byteAlignofType(t(.Set, signed-char))
     rule byteAlignofType(t(_, unsigned-short-int)) => byteAlignofType(t(.Set, short-int))
     rule byteAlignofType(t(_, unsigned-int)) => byteAlignofType(t(.Set, int))
     rule byteAlignofType(t(_, unsigned-long-int)) => byteAlignofType(t(.Set, long-int))
     rule byteAlignofType(t(_, unsigned-long-long-int)) => byteAlignofType(t(.Set, long-long-int))

     rule byteAlignofType(t(_, enumType(_))) => cfg:alignofEnum
     
     syntax Int ::= byteAlignofList(List) [function]
     syntax Int ::= "byteAlignofList'" "(" Int "," List ")" [function]

     rule byteAlignofList(L:List) => byteAlignofList'(0, L)
     rule byteAlignofList'(Sz:Int, ListItem(T:Type) LL:List)
	  => byteAlignofList'((Sz +Int byteAlignofType(T)), LL)
     rule byteAlignofList'(Sz:Int, .List) => Sz

     syntax Int ::= "maxByteAlignofList'" "(" Int "," List ")" [function]
     rule maxByteAlignofList(L:List) => maxByteAlignofList'(0, L)
     rule maxByteAlignofList'(Sz:Int, ListItem(T:Type) LL:List)
          => maxByteAlignofList'(maxInt(Sz, byteAlignofType(T)), LL)
     rule maxByteAlignofList'(Sz:Int, .List) => Sz

     rule byteAlignofType(typedDeclaration(T:Type, _)) => byteAlignofType(T)

     rule byteAlignofType(t(_, arrayType(T:Type, _)))  => byteAlignofType(T)
     rule byteAlignofType(t(_, pointerType(_))) => cfg:alignofPointer
     rule byteAlignofType(t(_, structType(_, fieldInfo(Decls:List, _, _, _))))
          => maxByteAlignofList(Decls)
     rule byteAlignofType(t(_, unionType(_, fieldInfo(Decls:List, _, _, _))))
          => maxByteAlignofList(Decls)

     // TODO(dwightguth): make sure we correctly handle all the corner cases
     rule byteAlignofType(_) => 1 [owise]
endmodule
