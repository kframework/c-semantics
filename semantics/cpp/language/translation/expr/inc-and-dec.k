module CPP-TRANSLATION-EXPR-INC-AND-DEC
     imports BOOL
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule LV:LVal ++
          => postOp(LV, le(LHOLE, trace(LV), type(LV)) := pre(RHOLE, trace(LV), utype(LV)) + prv(1, noTrace, type(int)), combine(trace(LV), #klabel(`_++_CPP-SYNTAX`)))
          requires notBool isCPPBoolType(type(LV))

     rule LV:LVal ++
          => postOp(LV, le(LHOLE, trace(LV), type(LV)) := prv(1, noTrace, type(bool)), combine(trace(LV), #klabel(`_++_CPP-SYNTAX`)))
          requires isCPPBoolType(type(LV))

     rule LV:LVal --
          => postOp(LV, le(LHOLE, trace(LV), type(LV)) := pre(RHOLE, trace(LV), utype(LV)) - prv(1, noTrace, type(int)), combine(trace(LV), #klabel(`_--_CPP-SYNTAX`)))

     context postOp(_, (HOLE:Expr => reval(HOLE)), _) [result(PRVal)]

     rule postOp(LV:LVal, Op:PRVal, Tr::Trace) => pre(postOp(LV, Op, Tr), Tr, utype(LV))
          requires Translation()

     rule ++ LV:LVal
          => LV += prv(1, noTrace, type(int))
          requires notBool isCPPBoolType(type(LV))

     rule ++ LV:LVal
          => LV := prv(1, noTrace, type(bool))
          requires isCPPBoolType(type(LV))

     rule -- LV:LVal
          => LV -= prv(1, noTrace, type(int))
          requires notBool isCPPBoolType(type(LV))

endmodule
