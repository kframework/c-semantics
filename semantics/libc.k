require "library/bootstrap.k"
require "library/io.k"
require "library/math.k"
require "library/setjmp.k"
require "library/stdarg.k"
require "library/stddef.k"
require "library/stdio.k"
require "library/stdlib.k"
require "library/string.k"
require "library/threads.k"
require "library/time.k"

module LIBC-SYNTAX
endmodule

module LIBC
     ////////////////////////////////
     //- C standard library
     imports LIBC-BOOTSTRAP
     imports LIBC-IO
     
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
