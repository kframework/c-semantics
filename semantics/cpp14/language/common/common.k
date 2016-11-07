require "alignment.k"
require "binding.k"
require "bitsize.k"
require "builtin.k"
require "conversion.k"
require "dynamic.k"
require "error.k"
require "promotion-context.k"
require "reference.k"
require "settings.k"
require "symloc.k"
require "syntax.k"
require "typing.k"
require "citations.k"

require "expr/additive.k"
require "expr/bitwise.k"
require "expr/cast.k"
require "expr/eval.k"
require "expr/multiplicative.k"
require "expr/relational.k"
require "expr/unary.k"

require "memory/alloc.k"
require "memory/reading.k"
require "memory/writing.k"

require "stmt/expr.k"

require "cpp-extensions-common.k"

module CPP-COMMON
     imports CPP-ALIGNMENT
     imports CPP-BINDING
     imports CPP-BITSIZE
     imports CPP-BUILTIN
     imports CPP-CONVERSION
     imports CPP-DYNAMIC
     imports CPP-ERROR
     imports CPP-COMMON-PROMOTION-CONTEXT
     imports CPP-REFERENCE
     imports CPP-SYMLOC
     imports C-CPP-TYPING
     imports CPP-CITATIONS

     imports CPP-SETTINGS

     imports CPP-EXPR-ADDITIVE
     imports CPP-EXPR-BITWISE
     imports CPP-EXPR-CAST
     imports CPP-EXPR-EVAL
     imports CPP-EXPR-MULTIPLICATIVE
     imports CPP-EXPR-RELATIONAL
     imports CPP-EXPR-UNARY

     imports CPP-MEMORY-ALLOC
     imports CPP-MEMORY-READING
     imports CPP-MEMORY-WRITING

     imports CPP-COMMON-STMT-EXPR

     imports CPP-COMMON-EXTENSIONS
endmodule
