require "kast.k"
require "domains.k"
require "language/translation/translation.k"
require "language/common/common.k"
require "../linking/linking.k"
require "cpp-settings.k"

module CPP14-TRANSLATION-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
endmodule

module CPP14-TRANSLATION
     imports CPP14-TRANSLATION-SYNTAX
     imports CPP-TRANSLATION
     imports CPP-COMMON
     imports C-LINKING
     imports COMMON
     imports CPP-SETTINGS
endmodule
