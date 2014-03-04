module C-BUILTIN-SYNTAX

     syntax Set ::= "builtins" [function]
     syntax Value ::= builtinPrototype(Id, Type)
     syntax K ::= handleBuiltin(Id, Type)

endmodule

module C-BUILTIN
     imports C-BUILTIN-SYNTAX

     // This set prevents our "linker" from choking due to unresolved
     // references.
     rule builtins =>
          SetItem("__debug")
          SetItem("__fslCloseFile")
          SetItem("__fslFGetC")
          SetItem("__fslOpenFile")
          SetItem("__fslPutc")
          SetItem("__va_copy")
          SetItem("__va_end")
          SetItem("__va_inc")
          SetItem("__va_start")
          SetItem("abort")
          SetItem("asin")
          SetItem("atan")
          SetItem("atan2")
          SetItem("calloc")
          SetItem("cos")
          SetItem("exit")
          SetItem("exp")
          SetItem("floor")
          SetItem("fmod")
          SetItem("free")
          SetItem("getchar")
          SetItem("log")
          SetItem("longjmp")
          SetItem("malloc")
          SetItem("mtx_init")
          SetItem("mtx_lock")
          SetItem("mtx_unlock")
          SetItem("printf")
          SetItem("putchar")
          SetItem("rand")
          SetItem("realloc")
          SetItem("setjmp")
          SetItem("sin")
          SetItem("snprintf")
          SetItem("sprintf")
          SetItem("sqrt")
          SetItem("srand")
          SetItem("strcpy")
          SetItem("tan")
          SetItem("thrd_create")
          SetItem("thrd_current")
          SetItem("thrd_join")
          SetItem("time")

endmodule
