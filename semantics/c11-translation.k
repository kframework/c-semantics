require "language/translation/translation.k"
require "language/common/common.k"

module C11-TRANSLATION-SYNTAX
     imports C-ABSTRACT-SYNTAX
endmodule

module C11-TRANSLATION
     imports C11-TRANSLATION-SYNTAX
     imports C-TRANSLATION
     imports C-COMMON
endmodule
