require "bootstrap.k"
require "io.k"
require "math.k"
require "setjmp.k"
require "stdarg.k"
require "stdio.k"
require "stdlib.k"
require "string.k"
require "threads.k"
require "time.k"

module C-LIBRARY
     ////////////////////////////////
     //- C standard library
     imports LIBC-BOOTSTRAP
     imports LIBC-IO
     
     imports LIBC-MATH
     imports LIBC-SETJMP
     imports LIBC-STDARG
     imports LIBC-STDIO 
     imports LIBC-STDLIB
     imports LIBC-STRING
     imports LIBC-THREADS
     imports LIBC-TIME
endmodule
