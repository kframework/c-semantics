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

require "symbolic/function-call.k"
require "symbolic/id-rval.k"
require "symbolic/inc-and-dec.k"
require "symbolic/sequencing.k"

require "symbolic/additive-operators.k"
require "symbolic/bitwise.k"
require "symbolic/conversion.k"
require "symbolic/identifier.k"
require "symbolic/logical.k"
require "symbolic/multiplicative-operators.k"
require "symbolic/relational.k"
require "symbolic/unary-arithmetic.k"
require "symbolic/value.k"

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

     imports C-SYMBOLIC-FUNCTION-CALL
     imports C-SYMBOLIC-ID-RVAL
     imports C-SYMBOLIC-INC-AND-DEC
     imports C-SYMBOLIC-SEQUENCING

     imports C-SYMBOLIC-ADDITIVE-OPERATORS
     imports C-SYMBOLIC-BITWISE
     imports C-SYMBOLIC-CONVERSION
     imports C-SYMBOLIC-IDENTIFIER
     imports C-SYMBOLIC-LOGICAL
     imports C-SYMBOLIC-MULTIPLICATIVE-OPERATORS
     imports C-SYMBOLIC-RELATIONAL
     imports C-SYMBOLIC-UNARY-ARITHMETIC
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
