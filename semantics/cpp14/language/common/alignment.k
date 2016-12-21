module CPP-ALIGNMENT-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-TYPING-SORTS

     syntax Int ::= getAlign(SymLoc) [function, klabel(getAlignCpp)]
                  | getAlignof(CPPType) [function]

     syntax Int ::= byteAlignofType(CPPType) [function, klabel(byteAlignofTypeCpp)]

endmodule

module CPP-ALIGNMENT
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule byteAlignofType(t(_, _, _:CPPSimpleCharType)) => cfg:alignofSignedChar
endmodule
