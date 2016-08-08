require "elaborator.k"
require "env.k"
require "init.k"
require "io.k"
require "overloading.k"
require "process-label.k"
require "syntax.k"
require "configuration.k"

require "decl/declarator.k"
require "decl/initializer.k"
require "decl/linkage.k"
require "decl/namespace.k"
require "decl/typedef.k"

require "expr/assignment.k"
require "expr/function-call.k"
require "expr/literal.k"
require "expr/name.k"

require "stmt/block.k"
require "stmt/canonicalization.k"
require "stmt/expr.k"
require "stmt/labeled.k"
require "stmt/return.k"

require "typing/canonicalization.k"
require "typing/expr.k"

require "cpp-extensions-translation.k"

module CPP-TRANSLATION
     imports CPP-ELABORATOR
     imports CPP-ENV
     imports CPP-TRANSLATION-INIT
     imports CPP-TRANSLATION-IO
     imports CPP-OVERLOADING
     imports CPP-PROCESS-LABEL

     imports CPP-DECL-DECLARATOR
     imports CPP-DECL-INITIALIZER
     imports CPP-DECL-LINKAGE
     imports CPP-DECL-NAMESPACE
     imports CPP-DECL-TYPEDEF

     imports CPP-EXPR-ASSIGNMENT
     imports CPP-EXPR-FUNCTION-CALL
     imports CPP-EXPR-NAME
     imports CPP-EXPR-LITERAL

     imports CPP-STMT-BLOCK
     imports CPP-STMT-CANONICALIZATION
     imports CPP-STMT-EXPR
     imports CPP-STMT-LABELED
     imports CPP-STMT-RETURN

     imports CPP-TYPING-CANONICALIZATION
     imports CPP-TYPING-EXPR

     imports CPP-TRANSLATION-EXTENSIONS
endmodule
