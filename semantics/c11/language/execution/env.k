module C-ENV-SYNTAX
     imports BASIC-K
     imports INT-SYNTAX
     imports COMMON-SORTS
     imports SYMLOC-SORTS
     imports C-TYPING-SORTS

     syntax KItem ::= addToEnv(CId, SymBase)
     syntax KItem ::= giveType(CId, Type)
     syntax KItem ::= populateFromGlobal(K)

endmodule

module C-ENV
     imports STRING
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> populateFromGlobal(_) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map </genv>
          <rgenv> RG:Map </rgenv>
          <gtypes> GT:Map </gtypes>
          <env> _ => G </env>
          <renv> _ => RG </renv>
          <types> _ => GT </types>
          requires Tu =/=String "native"
          [structural]
     rule <k> populateFromGlobal(T::Type) => .K ...</k>
          <curr-tu> "native" </curr-tu>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <env> _ => .Map </env>
          <renv> _ => .Map </renv>
          <types> _ => F |-> T </types>
          [structural]

     rule <k> addToEnv(X::CId, Base::SymBase) => .K ...</k>
          <env> E:Map => E[X <- Base] </env>
          <renv> RE:Map => RE[Base <- X] </renv>
          [structural]

     rule <k> giveType(X::CId, T::Type) => .K ...</k>
          <types> L:Map => L[X <- tagRestrict(S, T)] </types>
          <curr-scope> S:Scope </curr-scope>
          [structural]
endmodule
