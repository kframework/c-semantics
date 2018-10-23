require "constant.k"
require "conversion.k"
require "elaborator.k"
require "env.k"
require "error.k"
require "implicit.k"
require "init.k"
require "io.k"
require "linking-interface.k"
require "name.k"
require "odr.k"
require "operators.k"
require "overloading.k"
require "process-label.k"
require "promotion.k"
require "syntax.k"
require "template-deduction.k"
require "value-category.k"

require "decl/class.k"
require "decl/declarator.k"
require "decl/enum.k"
require "decl/initializer.k"
require "decl/linkage.k"
require "decl/namespace.k"
require "decl/template.k"
require "decl/typedef.k"
require "decl/using.k"

require "expr/additive.k"
require "expr/alignof.k"
require "expr/assignment.k"
require "expr/bitwise.k"
require "expr/cast.k"
require "expr/comma.k"
require "expr/conditional.k"
require "expr/function-call.k"
require "expr/eval.k"
require "expr/inc-and-dec.k"
require "expr/literal.k"
require "expr/logical.k"
require "expr/members.k"
require "expr/multiplicative.k"
require "expr/new.k"
require "expr/reference.k"
require "expr/relational.k"
require "expr/sizeof.k"
require "expr/unary.k"

require "stmt/block.k"
require "stmt/canonicalization.k"
require "stmt/expr.k"
require "stmt/goto.k"
require "stmt/if.k"
require "stmt/labeled.k"
require "stmt/loop.k"
require "stmt/return.k"
require "stmt/try.k"

require "typing/canonicalization.k"
require "typing/dependent.k"
require "typing/expr.k"

module CPP-TRANSLATION

     imports CPP-LINKING-INTERFACE

     imports CPP-TRANSLATION-CONVERSION
     imports CPP-TRANSLATION-ELABORATOR
     imports CPP-TRANSLATION-ENV
     imports CPP-TRANSLATION-CONSTANT
     imports CPP-TRANSLATION-ERROR
     imports CPP-TRANSLATION-IMPLICIT
     imports CPP-TRANSLATION-INIT
     imports CPP-TRANSLATION-IO
     imports CPP-TRANSLATION-NAME
     imports CPP-TRANSLATION-ODR
     imports CPP-TRANSLATION-OPERATORS
     imports CPP-TRANSLATION-OVERLOADING
     imports CPP-TRANSLATION-PROCESS-LABEL
     imports CPP-TRANSLATION-PROMOTION
     imports CPP-TRANSLATION-ABSTRACT-REWRITING
     imports CPP-TRANSLATION-TEMPLATE-DEDUCTION
     imports CPP-TRANSLATION-VALUE-CATEGORY

     imports CPP-TRANSLATION-DECL-CLASS
     imports CPP-TRANSLATION-DECL-ENUM
     imports CPP-TRANSLATION-DECL-DECLARATOR
     imports CPP-TRANSLATION-DECL-INITIALIZER
     imports CPP-TRANSLATION-DECL-LINKAGE
     imports CPP-TRANSLATION-DECL-NAMESPACE
     imports CPP-TRANSLATION-DECL-TEMPLATE
     imports CPP-TRANSLATION-DECL-TYPEDEF
     imports CPP-TRANSLATION-DECL-USING

     imports CPP-TRANSLATION-EXPR-ADDITIVE
     imports CPP-TRANSLATION-EXPR-ALIGNOF
     imports CPP-TRANSLATION-EXPR-ASSIGNMENT
     imports CPP-TRANSLATION-EXPR-BITWISE
     imports CPP-TRANSLATION-EXPR-CAST
     imports CPP-TRANSLATION-EXPR-COMMA
     imports CPP-TRANSLATION-EXPR-CONDITIONAL
     imports CPP-TRANSLATION-EXPR-EVAL
     imports CPP-TRANSLATION-EXPR-FUNCTION-CALL
     imports CPP-TRANSLATION-EXPR-INC-AND-DEC
     imports CPP-TRANSLATION-EXPR-LITERAL
     imports CPP-TRANSLATION-EXPR-LOGICAL
     imports CPP-TRANSLATION-EXPR-MEMBERS
     imports CPP-TRANSLATION-EXPR-MULTIPLICATIVE
     imports CPP-TRANSLATION-EXPR-NEW
     imports CPP-TRANSLATION-EXPR-REFERENCE
     imports CPP-TRANSLATION-EXPR-RELATIONAL
     imports CPP-TRANSLATION-EXPR-SIZEOF
     imports CPP-TRANSLATION-EXPR-UNARY

     imports CPP-TRANSLATION-STMT-BLOCK
     imports CPP-TRANSLATION-STMT-CANONICALIZATION
     imports CPP-TRANSLATION-STMT-EXPR
     imports CPP-TRANSLATION-STMT-GOTO
     imports CPP-TRANSLATION-STMT-IF
     imports CPP-TRANSLATION-STMT-LABELED
     imports CPP-TRANSLATION-STMT-LOOP
     imports CPP-TRANSLATION-STMT-RETURN
     imports CPP-TRANSLATION-STMT-TRY

     imports CPP-TRANSLATION-TYPING-CANONICALIZATION
     imports CPP-TRANSLATION-TYPING-DEPENDENT
     imports CPP-TRANSLATION-TYPING-EXPR

endmodule
