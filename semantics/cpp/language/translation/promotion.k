module CPP-TRANSLATION-PROMOTION
     imports BOOL
     imports CPP-DYNAMIC-SORTS
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax ResolvedExpr ::= arithBinConversionOp(Expr, Expr)
     rule arithBinConversionOp(L::Expr, R::Expr)
         => ((L + R)
        #Or ((L - R)
        #Or ((L * R)
        #Or ((L / R)
        #Or ((L % R)
        #Or ((L ^ R)
        #Or ((L & R)
        #Or ((L | R)
        #Or ((L != R)
        #Or ((L == R)
        #Or ((L < R)
        #Or ((L <= R)
        #Or ((L > R)
        #Or ((L >= R))))))))))))))) [macro]

     syntax ResolvedExpr ::= compositePointerOp(Expr, Expr)
     rule compositePointerOp(L::Expr, R::Expr)
         => ((L != R)
        #Or ((L == R)
        #Or ((L < R)
        #Or ((L <= R)
        #Or ((L > R)
        #Or ((L >= R))))))) [macro]

     rule - V:PRVal => - convertType(promote(promote(type(V))), V)
          requires (isCPPArithmeticType(type(V)) orBool isCPPEnumType(type(V)))
               andBool notBool isPromoted(type(V))
     rule + V:PRVal => - convertType(promote(promote(type(V))), V)
          requires (isCPPArithmeticType(type(V)) orBool isCPPEnumType(type(V)))
               andBool notBool isPromoted(type(V))
     rule ~ V:PRVal => - convertType(promote(promote(type(V))), V)
          requires (isCPPArithmeticType(type(V)) orBool isCPPEnumType(type(V)))
               andBool notBool isPromoted(type(V))

     rule L:PRVal << R:PRVal 
          => convertType(promote(promote(type(L))), L)
          << convertType(promote(promote(type(R))), R)
          requires (isCPPArithmeticType(type(L)) orBool isCPPEnumType(type(L)))
               andBool (isCPPArithmeticType(type(R)) orBool isCPPEnumType(type(R)))
               andBool (notBool isPromoted(type(L)) orBool notBool isPromoted(type(R)))
     rule L:PRVal >> R:PRVal 
          => convertType(promote(promote(type(L))), L)
          >> convertType(promote(promote(type(R))), R)
          requires (isCPPArithmeticType(type(L)) orBool isCPPEnumType(type(L)))
               andBool (isCPPArithmeticType(type(R)) orBool isCPPEnumType(type(R)))
               andBool (notBool isPromoted(type(L)) orBool notBool isPromoted(type(R)))

     rule arithBinConversionOp(L:PRVal, R:PRVal) #as O:ResolvedExpr
          => fillExpr(O,
               convertType(usualArithmeticConversions(type(L), type(R)), L),
               convertType(usualArithmeticConversions(type(L), type(R)), R))
          requires (isCPPArithmeticType(type(L)) orBool isCPPEnumType(type(L)))
               andBool (isCPPArithmeticType(type(R)) orBool isCPPEnumType(type(R)))
               andBool (type(L) =/=Type type(R) orBool notBool isPromoted(type(L)))

     rule compositePointerOp(L:PRVal, R:PRVal) #as O:ResolvedExpr
          => fillExpr(O,
               convertType(compositePointerType(L, R), L),
               convertType(compositePointerType(L, R), R))
          requires (isCPPPointerType(type(L)) orBool isCPPMemberPointerType(type(L))
                    orBool isCPPPointerType(type(R)) orBool isCPPMemberPointerType(type(R))
                    orBool isCPPNullPtrTType(type(L)) orBool isCPPNullPtrTType(type(R)))
               andBool type(L) =/=Type type(R)

endmodule
