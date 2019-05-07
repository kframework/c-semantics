require "kast.k"
require "domains.k"

require "cpp/linking.k"

require "c/linking.k"

require "linking/error.k"
require "linking/init.k"
require "linking/cpp-builtin.k"
require "linking/c-builtin.k"
require "linking/cpp-resolution.k"
require "linking/c-resolution.k"
require "linking/configuration.k"

require "common/common.k"

require "c-settings.k"
require "cpp-settings.k"
require "extensions-linking.k"

module C-CPP-LINKING-SYNTAX
endmodule

module C-CPP-LINKING
     imports CPP-LINKING

     imports C-CONFIGURATION
     imports C-LINKING

     imports LINKING-CPP-BUILTIN
     imports LINKING-CPP-RESOLUTION
     imports LINKING-C-BUILTIN
     imports LINKING-C-RESOLUTION
     imports LINKING-ERROR
     imports LINKING-INIT

     imports COMMON

     imports C-SETTINGS
     imports CPP-SETTINGS
     imports LINKING-EXTENSIONS
endmodule
