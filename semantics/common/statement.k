module C-COMMON-STATEMENT-SYNTAX
     //  switchid, value (tv or 'Default)
     syntax K ::= genLabel(Int, K) [klabel('genLabel)]

     syntax K ::= "pushBlock"
     syntax K ::= "popBlock"

     syntax Statement ::= "loopMarked"
     syntax K ::= "popLoop"

     //  nestingDepth, currentBlock, decl
     syntax K ::= "frozenDeclaration" "(" Int "," Int "," K ")"
     //  nestingDepth, block history, continuation, loop stack, decl stack
     syntax K ::= "gotoObject" "(" Int "," List "," K "," List "," List ")"
          [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))]
endmodule
