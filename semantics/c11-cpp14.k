require "kast.k"
require "domains.k"

require "c/language/execution/execution.k"
require "c/language/common/common.k"
require "c/library/library.k"
require "c-settings.k"

require "cpp/language/execution/execution.k"
require "cpp/language/common/common.k"
require "cpp/library/library.k"
require "cpp-settings.k"

require "common/common.k"

module C11-SYNTAX
endmodule

module C11
     imports C11-SYNTAX
     imports C-EXECUTION
     imports C-COMMON
     imports C-LIBRARY
     imports COMMON
endmodule

module CPP14-SYNTAX
endmodule

module CPP14
     imports CPP14-SYNTAX
     imports CPP-EXECUTION
     imports CPP-COMMON
     imports CPP-LIBRARY
     imports COMMON
endmodule

module C11-CPP14-SYNTAX
     imports C11-SYNTAX
     imports CPP14-SYNTAX
endmodule

module C11-CPP14
     imports C11
     imports CPP14
endmodule
