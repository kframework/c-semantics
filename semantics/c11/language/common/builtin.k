module C-BUILTIN-SYNTAX
     imports COMMON-BUILTIN-SYNTAX

     syntax Map ::= "builtins" [function]
                  | "extensionBuiltins" [function]

     syntax Type ::= "mtx_t" [function]
                   | "jmp_buf" [function]
                   | "va_list" [function]

endmodule

module C-BUILTIN
     imports C-BUILTIN-SYNTAX
     imports MAP
     imports C-SETTINGS-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX

     // Types for library functions defined in the semantics. These are the
     // definitive types against which all calls are checked for compatibility.
     rule builtins =>

          // stdlib
          "abort" |-> fun(void)
          "atexit" |-> fun(int, ptr(fun(void)))
          "at_quick_exit" |-> fun(int, ptr(fun(void)))
          "calloc" |-> fun(ptr(void), size_t, size_t)
          "__debug" |-> fun(void, int)
          "exit" |-> fun(void, int)
          "free" |-> fun(void, ptr(void))
          "malloc" |-> fun(ptr(void), size_t)
          "quick_exit" |-> fun(void, int)
          "rand" |-> fun(int)
          "realloc" |-> fun(ptr(void), ptr(void), size_t)
          "srand" |-> fun(void, unsigned-int)

          // math
          "asin" |-> fun(double, double)
          "atan2" |-> fun(double, double, double)
          "atan" |-> fun(double, double)
          "cos" |-> fun(double, double)
          "exp" |-> fun(double, double)
          "floor" |-> fun(double, double)
          "fmod" |-> fun(double, double, double)
          "log" |-> fun(double, double)
          "sin" |-> fun(double, double)
          "sqrt" |-> fun(double, double)
          "tan" |-> fun(double, double)

          // setjmp
          "longjmp" |-> noreturn(fun(void, jmp_buf, int))
          "__setjmp" |-> fun(int, jmp_buf)

          // threads
          "mtx_init" |-> fun(int, ptr(mtx_t), int)
          "mtx_lock" |-> fun(int, ptr(mtx_t))
          "mtx_unlock" |-> fun(int, ptr(mtx_t))
          "thrd_create" |-> fun(int, ptr(int), ptr(fun(int, ptr(void))), ptr(void))
          "thrd_current" |-> fun(int)
          "thrd_join" |-> fun(int, int, ptr(int))

          // stdio
          "__fslCloseFile" |-> fun(int, int)
          "__fslFGetC" |-> fun(int, int, unsigned-long-long-int)
          "__fslOpenFile" |-> fun(int, ptr(const(char)), ptr(const(char)))
          "__fslPutc" |-> fun(int, unsigned-char, int)
          "printf" |-> fun(int, restrict(ptr(const(char))), variadic)
          "snprintf" |-> fun(int, restrict(ptr(char)), size_t, restrict(ptr(const(char))), variadic)
          "sprintf" |-> fun(int, restrict(ptr(char)), restrict(ptr(const(char))), variadic)
          "vprintf" |-> fun(int, restrict(ptr(const(char))), va_list)
          "vsnprintf" |-> fun(int, restrict(ptr(char)), size_t, restrict(ptr(const(char))), va_list)
          "vsprintf" |-> fun(int, restrict(ptr(char)), restrict(ptr(const(char))), va_list)

          // string
          "strcpy" |-> fun(ptr(char), restrict(ptr(char)), restrict(ptr(const(char))))

          // stdarg
          "__va_copy" |-> fun(void, ptr(va_list), va_list)
          "va_end" |-> fun(void, va_list)
          "__va_inc" |-> fun(ptr(void), va_list)
          "__va_start" |-> fun(void, ptr(va_list), ptr(void))

          extensionBuiltins

     rule mtx_t => struct("__typeref_mtx_t")
     rule jmp_buf => ptr(cfg:ptrdiffut)
     rule va_list => type(cfg:ptrdiffut)

endmodule
