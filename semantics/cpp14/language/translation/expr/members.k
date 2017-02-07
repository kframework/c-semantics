module CPP-TRANSLATION-EXPR-MEMBERS
     imports CPP-EXPR-MEMBERS
     imports CPP-ABSTRACT-SYNTAX

     rule fieldExp(le(E::Expr, Trace::Trace, _), N::Name, T::CPPType, _)
          => le(E . no-template N, Trace, T)
endmodule
