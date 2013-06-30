module C-SETTINGS-SYNTAX
     syntax Type ::= "cfg:charAlias" [function]
     syntax Int ::= "cfg:bitsPerByte" [function]
     syntax Int ::= "cfg:sizeofBool" [function]
     syntax Int ::= "cfg:sizeofSignedChar" [function]
     syntax Int ::= "cfg:sizeofShortInt" [function]
     syntax Int ::= "cfg:sizeofInt" [function]
     syntax Int ::= "cfg:sizeofLongInt" [function]
     syntax Int ::= "cfg:sizeofLongLongInt" [function]
     syntax Int ::= "cfg:sizeofFloat" [function]
     syntax Int ::= "cfg:sizeofDouble" [function]
     syntax Int ::= "cfg:sizeofLongDouble" [function]
     syntax Int ::= "cfg:sizeofEnum" [function]
     syntax Int ::= "cfg:mtxPlain" [function]
     syntax Type ::= "cfg:sizeut" [function]
     syntax Type ::= "cfg:wcharut" [function]
     syntax Type ::= "cfg:largestUnsigned" [function]
     syntax Int ::= "cfg:ptrsize" [function]
     syntax Type ::= "cfg:ptrdiffut" [function]

     syntax Int ::= "cfg:enumMin" [function]
     syntax Int ::= "cfg:enumMax" [function]
endmodule

module C-SETTINGS
     imports C-SETTINGS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     
     // S 6.2.5 p.35 i.15.  "The implementation shall define char to have the
     // same range, representation, and behavior as either signed char or
     // unsigned char.  37)... Irrespective of the choice made, char is a
     // separate type from the other two and is not compatible with either"
     //
     // fixme I'm not sure what consequence being a separate type entails, so
     // for now it will just be rewritten to the chosen type
     rule cfg:charAlias => signed-char

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
     rule cfg:sizeofEnum => cfg:sizeofInt

     rule cfg:largestUnsigned => t(.Set, unsigned-long-long-int)
     
     rule cfg:mtxPlain => 0

     rule cfg:sizeut => t(.Set, unsigned-int)
     rule cfg:wcharut => t(.Set, int)
     rule cfg:ptrsize => 4
     rule cfg:ptrdiffut => t(.Set, int)
     
     rule cfg:enumMin => min(t(.Set, int))
     rule cfg:enumMax => max(t(.Set, int))
endmodule

