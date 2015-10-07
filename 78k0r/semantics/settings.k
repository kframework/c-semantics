module C-SETTINGS
     imports C-SETTINGS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-BITS-SYNTAX
     imports COMPAT-SYNTAX

     rule cfg:charAlias => signed-char
     rule cfg:enumAlias => int

     syntax SimpleSignedType ::= SimpleEnumType

     rule cfg:bitsPerByte => 8

     rule cfg:sizeofBool => 1
     rule cfg:sizeofSignedChar => 1
     rule cfg:sizeofShortInt => 2
     rule cfg:sizeofInt => 2
     rule cfg:sizeofLongInt => 4
     rule cfg:sizeofLongLongInt => 8
     rule cfg:sizeofFloat => 4
     rule cfg:sizeofDouble => 4
     rule cfg:sizeofLongDouble => 4

     rule cfg:largestUnsigned => unsigned-long-long-int

     rule cfg:mtxPlain => 0

     rule cfg:sizeut => unsigned-int
     rule cfg:wcharut => int
     rule cfg:ptrsize => 2
     rule cfg:ptrdiffut => int

     rule cfg:alignofBool => 1
     rule cfg:alignofSignedChar => 1
     rule cfg:alignofShortInt => 2
     rule cfg:alignofInt => 2
     rule cfg:alignofLongInt => 4
     rule cfg:alignofLongLongInt => 8
     rule cfg:alignofFloat => 4
     rule cfg:alignofDouble => 4
     rule cfg:alignofLongDouble => 4
     rule cfg:alignofPointer => 2
     // Max of the above.
     rule cfg:alignofMalloc => 8

     rule cfg:intToPointer(0, _) => NullPointer
     rule cfg:intToPointer(V:Int, _) => loc(0 @ nativeAddress, V, SetItem(align(getNativeAlign(V))))
          requires V =/=Int 0
     rule cfg:intToPointer(L:SymLoc, _) => L
     rule cfg:intToPointer(_, _) => trap [owise]
     rule cfg:pointerToInt(loc(0 @ nativeAddress, V:Int), _) => V
     rule cfg:pointerToInt(loc(0 @ nativeAddress, V:Int, _), _) => V
     rule cfg:pointerToInt(L:SymLoc, _) => L requires notBool isNativeLoc(L)

     rule isErrorRecovery => true

endmodule

