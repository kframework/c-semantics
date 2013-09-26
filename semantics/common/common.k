require "syntax.k"
require "statement.k"

require "compat.k"
require "declaration.k"
require "bitsize.k"
require "bits.k"
require "typing.k"
require "literal.k"
require "compound-literal.k"
require "conversion.k"
require "promotion.k"
require "alloc.k"
require "symloc.k"

require "expression/multiplicative-operators.k"

module C-COMMON
     imports C-DECLARATION
     imports C-BITSIZE
     imports C-BITS
     imports C-TYPING
     imports C-LITERAL
     imports C-COMPOUND-LITERAL
     imports C-CONVERSION
     imports C-MEMORY-ALLOC
     imports C-SYMLOC
     imports C-PROMOTION

     imports C-EXPRESSION-MULTIPLICATIVE-OPERATORS
endmodule
