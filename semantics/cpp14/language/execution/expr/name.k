module CPP-EXPR-NAME
     imports C-CONFIGURATION
     imports K-EQUAL
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX

     rule <k> Name(NoNNS(), X:CId) => lv(lnew(Base, T), noTrace, T) ...</k>
          <env>... X |-> (T::CPPType |-> kpair(_, Base::SymBase)) ...</env>

     rule <k> temp(I::Int, T::CPPType) => Name(NoNNS(), #NoName(I)) ...</k>
          <env> Env::Map </env>
          requires #NoName(I) in_keys(Env)

     rule <k> temp(I::Int, T::CPPType) 
              => #if isCPPRefType(T) #then .K #else allocObject(!I @ D, T, byteSizeofType(T)) #fi
              ~> addToEnv(#NoName(I), T, !I @ D, false)
              ~> lv(lnew(!I:Int @ D, T), noTrace, T) ...</k>
          <duration> D::Duration </duration>
          

     // instantiate lives here for similarity to C semantics. Maybe we should move both?
     rule instantiate(Loc::SymLoc, Tr::Trace, T::CPPType)
     => read(Loc, Tr, T)

endmodule
