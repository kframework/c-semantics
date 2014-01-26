module C-BUILTINS-SYNTAX

     syntax Set ::= "builtins" [function]

endmodule

module C-BUILTINS
     imports C-BUILTINS-SYNTAX

     // This set prevents our "linker" from choking due to unresolved
     // references.
     rule builtins =>
          SetItem("__debug")
          SetItem("__fslCloseFile")
          SetItem("__fslFGetC")
          SetItem("__fslOpenFile")
          SetItem("__fslPutc")
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
          SetItem("isalnum")
          SetItem("isalpha")
          SetItem("isblank")
          SetItem("iscntrl")
          SetItem("isdigit")
          SetItem("isgraph")
          SetItem("islower")
          SetItem("ispunct")
          SetItem("isspace")
          SetItem("isupper")
          SetItem("isxdigit")
          SetItem("log")
          SetItem("malloc")
          SetItem("printf")
          SetItem("putchar")
          SetItem("rand")
          SetItem("realloc")
          SetItem("sin")
          SetItem("snprintf")
          SetItem("sprintf")
          SetItem("sqrt")
          SetItem("srand")
          SetItem("strcpy")
          SetItem("tan")
          SetItem("tolower")
          SetItem("toupper")

endmodule
