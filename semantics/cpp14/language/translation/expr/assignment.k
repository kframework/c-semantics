module CPP-EXPR-ASSIGNMENT
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule le(L::Expr, Tr::Trace, T::CPPType) := PR:PRVal
               => le(L := stripHold(convertType(utype(T), PR)), combine(Tr, trace(PR), #klabel(`_:=__CPP-SYNTAX`)), T)
          requires notBool isCPPClassType(T)

     rule lv(Loc::SymLoc, Tr::Trace, T::CPPType) := prv(V::CPPValue, Tr'::Trace, T'::CPPType)
               => write(Loc, convertType(utype(T), prv(V, combine(Tr, Tr', #klabel(`_:=__CPP-SYNTAX`)), T')), T)
               ~> lv(Loc, combine(Tr, Tr', #klabel(`_:=__CPP-SYNTAX`)), T)
          requires notBool isCPPClassType(T)
               andBool notBool isLinkerLoc(Loc)

endmodule
