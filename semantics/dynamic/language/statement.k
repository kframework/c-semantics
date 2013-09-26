require "statement/block.k"
require "statement/break.k"
require "statement/loop.k"
require "statement/goto.k"
require "statement/if-then.k"
require "statement/labeled.k"
require "statement/return.k"
require "statement/switch.k"

module C-STATEMENT-SYNTAX
     imports C-COMMON-STATEMENT-SYNTAX
endmodule

module C-STATEMENT
     imports C-STATEMENT-LABELED
     imports C-STATEMENT-IF-THEN 
     imports C-STATEMENT-LOOP 
     imports C-STATEMENT-SWITCH 
     imports C-STATEMENT-GOTO 
     imports C-STATEMENT-RETURN 
     imports C-STATEMENT-BLOCK
     imports C-STATEMENT-BREAK
endmodule
