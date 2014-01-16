require "check-loc.k"
require "compound-literal.k"
require "configuration.k"
require "error.k"
require "io-direct.k"
require "process-label.k"
require "function-def.k"
require "settings.k"
require "init.k"
require "sym-val.k"

require "declaration/resolution.k"
require "declaration/global.k"

require "expression/function-call.k"
require "expression/id-rval.k"
require "expression/inc-and-dec.k"
require "expression/sequencing.k"

require "statement/block.k"
require "statement/break.k"
require "statement/goto.k"
require "statement/if-then.k"
require "statement/labeled.k"
require "statement/loop.k"
require "statement/return.k"
require "statement/switch.k"

module C11-TRANSLATION
     imports C11-CONFIGURATION
     imports C11-TRANS-ERROR
     imports C11-SETTINGS
     imports C-CHECK-LOC
     imports C-IO-DIRECT
     imports C-PROCESS-LABEL
     imports C-FUNCTION-DEF
     imports C-COMPOUND-LITERAL
     imports C-DYNAMIC-SYNTAX
     imports C-TRANSLATION-INIT
     imports C-SYM-VAL-SYNTAX

     imports C-DECLARATION-RESOLUTION
     imports C-DECLARATION-GLOBAL

     imports C-EXPRESSION-FUNCTION-CALL
     imports C-EXPRESSION-ID-RVAL
     imports C-EXPRESSION-INC-AND-DEC
     imports C-EXPRESSION-SEQUENCING

     imports C-STATEMENT-BLOCK
     imports C-STATEMENT-BREAK
     imports C-STATEMENT-GOTO
     imports C-STATEMENT-IF-THEN
     imports C-STATEMENT-LABELED
     imports C-STATEMENT-LOOP
     imports C-STATEMENT-RETURN
     imports C-STATEMENT-SWITCH

endmodule
