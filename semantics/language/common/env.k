module C-ENV-SYNTAX
     syntax K ::= addToEnv(Id, SymLoc)
     syntax K ::= giveType(Id, Type)
     syntax K ::= "populateFromGlobal"

endmodule

module C-ENV
     imports C-SYNTAX
     imports C-ENV-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX

     syntax K ::= addToGlobalEnv(K, SymLoc)
     syntax K ::= addToLocalEnv(K, SymLoc)
          
     rule [populateFromGlobal]:
          <k> populateFromGlobal => . ...</k>
          <curr-tu> Tu:K </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map </genv> 
          <gtypes> GT:Map </gtypes> 
          <gstructs> GS:Map </gstructs> 
          <env> _ => G </env>
          <types> _ => GT </types>
          <structs> _ => GS </structs>
          [structural]
     
     rule <k> addToEnv(X:Id, Loc:SymLoc) => addToGlobalEnv(X, Loc) ...</k>
          <curr-function> file-scope </curr-function>
          [structural] 
     rule <k> addToEnv(X:Id, Loc:SymLoc) => addToLocalEnv(X, Loc) ...</k>
          <curr-function> F:Id </curr-function>
          when F =/=K file-scope
          [structural] 
          
     rule <k> addToGlobalEnv(X:Id, Loc:SymLoc) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id> 
          <genv> G:Map => G:Map[Loc / X] </genv>
          <env> E:Map => E:Map[Loc / X] </env>
          [structural] 
     rule <k> addToLocalEnv(X:Id, Loc:SymLoc) => . ...</k>
          <env> E:Map => E:Map[Loc / X] </env>
          [structural] 

     syntax K ::= giveGlobalType(K, Type)
     syntax K ::= giveLocalType(K, Type)
     
     rule <k> giveType(X:Id, T:KResult) => 
               #if (Fun:Id ==K file-scope) 
               #then giveGlobalType(X:Id, unqualifyType(T:KResult)) 
               #else giveLocalType(X:Id, unqualifyType(T:KResult)) 
               #fi
          ...</k>
          <curr-function> Fun:Id </curr-function>
          [structural]
          
     rule <k> giveGlobalType(X:Id, T:KResult) => .K ...</k>
          <types> M:Map => M:Map[T:KResult / X:Id] </types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes>
               M':Map => M':Map[T:KResult / X:Id]
          </gtypes>
          [structural]
     rule <k> giveLocalType(X:Id, T:KResult) => .K ...</k>
          <types> M:Map => M:Map[T:KResult / X:Id] </types>
          [structural]   

endmodule
