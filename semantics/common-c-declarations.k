require "common-c-semantics.k"

module COMMON-SEMANTICS-DECLARATIONS-INCLUDE
     imports COMMON-INCLUDE 
     syntax K ::= "figureInit-aux" "(" Id "," Type "," K ")" [strict(3)] // id, type, initializer
     syntax K ::= "declarationObject" "(" Type "," K "," K ")" [latex(\terminal{declObj(}{#1}, {#2}, {#3}\terminal{)})] // type, translation unit it was defined in, definition
     
     syntax K ::= "external"
     syntax K ::= "internal"
     syntax K ::= "noLinkage"
     
     syntax KResult ::= "initializer" "(" K ")"
     syntax K ::= "startInit" "(" Type "," Id "," K ")"
      
     syntax K ::= "doDeclare" "(" K "," K ")" [strict(1)] 
               
     syntax K ::= "processFunctionBody" "(" K ")"
endmodule

module COMMON-SEMANTICS-DECLARATIONS-GENERAL
     imports COMMON-SEMANTICS-DECLARATIONS-INCLUDE 

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

     rule <k> figureInit(X:Id, T:KResult, CodeLoc(K:K, L:K)) 
               => CodeLoc(.K, L:K)
               ~> figureInit(X:Id, T:KResult, K:K) 
          ...</k>
          [structural]
          
     
     // aggregates
     rule <k> figureInit(X:Id, T:KResult, CompoundInit(L:K))
               => giveType(X:Id, T:KResult)
               ~> figureInit-aux(X:Id, T:KResult, startInit(T:KResult, X:Id, CompoundInit(L:K)))
          ...</k>
          when (isAggregateType(T:KResult) orBool isUnionType(T:KResult)) 
          //andBool notBool isIncompleteType(T:KResult)
          [structural] 
     rule <k> figureInit(
               X:Id, 
               t(Se:Set, arrayType(T:KResult, Len:Int)), 
               (SingleInit(Constant(StringLiteral(S:String))) => CompoundInit(klist(InitFragment(NextInit, SingleInit(Constant(StringLiteral(S:String)))))))
          )
          ...</k>
          when isCharType(T:KResult)
          andBool (lengthString(S:String) <=Int Len:Int)
          [structural]

      rule <k> figureInit(
                  X:Id, 
                  t(Se:Set, arrayType(T:KResult, Len:Int)), 
                  (SingleInit(Constant(WStringLiteral(S:KList))) => CompoundInit(klist(InitFragment(NextInit, SingleInit(Constant(WStringLiteral(S:KList)))))))
            )
            ...</k>
            when isWCharType(T:KResult)
            andBool (lengthKList S <=Int Len:Int)
            [structural] 
     
     rule <k> figureInit(X:Id, t(_, (incompleteArrayType(T:KResult) 
               => arrayType(T:KResult, lengthString(S:String) +Int 1))), SingleInit(Constant(StringLiteral(S:String)))) 
          ...</k>
          when isCharType(T:KResult)
          [structural]

     rule <k> figureInit(X:Id, t(_, (incompleteArrayType(T:KResult) 
               => arrayType(T:KResult, lengthKList S:KList +Int 1))), SingleInit(Constant(WStringLiteral(S:KList)))) 
          ...</k>
          when isWCharType(T:KResult)
          [structural] 
          
     rule <k> figureInit(X:Id, t(Se:Set, incompleteArrayType(T:KResult)), CompoundInit(klist(InitFragment(NextInit, SingleInit(Constant(StringLiteral(S:String)))))))
               => figureInit(X:Id, t(Se:Set, incompleteArrayType(T:KResult)), SingleInit(Constant(StringLiteral(S:String))))
          ...</k>
          [structural] 
          
     // this comes from function declarations.  should probably adjust this
     rule <k> figureInit(X:Id, T:KResult, initializer(K:K))
               => figureInit-aux(X:Id, T:KResult, initializer(K:K))
          ...</k>
          [structural] 

     rule <k> figureInit-aux(X:Id, T:KResult, initializer(K:K))
               => initValue(X:Id, T:KResult, K:K)
          ...</k>
          when notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
          andBool notBool isConstType(T:KResult)
          [structural]
     rule <k> figureInit-aux(X:Id, T:KResult, initializer(K:K))
               => initValue(X:Id, T:KResult, (K:K ~> makeUnwritableVar(X:Id)))
          ...</k>
          when notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
          andBool isConstType(T:KResult)
          [structural]
     
     // base types
     rule <k> figureInit(X:Id, T:KResult, SingleInit(K:K))
               => figureInit-aux(X:Id, T:KResult, initializer(Computation(AllowWrite(X:Id) := K:K)))
          ...</k>
          when notBool isArrayType(T:KResult)
          [structural] 
     // c1x 6.7.8:11
     rule <k> figureInit(X:Id, T:KResult, CompoundInit(klist(InitFragment(NextInit, SingleInit(K:K)))))
               => figureInit-aux(X:Id, T:KResult, initializer(Computation(AllowWrite(X:Id) := K:K)))
          ...</k>
          when notBool (isAggregateType(T:KResult) orBool isUnionType(T:KResult))
          [structural] 
          
     rule DeclarationDefinition(InitNameGroup(T:KResult, klist((K:K,, K':K,, L:KList))))
          => DeclarationDefinition(InitNameGroup(T:KResult, klist(K:K)))
          ~> DeclarationDefinition(InitNameGroup(T:KResult, klist((K':K,, L:KList))))
          [structural]
     rule DeclarationDefinition(InitNameGroup(T:KResult, klist(InitName(N:K, Exp:K))))
               => doDeclare(SingleName(T:KResult, N:K), Exp:K)
          [structural]
               
     rule Typedef(NameGroup(T:KResult, klist((K:K,, L:KList)))) 
          => defineType(SingleName(T:KResult, K:K))
          ~> Typedef(NameGroup(T:KResult, klist(L:KList)))
          [structural]
     rule Typedef(NameGroup(T:KResult, klist(.KList))) => .K
          [structural]

     rule <k> defineType(typedDeclaration(T:KResult, X:Id)) 
               => giveType(typedef(X:Id), T:KResult) 
          ...</k>
          [structural] 
               
     syntax K ::= "declareFunction" "(" Id "," Type "," K ")"
     syntax K ::= "declareExternalVariable" "(" Id "," Type "," K ")"
     syntax K ::= "declareInternalVariable" "(" Id "," Type "," K ")"
     
     // function definition
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), K:K) 
               => declareFunction(X:Id, T:KResult, K:K)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          when notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
               andBool isFunctionType(T:KResult)
          [structural]
          
     // fixme there are still no nested functions though, right_
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), NoInit) 
               => addToEnv(X:Id, Loc)
               ~> giveType(X:Id, unqualifyType(T:KResult))
          ...</k>
          <externalLocations>... X:Id |-> Loc:SymLoc ...</externalLocations> 
          <currentFunction> F:K </currentFunction>
          when notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
               andBool isFunctionType(T:KResult)
               andBool F:K =/=K file-scope
          [structural] 
     // fixme i believe this is for local declarations of external library functions
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), NoInit) 
               => giveType(X:Id, unqualifyType(T:KResult))
          ...</k>
          <externalLocations> Locs:Map </externalLocations> 
          <currentFunction> F:K </currentFunction>
          when (notBool isIncompleteType(T:KResult)) // I'd like to get rid of this cleanly
               andBool (isFunctionType(T:KResult))
               andBool (F:K =/=K file-scope)
               andBool (notBool $hasMapping(Locs:Map, X:Id))
          [structural]
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), K:K)
               => declareExternalVariable(X:Id, T:KResult, #if K:K ==K NoInit #then NoInit #else CodeLoc(K:K, L:CabsLoc) #fi)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          <currentProgramLoc> L:CabsLoc </currentProgramLoc>
          // if notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
          when notBool isFunctionType(T:KResult)
          [structural] 
     rule <k> doDeclare(typedDeclaration(T:KResult, X:Id), K:K) 
               => declareInternalVariable(X:Id, T:KResult, K:K)
          ...</k>
          <currentFunction> F:K </currentFunction>
          // if notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
          when notBool isFunctionType(T:KResult)
               andBool F:K =/=K file-scope
          [structural] 
          
     //- external variables
     // feature request : nice to have MapList
     
     // function definition
     rule <k> declareFunction(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, external)
          ...</k>
          when notBool isStaticType(T:KResult)
               andBool K:K =/=K NoInit
          [structural] 

     rule <k> declareFunction(X:Id, T:KResult, NoInit)
               => declareWithLinkage(X:Id, t(.Set, prototype(T:KResult)), NoInit, external)
          ...</k>
          when notBool isStaticType(T:KResult)
          [structural] 
          
     // fixme not handling internal prototypes
     rule <k> declareFunction(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, internal)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          when isStaticType(T:KResult)
          [structural] 
          
          
     
     syntax K ::= "declareWithLinkage" "(" Id "," Type "," K "," K ")" // id, type, possible init, linkage (external, internal, noLinkage)
     
     //- internal variables
     
     // fixme need to look for bad use
     rule <k> declareInternalVariable(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, noLinkage)
          ...</k>
          when notBool isStaticType(T:KResult)
          andBool notBool isExternType(T:KResult)
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
               Tu:K |-> map((Locs:Map => Locs:Map[Loc / kpair(X:Id, BlockNum:Int)])) 
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
               => defineAndInit(X:Id, unqualifyType(T:KResult), figureInit(X:Id, removeStorageSpecifiers(T:KResult), K:K), Loc)
          ...</k>
          <internalLocations>... 
               Tu:K |-> map((Locs:Map => Locs:Map[Loc / kpair(X:Id, BlockNum:Int)])) 
          ...</internalLocations>
          <br/>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currTU> Tu:K </currTU>
          when (isStaticType(T:KResult))
          andBool (notBool isExternType(T:KResult))
          andBool (K:K =/=K NoInit)
          andBool (notBool $hasMapping(Locs:Map, kpair(X:Id, BlockNum:Int)))
          [structural, large] 
                    
     // this is essentially defineandinit, but that checks if type has been seen for allocation
     syntax K ::= "reseenStatic" "(" Id "," Type "," K "," SymLoc ")" [strict(3)] 
     rule <k> declareInternalVariable(X:Id, T:KResult, K:K)
               => reseenStatic(X:Id, unqualifyType(T:KResult), figureInit(X:Id, removeStorageSpecifiers(T:KResult), K:K), Loc)
          ...</k>
          <internalLocations>... Tu:K |-> map((_ kpair(X:Id, BlockNum:Int) |-> Loc:SymLoc)) ...</internalLocations>
          <br/>
          <blockHistory> ListItem(BlockNum:Int) ...</blockHistory>
          <currTU> Tu:K </currTU>
          when isStaticType(T:KResult)
          andBool notBool isExternType(T:KResult)
          andBool K:K =/=K NoInit
          [structural, large] 
          
     rule <k> reseenStatic(X:Id, _, initValue(X:Id, T:KResult, _), Loc:SymLoc)
               => addToEnv(X, Loc)
               ~> giveType(X, T)
          ...</k>
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
     rule <k> declareExternalVariable(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, external)
          ...</k>
          when notBool isStaticType(T:KResult)
          andBool notBool isExternType(T:KResult)
          [structural] 
     rule <k> declareExternalVariable(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, external)
          ...</k>
          <preLinkage>... Tu:K |-> map(Linkage:Map) ...</preLinkage>
          <currTU> Tu:K </currTU>
          when notBool isStaticType(T:KResult)
          andBool isExternType(T:KResult)
          andBool notBool $hasMapping(Linkage:Map, X:Id)
          [structural] 
     // not triggering
     rule [declareExtern-again]:
          <k> declareExternalVariable(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, Linkage:Map(X:Id))
          ...</k>
          <preLinkage>... Tu:K |-> map(Linkage:Map) ...</preLinkage>
          <currTU> Tu:K </currTU>
          when notBool isStaticType(T:KResult)
          andBool isExternType(T:KResult)
          andBool $hasMapping(Linkage:Map, X:Id)
          [structural] 
     rule <k> declareExternalVariable(X:Id, T:KResult, K:K)
               => declareWithLinkage(X:Id, T:KResult, K:K, internal)
          ...</k>
          when isStaticType(T:KResult)
          andBool notBool isExternType(T:KResult)
          [structural] 
          
     syntax K ::= "declareOnly" "(" Id "," Type "," K ")"
     syntax K ::= "declareAndDefine" "(" Id "," Type "," K "," K ")"

     rule <k> declareWithLinkage(X:Id, T:KResult, NoInit, L:K) => declareOnly(X:Id, T:KResult, L:K) ...</k>
          <declarationOrder>... Tu:K |-> ListToK(_ (. => ListItem(X:Id))) ...</declarationOrder>
          <currTU> Tu:K </currTU>
          when L:K =/=K noLinkage
          [structural] 
     rule <k> declareWithLinkage(X:Id, T:KResult, K:K, L:K) => declareAndDefine(X:Id, T:KResult, K:K, L:K) ...</k>
          <declarationOrder>... Tu:K |-> ListToK(_ (. => ListItem(X:Id))) ...</declarationOrder>
          <currTU> Tu:K </currTU>
          when K:K =/=K NoInit
          andBool L:K =/=K noLinkage
          [structural] 
          
     // fixme this terribly needs to be refactored.  I'm duplicating the above two rules so I don't add locals to the declaration order
     rule <k> declareWithLinkage(X:Id, T:KResult, NoInit, L:K) => declareOnly(X:Id, T:KResult, L:K) ...</k>
          // <declarationOrder>... Tu:K |-> ListToK(_ (. => ListItem(X:Id))) ...</declarationOrder>
          <currTU> Tu:K </currTU>
          when L:K ==K noLinkage
          [structural] 
     rule <k> declareWithLinkage(X:Id, T:KResult, K:K, L:K) => declareAndDefine(X:Id, T:KResult, K:K, L:K) ...</k>
          // <declarationOrder>... Tu:K |-> ListToK(_ (. => ListItem(X:Id))) ...</declarationOrder>
          <currTU> Tu:K </currTU>
          when K:K =/=K NoInit
          andBool L:K ==K noLinkage
          [structural] 
     
     // extern functions are no different than functions
     // fixme dangerous if someone marks it as static and extern.  can't tell
     rule t(_, qualifiedType(T:KResult, Extern)) => T:KResult
          when isFunctionType(T:KResult) 
          [structural]
     
     // fixme clean these up, they are so redundant
     // fixme unqualifying these is probably unsafe
     rule <k> declareOnly(X:Id, T:KResult, external)
               => .K
          ...</k>
          <declarations>... .Set => SetItem(X) ...</declarations>
          <preLinkage>... Tu |-> map((LinkageMap => LinkageMap[external / X])) ...</preLinkage>
          <preTypes>... Tu |-> map((TypesMap => TypesMap[T / X])) ...</preTypes>
          <currTU> Tu:K </currTU>
          when ((notBool $hasMapping(LinkageMap, X))
                    orElseBool (LinkageMap(X) ==K external)
               ) andBool (
                    (notBool $hasMapping(TypesMap, X))
                    // orBool Types:Map(X:Id) ==K prototype(T:KResult)
                    orElseBool isTypeCompatible(unqualifyType(TypesMap(X)), unqualifyType(T))
               )
          [structural] 
          
     rule <k> declareOnly(X:Id, t(_, prototype(T:KResult)), external)
               => .K
          ...</k>
          //<br/>
          <preLinkage>... Tu:K |-> map((Linkage:Map => Linkage:Map[external / X:Id])) ...</preLinkage>
          <preTypes>... Tu:K |-> map(Types:Map) ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Linkage:Map, X:Id) 
                    orBool Linkage:Map(X:Id) ==K external
               )
               andBool isTypeCompatible(unqualifyType(Types:Map(X:Id)), unqualifyType(T:KResult))
          [structural]
     
     // fixme haven't thought about this much, is it right_
     rule <k> declareOnly(X:Id, T:KResult, internal)
               => .K
          ...</k>
          <declarations>... .Set => SetItem(X:Id) ...</declarations>
          //<br/>
          <preLinkage>... Tu:K |-> map((Linkage:Map => Linkage:Map[internal / X:Id])) ...</preLinkage>
          <preTypes>... Tu:K |-> map((Types:Map => Types:Map[T:KResult / X:Id])) ...</preTypes>
          <currTU> Tu:K </currTU>
          when notBool $hasMapping(Linkage:Map, X:Id) 
          orBool Linkage:Map(X:Id) ==K internal
          [structural] 
     rule <k> declareOnly(X:Id, T:KResult, noLinkage)
               => allocateType(Loc, T:KResult)
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, T:KResult)
          ...</k>
          //<br/>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localVariables> Vars:List (. => ListItem(X:Id)) </localVariables>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          when (notBool isIncompleteType(T:KResult))
          andBool (notBool isStaticType(T:KResult))
          andBool (notBool isExternType(T:KResult))
          andBool (notBool X:Id in Vars) // this should be here statically, but not dynamically
          [structural]
     rule // same as above, but for the case where the variable has already been declared.  this is seen if we goto earlier in the same block
          <k> declareOnly(X:Id, T:KResult, noLinkage)
               => .K
          ...</k>
          <localVariables>... ListItem(X:Id) ...</localVariables>
          when (notBool isIncompleteType(T:KResult))
          andBool (notBool isStaticType(T:KResult))
          andBool (notBool isExternType(T:KResult))
          [structural] 
     
     /*@ \fromStandard{\source[n1570]{\para{6.2.2}{4}}}{
     For an identifier declared with the storage-class specifier \cinline{extern} in a scope in which a prior declaration of that identifier is visible, if the prior declaration specifies internal or external linkage, the linkage of the identifier at the later declaration is the same as the linkage specified at the prior declaration. If no prior declaration is visible, or if the prior declaration specifies no linkage, then the identifier has external linkage. 
     }*/
     // exception to multiple definitions for functions since we consider prototypes to be definitions to some extent
     // case when it has no previous linkage, or previous linkage is external
     rule <k> declareAndDefine(X:Id, T:KResult, K:K, external)
               => .K
          ...</k>
          <declarations>... .Set => SetItem(X:Id) ...</declarations>
          //<br/>
          <externalDefinitions> 
               Def:Map => Def:Map (X:Id |-> declarationObject(unqualifyType(T:KResult), Tu:K, K:K)) 
          </externalDefinitions>
          <br/>
          <preLinkage>... Tu:K |-> map((Linkage:Map => Linkage:Map[external / X:Id])) ...</preLinkage>
          <preTypes>... Tu:K |-> map((Types:Map => Types:Map[T:KResult / X:Id])) ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Def:Map, X:Id) orBool isFunctionType(T:KResult))
          andBool (notBool $hasMapping(Linkage:Map, X:Id) orBool Linkage:Map(X:Id) ==K external)
          [structural, large]
          
     // case when it has a previous linkage (internal).  
     rule <k> declareAndDefine(X:Id, T:KResult, K:K, external)
               => .K
          ...</k>
          <declarations>... .Set => SetItem(X:Id) ...</declarations>
          //<br/>
          // <externalDefinitions> Def:Map => Def:Map (X:Id |-> declarationObject(unqualifyType(T:KResult), Tu:K, K:K)) </externalDefinitions>
          <internalDefinitions>... Tu:K |-> map((Def:Map => Def:Map[declarationObject(unqualifyType(T:KResult), Tu:K, K:K) / X:Id])) ...</internalDefinitions>
          <br/>
          <preLinkage>... Tu:K |-> map(Linkage:Map) ...</preLinkage>
          <preTypes>... Tu:K |-> map((Types:Map => Types:Map[T:KResult / X:Id])) ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Def:Map, X:Id) orBool isFunctionType(T:KResult))
          andBool Linkage:Map(X:Id) ==K internal
          [structural, large]
          
     rule <k> declareAndDefine(X:Id, T:KResult, K:K, internal)
               => .K
          ...</k>
          <declarations>... .Set => SetItem(X:Id) ...</declarations>
          //<br/>
          <internalDefinitions>... Tu:K |-> map((Def:Map => Def:Map[declarationObject(unqualifyType(T:KResult), Tu:K, K:K) / X:Id])) ...</internalDefinitions>
          <br/>
          <preLinkage>... Tu:K |-> map((Linkage:Map => Linkage:Map[internal / X:Id])) ...</preLinkage>
          <preTypes>... Tu:K |-> map((Types:Map => Types:Map[T:KResult / X:Id])) ...</preTypes>
          <currTU> Tu:K </currTU>
          when (notBool $hasMapping(Def:Map, X:Id) orBool isFunctionType(T:KResult))
          andBool (notBool $hasMapping(Linkage:Map, X:Id) orBool Linkage:Map(X:Id) ==K internal)
          [structural, large]
          
     syntax K ::= "defineAndInit" "(" Id "," Type "," K "," SymLoc ")" [strict(3)] 
     rule <k> declareAndDefine(X:Id, T:KResult, K:K, noLinkage)
               => defineAndInit(X:Id, T:KResult, figureInit(X:Id, T:KResult, K:K), Loc)
          ...</k>
          //<br/>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localVariables> Vars:List (. => ListItem(X:Id)) </localVariables>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          when notBool X:Id in Vars:List // again, this should be needed statically, but not dynamically
          [structural] 
     rule // this happens when we jump before a variable declaration with an initialization in the same block
          <k> declareAndDefine(X:Id, T:KResult, K:K, noLinkage)
               => justInit(figureInit(X:Id, T:KResult, K:K))
          ...</k>
          <localVariables>... ListItem(X:Id) ...</localVariables>
          [structural] 
          
     syntax K ::= "justInit" "(" K ")" [strict(1)]
     
     rule <k> justInit(initValue(X:Id, T:KResult, K:K)) => initialize(X:Id, T:KResult, K:K) ...</k>
          [structural]
          
     rule <k> defineAndInit(X:Id, _, initValue(X:Id, T:KResult, K:K), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T:KResult)
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, T:KResult)
               ~> initialize(X:Id, T:KResult, K:K)
          ...</k>
          <shouldInit> true </shouldInit>
          [structural] 
          
     rule <k> defineAndInit(X:Id, _, initValue(X:Id, T:KResult, _), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T:KResult)
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, T:KResult)
          ...</k>
          <shouldInit> false </shouldInit>
          [structural]
          
     rule <k> figureInit-aux(_:Id, t(_, (incompleteArrayType(T:KResult) => arrayType(T:KResult, N:Int))), initializer(K:K))
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
     
     // syntax K ::= "defineFunctionUsingOldDeclaration" "(" Type "," Id "," K ")"
     // FIXME check prototypes
     rule [function-definition]:
          <k> FunctionDefinition(typedDeclaration(T:KResult, X:Id), Block:K) 
               => createNewFun(X:Id, T:KResult, safeBody(X:Id, Block:K))
               ~> calculateGotoMap(X:Id, safeBody(X:Id, Block:K))
          ...</k>
          when isFunctionType(T:KResult)
          [structural]

     syntax K ::= "createNewFun" "(" K "," K "," K ")"
     
     rule createNewFun(X:Id, T:KResult, Block:K)
          => declareFunction(
                    X:Id, 
                    T:KResult, 
                    initializer(initFunction(
                         &(X:Id), 
                         functionObject(
                              X:Id, 
                              unqualifyType(T:KResult), 
                              Block:K
                         )
                    ))
               )
          
     syntax K ::= safeBody(Id, K) [function]
     rule safeBody(X:Id, Block:K) 
          => Block:K 
          ~> Return(NothingExpression)
          when X:Id =/=K Identifier("main")
     rule safeBody(Identifier("main"), Block:K) 
          => Block:K 
          ~> Return(tv(0, t(.Set, int)))
endmodule

module COMMON-SEMANTICS-DECLARATIONS-FUNTION-BODY
     imports COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
     syntax K ::= "typingBody" "(" Id "," Type "," K ")" // third argument is just for now, as a hack
     
endmodule

module COMMON-SEMANTICS-DECLARATIONS-INITIALIZATIONS
     imports COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
     
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
          //<br/>
          <currentSubObject> .List => ListItem(te(X:Id, T:KResult)) </currentSubObject>
          <currentObject> .List => ListItem(te(X:Id, T:KResult)) </currentObject>
          <savedInitialization>... .K => zero(X:Id) </savedInitialization> 
          when isUnionType(T:KResult) orBool isAggregateType(T:KResult)
          [structural] 
     
     rule <k> fillInit((InitFragment(K:K, Exp:K),, L:KList))
               => fillInit(InitFragment(K:K, Exp:K)) 
               ~> fillInit(L:KList)
          ...</k>
          [structural] 
     rule <k> fillInit(.KList) => . ...</k>
          [structural] 
     
     syntax ListItem ::= "next"
     syntax ListItem ::= "block"
     
     rule <currentSubObject> 
               ListItem(te(K:K, t(S:Set, arrayType(T:KResult, Len:Int))))
               => ListItem(te(K:K[0], T:KResult)) ListItem(te(K:K, t(S:Set, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          [structural] 
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, incompleteArrayType(T:KResult))))
               => ListItem(te(K:K[0], T:KResult)) ListItem(te(K:K, t(Se:Set, incompleteArrayType(T:KResult))))
          ...</currentSubObject>
          [structural] 
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K:K . F:Id, T:KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
          ...</currentSubObject>
          <structs>... 
               S:Id |-> aggregateInfo((typedDeclaration(T:KResult, F:Id),, _), _, _)
          ...</structs> 
          [structural] 
          
     // fixme these are terrible!
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, unionType(S:Id))))
               => ListItem(te(K:K . F:Id, T:KResult)) ListItem(te(K:K, t(Se:Set, unionType(S:Id))))
          ...</currentSubObject>
          <structs>... 
               S:Id |-> aggregateInfo((typedDeclaration(T:KResult, F:Id),, _), _, _) 
          ...</structs> 
          [structural] 
          
     // fixme should i worry about basetype here_
     rule [init-next-array-element]:
          <currentSubObject> 
               (next ListItem(te(K:K[N:Int], T:KResult)) => ListItem(te(K:K[N:Int +Int 1], T:KResult)))
               ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</currentSubObject>
          when Len:Int >Int N:Int +Int 1
          [structural] 
     rule [init-next-array-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K[N:Int], T:KResult)) => .List) ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</currentSubObject>
          when notBool Len:Int >Int N:Int +Int 1
          [structural] 
     
     rule [init-next-incomplete-array-element]:
          <currentSubObject>
               (next ListItem(te(K:K[N:Int], T:KResult)) => ListItem(te(K:K[N:Int +Int 1], T:KResult))) 
               ListItem(te(K:K, t(_, incompleteArrayType(_))))
          ...</currentSubObject>
          [structural] 
     
     rule [init-next-struct-element]:
          <currentSubObject>
               next ListItem(te(K:K . F:Id, T:KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K:K . F':Id, T':KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),, typedDeclaration(T':KResult, F':Id),, _), _, _)
          ...</structs> 
          when F':Id =/=K #NoName
          [structural, large] 
      
     rule [init-next-struct-element-noname]:
          <currentSubObject>
               next ListItem(te(K:K . F:Id, T:KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K:K . F':Id, T':KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),, typedDeclaration(_, #NoName),, typedDeclaration(T':KResult, F':Id),, _), _, _)
          ...</structs>
          [structural, large] 
          
     rule [init-next-struct-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K . F:Id, T:KResult)) => .) ListItem(te(K:K, t(_, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id)), _, _)
          ...</structs> 
          [structural, large] 
     rule [init-next-struct-element-done-noname]:
          <currentSubObject>
               next (ListItem(te(K:K . F:Id, T:KResult)) => .) ListItem(te(K:K, t(_, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),, typedDeclaration(_, #NoName)), _, _)
          ...</structs> 
          [structural, large] 
          
     rule [init-next-union-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K . _:Id, T:KResult)) => .List) ListItem(te(K:K, t(_, unionType(S:Id))))
          ...</currentSubObject>
          [structural] 
          
     rule <k> fillInit(InitFragment(NextInit, Exp:K)) 
               => fillInit(Exp:K) 
          ...</k>
          [structural] 
          
     syntax K ::= "finishCompoundInit" "(" List ")"
     rule <k> fillInit(CompoundInit(klist(L:KList)))
               => fillInit(L:KList)
               // ~> debug
               ~> finishCompoundInit(next ListItem(te(K:K, T:KResult)) Remainder:ListItem)
          ...</k>
          //<br/>
          <currentSubObject> (_:List => .) ListItem(te(K:K, T:KResult)) (Remainder:ListItem => .) </currentSubObject>
          <currentObject> (. => ListItem(te(K:K, T:KResult))) ...</currentObject>
          when isAggregateType(T:KResult) orBool isUnionType(T:KResult)
          [structural]
     rule <k> finishCompoundInit(L:List) => 
               .K
               // debug
          ...</k>
          <currentObject> (ListItem(te(K:K, T:KResult)) => .) ...</currentObject>
          <currentSubObject> (_ => L:List) </currentSubObject>
          [structural] 
               
     context fillInit(InitFragment(HOLE, _)) 
     syntax K ::= "buildDesignator" "(" K ")"
     
     // note that these clear the current subobject cell, because it will be repopulated when building the designator
     rule <k> fillInit(InitFragment(InFieldInit(F:Id, K':K), Exp:K))
               => fillInit(InitFragment(buildDesignator(InFieldInit(F:Id, K':K)), Exp:K))
          ...</k>
          //<br/>
          <currentObject> ListItem(te(K:K, T:KResult)) ...</currentObject>
          <currentSubObject> _:List => block ListItem(te(K:K, T:KResult)) </currentSubObject>
          when isStructType(T:KResult) orBool isUnionType(T:KResult)
          [structural] 
     // fixme does this need to worry about incompleteLength_
     rule <k> fillInit(InitFragment(AtIndexInit(Index:K, K':K), Exp:K))
               => fillInit(InitFragment(buildDesignator(AtIndexInit(Index:K, K':K)), Exp:K))
          ...</k>
          //<br/>
          <currentObject> ListItem(te(K:K, T:KResult)) ...</currentObject>
          <currentSubObject> _:List => block ListItem(te(K:K, T:KResult)) </currentSubObject>
          when isArrayType(T:KResult)
          [structural] 
          
     
     // fixme these are also too restrictive on type.  if we try to assign an int to a long-int field, it will fail
     // i don't think this is true anymore
     rule <k> buildDesignator(InFieldInit(F:Id, More:K)) 
               => buildDesignator(More:K)
          ...</k>
          <currentSubObject> block (.List => ListItem(te(K:K . F:Id, T:KResult))) ListItem('te(K:K,, 't(_,, KL:KLabel(S:Id)))) ...</currentSubObject>
          //<br/>
          <structs>... 
               // S:Id |-> _ :: typedDeclaration(T:KResult, F:Id) :: _ 
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
          <currentSubObject> block (.List => ListItem(te(K:K[N:Int], innerType(T:KResult)))) ListItem(te(K:K, T:KResult)) ...</currentSubObject>
          when isArrayType(T:KResult)
          [structural] 
     
     syntax K ::= "popInit"
     
     syntax Int ::= getTopArrayUse(K) [function]
     rule getTopArrayUse(X:Id) => 0
     rule getTopArrayUse(X:Id[N:Int]) => N:Int +Int 1 // +1 for length instead of index
     rule getTopArrayUse(K:K . F:Id) => getTopArrayUse(K:K)
     rule getTopArrayUse((K:K[N:Int])[_]) => getTopArrayUse(K:K[N:Int])
     rule getTopArrayUse((K:K . F:Id)[_]) => getTopArrayUse(K:K)
     
     syntax K ::= "initializeSingleInit" "(" K ")"
          
     rule <k> (.K => typeof(K:K)) ~> initializeSingleInit(K:K) ...</k>
          [structural] 
     
     // fixme want to exclude strings, but not normal arrays
     rule <k> T':KResult ~> initializeSingleInit(K':K) => . ...</k>
          <currentSubObject> (.List => next) ListItem(te(K:K, T:KResult)) ...</currentSubObject>
          //<br/>
          <incompleteLength> N:Int => maxInt(N:Int, getTopArrayUse(K:K)) </incompleteLength>
          <savedInitialization>... .K => Computation(AllowWrite(K:K) := K':K) ~> possiblyMakeConst(T:KResult, K:K) </savedInitialization>
          when (isBasicType(T:KResult) orBool isPointerType(T:KResult) orBool isBitfieldType(T:KResult))
          andBool notBool isStructType(T':KResult)
          andBool notBool isUnionType(T':KResult)
          [structural]
     
     syntax K ::= "possiblyMakeConst" "(" Type "," K ")"
     
     rule <k> possiblyMakeConst(T:KResult, K) => makeUnwritableSubObject(K) ...</k>
          when isConstType(T:KResult)
          [structural]
     rule <k> possiblyMakeConst(T:KResult, K) => . ...</k>
          when notBool isConstType(T:KResult)
          [structural]
          
     // this is used to have an aggregate on the RHS of a compound init
     // fixme want to exclude strings, but not normal arrays
     syntax K ::= "initFromAggregateRHS" "(" K "," Type ")"
     rule <k> T:KResult ~> initializeSingleInit(K:K) => initFromAggregateRHS(K:K, T:KResult) ...</k>
          when isStructType(T:KResult)
          orBool isUnionType(T:KResult)
          [structural] 
          
     syntax K ::= "initFromStructRHS" "(" K "," Type ")"
     rule <k> initFromAggregateRHS(K:K, t(S:Set, structType(I:Id)))
               => initFromStructRHS(K:K, t(S:Set, structType(I:Id)))
          ...</k>
          <currentSubObject> .List => findStruct(t(S:Set, structType(I:Id))) ...</currentSubObject>
          [structural] 
          
     syntax ListItem ::= "findStruct" "(" Type ")"
          
     rule <currentSubObject> findStruct(T:KResult) (ListItem(te(_, T':KResult)) => .List) ...</currentSubObject>
          when T:KResult =/=K T':KResult
          [structural] 
          
     // fixme unsafe, might have started to initialize other things
     rule <k> initFromStructRHS(K':K, t(_, structType(S:Id)))
               => .K
          ...</k>
          //<br/>
          <currentSubObject> 
               findStruct(t(_, structType(S:Id))) ListItem(te(K:K, t(_, structType(S:Id)))) => next 
          ...</currentSubObject>
          <br/>
          <incompleteLength> N:Int => maxInt(N:Int, getTopArrayUse(K:K)) </incompleteLength>
          <savedInitialization>... .K => Computation(AllowWrite(K:K) := K':K) </savedInitialization> 
          [structural, large] 
     
     rule <k> fillInit(SingleInit(K:K)) => initializeSingleInit(K:K) ...</k>
          when getKLabel(K:K) =/=KLabel 'Constant
          [structural] 

     rule [fillInit-string-array-eq]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit-aux(SingleInit(Constant(StringLiteral(S:String))))
          ...</k>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, arrayType(T:KResult, Len:Int)))) ...</currentSubObject>
          when isCharType(T:KResult)
          andBool lengthString(S:String) ==Int Len:Int
          [structural] 
     rule [fillInit-wstring-array-eq]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit-aux(SingleInit(Constant(WStringLiteral(S:KList))))
          ...</k>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, arrayType(T:KResult, Len:Int)))) ...</currentSubObject>
          when isWCharType(T:KResult)
          andBool lengthKList S:KList  ==Int Len:Int
          [structural] 
     rule [fillInit-string-array-lt]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit(SingleInit(Constant(StringLiteral(S:String +String "\0"))))
          ...</k>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, arrayType(T:KResult, Len:Int)))) ...</currentSubObject>
          when isCharType(T:KResult)
          andBool lengthString(S:String) <Int Len:Int
          [structural] 
     rule [fillInit-wstring-array-lt]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit(SingleInit(Constant(WStringLiteral((S:KList,, 0)))))
          ...</k>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, arrayType(T:KResult, Len:Int)))) ...</currentSubObject>
          when isWCharType(T:KResult)
          andBool lengthKList S:KList <Int Len:Int
          [structural] 
     rule [fillInit-string-char]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit-aux(SingleInit(Constant(StringLiteral(S:String +String "\0"))))
          ...</k>
          //<br/>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, incompleteArrayType(T:KResult)))) ...</currentSubObject>
          when isCharType(T:KResult)
          [structural] 
     rule [fillInit-wstring-wchar]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit-aux(SingleInit(Constant(WStringLiteral((S:KList,, 0)))))
          ...</k>
          //<br/>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, incompleteArrayType(T:KResult)))) ...</currentSubObject>
          when isWCharType(T:KResult)
          [structural]
     rule [fillInitAux-string-some]:
          <k> fillInit-aux(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit(initHead(S:String, T:KResult)) 
               ~> fillInit-aux(initTail(S:String))
          ...</k>
          //<br/>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ...</currentSubObject>
          when S:String =/=String ""
          andBool isCharType(T:KResult)
          [structural]
          
     syntax K ::= "initHead" "(" K "," K ")"
     syntax K ::= "initTail" "(" K ")"
     rule initHead(S:String, T:KResult)
          => SingleInit(tv(asciiString(firstChar(S:String)), t(getModifiers(T:KResult), char)))
     
     rule initTail(S:String)
          => SingleInit(Constant(StringLiteral(butFirstChar(S:String))))
          
     rule [fillInitAux-wstring-some]:
          <k> fillInit-aux(SingleInit(Constant(WStringLiteral((N:Int,, S:KList)))))
               => fillInit(SingleInit(tv(N:Int, cfg:wcharut)))
               ~> fillInit-aux(SingleInit(Constant(WStringLiteral(S:KList)))) 
          ...</k>
          //<br/>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ...</currentSubObject>
          when isWCharType(T:KResult)
          [structural]
     // fixme not sure what happens in the case of   char *x = "";
     rule [fillInitAux-string-done]:
          <k> fillInit-aux(SingleInit(Constant(StringLiteral("")))) => .K ...</k>
          [structural]
     rule [fillInitAux-wstring-done]:
          <k> fillInit-aux(SingleInit(Constant(WStringLiteral(.KList)))) => .K ...</k>
          [structural] 
          
     // this rule assumes all unrollings have already occurred, so it needs to be a rule
     // alternatively, i've added the condition below which might be enough
     rule [fillInit-string-notchar]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => initializeSingleInit(Constant(StringLiteral(S:String)))
          ...</k>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ...</currentSubObject>
          when notBool isCharType(T:KResult)
          andBool (isBasicType(T:KResult) orBool isPointerType(T:KResult) orBool isBitfieldType(T:KResult))
          [structural] 
     rule [fillinit-wstring-notwchar]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => initializeSingleInit(Constant(WStringLiteral(S:KList)))
          ...</k>
          <currentSubObject> ListItem(te(K:K, T:KResult)) ...</currentSubObject>
          when notBool isWCharType(T:KResult)
          andBool (isBasicType(T:KResult) orBool isPointerType(T:KResult) orBool isBitfieldType(T:KResult))
          [structural]
endmodule


module COMMON-SEMANTICS-DECLARATIONS-RESOLUTION
     imports COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
     
     syntax K ::= "canonicalizeTranslationUnitVariables"
     rule [unpack-TranslationUnit]:
          <k> TranslationUnit(Name:String, Strings:K, K:K, P:String) 
               => preDeclareStrings(Strings:K)
               ~> klistToK(eraseKLabel('StmtCons, K:K))
          ...</k>
          <currTU> _ => Name:String </currTU>
          <declarationOrder> DeclOrder:Map => DeclOrder:Map[ListToK(.List) / Name:String] </declarationOrder>
          <internalLocations> ExtLoc:Map => ExtLoc:Map[map(.) / Name:String] </internalLocations>
          <br/>
          <funTUs> Funs:Map => Funs:Map[map(.) / Name:String] </funTUs>
          <translationUnits>... . => BagItem(Name:String) ...</translationUnits>
          <preLinkage> Linkage:Map => Linkage:Map[map(.) / Name:String] </preLinkage>
          <preTypes> Types:Map => Types:Map[map(.) / Name:String] </preTypes>
          <br/>
          <internalDefinitions> Def:Map => Def:Map[map(.) / Name:String] </internalDefinitions>
          <genv> Env:Map => Env:Map[map(.) / Name:String] </genv>
          <gtypes> Gtypes:Map => Gtypes:Map[map(.) / Name:String]</gtypes>
          <programText> M:Map => M:Map[P:String / Name:String] </programText>
          when notBool $hasMapping(Env:Map, Name:String)
          [structural, large]
          
     syntax K ::= "preDeclareStrings" "(" K ")"
     
     rule <k> preDeclareStrings(klist((K:K,, L:KList)))
               => K:K
               ~> discard
               ~> preDeclareStrings(klist(L:KList))
          ...</k>
          [structural]
     rule <k> preDeclareStrings(klist(.KList)) => .K ...</k>
          [structural]
     
     syntax K ::= "resolve" "(" K ")"
     rule <k> (. => resolve(Tu:K)) ~> resolveReferences ...</k>
          <translationUnits>... BagItem(Tu:K) => .Bag ...</translationUnits>
          [structural] 
          
     // rule
          // <k> resolveReferences => .K ...</k>
          // <translationUnits> .Bag </translationUnits>
          // [structural] 
     
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
          //<br/>
          <externalLocations>... X |-> Loc:SymLoc ...</externalLocations>
          <leftoverExterns>... BagItem(leftover(Tu:K, X:Id, T:KResult)) => .Bag ...</leftoverExterns>
          [structural]
     rule <k> resolveLeftovers ...</k>
          <externalLocations> Locs:Map </externalLocations>
          <leftoverExterns>... BagItem(leftover(_, X:Id, _)) => .Bag ...</leftoverExterns>
          when notBool $hasMapping(Locs:Map, X:Id)
          [structural]
     
     rule <k> resolveLeftovers => .K ...</k>
          <leftoverExterns> .Bag </leftoverExterns>
          [structural]
               
     syntax K ::= "resolveInternal" "(" Id "," K "," K ")"
     syntax K ::= "resolveExternal" "(" Id "," K "," Bag "," K ")"
     syntax K ::= "resolveExternal'" "(" Id "," K "," Bag "," K "," SymLoc "," K ")" [strict(6)]
     
     syntax K ::= "recordFunTUInfo" "(" K "," Type "," K "," K ")" // name, type, context, where defined
     rule <k> recordFunTUInfo(X:Id, T:KResult, Tu:K, DefTu:K) => .K ...</k>
          <funTUs>... Tu:K |-> map((Funs:Map => Funs:Map[DefTu:K / X:Id])) ...</funTUs>
          when isFunctionType(T:KResult)
          [structural] 
     rule <k> recordFunTUInfo(_, T:KResult, _, _) => .K ...</k>
          when notBool isFunctionType(T:KResult)
          [structural] 
     
     // fixme
     // should be adding to env after figuring initializer
     // should be changing env to be correct env before figuring initializer
     //syntax K ::= "allocateWithInit" "(" K "," Int ")" [strict] 
     //syntax K ::= "noAllocateWithInit" "(" K "," Int ")" [strict] 
     syntax K ::= "resolveInternal'" "(" Id "," K "," K "," K ")" [strict(4)] 
     rule <k> resolveInternal(X:Id, Tu:K, declarationObject(T:KResult, Tu:K, K:K))
               => resolveInternal'(X:Id, Tu:K, declarationObject(T:KResult, Tu:K, K:K), figureInit(X:Id, T:KResult, K:K))
          ...</k>
          //<br/>
          <currTU> _ => Tu:K </currTU>
          [structural] 
     rule <k> resolveInternal'(X:Id, Tu:K, declarationObject(_, Tu:K, _), initValue(X:Id, T:KResult, K:K))
               => allocateType(Loc, T:KResult)
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, T:KResult)
               ~> initialize(X:Id, T:KResult, K:K)
               ~> recordFunTUInfo(X:Id, T:KResult, Tu:K, Tu:K)
          ...</k>
          //<br/>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currTU> _ => Tu:K </currTU>
          [structural] 
               
     rule <k> resolveExternal(X:Id, Tu:K, Units:Bag, declarationObject(T:KResult, DefTu:K, K:K))
               => resolveExternal'(X:Id, Tu:K, Units:Bag, declarationObject(T:KResult, DefTu:K, K:K), Loc, figureInit(X:Id, T:KResult, K:K))
          ...</k>
          //<br/>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          [structural] 
     rule <k> ( .K
               => addToEnv(X:Id, Loc)
               ~> giveType(X:Id, T:KResult)
               ~> recordFunTUInfo(X:Id, T:KResult, Tu':K, DefTu:K)
               ) ~> resolveExternal'(X:Id, Tu:K, ((BagItem(Tu':K) => .) Units:Bag), declarationObject(_, DefTu:K, _), Loc:SymLoc, initValue(X:Id, T:KResult, K:K))
          ...</k>
          <br/>
          <currTU> _ => Tu':K </currTU>
          <preLinkage>... Tu':K |-> map((_ (X:Id |-> external => .))) ...</preLinkage>
          [structural, large] 
     rule <k> resolveExternal'(X:Id, Tu:K, .Bag, declarationObject(_, DefTu:K, _), Loc:SymLoc, initValue(X:Id, T:KResult, K:K))
               => allocateType(Loc, T:KResult)
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, T:KResult)
               ~> initialize(X:Id, T:KResult, K:K)
               ~> recordFunTUInfo(X:Id, T:KResult, Tu:K, DefTu:K)
          ...</k>
          //<br/>
          <currTU> _ => Tu:K </currTU>
          <externalLocations> Locs:Map => Locs:Map[Loc / X:Id] </externalLocations>
          when notBool $hasMapping(Locs:Map, X:Id)
          [structural] 
     rule <k> resolveExternal'(X:Id, _, ((BagItem(Tu:K) => .) Units:Bag), _, _, _) ...</k>
          <preLinkage>... Tu:K |-> map(M:Map) ...</preLinkage>
          when notBool $hasMapping(M:Map, X:Id)
          [structural] 
     rule [resolveExternal-internal]:
          <k> resolveExternal'(X:Id, _, ((BagItem(Tu:K) => .) Units:Bag), _, _, _) ...</k>
          //<br/>
          <preLinkage>... Tu:K |-> map((_ X:Id |-> internal)) ...</preLinkage>
          [structural] 
     
     rule <k> (.K => resolveInternal(X:Id, Tu:K, K:K)) ~> resolve(Tu:K) ...</k>
          //<br/>
          <preLinkage>... Tu:K |-> map((_ (X:Id |-> internal => .Map))) ...</preLinkage>
          <internalDefinitions>... Tu:K |-> map((_ (X:Id |-> K:K => .Map))) ...</internalDefinitions>
          <declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .List) _) ...</declarationOrder>
          [structural] 
          
     // static variable without an initializer
     rule <k> (.K => resolveInternal(X:Id, Tu:K, declarationObject(unqualifyType(T:KResult), Tu:K, initializer(zero(X:Id))))) ~> resolve(Tu:K) ...</k>
          <br/>
          <preLinkage>... Tu:K |-> map((_ (X:Id |-> internal => .Map))) ...</preLinkage>
          <internalDefinitions>... Tu:K |-> map(Defs:Map) ...</internalDefinitions>
          <declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .List) _) ...</declarationOrder>
          <preTypes>... Tu:K |-> map((_ (X:Id |-> T:KResult => .Map))) ...</preTypes>
          when notBool $hasMapping(Defs:Map, X:Id)
          [structural, large] 
          
     rule <k> (.K => resolveExternal(X:Id, Tu:K, Units:Bag, K:K)) ~> resolve(Tu:K) ...</k>
          <br/>
          <preLinkage>... Tu:K |-> map((_ (X:Id |-> external => .Map))) ...</preLinkage>
          <externalDefinitions> ExtDefs:Map (X:Id |-> K:K => .Map) </externalDefinitions>
          <declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .List) _) ...</declarationOrder>
          <translationUnits> Units:Bag </translationUnits>
          when notBool $hasMapping(ExtDefs:Map, X:Id)
          [structural, large] 

     
     // fixme this means we've declared it twice (like a prototype maybe_), but already handled it.  happening with getc in clib.c
     rule <k> resolve(Tu:K) ...</k>
          <preLinkage>... Tu:K |-> map(Linkage:Map) ...</preLinkage>
          <declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .) _) ...</declarationOrder>
          <externalDefinitions> ExtDefs:Map </externalDefinitions>
          <internalDefinitions> IntDefs:Map </internalDefinitions>
          when notBool $hasMapping(Linkage:Map, X:Id)
          andBool notBool $hasMapping(ExtDefs:Map, X:Id)
          andBool notBool $hasMapping(IntDefs:Map, X:Id)
          [structural] 
     
     // function prototypes
     rule <k> (.K => 
                    giveType(X:Id, T:KResult)
                    ~> recordFunTUInfo(X:Id, T:KResult, Tu:K, Tu:K)  // fixme fake Tu
               )
               ~> resolve(Tu:K) 
          ...</k>
          <br/>
          <preLinkage>... Tu:K |-> map((_ (X:Id |-> external => .))) ...</preLinkage>
          <preTypes>... Tu:K |-> map((_ X:Id |-> t(S:Set, prototype(T:KResult)))) ...</preTypes>
          <declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .) _) ...</declarationOrder>
          <br/>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <currTU> _ => Tu:K </currTU>
          when isFunctionType(T:KResult)
          andBool notBool $hasMapping(Defs:Map, X:Id)
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
     rule <k> (. 
               => allocateType(Loc, unqualifyType(T:KResult))
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, unqualifyType(T:KResult))
               ~> zero(X:Id)
               ) ~> resolve(Tu:K)
          ...</k>
          <br/>
          <preLinkage>... Tu:K |-> map((_ (X:Id |-> external => .))) ...</preLinkage>
          <preTypes>... Tu:K |-> map((_ X:Id |-> T:KResult)) ...</preTypes>
          <declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .) _) ...</declarationOrder>
          <br/>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <currTU> _ => Tu:K </currTU>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <externalLocations> Locs:Map => Locs:Map[Loc / X:Id] </externalLocations>
          when notBool $hasMapping(Locs:Map, X:Id)
          andBool notBool isFunctionType(T:KResult)
          andBool notBool isIncompleteType(T:KResult)
          andBool notBool isExternType(T:KResult)
          andBool notBool $hasMapping(Defs:Map, X:Id)
          [structural, large] 
     syntax K ::= "leftover" "(" K "," K "," K ")"
     rule [resolve-extern-object-nomapping]:
          <k> resolve(Tu:K) ...</k>
          <preLinkage>... Tu:K |-> map((_ (X:Id |-> external => .))) ...</preLinkage>
          <preTypes>... Tu:K |-> map((_ X:Id |-> T:KResult)) ...</preTypes>
          <declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .) _) ...</declarationOrder>
          //<br/>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <leftoverExterns>... .Bag => BagItem(leftover(Tu:K, X:Id, T:KResult)) ...</leftoverExterns>
          when notBool isFunctionType(T:KResult)
          andBool isExternType(T:KResult)
          andBool notBool $hasMapping(Defs:Map, X:Id)
          [structural] 
          
     rule <k> resolve(Tu:K) => . ...</k>
          //<br/>
          <preLinkage>... Tu:K |-> map(.) ...</preLinkage>
          <internalDefinitions>... Tu:K |-> map(.) ...</internalDefinitions>
          <declarationOrder>... Tu:K |-> ListToK(.List) ...</declarationOrder>
          [structural] 
                    
     // need to worry about things that don't have definitions that may override externs
     // want to make it so env is always correct local env, so need to have a set of global envs, one for each tu
     
     rule [initialize-function]:
          <k> initFunction(tv(Loc:SymLoc, t(_, pointerType(T:KResult))), Fun:KResult) => .K ...</k>
          <functions> M:Map => M:Map[Fun / Loc] </functions>
          when isFunctionType(T)
          andBool notBool $hasMapping(M, Loc)
          [structural]
          
     rule <k> readFunction(Loc:SymLoc) => Fun  ...</k>
          <functions>... Loc |-> Fun ...</functions>
          [structural]
     
endmodule

module COMMON-SEMANTICS-DECLARATIONS-ENUMS
     imports COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
     
     syntax K ::= "fillEnums" "(" K ")"
     syntax K ::= "fillEnums-aux" "(" K "," K ")"
     rule <k> EnumDef(X:Id, L:K) => fillEnums(EnumDef(X:Id, L:K)) ...</k>
          [structural] 
     rule <k> fillEnums(K:K) => fillEnums-aux(K:K, tv(0, t(.Set, int))) ...</k> 
          [structural]
     rule <k> fillEnums-aux(EnumDef(X:Id, klist((EnumItem(E:Id),, L:KList))), K:K) 
               => doDeclare(typedDeclaration(t(.Set, int), E:Id), SingleInit(K:K))
               ~> fillEnums-aux(EnumDef(X:Id, klist(L:KList)), K:K + tv(1, t(.Set, int)))
          ...</k>
          [structural] 
     rule <k> fillEnums-aux(EnumDef(X:Id, klist((EnumItemInit(E:Id, Exp:K),, L:KList))), _)
               => doDeclare(typedDeclaration(t(.Set, int), E:Id), SingleInit(Exp:K))
               ~> fillEnums-aux(EnumDef(X:Id, klist(L:KList)), Exp:K + tv(1, t(.Set, int)))
          ...</k>
          when Exp:K =/=K NothingExpression
          [structural] 
     rule <k> fillEnums-aux(EnumDef(X:Id, klist(.KList)), _) => .K ...</k> 
          [structural] 
endmodule

module COMMON-C-DECLARATIONS
     imports COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
     
     imports COMMON-SEMANTICS-DECLARATIONS-GENERAL 
     imports COMMON-SEMANTICS-DECLARATIONS-FUNTION-BODY
     imports COMMON-SEMANTICS-DECLARATIONS-INITIALIZATIONS 
     imports COMMON-SEMANTICS-DECLARATIONS-ENUMS 
     imports COMMON-SEMANTICS-DECLARATIONS-RESOLUTION 
endmodule
