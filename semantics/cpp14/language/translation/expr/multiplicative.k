module CPP-TRANSLATION-EXPR-MULTIPLICATIVE
     imports BOOL
     imports FLOAT
     imports INT
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule L:PRVal * R:PRVal => pre(stripHold(L) * stripHold(R), combine(trace(L), trace(R), #klabel(`_*__CPP-SYNTAX`)), type(L))
          requires (isPRExpr(L) orBool isPRExpr(R))
               andBool isPromoted(type(L))
               andBool type(L) ==Type type(R)

     rule L:PRVal / prv(I:Int, Tr::Trace, T::CPPType) => pre(stripHold(L) / prv(I, Tr, T), combine(trace(L), Tr, #klabel(`_/__CPP-SYNTAX`)), type(L))
          requires isPRExpr(L)
               andBool isPromoted(type(L))
               andBool type(L) ==Type T
               andBool I =/=Int 0

     rule L:PRVal / prv(F:Float, Tr::Trace, T::CPPType) => pre(stripHold(L) / prv(F, Tr, T), combine(trace(L), Tr, #klabel(`_/__CPP-SYNTAX`)), type(L))
          requires isPRExpr(L)
               andBool isPromoted(type(L))
               andBool type(L) ==Type T
               andBool F =/=Float 0.0


     rule L:PRVal / R:PRExpr => pre(stripHold(L) / stripHold(R), combine(trace(L), trace(R), #klabel(`_/__CPP-SYNTAX`)), type(L))
          requires isPromoted(type(L))
               andBool type(L) ==Type type(R)

     rule L:PRVal % prv(I:Int, Tr::Trace, T::CPPType) => pre(stripHold(L) % prv(I, Tr, T), combine(trace(L), Tr, #klabel(`_%__CPP-SYNTAX`)), type(L))
          requires isPRExpr(L)
               andBool isPromoted(type(L))
               andBool type(L) ==Type T
               andBool I =/=Int 0

     rule L:PRVal % R:PRExpr => pre(stripHold(L) % stripHold(R), combine(trace(L), trace(R), #klabel(`_%__CPP-SYNTAX`)), type(L))
          requires isPromoted(type(L))
               andBool type(L) ==Type type(R)

endmodule
