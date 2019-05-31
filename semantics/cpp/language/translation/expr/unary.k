module CPP-TRANSLATION-EXPR-UNARY
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (*(pre(E::Expr, Tr::Trace, t(... st: pointerType(...)) #as T::CPPType))) #as O:Expr
          => le(* E, combine(Tr, O), innerType(T))

     rule (&(le(E::Expr, Tr::Trace, T::CPPType))) #as O:Expr
          => pre(& E, combine(Tr, O), type(pointerType(T)))

     rule getAddress(E:TExpr)
          => pre(getAddress(stripHold(E)), combine(trace(E), & E), type(pointerType(type(E))))

     rule (- (pre(E::Expr, Tr::Trace, T::CPPType))) #as O:Expr
          => pre(- E, combine(Tr, O), T)
          requires isPromoted(T)

endmodule
