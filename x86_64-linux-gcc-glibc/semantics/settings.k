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

     rule cfg:largestUnsigned => t(.Set, unsigned-long-long-int)

     rule cfg:mtxPlain => 0

     rule cfg:sizeut => t(.Set, unsigned-long-int)
     rule cfg:wcharut => t(.Set, int)
     rule cfg:ptrsize => 8
     rule cfg:ptrdiffut => t(.Set, int)

     rule cfg:enumMin => min(t(.Set, int))
     rule cfg:enumMax => max(t(.Set, int))
endmodule

