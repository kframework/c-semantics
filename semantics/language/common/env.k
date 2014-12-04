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
     imports C-DECL-DEFINITION-SYNTAX

     imports COMPAT-SYNTAX

     rule <k> addToHistory(Num:Int) => .K ...</k>
          <block-history> .List => ListItem(Num) ...</block-history>
          [structural]

     rule <k> populateFromGlobal => .K ...</k>
          <curr-tu> Tu:K </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map </genv>
          <gtypes> GT:Map </gtypes>
          <gstructs> GS:Map </gstructs>
          <env> _ => G </env>
          <types> _ => GT </types>
          <structs> _ => GS </structs>
          [structural]

     rule <k> addToEnv(X:CId, Base:SymBase) => addToGlobalEnv(X, Base) ...</k>
          <curr-function> file-scope </curr-function>
          [structural]
     rule <k> addToEnv(X:CId, Base:SymBase) => addToLocalEnv(X, Base) ...</k>
          <curr-function> F:CId </curr-function>
          requires F =/=K file-scope
          [structural]

     syntax KItem ::= addToGlobalEnv(K, SymBase)
     rule <k> addToGlobalEnv(X:CId, Base:SymBase) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map => G[X <- Base] </genv>
          <env> E:Map => E[X <- Base] </env>
          [structural]

     syntax KItem ::= addToLocalEnv(K, SymBase)
     rule <k> addToLocalEnv(X:CId, Base:SymBase) => .K ...</k>
          <env> E:Map => E[X <- Base] </env>
          [structural]

     rule <k> giveType(X:CId, T:Type)
               => #if (Fun ==K file-scope)
               #then giveGlobalType(X,
                    tagRestrict(global, stripStorageSpecifiers(T)))
               #else giveLocalType(X, stripStorageSpecifiers(T))
               #fi
          ...</k>
          <curr-function> Fun:CId </curr-function>
          [structural]

     syntax KItem ::= giveGlobalType(K, Type)
     rule <k> giveGlobalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[X <- T] </types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes>
               G:Map => G[X <- T]
          </gtypes>
          [structural]

     syntax KItem ::= giveLocalType(K, Type)
     rule <k> giveLocalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[X <- tagRestrict(BlockNum, T)] </types>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          [structural]
     // Function parameters.
     rule <k> giveLocalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[X <- tagRestrict(Fun, T)] </types>
          <block-history> .List </block-history>
          <curr-function> Fun:CId </curr-function>
          [structural]
endmodule
