module CPP-ALIGNMENT-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-TYPING-SORTS

     syntax Int ::= getAlign(SymLoc) [function, klabel(getAlignCpp)]
                  | getAlignof(CPPType) [function]

endmodule

module CPP-ALIGNMENT
     imports CPP-ALIGNMENT-SYNTAX

endmodule
