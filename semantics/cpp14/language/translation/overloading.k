module CPP-OVERLOADING-SYNTAX
     imports COMPAT-SYNTAX

     syntax Val ::= CandidateSet
     syntax CandidateSet ::= cSet(Map)
     syntax Expr ::= resolveOverload(CandidateSet, StrictList, CId)

endmodule

module CPP-OVERLOADING
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     // no overloading
     rule <k> resolveOverload(cSet(T::CPPType |-> kpair(_, Base::SymBase)), Args::StrictList, operator()) => CallExpr(lv(lnew(Base, T), T), Args) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires notBool isCPPClassType(T)

endmodule
