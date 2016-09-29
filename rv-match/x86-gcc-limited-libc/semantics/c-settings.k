module C-SETTINGS
     // Note: This profile will cause the C semantics to work incorrectly unless built with
     // proprietary RV-Match code.
     imports BITS-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports BOOL
     imports INT

     rule cfg:charAlias => signed-char
     rule cfg:enumAlias => int

     syntax SimpleSignedType ::= SimpleEnumType

     rule cfg:bitsPerByte => 8

     rule cfg:sizeofBool => 1
     rule cfg:sizeofSignedChar => 1
     rule cfg:sizeofShortInt => 2
     rule cfg:sizeofInt => 4
     rule cfg:sizeofLongInt => 4
     rule cfg:sizeofLongLongInt => 8
     rule cfg:sizeofFloat => 4
     rule cfg:sizeofDouble => 8
     rule cfg:sizeofLongDouble => 16
     rule cfg:thrdut => int

     rule cfg:precisionofFloat => 24
     rule cfg:precisionofDouble => 53
     rule cfg:precisionofLongDouble => 65
     rule cfg:exponentofFloat => 8
     rule cfg:exponentofDouble => 11
     rule cfg:exponentofLongDouble => 15

     rule cfg:largestUnsigned => unsigned-long-long-int

     rule cfg:mtxPlain => 0

     rule cfg:sizeut => unsigned-int
     rule cfg:wcharut => int
     rule cfg:ptrsize => 4
     rule cfg:ptrdiffut => int

     rule cfg:alignofBool => 1
     rule cfg:alignofSignedChar => 1
     rule cfg:alignofShortInt => 2
     rule cfg:alignofInt => 4
     rule cfg:alignofLongInt => 4
     rule cfg:alignofLongLongInt => 8
     rule cfg:alignofFloat => 4
     rule cfg:alignofDouble => 8
     rule cfg:alignofLongDouble => 16
     rule cfg:alignofPointer => 4
     // Max of the above.
     rule cfg:alignofMalloc => 16

     rule cfg:intToPointer(0, _) => NullPointer
     rule cfg:intToPointer(_, _) => trap [owise]
     rule cfg:pointerToInt(_, T::UType) => unknown(max(T))

     rule cfg:maxHeapBound => (1 <<Int 32) -Int 2

     rule isErrorRecovery => true
     rule hasLint => true

     rule cfg:stackSize(_, _) => 0

endmodule

