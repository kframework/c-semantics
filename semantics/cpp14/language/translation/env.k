module CPP-ENV-SYNTAX
     imports BASIC-K
     imports BOOL-SYNTAX
     imports COMPAT-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SYMLOC-SORTS
     imports CPP-TYPING-SORTS

     // identifier, type, location, is using declaration
     syntax KItem ::= addToEnv(QualId, CPPType, SymBase, Bool)
                    | scope(Scope, K)
                    | setScope(Scope)
                    | noEval(K)
                    | "recover"
     syntax KItem ::= "pushLocals" | "popLocals"
     syntax KItem ::= updateDefaultArguments(QualId, CPPType, StrictList) [strict(3)]

     syntax KResult ::= EnvEntry

     syntax Bool ::= isUsing(EnvEntry) [function, klabel(getEnvEntryUsing)]
     syntax List ::= getDefaultArgs(EnvEntry) [function, klabel(getEnvEntryDefaultArgs)]
     syntax List ::= setDefaultArgs(EnvEntry, List) [function, klabel(setEnvEntryDefaultArgs)]

endmodule

module CPP-ENV
    imports CPP-ENV-SYNTAX
    imports C-CONFIGURATION
    imports BOOL
    imports K-EQUAL
    imports COMPAT-SYNTAX
    imports CPP-ABSTRACT-SYNTAX
    imports CPP-DYNAMIC-SYNTAX
    imports CPP-SYMLOC-SYNTAX
    imports CPP-TYPING-SYNTAX

    rule updateDefaultArguments(_, T::CPPType, _) => .K 
         requires notBool isCPPFunctionType(T)

    rule <k> addToEnv(N:Namespace :: X::CId, T:CPPFunctionType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <curr-tu> Tu::String </curr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv> NE::Map => NE[X <- updateFnEnv(NE, X, T, Base, IsUsing)] </nenv>
         requires N =/=K NoNamespace()
    
    rule <k> updateDefaultArguments(N:Namespace :: X::CId, T:CPPFunctionType, krlist(A1::List)) => .K ...</k>
         <curr-tu> Tu::String </curr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv>... X |-> (_ T |-> envEntry(... defaultArgs: krlist(A2::List => #updateDefaultArgs(A1, A2)))) ...</nenv>
         requires N =/=K NoNamespace()

    rule <k> addToEnv(N:Namespace :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <curr-tu> Tu::String </curr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv> NE::Map => NE[X <- T |-> envEntry(Base, IsUsing, krlist(.List))] </nenv>
         requires N =/=K NoNamespace() andBool notBool isCPPFunctionType(T)

    rule <k> addToEnv(NoNamespace() :: X::CId, T:CPPFunctionType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <env> NE::Map => NE[X <- updateFnEnv(NE, X, T, Base, IsUsing)] </env>

    rule <k> updateDefaultArguments(NoNamespace() :: X::CId, T:CPPFunctionType, krlist(A1::List)) => .K ...</k>
         <env>... X |-> (_ T |-> envEntry(... defaultArgs: krlist(A2::List => #updateDefaultArgs(A1, A2)))) ...</env>

    rule <k> addToEnv(NoNamespace() :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <env> NE::Map => NE[X <- T |-> envEntry(Base, IsUsing, krlist(.List))] </env>
         requires notBool isCPPFunctionType(T)

    rule <k> addToEnv(C:Class :: X::CId, T:CPPFunctionType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <class-id> C </class-id>
         <cenv> CE::Map => CE[X <- updateFnEnv(CE, X, T, Base, IsUsing)] </cenv>

     rule <k> updateDefaultArguments(C:Class :: X::CId, T:CPPFunctionType, krlist(A1::List)) => .K ...</k>
          <class-id> C </class-id>
          <cenv>... X |-> (_ T |-> envEntry(... defaultArgs: krlist(A2::List => #updateDefaultArgs(A1, A2)))) ...</cenv>

    rule <k> addToEnv(C:Class :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool)
             => .K
         ...</k>
         <class-id> C </class-id>
         <cenv> CE::Map => CE[X <- T |-> envEntry(Base, IsUsing, krlist(.List))] </cenv>
         requires notBool isCPPFunctionType(T)

     rule isUsing(envEntry(... using: IsUsing::Bool)) => IsUsing
     rule getDefaultArgs(envEntry(... defaultArgs: krlist(Args::List))) => Args
     rule setDefaultArgs(Entry::EnvEntry, Args::List)
          => #fun(envEntry(... defaultArgs: _ => krlist(Args::List)))(Entry)

     syntax Map ::= updateFnEnv(Map, CId, CPPFunctionType, SymBase, Bool) [function]
     rule updateFnEnv(Env::Map, X::CId, T::CPPFunctionType, Base::SymBase, IsUsing::Bool) => T |-> envEntry(Base, IsUsing, emptyDefaultArguments(T))
          requires notBool X in_keys(Env)
     rule updateFnEnv(_ X |-> XEnv::Map, X::CId, T::CPPFunctionType, Base::SymBase, IsUsing::Bool)
          => #updateFnEnv(XEnv, T, Base, IsUsing)

     syntax Map ::= #updateFnEnv(Map, CPPFunctionType, SymBase, Bool) [function]
     rule #updateFnEnv(XEnv::Map T |-> Entry:EnvEntry, T::CPPFunctionType, Base::SymBase, IsUsing::Bool)
          => XEnv T |-> #fun(envEntry(... base: _ => Base, using: _ => IsUsing))(Entry)
     rule #updateFnEnv(XEnv::Map, T::CPPFunctionType, Base::SymBase, IsUsing::Bool) => XEnv T |-> envEntry(Base, IsUsing, emptyDefaultArguments(T)) [owise]

     syntax List ::= #updateDefaultArgs(newArgs: List, oldArgs: List) [function]
    // The next rule compensates for the clang policy to aggregate existing default args from previous declarations
    // Hence, we'll trust clang to check that the user does not redefine an old def. arg.
     rule #updateDefaultArgs(ListItem(_) New::List, ListItem(I::Init) Old::List)
          => ListItem(I) #updateDefaultArgs(New, Old)
          requires I =/=K NoArg()
     rule #updateDefaultArgs(ListItem(I::Init) New::List, ListItem(NoArg()) Old::List)
          => ListItem(I) #updateDefaultArgs(New, Old)
     rule #updateDefaultArgs(.List, .List) => .List


     rule <k> scope(Scope::Scope, K:K)
              => pushLocals ~> K ~> popLocals ~> setScope(OldScope)
          ...</k>
          <curr-scope> OldScope::Scope => Scope </curr-scope>

     rule <k> setScope(Scope::Scope) => .K ...</k>
          <curr-scope> _ => Scope </curr-scope>

     rule <k> pushLocals => .K ...</k>
          <block-control> C::Bag </block-control>
          <block-stack>
               .List => ListItem(<block-control> C </block-control>)
          ...</block-stack>

     rule <k> popLocals => .K ...</k>
          (_:BlockControlCell => L)
          <block-stack>
               ListItem(L:BlockControlCell) => .List
          ...</block-stack>

     rule <k> noEval(K:K)
              => setEval(noEval) ~> pushLocals ~> K ~> popLocals ~> setEval(OldEval)
          ...</k>
          <curr-eval-context> OldEval::EvalContext </curr-eval-context>

     syntax KItem ::= setEval(EvalContext)
     rule <k> setEval(Eval::EvalContext) => .K ...</k>
          <curr-eval-context> _ => Eval </curr-eval-context>

     rule recover ~> (K:KItem => .K)
          requires K =/=K popLocals
     rule (recover => .K) ~> popLocals

endmodule
