require "kast.k"
require "domains.k"
require "language/translation/translation.k"
require "language/common/common.k"
require "library/init.k"
require "../linking/linking.k"
require "c-settings.k"

module C11-TRANSLATION-SYNTAX
     imports C-ABSTRACT-SYNTAX
endmodule

module C11-TRANSLATION
     imports C11-TRANSLATION-SYNTAX
     imports C-COMMON
     imports C-LINKING
     imports COMMON
     imports C-TRANSLATION
     imports LIBC-INIT
endmodule
