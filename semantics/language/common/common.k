require "alignment.k"
require "binding.k"
require "bitsize.k"
require "bits.k"
require "builtin.k"
require "compat.k"
require "conversion.k"
require "dynamic.k"
require "error.k"
require "promotion.k"
require "settings.k"
require "symloc.k"
require "syntax.k"
require "type-builder.k"
require "typing.k"

require "expr/additive.k"
require "expr/bitwise.k"
require "expr/cast.k"
require "expr/eval.k"
require "expr/members.k"
require "expr/multiplicative.k"
require "expr/reference.k"
require "expr/relational.k"
require "expr/unary.k"

require "memory/alloc.k"
require "memory/reading.k"
require "memory/writing.k"

require "extensions-common.k"

module C-COMMON
     imports C-ALIGNMENT
     imports C-BINDING
     imports C-BITS
     imports C-BITSIZE
     imports C-BUILTIN
     imports C-COMMON-PROMOTION
     imports C-CONVERSION
     imports C-DYNAMIC
     imports C-ERROR
     imports C-SETTINGS
     imports C-SYMLOC
     imports C-SYNTAX
     imports C-TYPE-BUILDER
     imports C-TYPING

     imports COMPAT

     imports C-COMMON-EXPR-ADDITIVE
     imports C-COMMON-EXPR-BITWISE
     imports C-COMMON-EXPR-CAST
     imports C-COMMON-EXPR-EVAL
     imports C-COMMON-EXPR-MEMBERS
     imports C-COMMON-EXPR-MULTIPLICATIVE
     imports C-COMMON-EXPR-REFERENCE
     imports C-COMMON-EXPR-RELATIONAL
     imports C-COMMON-EXPR-UNARY

     imports C-MEMORY-ALLOC
     imports C-MEMORY-READING
     imports C-MEMORY-WRITING

     imports C-COMMON-EXTENSIONS
endmodule
