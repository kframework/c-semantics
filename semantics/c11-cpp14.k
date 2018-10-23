require "kast.k"
require "domains.k"

require "c/language/common/common.k"
require "c/language/execution/configuration.k"
require "c/language/execution/execution.k"
require "c/library/library.k"
require "c-settings.k"

require "cpp/language/execution/execution.k"
require "cpp/language/common/common.k"
require "cpp/library/library.k"
require "cpp-settings.k"

require "common/common.k"
require "common/execution/execution.k"

require "c-settings.k"
require "cpp-settings.k"
require "extensions-execution.k"

module C11-CPP14-SYNTAX
endmodule

module C11-CPP14
     imports CPP-COMMON
     imports CPP-EXECUTION
     imports CPP-LIBRARY

     imports C-COMMON
     imports C-CONFIGURATION
     imports C-EXECUTION
     imports C-LIBRARY

     imports COMMON
     imports COMMON-EXECUTION

     imports C-SETTINGS
     imports CPP-SETTINGS
     imports EXECUTION-EXTENSIONS
endmodule
