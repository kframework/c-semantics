module CPP-TRANSLATION-EXPR-BITWISE
     imports BOOL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (L:PRVal ^ R:PRVal) #as O:Expr
          => pre(stripHold(L) ^ stripHold(R), combine(trace(L), trace(R), O), type(L))
          requires (isTExpr(L) orBool isTExpr(R))
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)

     rule (L:PRVal & R:PRVal) #as O:Expr
          => pre(stripHold(L) & stripHold(R), combine(trace(L), trace(R), O), type(L))
          requires (isTExpr(L) orBool isTExpr(R))
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)

     rule (L:PRVal | R:PRVal) #as O:Expr
          => pre(stripHold(L) | stripHold(R), combine(trace(L), trace(R), O), type(L))
          requires (isTExpr(L) orBool isTExpr(R))
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)

     rule (L:PRVal << R:PRVal) #as O:Expr
          => pre(stripHold(L) << stripHold(R), combine(trace(L), trace(R), O), type(L))
          requires (isTExpr(L) orBool isTExpr(R))
               andBool isPromoted(type(L)) andBool isPromoted(type(R))

     rule (L:PRVal >> R:PRVal) #as O:Expr
          => pre(stripHold(L) >> stripHold(R), combine(trace(L), trace(R), O), type(L))
          requires (isTExpr(L) orBool isTExpr(R))
               andBool isPromoted(type(L)) andBool isPromoted(type(R))


endmodule
