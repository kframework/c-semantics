module C-DECLARATIONS-GENERAL
     imports C-SYNTAX
     imports C-SEMANTIC-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-DECLARATIONS-SYNTAX 

     // c99 6.7.8:9 Except where explicitly stated otherwise, for the purposes
     // of this subclause unnamed members of objects of structure and union
     // type do not participate in initialization.  Unnamed members of
     // structure objects have indeterminate value even after initialization

     // c99 6.7.8:10 If an object that has automatic storage duration is not
     // initialized explicitly, its value is indeterminate. If an object that
     // has static storage duration is not initialized explicitly, then:

     // -- if it has pointer type, it is initialized to a null pointer;

     // -- if it has arithmetic type, it is initialized to (positive or
     // unsigned) zero;

     // if it is an aggregate, every member is initialized (recursively)
     // according to these rules;

     // -- if it is a union, the first named member is initialized
     // (recursively) according to these rules

     syntax K ::= "defineType" "(" K ")" [strict] 
     context DeclarationDefinition(InitNameGroup(HOLE, _)) 
     context Typedef(NameGroup(HOLE, _))

     rule figureInit(X:Id, T:KResult, CodeLoc(K:K, L:K)) 
          => CodeLoc(.K, L:K)
          ~> figureInit(X:Id, T:KResult, K:K) 
          [structural]
          
     
     // aggregates
     rule figureInit(X:Id, T:KResult, CompoundInit(L:K))
          => giveType(X:Id, T:KResult)
          ~> figureInit-aux(X:Id, T:KResult,
               startInit(T:KResult, X:Id, CompoundInit(L:K)))
          when (isAggregateType(T:KResult) orBool isUnionType(T:KResult)) 
          [structural] 

     rule figureInit(
               _:Id, 
               t(_:Set, arrayType(T:KResult, Len:Int)), 
               (SingleInit(Constant(StringLiteral(S:String))) 
               => CompoundInit(klist(InitFragment(NextInit,
                    SingleInit(Constant(StringLiteral(S:String)))))))
          )
          when isCharType(T:KResult)
               andBool (lengthString(S:String) <=Int Len:Int)
          [structural]

     rule figureInit(
               _:Id, 
               t(_:Set, arrayType(T:KResult, Len:Int)), 
               (SingleInit(Constant(WStringLiteral(S:KList))) 
               => CompoundInit(klist(InitFragment(NextInit,
                    SingleInit(Constant(WStringLiteral(S:KList)))))))
          )
          when isWCharType(T:KResult)
               andBool (lengthKList S <=Int Len:Int)
          [structural] 
     
     rule figureInit(_:Id, t(_, (incompleteArrayType(T:KResult) 
          => arrayType(T:KResult, lengthString(S:String) +Int 1))),
               SingleInit(Constant(StringLiteral(S:String)))) 
          when isCharType(T:KResult)
          [structural]

     rule figureInit(_:Id, t(_, (incompleteArrayType(T:KResult) 
          => arrayType(T:KResult, lengthKList S:KList +Int 1))),
               SingleInit(Constant(WStringLiteral(S:KList)))) 
          when isWCharType(T:KResult)
          [structural] 
          
     rule figureInit(X:Id, t(Se:Set, incompleteArrayType(T:KResult)),
               CompoundInit(klist(InitFragment(NextInit,
               SingleInit(Constant(StringLiteral(S:String)))))))
          => figureInit(X:Id, t(Se:Set, incompleteArrayType(T:KResult)),
               SingleInit(Constant(StringLiteral(S:String))))
          [structural] 
          
     // this comes from function declarations.  should probably adjust this
     rule figureInit(X:Id, T:KResult, initializer(K:K))
          => figureInit-aux(X:Id, T:KResult, initializer(K:K))
          [structural] 

     rule figureInit-aux(X:Id, T:KResult, initializer(K:K))
          => initValue(X:Id, T:KResult, K:K)
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T:KResult)
               andBool notBool isConstType(T:KResult)
          [structural]
     rule figureInit-aux(X:Id, T:KResult, initializer(K:K))
          => initValue(X, T, (K ~> makeUnwritableVar(X)))
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T)
               andBool isConstType(T)
          [structural]
     
     // base types
     rule figureInit(X:Id, T:KResult, SingleInit(K:K))
          => figureInit-aux(X:Id, T:KResult,
               initializer(Computation(AllowWrite(X:Id) := K:K)))
          when notBool isArrayType(T:KResult)
          [structural] 
     // c1x 6.7.8:11
     rule figureInit(X:Id, T:KResult,
               CompoundInit(klist(InitFragment(NextInit, SingleInit(K:K)))))
          => figureInit-aux(X:Id, T:KResult,
               initializer(Computation(AllowWrite(X:Id) := K:K)))
          when notBool (isAggregateType(T:KResult) 
                    orBool isUnionType(T:KResult))
          [structural] 
          
     rule DeclarationDefinition(
               InitNameGroup(T:KResult, klist((K:K,, K':K,, L:KList))))
          => DeclarationDefinition(InitNameGroup(T:KResult, klist(K:K)))
          ~> DeclarationDefinition(
               InitNameGroup(T:KResult, klist((K':K,, L:KList))))
          [structural]
     rule DeclarationDefinition(
               InitNameGroup(T:KResult, klist(InitName(N:K, Exp:K))))
          => doDeclare(SingleName(T:KResult, N:K), Exp:K)
          [structural]
               
     rule Typedef(NameGroup(T:KResult, klist((K:K,, L:KList)))) 
          => defineType(SingleName(T:KResult, K:K))
          ~> Typedef(NameGroup(T:KResult, klist(L:KList)))
          [structural]
     rule Typedef(NameGroup(_:KResult, klist(.KList))) => .K
          [structural]

     rule defineType(typedDeclaration(T:KResult, X:Id)) 
          => giveType(typedef(X:Id), T:KResult) 
          [structural] 
               
     syntax K ::= "declareFunction" "(" Id "," Type "," K ")"
     syntax K ::= "declareExternalVariable" "(" Id "," Type "," K ")"
     syntax K ::= "declareInternalVariable" "(" Id "," Type "," K ")"
     
     // function definition
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), K:K) 
               => declareFunction(X:Id, T:KResult, K:K)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T:KResult)
               andBool isFunctionType(T:KResult)
          [structural]
          
     // fixme there are still no nested functions though, right_
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), NoInit) 
               => addToEnv(X:Id, Loc)
               ~> giveType(X:Id, unqualifyType(T:KResult))
          ...</k>
          <externalLocations>... X:Id |-> Loc:SymLoc ...</externalLocations> 
          <currentFunction> F:K </currentFunction>
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T:KResult)
               andBool isFunctionType(T:KResult)
               andBool F:K =/=K file-scope
          [structural] 
     // fixme i believe this is for local declarations of external library
     // functions
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), NoInit) 
               => giveType(X:Id, unqualifyType(T:KResult))
          ...</k>
          <externalLocations> Locs:Map </externalLocations> 
          <currentFunction> F:K </currentFunction>
          // I'd like to get rid of this cleanly
          when (notBool isIncompleteType(T:KResult))
               andBool (isFunctionType(T:KResult))
               andBool (F:K =/=K file-scope)
               andBool (notBool $hasMapping(Locs:Map, X:Id))
          [structural]
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), K:K)
               => declareExternalVariable(X, T,
                    #if K:K ==K NoInit 
                    #then NoInit #else CodeLoc(K:K, L:CabsLoc) #fi)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          <currentProgramLoc> L:CabsLoc </currentProgramLoc>
          when notBool isFunctionType(T:KResult)
          [structural] 
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), K:K) 
               => declareInternalVariable(X:Id, T:KResult, K:K)
          ...</k>
          <currentFunction> F:K </currentFunction>
          when notBool isFunctionType(T:KResult)
               andBool F:K =/=K file-scope
          [structural] 
          
     //- external variables
     // feature request : nice to have MapList
     
     // function definition
     rule declareFunction(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, external)
          when notBool isStaticType(T:KResult)
               andBool K:K =/=K NoInit
          [structural] 

     rule declareFunction(X:Id, T:KResult, NoInit)
               => declareWithLinkage(X:Id,
                    t(.Set, prototype(T:KResult)), NoInit, external)
          when notBool isStaticType(T:KResult)
          [structural] 
          
     // fixme not handling internal prototypes
     rule <k> declareFunction(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, internal)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          when isStaticType(T:KResult)
          [structural] 
          
     // id, type, possible init, linkage (external, internal, noLinkage)
     syntax K ::= "declareWithLinkage" "(" Id "," Type "," K "," K ")"
     
     //- internal variables
     
     // fixme need to look for bad use
     rule declareInternalVariable(X:Id, T:KResult, K:K)
          => declareWithLinkage(X:Id, T:KResult, K:K, noLinkage)
          when notBool isStaticType(T:KResult)
               andBool (notBool isExternType(T:KResult))
          [structural] 
          
     rule <k> declareInternalVariable(X:Id, T:KResult, NoInit)
               => addToEnv(X:Id, Loc)
               ~> giveType(X:Id, unqualifyType(T:KResult))
          ...</k>
          <internalLocations>... 
               Tu:K |-> map((_ kpair(X:Id, BlockNum:Int) |-> Loc:SymLoc)) 
          ...</internalLocations>
          <br/>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <currTU> Tu:K </currTU>
          when isStaticType(T:KResult)
               andBool notBool isExternType(T:KResult)
          [structural, large] 
     rule <k> declareInternalVariable(X:Id, T:KResult, NoInit)
               => allocateType(Loc, T:KResult)
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, unqualifyType(T:KResult))
               ~> zero(X:Id)
          ...</k>
          <internalLocations>... 
               Tu:K |-> map((Locs:Map => Locs:Map[
                    Loc / kpair(X:Id, BlockNum:Int)])) 
          ...</internalLocations>
          <br/>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currTU> Tu:K </currTU>
          when isStaticType(T:KResult)
               andBool notBool isExternType(T:KResult)
               andBool notBool $hasMapping(Locs:Map, kpair(X:Id, BlockNum:Int))
          [structural, large] 
          
     rule <k> declareInternalVariable(X:Id, T:KResult, K:K)
               => defineAndInit(X:Id, unqualifyType(T:KResult),
                    figureInit(X:Id,
                    removeStorageSpecifiers(T:KResult), K:K), Loc)
          ...</k>
          <internalLocations>... 
               Tu:K |-> map((Locs:Map => Locs:Map[
                    Loc / kpair(X:Id, BlockNum:Int)])) 
          ...</internalLocations>
          <br/>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currTU> Tu:K </currTU>
          when (isStaticType(T:KResult))
               andBool (notBool isExternType(T:KResult))
               andBool (K:K =/=K NoInit)
               andBool (notBool $hasMapping(Locs:Map,
                    kpair(X:Id, BlockNum:Int)))
          [structural, large] 
                    
     // this is essentially defineandinit, but that checks if type has been
     // seen for allocation
     syntax K ::= "reseenStatic" "(" Id "," Type "," K "," SymLoc ")"
          [strict(3)] 
     rule <k> declareInternalVariable(X:Id, T:KResult, K:K)
               => reseenStatic(X:Id, unqualifyType(T:KResult),
                    figureInit(X:Id,
                    removeStorageSpecifiers(T:KResult), K:K), Loc)
          ...</k>
          <internalLocations>...
               Tu:K |-> map((_ kpair(X:Id, BlockNum:Int) |-> Loc:SymLoc))
          ...</internalLocations>
          <br/>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <currTU> Tu:K </currTU>
          when isStaticType(T:KResult)
               andBool notBool isExternType(T:KResult)
               andBool K:K =/=K NoInit
          [structural, large] 
          
     rule reseenStatic(X:Id, _, initValue(X:Id, T:KResult, _), Loc:SymLoc)
          => addToEnv(X, Loc) ~> giveType(X, T)
          [structural] 
          
          
     rule [declareExternInternal]:
          <k> declareInternalVariable(X:Id, T:KResult, NoInit)
               => addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T))
          ...</k>
          <externalLocations>... X |-> Loc:SymLoc ...</externalLocations>
          when notBool isIncompleteType(T)
               andBool notBool isStaticType(T)
               andBool isExternType(T)
          [structural] 
          
     //- external variables
     rule declareExternalVariable(X:Id, T:KResult, K:K)
          => declareWithLinkage(X:Id, T:KResult, K:K, external)
          when notBool isStaticType(T:KResult)
               andBool notBool isExternType(T:KResult)
          [structural] 
     rule <k> declareExternalVariable(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, external)
          ...</k>
          <preLinkage>... Tu:K |-> map(Lnk:Map) ...</preLinkage>
          <currTU> Tu:K </currTU>
          when notBool isStaticType(T:KResult)
               andBool isExternType(T:KResult)
               andBool notBool $hasMapping(Lnk:Map, X:Id)
          [structural] 
     // not triggering
     rule [declareExtern-again]:
          <k> declareExternalVariable(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, Lnk:Map(X:Id))
          ...</k>
          <preLinkage>... Tu:K |-> map(Lnk:Map) ...</preLinkage>
          <currTU> Tu:K </currTU>
          when notBool isStaticType(T:KResult)
               andBool isExternType(T:KResult)
               andBool $hasMapping(Lnk:Map, X:Id)
          [structural] 
     rule declareExternalVariable(X:Id, T:KResult, K:K)
          => declareWithLinkage(X:Id, T:KResult, K:K, internal)
          when isStaticType(T:KResult)
               andBool notBool isExternType(T:KResult)
          [structural] 
          
     syntax K ::= "declareOnly" "(" Id "," Type "," K ")"
     syntax K ::= "declareAndDefine" "(" Id "," Type "," K "," K ")"

     rule <k>
               declareWithLinkage(X:Id, T:KResult, NoInit, L:K)
               => declareOnly(X:Id, T:KResult, L:K)
          ...</k>
          <declarationOrder>...
               Tu:K |-> ListToK(_ (. => ListItem(X:Id)))
          ...</declarationOrder>
          <currTU> Tu:K </currTU>
          when L:K =/=K noLinkage
          [structural] 
     rule <k>
               declareWithLinkage(X:Id, T:KResult, K:K, L:K) 
               => declareAndDefine(X:Id, T:KResult, K:K, L:K)
          ...</k>
          <declarationOrder>...
               Tu:K |-> ListToK(_ (. => ListItem(X:Id)))
          ...</declarationOrder>
          <currTU> Tu:K </currTU>
          when K:K =/=K NoInit
               andBool L:K =/=K noLinkage
          [structural] 
          
     // fixme this terribly needs to be refactored.  I'm duplicating the above
     // two rules so I don't add locals to the declaration order
     rule declareWithLinkage(X:Id, T:KResult, NoInit, L:K) 
          => declareOnly(X, T, L)
          when L ==K noLinkage
          [structural] 
     rule declareWithLinkage(X:Id, T:KResult, K:K, L:K)
          => declareAndDefine(X, T, K, L)
          when (K =/=K NoInit)
               andBool (L ==K noLinkage)
          [structural] 
     
     // extern functions are no different than functions
     // fixme dangerous if someone marks it as static and extern.  can't tell
     rule t(_, qualifiedType(T:KResult, Extern)) => T:KResult
          when isFunctionType(T:KResult) 
          [structural]
     
     // fixme clean these up, they are so redundant
     // fixme unqualifying these is probably unsafe
     rule <k> 
               declareOnly(X:Id, T:KResult, external)
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
               declareOnly(X:Id, t(_, prototype(T:KResult)), external)
               => .K
          ...</k>
          <preLinkage>...
               Tu:K |-> map((Lnk:Map => Lnk:Map[external / X:Id]))
          ...</preLinkage>
          <preTypes>... Tu:K |-> map(Types:Map) ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Lnk:Map, X:Id) 
                    orBool Lnk:Map(X:Id) ==K external
               )
               andBool isTypeCompatible(unqualifyType(Types:Map(X:Id)),
                    unqualifyType(T:KResult))
          [structural]
     
     // fixme haven't thought about this much, is it right_
     rule <k> 
               declareOnly(X:Id, T:KResult, internal)
               => .K
          ...</k>
          <declarations>... .Set => SetItem(X:Id) ...</declarations>
          <preLinkage>...
               Tu:K |-> map((Lnk:Map => Lnk:Map[internal / X:Id]))
          ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((Types:Map => Types:Map[T:KResult / X:Id]))
          ...</preTypes>
          <currTU> Tu:K </currTU>
          when notBool $hasMapping(Lnk:Map, X:Id) 
               orBool Lnk:Map(X:Id) ==K internal
          [structural] 
     rule <k> 
               declareOnly(X:Id, T:KResult, noLinkage)
               => allocateType(Loc, T:KResult)
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, T:KResult)
          ...</k>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localVariables> Vars:List (. => ListItem(X:Id)) </localVariables>
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
               declareOnly(X:Id, T:KResult, noLinkage)
               => .K
          ...</k>
          <localVariables>... ListItem(X:Id) ...</localVariables>
          when (notBool isIncompleteType(T:KResult))
               andBool (notBool isStaticType(T:KResult))
               andBool (notBool isExternType(T:KResult))
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
     rule <k> 
               declareAndDefine(X:Id, T:KResult, K:K, external)
               => .
          ...</k>
          <declarations>... .Set => SetItem(X:Id) ...</declarations>
          <externalDefinitions> 
               Def:Map => Def:Map (X:Id |->
                    declarationObject(unqualifyType(T:KResult), Tu:K, K:K)) 
          </externalDefinitions>
          <br/>
          <preLinkage>...
               Tu:K |-> map((Lnk:Map => Lnk:Map[external / X:Id]))
          ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((Types:Map => Types:Map[T:KResult / X:Id]))
          ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Def:Map, X:Id)
                    orBool isFunctionType(T:KResult))
               andBool (notBool $hasMapping(Lnk:Map, X:Id)
                    orBool Lnk:Map(X:Id) ==K external)
          [structural, large]
          
     // case when it has a previous linkage (internal).  
     rule <k> 
               declareAndDefine(X:Id, T:KResult, K:K, external)
               => .
          ...</k>
          <declarations>... .Set => SetItem(X:Id) ...</declarations>
          <internalDefinitions>... 
               Tu:K |-> map((Def:Map 
               => Def:Map[
                    declarationObject(unqualifyType(T:KResult), Tu:K, K:K)
                    / X:Id])) 
          ...</internalDefinitions>
          <br/>
          <preLinkage>... Tu:K |-> map(Lnk:Map) ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((Types:Map => Types:Map[T:KResult / X:Id]))
          ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Def:Map, X:Id) 
                    orBool isFunctionType(T:KResult))
               andBool Lnk:Map(X:Id) ==K internal
          [structural, large]
          
     rule <k> 
               declareAndDefine(X:Id, T:KResult, K:K, internal)
               => .
          ...</k>
          <declarations>... .Set => SetItem(X:Id) ...</declarations>
          <internalDefinitions>... 
               Tu:K |-> map((Def:Map 
               => Def:Map[
                    declarationObject(unqualifyType(T:KResult), Tu:K, K:K)
                    / X:Id])) 
          ...</internalDefinitions>
          <br/>
          <preLinkage>...
               Tu:K |-> map((Lnk:Map => Lnk:Map[internal / X:Id]))
          ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((Types:Map => Types:Map[T:KResult / X:Id]))
          ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Def:Map, X:Id) 
                    orBool isFunctionType(T:KResult))
               andBool (notBool $hasMapping(Lnk:Map, X:Id)
                    orBool Lnk:Map(X:Id) ==K internal)
          [structural, large]
          
     syntax K ::= "defineAndInit" "(" Id "," Type "," K "," SymLoc ")"
          [strict(3)] 
     rule <k> 
               declareAndDefine(X:Id, T:KResult, K:K, noLinkage)
               => defineAndInit(X:Id, T:KResult,
                    figureInit(X:Id, T:KResult, K:K), Loc)
          ...</k>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localVariables> Vars:List (. => ListItem(X:Id)) </localVariables>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          // again, this should be needed statically, but not dynamically
          when notBool X:Id in Vars:List 
          [structural] 

     // this happens when we jump before a variable declaration with an
     // initialization in the same block
     rule <k> 
               declareAndDefine(X:Id, T:KResult, K:K, noLinkage)
               => justInit(figureInit(X:Id, T:KResult, K:K))
          ...</k>
          <localVariables>... ListItem(X:Id) ...</localVariables>
          [structural] 
          
     syntax K ::= "justInit" "(" K ")" [strict(1)]
     
     rule justInit(initValue(X:Id, T:KResult, K:K)) 
          => initialize(X:Id, T:KResult, K:K)
          [structural]
          
     rule <k> 
               defineAndInit(X:Id, _,
                    initValue(X:Id, T:KResult, K:K), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T:KResult)
                    ~> addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, T:KResult)
                    ~> initialize(X:Id, T:KResult, K:K)
          ...</k>
          <shouldInit> true </shouldInit>
          [structural] 
          
     rule <k> 
               defineAndInit(X:Id, _,
                    initValue(X:Id, T:KResult, _), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T:KResult)
                    ~> addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, T:KResult)
          ...</k>
          <shouldInit> false </shouldInit>
          [structural]
          
     rule <k> 
               figureInit-aux(_:Id, t(_, (incompleteArrayType(T:KResult) 
               => arrayType(T:KResult, N:Int))), initializer(_))
          ...</k>
          <incompleteLength> N:Int </incompleteLength>
          [structural] 

     syntax K ::= "allocateAndZeroIfAbsent" "(" Type "," Id ")"
     syntax K ::= "addToLinkage" "(" Id "," Type ")"
     syntax K ::= "addToGlobalEnv" "(" K "," SymLoc ")"
     syntax K ::= "addToLocalEnv" "(" K "," SymLoc ")"
     
     rule <k> addToEnv(X:Id, Loc:SymLoc) => addToGlobalEnv(X, Loc) ...</k>
          <currentFunction> file-scope </currentFunction>
          [structural] 
     rule <k> addToEnv(X:Id, Loc:SymLoc) => addToLocalEnv(X, Loc) ...</k>
          <currentFunction> F:K </currentFunction>
          when F:K =/=K file-scope
          [structural] 
          
     rule <k> addToGlobalEnv(X:Id, Loc:SymLoc) => . ...</k>
          <genv>... Tu:K |-> map((M':Map => M':Map[Loc / X:Id])) ...</genv>
          <currTU> Tu:K </currTU>
          <env> E:Map => E:Map[Loc / X:Id] </env>
          [structural] 
     rule <k> addToLocalEnv(X:Id, Loc:SymLoc) => . ...</k>
          <env> E:Map => E:Map[Loc / X:Id] </env>
          [structural] 
     
     syntax K ::= "defineUsingOldDeclaration" "(" Type "," Id "," K ")"
     
     // FIXME check prototypes
     rule [function-definition]:
          FunctionDefinition(typedDeclaration(T:KResult, X:Id), Blk:K) 
          => createNewFun(X:Id, T:KResult, safeBody(X:Id, Blk:K))
               ~> calculateGotoMap(X:Id, safeBody(X:Id, Blk:K))
          when isFunctionType(T:KResult)
          [structural]

     syntax K ::= "createNewFun" "(" Id "," K "," K ")" [function]
     
     rule createNewFun(X:Id, T:KResult, Blk:K)
          => declareFunction(
               X:Id, 
               T:KResult, 
               initializer(initFunction(
                    &(X:Id), 
                    functionObject(
                         X:Id, 
                         unqualifyType(T:KResult), 
                         Blk:K
                    )
               ))
          )
          
     syntax K ::= safeBody(Id, K) [function]
     rule safeBody(X:Id, Blk:K) 
          => Blk:K ~> Return(NothingExpression)
          when X:Id =/=K Identifier("main")
     rule safeBody(Identifier("main"), Blk:K) 
          => Blk:K ~> Return(tv(0, t(.Set, int)))
endmodule

