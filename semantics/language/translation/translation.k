require "syntax.k"

require "annotation.k"
require "compound-literal.k"
require "configuration.k"
require "elaborator.k"
require "env.k"
require "error.k"
require "function-def.k"
require "init.k"
require "io-direct.k"
require "literal.k"
require "process-label.k"
require "promotion.k"

require "decl/definition.k"
require "decl/global.k"
require "decl/initializer.k"
require "decl/local.k"
require "decl/resolution.k"
require "decl/tagged.k"
require "decl/typedef.k"

require "expr/additive.k"
require "expr/alignof.k"
require "expr/assignment.k"
require "expr/bitwise.k"
require "expr/cast.k"
require "expr/conditional.k"
require "expr/eval.k"
require "expr/function-call.k"
require "expr/identifier.k"
require "expr/inc-and-dec.k"
require "expr/logical.k"
require "expr/members.k"
require "expr/multiplicative.k"
require "expr/offsetof.k"
require "expr/reference.k"
require "expr/relational.k"
require "expr/sequencing.k"
require "expr/sizeof.k"
require "expr/unary.k"

require "stmt/block.k"
require "stmt/break.k"
require "stmt/goto.k"
require "stmt/if-then.k"
require "stmt/labeled.k"
require "stmt/loop.k"
require "stmt/return.k"
require "stmt/static-assert.k"
require "stmt/switch.k"

require "typing/canonicalization.k"
require "typing/interpretation.k"
require "typing/expr.k"

require "../../extensions-translation.k"

module C-TRANSLATION
     imports C-DYNAMIC-SYNTAX

     imports C-ANNOTATION
     imports C-COMPOUND-LITERAL
     imports C-CONFIGURATION
     imports C-ELABORATOR
     imports C-ENV
     imports C-FUNCTION-DEF
     imports C-IO-DIRECT
     imports C-LITERAL
     imports C-PROCESS-LABEL
     imports C-PROMOTION
     imports C-TRANSLATION-ERROR
     imports C-TRANSLATION-INIT

     imports C-DECL-DEFINITION
     imports C-DECL-GLOBAL
     imports C-DECL-INITIALIZER
     imports C-DECL-LOCAL
     imports C-DECL-RESOLUTION
     imports C-DECL-TAGGED
     imports C-DECL-TYPEDEF

     imports C-EXPR-ADDITIVE
     imports C-EXPR-ALIGNOF
     imports C-EXPR-ASSIGNMENT
     imports C-EXPR-BITWISE
     imports C-EXPR-CAST
     imports C-EXPR-CONDITIONAL
     imports C-EXPR-EVAL
     imports C-EXPR-FUNCTION-CALL
     imports C-EXPR-IDENTIFIER
     imports C-EXPR-INC-AND-DEC
     imports C-EXPR-LOGICAL
     imports C-EXPR-MEMBERS
     imports C-EXPR-MULTIPLICATIVE
     imports C-EXPR-OFFSETOF
     imports C-EXPR-REFERENCE
     imports C-EXPR-RELATIONAL
     imports C-EXPR-SEQUENCING
     imports C-EXPR-SIZEOF
     imports C-EXPR-UNARY

     imports C-STMT-BLOCK
     imports C-STMT-BREAK
     imports C-STMT-GOTO
     imports C-STMT-IF-THEN
     imports C-STMT-LABELED
     imports C-STMT-LOOP
     imports C-STMT-RETURN
     imports C-STMT-STATIC-ASSERT
     imports C-STMT-SWITCH

     imports C-TYPING-CANONICALIZATION
     imports C-TYPING-INTERPRETATION
     imports C-TYPING-EXPR

     imports C-TRANSLATION-EXTENSIONS
endmodule
