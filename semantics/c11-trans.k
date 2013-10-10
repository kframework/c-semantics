require "language/translation/translation.k"
require "language/common/common.k"

module C11-SYNTAX
     imports C-SYNTAX
endmodule

module C11
     imports C-SYNTAX
     imports C11-TRANSLATION
     imports C11-COMMON
endmodule
