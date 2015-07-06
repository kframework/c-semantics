module C-ENV-SYNTAX
     imports C-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax KItem ::= addToEnv(CId, SymBase)
     syntax KItem ::= giveType(CId, Type)
     syntax KItem ::= "populateFromGlobal"
     syntax KItem ::= addToHistory(Int)

endmodule

module C-ENV
     imports C-ENV-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule <k> addToHistory(BlockNum:Int) => .K ...</k>
          <block-history> .List => ListItem(BlockNum) ...</block-history>
          [structural]

     rule <k> populateFromGlobal => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map </genv>
          <gtypes> GT:Map </gtypes>
          <env> _ => G </env>
          <types> _ => GT </types>
          [structural]

     rule <k> addToEnv(X:CId, Base:SymBase) => .K ...</k>
          <env> E:Map => E[X <- Base] </env>
          [structural]

     rule <k> giveType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[X <- tagRestrict(S, T)] </types>
          <curr-scope> S:Scope </curr-scope>
          [structural]
endmodule
