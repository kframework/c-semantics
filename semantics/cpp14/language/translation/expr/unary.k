module CPP-TRANSLATION-EXPR-UNARY
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule *(pre(E::Expr, Tr::Trace, T:CPPPointerType))
          => le(* E, combine(Tr, #klabel(`*__CPP-SYNTAX`)), innerType(T))

endmodule
