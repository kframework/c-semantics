module C-ENV-SYNTAX
     imports BASIC-K
     imports INT-SYNTAX
     imports COMMON-SORTS
     imports SYMLOC-SORTS
     imports C-TYPING-SORTS

     syntax KItem ::= addToEnv(CId, SymBase)
     syntax KItem ::= giveType(CId, Type)
     syntax KItem ::= populateFromGlobal(K)
     syntax KItem ::= addToHistory(Int)

endmodule

module C-ENV
     imports C-CONFIGURATION
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> addToHistory(BlockNum:Int) => .K ...</k>
          <block-history> .List => ListItem(BlockNum) ...</block-history>
          [structural]

     rule <k> populateFromGlobal(_) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map </genv>
          <gtypes> GT:Map </gtypes>
          <env> _ => G </env>
          <types> _ => GT </types>
          [structural]

     rule <k> addToEnv(X::CId, Base::SymBase) => .K ...</k>
          <env> E:Map => E[X <- Base] </env>
          [structural]

     rule <k> giveType(X::CId, T::Type) => .K ...</k>
          <types> L:Map => L[X <- tagRestrict(S, T)] </types>
          <curr-scope> S:Scope </curr-scope>
          [structural]
endmodule
