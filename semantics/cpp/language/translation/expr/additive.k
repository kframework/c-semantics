module CPP-TRANSLATION-EXPR-ADDITIVE
     imports BOOL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule L:PRVal + R:PRVal => pre(stripHold(L) + stripHold(R), combine(trace(L), trace(R), #klabel(`_+__CPP-SYNTAX`)), type(L))
          requires (isPRExpr(L) orBool isPRExpr(R))
               andBool (isCPPIntegerType(type(L)) orBool isCPPFloatingType(type(L)))
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)

     rule L:PRVal + R:PRVal => pre(stripHold(L) + stripHold(R), combine(trace(L), trace(R), #klabel(`_+__CPP-SYNTAX`)), type(L))
          requires (isPRExpr(L) orBool isPRExpr(R))
               andBool isCPPPointerType(type(L)) andBool isCPPIntegerType(type(R))
                    andBool isCompleteType(innerType(type(L)))
                    andBool isObjectType(innerType(type(L)))

     rule L:PRVal + R:PRVal => pre(stripHold(L) + stripHold(R), combine(trace(L), trace(R), #klabel(`_+__CPP-SYNTAX`)), type(R))
          requires (isPRExpr(L) orBool isPRExpr(R))
               andBool isCPPPointerType(type(R)) andBool isCPPIntegerType(type(L))
                    andBool isCompleteType(innerType(type(R)))
                    andBool isObjectType(innerType(type(R)))

     rule L:PRVal - R:PRVal => pre(stripHold(L) - stripHold(R), combine(trace(L), trace(R), #klabel(`_-__CPP-SYNTAX`)), type(ptrdiff_t))
          requires (isPRExpr(L) orBool isPRExpr(R))
               andBool isCPPPointerType(type(L)) andBool isCPPPointerType(type(R))

     rule L:PRVal - R:PRVal => pre(stripHold(L) - stripHold(R), combine(trace(L), trace(R), #klabel(`_-__CPP-SYNTAX`)), type(L))
          requires (isPRExpr(L) orBool isPRExpr(R))
               andBool (isCPPIntegerType(type(L)) orBool isCPPFloatingType(type(L)))
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)

     rule L:PRVal - R:PRVal => pre(stripHold(L) - stripHold(R), combine(trace(L), trace(R), #klabel(`_-__CPP-SYNTAX`)), type(L))
          requires (isPRExpr(L) orBool isPRExpr(R))
               andBool isCPPPointerType(type(L)) andBool isCPPIntegerType(type(R))
                    andBool isCompleteType(innerType(type(L)))
                    andBool isObjectType(innerType(type(L)))

endmodule
