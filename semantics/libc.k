require "libc/bootstrap.k"
require "libc/math.k"
require "libc/setjmp.k"
require "libc/stdarg.k"
require "libc/stddef.k"
require "libc/stdio.k"
require "libc/stdlib.k"
require "libc/string.k"
require "libc/threads.k"
require "libc/time.k"

module LIBC-SYNTAX
endmodule

module LIBC
     ////////////////////////////////
     //- C standard library
     imports LIBC-BOOTSTRAP
     
     imports LIBC-MATH
     imports LIBC-SETJMP
     imports LIBC-STDARG
     imports LIBC-STDDEF
     imports LIBC-STDIO 
     imports LIBC-STDLIB
     imports LIBC-STRING
     imports LIBC-THREADS
     imports LIBC-TIME
endmodule
