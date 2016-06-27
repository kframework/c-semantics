module C-BUILTIN-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMMON-BUILTIN-SYNTAX

     syntax Map ::= "builtins" [function]
                  | "extensionBuiltins" [function]

     syntax Type ::= "mtx_t" [function]
                   | "jmp_buf" [function]
                   | "va_list" [function]

endmodule

module C-BUILTIN
     imports C-BITS-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports COMPAT-SYNTAX

     // Types for library functions defined in the semantics. These are the
     // definitive types against which all calls are checked for compatibility.
     rule builtins =>
          "abort" |-> fun(void)
          "asin" |-> fun(double, double)
          "atan2" |-> fun(double, double, double)
          "atan" |-> fun(double, double)
          "atexit" |-> fun(int, ptr(fun(void)))
          "at_quick_exit" |-> fun(int, ptr(fun(void)))
          "calloc" |-> fun(ptr(void), size_t, size_t)
          "cos" |-> fun(double, double)
          "__debug" |-> fun(void, int)
          "exit" |-> fun(void, int)
          "exp" |-> fun(double, double)
          "floor" |-> fun(double, double)
          "fmod" |-> fun(double, double, double)
          "free" |-> fun(void, ptr(void))
          "__fslCloseFile" |-> fun(int, int)
          "__fslFGetC" |-> fun(int, int, unsigned-long-long-int)
          "__fslOpenFile" |-> fun(int, ptr(const(char)), ptr(const(char)))
          "__fslPutc" |-> fun(int, unsigned-char, int)
          "log" |-> fun(double, double)
          "longjmp" |-> fun(void, jmp_buf, int)
          "malloc" |-> fun(ptr(void), size_t)
          "mtx_init" |-> fun(int, ptr(mtx_t), int)
          "mtx_lock" |-> fun(int, ptr(mtx_t))
          "mtx_unlock" |-> fun(int, ptr(mtx_t))
          "printf" |-> fun(int, restrict(ptr(const(char))), variadic)
          "quick_exit" |-> fun(void, int)
          "rand" |-> fun(int)
          "realloc" |-> fun(ptr(void), ptr(void), size_t)
          "setjmp" |-> fun(int, jmp_buf)
          "sin" |-> fun(double, double)
          "snprintf" |-> fun(int, restrict(ptr(char)), size_t, restrict(ptr(const(char))), variadic)
          "sprintf" |-> fun(int, restrict(ptr(char)), restrict(ptr(const(char))), variadic)
          "sqrt" |-> fun(double, double)
          "srand" |-> fun(void, unsigned-int)
          "strcpy" |-> fun(ptr(char), restrict(ptr(char)), restrict(ptr(const(char))))
          "tan" |-> fun(double, double)
          "thrd_create" |-> fun(int, ptr(int), ptr(fun(int, ptr(void))), ptr(void))
          "thrd_current" |-> fun(int)
          "thrd_join" |-> fun(int, int, ptr(int))
          "__va_copy" |-> fun(void, ptr(va_list), va_list)
          "va_end" |-> fun(void, va_list)
          "__va_inc" |-> fun(ptr(void), va_list)
          "__va_start" |-> fun(void, ptr(va_list), ptr(void))
          "vsnprintf" |-> fun(int, restrict(ptr(char)), size_t, restrict(ptr(const(char))), va_list)
          extensionBuiltins

     rule mtx_t => struct("__typeref_mtx_t")
     rule jmp_buf => arr(struct("__typeref_jmp_buf"), 1)
     rule va_list => type(cfg:ptrdiffut)

endmodule
