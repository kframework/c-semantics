module CPP-EXECUTION-EXPR-NAME
     imports CPP-EXPR-NAME
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

     rule getInnermostNamespace(none) => GlobalNamespace()

     rule <k> Name(NoNNS(), X:CId) => lv(lnew(Base, T), noTrace, T) ...</k>
          <env>... X |-> (T::CPPType |-> kpair(_, Base::SymBase)) ...</env>

     rule <k> Name(NoNNS(), X:CId) => T ...</k>
          <types>... X |-> (_ |-> T::CPPType) ...</types>

     rule <k> Name(NoNNS(), X:CId) => nameLookupInNamespace(X, getInnermostNamespace(S), NoTag()) ...</k>
          <curr-scope> S::Scope </curr-scope>
          <env> Env::Map </env>
          <types> Types::Map </types>
          requires notBool X in_keys(Env) andBool notBool X in_keys(Types)

     rule (.K => N) ~> Name(NNS(N:Name), _)
     rule <k> t(Qs::Quals, Mods::Set, classType(C::Class)) ~> Name(_, X::CId)
              => dataMemberValue(memberPointer(C, X, T), noTrace, T) ...</k>
          <class-id> C </class-id>
          <cenv>... X |-> (T::CPPType |-> _) ...</cenv>

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
