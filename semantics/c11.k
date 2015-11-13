require "language/execution/execution.k"
require "language/common/common.k"
require "library/library.k"
require "settings.k"

module C11-SYNTAX
endmodule

module C11
     imports C11-SYNTAX
     imports C-EXECUTION
     imports C-COMMON
     imports C-LIBRARY
endmodule
