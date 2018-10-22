require "../common/common.k"
require "error.k"
require "init.k"
require "resolution.k"
require "interface.k"
require "../c/language/common/alignment.k"
require "../c/language/common/promotion.k"
require "../c/language/common/typing/common.k"
require "../c/language/common/typing/compatibility.k"
require "../c/language/common/typing.k"
require "../c/language/common/settings.k"
require "c-settings.k"

module C-LINKING
     imports COMMON-LINKING-INTERFACE-SYNTAX
     imports TRANSLATION-ERROR
     imports C-LINKING-INIT
     imports C-LINKING-RESOLUTION
     imports C-ALIGNMENT
     imports C-COMMON-PROMOTION
     imports C-TYPING-COMMON
     imports C-TYPING-COMPATIBILITY
     imports C-SETTINGS
endmodule
