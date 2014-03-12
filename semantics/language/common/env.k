module C-ENV-SYNTAX
     syntax AggInfo ::= makeStructAggInfo(List) [function]
     syntax AggInfo ::= makeUnionAggInfo(List) [function]
     syntax K ::= addAgg(Id, AggInfo)
     syntax K ::= addToEnv(Id, SymLoc)
     syntax K ::= giveType(Id, Type)
     syntax K ::= "populateFromGlobal"

     // First map is for type, second map is for offset.
     syntax AggInfo ::= aggInfo(List, Map, Map)
endmodule

module C-ENV
     imports C-ENV-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-TYPING-SYNTAX

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


     syntax K ::= addGlobalAggregate(Id, K)
                | addLocalAggregate(Id, K)

     syntax AggInfo ::= "makeStructAggInfo'" "(" List "," Int "," Map ","  Map "," List ")"
                         [function]
     rule makeStructAggInfo(L:List) 
          => makeStructAggInfo'(L:List, 0, .Map, .Map, L:List)
          when L:List =/=List .List
     rule makeStructAggInfo'(
               ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , V:Int
               , Types:Map
               , Offsets:Map
               , L':List
          )
          => makeStructAggInfo'(L, V +Int bitSizeofType(T),
               Types:Map[T / Field], Offsets:Map[V / Field], L')
     rule makeStructAggInfo'(.List, _, Types:Map, Offsets:Map, L:List) 
          => aggInfo(L, Types, Offsets)

     rule <k> addAgg(S:Id, Info:AggInfo)
               => addGlobalAggregate(S, Info)
          ...</k>
          <curr-function> file-scope </curr-function>
          [structural]        
     rule <k> addAgg(S:Id, Info:AggInfo)
               => addLocalAggregate(S, Info)
          ...</k>
          <curr-function> F:Id </curr-function>
          when F =/=K file-scope
          [structural]        

     syntax AggInfo ::= "makeUnionAggInfo'" "(" List "," Map ","  Map "," List ")"
                         [function]
     
     rule makeUnionAggInfo(L:List) 
          => makeUnionAggInfo'(L, .Map, .Map, L)
          when L =/=List .List
     rule makeUnionAggInfo'(
               ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , Types:Map
               , Offsets:Map
               , L':List
          ) 
          => makeUnionAggInfo'(L,
               Types:Map[T / Field], Offsets:Map[0 / Field],
               L')
     rule makeUnionAggInfo'(.List, Types:Map, Offsets:Map, L:List) 
          => aggInfo(L, Types, Offsets)
          
     rule <k> addGlobalAggregate(X:Id, Agg:AggInfo) => . ...</k>
          <structs> M':Map => M':Map[Agg / X] </structs>
          <gstructs> M:Map => M:Map[Agg / X] </gstructs>
          <incomplete-aggs>... SetItem(X) => .Set ...</incomplete-aggs>
          [structural]
     rule <k> addGlobalAggregate(X:Id, Agg:AggInfo) => . ...</k>
          <structs> M':Map => M':Map[Agg / X] </structs>
          <gstructs> M:Map => M:Map[Agg / X] </gstructs>
          <incomplete-aggs> Incs:Set </incomplete-aggs>
          when notBool (X in Incs)
          [structural]
     rule <k> addLocalAggregate(X:Id, Agg:AggInfo) => . ...</k>
          <structs> M:Map => M:Map[Agg / X] </structs>
          [structural]
endmodule
