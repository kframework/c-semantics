module C-CONSTRAINT-MAP-SYNTAX
     syntax Map ::= "Constraints" [function]
     syntax ErrorRef ::= cv(String) // "constraint violation"
     syntax ErrorTxt ::= String
endmodule

module C-CONSTRAINT-MAP
     imports C-CONSTRAINT-MAP-SYNTAX

     rule Constraints => 
"6.5.2.3:1" |-> "The first operand of the . operator shall have an atomic, qualified, or unqualified structure or union type, and the second operand shall name a member of that type."
"6.5.15:3" |-> "Constraints on conditional expressions."
"6.5.16.1:1" |-> "Constraints on assignment."
"6.7:3" |-> "If an identifier has no linkage, there shall be no more than one declaration of the identifier (in a declarator or type specifier) with the same scope and in the same name space, except in certain cases."
"6.7.6.2:1" |-> "If the (size of an array) is a constant expression, it shall have a value greater than zero."
"6.9:2" |-> "The storage-class specifiers auto and register shall not appear in the declaration specifiers in an external declaration."
"6.9:3s1" |-> "There shall be no more than one external definition for each identifier declared with internal linkage in a translation unit."
"6.9:3s2" |-> "If an identifier declared with internal linkage is used in an expression (other than as a part of the operand of a sizeof or _Alignof operator whose result is an integer constant), there shall be exactly one external definition for the identifier in the translation unit."

endmodule
