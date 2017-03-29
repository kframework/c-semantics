module CPP-EXPR-ASSIGNMENT
     imports C-CONFIGURATION
     imports BOOL
     imports SYMLOC-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule le(L::Expr, Tr::Trace, T::CPPType) := PR:PRVal
               => le(L := stripHold(convertType(utype(T), PR)), combine(Tr, trace(PR), #klabel(`_:=__CPP-SYNTAX`)), T)
          requires notBool isCPPClassType(T)

     rule <k> lv(Loc::SymLoc, Tr::Trace, T::CPPType) := prv(V::CPPValue, Tr'::Trace, T'::CPPType)
              => write(Loc, convertType(utype(T), prv(V, combine(Tr, Tr', #klabel(`_:=__CPP-SYNTAX`)), T')), T)
              ~> lv(Loc, combine(Tr, Tr', #klabel(`_:=__CPP-SYNTAX`)), T)
          ...</k>
          <initializing> true </initializing>
          requires notBool isCPPClassType(T)
               andBool notBool isLinkerLoc(Loc)

     rule <k> lv(Loc::SymLoc, Tr::Trace, T::CPPType) := PR:PRVal
              => le(lv(Loc, Tr, T) := stripHold(convertType(utype(T), PR)), combine(Tr, trace(PR), #klabel(`_:=__CPP-SYNTAX`)), T)
          ...</k>
          <initializing> Init:Bool </initializing>
          requires isLinkerLoc(Loc) orBool isPRExpr(PR) orBool notBool Init


     rule L:LVal += R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) + R), 
               combine(trace(L), trace(R), #klabel(`_+=__CPP-SYNTAX`)))
     rule L:LVal -= R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) - R), 
               combine(trace(L), trace(R), #klabel(`_-=__CPP-SYNTAX`)))
     rule L:LVal *= R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) * R), 
               combine(trace(L), trace(R), #klabel(`_*=__CPP-SYNTAX`)))
     rule L:LVal /= R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) / R), 
               combine(trace(L), trace(R), #klabel(`_/=__CPP-SYNTAX`)))
     rule L:LVal %= R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) % R), 
               combine(trace(L), trace(R), #klabel(`_%=__CPP-SYNTAX`)))
     rule L:LVal ^= R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) ^ R), 
               combine(trace(L), trace(R), #klabel(`_^=__CPP-SYNTAX`)))
     rule L:LVal &= R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) & R), 
               combine(trace(L), trace(R), #klabel(`_&=__CPP-SYNTAX`)))
     rule L:LVal |= R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) | R),
               combine(trace(L), trace(R), #klabel(`_|=__CPP-SYNTAX`)))
     rule L:LVal <<= R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) << R), 
               combine(trace(L), trace(R), #klabel(`_<<=__CPP-SYNTAX`)))
     rule L:LVal >>= R:PRVal
          => compoundAssign(L, le(LHOLE, trace(L), type(L)) := compoundOp(pre(RHOLE, trace(L), utype(L)) >> R), 
               combine(trace(L), trace(R), #klabel(`_>>=__CPP-SYNTAX`)))

     context compoundAssign(_, (HOLE:Expr => reval(HOLE)), _) [result(PRVal)]
     rule compoundAssign(L:LVal, R:PRVal, Tr::Trace)
          => le(compoundAssign(L, R, Tr), Tr, type(L))
     context compoundOp(HOLE:Expr)
     rule compoundOp(V:PRVal)
          => pre(compoundOp(stripHold(V)), noTrace, type(V))
endmodule
