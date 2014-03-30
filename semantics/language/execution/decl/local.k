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

     imports C-SYNTAX

     imports COMPAT-SYNTAX

     rule doDeclare(typedDeclaration(T:Type, X:Id), K:K) 
          => declareInternalVariable(X, T, K)
          [structural] 
          
     syntax K ::= declareInternalVariable(Id, Type, K)

     rule [declareExternInternal]:
          <k> declareInternalVariable(X:Id, T:Type, NoInit)
               => addToEnv(X, Loc) 
               ~> giveType(X, T')
          ...</k>
          <curr-tu> TU:String </curr-tu>
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
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
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
          <next-loc> Loc:SymLoc => linc(Loc) </next-loc>
          <local-vars> Vars:List (. => ListItem(X)) </local-vars>
          <local-addresses>... .Set => SetItem(Loc) ...</local-addresses>
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
          <local-vars>... ListItem(X) ...</local-vars>
          when (notBool isIncompleteType(T))
               andBool (notBool isStaticType(T))
               andBool (notBool isExternType(T))
          [structural] 

     rule <k> declareAndDefine(X:Id, T:Type, K:K)
               => defineAndInit(X, T, figureInit(X, T, K), Loc)
          ...</k>
          <next-loc> Loc:SymLoc => linc(Loc) </next-loc>
          <local-vars> Vars:List (. => ListItem(X)) </local-vars>
          <local-addresses>... .Set => SetItem(Loc) ...</local-addresses>
          // Again, this should be needed statically, but not dynamically.
          when notBool X in Vars
          [structural] 
          
     // This happens when we jump before a variable declaration with an
     // initialization in the same block.
     rule <k> declareAndDefine(X:Id, T:Type, K:K)
               => justInit(figureInit(X, T, K))
          ...</k>
          <local-vars>... ListItem(X) ...</local-vars>
          [structural] 

     syntax K ::= defineAndInit(Id, Type, K, SymLoc) [strict(3)] 

     rule <k> defineAndInit(X:Id, _, initValue(X:Id, T':Type, K:K), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T')
               ~> addToEnv(X, Loc)
               ~> giveType(X, T')
               ~> K
               ~> sequencePoint
          ...</k>
          <should-init> true </should-init>
          [structural] 
          
     rule <k> defineAndInit(X:Id, _, initValue(X:Id, T':Type, _), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T')
               ~> addToEnv(X, Loc)
               ~> giveType(X, T')
          ...</k>
          <should-init> false </should-init>
          [structural]
          
     syntax K ::= justInit(K) [strict(1)]

     rule justInit(initValue(_, _, K:K)) 
          => K ~> sequencePoint
          [structural]
endmodule

