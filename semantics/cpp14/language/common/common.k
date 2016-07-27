require "binding.k"
require "bitsize.k"
require "conversion.k"
require "dynamic.k"
require "error.k"
require "symloc.k"
require "syntax.k"
require "typing.k"

require "expr/eval.k"
require "expr/unary.k"

require "memory/alloc.k"
require "memory/reading.k"
require "memory/writing.k"

require "stmt/expr.k"

require "cpp-extensions-common.k"

module CPP-COMMON
     imports CPP-BINDING
     imports CPP-BITSIZE
     imports CPP-CONVERSION
     imports CPP-DYNAMIC
     imports CPP-ERROR
     imports CPP-SYMLOC
     imports CPP-SYNTAX
     imports C-CPP-TYPING

     imports CPP-EXPR-EVAL
     imports CPP-EXPR-UNARY

     imports CPP-MEMORY-ALLOC
     imports CPP-MEMORY-READING
     imports CPP-MEMORY-WRITING

     imports CPP-COMMON-STMT-EXPR

     imports CPP-COMMON-EXTENSIONS
endmodule
