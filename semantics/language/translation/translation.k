require "syntax.k"

require "check-loc.k"
require "compound-literal.k"
require "configuration.k"
require "conversion.k"
require "error.k"
require "io-direct.k"
require "process-label.k"
require "function-def.k"
require "init.k"

require "decl/resolution.k"
require "decl/global.k"
require "decl/local.k"

require "expr/additive.k"
require "expr/assignment.k"
require "expr/bitwise.k"
require "expr/conversion.k"
require "expr/function-call.k"
require "expr/identifier.k"
require "expr/inc-and-dec.k"
require "expr/logical.k"
require "expr/members.k"
require "expr/multiplicative.k"
require "expr/relational.k"
require "expr/sequencing.k"
require "expr/unary.k"

require "symbolic-value.k"

require "stmt/block.k"
require "stmt/break.k"
require "stmt/goto.k"
require "stmt/if-then.k"
require "stmt/labeled.k"
require "stmt/loop.k"
require "stmt/return.k"
require "stmt/static-assert.k"
require "stmt/switch.k"

module C-TRANSLATION
     imports C-CHECK-LOC
     imports C-COMPOUND-LITERAL
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-FUNCTION-DEF
     imports C-IO-DIRECT
     imports C-PROCESS-LABEL
     imports C-TRANSLATION-CONVERSION
     imports C-TRANSLATION-ERROR
     imports C-TRANSLATION-INIT

     imports C-DECL-RESOLUTION
     imports C-DECL-GLOBAL
     imports C-DECL-LOCAL

     imports C-EXPR-ADDITIVE
     imports C-EXPR-ASSIGNMENT
     imports C-EXPR-BITWISE
     imports C-EXPR-CONVERSION
     imports C-EXPR-FUNCTION-CALL
     imports C-EXPR-IDENTIFIER
     imports C-EXPR-INC-AND-DEC
     imports C-EXPR-LOGICAL
     imports C-EXPR-MEMBERS
     imports C-EXPR-MULTIPLICATIVE
     imports C-EXPR-RELATIONAL
     imports C-EXPR-SEQUENCING
     imports C-EXPR-UNARY

     imports C-SYMBOLIC-VALUE

     imports C-STMT-BLOCK
     imports C-STMT-BREAK
     imports C-STMT-GOTO
     imports C-STMT-IF-THEN
     imports C-STMT-LABELED
     imports C-STMT-LOOP
     imports C-STMT-RETURN
     imports C-STMT-STATIC-ASSERT
     imports C-STMT-SWITCH
endmodule
