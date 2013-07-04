require "configuration.k"
require "settings.k"
require "ltlmc.k"
require "error.k"
require "compat.k"

require "libc.k"

require "language/dynamic.k"

module C11-SYNTAX
     imports C-SYNTAX
     imports C11-LTLMC-SYNTAX
endmodule

module C11
     imports COMPAT

     imports C11-CONFIGURATION
     imports C11-SETTINGS
     imports C11-LTLMC
     imports C11-ERROR

     imports C
     imports LIBC
endmodule
