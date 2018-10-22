module CPP-TRANSLATION-PROMOTION
     imports BOOL
     imports CPP-DYNAMIC-SORTS
     imports CPP-COMMON-PROMOTION-CONTEXT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule Lbl:KLabel(V:PRVal)
          => Lbl(
               convertType(promote(promote(type(V))), V))
          requires isPromoteOp(#klabel(Lbl))
               andBool (isCPPArithmeticType(type(V)) orBool isCPPEnumType(type(V)))
               andBool notBool isPromoted(type(V))

     rule Lbl:KLabel(L:PRVal, R:PRVal)
          => Lbl(
               convertType(promote(promote(type(L))), L),
               convertType(promote(promote(type(R))), R))
          requires isPromoteOp(#klabel(Lbl))
               andBool (isCPPArithmeticType(type(L)) orBool isCPPEnumType(type(L)))
               andBool (isCPPArithmeticType(type(R)) orBool isCPPEnumType(type(R)))
               andBool (notBool isPromoted(type(L)) orBool notBool isPromoted(type(R)))

     rule Lbl:KLabel(L:PRVal, R:PRVal)
          => Lbl(
               convertType(usualArithmeticConversions(type(L), type(R)), L),
               convertType(usualArithmeticConversions(type(L), type(R)), R))
          requires isArithBinConversionOp(#klabel(Lbl))
               andBool (isCPPArithmeticType(type(L)) orBool isCPPEnumType(type(L)))
               andBool (isCPPArithmeticType(type(R)) orBool isCPPEnumType(type(R)))
               andBool (type(L) =/=Type type(R) orBool notBool isPromoted(type(L)))

     rule Lbl:KLabel(L:PRVal, R:PRVal)
          => Lbl(
               convertType(compositePointerType(L, R), L),
               convertType(compositePointerType(L, R), R))
          requires isCompositePointerOp(#klabel(Lbl))
               andBool (isCPPPointerType(type(L)) orBool isCPPMemberPointerType(type(L))
                    orBool isCPPPointerType(type(R)) orBool isCPPMemberPointerType(type(R))
                    orBool isCPPNullPtrTType(type(L)) orBool isCPPNullPtrTType(type(R)))
               andBool type(L) =/=Type type(R)

endmodule
