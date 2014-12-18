module C-SETTINGS-SYNTAX
     // S 6.2.5 p.35 i.15.  "The implementation shall define char to have the
     // same range, representation, and behavior as either signed char or
     // unsigned char.  37)... Irrespective of the choice made, char is a
     // separate type from the other two and is not compatible with either"
     //
     // FIXME I'm not sure what consequence being a separate type entails, so
     // for now it will just be rewritten to the chosen type
     syntax BaseType ::= "cfg:charAlias" [function]

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
