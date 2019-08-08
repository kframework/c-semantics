module LIBC-CTYPE
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-NATIVE-BRIDGE-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-IO-SYNTAX

     syntax Bool ::= isCTypeFun(String) [function]
     rule isCTypeFun("isalnum") => true
     rule isCTypeFun("isalpha") => true
     rule isCTypeFun("isblank") => true
     rule isCTypeFun("iscntrl") => true
     rule isCTypeFun("isdigit") => true
     rule isCTypeFun("isgraph") => true
     rule isCTypeFun("islower") => true
     rule isCTypeFun("isprint") => true
     rule isCTypeFun("ispunct") => true
     rule isCTypeFun("isspace") => true
     rule isCTypeFun("isupper") => true
     rule isCTypeFun("isxdigit") => true
     rule isCTypeFun("tolower") => true
     rule isCTypeFun("toupper") => true
     rule isCTypeFun(_) => false [owise]

     rule builtin("isdigit", tv(V::Int, T::UType))
          => tv(1, int)
          requires (V ==K value(eof) orBool withinRange(V, unsigned-char))
               andBool (V >=Int 48 andBool V <=Int 57)
          [native-call]
     rule builtin("isdigit", tv(V::Int, T::UType))
          => tv(0, int)
          requires (V ==K value(eof) orBool withinRange(V, unsigned-char))
               andBool notBool (V >=Int 48 andBool V <=Int 57)
          [native-call]

     rule builtin(F::String, tv(V::Int, T::UType))
          => nativeCall(F, ListItem(tv(V, T)), .List)
          requires (V ==K value(eof) orBool withinRange(V, unsigned-char))
               andBool isCTypeFun(F)
               andBool F =/=String "isdigit"
          [native-call]
     rule (.K => outsideRange())
          ~> builtin(F::String, tv(V::Int, T::UType))
          requires notBool (V ==K value(eof) orBool withinRange(V, unsigned-char))
               andBool isCTypeFun(F)

     syntax KItem ::= outsideRange()
     rule (.K => UNDEF("CTYPE1", "Argument to " +String F +String " outside range representable by unsigned char (and not EOF)."))
          ~> outsideRange() ~> builtin(F::String, _)

endmodule
