require "language/execution/execution.k"
require "language/common/common.k"
require "library/library.k"

module C11-SYNTAX
     imports C-SYNTAX
     imports C11-LTLMC-SYNTAX
endmodule

module C11
     imports C11-SYNTAX
     imports C11-EXECUTION
     imports C11-COMMON
     imports C11-LIBRARY
endmodule
