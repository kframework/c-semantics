require "check-loc.k"
require "compound-literal.k"
require "configuration.k"
require "error.k"
require "io-direct.k"
require "process-label.k"
require "function-def.k"
require "init.k"
require "builtins.k"

require "declaration/resolution.k"
require "declaration/global.k"
require "declaration/local.k"

require "expression/assignment.k"
require "expression/function-call.k"
require "expression/id-rval.k"
require "expression/inc-and-dec.k"
require "expression/sequencing.k"
require "expression/additive-operators.k"
require "expression/bitwise.k"
require "expression/conversion.k"
require "expression/identifier.k"
require "expression/logical.k"
require "expression/multiplicative-operators.k"
require "expression/relational.k"
require "expression/unary-arithmetic.k"

require "symbolic-value.k"

require "statement/block.k"
require "statement/break.k"
require "statement/goto.k"
require "statement/if-then.k"
require "statement/labeled.k"
require "statement/loop.k"
require "statement/return.k"
require "statement/switch.k"

module C-TRANSLATION
     imports C-CONFIGURATION
     imports C-TRANSLATION-ERROR
     imports C-CHECK-LOC
     imports C-IO-DIRECT
     imports C-PROCESS-LABEL
     imports C-FUNCTION-DEF
     imports C-COMPOUND-LITERAL
     imports C-DYNAMIC-SYNTAX
     imports C-BUILTINS
     imports C-TRANSLATION-INIT

     imports C-DECLARATION-RESOLUTION
     imports C-DECLARATION-GLOBAL
     imports C-DECLARATION-LOCAL

     imports C-EXPRESSION-ASSIGNMENT
     imports C-EXPRESSION-FUNCTION-CALL
     imports C-EXPRESSION-ID-RVAL
     imports C-EXPRESSION-INC-AND-DEC
     imports C-EXPRESSION-SEQUENCING
     imports C-EXPRESSION-ADDITIVE-OPERATORS
     imports C-EXPRESSION-BITWISE
     imports C-EXPRESSION-CONVERSION
     imports C-EXPRESSION-IDENTIFIER
     imports C-EXPRESSION-LOGICAL
     imports C-EXPRESSION-MULTIPLICATIVE-OPERATORS
     imports C-EXPRESSION-RELATIONAL
     imports C-EXPRESSION-UNARY-ARITHMETIC

     imports C-SYMBOLIC-VALUE

     imports C-STATEMENT-BLOCK
     imports C-STATEMENT-BREAK
     imports C-STATEMENT-GOTO
     imports C-STATEMENT-IF-THEN
     imports C-STATEMENT-LABELED
     imports C-STATEMENT-LOOP
     imports C-STATEMENT-RETURN
     imports C-STATEMENT-SWITCH
endmodule
