module CPP-TRANSLATION-EXPR-UNARY
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule *(pre(E::Expr, Tr::Trace, T:CPPPointerType))
          => le(* E, combine(Tr, #klabel(`*__CPP-SYNTAX`)), innerType(T))

     rule &(le(E::Expr, Tr::Trace, T::CPPType))
          => pre(& E, combine(Tr, #klabel(`&__CPP-SYNTAX`)), type(pointerType(T)))

     rule - (pre(E::Expr, Tr::Trace, T::CPPType))
          => pre(- E, combine(Tr, #klabel(`-__CPP-SYNTAX`)), T)
          requires isPromoted(T)

endmodule
