require "configuration.k"
require "settings.k"
require "ltlmc.k"
require "error.k"
require "compat.k"

require "libc.k"

require "c/dynamic.k"

module C11-SYNTAX
     imports C-SYNTAX
endmodule

module C11
     imports COMPAT

     imports LIBC

     imports C11-CONFIGURATION
     imports C11-SETTINGS
     imports C11-LTLMC
     imports C11-ERROR

     imports C-DYNAMIC
endmodule
