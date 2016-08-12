module CPP-ENV-SYNTAX
     imports BASIC-K
     imports BOOL-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     // identifier, type, location, is using declaration
     syntax KItem ::= addToEnv(QualId, CPPType, SymBase, Bool)
                    | scope(Scope, K)
                    | setScope(Scope)
                    | noEval(K)
                    | "recover"
     syntax KItem ::= "pushLocals" | "popLocals"

endmodule

module CPP-ENV
    imports CPP-ENV-SYNTAX
    imports C-CONFIGURATION
    imports COMPAT-SYNTAX
    imports CPP-DYNAMIC-SYNTAX

    rule <k> addToEnv(N:Namespace :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <curr-tu> Tu::String </curr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv> NE::Map => NE[X, T <- kpair(IsUsing, Base)] </nenv>
         requires N =/=K NoNamespace()

    rule <k> addToEnv(NoNamespace() :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <env> NE::Map => NE[X, T <- kpair(IsUsing, Base)] </env>

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
