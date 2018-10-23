require "check-effective.k"
require "check-restrict.k"
require "env.k"
require "error.k"
require "init.k"
require "io.k"
require "races.k"
require "sequence-point.k"

require "stmt/block.k"
require "stmt/break.k"
require "stmt/expr.k"
require "stmt/goto.k"
require "stmt/if-then.k"
require "stmt/labeled.k"
require "stmt/loop.k"
require "stmt/return.k"
require "stmt/switch.k"

require "expr/assignment.k"
require "expr/conditional.k"
require "expr/function-call.k"
require "expr/identifier.k"
require "expr/inc-and-dec.k"
require "expr/logical.k"
require "expr/sequencing.k"

require "decl/local.k"
require "decl/typedef.k"

module C-EXECUTION
     imports C-ENV
     imports C-EXECUTION-ERROR
     imports C-EXECUTION-INIT

     imports C-CHECK-EFFECTIVE
     imports C-CHECK-RESTRICT
     imports C-IO
     imports C-RACES
     imports C-SEQUENCE-POINT

     imports C-STMT-BLOCK
     imports C-STMT-BREAK
     imports C-STMT-EXPR
     imports C-STMT-GOTO
     imports C-STMT-IF-THEN
     imports C-STMT-LABELED
     imports C-STMT-LOOP
     imports C-STMT-RETURN
     imports C-STMT-SWITCH

     imports C-EXPR-ASSIGNMENT
     imports C-EXPR-CONDITIONAL
     imports C-EXPR-FUNCTION-CALL
     imports C-EXPR-IDENTIFIER
     imports C-EXPR-INC-AND-DEC
     imports C-EXPR-LOGICAL
     imports C-EXPR-SEQUENCING

     imports C-DECL-LOCAL
     imports C-DECL-TYPEDEF

endmodule


