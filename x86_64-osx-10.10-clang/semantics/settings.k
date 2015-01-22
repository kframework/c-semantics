module C-SETTINGS
     imports C-SETTINGS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule cfg:charAlias => signed-char

     rule cfg:bitsPerByte => 8

     rule cfg:sizeofBool => 1
     rule cfg:sizeofSignedChar => 1
     rule cfg:sizeofShortInt => 2
     rule cfg:sizeofInt => 4
     rule cfg:sizeofLongInt => 8
     rule cfg:sizeofLongLongInt => 8
     rule cfg:sizeofFloat => 4
     rule cfg:sizeofDouble => 8
     rule cfg:sizeofLongDouble => 16
     rule cfg:sizeofEnum => cfg:sizeofInt

     rule cfg:largestUnsigned => unsigned-long-long-int

     rule cfg:mtxPlain => 0

     rule cfg:sizeut => unsigned-long-int
     rule cfg:wcharut => int
     rule cfg:ptrsize => 8
     rule cfg:ptrdiffut => long-int

     rule cfg:enumMin => min(t(.Set, int))
     rule cfg:enumMax => max(t(.Set, int))

     rule cfg:alignofBool => 1
     rule cfg:alignofSignedChar => 1
     rule cfg:alignofShortInt => 2
     rule cfg:alignofInt => 4
     rule cfg:alignofLongInt => 8
     rule cfg:alignofLongLongInt => 8
     rule cfg:alignofFloat => 4
     rule cfg:alignofDouble => 8
     rule cfg:alignofLongDouble => 16
     rule cfg:alignofEnum => cfg:alignofInt
     rule cfg:alignofPointer => 8

endmodule

