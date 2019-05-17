module CPP-TRANSLATION-EXPR-ASSIGNMENT
     imports C-CONFIGURATION
     imports BOOL
     imports SYMLOC-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (le(L::Expr, Tr::Trace, T::CPPType) := PR:PRVal) #as O:Expr
          => le(L := stripHold(convertType(utype(T), PR)), combine(Tr, trace(PR), O), T)
          requires Translation() andBool notBool isCPPClassType(T)

     rule (lv(Loc::SymLoc, Tr::Trace, T::CPPType) := PR:PRVal) #as O:Expr
          => le(lv(Loc, Tr, T) := stripHold(convertType(utype(T), PR)), combine(Tr, trace(PR), O), T)
          requires Translation()

     rule (le(L::Expr, Tr::Trace, T::CPPType) #as LE::Expr) :=init PR:PRVal
          => le(L :=init stripHold(convertType(utype(T), PR)), combine(Tr, trace(PR), LE := PR), T)
          requires Translation() andBool notBool isCPPClassType(T)

     rule (lv(Loc::SymLoc, Tr::Trace, T::CPPType) #as LE::Expr) :=init (prv(V::CPPValue, Tr'::Trace, T'::CPPType) #as RE::Expr)
          => init(Loc, convertType(utype(T), prv(V, combine(Tr, Tr', LE := RE), T')), T)
          ~> lv(Loc, combine(Tr, Tr', LE := RE), T)
          requires Translation() andBool notBool isCPPClassType(T)
               andBool notBool isLinkerLoc(Loc)

     rule (lv(Loc::SymLoc, Tr::Trace, T::CPPType) #as LE::Expr) :=init PR:PRVal
          => le(lv(Loc, Tr, T) :=init stripHold(convertType(utype(T), PR)), combine(Tr, trace(PR), LE := PR), T)
          requires Translation() andBool (isLinkerLoc(Loc) orBool isPRExpr(PR))


     rule (L:LVal += R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) + R),
               combine(trace(L), trace(R), O))

     rule (L:LVal -= R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) - R),
               combine(trace(L), trace(R), O))

     rule (L:LVal *= R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) * R),
               combine(trace(L), trace(R), O))

     rule (L:LVal /= R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) / R),
               combine(trace(L), trace(R), O))

     rule (L:LVal %= R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) % R),
               combine(trace(L), trace(R), O))

     rule (L:LVal ^= R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) ^ R),
               combine(trace(L), trace(R), O))

     rule (L:LVal &= R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) & R),
               combine(trace(L), trace(R), O))

     rule (L:LVal |= R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) | R),
               combine(trace(L), trace(R), O))

     rule (L:LVal <<= R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) << R),
               combine(trace(L), trace(R), O))

     rule (L:LVal >>= R:PRVal) #as O:Expr
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) >> R),
               combine(trace(L), trace(R), O))

     context compoundAssign(_, (HOLE:Expr => reval(HOLE)), _) [result(PRVal)]

     rule compoundAssign(L:LVal, R:PRVal, Tr::Trace)
          => le(compoundAssign(L, R, Tr), Tr, type(L))
          requires Translation()

     context compoundOp(HOLE:Expr)

     rule compoundOp(V:PRVal)
          => pre(compoundOp(stripHold(V)), noTrace, type(V))
          requires Translation()
endmodule
