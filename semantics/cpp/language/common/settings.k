module CPP-SETTINGS-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports CPP-TYPING-SORTS

     syntax Int ::= "cfg:maxNewSize" [function]

     syntax Int ::= "cfg:memberDataPtrSize" [function]

     syntax Int ::= "cfg:refsize" [function]

     syntax Int ::= "cfg:memberFunctionPtrSize" [function]

     syntax Int ::= "cfg:memberDataPtrAlign" [function]

     syntax Int ::= "cfg:memberFunctionPtrAlign" [function]

     syntax Int ::= "cfg:alignofReference" [function]

     syntax Int ::= "cfg:alignofNullPtrT" [function]

     syntax Bool ::= "cfg:unwindBeforeTerminate" [function]

     syntax CPPValue ::= "cfg:intToPointer" "(" CPPValue "," CPPType ")" [function]

     syntax CPPValue ::= "cfg:pointerToInt" "(" CPPValue "," CPPType ")" [function]
endmodule
