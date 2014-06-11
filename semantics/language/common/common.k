require "binding.k"
require "bitsize.k"
require "bits.k"
require "builtin.k"
require "compat.k"
require "conversion.k"
require "debug.k"
require "dynamic.k"
require "env.k"
require "error.k"
require "literal.k"
require "promotion.k"
require "settings.k"
require "symloc.k"
require "syntax.k"
require "type-builder.k"
require "typing.k"

require "decl/definition.k"
require "decl/enum.k"
require "decl/initializer.k"
require "decl/tagged.k"
require "decl/typedef.k"
require "decl/zero.k"

require "expr/additive.k"
require "expr/alignof.k"
require "expr/assignment.k"
require "expr/bitwise.k"
require "expr/cast.k"
require "expr/conditional.k"
require "expr/eval.k"
require "expr/members.k"
require "expr/multiplicative.k"
require "expr/reference.k"
require "expr/relational.k"
require "expr/sizeof.k"
require "expr/unary.k"

require "memory/alloc.k"
require "memory/reading.k"
require "memory/writing.k"

module C-COMMON
     imports C-BINDING
     imports C-BITSIZE
     imports C-BITS
     imports C-BUILTIN
     imports COMPAT
     imports C-CONVERSION
     imports C-DYNAMIC
     imports C-ENV
     imports C-ERROR
     imports C-LITERAL
     imports C-PROMOTION
     imports C-SETTINGS
     imports C-SYMLOC
     imports C-SYNTAX
     imports C-TYPE-BUILDER
     imports C-TYPING

     imports C-DECL-DEFINITION
     imports C-DECL-ENUM
     imports C-DECL-INITIALIZER
     imports C-DECL-TAGGED
     imports C-DECL-TYPEDEF
     imports C-DECL-ZERO

     imports C-COMMON-EXPR-ADDITIVE
     imports C-COMMON-EXPR-ALIGNOF
     imports C-COMMON-EXPR-ASSIGNMENT
     imports C-COMMON-EXPR-BITWISE
     imports C-COMMON-EXPR-CAST
     imports C-COMMON-EXPR-CONDITIONAL
     imports C-COMMON-EXPR-EVAL
     imports C-COMMON-EXPR-MEMBERS
     imports C-COMMON-EXPR-MULTIPLICATIVE
     imports C-COMMON-EXPR-REFERENCE
     imports C-COMMON-EXPR-RELATIONAL
     imports C-COMMON-EXPR-SIZEOF
     imports C-COMMON-EXPR-UNARY

     imports C-MEMORY-ALLOC
     imports C-MEMORY-READING
     imports C-MEMORY-WRITING
endmodule
