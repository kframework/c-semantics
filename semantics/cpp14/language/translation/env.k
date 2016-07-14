module CPP-ENV-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports SYMLOC-SYNTAX

     // identifier, type, location, is using declaration
     syntax KItem ::= addToEnv(QualId, CPPType, SymBase, Bool)
                    | scope(Scope, K)

endmodule

module CPP-ENV
    imports CPP-ENV-SYNTAX
    imports COMPAT-SYNTAX

    imports C-CONFIGURATION

    rule <k> addToEnv(N::NormalizedNamespace :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <curr-tu> Tu::String </curr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv> NE::Map => NE[X, T <- kpair(IsUsing, Base)] </nenv>

     rule <k> scope(Scope::Scope, K:K)
              => pushLocals ~> K ~> popLocals ~> setScope(OldScope)
          ...</k>
          <curr-scope> OldScope::Scope => Scope </curr-scope>

     syntax KItem ::= setScope(Scope)
     rule <k> setScope(Scope::Scope) => .K ...</k>
          <curr-scope> _ => Scope </curr-scope>

     syntax KItem ::= "pushLocals" | "popLocals"
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

endmodule
