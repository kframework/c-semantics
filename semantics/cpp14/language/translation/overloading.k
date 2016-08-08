module CPP-OVERLOADING-SYNTAX
     imports COMPAT-SYNTAX

     syntax Val ::= CandidateSet
     syntax CandidateSet ::= cSet(Map)
     syntax Expr ::= resolveOverload(CandidateSet, StrictList, CId)
     syntax Expr ::= resolveUniqueDecl(K, Expr) [strict(1)]

endmodule

module CPP-OVERLOADING
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SORTS
     imports C-CONFIGURATION

     // no overloading
     rule <k> resolveOverload(cSet(T::CPPType |-> kpair(_, Base::SymBase)), Args::StrictList, operator()) => CallExpr(lv(lnew(Base, T), T), Args) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires notBool isCPPClassType(T)
               andBool Base =/=K nonStatic

     rule resolveUniqueDecl(cSet(T::CPPType |-> kpair(_, Base::SymBase)), _) => lv(lnew(Base, T), T)
          requires Base =/=K nonStatic
     rule resolveUniqueDecl(cSet(T::CPPType |-> kpair(_, nonStatic)), E::Expr) => le(E, T)
     rule resolveUniqueDecl(V:KResult, _) => V
          requires notBool isCandidateSet(V)

endmodule
