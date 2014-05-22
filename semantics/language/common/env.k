module C-ENV-SYNTAX
     syntax K ::= addToEnv(CId, SymLoc)
     syntax K ::= giveType(CId, Type)
     syntax K ::= "populateFromGlobal"
     syntax K ::= addToHistory(Int)
          [latex(\terminal{addToHist}\!({#1}\!))]

endmodule

module C-ENV
     imports C-SYNTAX
     imports C-ENV-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX

     imports COMPAT-SYNTAX

     rule <k> addToHistory(Num:Int) => .K ...</k>
          <block-history> .List => ListItem(Num) ...</block-history>
          [structural] 

     syntax K ::= addToGlobalEnv(K, SymLoc)
     syntax K ::= addToLocalEnv(K, SymLoc)
          
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
     
     rule <k> addToEnv(X:CId, Loc:SymLoc) => addToGlobalEnv(X, Loc) ...</k>
          <curr-function> file-scope </curr-function>
          [structural] 
     rule <k> addToEnv(X:CId, Loc:SymLoc) => addToLocalEnv(X, Loc) ...</k>
          <curr-function> F:CId </curr-function>
          when F =/=K file-scope
          [structural] 
          
     rule <k> addToGlobalEnv(X:CId, Loc:SymLoc) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id> 
          <genv> G:Map => G[Loc <- X] </genv>
          <env> E:Map => E[Loc <- X] </env>
          [structural] 
     rule <k> addToLocalEnv(X:CId, Loc:SymLoc) => . ...</k>
          <env> E:Map => E[Loc <- X] </env>
          [structural] 

     syntax K ::= giveGlobalType(K, Type)
     syntax K ::= giveLocalType(K, Type)
     
     rule <k> giveType(X:CId, T:Type) => 
               #if (Fun ==K file-scope) 
               #then giveGlobalType(X, stripStorageSpecifiers(T)) 
               #else giveLocalType(X, stripStorageSpecifiers(T)) 
               #fi
          ...</k>
          <curr-function> Fun:CId </curr-function>
          [structural]
          
     rule <k> giveGlobalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[T <- X] </types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes>
               G:Map => G[T <- X]
          </gtypes>
          [structural]
     rule <k> giveLocalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[T <- X] </types>
          [structural]   

endmodule
