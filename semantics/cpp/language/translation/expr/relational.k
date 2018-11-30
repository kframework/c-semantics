module CPP-TRANSLATION-EXPR-RELATIONAL
     imports BOOL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule R1:PRVal == R2:PRVal
          => pre(stripHold(R1) == stripHold(R2), combine(trace(R1), trace(R2), #klabel(`_==__CPP-SYNTAX`)), type(bool))
          requires isPromoted(type(R1)) andBool type(R1) ==Type type(R2)
               andBool (isTExpr(R1) orBool isTExpr(R2))

     rule R1:PRVal != R2:PRVal
          => pre(stripHold(R1) != stripHold(R2), combine(trace(R1), trace(R2), #klabel(`_!=__CPP-SYNTAX`)), type(bool))
          requires isPromoted(type(R1)) andBool type(R1) ==Type type(R2)
               andBool (isTExpr(R1) orBool isTExpr(R2))

     rule R1:PRVal < R2:PRVal
          => pre(stripHold(R1) < stripHold(R2), combine(trace(R1), trace(R2), #klabel(`_<__CPP-SYNTAX`)), type(bool))
          requires isPromoted(type(R1)) andBool type(R1) ==Type type(R2)
               andBool (isTExpr(R1) orBool isTExpr(R2))

     rule R1:PRVal > R2:PRVal
          => pre(stripHold(R1) > stripHold(R2), combine(trace(R1), trace(R2), #klabel(`_>__CPP-SYNTAX`)), type(bool))
          requires isPromoted(type(R1)) andBool type(R1) ==Type type(R2)
               andBool (isTExpr(R1) orBool isTExpr(R2))

     rule R1:PRVal <= R2:PRVal
          => pre(stripHold(R1) <= stripHold(R2), combine(trace(R1), trace(R2), #klabel(`_<=__CPP-SYNTAX`)), type(bool))
          requires isPromoted(type(R1)) andBool type(R1) ==Type type(R2)
               andBool (isTExpr(R1) orBool isTExpr(R2))

     rule R1:PRVal >= R2:PRVal
          => pre(stripHold(R1) >= stripHold(R2), combine(trace(R1), trace(R2), #klabel(`_>=__CPP-SYNTAX`)), type(bool))
          requires isPromoted(type(R1)) andBool type(R1) ==Type type(R2)
               andBool (isTExpr(R1) orBool isTExpr(R2))





endmodule
