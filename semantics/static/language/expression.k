require "expression/additive-operators.k"
require "expression/assignment.k"
require "expression/bitwise.k"
require "expression/cast.k"
require "expression/compound-literal.k"
require "expression/conditional.k"
require "expression/conversion.k"
require "expression/eval.k"
require "expression/function-call.k"
require "expression/identifier.k"
require "expression/inc-and-dec.k"
require "expression/literal.k"
require "expression/logical.k"
require "expression/members.k"
require "expression/multiplicative-operators.k"
require "expression/reference.k"
require "expression/relational.k"
require "expression/sequencing.k"
require "expression/sizeof.k"
require "expression/unary-arithmetic.k"

module C-EXPRESSION-SYNTAX
     syntax Value ::= "functionObject" "(" Id "," Type "," K ")"
     syntax Value ::= "functionPrototype" "(" Id "," Type ")"
     syntax K ::= "handleBuiltin" "(" Id "," Type ")"
     syntax K ::= "byteSizeofType" "(" Type ")"

     // generates a tv(size, cfg:sizeut)
     syntax K ::= "sizeofType" "(" K ")" [strict]
     syntax K ::= "populateFromGlobal"

     // TODO(chathhorn): hackish, rename at least
     syntax K ::= rkludge(K) [function, klabel('rkludge)]
     syntax K ::= pkludge(K) [function, klabel('pkludge)]

     // as described in 6.3 // totype, fromvalue
     syntax K ::= cast(K, K) [strict(1)]
endmodule

module C-EXPRESSION
     imports C-EXPRESSION-COMPOUND-LITERAL
     imports C-EXPRESSION-LOGICAL
     imports C-EXPRESSION-CONDITIONAL
     imports C-EXPRESSION-CONVERSION
     imports C-EXPRESSION-SIZEOF
     imports C-EXPRESSION-IDENTIFIER
     imports C-EXPRESSION-FUNCTION-CALL
     imports C-EXPRESSION-CAST
     imports C-EXPRESSION-EVAL
     imports C-EXPRESSION-ASSIGNMENT
     imports C-EXPRESSION-LITERAL
     imports C-EXPRESSION-BITWISE
     imports C-EXPRESSION-MULTIPLICATIVE-OPERATORS
     imports C-EXPRESSION-ADDITIVE-OPERATORS
     imports C-EXPRESSION-RELATIONAL
     imports C-EXPRESSION-UNARY-ARITHMETIC
     imports C-EXPRESSION-MEMBERS
     imports C-EXPRESSION-REFERENCE
     imports C-EXPRESSION-INC-AND-DEC
     imports C-EXPRESSION-SEQUENCING
endmodule
