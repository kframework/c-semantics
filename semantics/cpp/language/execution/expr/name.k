module CPP-EXECUTION-EXPR-NAME
     imports C-CONFIGURATION
     imports K-EQUAL
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> ExecName(NoNNS(), X:CId) => lv(lnew(getBase(Entry)), noTrace, T) ...</k>
          <env>... X |-> (T::CPPType |-> Entry::EnvEntry) ...</env>
          requires Execution()

     rule <k> ExecName(NoNNS(), X:CId) => T ...</k>
          <types>... X |-> T::CPPType ...</types>
          requires Execution()

     rule <k> temp(I::Int, T::CPPType) => ExecName(NoNNS(), #NoName(I)) ...</k>
          <env> Env::Map </env>
          requires Execution() andBool #NoName(I) in_keys(Env)

     // TODO(dwightguth): temporaries need to be deleted at the end of the full expression, except
     // for the exception object (see translation/stmt/try.k), which is deleted at the end of the
     // catch statement.
     rule <k> temp(I::Int, T::CPPType)
              => #if isCPPRefType(T) #then .K #else allocObject(bnew(!I:Int, T, .Set, D), T, byteSizeofType(T)) #fi
              ~> addToExecEnv(#NoName(I), T, bnew(!I:Int, T, .Set, D), false)
              ~> lv(lnew(bnew(!I:Int, T, .Set, D)), noTrace, T) ...</k>
          <env> Env::Map </env>
          <duration> D::Duration </duration>
          requires Execution() andBool notBool (#NoName(I) in_keys(Env))

     // instantiate lives here for similarity to C semantics. Maybe we should move both?
     rule instantiate(Loc::SymLoc, Tr::Trace, T::CPPType)
          => read(Loc, Tr, T)
          requires Execution()

endmodule
