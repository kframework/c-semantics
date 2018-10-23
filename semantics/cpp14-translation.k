require "kast.k"
require "domains.k"

require "cpp/language/common/common.k"
require "cpp/language/execution/simple-execution.k"
require "cpp/language/translation/configuration.k"
require "cpp/language/translation/translation.k"

require "c/language/common/error.k"
require "c/language/common/settings.k"
require "c/language/common/typing/common.k"
require "c/language/common/typing.k"
require "c/language/execution/check-restrict.k"
require "c/language/execution/sequence-point.k"

require "common/common.k"
require "common/execution/execution.k"

require "c-settings.k"
require "cpp-settings.k"
require "cpp-extensions-translation.k"

module CPP14-TRANSLATION-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
endmodule

module CPP14-TRANSLATION
     imports CPP14-TRANSLATION-SYNTAX
     imports CPP-COMMON
     imports CPP-SIMPLE-EXECUTION
     imports CPP-TRANSLATION

     imports C-CHECK-RESTRICT
     imports C-CONFIGURATION
     imports C-ERROR
     imports C-SEQUENCE-POINT
     imports C-TYPING-COMMON

     imports COMMON
     imports COMMON-EXECUTION

     imports C-SETTINGS
     imports CPP-SETTINGS
     imports CPP-TRANSLATION-EXTENSIONS
endmodule
