module LIBC-CTYPE
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-NATIVE-BRIDGE-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-IO-SYNTAX

     syntax Bool ::= isNativeCTypeFun(String) [function]
     rule isNativeCTypeFun("isalnum") => true
     rule isNativeCTypeFun("isalpha") => true
     rule isNativeCTypeFun("isblank") => true
     rule isNativeCTypeFun("iscntrl") => true
     rule isNativeCTypeFun("isdigit") => true
     rule isNativeCTypeFun("isgraph") => true
     rule isNativeCTypeFun("islower") => true
     rule isNativeCTypeFun("isprint") => true
     rule isNativeCTypeFun("ispunct") => true
     rule isNativeCTypeFun("isspace") => true
     rule isNativeCTypeFun("isupper") => true
     rule isNativeCTypeFun("isxdigit") => true
     rule isNativeCTypeFun("tolower") => true
     rule isNativeCTypeFun("toupper") => true
     rule isNativeCTypeFun(_) => false [owise]

     rule builtin(F::String, tv(V:Int, T::UType))
          => nativeCall(F, ListItem(tv(V, T)), .List)
          requires isNativeCTypeFun(F)
               andBool (V ==K value(eof) orBool withinRange(V, unsigned-char))
          [native-call]
     rule (.K => outsideRange())
          ~> builtin(F::String, tv(V::Int, T::UType))
          requires isNativeCTypeFun(F)
               andBool notBool (V ==K value(eof) orBool withinRange(V, unsigned-char))

     syntax KItem ::= outsideRange()
     rule (.K => UNDEF("CTYPE1", "Argument to " +String F +String " outside range representable by unsigned char (and not EOF)."))
          ~> outsideRange() ~> builtin(F::String, _)

endmodule
