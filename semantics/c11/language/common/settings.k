module C-SETTINGS-SYNTAX
     imports SETTINGS-SYNTAX
     imports LIST
     // S 6.2.5 p.35 i.15.  "The implementation shall define char to have the
     // same range, representation, and behavior as either signed char or
     // unsigned char.  37)... Irrespective of the choice made, char is a
     // separate type from the other two and is not compatible with either"
     //
     // FIXME I'm not sure what consequence being a separate type entails, so
     // for now it will just be rewritten to the chosen type
     syntax SimpleCharType ::= "cfg:charAlias" [function]
     syntax SimpleBasicType ::= "cfg:enumAlias" [function]

     syntax Int ::= "cfg:sizeofBool" [function]
     syntax Int ::= "cfg:sizeofSignedChar" [function]
     syntax Int ::= "cfg:sizeofShortInt" [function]
     syntax Int ::= "cfg:sizeofInt" [function]
     syntax Int ::= "cfg:sizeofLongInt" [function]
     syntax Int ::= "cfg:sizeofLongLongInt" [function]
     syntax Int ::= "cfg:sizeofFloat" [function]
     syntax Int ::= "cfg:sizeofDouble" [function]
     syntax Int ::= "cfg:sizeofLongDouble" [function]
     syntax Int ::= "cfg:exponentofFloat" [function]
     syntax Int ::= "cfg:exponentofDouble" [function]
     syntax Int ::= "cfg:exponentofLongDouble" [function]
     syntax Int ::= "cfg:precisionofFloat" [function]
     syntax Int ::= "cfg:precisionofDouble" [function]
     syntax Int ::= "cfg:precisionofLongDouble" [function]
     syntax SimpleBasicType ::= "cfg:thrdut" [function]
     syntax Int ::= "cfg:mtxPlain" [function]
     syntax SimpleBasicType ::= "cfg:sizeut" [function]
     syntax SimpleBasicType ::= "cfg:wcharut" [function]
     syntax SimpleBasicType ::= "cfg:largestUnsigned" [function]
     syntax Int ::= "cfg:ptrsize" [function]
     syntax SimpleBasicType ::= "cfg:ptrdiffut" [function]

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

     syntax UType

     syntax CValue ::= "cfg:intToPointer" "(" CValue "," UType ")" [function]
     syntax CValue ::= "cfg:pointerToInt" "(" CValue "," UType ")" [function]

     syntax Float ::= "cfg:floatFromBits" "(" Int "," UType ")" [function]
     syntax Int ::= "cfg:floatRepr" "(" Float "," Int "," Int "," UType ")" [function]

     syntax Int ::= "cfg:maxHeapBound" [function]

     syntax Int ::= "cfg:stackSize" "(" List "," List ")" [function]

endmodule
