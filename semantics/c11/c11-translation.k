require "kast.k"
require "domains.k"
require "language/translation/translation.k"
require "language/common/common.k"
require "../linking/linking.k"
require "../common/common.k"
require "c-settings.k"

module C11-TRANSLATION-SYNTAX
     imports C-ABSTRACT-SYNTAX
endmodule

module C11-TRANSLATION
     imports C11-TRANSLATION-SYNTAX
     imports C-TRANSLATION
     imports C-COMMON
     imports C-LINKING
     imports COMMON
endmodule
