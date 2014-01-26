require "syntax.k"
require "statement.k"

require "compat.k"
require "decl.k"
require "bitsize.k"
require "bits.k"
require "typing.k"
require "literal.k"
require "conversion.k"
require "promotion.k"
require "alloc.k"
require "symloc.k"
require "settings.k"

require "error.k"
require "error-map.k"
require "constraint-map.k"

require "memory.k"

require "expr/additive-operators.k"
require "expr/assignment.k"
require "expr/bitwise.k"
require "expr/cast.k"
require "expr/conditional.k"
require "expr/eval.k"
require "expr/identifier.k"
require "expr/members.k"
require "expr/multiplicative-operators.k"
require "expr/reference.k"
require "expr/relational.k"
require "expr/sizeof.k"
require "expr/unary-arithmetic.k"

require "dynamic.k"

require "debug.k"

module C-COMMON
     imports COMPAT

     imports C-DECL
     imports C-BITSIZE
     imports C-BITS
     imports C-TYPING
     imports C-LITERAL
     imports C-CONVERSION
     imports C-MEMORY-ALLOC
     imports C-SYMLOC
     imports C-PROMOTION
     imports C-SETTINGS

     imports C-ERROR
     imports C-ERROR-MAP
     imports C-CONSTRAINT-MAP

     imports C-MEMORY

     imports C-COMMON-EXPR-ADDITIVE-OPERATORS
     imports C-COMMON-EXPR-ASSIGNMENT
     imports C-COMMON-EXPR-BITWISE
     imports C-COMMON-EXPR-CAST
     imports C-COMMON-EXPR-CONDITIONAL
     imports C-COMMON-EXPR-EVAL
     imports C-COMMON-EXPR-IDENTIFIER
     imports C-COMMON-EXPR-MEMBERS
     imports C-COMMON-EXPR-MULTIPLICATIVE-OPERATORS
     imports C-COMMON-EXPR-REFERENCE
     imports C-COMMON-EXPR-RELATIONAL
     imports C-COMMON-EXPR-SIZEOF
     imports C-COMMON-EXPR-UNARY-ARITHMETIC

     imports C-DYNAMIC

     imports DEBUG

endmodule
