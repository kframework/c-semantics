module CPP-PROMOTION
     imports BOOL
     imports CPP-DYNAMIC-SORTS
     imports CPP-COMMON-PROMOTION-CONTEXT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule Lbl:KLabel(L:PRVal, R:PRVal)
          => Lbl(
               convertType(usualArithmeticConversions(type(L), type(R)), L),
               convertType(usualArithmeticConversions(type(L), type(R)), R))
          requires isArithBinConversionOp(#klabel(Lbl))
               andBool isCPPArithmeticType(type(L))
               andBool isCPPArithmeticType(type(R))
               andBool type(L) =/=Type type(R)

endmodule
