require "../common/common.k"
require "error.k"
require "init.k"
require "resolution.k"
require "interface.k"
require "../c11/language/common/alignment.k"
require "../c11/language/common/promotion.k"
require "../c11/language/common/typing/common.k"
require "../c11/language/common/typing/compatibility.k"
require "../c11/language/common/typing.k"
require "../c11/language/common/settings.k"
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
