module C-ENV-SYNTAX
     syntax K ::= addToEnv(CId, SymBase)
     syntax K ::= giveType(CId, Type)
     syntax K ::= "populateFromGlobal"
     syntax K ::= addToHistory(Int) [latex(\terminal{addToHist}\!({#1}\!))]
endmodule

module C-ENV
     imports C-SYNTAX
     imports C-ENV-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX

     imports COMPAT-SYNTAX

     rule <k> addToHistory(Num:Int) => . ...</k>
          <block-history> .List => ListItem(Num) ...</block-history>
          [structural]

     rule <k> populateFromGlobal => . ...</k>
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
          when F =/=K file-scope
          [structural]

     syntax K ::= addToGlobalEnv(K, SymBase)
     rule <k> addToGlobalEnv(X:CId, Base:SymBase) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map => G[Base <- X] </genv>
          <env> E:Map => E[Base <- X] </env>
          [structural]

     syntax K ::= addToLocalEnv(K, SymBase)
     rule <k> addToLocalEnv(X:CId, Base:SymBase) => . ...</k>
          <env> E:Map => E[Base <- X] </env>
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

     syntax K ::= giveGlobalType(K, Type)
     rule <k> giveGlobalType(X:CId, T:Type) => . ...</k>
          <types> L:Map => L[T <- X] </types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes>
               G:Map => G[T <- X]
          </gtypes>
          [structural]

     syntax K ::= giveLocalType(K, Type)
     rule <k> giveLocalType(X:CId, T:Type) => . ...</k>
          <types> L:Map => L[tagRestrict(BlockNum, T) <- X] </types>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          [structural]
     // Function parameters.
     rule <k> giveLocalType(X:CId, T:Type) => . ...</k>
          <types> L:Map => L[tagRestrict(Fun, T) <- X] </types>
          <block-history> .List </block-history>
          <curr-function> Fun:CId </curr-function>
          [structural]
endmodule
