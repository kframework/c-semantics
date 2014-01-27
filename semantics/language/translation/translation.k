require "check-loc.k"
require "compound-literal.k"
require "configuration.k"
require "error.k"
require "io-direct.k"
require "process-label.k"
require "function-def.k"
require "init.k"

require "decl/resolution.k"
require "decl/global.k"
require "decl/local.k"

require "expr/assignment.k"
require "expr/function-call.k"
require "expr/inc-and-dec.k"
require "expr/sequencing.k"
require "expr/additive.k"
require "expr/bitwise.k"
require "expr/conversion.k"
require "expr/identifier.k"
require "expr/logical.k"
require "expr/multiplicative.k"
require "expr/relational.k"
require "expr/unary.k"

require "symbolic-value.k"

require "stmt/block.k"
require "stmt/break.k"
require "stmt/goto.k"
require "stmt/if-then.k"
require "stmt/labeled.k"
require "stmt/loop.k"
require "stmt/return.k"
require "stmt/switch.k"

module C-TRANSLATION
     imports C-CONFIGURATION
     imports C-TRANSLATION-ERROR
     imports C-CHECK-LOC
     imports C-IO-DIRECT
     imports C-PROCESS-LABEL
     imports C-FUNCTION-DEF
     imports C-COMPOUND-LITERAL
     imports C-DYNAMIC-SYNTAX
     imports C-TRANSLATION-INIT

     imports C-DECL-RESOLUTION
     imports C-DECL-GLOBAL
     imports C-DECL-LOCAL

     imports C-EXPR-ASSIGNMENT
     imports C-EXPR-FUNCTION-CALL
     imports C-EXPR-INC-AND-DEC
     imports C-EXPR-SEQUENCING
     imports C-EXPR-ADDITIVE
     imports C-EXPR-BITWISE
     imports C-EXPR-CONVERSION
     imports C-EXPR-IDENTIFIER
     imports C-EXPR-LOGICAL
     imports C-EXPR-MULTIPLICATIVE
     imports C-EXPR-RELATIONAL
     imports C-EXPR-UNARY

     imports C-SYMBOLIC-VALUE

     imports C-STMT-BLOCK
     imports C-STMT-BREAK
     imports C-STMT-GOTO
     imports C-STMT-IF-THEN
     imports C-STMT-LABELED
     imports C-STMT-LOOP
     imports C-STMT-RETURN
     imports C-STMT-SWITCH
endmodule
