require "common-c-semantics.k"

module COMMON-SEMANTICS-DECLARATIONS-SYNTAX
     // id, type, initializer
     syntax K ::= "figureInit-aux" "(" Id "," Type "," K ")" [strict(3)]
     // type, translation unit it was defined in, definition
     syntax K ::= "declarationObject" "(" Type "," K "," K ")"
          [latex(\terminal{declObj(}{#1}, {#2}, {#3}\terminal{)})]
     
     syntax K ::= "external"
     syntax K ::= "internal"
     syntax K ::= "noLinkage"
     
     syntax KResult ::= "initializer" "(" K ")"
     syntax K ::= "startInit" "(" Type "," Id "," K ")"
      
     syntax K ::= "doDeclare" "(" K "," K ")" [strict(1)] 
               
     syntax K ::= "processFunctionBody" "(" K ")"
endmodule

module COMMON-SEMANTICS-DECLARATIONS-GENERAL
     imports COMMON-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS

     imports COMMON-SEMANTICS-DECLARATIONS-SYNTAX 

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
     rule <k> declareAndDefine(X:Id, T:KResult, K:K, external)
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
     rule <k> declareAndDefine(X:Id, T:KResult, K:K, external)
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
          
     rule <k> declareAndDefine(X:Id, T:KResult, K:K, internal)
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
     rule <k> declareAndDefine(X:Id, T:KResult, K:K, noLinkage)
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
     rule 
          <k> declareAndDefine(X:Id, T:KResult, K:K, noLinkage)
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

module COMMON-SEMANTICS-DECLARATIONS-INITIALIZATIONS
     imports COMMON-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS

     imports COMMON-SEMANTICS-DECLARATIONS-SYNTAX 
     
     syntax K ::= "te" "(" K "," Type ")" [klabel('te)]
     syntax K ::= "getInit"
     syntax K ::= "fillInit" "(" K ")"
     syntax K ::= "fillInit-aux" "(" K ")"
     syntax K ::= "fillInit" "(" KList ")"
     syntax C ::= "completeInitFragment" "(" K "," K ")"
     syntax KResult ::= "initializerFragment" "(" K ")"
     
     rule <k> getInit => initializer(K:K) ...</k>
          <savedInitialization> K:K => . </savedInitialization> 
          <currentObject> _:List => . </currentObject> 
          <currentSubObject> _:List => . </currentSubObject> 
          [structural] 

     rule <k> startInit(T:KResult, X:Id, CompoundInit(klist(L:KList)))
               => fillInit(L:KList) 
               ~> getInit
          ...</k>
          <incompleteLength> _ => 0 </incompleteLength>
          <currentSubObject>
               .List => ListItem(te(X:Id, T:KResult))
          </currentSubObject>
          <currentObject>
               .List => ListItem(te(X:Id, T:KResult))
          </currentObject>
          <savedInitialization>... .K => zero(X:Id) </savedInitialization> 
          when isUnionType(T:KResult) orBool isAggregateType(T:KResult)
          [structural] 
     
     rule fillInit((InitFragment(K:K, Exp:K),, L:KList))
          => fillInit(InitFragment(K:K, Exp:K)) 
          ~> fillInit(L:KList)
          [structural] 
     rule fillInit(.KList) => .
          [structural] 
     
     syntax ListItem ::= "next"
     syntax ListItem ::= "block"
     
     rule <currentSubObject> 
               ListItem(te(K:K, t(S:Set, arrayType(T:KResult, Len:Int))))
               => ListItem(te(K:K[0], T:KResult))
                    ListItem(te(K:K, t(S:Set, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          [structural] 
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, incompleteArrayType(T:KResult))))
               => ListItem(te(K:K[0], T:KResult))
                    ListItem(te(K:K, t(Se:Set, incompleteArrayType(T:KResult))))
          ...</currentSubObject>
          [structural] 
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K:K . F:Id, T:KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
          ...</currentSubObject>
          <structs>... 
               S:Id |-> aggregateInfo((typedDeclaration(T:KResult, F:Id),, _), _, _)
          ...</structs> 
          [structural] 
          
     // fixme these are terrible!
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, unionType(S:Id))))
               => ListItem(te(K:K . F:Id, T:KResult))
                    ListItem(te(K:K, t(Se:Set, unionType(S:Id))))
          ...</currentSubObject>
          <structs>... 
               S:Id |-> aggregateInfo((typedDeclaration(T:KResult, F:Id),, _), _, _) 
          ...</structs> 
          [structural] 
          
     // fixme should i worry about basetype here_
     rule [init-next-array-element]:
          <currentSubObject> 
               (next ListItem(te(K:K[N:Int], T:KResult)) 
                    => ListItem(te(K:K[N:Int +Int 1], T:KResult)))
               ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</currentSubObject>
          when Len:Int >Int N:Int +Int 1
          [structural] 
     rule [init-next-array-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K[N:Int], _:KResult)) => .List)
                    ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</currentSubObject>
          when notBool Len:Int >Int N:Int +Int 1
          [structural] 
     
     rule [init-next-incomplete-array-element]:
          <currentSubObject>
               (next ListItem(te(K:K[N:Int], T:KResult)) 
                    => ListItem(te(K:K[N:Int +Int 1], T:KResult))) 
               ListItem(te(K:K, t(_, incompleteArrayType(_))))
          ...</currentSubObject>
          [structural] 
     
     rule [init-next-struct-element]:
          <currentSubObject>
               next ListItem(te(K:K . F:Id, T:KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K:K . F':Id, T':KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),,
                    typedDeclaration(T':KResult, F':Id),, _), _, _)
          ...</structs> 
          when F':Id =/=K #NoName
          [structural, large] 
      
     rule [init-next-struct-element-noname]:
          <currentSubObject>
               next ListItem(te(K:K . F:Id, T:KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K:K . F':Id, T':KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),,
                    typedDeclaration(_, #NoName),,
                    typedDeclaration(T':KResult, F':Id),, _), _, _)
          ...</structs>
          [structural, large] 
          
     rule [init-next-struct-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K . F:Id, T:KResult)) => .)
                    ListItem(te(K:K, t(_, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id)), _, _)
          ...</structs> 
          [structural, large] 
     rule [init-next-struct-element-done-noname]:
          <currentSubObject>
               next (ListItem(te(K:K . F:Id, T:KResult)) => .)
                    ListItem(te(K:K, t(_, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, 
                    typedDeclaration(T:KResult, F:Id),,
                    typedDeclaration(_, #NoName)), _, _)
          ...</structs> 
          [structural, large] 
          
     rule [init-next-union-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K . _:Id, _:KResult)) => .List)
                    ListItem(te(K:K, t(_, unionType(_:Id))))
          ...</currentSubObject>
          [structural] 
          
     rule fillInit(InitFragment(NextInit, Exp:K)) => fillInit(Exp:K) 
          [structural] 
          
     syntax K ::= "finishCompoundInit" "(" List ")"
     rule <k> fillInit(CompoundInit(klist(L:KList)))
               => fillInit(L:KList)
                    ~> finishCompoundInit(
                    next ListItem(te(K:K, T:KResult)) Remainder:ListItem)
          ...</k>
          <currentSubObject> 
               (_:List => .) ListItem(te(K:K, T:KResult))
                    (Remainder:ListItem => .)
          </currentSubObject>
          <currentObject>
               (. => ListItem(te(K:K, T:KResult)))
          ...</currentObject>
          when isAggregateType(T:KResult) orBool isUnionType(T:KResult)
          [structural]
     rule <k> finishCompoundInit(L:List) => . ...</k>
          <currentObject>
               (ListItem(te(_:K, _:KResult)) => .)
          ...</currentObject>
          <currentSubObject> (_ => L:List) </currentSubObject>
          [structural] 
               
     context fillInit(InitFragment(HOLE, _)) 
     syntax K ::= "buildDesignator" "(" K ")"
     
     // note that these clear the current subobject cell, because it will be
     // repopulated when building the designator
     rule <k> fillInit(InitFragment(InFieldInit(F:Id, K':K), Exp:K))
               => fillInit(InitFragment(buildDesignator(
                    InFieldInit(F:Id, K':K)), Exp:K))
          ...</k>
          <currentObject> ListItem(te(K:K, T:KResult)) ...</currentObject>
          <currentSubObject>
               _:List => block ListItem(te(K:K, T:KResult))
          </currentSubObject>
          when isStructType(T:KResult) orBool isUnionType(T:KResult)
          [structural] 
     // fixme does this need to worry about incompleteLength_
     rule <k> fillInit(InitFragment(AtIndexInit(Index:K, K':K), Exp:K))
               => fillInit(InitFragment(
                    buildDesignator(AtIndexInit(Index:K, K':K)), Exp:K))
          ...</k>
          <currentObject> ListItem(te(K:K, T:KResult)) ...</currentObject>
          <currentSubObject>
               _:List => block ListItem(te(K:K, T:KResult))
          </currentSubObject>
          when isArrayType(T:KResult)
          [structural] 
          
     
     // fixme these are also too restrictive on type.  if we try to assign an
     // int to a long-int field, it will fail
     // i don't think this is true anymore
     rule <k> buildDesignator(InFieldInit(F:Id, More:K)) 
               => buildDesignator(More:K)
          ...</k>
          <currentSubObject> 
               block (.List => ListItem(te(K:K . F:Id, T:KResult)))
                    ListItem('te(K:K,, 't(_,, KL:KLabel(S:Id))))
          ...</currentSubObject>
          <structs>... 
               S:Id |-> aggregateInfo(_, (_ F:Id |-> T:KResult), _)
          ...</structs>
          when KL:KLabel ==KLabel 'structType 
          orBool KL:KLabel ==KLabel 'unionType
          [structural] 
          
     rule <k> buildDesignator(NextInit) => NextInit ...</k>
          <currentSubObject> (block => .List) ...</currentSubObject>
          [structural] 
          
     rule [innerType-arrayType]:
          innerType(t(_, arrayType(T:KResult, _:Int))) => T:KResult
     rule [innerType-incompleteArrayType]: 
          innerType(t(_, incompleteArrayType(T:KResult))) => T:KResult
     rule [innerType-flexibleArrayType]: 
          innerType(t(_, flexibleArrayType(T:KResult))) => T:KResult
     rule [innerType-qualifiedType]:
          innerType(t(_, qualifiedType(T:KResult, _))) => innerType(T:KResult)
     rule [innerType-pointerType]:
          innerType(t(_, pointerType(T:KResult))) => T:KResult
     rule [innerType-bitfieldType]:
          innerType(t(_, bitfieldType(T:KResult, _:Int))) => T:KResult
     rule [innerType-functionType]:
          innerType(t(_, functionType(T:KResult, _:KList))) => T:KResult

     context buildDesignator(AtIndexInit((HOLE => reval(HOLE)), _)) 
     rule <k> buildDesignator(AtIndexInit(tv(N:Int, _), More:K)) 
               => buildDesignator(More:K)
          ...</k>
          <currentSubObject> 
               block (.List => ListItem(te(K:K[N:Int], innerType(T:KResult))))
                    ListItem(te(K:K, T:KResult)) 
          ...</currentSubObject>
          when isArrayType(T:KResult)
          [structural] 
     
     syntax K ::= "popInit"
     
     syntax Int ::= getTopArrayUse(K) [function]
     rule getTopArrayUse(_:Id) => 0
     // +1 for length instead of index
     rule getTopArrayUse(_:Id[N:Int]) => N:Int +Int 1
     rule getTopArrayUse(K:K . _:Id) => getTopArrayUse(K:K)
     rule getTopArrayUse((K:K[N:Int])[_]) => getTopArrayUse(K:K[N:Int])
     rule getTopArrayUse((K:K . _:Id)[_]) => getTopArrayUse(K:K)
     
     syntax K ::= "initializeSingleInit" "(" K ")"
          
     rule (. => typeof(K)) ~> initializeSingleInit(K:K)
          [structural] 
     
     // fixme want to exclude strings, but not normal arrays
     rule <k> T':KResult ~> initializeSingleInit(K':K) => . ...</k>
          <currentSubObject>
               (.List => next) ListItem(te(K:K, T:KResult))
          ...</currentSubObject>
          <incompleteLength>
               N:Int => maxInt(N:Int, getTopArrayUse(K:K))
          </incompleteLength>
          <savedInitialization>... 
               .K => Computation(AllowWrite(K:K) := K':K) 
                    ~> possiblyMakeConst(T:KResult, K:K)
          </savedInitialization>
          when (isBasicType(T:KResult) 
                    orBool isPointerType(T:KResult) 
                    orBool isBitfieldType(T:KResult))
               andBool (notBool isStructType(T':KResult))
               andBool (notBool isUnionType(T':KResult))
          [structural]
     
     syntax K ::= "possiblyMakeConst" "(" Type "," K ")"
     
     rule possiblyMakeConst(T:KResult, K:K) => makeUnwritableSubObject(K)
          when isConstType(T)
          [structural]
     rule possiblyMakeConst(T:KResult, _) => .
          when notBool isConstType(T)
          [structural]
          
     // this is used to have an aggregate on the RHS of a compound init
     // fixme want to exclude strings, but not normal arrays
     syntax K ::= "initFromAggregateRHS" "(" K "," Type ")"
     rule T:KResult ~> initializeSingleInit(K:K) 
          => initFromAggregateRHS(K:K, T:KResult)
          when isStructType(T:KResult)
               orBool isUnionType(T:KResult)
          [structural] 
          
     syntax K ::= "initFromStructRHS" "(" K "," Type ")"
     rule <k> initFromAggregateRHS(K:K, t(S:Set, structType(I:Id)))
               => initFromStructRHS(K:K, t(S:Set, structType(I:Id)))
          ...</k>
          <currentSubObject>
               .List => findStruct(t(S:Set, structType(I:Id)))
          ...</currentSubObject>
          [structural] 
          
     syntax ListItem ::= "findStruct" "(" Type ")"
          
     rule <currentSubObject>
               findStruct(T:KResult) (ListItem(te(_, T':KResult)) => .List)
          ...</currentSubObject>
          when T:KResult =/=K T':KResult
          [structural] 
          
     // fixme unsafe, might have started to initialize other things
     rule <k> initFromStructRHS(K':K, t(_, structType(S:Id))) => . ...</k>
          <currentSubObject> 
               findStruct(t(_, structType(S:Id)))
                    ListItem(te(K:K, t(_, structType(S:Id)))) => next 
          ...</currentSubObject>
          <br/>
          <incompleteLength>
               N:Int => maxInt(N:Int, getTopArrayUse(K:K))
          </incompleteLength>
          <savedInitialization>...
               .K => Computation(AllowWrite(K:K) := K':K)
          </savedInitialization> 
          [structural, large] 
     
     rule fillInit(SingleInit(K:K)) => initializeSingleInit(K:K)
          when getKLabel(K:K) =/=KLabel 'Constant
          [structural] 

     rule [fillInit-string-array-eq]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit-aux(SingleInit(Constant(StringLiteral(S:String))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          when isCharType(T:KResult)
               andBool lengthString(S:String) ==Int Len:Int
          [structural] 
     rule [fillInit-wstring-array-eq]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit-aux(SingleInit(Constant(WStringLiteral(S:KList))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          when isWCharType(T:KResult)
               andBool lengthKList S:KList  ==Int Len:Int
          [structural] 
     rule [fillInit-string-array-lt]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit(SingleInit(Constant(
                    StringLiteral(S:String +String "\0"))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          when isCharType(T:KResult)
               andBool lengthString(S:String) <Int Len:Int
          [structural] 
     rule [fillInit-wstring-array-lt]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit(SingleInit(Constant(WStringLiteral((S:KList,, 0)))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          when isWCharType(T:KResult)
               andBool lengthKList S:KList <Int Len:Int
          [structural] 
     rule [fillInit-string-char]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit-aux(SingleInit(Constant(
                    StringLiteral(S:String +String "\0"))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, incompleteArrayType(T:KResult))))
          ...</currentSubObject>
          when isCharType(T:KResult)
          [structural] 
     rule [fillInit-wstring-wchar]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit-aux(SingleInit(Constant(
                    WStringLiteral((S:KList,, 0)))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult)) ListItem(te(_, t(_, incompleteArrayType(T:KResult))))
          ...</currentSubObject>
          when isWCharType(T:KResult)
          [structural]
     rule [fillInitAux-string-some]:
          <k> fillInit-aux(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit(initHead(S:String, T:KResult)) 
               ~> fillInit-aux(initTail(S:String))
          ...</k>
          <currentSubObject> ListItem(te(_:K, T:KResult)) ...</currentSubObject>
          when S:String =/=String ""
               andBool isCharType(T:KResult)
          [structural]
          
     syntax K ::= "initHead" "(" K "," K ")"
     syntax K ::= "initTail" "(" K ")"
     rule initHead(S:String, T:KResult)
          => SingleInit(tv(asciiString(firstChar(S:String)),
               t(getModifiers(T:KResult), char)))
          [structural, anywhere]
     
     rule initTail(S:String) 
          => SingleInit(Constant(StringLiteral(butFirstChar(S:String))))
          [structural, anywhere]
          
     rule [fillInitAux-wstring-some]:
          <k> 
               fillInit-aux(SingleInit(Constant(
                    WStringLiteral((N:Int,, S:KList)))))
               => fillInit(SingleInit(tv(N:Int, cfg:wcharut)))
                    ~> fillInit-aux(SingleInit(Constant(
                    WStringLiteral(S:KList)))) 
          ...</k>
          <currentSubObject> 
               ListItem(te(_:K, T:KResult))
          ...</currentSubObject>
          when isWCharType(T:KResult)
          [structural]
     // fixme not sure what happens in the case of   char *x = "";
     rule [fillInitAux-string-done]:
          fillInit-aux(SingleInit(Constant(StringLiteral("")))) => .
          [structural]
     rule [fillInitAux-wstring-done]:
          fillInit-aux(SingleInit(Constant(WStringLiteral(.KList)))) => .
          [structural] 
          
     // This rule assumes all unrollings have already occurred, so it needs to
     // be a rule. Alternatively, I've added the condition below which might be
     // enough.
     rule [fillInit-string-notchar]:
          <k> 
               fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => initializeSingleInit(Constant(StringLiteral(S:String)))
          ...</k>
          <currentSubObject> 
               ListItem(te(_:K, T:KResult)) 
          ...</currentSubObject>
          when notBool isCharType(T:KResult)
               andBool (isBasicType(T:KResult) orBool isPointerType(T:KResult)
                    orBool isBitfieldType(T:KResult))
          [structural] 
     rule [fillinit-wstring-notwchar]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => initializeSingleInit(Constant(WStringLiteral(S:KList)))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
          ...</currentSubObject>
          when notBool isWCharType(T:KResult)
               andBool (isBasicType(T:KResult) orBool isPointerType(T:KResult)
                    orBool isBitfieldType(T:KResult))
          [structural]
endmodule

module COMMON-SEMANTICS-DECLARATIONS-RESOLUTION
     imports COMMON-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS

     imports COMMON-SEMANTICS-DECLARATIONS-SYNTAX 
     
     syntax K ::= "canonicalizeTranslationUnitVariables"
     rule [unpack-TranslationUnit]:
          <k> TranslationUnit(TUName:String, Strings:K, K:K, P:String) 
               => preDeclareStrings(Strings:K)
               ~> klistToK(eraseKLabel('StmtCons, K:K))
          ...</k>
          <currTU> _ => TUName:String </currTU>
          <declarationOrder> 
               DeclOrder:Map => DeclOrder:Map[ListToK(.List) / TUName:String] 
          </declarationOrder>
          <internalLocations>
               ExtLoc:Map => ExtLoc:Map[map(.) / TUName:String]
          </internalLocations>
          <br/>
          <funTUs> Funs:Map => Funs:Map[map(.) / TUName:String] </funTUs>
          <translationUnits>...
               . => BagItem(TUName:String)
          ...</translationUnits>
          <preLinkage>
               Lnk:Map => Lnk:Map[map(.) / TUName:String]
          </preLinkage>
          <preTypes>
               Types:Map => Types:Map[map(.) / TUName:String]
          </preTypes>
          <br/>
          <internalDefinitions>
               Def:Map => Def:Map[map(.) / TUName:String]
          </internalDefinitions>
          <genv> Env:Map => Env:Map[map(.) / TUName:String] </genv>
          <gtypes> Gtypes:Map => Gtypes:Map[map(.) / TUName:String]</gtypes>
          <programText> M:Map => M:Map[P:String / TUName:String] </programText>
          when notBool $hasMapping(Env:Map, TUName:String)
          [structural, large]
          
     syntax K ::= "preDeclareStrings" "(" K ")"
     
     rule preDeclareStrings(klist((K:K,, L:KList)))
          => K ~> discard ~> preDeclareStrings(klist(L))
          [structural]
     rule preDeclareStrings(klist(.KList)) => .
          [structural]
     
     syntax K ::= "resolve" "(" K ")"
     rule <k> (. => resolve(Tu:K)) ~> resolveReferences ...</k>
          <translationUnits>... BagItem(Tu:K) => .Bag ...</translationUnits>
          [structural] 
          
     syntax K ::= "resolveLeftovers"
     rule <k> resolveReferences => resolveLeftovers ...</k>
          <translationUnits> .Bag </translationUnits>
          [structural] 
          
     rule <k> (.K =>
               addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T))
               ) ~> resolveLeftovers 
          ...</k>
          <currTU> _ => Tu </currTU>
          <externalLocations>... X |-> Loc:SymLoc ...</externalLocations>
          <leftoverExterns>...
               BagItem(leftover(Tu:K, X:Id, T:KResult)) => .Bag
          ...</leftoverExterns>
          [structural]
     rule <k> resolveLeftovers ...</k>
          <externalLocations> Locs:Map </externalLocations>
          <leftoverExterns>...
               BagItem(leftover(_, X:Id, _)) => .Bag
          ...</leftoverExterns>
          when notBool $hasMapping(Locs:Map, X:Id)
          [structural]
     
     rule <k> resolveLeftovers => .K ...</k>
          <leftoverExterns> .Bag </leftoverExterns>
          [structural]
               
     syntax K ::= "resolveInternal" "(" Id "," K "," K ")"
     syntax K ::= "resolveExternal" "(" Id "," K "," Bag "," K ")"
     syntax K ::= "resolveExternal'" "(" Id "," K "," Bag "," K "," SymLoc "," K ")"
          [strict(6)]
     
     // name, type, context, where defined
     syntax K ::= "recordFunTUInfo" "(" K "," Type "," K "," K ")"
     rule <k> recordFunTUInfo(X:Id, T:KResult, Tu:K, DefTu:K) => .K ...</k>
          <funTUs>...
               Tu:K |-> map((Funs:Map => Funs:Map[DefTu:K / X:Id]))
          ...</funTUs>
          when isFunctionType(T:KResult)
          [structural] 
     rule <k> recordFunTUInfo(_, T:KResult, _, _) => .K ...</k>
          when notBool isFunctionType(T:KResult)
          [structural] 
     
     // fixme
     // should be adding to env after figuring initializer
     // should be changing env to be correct env before figuring initializer
     syntax K ::= "resolveInternal'" "(" Id "," K "," K "," K ")" [strict(4)] 
     rule <k> 
               resolveInternal(X:Id, Tu:K, 
                    declarationObject(T:KResult, Tu:K, K:K))
               => resolveInternal'(X:Id, Tu:K, 
                    declarationObject(T:KResult, Tu:K, K:K), 
                    figureInit(X:Id, T:KResult, K:K))
          ...</k>
          <currTU> _ => Tu:K </currTU>
          [structural] 
     rule <k> 
               resolveInternal'(X:Id, Tu:K, 
                    declarationObject(_, Tu:K, _), 
                    initValue(X:Id, T:KResult, K:K))
               => allocateType(Loc, T:KResult)
                    ~> addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, T:KResult)
                    ~> initialize(X:Id, T:KResult, K:K)
                    ~> recordFunTUInfo(X:Id, T:KResult, Tu:K, Tu:K)
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currTU> _ => Tu:K </currTU>
          [structural] 
               
     rule <k> 
               resolveExternal(X:Id, Tu:K, Units:Bag, 
                    declarationObject(T:KResult, DefTu:K, K:K))
               => resolveExternal'(X:Id, Tu:K, Units:Bag,
                    declarationObject(T:KResult, DefTu:K, K:K), Loc, 
                    figureInit(X:Id, T:KResult, K:K))
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          [structural] 
     rule <k> 
               ( .K
               => addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, T:KResult)
                    ~> recordFunTUInfo(X:Id, T:KResult, Tu':K, DefTu:K)
               ) ~> resolveExternal'(X:Id, _:K, 
                    ((BagItem(Tu':K) => .) _:Bag),
                    declarationObject(_, DefTu:K, _), Loc:SymLoc, 
                    initValue(X:Id, T:KResult, _:K))
          ...</k>
          <br/>
          <currTU> _ => Tu':K </currTU>
          <preLinkage>...
               Tu':K |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          [structural, large] 
     rule <k> 
               resolveExternal'(X:Id, Tu:K, .Bag,
                    declarationObject(_, DefTu:K, _), Loc:SymLoc,
                    initValue(X:Id, T:KResult, K:K))
               => allocateType(Loc, T:KResult)
                    ~> addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, T:KResult)
                    ~> initialize(X:Id, T:KResult, K:K)
                    ~> recordFunTUInfo(X:Id, T:KResult, Tu:K, DefTu:K)
          ...</k>
          <currTU> _ => Tu:K </currTU>
          <externalLocations>
               Locs:Map => Locs:Map[Loc / X:Id]
          </externalLocations>
          when notBool $hasMapping(Locs:Map, X:Id)
          [structural] 
     rule <k>
               resolveExternal'(X:Id, _,
                    ((BagItem(Tu:K) => .) _:Bag), _, _, _)
          ...</k>
          <preLinkage>... Tu:K |-> map(M:Map) ...</preLinkage>
          when notBool $hasMapping(M:Map, X:Id)
          [structural] 
     rule [resolveExternal-internal]:
          <k>
               resolveExternal'(X:Id, _,
                    ((BagItem(Tu:K) => .) _:Bag), _, _, _)
          ...</k>
          <preLinkage>... Tu:K |-> map((_ X:Id |-> internal)) ...</preLinkage>
          [structural] 
     
     rule <k> (. => resolveInternal(X:Id, Tu:K, K:K)) ~> resolve(Tu:K) ...</k>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> internal => .Map)))
          ...</preLinkage>
          <internalDefinitions>...
               Tu:K |-> map((_ (X:Id |-> K:K => .Map)))
          ...</internalDefinitions>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .List) _)
          ...</declarationOrder>
          [structural] 
          
     // static variable without an initializer
     rule <k> 
               (. => resolveInternal(X:Id, Tu:K, 
                    declarationObject(unqualifyType(T:KResult), Tu:K, 
                    initializer(zero(X:Id))))) ~> resolve(Tu:K)
          ...</k>
          <br/>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> internal => .Map)))
          ...</preLinkage>
          <internalDefinitions>...
               Tu:K |-> map(Defs:Map)
          ...</internalDefinitions>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .List) _)
          ...</declarationOrder>
          <preTypes>...
               Tu:K |-> map((_ (X:Id |-> T:KResult => .Map)))
          ...</preTypes>
          when notBool $hasMapping(Defs:Map, X:Id)
          [structural, large] 
          
     rule <k>
               (. => resolveExternal(X:Id, Tu:K, Units:Bag, K:K)) 
               ~> resolve(Tu:K)
          ...</k>
          <br/>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> external => .Map)))
          ...</preLinkage>
          <externalDefinitions>
               ExtDefs:Map (X:Id |-> K:K => .Map)
          </externalDefinitions>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .List) _)
          ...</declarationOrder>
          <translationUnits> Units:Bag </translationUnits>
          when notBool $hasMapping(ExtDefs:Map, X:Id)
          [structural, large] 

     
     // fixme this means we've declared it twice (like a prototype maybe_), but
     // already handled it.  happening with getc in clib.c
     rule <k> resolve(Tu:K) ...</k>
          <preLinkage>... Tu:K |-> map(Lnk:Map) ...</preLinkage>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <externalDefinitions> ExtDefs:Map </externalDefinitions>
          <internalDefinitions> IntDefs:Map </internalDefinitions>
          when notBool ($hasMapping(Lnk:Map, X:Id))
               andBool (notBool $hasMapping(ExtDefs:Map, X:Id))
               andBool (notBool $hasMapping(IntDefs:Map, X:Id))
          [structural] 
     
     // function prototypes
     rule <k> 
               (. => 
                    giveType(X:Id, T:KResult)
                    // fixme fake Tu
                    ~> recordFunTUInfo(X:Id, T:KResult, Tu:K, Tu:K)
               )
               ~> resolve(Tu:K) 
          ...</k>
          <br/>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((_ X:Id |-> t(_, prototype(T:KResult))))
          ...</preTypes>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <br/>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <currTU> _ => Tu:K </currTU>
          when isFunctionType(T:KResult)
               andBool (notBool $hasMapping(Defs:Map, X:Id))
          [structural, large] 
          
     // c1x 6.9.2:2 A declaration of an identifier for an object that has file
     // scope without an initializer, and without a storage-class specifier or
     // with the storage-class specifier static, constitutes a tentative
     // definition. If a translation unit contains one or more tentative
     // definitions for an identifier, and the translation unit contains no
     // external definition for that identifier, then the behavior is exactly
     // as if the translation unit contains a file scope declaration of that
     // identifier, with the composite type as of the end of the translation
     // unit, with an initializer equal to 0
     rule <k> 
               (. 
               => allocateType(Loc, unqualifyType(T:KResult))
                    ~> addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, unqualifyType(T:KResult))
                    ~> zero(X:Id)
               ) ~> resolve(Tu:K)
          ...</k>
          <br/>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((_ X:Id |-> T:KResult))
          ...</preTypes>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <br/>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <currTU> _ => Tu:K </currTU>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <externalLocations>
               Locs:Map => Locs:Map[Loc / X:Id]
          </externalLocations>
          when notBool $hasMapping(Locs:Map, X:Id)
               andBool (notBool isFunctionType(T:KResult))
               andBool (notBool isIncompleteType(T:KResult))
               andBool (notBool isExternType(T:KResult))
               andBool (notBool $hasMapping(Defs:Map, X:Id))
          [structural, large] 
     syntax K ::= "leftover" "(" K "," K "," K ")"
     rule [resolve-extern-object-nomapping]:
          <k> resolve(Tu:K) ...</k>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((_ X:Id |-> T:KResult))
          ...</preTypes>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <leftoverExterns>...
               .Bag => BagItem(leftover(Tu:K, X:Id, T:KResult))
          ...</leftoverExterns>
          when notBool isFunctionType(T:KResult)
               andBool isExternType(T:KResult)
               andBool notBool $hasMapping(Defs:Map, X:Id)
          [structural] 
          
     rule <k> resolve(Tu:K) => . ...</k>
          <preLinkage>... Tu:K |-> map(.) ...</preLinkage>
          <internalDefinitions>... Tu:K |-> map(.) ...</internalDefinitions>
          <declarationOrder>... Tu:K |-> ListToK(.List) ...</declarationOrder>
          [structural] 
                    
     // need to worry about things that don't have definitions that may
     // override externs
     // want to make it so env is always correct local env, so need to have a
     // set of global envs, one for each tu
     
     rule [initialize-function]:
          <k> 
               initFunction(tv(Loc:SymLoc, 
                    t(_, pointerType(T:KResult))), Fun:KResult) 
               => .K
          ...</k>
          <functions> M:Map => M:Map[Fun / Loc] </functions>
          when isFunctionType(T)
               andBool notBool $hasMapping(M, Loc)
          [structural]
          
     rule <k> readFunction(Loc:SymLoc) => Fun  ...</k>
          <functions>... Loc |-> Fun:KResult ...</functions>
          [structural]
     
endmodule

module COMMON-SEMANTICS-DECLARATIONS-ENUMS
     imports COMMON-SEMANTICS-DECLARATIONS-SYNTAX 
     imports COMMON-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS
     
     syntax K ::= "fillEnums" "(" K ")"
     syntax K ::= "fillEnums-aux" "(" K "," K ")"
     rule EnumDef(X:Id, L:K) => fillEnums(EnumDef(X, L))
          [structural] 
     rule fillEnums(K:K) => fillEnums-aux(K, tv(0, t(.Set, int))) 
          [structural]
     rule fillEnums-aux(EnumDef(X:Id, klist((EnumItem(E:Id),, L:KList))), K:K) 
          => doDeclare(typedDeclaration(t(.Set, int), E), SingleInit(K))
               ~> fillEnums-aux(EnumDef(X, klist(L)), 
               K + tv(1, t(.Set, int)))
          [structural] 
     rule fillEnums-aux(EnumDef(X:Id, klist((
               EnumItemInit(E:Id, Exp:K),, L:KList))), _)
          => doDeclare(typedDeclaration(t(.Set, int), E), SingleInit(Exp))
               ~> fillEnums-aux(EnumDef(X, klist(L)), 
               Exp + tv(1, t(.Set, int)))
          when Exp =/=K NothingExpression
          [structural] 
     rule fillEnums-aux(EnumDef(_:Id, klist(.KList)), _) => . 
          [structural] 
endmodule

module COMMON-C-DECLARATIONS
     imports COMMON-SEMANTICS-DECLARATIONS-GENERAL 
     imports COMMON-SEMANTICS-DECLARATIONS-INITIALIZATIONS 
     imports COMMON-SEMANTICS-DECLARATIONS-ENUMS 
     imports COMMON-SEMANTICS-DECLARATIONS-RESOLUTION 

endmodule
