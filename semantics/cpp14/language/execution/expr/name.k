module CPP-EXECUTION-EXPR-NAME
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
     imports CPP-TYPING-SYNTAX

     rule <k> Name(NoNNS(), X:CId) => lv(lnew(Base), noTrace, T) ...</k>
          <env>... X |-> (T::CPPType |-> kpair(_, Base::SymBase)) ...</env>

     rule <k> Name(NoNNS(), X:CId) => T ...</k>
          <types>... X |-> (_ |-> T::CPPType) ...</types>

     rule <k> temp(I::Int, T::CPPType) => Name(NoNNS(), #NoName(I)) ...</k>
          <env> Env::Map </env>
          requires #NoName(I) in_keys(Env)

     rule <k> temp(I::Int, T::CPPType) 
              => #if isCPPRefType(T) #then .K #else allocObject(bnew(!I:Int, T, .Set, D), T, byteSizeofType(T)) #fi
              ~> addToEnv(#NoName(I), T, bnew(!I:Int, T, .Set, D), false)
              ~> lv(lnew(bnew(!I:Int, T, .Set, D)), noTrace, T) ...</k>
          <duration> D::Duration </duration>
          

     // instantiate lives here for similarity to C semantics. Maybe we should move both?
     rule instantiate(Loc::SymLoc, Tr::Trace, T::CPPType)
     => read(Loc, Tr, T)

endmodule
