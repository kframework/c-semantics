module C-SETTINGS-SYNTAX
     imports SETTINGS-SYNTAX
     imports COMMON-SORTS
     imports STRING
     imports LIST

     syntax Int ::= "cfg:sizeofBool" [function]
     syntax Int ::= "cfg:sizeofSignedChar" [function]
     syntax Int ::= "cfg:sizeofShortInt" [function]
     syntax Int ::= "cfg:sizeofInt" [function]
     syntax Int ::= "cfg:sizeofLongInt" [function]
     syntax Int ::= "cfg:sizeofLongLongInt" [function]
     syntax Int ::= "cfg:sizeofOversizedInt" [function]
     syntax Int ::= "cfg:sizeofFloat" [function]
     syntax Int ::= "cfg:sizeofDouble" [function]
     syntax Int ::= "cfg:sizeofLongDouble" [function]
     syntax Int ::= "cfg:sizeofOversizedFloat" [function]
     syntax Int ::= "cfg:exponentofFloat" [function]
     syntax Int ::= "cfg:exponentofDouble" [function]
     syntax Int ::= "cfg:exponentofLongDouble" [function]
     syntax Int ::= "cfg:exponentofOversizedFloat" [function]
     syntax Int ::= "cfg:precisionofFloat" [function]
     syntax Int ::= "cfg:precisionofDouble" [function]
     syntax Int ::= "cfg:precisionofLongDouble" [function]
     syntax Int ::= "cfg:precisionofOversizedFloat" [function]
     syntax SimpleBasicType ::= "cfg:thrdut" [function]
     syntax Int ::= "cfg:mtxPlain" [function]
     syntax SimpleBasicType ::= "cfg:sizeut" [function]
     syntax SimpleBasicType ::= "cfg:wintut" [function]
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
     syntax Int ::= "cfg:alignofOversizedInt" [function]
     syntax Int ::= "cfg:alignofFloat" [function]
     syntax Int ::= "cfg:alignofDouble" [function]
     syntax Int ::= "cfg:alignofLongDouble" [function]
     syntax Int ::= "cfg:alignofOversizedFloat" [function]
     syntax Int ::= "cfg:alignofPointer" [function]
     syntax Int ::= "cfg:defaultMaxAlign" [function]
     syntax Int ::= "cfg:alignofMalloc" [function]

     syntax UType

     syntax CValue ::= "cfg:intToPointer" "(" CValue "," UType ")" [function]
     syntax CValue ::= "cfg:pointerToInt" "(" CValue "," UType ")" [function]

     syntax Float ::= "cfg:floatFromBits" "(" Int "," UType ")" [function]
     syntax Int ::= "cfg:floatRepr" "(" Float "," Int "," Int "," UType ")" [function]

     syntax Int ::= "cfg:maxHeapBound" [function]

     syntax Int ::= "cfg:stackSize" "(" List "," List ")" [function]

     syntax Bool ::= "cfg:reservedKeywordSupported" "(" String ")" [function, klabel(cfg:reservedKeywordSupported)]
endmodule
