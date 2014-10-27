module C-BUILTIN-SYNTAX
     syntax Map ::= "builtins" [function]
     syntax K ::= "handleBuiltin"
endmodule

module C-BUILTIN
     imports C-BITS-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX

     // Types for library functions defined in the semantics. These are the
     // "definitive" types against which all calls are checked for
     // compatibility.
     rule builtins =>
          "__debug" |-> fun(void, int)
          "__fslCloseFile" |-> fun(int, int)
          "__fslFGetC" |-> fun(int, int, unsigned-long-long-int)
          "__fslOpenFile" |-> fun(int, ptr(const(char)), ptr(const(char)))
          "__fslPutc" |-> fun(int, char, int)
          "__va_copy" |-> fun(void, ptr(ptr(void)), ptr(void))
          "__va_end" |-> fun(void, ptr(ptr(void)))
          "__va_inc" |-> fun(ptr(void), ptr(ptr(void)), unsigned-int)
          "__va_start" |-> fun(void, ptr(ptr(void)), ptr(void))
          "abort" |-> fun(void)
          "asin" |-> fun(double, double)
          "atan" |-> fun(double, double)
          "atan2" |-> fun(double, double, double)
          "calloc" |-> fun(ptr(void), unsigned-int, unsigned-int)
          "cos" |-> fun(double, double)
          "exit" |-> fun(void, int)
          "exp" |-> fun(double, double)
          "floor" |-> fun(double, double)
          "fmod" |-> fun(double, double, double)
          "free" |-> fun(void, ptr(void))
          "getchar" |-> fun(int)
          "log" |-> fun(double, double)
          "longjmp" |-> fun(void, jmp_buf, int)
          "malloc" |-> fun(ptr(void), unsigned-int)
          "mtx_init" |-> fun(int, ptr(mtx_t), int)
          "mtx_lock" |-> fun(int, ptr(mtx_t))
          "mtx_unlock" |-> fun(int, ptr(mtx_t))
          "printf" |-> fun(int, restrict(ptr(const(char))), variadic)
          "putchar" |-> fun(int, int)
          "rand" |-> fun(int)
          "realloc" |-> fun(ptr(void), ptr(void), unsigned-int)
          "setjmp" |-> fun(int, jmp_buf)
          "sin" |-> fun(double, double)
          "snprintf" |-> fun(int, restrict(ptr(char)), unsigned-int, restrict(ptr(const(char))), variadic)
          "sprintf" |-> fun(int, restrict(ptr(char)), restrict(ptr(const(char))), variadic)
          "sqrt" |-> fun(double, double)
          "srand" |-> fun(void, unsigned-int)
          "strcpy" |-> fun(ptr(char), ptr(char), ptr(const(char)))
          "tan" |-> fun(double, double)
          "thrd_create" |-> fun(int, ptr(int), ptr(fun(int, ptr(void))), ptr(void))
          "thrd_current" |-> fun(int)
          "thrd_join" |-> fun(int, int, ptr(int))
          "time" |-> fun(long-long-int, ptr(long-long-int))

     syntax Type ::= "mtx_t" [function]
     rule mtx_t => struct("mtx_t_",
          field(int, "id")
          field(int, "type")
          field(int, "owner")
          field(int, "owned")
          field(int, "flag")
          field(int, "alive"))

     syntax Type ::= "jmp_buf" [function]
     rule jmp_buf => arr(struct("jmp_buf_", field(unsigned-char, "used")), 1)

     // Used by stddef.h.
     rule OffsetOf(T:KResult, K:K, Mem:K) => offsetOf(DeclType(T, K), Mem)
          [structural]

     syntax K ::= offsetOf(K, K) [strict(1)]
     syntax SymBase ::= "accum"
     rule offsetOf(T:Type, Mem:K)
          => toOffset(& ( offsetOf'(lv(loc(accum, 0), T), Mem) ))
          [structural]

     // Rejigger the AST.
     // TODO(chathhorn): array indexing?
     syntax K ::= "offsetOf'" "(" K "," K ")" [function]
     rule offsetOf'(K:K, K':K . F:CId) => offsetOf'(K, K') . F
     rule offsetOf'(K:K, F:CId) => K . F

     syntax K ::= toOffset(K) [strict]
     rule toOffset(tv(Loc:SymLoc, _)) => tv(offset(Loc), cfg:sizeut)
          [structural]

endmodule
