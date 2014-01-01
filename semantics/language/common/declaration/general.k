module C-DECLARATION-GENERAL-SYNTAX
     syntax K ::= doDeclare(K, K) [strict(1)] 

     syntax K ::= declareOnly(Id, Type, K)

     syntax K ::= verifyDecl(K) [strict]

     syntax K ::= declareAndDefine(Id, Type, K, K)

     syntax K ::= defineAndInit(Id, Type, K, SymLoc) [strict(3)] 

     syntax K ::= declareInternalVariable(Id, Type, K)

     // id, type, possible init, linkage (external, internal, noLinkage)
     syntax K ::= declareWithLinkage(Id, Type, K, K)
     syntax K ::= justInit(K) [strict(1)]
     
endmodule

module C-DECLARATION-GENERAL
     imports C-DECLARATION-GENERAL-SYNTAX
     imports C-DECLARATION-INITIALIZATION-SYNTAX
     imports C-DECLARATION-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     // c99 6.7.8:9 Except where explicitly stated otherwise, for the purposes
     // of this subclause unnamed members of objects of structure and union
     // type do not participate in initialization. Unnamed members of
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

     // id, type, initializer
     syntax K ::= "figureInit-aux" "(" Id "," Type "," K ")" [strict(3)]

     syntax K ::= "defineType" "(" K ")" [strict] 
     context DeclarationDefinition(InitNameGroup(HOLE, _)) 
     context Typedef(NameGroup(HOLE, _))

     rule figureInit(X:Id, T:Type, CodeLoc(K:K, L:K)) 
          => CodeLoc(.K, L) ~> figureInit(X, T, K) 
          [structural]
     
     // aggregates
     rule figureInit(X:Id, T:Type, CompoundInit(L:K))
          => giveType(X, T)
               ~> figureInit-aux(X, T,
                    startInit(T, X, CompoundInit(L)))
          when isAggregateType(T) orBool isUnionType(T)
          [structural] 

     rule figureInit(
               _:Id, 
               t(_:Set, arrayType(T:Type, Len:Int)), 
               (SingleInit(Constant(StringLiteral(S:String))) 
               => CompoundInit(klist(InitFragment(NextInit,
                    SingleInit(Constant(StringLiteral(S)))))))
          )
          when isCharType(T) andBool (lengthString(S) <=Int Len)
          [structural]

     rule figureInit(
               _:Id, 
               t(_:Set, arrayType(T:Type, Len:Int)), 
               (SingleInit(Constant(WStringLiteral(S:KList))) 
               => CompoundInit(klist(InitFragment(NextInit,
                    SingleInit(Constant(WStringLiteral(S)))))))
          )
          when isWCharType(T) andBool (lengthKList S <=Int Len)
          [structural] 
     
     rule figureInit(_:Id, t(_, (incompleteArrayType(T:Type) 
          => arrayType(T, lengthString(S) +Int 1))),
               SingleInit(Constant(StringLiteral(S:String)))) 
          when isCharType(T)
          [structural]

     rule figureInit(_:Id, t(_, (incompleteArrayType(T:Type)
          => arrayType(T, lengthKList S +Int 1))),
               SingleInit(Constant(WStringLiteral(S:KList)))) 
          when isWCharType(T)
          [structural] 
          
     rule figureInit(X:Id, t(Se:Set, incompleteArrayType(T:Type)),
               CompoundInit(klist(InitFragment(NextInit,
               SingleInit(Constant(StringLiteral(S:String)))))))
          => figureInit(X, t(Se, incompleteArrayType(T)),
               SingleInit(Constant(StringLiteral(S))))
          [structural] 
          
     // this comes from function declarations.  should probably adjust this
     rule figureInit(X:Id, T:Type, initializer(K:K))
          => figureInit-aux(X, T, initializer(K))
          [structural] 

     rule figureInit-aux(X:Id, T:Type, initializer(K:K))
          => initValue(X, T, K)
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T)
               andBool notBool isConstType(T)
          [structural]
     rule figureInit-aux(X:Id, T:Type, initializer(K:K))
          => initValue(X, T, (K ~> makeUnwritableVar(X)))
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T)
               andBool isConstType(T)
          [structural]
     
     // base types
     rule figureInit(X:Id, T:Type, SingleInit(K:K))
          => figureInit-aux(X, T, 
               initializer(Computation(allowWrite(X) := K)))
          when notBool isArrayType(T)
          [structural] 
     // c1x 6.7.8:11
     rule figureInit(X:Id, T:Type,
               CompoundInit(klist(InitFragment(NextInit, SingleInit(K:K)))))
          => figureInit-aux(X, T,
               initializer(Computation(allowWrite(X) := K)))
          when notBool (isAggregateType(T) orBool isUnionType(T))
          [structural] 
          
     rule DeclarationDefinition(
               InitNameGroup(T:Type, klist((K:K,, K':K,, L:KList))))
          => DeclarationDefinition(InitNameGroup(T, klist(K)))
               ~> DeclarationDefinition(InitNameGroup(T, klist((K',, L))))
          [structural]
     rule DeclarationDefinition(
               InitNameGroup(T:Type, klist(InitName(N:K, Exp:K))))
          => doDeclare(SingleName(T, N), Exp)
          [structural]
               
     rule Typedef(NameGroup(T:Type, klist((K:K,, L:KList)))) 
          => defineType(SingleName(T, K))
               ~> Typedef(NameGroup(T, klist(L)))
          [structural]
     rule Typedef(NameGroup(_:Type, klist(.KList))) => .K
          [structural]

     rule defineType(typedDeclaration(T:Type, X:Id)) 
          => giveType(typedef(X), T) 
          [structural] 
               
     syntax K ::= "doDeclare'" "(" Type "," K ")" 
     syntax K ::= declareFunction(Id, Type, K)
     syntax K ::= declareExternalVariable(Id, Type, K)

     rule doDeclare(T:Type, K:K) 
          => verifyDecl(T) ~> doDeclare'(T, K)

     // function definition
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

     rule <k> doDeclare'(typedDeclaration(T:Type, X:Id), K:K) 
               => declareInternalVariable(X, T, K)
          ...</k>
          <currentFunction> F:K </currentFunction>
          when notBool isFunctionType(T)
               andBool F =/=K file-scope
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
          
     rule [declareExternInternal]:
          <k> 
               declareInternalVariable(X:Id, T:Type, NoInit)
               => addToEnv(X, Loc) ~> giveType(X, unqualifyType(T))
          ...</k>
          <externalLocations>... X |-> Loc:SymLoc ...</externalLocations>
          when notBool isIncompleteType(T)
               andBool isExternType(T)
          [structural] 
          
     //- external variables
    // rule declareExternalVariable(X:Id, T:Type, K:K)
    //      => declareWithLinkage(X, T, K, external)
    //      when notBool isStaticType(T)
    //           andBool notBool isExternType(T)
    //      [structural] 
     rule <k> 
               declareExternalVariable(X:Id, T:Type, K:K)
               => declareWithLinkage(X, T, K, external)
          ...</k>
          <preLinkage>... Tu |-> map(Lnk:Map) ...</preLinkage>
          <currTU> Tu:K </currTU>
          when notBool isStaticType(T)
               //andBool isExternType(T)
               andBool notBool $hasMapping(Lnk, X)
          [structural] 
     // not triggering
     rule [declareExtern-again]:
          <k> 
               declareExternalVariable(X:Id, T:Type, K:K)
               => declareWithLinkage(X, T, K, Lnk:Map(X))
          ...</k>
          <preLinkage>... Tu |-> map(Lnk:Map) ...</preLinkage>
          <currTU> Tu:K </currTU>
          when notBool isStaticType(T)
               //andBool isExternType(T)
               andBool $hasMapping(Lnk, X)
          [structural] 
     rule declareExternalVariable(X:Id, T:Type, K:K)
          => declareWithLinkage(X, T, K, internal)
          when isStaticType(T)
               andBool notBool isExternType(T)
          [structural] 
          
     rule <k>
               declareWithLinkage(X:Id, T:Type, NoInit, L:K)
               => declareOnly(X, T, L)
          ...</k>
          <declarationOrder>...
               Tu |-> ListToK(_ (. => ListItem(X)))
          ...</declarationOrder>
          <currTU> Tu:K </currTU>
          when L =/=K noLinkage
          [structural] 
     rule <k>
               declareWithLinkage(X:Id, T:Type, K:K, L:K) 
               => declareAndDefine(X, T, K, L)
          ...</k>
          <declarationOrder>...
               Tu |-> ListToK(_ (. => ListItem(X)))
          ...</declarationOrder>
          <currTU> Tu:K </currTU>
          when K =/=K NoInit
               andBool L =/=K noLinkage
          [structural] 
     
     // extern functions are no different than functions
     // fixme dangerous if someone marks it as static and extern.  can't tell
     // rule t(_, qualifiedType(T:Type, Extern)) => T
          // when isFunctionType(T) 
          // [structural]
     
     // fixme clean these up, they are so redundant
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
          
     rule justInit(initValue(X:Id, T:Type, K:K)) => initialize(X, T, K)
          [structural]
          
     rule <k> 
               defineAndInit(X:Id, _, 
                    initValue(X:Id, T:Type, K:K), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T)
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, T)
                    ~> initialize(X, T, K)
          ...</k>
          <shouldInit> true </shouldInit>
          [structural] 
          
     rule <k> 
               defineAndInit(X:Id, _,
                    initValue(X:Id, T:Type, _), Loc:SymLoc)
               => allocateTypeIfAbsent(Loc, T)
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, T)
          ...</k>
          <shouldInit> false </shouldInit>
          [structural]
          
     rule <k> 
               figureInit-aux(_:Id, t(_, 
                    (incompleteArrayType(T:Type) 
                    => arrayType(T, N))), initializer(_))
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
          when F =/=K file-scope
          [structural] 
          
     rule <k> addToGlobalEnv(X:Id, Loc:SymLoc) => . ...</k>
          <genv>... Tu:K |-> map((M':Map => M':Map[Loc / X:Id])) ...</genv>
          <currTU> Tu:K </currTU>
          <env> E:Map => E:Map[Loc / X] </env>
          [structural] 
     rule <k> addToLocalEnv(X:Id, Loc:SymLoc) => . ...</k>
          <env> E:Map => E:Map[Loc / X] </env>
          [structural] 
     
     syntax K ::= "defineUsingOldDeclaration" "(" Type "," Id "," K ")"
     
     // FIXME check prototypes
     rule [function-definition]:
          FunctionDefinition(typedDeclaration(T:Type, X:Id), Blk:K) 
          => verifyDecl(typedDeclaration(T, X))
               ~> createNewFun(X, T, safeBody(X, Blk))
               ~> calculateGotoMap(X, safeBody(X, Blk))
          when isFunctionType(T)
          [structural]

     syntax K ::= "createNewFun" "(" Id "," Type "," K ")" [function]
     
     rule createNewFun(X:Id, T:Type, Blk:K)
          => declareFunction(
               X, 
               T, 
               initializer(initFunction(
                    &(X), 
                    functionObject(
                         X, 
                         unqualifyType(T), 
                         Blk
                    )
               ))
          )
          
     syntax K ::= safeBody(Id, K) [function]
     rule safeBody(X:Id, Blk:K) 
          => Blk ~> Return(NothingExpression)
          when X =/=K Identifier("main")
     rule safeBody(Identifier("main"), Blk:K) 
          => Blk ~> Return(tv(0, t(.Set, int)))
endmodule

