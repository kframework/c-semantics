require "binding.k"
require "builtin.k"
require "check-loc.k"
require "compound-literal.k"
require "configuration.k"
require "declaration-local.k"
require "error.k"
require "expression.k"
require "io-buffered.k"
require "ltlmc.k"
require "settings.k"
require "statement.k"
require "init.k"

require "statement/block.k"
require "statement/break.k"
require "statement/loop.k"
require "statement/goto.k"
require "statement/if-then.k"
require "statement/labeled.k"
require "statement/return.k"
require "statement/switch.k"

require "expression/function-call.k"
require "expression/inc-and-dec.k"
require "expression/sequencing.k"
require "expression/id-rval.k"

require "declaration/local.k"

module C11-EXECUTION
     imports C11-CONFIGURATION
     imports C11-LTLMC
     imports C11-SETTINGS
     imports C11-EXEC-ERROR
     imports C11-EXECUTION-INIT

     imports C-BINDING
     imports C-BUILTIN
     imports C-CHECK-LOC
     imports C-COMPOUND-LITERAL
     imports C-IO-BUFFERED

     imports C-STATEMENT-LABELED
     imports C-STATEMENT-IF-THEN 
     imports C-STATEMENT-LOOP 
     imports C-STATEMENT-SWITCH 
     imports C-STATEMENT-GOTO 
     imports C-STATEMENT-RETURN 
     imports C-STATEMENT-BLOCK
     imports C-STATEMENT-BREAK

     imports C-EXPRESSION-FUNCTION-CALL
     imports C-EXPRESSION-INC-AND-DEC
     imports C-EXPRESSION-SEQUENCING
     imports C-EXPRESSION-ID-RVAL

     imports C-DECLARATION-LOCAL
endmodule


