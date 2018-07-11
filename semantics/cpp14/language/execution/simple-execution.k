// Parts of the execution semantics that:
// (1) do not depend on C semantics
// (2) may be used for compile-time function evaluation

//require "conversion.k"

require "binding.k"
require "env.k"
require "io.k"

require "decl/declarator.k"
require "decl/initializer.k"

require "expr/expr.k"
require "stmt/stmt.k"

module CPP-SIMPLE-EXECUTION
     imports CPP-EXECUTION-STMT
     imports CPP-EXECUTION-EXPR

     imports CPP-EXECUTION-BINDING
     imports CPP-EXECUTION-ENV
     imports CPP-EXECUTION-DECL-DECLARATOR
     imports CPP-EXECUTION-DECL-INITIALIZER
     imports CPP-EXECUTION-IO

endmodule
