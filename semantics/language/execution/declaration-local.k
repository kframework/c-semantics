module C-DECLARATION-LOCAL
     imports C-DECLARATION-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports COMPAT-SYNTAX

     imports C-SYNTAX

     // TODO(chathhorn): split out from common/declaration/general.k, need to
     // clean up/refactor the divide better. In particular, much that's still
     // in that file could probably be moved into translation/.
          
     //- internal variables
     
     // fixme need to look for bad use
     rule declareInternalVariable(X:Id, T:Type, K:K)
          => declareWithLinkage(X, T, K, noLinkage)
          when notBool isStaticType(T) 
               andBool (notBool isExternType(T))
          [structural] 
          
     rule <k> 
               declareInternalVariable(X:Id, T:Type, NoInit)
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
     rule <k> 
               declareInternalVariable(X:Id, T:Type, NoInit)
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
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currTU> Tu:K </currTU>
          when isStaticType(T)
               andBool notBool isExternType(T)
               andBool notBool $hasMapping(Locs, kpair(X, BlockNum))
          [structural, large] 
          
     rule <k> 
               declareInternalVariable(X:Id, T:Type, K:K)
               => defineAndInit(X, unqualifyType(T),
                    figureInit(X,
                    removeStorageSpecifiers(T), K), Loc)
          ...</k>
          <internalLocations>... 
               Tu |-> map((Locs:Map => Locs:Map[Loc / kpair(X, BlockNum)])) 
          ...</internalLocations>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currTU> Tu:K </currTU>
          when isStaticType(T)
               andBool (K =/=K NoInit)
               andBool (notBool $hasMapping(Locs, kpair(X, BlockNum)))
          [structural, large] 
                    
     // this is essentially defineandinit, but that checks if type has been
     // seen for allocation
     syntax K ::= "reseenStatic" "(" Id "," Type "," K "," SymLoc ")"
          [strict(3)] 
     rule <k> 
               declareInternalVariable(X:Id, T:Type, K:K)
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
          
     // fixme this terribly needs to be refactored.  I'm duplicating the two
     // rules (...for the common declareWithLinkage, without "noLinkage") so I
     // don't add locals to the declaration order
     rule declareWithLinkage(X:Id, T:Type, NoInit, noLinkage) 
          => declareOnly(X, T, noLinkage)
          [structural] 
     rule declareWithLinkage(X:Id, T:Type, K:K, noLinkage)
          => declareAndDefine(X, T, K, noLinkage)
          when K =/=K NoInit
          [structural] 

     rule <k> 
               declareOnly(X:Id, T:Type, noLinkage)
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

     // same as above, but for the case where the variable has already been
     // declared.  this is seen if we goto earlier in the same block
     rule <k> 
               declareOnly(X:Id, T:Type, noLinkage)
               => .K
          ...</k>
          <localVariables>... ListItem(X) ...</localVariables>
          when (notBool isIncompleteType(T))
               andBool (notBool isStaticType(T))
               andBool (notBool isExternType(T))
          [structural] 

     rule <k> 
               declareAndDefine(X:Id, T:Type, K:K, noLinkage)
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
     rule <k> 
               declareAndDefine(X:Id, T:Type, K:K, noLinkage)
               => justInit(figureInit(X, T, K))
          ...</k>
          <localVariables>... ListItem(X) ...</localVariables>
          [structural] 

endmodule

