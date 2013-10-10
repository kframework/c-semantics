require "language/translation/translation.k"
require "language/common/common.k"

module C11-TRANS-SYNTAX
     imports C-SYNTAX
endmodule

module C11-TRANS
     imports C-SYNTAX
     imports C11-TRANSLATION
     imports C11-COMMON
endmodule
