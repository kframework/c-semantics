module CPP-SETTINGS-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports CPP-TYPING-SORTS

     syntax Int ::= "cfg:maxNewSize" [function]

     syntax Int ::= "cfg:memberDataPtrSize" [function]
     syntax Int ::= "cfg:memberFunctionPtrSize" [function]
     syntax Int ::= "cfg:memberDataPtrAlign" [function]
     syntax Int ::= "cfg:memberFunctionPtrAlign" [function]

     syntax CPPValue ::= "cfg:intToPointer" "(" CPPValue "," CPPType ")" [function]
     syntax CPPValue ::= "cfg:pointerToInt" "(" CPPValue "," CPPType ")" [function]
endmodule
