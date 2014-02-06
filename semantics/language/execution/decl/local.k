module C-DECL-LOCAL-SYNTAX
     syntax K ::= declareOnly(Id, Type)
endmodule

module C-DECL-LOCAL
     imports C-DECL-LOCAL-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-ZERO-SYNTAX
     imports C-ENV-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports COMPAT-SYNTAX

     imports C-SYNTAX

     rule doDeclare(typedDeclaration(T:Type, X:Id), K:K) 
          => declareInternalVariable(X, T, K)
          [structural] 
          
     syntax K ::= declareInternalVariable(Id, Type, K)

     rule [declareExternInternal]:
          <k> declareInternalVariable(X:Id, T:Type, NoInit)
               => addToEnv(X, Loc) 
               ~> giveType(X, T')
          ...</k>
          <currTU> TU:String </currTU>
          <tu-id> TU </tu-id>
          <genv>...
               X |-> Loc:SymLoc
          ...</genv>
          <gtypes>...
               X |-> T':Type
          ...</gtypes>
          when isExternType(T) 
               orBool isFunctionType(T)
          [structural] 
          
     rule <k> declareInternalVariable(X:Id, T:Type, _)
               => addToEnv(X, Loc)
               ~> giveType(X, T')
          ...</k>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <currTU> TU:String </currTU>
          <tu-id> TU </tu-id>
          <local-statics>... 
               kpair(X, BlockNum) |-> Loc:SymLoc
          ...</local-statics>
          <local-types>... 
               kpair(X, BlockNum) |-> T':Type
          ...</local-types>
          when isStaticType(T)
          [structural] 
     
     rule declareInternalVariable(X:Id, T:Type, NoInit)
          => declareOnly(X, T)
          when notBool isStaticType(T) 
               andBool (notBool isExternType(T))
               andBool (notBool isFunctionType(T))
          [structural] 

     syntax K ::= declareAndDefine(Id, Type, K)

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => declareAndDefine(X, T, K)
          when notBool isStaticType(T) 
               andBool (notBool isExternType(T))
               andBool (notBool isFunctionType(T))
               andBool (K =/=K NoInit)
          [structural] 
                    
     rule <k> declareOnly(X:Id, T:Type)
               => allocateType(Loc, T) 
               ~> addToEnv(X, Loc) 
               ~> giveType(X, T)
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
          // Again, this should be needed statically, but not dynamically.
          when notBool X in Vars
          [structural] 
          
     // This happens when we jump before a variable declaration with an
     // initialization in the same block.
     rule <k> declareAndDefine(X:Id, T:Type, K:K)
               => justInit(figureInit(X, T, K))
          ...</k>
          <localVariables>... ListItem(X) ...</localVariables>
          [structural] 

     syntax K ::= defineAndInit(Id, Type, K, SymLoc) [strict(3)] 

     rule <k> defineAndInit(X:Id, _, initValue(X:Id, T':Type, K:K), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T')
               ~> addToEnv(X, Loc)
               ~> giveType(X, T')
               ~> K
               ~> sequencePoint
          ...</k>
          <shouldInit> true </shouldInit>
          [structural] 
          
     rule <k> defineAndInit(X:Id, _, initValue(X:Id, T':Type, _), Loc:SymLoc)
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

