require "alignment.k"
require "bits.k"
require "builtin.k"
require "compat.k"
require "configuration.k"
require "error.k"
require "init.k"
require "linking-deps.k"
require "memory.k"
require "options.k"
require "settings.k"
require "symloc.k"
require "syntax.k"
require "translation-unit.k"

module COMMON
     imports ALIGNMENT
     imports BITS
     imports COMMON-BUILTIN
     imports COMMON-INIT
     imports COMMON-LINKING-DEPS
     imports COMMON-TRANSLATION-UNIT
     imports COMPAT
     imports ERROR
     imports OPTIONS
     imports SYMLOC
endmodule
