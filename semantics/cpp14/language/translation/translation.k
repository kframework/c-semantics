require "conversion.k"
require "elaborator.k"
require "env.k"
require "error.k"
require "init.k"
require "io.k"
require "name.k"
require "operators.k"
require "overloading.k"
require "process-label.k"
require "promotion.k"
require "syntax.k"
require "template-deduction.k"
require "value-category.k"
require "configuration.k"

require "decl/class.k"
require "decl/declarator.k"
require "decl/initializer.k"
require "decl/linkage.k"
require "decl/namespace.k"
require "decl/template.k"
require "decl/typedef.k"

require "expr/additive.k"
require "expr/alignof.k"
require "expr/assignment.k"
require "expr/bitwise.k"
require "expr/cast.k"
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
require "expr/throw.k"
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

require "cpp-extensions-translation.k"

module CPP-TRANSLATION
     imports CPP-TRANSLATION-CONVERSION
     imports CPP-ELABORATOR
     imports CPP-ENV
     imports CPP-TRANSLATION-ERROR
     imports CPP-TRANSLATION-INIT
     imports CPP-TRANSLATION-IO
     imports CPP-TRANSLATION-NAME
     imports CPP-OPERATORS
     imports CPP-OVERLOADING
     imports CPP-PROCESS-LABEL
     imports CPP-PROMOTION
     imports CPP-ABSTRACT-REWRITING
     imports CPP-TEMPLATE-DEDUCTION
     imports CPP-VALUE-CATEGORY

     imports CPP-DECL-CLASS
     imports CPP-DECL-DECLARATOR
     imports CPP-DECL-INITIALIZER
     imports CPP-DECL-LINKAGE
     imports CPP-DECL-NAMESPACE
     imports CPP-DECL-TEMPLATE
     imports CPP-DECL-TYPEDEF

     imports CPP-TRANSLATION-EXPR-ADDITIVE
     imports CPP-EXPR-ALIGNOF
     imports CPP-EXPR-ASSIGNMENT
     imports CPP-TRANSLATION-EXPR-BITWISE
     imports CPP-TRANSLATION-EXPR-CAST
     imports CPP-EXPR-CONDITIONAL
     imports CPP-TRANSLATION-EXPR-EVAL
     imports CPP-EXPR-FUNCTION-CALL
     imports CPP-EXPR-INC-AND-DEC
     imports CPP-EXPR-LITERAL
     imports CPP-EXPR-LOGICAL
     imports CPP-TRANSLATION-EXPR-MEMBERS
     imports CPP-TRANSLATION-EXPR-MULTIPLICATIVE
     imports CPP-EXPR-NEW
     imports CPP-EXPR-REFERENCE
     imports CPP-TRANSLATION-EXPR-RELATIONAL
     imports CPP-EXPR-SIZEOF
     imports CPP-EXPR-THROW
     imports CPP-TRANSLATION-EXPR-UNARY

     imports CPP-STMT-BLOCK
     imports CPP-STMT-CANONICALIZATION
     imports CPP-STMT-EXPR
     imports CPP-STMT-GOTO
     imports CPP-STMT-IF
     imports CPP-STMT-LABELED
     imports CPP-STMT-LOOP
     imports CPP-STMT-RETURN
     imports CPP-STMT-TRY

     imports CPP-TYPING-CANONICALIZATION
     imports CPP-TYPING-DEPENDENT
     imports CPP-TYPING-EXPR

     imports CPP-TRANSLATION-EXTENSIONS
endmodule
