require "language/common/common.k"

require "language/translation/constant.k"
require "language/translation/elaborator.k"
require "language/translation/env.k"
require "language/translation/implicit.k"
require "language/translation/name.k"
require "language/translation/odr.k"
require "language/translation/operators.k"
require "language/translation/overloading.k"
require "language/translation/process-label.k"
require "language/translation/syntax.k"
require "language/translation/template-deduction.k"
require "language/translation/value-category.k"
require "language/translation/decl/class.k"
require "language/translation/decl/declarator.k"
require "language/translation/decl/initializer.k"
require "language/translation/decl/template.k"
require "language/translation/decl/typedef.k"
require "language/translation/expr/conditional.k"
require "language/translation/expr/literal.k"
require "language/translation/expr/new.k"
require "language/translation/typing/dependent.k"
require "language/translation/typing/expr.k"

module CPP-LINKING
     imports CPP-COMMON

     imports CPP-TRANSLATION-ENV
     imports CPP-TRANSLATION-IMPLICIT
     imports CPP-TRANSLATION-ODR
     imports CPP-TRANSLATION-OVERLOADING
     imports CPP-TRANSLATION-VALUE-CATEGORY
     imports CPP-TRANSLATION-DECL-DECLARATOR
     imports CPP-TRANSLATION-DECL-TEMPLATE
     imports CPP-TRANSLATION-DECL-TYPEDEF
     imports CPP-TRANSLATION-EXPR-LITERAL
     imports CPP-TRANSLATION-TYPING-DEPENDENT
     imports CPP-TRANSLATION-TYPING-EXPR
endmodule
