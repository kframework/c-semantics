require "binding.k"
require "builtin.k"
require "check-loc.k"
require "compound-literal.k"
require "configuration.k"
require "error.k"
require "io-buffered.k"
require "ltlmc.k"
require "init.k"
require "sequence-point.k"

require "statement/block.k"
require "statement/break.k"
require "statement/loop.k"
require "statement/goto.k"
require "statement/if-then.k"
require "statement/labeled.k"
require "statement/return.k"
require "statement/switch.k"

require "expression/function-call.k"
require "expression/id-rval.k"
require "expression/inc-and-dec.k"
require "expression/logical.k"
require "expression/sequencing.k"

require "declaration/local.k"

module C-EXECUTION
     imports C-CONFIGURATION
     imports C-LTLMC
     imports C-EXECUTION-ERROR
     imports C-EXECUTION-INIT

     imports C-BINDING
     imports C-BUILTIN
     imports C-CHECK-LOC
     imports C-COMPOUND-LITERAL
     imports C-IO-BUFFERED
     imports C-SEQUENCE-POINT

     imports C-STATEMENT-LABELED
     imports C-STATEMENT-IF-THEN 
     imports C-STATEMENT-LOOP 
     imports C-STATEMENT-SWITCH 
     imports C-STATEMENT-GOTO 
     imports C-STATEMENT-RETURN 
     imports C-STATEMENT-BLOCK
     imports C-STATEMENT-BREAK

     imports C-EXPRESSION-FUNCTION-CALL
     imports C-EXPRESSION-ID-RVAL
     imports C-EXPRESSION-INC-AND-DEC
     imports C-EXPRESSION-LOGICAL
     imports C-EXPRESSION-SEQUENCING

     imports C-DECLARATION-LOCAL
endmodule


