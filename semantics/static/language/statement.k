require "statement/block.k"
require "statement/loop.k"
require "statement/goto.k"
require "statement/process-label.k"
require "statement/switch.k"

module C-STATEMENT-SYNTAX
     syntax K ::= "calculateGotoMap" "(" Id "," K ")"
endmodule

module C-STATEMENT
     imports C-STATEMENT-PROCESS-LABEL
     imports C-STATEMENT-LOOP 
     imports C-STATEMENT-SWITCH 
     imports C-STATEMENT-GOTO 
     imports C-STATEMENT-BLOCK
endmodule
