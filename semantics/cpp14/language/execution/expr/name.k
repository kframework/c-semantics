module CPP-EXPR-NAME
     imports C-CONFIGURATION
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX

     rule <k> Name(NoNNS(), X:CId) => lv(lnew(Base, T), T) ...</k>
          <env>... X |-> (T::CPPType |-> kpair(_, Base::SymBase)) ...</env>

     // instantiate lives here for similarity to C semantics. Maybe we should move both?
     rule instantiate(Loc::SymLoc, T::CPPType)
     => read(Loc, T)

endmodule
