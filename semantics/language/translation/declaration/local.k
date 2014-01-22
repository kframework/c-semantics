module C-DECLARATION-LOCAL-SYNTAX
     syntax K ::= declareInternalVariable(Id, Type, K)
endmodule

module C-DECLARATION-LOCAL
     imports C-DECLARATION-LOCAL-SYNTAX
     imports C-DECLARATION-GLOBAL-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports COMPAT-SYNTAX

     // TODO(chathhorn): note that execution/declaration/local.k starts from
     // doDeclare, not declareInternalVariable.

     rule <k> declareInternalVariable(X:Id, T:Type, NoInit) 
               => addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T))
          ...</k>
          <externals>... X |-> declState(Loc:SymLoc, _, _) ...</externals> 
          when notBool isIncompleteType(T)
               andBool isFunctionType(T)
          [structural] 

     // TODO(chathhorn): Need to actually cause an extern to be declared or
     // completed at this point. 
     rule <k> declareInternalVariable(X:Id, T:Type, NoInit) 
               => giveType(X, unqualifyType(T))
          ...</k>
          <externals> Exts:Map </externals> 
          when isExternType(T) orBool isFunctionType(T)
               andBool (notBool $hasMapping(Exts, X))
          [structural]

     // TODO(chathhorn): Possibly complete the extern.
     rule <k> declareInternalVariable(X:Id, T:Type, NoInit)
               => addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T))
          ...</k>
          <externals>... X |-> declState(Loc:SymLoc, _, _) ...</externals>
          when isExternType(T)
               andBool (notBool isIncompleteType(T))
          [structural] 
     rule [declareExternInternal]:
          <k> declareInternalVariable(X:Id, T:Type, NoInit)
               => addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T))
          ...</k>
          <externals>... 
               X |-> declState(Loc:SymLoc, T:Type, _) 
          ...</externals>
          when isExternType(T)
               andBool isIncompleteType(T)
          [structural] 
     
     rule declareInternalVariable(X:Id, T:Type, NoInit)
          => giveType(X, T)
          when isNaked(T)
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => defineAndInit(X, T, figureInit(X, T, K))
          when isNaked(T)
               andBool (K =/=K NoInit)
          [structural] 
          
     rule declareInternalVariable(X:Id, T:Type, NoInit)
          => giveType(X, unqualifyType(T))
          when isStaticType(T)
          [structural] 
          
     rule declareInternalVariable(X:Id, T:Type, K:K)
          => defineAndInit(X, unqualifyType(T),
               figureInit(X,
               removeStorageSpecifiers(T), K))
          when isStaticType(T)
               andBool (K =/=K NoInit)
          [structural, large] 
                    
     syntax K ::= defineAndInit(Id, Type, K) [strict(3)] 

     rule defineAndInit(X:Id, _, initValue(X:Id, T:Type, _))
          => giveType(X, T)
          [structural] 
endmodule

