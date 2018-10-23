require "kast.k"
require "domains.k"

require "c/language/common/common.k"
require "c/language/translation/configuration.k"
require "c/language/translation/translation.k"
require "c/library/types.k"

require "common/common.k"

require "c-settings.k"
require "c-extensions-translation.k"

module C11-TRANSLATION-SYNTAX
     imports C-ABSTRACT-SYNTAX
endmodule

module C11-TRANSLATION
     imports C11-TRANSLATION-SYNTAX

     imports C-COMMON
     imports C-CONFIGURATION
     imports C-TRANSLATION
     imports LIBC-TYPES

     imports COMMON

     imports C-SETTINGS
     imports C-TRANSLATION-EXTENSIONS
endmodule
