module LIBC-SYNTAX
     imports C-DYNAMIC-SORTS
     imports COMMON-BUILTIN-SYNTAX
     imports C-TYPING-SORTS
     imports INT-SYNTAX
     imports LIST
     imports STRING-SYNTAX

     syntax Map ::= "builtins" [function]
                  | "extensionBuiltins" [function]

     syntax KItem ::= "initBuiltins"

     syntax Type ::= "mtx_t" [function]
                   | "jmp_buf" [function]
                   | "va_list" [function]
                   | "file" [function]
                   | "fpos_t" [function]
                   | "size_t" [function]

     syntax RValue ::= "eof" [function]

     syntax CValue ::= Opaque
     syntax EffectiveValue ::= Opaque
     syntax Opaque ::= opaque(Int, UType)

     syntax RValue ::= "stdin"  [function]
                     | "stdout" [function]
                     | "stderr" [function]

     syntax LValue ::= fileLVal(SymBase) [function]
     syntax LValue ::= filePtr(SymBase) [function]
     syntax Duration ::= "stdio"

endmodule

module LIBC-INIT
     imports BOOL-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX
     imports K-IO
     imports LIBC-SYNTAX
     imports MAP
     imports SYMLOC-SYNTAX

     // Types for library functions defined in the semantics. These are the
     // definitive types against which all calls are checked for compatibility.
     rule builtins =>

          // stdlib
          ("abort" |-> fun(void)
          ("atexit" |-> fun(int, ptr(fun(void)))
          ("at_quick_exit" |-> fun(int, ptr(fun(void)))
          ("calloc" |-> fun(ptr(void), size_t, size_t)
          ("__debug" |-> fun(void, int)
          ("exit" |-> fun(void, int)
          ("free" |-> fun(void, ptr(void))
          ("malloc" |-> fun(ptr(void), size_t)
          ("quick_exit" |-> fun(void, int)
          ("rand" |-> fun(int)
          ("realloc" |-> fun(ptr(void), ptr(void), size_t)
          ("srand" |-> fun(void, unsigned-int)
          ("strtod" |-> fun(double, ptr(const(char)), ptr(ptr(char)))
          ("strtof" |-> fun(float, ptr(const(char)), ptr(ptr(char)))
          ("strtold" |-> fun(long-double, ptr(const(char)), ptr(ptr(char)))

          // math
          ("asin" |-> fun(double, double)
          ("atan2" |-> fun(double, double, double)
          ("atan" |-> fun(double, double)
          ("cos" |-> fun(double, double)
          ("exp" |-> fun(double, double)
          ("floor" |-> fun(double, double)
          ("fmod" |-> fun(double, double, double)
          ("log" |-> fun(double, double)
          ("sin" |-> fun(double, double)
          ("sqrt" |-> fun(double, double)
          ("tan" |-> fun(double, double)

          // setjmp
          ("longjmp" |-> noreturn(fun(void, jmp_buf, int))
          ("__setjmp" |-> fun(int, jmp_buf)

          // threads
          ("mtx_init" |-> fun(int, ptr(mtx_t), int)
          ("mtx_lock" |-> fun(int, ptr(mtx_t))
          ("mtx_unlock" |-> fun(int, ptr(mtx_t))
          ("thrd_create" |-> fun(int, ptr(int), ptr(fun(int, ptr(void))), ptr(void))
          ("thrd_current" |-> fun(int)
          ("thrd_join" |-> fun(int, int, ptr(int))

          // stdio
          ("clearerr" |-> fun(void, ptr(file))
          ("fclose" |-> fun(int, ptr(file))
          ("feof" |-> fun(int, ptr(file))
          ("ferror" |-> fun(int, ptr(file))
          ("fflush" |-> fun(int, ptr(file))
          ("fgetc" |-> fun(int, ptr(file))
          ("fgetpos" |-> fun(int, restrict(ptr(file)), restrict(ptr(fpos_t)))
          ("fgets" |-> fun(ptr(char), ptr(char), int, ptr(file))
          ("fileno" |-> fun(int, ptr(file))
          ("fopen" |-> fun(ptr(file), restrict(ptr(const(char))), restrict(ptr(const(char))))
          ("fprintf" |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), variadic)
          ("fputc" |-> fun(int, int, ptr(file))
          ("fputs" |-> fun(int, restrict(ptr(const(char))), restrict(ptr(file)))
          ("fread" |-> fun(size_t, restrict(ptr(void)), size_t, size_t, restrict(ptr(file)))
          ("freopen" |-> fun(ptr(file), restrict(ptr(const(char))), restrict(ptr(const(char))), restrict(ptr(file)))
          ("fscanf" |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), variadic)
          ("fseek" |-> fun(int, ptr(file), long-int, int)
          ("fsetpos" |-> fun(int, ptr(file), ptr(const(fpos_t)))
          ("ftell" |-> fun(long-int, ptr(file))
          ("fwrite" |-> fun(size_t, restrict(ptr(const(void))), size_t, size_t, restrict(ptr(file)))
          ("getc" |-> fun(int, ptr(file))
          ("getchar" |-> fun(int)
          ("gets" |-> fun(ptr(char), ptr(char))
          ("_IO_getc" |-> fun(int, ptr(file))
          ("_IO_putc" |-> fun(int, int, ptr(file))
          ("__isoc99_fscanf" |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), variadic)
          ("__isoc99_scanf" |-> fun(int, restrict(ptr(const(char))), variadic)
          ("__isoc99_sscanf" |-> fun(int, restrict(ptr(const(char))), restrict(ptr(const(char))), variadic)
          ("__isoc99_vfscanf" |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), va_list)
          ("__isoc99_vscanf" |-> fun(int, restrict(ptr(const(char))), va_list)
          ("__isoc99_vsscanf" |-> fun(int, restrict(ptr(const(char))), restrict(ptr(const(char))), va_list)
          ("printf" |-> fun(int, restrict(ptr(const(char))), variadic)
          ("putc" |-> fun(int, int, ptr(file))
          ("putchar" |-> fun(int, int)
          ("puts" |-> fun(int, ptr(const(char)))
          ("rewind" |-> fun(void, ptr(file))
          ("scanf" |-> fun(int, restrict(ptr(const(char))), variadic)
          ("setbuffer" |-> fun(int, restrict(ptr(file)), restrict(ptr(char)), size_t)
          ("setbuf" |-> fun(void, restrict(ptr(file)), restrict(ptr(char)))
          ("setlinebuf" |-> fun(void, restrict(ptr(file)))
          ("setvbuf" |-> fun(int, restrict(ptr(file)), restrict(ptr(char)), int, size_t)
          ("snprintf" |-> fun(int, restrict(ptr(char)), size_t, restrict(ptr(const(char))), variadic)
          ("sprintf" |-> fun(int, restrict(ptr(char)), restrict(ptr(const(char))), variadic)
          ("sscanf" |-> fun(int, restrict(ptr(const(char))), restrict(ptr(const(char))), variadic)
          ("stderr" |-> ptr(file)
          ("stdin" |-> ptr(file)
          ("stdout" |-> ptr(file)
          ("tmpfile" |-> fun(ptr(file))
          ("tmpnam" |-> fun(ptr(char), ptr(char))
          ("ungetc" |-> fun(int, int, ptr(file))
          ("vfprintf" |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), va_list)
          ("vfscanf" |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), va_list)
          ("vprintf" |-> fun(int, restrict(ptr(const(char))), va_list)
          ("vscanf" |-> fun(int, restrict(ptr(const(char))), va_list)
          ("vsnprintf" |-> fun(int, restrict(ptr(char)), size_t, restrict(ptr(const(char))), va_list)
          ("vsprintf" |-> fun(int, restrict(ptr(char)), restrict(ptr(const(char))), va_list)
          ("vsscanf" |-> fun(int, restrict(ptr(const(char))), restrict(ptr(const(char))), va_list)

          // string
          ("strcpy" |-> fun(ptr(char), restrict(ptr(char)), restrict(ptr(const(char))))

          // stdarg
          ("__va_copy" |-> fun(void, ptr(va_list), va_list)
          ("va_end" |-> fun(void, va_list)
          ("__va_inc" |-> fun(ptr(void), va_list)
          ("__va_start" |-> fun(void, ptr(va_list), ptr(void))

          extensionBuiltins
          // we need these parentheses to avoid an exponential explosion of parsing time;
          // really should look further into true priorities in the parser kernel.
          ))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))

     rule mtx_t => struct("__typeref_mtx_t")
     rule jmp_buf => ptr(cfg:ptrdiffut)
     rule va_list => type(cfg:ptrdiffut)
     rule file => struct("__typeref_file")
     rule fpos_t => struct("__typeref_fpos_t")

     rule size_t => type(cfg:sizeut)

     rule eof => tv(-1, utype(int))

     rule initBuiltins => initStdio

     rule isStaticDuration(_ @ stdio) => true

     syntax KItem ::= "initStdio" [function]
     rule initStdio
          => alloc(!Stdin:Int @ static("builtin"), file, byteSizeofType(file))
          ~> allowInit(Computation(fileLVal(!Stdin @ static("builtin")) := stdin))
          ~> alloc(builtinSymbol("stdin"), type(pointerType(file)), byteSizeofType(type(pointerType(file))))
          ~> allowInit(Computation(filePtr(builtinSymbol("stdin")) := & fileLVal(!Stdin @ static("builtin"))))

          ~> alloc(!Stdout:Int @ static("builtin"), file, byteSizeofType(file))
          ~> allowInit(Computation(fileLVal(!Stdout @ static("builtin")) := stdout))
          ~> alloc(builtinSymbol("stdout"), type(pointerType(file)), byteSizeofType(type(pointerType(file))))
          ~> allowInit(Computation(filePtr(builtinSymbol("stdout")) := & fileLVal(!Stdout @ static("builtin"))))

          ~> alloc(!Stderr:Int @ static("builtin"), file, byteSizeofType(file))
          ~> allowInit(Computation(fileLVal(!Stderr @ static("builtin")) := stderr))
          ~> alloc(builtinSymbol("stderr"), type(pointerType(file)), byteSizeofType(type(pointerType(file))))
          ~> allowInit(Computation(filePtr(builtinSymbol("stderr")) := & fileLVal(!Stderr @ static("builtin"))))

     rule fileLVal(Base::SymBase) => lv(lnew(Base, file), file)
     rule filePtr(Base::SymBase) => lv(lnew(Base, file), type(pointerType(file)))

     rule stdin  => tv(opaque(#stdin, utype(file)), utype(file))
     rule stdout => tv(opaque(#stdout, utype(file)), utype(file))
     rule stderr => tv(opaque(#stderr, utype(file)), utype(file))

endmodule

