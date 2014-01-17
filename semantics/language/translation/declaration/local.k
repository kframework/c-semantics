module C-DECLARATION-LOCAL-SYNTAX
     syntax K ::= declareInternalVariable(Id, Type, K)
endmodule

module C-DECLARATION-LOCAL
     imports C-DECLARATION-LOCAL-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports COMPAT-SYNTAX

     // TODO(chathhorn): note that execution/declaration/local.k starts from
     // doDeclare, not declareInternalVariable.
     rule [declareExternInternal]:
          <k>
               declareInternalVariable(X:Id, T:Type, NoInit)
               => giveType(X, unqualifyType(T))
          ...</k>
          <externalLocations>... X |-> _ ...</externalLocations>
          when notBool isIncompleteType(T)
               andBool isExternType(T)
          [structural] 
     
     rule declareInternalVariable(X:Id, T:Type, NoInit)
          => giveType(X, T)
          when notBool isStaticType(T) 
               andBool (notBool isExternType(T))
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => defineAndInit(X, T, figureInit(X, T, K))
          when notBool isStaticType(T) 
               andBool (notBool isExternType(T))
               andBool (K =/=K NoInit)
          [structural] 
          
     rule declareInternalVariable(X:Id, T:Type, NoInit)
          => giveType(X, unqualifyType(T))
          when isStaticType(T)
               andBool notBool isExternType(T)
          [structural, large] 
          
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

