module CPP-TRANSLATION-EXPR-LOGICAL
     imports BOOL
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (V:PRVal => convertType(type(bool), V)) || _
          requires Translation() andBool notBool isCPPBoolType(type(V))

     rule _ || (V:PRVal => convertType(type(bool), V))
          requires Translation() andBool notBool isCPPBoolType(type(V))

     rule (V:PRVal => convertType(type(bool), V)) && _
          requires Translation() andBool notBool isCPPBoolType(type(V))

     rule _ && (V:PRVal => convertType(type(bool), V))
          requires Translation() andBool notBool isCPPBoolType(type(V))

     rule ! (V:PRVal => convertType(type(bool), V))
          requires Translation() andBool notBool isCPPBoolType(type(V))

     rule (! prv(0, Tr::Trace, t(... st: _:CPPSimpleBoolType) #as T::CPPType)) #as O:Expr
          => prv(1, combine(Tr, O), T)
          requires Translation()

     rule (! prv(1, Tr::Trace, t(... st: _:CPPSimpleBoolType) #as T::CPPType)) #as O:Expr
          => prv(0, combine(Tr, O), T)
          requires Translation()

     context (HOLE:Expr => reval(HOLE)) || _ [result(PRVal)]

     context _ || (HOLE:Expr => reval(HOLE)) [result(PRVal)]

     context (HOLE:Expr => reval(HOLE)) && _ [result(PRVal)]

     context _ && (HOLE:Expr => reval(HOLE)) [result(PRVal)]

     context ! (HOLE:Expr => reval(HOLE)) [result(PRVal)]

     rule (L:PRExpr || R:PRVal) #as O:Expr => pre(stripHold(L) || stripHold(R), combine(trace(L), trace(R), O), type(bool))
          requires Translation() andBool isCPPBoolType(type(L))
               andBool isCPPBoolType(type(R))

     rule (L:PRExpr && R:PRVal) #as O:Expr => pre(stripHold(L) && stripHold(R), combine(trace(L), trace(R), O), type(bool))
          requires Translation() andBool isCPPBoolType(type(L))
               andBool isCPPBoolType(type(R))

     rule prv(0, _, t(... st: _:CPPSimpleBoolType)) || R:PRVal => R
          requires Translation()

     rule prv(1, Tr::Trace, t(... st: _:CPPSimpleBoolType) #as T::CPPType) || _:PRVal => prv(1, Tr, T)
          requires Translation()

     rule prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, t(... st: _:CPPSimpleBoolType)) || _:PRVal
          requires Translation()

     rule prv(1, _, t(... st: _:CPPSimpleBoolType)) && R:PRVal => R
          requires Translation()

     rule prv(0, Tr::Trace, t(... st: _:CPPSimpleBoolType) #as T::CPPType) && _:PRVal => prv(0, Tr, T)
          requires Translation()

     rule prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, t(... st: _:CPPSimpleBoolType)) && _:PRVal
          requires Translation()

     rule (! V:PRExpr) #as O:Expr => pre(! stripHold(V), combine(trace(V), O), type(bool))
          requires Translation() andBool isCPPBoolType(type(V))

endmodule
