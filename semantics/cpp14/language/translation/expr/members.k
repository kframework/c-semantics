module CPP-TRANSLATION-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     context CallExpr(HOLE:Expr . _ _, _)

     rule fieldExp(le(E::Expr, Trace::Trace, _), N::Name, T::CPPType, _)
          => le(E . no-template N, Trace, T)
endmodule
