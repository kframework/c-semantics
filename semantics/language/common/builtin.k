module C-BUILTIN-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax Map ::= "builtins" [function]
                  | "semanticsDefinedBuiltins" [function]
                  | "nativeDefinedBuiltins"[function]
     syntax KItem ::= "handleBuiltin"
                    | handleBuiltinConstant(CId, Type)
endmodule

module C-BUILTIN
     imports C-BITS-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports COMPAT-SYNTAX

     rule builtins => semanticsDefinedBuiltins nativeDefinedBuiltins

     syntax Map ::= #nativeDefinedBuiltins(Set) [function, hook(C_SEMANTICS.nativeFunctions), impure]
     rule nativeDefinedBuiltins => #nativeDefinedBuiltins(keys(semanticsDefinedBuiltins))

     // defined as a K rule for if the hook is not defined
     rule #nativeDefinedBuiltins(_) => .Map

     // Types for library functions defined in the semantics. These are the
     // "definitive" types against which all calls are checked for
     // compatibility.
     rule semanticsDefinedBuiltins =>
          "__debug" |-> fun(void, int)
          "__fslCloseFile" |-> fun(int, int)
          "__fslFGetC" |-> fun(int, int, unsigned-long-long-int)
          "__fslOpenFile" |-> fun(int, ptr(const(char)), ptr(const(char)))
          "__fslPutc" |-> fun(int, unsigned-char, int)
          "__va_copy" |-> fun(void, ptr(ptr(void)), ptr(void))
          "__va_end" |-> fun(void, ptr(ptr(void)))
          "__va_inc" |-> fun(ptr(void), ptr(ptr(void)), cfg:sizeut)
          "__va_start" |-> fun(void, ptr(ptr(void)), ptr(void))
          "abort" |-> fun(void)
          "asin" |-> fun(double, double)
          "atan" |-> fun(double, double)
          "atan2" |-> fun(double, double, double)
          "calloc" |-> fun(ptr(void), cfg:sizeut, cfg:sizeut)
          "cos" |-> fun(double, double)
          "exit" |-> fun(void, int)
          "exp" |-> fun(double, double)
          "floor" |-> fun(double, double)
          "fmod" |-> fun(double, double, double)
          "free" |-> fun(void, ptr(void))
          "log" |-> fun(double, double)
          "longjmp" |-> fun(void, jmp_buf, int)
          "malloc" |-> fun(ptr(void), cfg:sizeut)
          "mtx_init" |-> fun(int, ptr(mtx_t), int)
          "mtx_lock" |-> fun(int, ptr(mtx_t))
          "mtx_unlock" |-> fun(int, ptr(mtx_t))
          "printf" |-> fun(int, restrict(ptr(const(char))), variadic)
          "rand" |-> fun(int)
          "realloc" |-> fun(ptr(void), ptr(void), cfg:sizeut)
          "setjmp" |-> fun(int, jmp_buf)
          "sin" |-> fun(double, double)
          "snprintf" |-> fun(int, restrict(ptr(char)), cfg:sizeut, restrict(ptr(const(char))), variadic)
          "sprintf" |-> fun(int, restrict(ptr(char)), restrict(ptr(const(char))), variadic)
          "sqrt" |-> fun(double, double)
          "srand" |-> fun(void, unsigned-int)
          "strcpy" |-> fun(ptr(char), restrict(ptr(char)), restrict(ptr(const(char))))
          "tan" |-> fun(double, double)
          "thrd_create" |-> fun(int, ptr(int), ptr(fun(int, ptr(void))), ptr(void))
          "thrd_current" |-> fun(int)
          "thrd_join" |-> fun(int, int, ptr(int))

     syntax Type ::= "mtx_t" [function]
     rule mtx_t => struct("mtx_t_")

     syntax Type ::= "jmp_buf" [function]
     rule jmp_buf => arr(struct("__jmp_buf_tag"), 1)

endmodule
