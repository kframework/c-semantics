module CPP-TYPING-CANONICALIZATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule BuiltinType(Int()) => t(noQuals, .Set, int) [anywhere]
     rule BuiltinType(Char()) => t(noQuals, .Set, char) [anywhere]

     rule PointerType(T::CPPType) => t(noQuals, .Set, pointerType(T)) [anywhere]

     rule Qualifier(Q::Qualifier, t(Quals::Quals, Mods::Set, S::CPPSimpleType)) => t(Quals +Qual Q, Mods, S) [anywhere]

     rule FunctionPrototype(T::CPPType, Args::List, Excepts::List, Noexcept::Expr, true) => FunctionPrototype(T, Args ListItem(variadic), Excepts, Noexcept, false) [anywhere]
     rule FunctionPrototype(T::CPPType, Args::List, Excepts::List, Noexcept::Expr, false) => t(noQuals, .Set, functionType(T, Args, proto(Excepts, Noexcept), DefaultLinkage)) [anywhere]

endmodule
