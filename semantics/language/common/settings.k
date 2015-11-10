module C-SETTINGS-SYNTAX
     // S 6.2.5 p.35 i.15.  "The implementation shall define char to have the
     // same range, representation, and behavior as either signed char or
     // unsigned char.  37)... Irrespective of the choice made, char is a
     // separate type from the other two and is not compatible with either"
     //
     // FIXME I'm not sure what consequence being a separate type entails, so
     // for now it will just be rewritten to the chosen type
     syntax SimpleCharType ::= "cfg:charAlias" [function]
     syntax SimpleType ::= "cfg:enumAlias" [function]

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
     syntax Int ::= "cfg:mtxPlain" [function]
     syntax SimpleType ::= "cfg:sizeut" [function]
     syntax SimpleType ::= "cfg:wcharut" [function]
     syntax SimpleType ::= "cfg:largestUnsigned" [function]
     syntax Int ::= "cfg:ptrsize" [function]
     syntax SimpleType ::= "cfg:ptrdiffut" [function]

     syntax Int ::= "cfg:alignofBool" [function]
     syntax Int ::= "cfg:alignofSignedChar" [function]
     syntax Int ::= "cfg:alignofShortInt" [function]
     syntax Int ::= "cfg:alignofInt" [function]
     syntax Int ::= "cfg:alignofLongInt" [function]
     syntax Int ::= "cfg:alignofLongLongInt" [function]
     syntax Int ::= "cfg:alignofFloat" [function]
     syntax Int ::= "cfg:alignofDouble" [function]
     syntax Int ::= "cfg:alignofLongDouble" [function]
     syntax Int ::= "cfg:alignofPointer" [function]
     syntax Int ::= "cfg:alignofMalloc" [function]

     syntax Type

     syntax CValue ::= "cfg:intToPointer" "(" CValue "," Type ")" [function]
     syntax CValue ::= "cfg:pointerToInt" "(" CValue "," Type ")" [function]

     syntax Bool ::= "isErrorRecovery" [function]
                   | "hasLint" [function]

endmodule
