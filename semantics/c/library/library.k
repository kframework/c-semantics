require "builtin.k"
require "types.k"
require "io.k"
require "locale.k"
require "math.k"
require "native.k"
require "setjmp.k"
require "signal.k"
require "stdarg.k"
require "stdio.k"
require "stdlib.k"
require "string.k"
require "threads.k"
require "time.k"

module C-LIBRARY
     ////////////////////////////////
     //- C standard library
     imports LIBC-BUILTIN
     imports LIBC-IO

     imports LIBC-TYPES
     imports LIBC-LOCALE
     imports LIBC-MATH
     imports LIBC-SETJMP
     imports LIBC-SIGNAL
     imports LIBC-STDARG
     imports LIBC-STDIO
     imports LIBC-STDLIB
     imports LIBC-STRING
     imports LIBC-THREADS
     imports LIBC-TIME

     imports C-NATIVE-BRIDGE
endmodule
