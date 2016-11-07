require "error.k"
require "init.k"
require "resolution.k"
require "../c11/language/common/promotion.k"
require "../c11/language/common/typing/common.k"
require "../c11/language/common/typing/compatibility.k"
require "../c11/language/common/typing.k"
require "../c11/language/common/settings.k"
require "../c11/language/common/citations.k"
require "c-settings.k"

module C-LINKING
     imports TRANSLATION-ERROR
     imports C-LINKING-INIT
     imports C-LINKING-RESOLUTION
     imports C-COMMON-PROMOTION
     imports C-TYPING-COMMON
     imports C-TYPING-COMPATIBILITY
     imports C-SETTINGS
     imports C-CITATIONS
endmodule
