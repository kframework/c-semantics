require "kast.k"
require "domains.k"

require "c11/language/execution/execution.k"
require "c11/language/common/common.k"
require "c11/library/library.k"
require "c-settings.k"

require "cpp14/language/execution/execution.k"
require "cpp14/language/common/common.k"
require "cpp14/library/library.k"
require "cpp-settings.k"

module C11-SYNTAX
endmodule

module C11
     imports C11-SYNTAX
     imports C-EXECUTION
     imports C-COMMON
     imports C-LIBRARY
endmodule

module CPP14-SYNTAX
endmodule

module CPP14
     imports CPP14-SYNTAX
     imports CPP-EXECUTION
     imports CPP-COMMON
     imports CPP-LIBRARY
endmodule

module C11-CPP14-SYNTAX
     imports C11-SYNTAX
     imports CPP14-SYNTAX
endmodule

module C11-CPP14
     imports C11
     imports CPP14
endmodule
