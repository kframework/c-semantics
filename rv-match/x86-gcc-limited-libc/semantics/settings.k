module C-SETTINGS
     // Note: This profile will cause the C semantics to work incorrectly unless built with
     // proprietary RV-Match code.
     imports C-SETTINGS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX

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
     rule cfg:pointerToInt(_, _) => unknown

     rule isErrorRecovery => true
     rule hasLint => true

endmodule

