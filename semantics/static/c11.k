require "configuration.k"
require "settings.k"
require "error.k"
require "error-map.k"

require "language/dynamic.k"

require "../common/common.k"

module C11-SYNTAX
     imports C-SYNTAX
endmodule

module C11
     imports COMPAT

     imports C11-CONFIGURATION
     imports C11-SETTINGS

     imports C11-ERROR
     imports C11-ERROR-MAP

     imports C
endmodule
