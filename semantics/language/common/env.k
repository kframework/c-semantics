module C-ENV-SYNTAX
     syntax K ::= addToEnv(Id, SymLoc)
     syntax K ::= giveType(Id, Type)
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
     
     rule <k> giveType(X:Id, T:Type) => 
               #if (Fun ==K file-scope) 
               #then giveGlobalType(X, unqualifyType(T)) 
               #else giveLocalType(X, unqualifyType(T)) 
               #fi
          ...</k>
          <curr-function> Fun:Id </curr-function>
          [structural]
          
     rule <k> giveGlobalType(X:Id, T:Type) => .K ...</k>
          <types> M:Map => M:Map[T / X] </types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes>
               M':Map => M':Map[T / X]
          </gtypes>
          [structural]
     rule <k> giveLocalType(X:Id, T:Type) => .K ...</k>
          <types> M:Map => M:Map[T / X] </types>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <local-types>
               LocalTypes:Map => LocalTypes:Map[T / kpair(X, BlockNum)]
          </local-types>
          [structural]   
     // For function parameters. TODO(chathhorn): handle better?
     rule <k> giveLocalType(X:Id, T:Type) => .K ...</k>
          <types> M:Map => M:Map[T / X] </types>
          <block-history> .List </block-history>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <local-types>
               LocalTypes:Map => LocalTypes:Map[T / kpair(X, 0)]
          </local-types>
          [structural]   

endmodule
