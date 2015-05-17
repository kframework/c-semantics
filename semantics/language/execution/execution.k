require "check-loc.k"
require "compound-literal.k"
require "configuration.k"
require "error.k"
require "io-buffered.k"
require "ltlmc.k"
require "init.k"
require "sequence-point.k"


require "stmt/block.k"
require "stmt/break.k"
require "stmt/goto.k"
require "stmt/if-then.k"
require "stmt/loop.k"
require "stmt/return.k"
require "stmt/switch.k"

require "expr/assignment.k"
require "expr/conditional.k"
require "expr/function-call.k"
require "expr/identifier.k"
require "expr/inc-and-dec.k"
require "expr/sequencing.k"

require "decl/local.k"

module C-EXECUTION
     imports C-CONFIGURATION
     imports C-LTLMC
     imports C-EXECUTION-ERROR
     imports C-EXECUTION-INIT

     imports C-CHECK-LOC
     imports C-COMPOUND-LITERAL
     imports C-IO-BUFFERED
     imports C-SEQUENCE-POINT

     imports C-STMT-BLOCK
     imports C-STMT-BREAK
     imports C-STMT-GOTO
     imports C-STMT-IF-THEN
     imports C-STMT-LOOP
     imports C-STMT-RETURN
     imports C-STMT-SWITCH

     imports C-EXPR-ASSIGNMENT
     imports C-EXPR-CONDITIONAL
     imports C-EXPR-FUNCTION-CALL
     imports C-EXPR-INC-AND-DEC
     imports C-EXPR-IDENTIFIER
     imports C-EXPR-SEQUENCING

     imports C-DECL-LOCAL

     imports C-EXECUTION-EXTENSIONS
endmodule


