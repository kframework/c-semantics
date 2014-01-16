module C-DECLARATION-GLOBAL-SYNTAX
     syntax Linkage ::= "external" | "internal"
     syntax K ::= declareFunction(Id, Type, K)
     syntax K ::= verifyDecl(K) [strict]
endmodule

module C-DECLARATION-GLOBAL
     imports C-DECLARATION-GLOBAL-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX

     imports COMPAT-SYNTAX

     syntax K ::= "doDeclare'" "(" Type "," K ")" 

     rule doDeclare(T:Type, K:K) 
          => verifyDecl(T) ~> doDeclare'(T, K)

     // function declaration
     rule <k> 
               doDeclare'(typedDeclaration(T:Type, X:Id), K:K) 
               => declareFunction(X, T, K)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T)
               andBool isFunctionType(T)
          [structural]
          
     // fixme there are still no nested functions though, right_
     rule <k> 
               doDeclare'(typedDeclaration(T:Type, X:Id), NoInit) 
               => addToEnv(X, Loc) ~> giveType(X, unqualifyType(T))
          ...</k>
          <externalLocations>... X |-> Loc:SymLoc ...</externalLocations> 
          <currentFunction> F:K </currentFunction>
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T)
               andBool isFunctionType(T)
               andBool F =/=K file-scope
          [structural] 
     // fixme i believe this is for local declarations of external library
     // functions
     rule <k> 
               doDeclare'(typedDeclaration(T:Type, X:Id), NoInit) 
               => giveType(X, unqualifyType(T))
          ...</k>
          <externalLocations> Locs:Map </externalLocations> 
          <currentFunction> F:K </currentFunction>
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T)
               andBool isFunctionType(T)
               andBool (F =/=K file-scope)
               andBool (notBool $hasMapping(Locs, X))
          [structural]
     rule <k> 
               doDeclare'(typedDeclaration(T:Type, X:Id), K:K)
               => declareExternalVariable(X, T,
                    #if K ==K NoInit 
                    #then NoInit 
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          <currentProgramLoc> L:CabsLoc </currentProgramLoc>
          when notBool isFunctionType(T)
          [structural] 
          
     //- external variables
     // feature request : nice to have MapList

     // function definition
     rule declareFunction(X:Id, T:Type, K:K)
          => declareWithLinkage(X, T, K, external)
          when notBool isStaticType(T)
               andBool K =/=K NoInit
               andBool (getQualifiers(T) ==Set .Set)
          [structural] 

     rule declareFunction(X:Id, T:Type, NoInit)
          => declareWithLinkage(X,
               t(.Set, prototype(T)), NoInit, external)
          when notBool isStaticType(T)
               andBool (getQualifiers(T) ==Set .Set)
          [structural] 
          
     // fixme not handling internal prototypes
     rule <k> 
               declareFunction(X:Id, T:Type, K:K)
               => declareWithLinkage(X, T, K, internal)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          when isStaticType(T)
               andBool (getQualifiers(T) ==Set .Set)
          [structural] 
          
     syntax K ::= declareExternalVariable(Id, Type, K)

     //- external variables
     rule <k> 
               declareExternalVariable(X:Id, T:Type, K:K)
               => declareWithLinkage(X, T, K, external)
          ...</k>
          <preLinkage>... Tu |-> map(Lnk:Map) ...</preLinkage>
          <currTU> Tu:K </currTU>
          when notBool isStaticType(T)
               andBool notBool $hasMapping(Lnk, X)
          [structural] 
     // not triggering
     // TODO(chathhorn): necessary?
     // rule [declareExtern-again]:
     //      <k> 
     //           declareExternalVariable(X:Id, T:Type, K:K)
     //           => declareWithLinkage(X, T, K, Lnk:Map(X))
     //      ...</k>
     //      <preLinkage>... Tu |-> map(Lnk:Map) ...</preLinkage>
     //      <currTU> Tu:K </currTU>
     //      when notBool isStaticType(T)
     //           andBool $hasMapping(Lnk, X)
     //      [structural] 
     rule declareExternalVariable(X:Id, T:Type, K:K)
          => declareWithLinkage(X, T, K, internal)
          when isStaticType(T)
               andBool notBool isExternType(T)
          [structural] 
          
     // id, type, possible init, linkage (external, internal)
     syntax K ::= declareWithLinkage(Id, Type, K, Linkage)
     
     rule <k>
               declareWithLinkage(X:Id, T:Type, NoInit, L:Linkage)
               => declareOnly(X, T, L)
               ~> addToEnv(X, firstLoc(1)) // TODO(chathhorn): better way.
               ~> giveType(X, T)
          ...</k>
          <declarationOrder>...
               Tu |-> ListToK(_ (. => ListItem(X)))
          ...</declarationOrder>
          <currTU> Tu:K </currTU>
          [structural] 
     rule <k>
               declareWithLinkage(X:Id, T:Type, K:K, L:Linkage)
               => declareAndDefine(X, T, K, L)
               ~> addToEnv(X, firstLoc(1)) // TODO(chathhorn): better way.
               ~> giveType(X, T)
          ...</k>
          <declarationOrder>...
               Tu |-> ListToK(_ (. => ListItem(X)))
          ...</declarationOrder>
          <currTU> Tu:K </currTU>
          when K =/=K NoInit
          [structural] 

     syntax K ::= declareOnly(Id, Type, Linkage)
     
     // fixme unqualifying these is probably unsafe
     rule <k> 
               declareOnly(X:Id, T:Type, external)
               => .K
          ...</k>
          <declarations>... .Set => SetItem(X) ...</declarations>
          <preLinkage>...
               Tu |-> map((LinkageMap:Map => LinkageMap[external / X]))
          ...</preLinkage>
          <preTypes>...
               Tu |-> map((TypesMap:Map => TypesMap[T / X]))
          ...</preTypes>
          <currTU> Tu:K </currTU>
          when ((notBool $hasMapping(LinkageMap, X))
                    orElseBool (LinkageMap(X) ==K external)
               ) andBool (
                    (notBool $hasMapping(TypesMap, X))
                    orElseBool isTypeCompatible(unqualifyType(TypesMap(X)),
                         unqualifyType(T))
               )
          [structural] 
          
     rule <k> 
               declareOnly(X:Id, t(_, prototype(T:Type)), external)
               => .K
          ...</k>
          <preLinkage>...
               Tu |-> map((Lnk:Map => Lnk:Map[external / X]))
          ...</preLinkage>
          <preTypes>... Tu:K |-> map(Types:Map) ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Lnk, X:Id) 
                    orBool Lnk:Map(X) ==K external
               )
               andBool isTypeCompatible(unqualifyType(Types:Map(X)),
                    unqualifyType(T))
          [structural]
     
     // fixme haven't thought about this much, is it right_
     rule <k> 
               declareOnly(X:Id, T:Type, internal)
               => .K
          ...</k>
          <declarations>... .Set => SetItem(X) ...</declarations>
          <preLinkage>...
               Tu |-> map((Lnk:Map => Lnk:Map[internal / X]))
          ...</preLinkage>
          <preTypes>...
               Tu |-> map((Types:Map => Types:Map[T / X]))
          ...</preTypes>
          <currTU> Tu:K </currTU>
          when notBool $hasMapping(Lnk, X:Id) 
               orBool Lnk:Map(X) ==K internal
          [structural] 
     
     /*@ \fromStandard{\source[n1570]{\para{6.2.2}{4}}}{
     For an identifier declared with the storage-class specifier
     \cinline{extern} in a scope in which a prior declaration of that
     identifier is visible, if the prior declaration specifies internal or
     external linkage, the linkage of the identifier at the later declaration
     is the same as the linkage specified at the prior declaration. If no prior
     declaration is visible, or if the prior declaration specifies no linkage,
     then the identifier has external linkage. 
     }*/
     // exception to multiple definitions for functions since we consider
     // prototypes to be definitions to some extent
     // case when it has no previous linkage, or previous linkage is external

     syntax K ::= declareAndDefine(Id, Type, K, Linkage)

     rule <k> 
               declareAndDefine(X:Id, T:Type, K:K, external)
               => .
          ...</k>
          <declarations>... .Set => SetItem(X) ...</declarations>
          <externalDefinitions> 
               Def:Map => Def:Map (X |->
                    declarationObject(unqualifyType(T), Tu, K)) 
          </externalDefinitions>
          <preLinkage>...
               Tu |-> map((Lnk:Map => Lnk:Map[external / X]))
          ...</preLinkage>
          <preTypes>...
               Tu |-> map((Types:Map => Types:Map[T / X]))
          ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Def, X)
                    orBool isFunctionType(T))
               andBool (notBool $hasMapping(Lnk, X) 
                    orBool Lnk:Map(X) ==K external)
          [structural, large]
          
     // case when it has a previous linkage (internal).  
     rule <k> 
               declareAndDefine(X:Id, T:Type, K:K, external)
               => .
          ...</k>
          <declarations>... .Set => SetItem(X) ...</declarations>
          <internalDefinitions>... 
               Tu |-> map((Def:Map 
               => Def:Map[
                    declarationObject(unqualifyType(T), Tu, K)
                    / X])) 
          ...</internalDefinitions>
          <preLinkage>... Tu:K |-> map(Lnk:Map) ...</preLinkage>
          <preTypes>...
               Tu |-> map((Types:Map => Types:Map[T / X]))
          ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Def, X) orBool isFunctionType(T))
               andBool Lnk:Map(X) ==K internal
          [structural, large]
          
     rule <k> 
               declareAndDefine(X:Id, T:Type, K:K, internal)
               => .
          ...</k>
          <declarations>... .Set => SetItem(X) ...</declarations>
          <internalDefinitions>... 
               Tu |-> map((Def:Map 
               => Def:Map[
                    declarationObject(unqualifyType(T), Tu, K) / X])) 
          ...</internalDefinitions>
          <preLinkage>...
               Tu |-> map((Lnk:Map => Lnk:Map[internal / X]))
          ...</preLinkage>
          <preTypes>...
               Tu |-> map((Types:Map => Types:Map[T / X]))
          ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Def, X) 
                    orBool isFunctionType(T))
               andBool (notBool $hasMapping(Lnk, X)
                    orBool Lnk:Map(X) ==K internal)
          [structural, large]
          
endmodule
