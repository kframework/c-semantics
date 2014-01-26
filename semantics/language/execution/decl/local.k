module C-DECL-LOCAL-SYNTAX
     syntax K ::= declareOnly(Id, Type)
endmodule

module C-DECL-LOCAL
     imports C-DECL-LOCAL-SYNTAX
     imports C-DECL-GENERAL-SYNTAX
     imports C-DECL-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports COMPAT-SYNTAX

     imports C-SYNTAX

     rule doDeclare(typedDeclaration(T:Type, X:Id), K:K) 
          => declareInternalVariable(X, T, K)
          when notBool isFunctionType(T)
          [structural] 
          
     syntax K ::= declareInternalVariable(Id, Type, K)

     rule [declareExternInternal]:
          <k> declareInternalVariable(X:Id, T:Type, NoInit)
               => addToEnv(X, Loc) ~> giveType(X, unqualifyType(T))
          ...</k>
          <genv>...
               Tu |-> map(_ X |-> Loc:SymLoc)
          ...</genv>
          <currTU> Tu:K </currTU>
          when notBool isIncompleteType(T)
               andBool isExternType(T)
          [structural] 
     
     // fixme need to look for bad use
     rule declareInternalVariable(X:Id, T:Type, NoInit)
          => declareOnly(X, T)
          when notBool isStaticType(T) 
               andBool (notBool isExternType(T))
          [structural] 

     syntax K ::= declareAndDefine(Id, Type, K)

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => declareAndDefine(X, T, K)
          when notBool isStaticType(T) 
               andBool (notBool isExternType(T))
               andBool (K =/=K NoInit)
          [structural] 
          
     rule <k> declareInternalVariable(_, _, _) ... </k>
          <currTU> Tu:String </currTU>
          <internalLocations> 
               Locs:Map (. => Tu |-> map(.Map))
          </internalLocations>
          when notBool $hasMapping(Locs, Tu)
          [structural]

     rule <k> declareInternalVariable(X:Id, T:Type, NoInit)
               => addToEnv(X, Loc) ~> giveType(X, unqualifyType(T))
          ...</k>
          <internalLocations>... 
               Tu |-> map((_ kpair(X, BlockNum) |-> Loc:SymLoc)) 
          ...</internalLocations>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <currTU> Tu:K </currTU>
          when isStaticType(T)
               andBool notBool isExternType(T)
          [structural, large] 
     // TODO(chathhorn): handle initialization of statics during the
     // translation phase.
     rule <k> declareInternalVariable(X:Id, T:Type, NoInit)
               => allocateType(Loc, T)
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, unqualifyType(T))
                    ~> zero(X)
          ...</k>
          <internalLocations>... 
               Tu |-> map((Locs:Map => Locs:Map[
                    Loc / kpair(X, BlockNum)])) 
          ...</internalLocations>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          when isStaticType(T)
               andBool notBool isExternType(T)
               andBool notBool $hasMapping(Locs, kpair(X, BlockNum))
          [structural, large] 
          
     rule <k> declareInternalVariable(X:Id, T:Type, K:K)
               => defineAndInit(X, T,
                    figureInit(X, removeStorageSpecifiers(T), K), Loc)
          ...</k>
          <internalLocations>... 
               Tu |-> map((Locs:Map => Locs:Map[Loc / kpair(X, BlockNum)])) 
          ...</internalLocations>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          when isStaticType(T)
               andBool (K =/=K NoInit)
               andBool (notBool $hasMapping(Locs, kpair(X, BlockNum)))
          [structural, large] 
                    
     // This is essentially defineAndInit, but that checks if the type has been
     // seen for allocation.
     syntax K ::= reseenStatic(Id, Type, K, SymLoc)
          [strict(3)] 
     rule <k> declareInternalVariable(X:Id, T:Type, K:K)
               => reseenStatic(X, unqualifyType(T),
                    figureInit(X,
                    removeStorageSpecifiers(T), K), Loc)
          ...</k>
          <internalLocations>...
               Tu |-> map((_ kpair(X, BlockNum:Int) |-> Loc:SymLoc))
          ...</internalLocations>
          <blockHistory> ListItem(BlockNum) ...</blockHistory>
          <currTU> Tu:K </currTU>
          when isStaticType(T)
               andBool K =/=K NoInit
          [structural, large] 
          
     rule reseenStatic(X:Id, _, initValue(X:Id, T:Type, _), Loc:SymLoc)
          => addToEnv(X, Loc) ~> giveType(X, T)
          [structural] 

     rule <k> declareOnly(X:Id, T:Type)
               => allocateType(Loc, T) ~> addToEnv(X, Loc) ~> giveType(X, T)
          ...</k>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localVariables> Vars:List (. => ListItem(X)) </localVariables>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          when (notBool isIncompleteType(T))
               andBool (notBool isStaticType(T))
               andBool (notBool isExternType(T))
               // this should be here statically, but not dynamically
               andBool (notBool X in Vars)
          [structural]

     // Same as above, but for the case where the variable has already been
     // declared. This is seen if we goto earlier in the same block.
     rule <k> declareOnly(X:Id, T:Type)
               => .K
          ...</k>
          <localVariables>... ListItem(X) ...</localVariables>
          when (notBool isIncompleteType(T))
               andBool (notBool isStaticType(T))
               andBool (notBool isExternType(T))
          [structural] 

     rule <k> declareAndDefine(X:Id, T:Type, K:K)
               => defineAndInit(X, T, figureInit(X, T, K), Loc)
          ...</k>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localVariables> Vars:List (. => ListItem(X)) </localVariables>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          // again, this should be needed statically, but not dynamically
          when notBool X in Vars
          [structural] 
          
     // this happens when we jump before a variable declaration with an
     // initialization in the same block
     rule <k> declareAndDefine(X:Id, T:Type, K:K)
               => justInit(figureInit(X, T, K))
          ...</k>
          <localVariables>... ListItem(X) ...</localVariables>
          [structural] 

     syntax K ::= defineAndInit(Id, Type, K, SymLoc) [strict(3)] 

     rule <k> defineAndInit(X:Id, T:Type, 
                    initValue(X:Id, T':Type, K:K), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T')
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, T')
                    ~> #if (isStaticType(T)) #then zero(X) #else (.) #fi
                    ~> K
                    ~> sequencePoint
          ...</k>
          <shouldInit> true </shouldInit>
          [structural] 
          
     rule <k> defineAndInit(X:Id, _,
                    initValue(X:Id, T':Type, _), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T')
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, T')
          ...</k>
          <shouldInit> false </shouldInit>
          [structural]
          
     syntax K ::= justInit(K) [strict(1)]

     rule justInit(initValue(_, _, K:K)) 
          => K ~> sequencePoint
          [structural]
          
endmodule

