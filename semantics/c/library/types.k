module LIBC-TYPES-SYNTAX
     syntax Map ::= "builtins" [function]
                  | "extensionBuiltins" [function]

     syntax Type ::= "mtx_t" [function]
                   | "jmp_buf" [function]
                   | "va_list" [function]
                   | "file" [function]
                   | "fpos_t" [function]
                   | "lconv" [function]
                   | "sighandler_t" [function]
                   | "size_t" [function]
endmodule

module LIBC-TYPES
     imports BOOL-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-TYPES-SYNTAX
     imports MAP

     // Types for library functions defined in the semantics. These are the
     // definitive types against which all calls are checked for compatibility.
     rule builtins =>

          // stdlib
          (id("abort") |-> fun(void)
          (id("aligned_alloc") |-> fun(ptr(void), size_t, size_t)
          (id("atexit") |-> fun(int, ptr(fun(void)))
          (id("at_quick_exit") |-> fun(int, ptr(fun(void)))
          (id("calloc") |-> fun(ptr(void), size_t, size_t)
          (id("exit") |-> fun(void, int)
          (id("free") |-> fun(void, ptr(void))
          (id("getenv") |-> fun(ptr(char), ptr(const(char)))
          (id("malloc") |-> fun(ptr(void), size_t)
          (id("quick_exit") |-> fun(void, int)
          (id("rand") |-> fun(int)
          (id("realloc") |-> fun(ptr(void), ptr(void), size_t)
          (id("secure_getenv") |-> fun(ptr(char), ptr(const(char)))
          (id("srand") |-> fun(void, unsigned-int)
          (id("strtod") |-> fun(double, ptr(const(char)), ptr(ptr(char)))
          (id("strtof") |-> fun(float, ptr(const(char)), ptr(ptr(char)))
          (id("strtold") |-> fun(long-double, ptr(const(char)), ptr(ptr(char)))

          // ctype
          (id("isalnum") |-> fun(int, int)
          (id("isalpha") |-> fun(int, int)
          (id("isblank") |-> fun(int, int)
          (id("iscntrl") |-> fun(int, int)
          (id("isdigit") |-> fun(int, int)
          (id("isgraph") |-> fun(int, int)
          (id("islower") |-> fun(int, int)
          (id("isprint") |-> fun(int, int)
          (id("ispunct") |-> fun(int, int)
          (id("isspace") |-> fun(int, int)
          (id("isupper") |-> fun(int, int)
          (id("isxdigit") |-> fun(int, int)
          (id("tolower") |-> fun(int, int)
          (id("toupper") |-> fun(int, int)

          // locale
          (id("setlocale") |-> fun(ptr(char), int, ptr(const(char)))
          (id("localeconv") |-> fun(ptr(lconv))

          // math
          (id("asin") |-> fun(double, double)
          (id("atan2") |-> fun(double, double, double)
          (id("atan") |-> fun(double, double)
          (id("cos") |-> fun(double, double)
          (id("exp") |-> fun(double, double)
          (id("floor") |-> fun(double, double)
          (id("fmod") |-> fun(double, double, double)
          (id("log") |-> fun(double, double)
          (id("sin") |-> fun(double, double)
          (id("sqrt") |-> fun(double, double)
          (id("tan") |-> fun(double, double)

          // setjmp
          (id("longjmp") |-> noreturn(fun(void, jmp_buf, int))
          (id("_setjmp") |-> fun(int, jmp_buf)

          // signal
          (id("raise") |-> fun(int, int)
          (id("signal") |-> fun(sighandler_t, int, sighandler_t)

          // threads
          (id("mtx_init") |-> fun(int, ptr(mtx_t), int)
          (id("mtx_lock") |-> fun(int, ptr(mtx_t))
          (id("mtx_unlock") |-> fun(int, ptr(mtx_t))
          (id("thrd_create") |-> fun(int, ptr(int), ptr(fun(int, ptr(void))), ptr(void))
          (id("thrd_current") |-> fun(int)
          (id("thrd_join") |-> fun(int, int, ptr(int))

          // stdio
          (id("asprintf") |-> fun(int, restrict(ptr(ptr(char))), restrict(ptr(const(char))), variadic)
          (id("clearerr") |-> fun(void, ptr(file))
          (id("fclose") |-> fun(int, ptr(file))
          (id("feof") |-> fun(int, ptr(file))
          (id("ferror") |-> fun(int, ptr(file))
          (id("fflush") |-> fun(int, ptr(file))
          (id("fgetc") |-> fun(int, ptr(file))
          (id("fgetpos") |-> fun(int, restrict(ptr(file)), restrict(ptr(fpos_t)))
          (id("fgets") |-> fun(ptr(char), ptr(char), int, ptr(file))
          (id("fileno") |-> fun(int, ptr(file))
          (id("fopen") |-> fun(ptr(file), restrict(ptr(const(char))), restrict(ptr(const(char))))
          (id("fprintf") |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), variadic)
          (id("fputc") |-> fun(int, int, ptr(file))
          (id("fputs") |-> fun(int, restrict(ptr(const(char))), restrict(ptr(file)))
          (id("fread") |-> fun(size_t, restrict(ptr(void)), size_t, size_t, restrict(ptr(file)))
          (id("freopen") |-> fun(ptr(file), restrict(ptr(const(char))), restrict(ptr(const(char))), restrict(ptr(file)))
          (id("fscanf") |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), variadic)
          (id("fseek") |-> fun(int, ptr(file), long-int, int)
          (id("fsetpos") |-> fun(int, ptr(file), ptr(const(fpos_t)))
          (id("ftell") |-> fun(long-int, ptr(file))
          (id("fwrite") |-> fun(size_t, restrict(ptr(const(void))), size_t, size_t, restrict(ptr(file)))
          (id("getc") |-> fun(int, ptr(file))
          (id("getchar") |-> fun(int)
          (id("gets") |-> fun(ptr(char), ptr(char))
          (id("_IO_getc") |-> fun(int, ptr(file))
          (id("_IO_putc") |-> fun(int, int, ptr(file))
          (id("__isoc99_fscanf") |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), variadic)
          (id("__isoc99_scanf") |-> fun(int, restrict(ptr(const(char))), variadic)
          (id("__isoc99_sscanf") |-> fun(int, restrict(ptr(const(char))), restrict(ptr(const(char))), variadic)
          (id("__isoc99_vfscanf") |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), va_list)
          (id("__isoc99_vscanf") |-> fun(int, restrict(ptr(const(char))), va_list)
          (id("__isoc99_vsscanf") |-> fun(int, restrict(ptr(const(char))), restrict(ptr(const(char))), va_list)
          (id("printf") |-> fun(int, restrict(ptr(const(char))), variadic)
          (id("putc") |-> fun(int, int, ptr(file))
          (id("putchar") |-> fun(int, int)
          (id("puts") |-> fun(int, ptr(const(char)))
          (id("rewind") |-> fun(void, ptr(file))
          (id("scanf") |-> fun(int, restrict(ptr(const(char))), variadic)
          (id("setbuffer") |-> fun(int, restrict(ptr(file)), restrict(ptr(char)), size_t)
          (id("setbuf") |-> fun(void, restrict(ptr(file)), restrict(ptr(char)))
          (id("setlinebuf") |-> fun(void, restrict(ptr(file)))
          (id("setvbuf") |-> fun(int, restrict(ptr(file)), restrict(ptr(char)), int, size_t)
          (id("snprintf") |-> fun(int, restrict(ptr(char)), size_t, restrict(ptr(const(char))), variadic)
          (id("sprintf") |-> fun(int, restrict(ptr(char)), restrict(ptr(const(char))), variadic)
          (id("sscanf") |-> fun(int, restrict(ptr(const(char))), restrict(ptr(const(char))), variadic)
          (id("stderr") |-> ptr(file)
          (id("stdin") |-> ptr(file)
          (id("stdout") |-> ptr(file)
          (id("tmpfile") |-> fun(ptr(file))
          (id("tmpnam") |-> fun(ptr(char), ptr(char))
          (id("ungetc") |-> fun(int, int, ptr(file))
          (id("vasprintf") |-> fun(int, restrict(ptr(ptr(char))), restrict(ptr(const(char))), va_list)
          (id("vfprintf") |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), va_list)
          (id("vfscanf") |-> fun(int, restrict(ptr(file)), restrict(ptr(const(char))), va_list)
          (id("vprintf") |-> fun(int, restrict(ptr(const(char))), va_list)
          (id("vscanf") |-> fun(int, restrict(ptr(const(char))), va_list)
          (id("vsnprintf") |-> fun(int, restrict(ptr(char)), size_t, restrict(ptr(const(char))), va_list)
          (id("vsprintf") |-> fun(int, restrict(ptr(char)), restrict(ptr(const(char))), va_list)
          (id("vsscanf") |-> fun(int, restrict(ptr(const(char))), restrict(ptr(const(char))), va_list)

          // string
          (id("memset") |-> fun(ptr(void), ptr(void), int, size_t)
          (id("strcpy") |-> fun(ptr(char), restrict(ptr(char)), restrict(ptr(const(char))))
          (id("strerror") |-> fun(ptr(char), int)
          (id("strerror_r") |-> fun(int, int, ptr(char), size_t)
          (id("__xpg_strerror_r") |-> fun(int, int, ptr(char), size_t)
          (id("strlen") |-> fun(size_t, ptr(const(char)))

          // stdarg
          (id("__kcc_va_copy") |-> fun(void, ptr(va_list), va_list)
          (id("__kcc_va_end") |-> fun(void, va_list)
          (id("__kcc_va_inc") |-> fun(ptr(void), va_list)
          (id("__kcc_va_start") |-> fun(void, ptr(va_list), ptr(void))

          // errno
          (id("errno") |-> type(int)

          // klee helpers
          (id("__kcc_get_obj_size") |-> fun(int, ptr(void))

          extensionBuiltins
          // we need these parentheses to avoid an exponential explosion of parsing time;
          // really should look further into true priorities in the parser kernel.
          )))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))

     rule mtx_t => typeref("__kcc_typeref_mtx_t")
     rule jmp_buf => typeref("__kcc_typeref_jmp_buf")
     rule va_list => typeref("__kcc_typeref_va_list")
     rule file => typeref("__kcc_typeref_file")
     rule fpos_t => typeref("__kcc_typeref_fpos_t")
     rule lconv => typeref("__kcc_typeref_lconv")
     rule sighandler_t => ptr(fun(void, int))
     rule size_t => type(cfg:sizeut)

endmodule

