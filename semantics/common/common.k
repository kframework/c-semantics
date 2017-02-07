require "bits.k"
require "builtin.k"
require "compat.k"
require "configuration.k"
require "error.k"
require "init.k"
require "memory.k"
require "resolution.k"
require "settings.k"
require "symloc.k"
require "syntax.k"

module COMMON
  imports BITS
  imports COMMON-BUILTIN
  imports COMPAT
  imports ERROR
  imports COMMON-INIT
  imports MEMORY
  imports COMMON-RESOLUTION-SYNTAX
  imports SYMLOC
endmodule
