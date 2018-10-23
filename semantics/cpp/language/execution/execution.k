require "conversion.k"
require "error.k"
require "init.k"

require "simple-execution.k"

// C/C++ compatability
require "stmt/return-from-c.k"
require "expr/function-call-to-c.k"

module CPP-EXECUTION
     imports CPP-SIMPLE-EXECUTION
     imports CPP-EXECUTION-CONVERSION
     imports CPP-EXECUTION-ERROR
     imports CPP-EXECUTION-INIT

     // C/C++ interoperability
     imports C-CPP-EXECUTION-STMT-RETURN
     imports C-CPP-EXECUTION-EXPR-FUNCTION-CALL
     imports C-CPP-EXECUTION-VAL-CONVERSION
endmodule
