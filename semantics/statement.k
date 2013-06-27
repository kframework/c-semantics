module C-STATEMENT-INCLUDE
     imports C-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-HELPERS
     imports C-COMPAT-SYNTAX
     
     syntax Statement ::= "loopMarked"
     //  switchid, value (tv or 'Default)
     syntax K ::= "genLabel" "(" Int "," K ")" [klabel('genLabel)]
     syntax K ::= "popLoop"
     syntax K ::= "popBlock"
     //  nestingDepth, currentBlock, decl
     syntax K ::= "frozenDeclaration" "(" Int "," Int "," K ")"
     //  nestingDepth, block history, continuation, loop stack, decl stack
     syntax K ::= "gotoObject" "(" Int "," List "," K "," List "," List ")"
          [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))]
     syntax K ::= "case" "(" Int ")"
endmodule 

module C-STATEMENT
     imports C-STATEMENT-PROCESS-LABELS
endmodule
