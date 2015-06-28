module C-ENV-SYNTAX
     imports C-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax KItem ::= addToEnv(CId, SymBase)
     syntax KItem ::= giveType(CId, Type)
     syntax KItem ::= "populateFromGlobal"
     syntax KItem ::= addToHistory(BlockTag)

     syntax Bool ::= isGlobalScope(K) [function]

     syntax CId ::= "prototypeScope"
     syntax KItem ::= scope(CId, K)
endmodule

module C-ENV
     imports C-ENV-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     rule <k> addToHistory(Tag:BlockTag) => .K ...</k>
          <block-history> .List => ListItem(Tag) ...</block-history>

     rule <k> populateFromGlobal => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map </genv>
          <gtypes> GT:Map </gtypes>
          <env> _ => G </env>
          <types> _ => GT </types>

     rule <k> addToEnv(X:CId, Base:SymBase) => addToGlobalEnv(X, Base) ...</k>
          <curr-function> fileScope </curr-function>
     rule <k> addToEnv(X:CId, Base:SymBase) => addToLocalEnv(X, Base) ...</k>
          <curr-function> E:CId </curr-function>
          requires E =/=K fileScope

     syntax KItem ::= addToGlobalEnv(K, SymBase)
     rule <k> addToGlobalEnv(X:CId, Base:SymBase) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map => G[X <- Base] </genv>
          <env> E:Map => E[X <- Base] </env>

     syntax KItem ::= addToLocalEnv(K, SymBase)
     rule <k> addToLocalEnv(X:CId, Base:SymBase) => .K ...</k>
          <env> E:Map => E[X <- Base] </env>

     rule <k> giveType(X:CId, T:Type)
               => giveGlobalType(X, tagRestrict(global, stripStorageSpecifiers(T)))
          ...</k>
          <curr-function> fileScope </curr-function>
     rule <k> giveType(X:CId, T:Type)
               => giveLocalType(X, stripStorageSpecifiers(T))
          ...</k>
          <curr-function> E:CId </curr-function>
          requires E =/=K fileScope

     syntax KItem ::= giveGlobalType(K, Type)
     rule <k> giveGlobalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[X <- T] </types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes> G:Map => G[X <- T] </gtypes>

     syntax KItem ::= giveLocalType(K, Type)
     rule <k> giveLocalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[X <- tagRestrict(BlockNum, T)] </types>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
     // Function parameters.
     rule <k> giveLocalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[X <- tagRestrict(Fun, T)] </types>
          <block-history> .List </block-history>
          <curr-function> Fun:CId </curr-function>

     rule <k> scope(Scope:CId, K:K) => K ~> setScope(OldScope) ...</k>
          <curr-function> OldScope:CId => Scope </curr-function>

     syntax KItem ::= setScope(CId)
     rule <k> setScope(Scope:CId) => .K ...</k>
          <curr-function> _ => Scope </curr-function>

     rule isGlobalScope(fileScope) => true
     rule isGlobalScope(prototypeScope) => true
     rule isGlobalScope(_) => false [owise]

endmodule
