module COMMON-SEMANTICS-DECLARATIONS-INCLUDE is
	including COMMON-INCLUDE 
	syntax K ::= "figureInitializer-aux" "(" Id "," Type "," K ")" [strict(3) klabel(figureInitializer-aux)] // id, type, initializer
	syntax K ::= "declarationObject" "(" Type "," K "," K ")" [klabel(declarationObject)] // type, translation unit it was defined in, definition
	
	syntax K ::= "external" [klabel(external)] 
	syntax K ::= "internal" [klabel(internal)] 
	syntax K ::= "noLinkage" [klabel(noLinkage)] 
	
	syntax KResult ::= "initializer" "(" K ")" [klabel(initializer)] 
	syntax K ::= "startInitializer" "(" Type "," Id "," K ")" [klabel(startInitializer)] 
	 
	syntax K ::= "doDeclare" "(" K "," K ")" [strict(1) klabel(doDeclare)] 
			
	syntax K ::= "processFunctionBody" "(" K ")" [klabel(processFunctionBody)]
end module

module COMMON-SEMANTICS-DECLARATIONS-GENERAL is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 

	// c99 6.7.8:9 Except where explicitly stated otherwise, for the purposes of this subclause unnamed members of objects of structure and union type do not participate in initialization.  Unnamed members of structure objects have indeterminate value even after initialization
	// c99 6.7.8:10 If an object that has automatic storage duration is not initialized explicitly, its value is indeterminate. If an object that has static storage duration is not initialized explicitly, then:
	// -- if it has pointer type, it is initialized to a null pointer;
	// -- if it has arithmetic type, it is initialized to (positive or unsigned) zero;
	// if it is an aggregate, every member is initialized (recursively) according to these rules;
	// -- if it is a union, the first named member is initialized (recursively) according to these rules

	syntax K ::= "defineType" "(" K ")" [strict klabel(defineType)] 
	context DeclarationDefinition(InitNameGroup(HOLE, _)) 
	context Typedef(NameGroup(HOLE, _))

	rule
		<k> figureInitializer(X:Id, T:KResult, CodeLoc(K:K, L:K)) 
			=> CodeLoc(.K, L:K)
			~> figureInitializer(X:Id, T:KResult, K:K) 
		...</k>
		[structural]
		
	
	// aggregates
	rule
		<k> figureInitializer(X:Id, T:KResult, CompoundInit(L:K))
			=> giveType(X:Id, T:KResult)
			~> figureInitializer-aux(X:Id, T:KResult, startInitializer(T:KResult, X:Id, CompoundInit(L:K)))
		...</k>
		when (isAggregateType(T:KResult) orBool isUnionType(T:KResult)) 
		//andBool notBool isIncompleteType(T:KResult)
		[structural] 
	rule
		<k> figureInitializer(X:Id, t(Se:Set, arrayType(T:KResult, Len:Nat)), SingleInit(Constant(StringLiteral(S:String)))) 
			=> figureInitializer(X:Id, t(Se:Set, arrayType(T:KResult, Len:Nat)), CompoundInit(List(InitFragment(NextInit, SingleInit(Constant(StringLiteral(S:String)))))))
		...</k>
		when isCharType(T:KResult)
		andBool lengthString(S:String) <=Int Len:Nat
		[structural]
	rule
		<k> figureInitializer(X:Id, t(Se:Set, arrayType(T:KResult, Len:Nat)), SingleInit(Constant(WStringLiteral(S:List{K})))) 
			=> figureInitializer(X:Id, t(Se:Set, arrayType(T:KResult, Len:Nat)), CompoundInit(List(InitFragment(NextInit, SingleInit(Constant(WStringLiteral(S:List{K})))))))
		...</k>
		when isWCharType(T:KResult)
		andBool lengthList{K}(S:List{K}) <=Int Len:Nat
		[structural] 
	
	rule
		<k> figureInitializer(X:Id, t(_, (incompleteArrayType(T:KResult) 
			=> arrayType(T:KResult, lengthString(S:String) +Int 1))), SingleInit(Constant(StringLiteral(S:String)))) 
		...</k>
		when isCharType(T:KResult)
		[structural]
	rule
		<k> figureInitializer(X:Id, t(_, (incompleteArrayType(T:KResult) 
			=> arrayType(T:KResult, lengthList{K}(S:List{K}) +Int 1))), SingleInit(Constant(WStringLiteral(S:List{K})))) 
		...</k>
		when isWCharType(T:KResult)
		[structural] 
		
	rule
		<k> figureInitializer(X:Id, t(Se:Set, incompleteArrayType(T:KResult)), CompoundInit(List(InitFragment(NextInit, SingleInit(Constant(StringLiteral(S:String)))))))
			=> figureInitializer(X:Id, t(Se:Set, incompleteArrayType(T:KResult)), SingleInit(Constant(StringLiteral(S:String))))
		...</k>
		[structural] 
		
	// this comes from function declarations.  should probably adjust this
	rule
		<k> figureInitializer(X:Id, T:KResult, initializer(K:K))
			=> figureInitializer-aux(X:Id, T:KResult, initializer(K:K))
		...</k>
		[structural] 

	rule
		<k> figureInitializer-aux(X:Id, T:KResult, initializer(K:K))
			=> initializerValue(X:Id, T:KResult, K:K)
		...</k>
		when notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
		andBool notBool isConstType(T:KResult)
		[structural]
	rule
		<k> figureInitializer-aux(X:Id, T:KResult, initializer(K:K))
			=> initializerValue(X:Id, T:KResult, (K:K ~> makeUnwritableVar(X:Id)))
		...</k>
		when notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
		andBool isConstType(T:KResult)
		[structural]
	
	// base types
	rule
		<k> figureInitializer(X:Id, T:KResult, SingleInit(K:K))
			=> figureInitializer-aux(X:Id, T:KResult, initializer(Computation(AllowWrite(X:Id) := K:K)))
		...</k>
		when notBool isArrayType(T:KResult)
		[structural] 
	// c1x 6.7.8:11
	rule
		<k> figureInitializer(X:Id, T:KResult, CompoundInit(List(InitFragment(NextInit, SingleInit(K:K)))))
			=> figureInitializer-aux(X:Id, T:KResult, initializer(Computation(AllowWrite(X:Id) := K:K)))
		...</k>
		when notBool (isAggregateType(T:KResult) orBool isUnionType(T:KResult))
		[structural] 
		
	rule DeclarationDefinition(InitNameGroup(T:KResult, List((K:K,, K':K,, L:List{K}))))
		=> DeclarationDefinition(InitNameGroup(T:KResult, List(K:K)))
		~> DeclarationDefinition(InitNameGroup(T:KResult, List((K':K,, L:List{K}))))
		[structural]
	rule 
		DeclarationDefinition(InitNameGroup(T:KResult, List(InitName(Name:K, Exp:K))))
			=> doDeclare(SingleName(T:KResult, Name:K), Exp:K)
		[structural]
			
	rule Typedef(NameGroup(T:KResult, List((K:K,, L:List{K})))) 
		=> defineType(SingleName(T:KResult, K:K))
		~> Typedef(NameGroup(T:KResult, List(L:List{K})))
		[structural]
	rule Typedef(NameGroup(T:KResult, List(.List{K}))) => .K
		[structural]

	rule
		<k> defineType(typedDeclaration(T:KResult, X:Id)) 
			=> giveType(typedef(X:Id), T:KResult) 
		...</k>
		[structural] 
			
	syntax K ::= "declareFunction" "(" Id "," Type "," K ")" [klabel(declareFunction)] 
	syntax K ::= "declareExternalVariable" "(" Id "," Type "," K ")" [klabel(declareExternalVariable)] 
	syntax K ::= "declareInternalVariable" "(" Id "," Type "," K ")" [klabel(declareInternalVariable)] 
	
	// function definition
	rule
		<k> doDeclare(typedDeclaration(T:KResult, X:Id), K:K) 
			=> declareFunction(X:Id, T:KResult, K:K)
		...</k>
		<currentFunction> File-Scope </currentFunction>
		when notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
		andBool isFunctionType(T:KResult)
		[structural]
		
	// fixme there are still no nested functions though, right_
	rule
		<k> doDeclare(typedDeclaration(T:KResult, X:Id), NoInit) 
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:KResult))
		...</k>
		<externalLocations>... X:Id |-> Loc:Nat ...</externalLocations> 
		<currentFunction> F:K </currentFunction>
		when notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
		andBool isFunctionType(T:KResult)
		andBool F:K =/=K File-Scope
		[structural] 
	// fixme i believe this is for local declarations of external library functions
	rule
		<k> doDeclare(typedDeclaration(T:KResult, X:Id), NoInit) 
			=> giveType(X:Id, unqualifyType(T:KResult))
		...</k>
		<externalLocations> Locs:Map </externalLocations> 
		<currentFunction> F:K </currentFunction>
		when notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
		andBool isFunctionType(T:KResult)
		andBool F:K =/=K File-Scope
		andBool notBool $hasMapping(Locs:Map, X:Id)
		[structural] 
	rule
		<k> doDeclare(typedDeclaration(T:KResult, X:Id), K:K)
			=> declareExternalVariable(X:Id, T:KResult, #if K:K ==K NoInit #then NoInit #else CodeLoc(K:K, L:CabsLoc) #fi)
		...</k>
		<currentFunction> File-Scope </currentFunction>
		<currentProgramLoc> L:CabsLoc </currentProgramLoc>
		// if notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
		when notBool isFunctionType(T:KResult)
		[structural] 
	rule
		<k> doDeclare(typedDeclaration(T:KResult, X:Id), K:K) 
			=> declareInternalVariable(X:Id, T:KResult, K:K)
		...</k>
		<currentFunction> F:K </currentFunction>
		// if notBool isIncompleteType(T:KResult) // I'd like to get rid of this cleanly
		when notBool isFunctionType(T:KResult)
		andBool F:K =/=K File-Scope
		[structural] 
		
	//- external variables
	// feature request : nice to have MapList
	
	// function definition
	rule
		<k> declareFunction(X:Id, T:KResult, K:K)
			=> declareWithLinkage(X:Id, T:KResult, K:K, external)
		...</k>
		when notBool isStaticType(T:KResult)
		andBool K:K =/=K NoInit
		[structural] 

	rule
		<k> declareFunction(X:Id, T:KResult, NoInit)
			=> declareWithLinkage(X:Id, t(.Set, prototype(T:KResult)), NoInit, external)
		...</k>
		when notBool isStaticType(T:KResult)
		[structural] 
		
	// fixme not handling internal prototypes
	rule
		<k> declareFunction(X:Id, T:KResult, K:K)
			=> declareWithLinkage(X:Id, T:KResult, K:K, internal)
		...</k>
		<currentFunction> File-Scope </currentFunction>
		when isStaticType(T:KResult)
		[structural] 
		
		
	
	syntax K ::= "declareWithLinkage" "(" Id "," Type "," K "," K ")" [klabel(declareWithLinkage)] // id, type, possible init, linkage (external, internal, noLinkage)
	
	//- internal variables
	
	// fixme need to look for bad use
	rule
		<k> declareInternalVariable(X:Id, T:KResult, K:K)
			=> declareWithLinkage(X:Id, T:KResult, K:K, noLinkage)
		...</k>
		when notBool isStaticType(T:KResult)
		andBool notBool isExternType(T:KResult)
		[structural] 
		
	rule
		<k> declareInternalVariable(X:Id, T:KResult, NoInit)
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:KResult))
		...</k>
		<internalLocations>... Tu:K |-> Map((_ kpair(X:Id, BlockNum:Nat) |-> Loc:Nat)) ...</internalLocations>
		<blockHistory> ListItem(BlockNum:Nat) ...</blockHistory>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when isStaticType(T:KResult)
		andBool notBool isExternType(T:KResult)
		[structural] 
	rule
		<k> declareInternalVariable(X:Id, T:KResult, NoInit)
			=> allocateType(Loc:Nat, T:KResult)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:KResult))
			~> zero(X:Id)
		...</k>
		<internalLocations>... Tu:K |-> Map((Locs:Map => Locs:Map[Loc:Nat / kpair(X:Id, BlockNum:Nat)])) ...</internalLocations>
		<blockHistory> ListItem(BlockNum:Nat) ...</blockHistory>
		<nextSharedLoc> Loc:Nat => inc(Loc:Nat) </nextSharedLoc>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when isStaticType(T:KResult)
		andBool notBool isExternType(T:KResult)
		andBool notBool $hasMapping(Locs:Map, kpair(X:Id, BlockNum:Nat))
		[structural] 
		
	rule
		<k> declareInternalVariable(X:Id, T:KResult, K:K)
			=> defineAndInit(X:Id, unqualifyType(T:KResult), figureInitializer(X:Id, removeStorageSpecifiers(T:KResult), K:K), Loc:Nat)
		...</k>
		<internalLocations>... Tu:K |-> Map((Locs:Map => Locs:Map[Loc:Nat / kpair(X:Id, BlockNum:Nat)])) ...</internalLocations>
		<blockHistory> ListItem(BlockNum:Nat) ...</blockHistory>
		<nextSharedLoc> Loc:Nat => inc(Loc:Nat) </nextSharedLoc>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when isStaticType(T:KResult)
		andBool notBool isExternType(T:KResult)
		andBool K:K =/=K NoInit
		andBool notBool $hasMapping(Locs:Map, kpair(X:Id, BlockNum:Nat))
		[structural] 
				
	// this is essentially defineandinit, but that checks if type has been seen for allocation
	syntax K ::= "reseenStatic" "(" Id "," Type "," K "," Nat ")" [strict(3) klabel(reseenStatic)] 
	rule
		<k> declareInternalVariable(X:Id, T:KResult, K:K)
			=> reseenStatic(X:Id, unqualifyType(T:KResult), figureInitializer(X:Id, removeStorageSpecifiers(T:KResult), K:K), Loc:Nat)
		...</k>
		<internalLocations>... Tu:K |-> Map((_ kpair(X:Id, BlockNum:Nat) |-> Loc:Nat)) ...</internalLocations>
		<blockHistory> ListItem(BlockNum:Nat) ...</blockHistory>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when isStaticType(T:KResult)
		andBool notBool isExternType(T:KResult)
		andBool K:K =/=K NoInit
		[structural] 
		
	rule
		<k> reseenStatic(X:Id, _, initializerValue(X:Id, T:KResult, _), Loc:Nat)
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:KResult)
		...</k>
		[structural] 
		
		
	rule [declareExternInternal]:
		<k> declareInternalVariable(X:Id, T:KResult, NoInit)
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:KResult))
		...</k>
		<externalLocations>... X:Id |-> Loc:Nat ...</externalLocations>
		when notBool isIncompleteType(T:KResult)
		andBool notBool isStaticType(T:KResult)
		andBool isExternType(T:KResult)
		[structural] 
		
	
	//- external variables
	rule
		<k> declareExternalVariable(X:Id, T:KResult, K:K)
			=> declareWithLinkage(X:Id, T:KResult, K:K, external)
		...</k>
		when notBool isStaticType(T:KResult)
		andBool notBool isExternType(T:KResult)
		[structural] 
	rule
		<k> declareExternalVariable(X:Id, T:KResult, K:K)
			=> declareWithLinkage(X:Id, T:KResult, K:K, external)
		...</k>
		<preLinkage>... Tu:K |-> Map(Linkage:Map) ...</preLinkage>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when notBool isStaticType(T:KResult)
		andBool isExternType(T:KResult)
		andBool notBool $hasMapping(Linkage:Map, X:Id)
		[structural] 
	// not triggering
	rule [declareExtern-again]:
		<k> declareExternalVariable(X:Id, T:KResult, K:K)
			=> declareWithLinkage(X:Id, T:KResult, K:K, Linkage:Map(X:Id))
		...</k>
		<preLinkage>... Tu:K |-> Map(Linkage:Map) ...</preLinkage>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when notBool isStaticType(T:KResult)
		andBool isExternType(T:KResult)
		andBool $hasMapping(Linkage:Map, X:Id)
		[structural] 
	rule
		<k> declareExternalVariable(X:Id, T:KResult, K:K)
			=> declareWithLinkage(X:Id, T:KResult, K:K, internal)
		...</k>
		when isStaticType(T:KResult)
		andBool notBool isExternType(T:KResult)
		[structural] 
		
	syntax K ::= "declareOnly" "(" Id "," Type "," K ")" [klabel(declareOnly)] 
	syntax K ::= "declareAndDefine" "(" Id "," Type "," K "," K ")" [klabel(declareAndDefine)] 

	rule
		<k> declareWithLinkage(X:Id, T:KResult, NoInit, L:K) => declareOnly(X:Id, T:KResult, L:K) ...</k>
		<declarationOrder>... Tu:K |-> ListToK(_ (. => ListItem(X:Id))) ...</declarationOrder>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when L:K =/=K noLinkage
		[structural] 
	rule
		<k> declareWithLinkage(X:Id, T:KResult, K:K, L:K) => declareAndDefine(X:Id, T:KResult, K:K, L:K) ...</k>
		<declarationOrder>... Tu:K |-> ListToK(_ (. => ListItem(X:Id))) ...</declarationOrder>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when K:K =/=K NoInit
		andBool L:K =/=K noLinkage
		[structural] 
		
	// fixme this terribly needs to be refactored.  I'm duplicating the above two rules so I don't add locals to the declaration order
	rule
		<k> declareWithLinkage(X:Id, T:KResult, NoInit, L:K) => declareOnly(X:Id, T:KResult, L:K) ...</k>
		// <declarationOrder>... Tu:K |-> ListToK(_ (. => ListItem(X:Id))) ...</declarationOrder>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when L:K ==K noLinkage
		[structural] 
	rule
		<k> declareWithLinkage(X:Id, T:KResult, K:K, L:K) => declareAndDefine(X:Id, T:KResult, K:K, L:K) ...</k>
		// <declarationOrder>... Tu:K |-> ListToK(_ (. => ListItem(X:Id))) ...</declarationOrder>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
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
	rule
		<k> declareOnly(X:Id, T:KResult, external)
			=> .K
		...</k>
		<declarations>... .Set => SetItem(X:Id) ...</declarations>
		<preLinkage>... Tu:K |-> Map((Linkage:Map => Linkage:Map[external / X:Id])) ...</preLinkage>
		<preTypes>... Tu:K |-> Map((Types:Map => Types:Map[T:KResult / X:Id])) ...</preTypes>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when (notBool $hasMapping(Linkage:Map, X:Id) 
				orBool Linkage:Map(X:Id) ==K external
			)
			andBool (
				notBool $hasMapping(Types:Map, X:Id)
				// orBool Types:Map(X:Id) ==K prototype(T:KResult)
				orBool isTypeCompatible(unqualifyType(Types:Map(X:Id)), unqualifyType(T:KResult))
			)
		[structural] 
		
	rule
		<k> declareOnly(X:Id, t(_, prototype(T:KResult)), external)
			=> .K
		...</k>
		<preLinkage>... Tu:K |-> Map((Linkage:Map => Linkage:Map[external / X:Id])) ...</preLinkage>
		<preTypes>... Tu:K |-> Map(Types:Map) ...</preTypes>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when (notBool $hasMapping(Linkage:Map, X:Id) 
				orBool Linkage:Map(X:Id) ==K external
			)
			andBool isTypeCompatible(unqualifyType(Types:Map(X:Id)), unqualifyType(T:KResult))
		[structural]
	
	// fixme haven't thought about this much, is it right_
	rule
		<k> declareOnly(X:Id, T:KResult, internal)
			=> .K
		...</k>
		<declarations>... .Set => SetItem(X:Id) ...</declarations>
		<preLinkage>... Tu:K |-> Map((Linkage:Map => Linkage:Map[internal / X:Id])) ...</preLinkage>
		<preTypes>... Tu:K |-> Map((Types:Map => Types:Map[T:KResult / X:Id])) ...</preTypes>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when notBool $hasMapping(Linkage:Map, X:Id) 
		orBool Linkage:Map(X:Id) ==K internal
		[structural] 
	rule
		<k> declareOnly(X:Id, T:KResult, noLinkage)
			=> allocateType(Loc:Nat, T:KResult)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:KResult)
		...</k>
		<nextLoc> Loc:Nat => inc(Loc:Nat) </nextLoc>
		<localVariables> Vars:List (. => ListItem(X:Id)) </localVariables>
		<localAddresses>... .Set => SetItem(Loc:Nat) ...</localAddresses>
		when notBool isIncompleteType(T:KResult)
		andBool notBool isStaticType(T:KResult)
		andBool notBool isExternType(T:KResult)
		andBool notBool X:Id in Vars:List // this should be here statically, but not dynamically
		[structural]
	rule // same as above, but for the case where the variable has already been declared.  this is seen if we goto earlier in the same block
		<k> declareOnly(X:Id, T:KResult, noLinkage)
			=> .K
		...</k>
		<localVariables>... ListItem(X:Id) ...</localVariables>
		when notBool isIncompleteType(T:KResult)
		andBool notBool isStaticType(T:KResult)
		andBool notBool isExternType(T:KResult)
		[structural] 
	
	/*@ \source[n1570]{\para{6.2.2}{4}}
	For an identifier declared with the storage-class specifier \cinline{extern} in a scope in which a prior declaration of that identifier is visible, if the prior declaration specifies internal or external linkage, the linkage of the identifier at the later declaration is the same as the linkage specified at the prior declaration. If no prior declaration is visible, or if the prior declaration specifies no linkage, then the identifier has external linkage. 
	*/
	// exception to multiple definitions for functions since we consider prototypes to be definitions to some extent
	// case when it has no previous linkage, or previous linkage is external
	rule
		<k> declareAndDefine(X:Id, T:KResult, K:K, external)
			=> .K
		...</k>
		<declarations>... .Set => SetItem(X:Id) ...</declarations>
		<externalDefinitions> Def:Map => Def:Map (X:Id |-> declarationObject(unqualifyType(T:KResult), Tu:K, K:K)) </externalDefinitions>
		<preLinkage>... Tu:K |-> Map((Linkage:Map => Linkage:Map[external / X:Id])) ...</preLinkage>
		<preTypes>... Tu:K |-> Map((Types:Map => Types:Map[T:KResult / X:Id])) ...</preTypes>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when (notBool $hasMapping(Def:Map, X:Id) orBool isFunctionType(T:KResult))
		andBool (notBool $hasMapping(Linkage:Map, X:Id) orBool Linkage:Map(X:Id) ==K external)
		[structural]
		
	// case when it has a previous linkage (internal).  
	rule
		<k> declareAndDefine(X:Id, T:KResult, K:K, external)
			=> .K
		...</k>
		<declarations>... .Set => SetItem(X:Id) ...</declarations>
		// <externalDefinitions> Def:Map => Def:Map (X:Id |-> declarationObject(unqualifyType(T:KResult), Tu:K, K:K)) </externalDefinitions>
		<internalDefinitions>... Tu:K |-> Map((Def:Map => Def:Map[declarationObject(unqualifyType(T:KResult), Tu:K, K:K) / X:Id])) ...</internalDefinitions>
		<preLinkage>... Tu:K |-> Map(Linkage:Map) ...</preLinkage>
		<preTypes>... Tu:K |-> Map((Types:Map => Types:Map[T:KResult / X:Id])) ...</preTypes>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when (notBool $hasMapping(Def:Map, X:Id) orBool isFunctionType(T:KResult))
		andBool Linkage:Map(X:Id) ==K internal
		[structural]
		
	rule
		<k> declareAndDefine(X:Id, T:KResult, K:K, internal)
			=> .K
		...</k>
		<declarations>... .Set => SetItem(X:Id) ...</declarations>
		<internalDefinitions>... Tu:K |-> Map((Def:Map => Def:Map[declarationObject(unqualifyType(T:KResult), Tu:K, K:K) / X:Id])) ...</internalDefinitions>
		<preLinkage>... Tu:K |-> Map((Linkage:Map => Linkage:Map[internal / X:Id])) ...</preLinkage>
		<preTypes>... Tu:K |-> Map((Types:Map => Types:Map[T:KResult / X:Id])) ...</preTypes>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		when (notBool $hasMapping(Def:Map, X:Id) orBool isFunctionType(T:KResult))
		andBool (notBool $hasMapping(Linkage:Map, X:Id) orBool Linkage:Map(X:Id) ==K internal)
		[structural]
		
	syntax K ::= "defineAndInit" "(" Id "," Type "," K "," Nat ")" [strict(3) klabel(defineAndInit)] 
	rule
		<k> declareAndDefine(X:Id, T:KResult, K:K, noLinkage)
			=> defineAndInit(X:Id, T:KResult, figureInitializer(X:Id, T:KResult, K:K), Loc:Nat)
		...</k>
		<nextLoc> Loc:Nat => inc(Loc:Nat) </nextLoc>
		<localVariables> Vars:List (. => ListItem(X:Id)) </localVariables>
		<localAddresses>... .Set => SetItem(Loc:Nat) ...</localAddresses>
		when notBool X:Id in Vars:List // again, this should be needed statically, but not dynamically
		[structural] 
	rule // this happens when we jump before a variable declaration with an initialization in the same block
		<k> declareAndDefine(X:Id, T:KResult, K:K, noLinkage)
			=> justInit(figureInitializer(X:Id, T:KResult, K:K))
		...</k>
		<localVariables>... ListItem(X:Id) ...</localVariables>
		[structural] 
		
	syntax K ::= "justInit" "(" K ")" [strict(1) klabel(justInit)]
	
	rule
		<k> justInit(initializerValue(X:Id, T:KResult, K:K)) => initialize(X:Id, T:KResult, K:K) ...</k>
		[structural]
		
	rule
		<k> defineAndInit(X:Id, _, initializerValue(X:Id, T:KResult, K:K), Loc:Nat)
			=> allocateTypeIfAbsent(Loc:Nat, T:KResult)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:KResult)
			~> initialize(X:Id, T:KResult, K:K)
		...</k>
		<shouldInit> true </shouldInit>
		[structural] 
		
	rule
		<k> defineAndInit(X:Id, _, initializerValue(X:Id, T:KResult, _), Loc:Nat)
			=> allocateTypeIfAbsent(Loc:Nat, T:KResult)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:KResult)
		...</k>
		<shouldInit> false </shouldInit>
		[structural]
		
	rule
		<k> figureInitializer-aux(_:Id, t(_, (incompleteArrayType(T:KResult) => arrayType(T:KResult, N:Nat))), initializer(K:K))
		...</k>
		<incompleteLength> N:Nat </incompleteLength>
		[structural] 

	syntax K ::= "allocateAndZeroIfAbsent" "(" Type "," Id ")" [klabel(allocateAndZeroIfAbsent)] 
	syntax K ::= "addToLinkage" "(" Id "," Type ")" [klabel(addToLinkage)] 
	syntax K ::= "addToGlobalEnv" "(" K "," Nat ")" [klabel(addToGlobalEnv)] 
	syntax K ::= "addToLocalEnv" "(" K "," Nat ")" [klabel(addToLocalEnv)] 
	
	rule
		<k> addToEnv(X:Id, Loc:Nat) => addToGlobalEnv(X:Id, Loc:Nat) ...</k>
		<currentFunction> File-Scope </currentFunction>
		[structural] 
	rule
		<k> addToEnv(X:Id, Loc:Nat) => addToLocalEnv(X:Id, Loc:Nat) ...</k>
		<currentFunction> F:K </currentFunction>
		when F:K =/=K File-Scope
		[structural] 
		
	rule
		<k> addToGlobalEnv(X:Id, Loc:Nat) => . ...</k>
		<genv>... Tu:K |-> Map((M':Map => M':Map[Loc:Nat / X:Id])) ...</genv>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		<env> E:Map => E:Map[Loc:Nat / X:Id] </env>
		[structural] 
	rule
		<k> addToLocalEnv(X:Id, Loc:Nat) => . ...</k>
		<env> E:Map => E:Map[Loc:Nat / X:Id] </env>
		[structural] 
	
	syntax K ::= "defineUsingOldDeclaration" "(" Type "," Id "," K ")" [klabel(defineUsingOldDeclaration)] 
	
	// syntax K ::= "defineFunctionUsingOldDeclaration" "(" Type "," Id "," K ")" [klabel(defineFunctionUsingOldDeclaration)] 
	// FIXME check prototypes
	rule [function-definition]:
		<k> FunctionDefinition(typedDeclaration(T:KResult, X:Id), Block:K) 
			=> declareFunction(
				X:Id, 
				T:KResult, 
				initializer(initFunction(
					&(X:Id), 
					functionObject(
						X:Id, 
						unqualifyType(T:KResult), 
						BODY
					)
				))
			)
			~> calculateGotoMap(X:Id, BODY)
		...</k>
		when isFunctionType(T:KResult)
		where BODY = (Block:K ~> Return(#if (X:Id ==K Identifier("main")) #then tv(0, t(.Set, int)) #else NothingExpression #fi))
		[structural] 
end module

module COMMON-SEMANTICS-DECLARATIONS-FUNTION-BODY is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
	syntax K ::= "typingBody" "(" Id "," Type "," K ")" [klabel(typingBody)] // third argument is just for now, as a hack
	
end module

module COMMON-SEMANTICS-DECLARATIONS-INITIALIZATIONS is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
	
	syntax K ::= "te" "(" K "," Type ")" [klabel(te)] 
	syntax K ::= "getInitializer" [klabel(getInitializer)] 
	syntax K ::= "fillInitializer" "(" K ")" [klabel(fillInitializer)] 
	syntax K ::= "fillInitializer-aux" "(" K ")" [klabel(fillInitializer-aux)] 
	syntax K ::= "fillInitializer" "(" List{K} ")" [klabel(fillInitializer)] 
	syntax C ::= "completeInitializerFragment" "(" K "," K ")" [klabel(completeInitializerFragment)] 
	syntax KResult ::= "initializerFragment" "(" K ")" [klabel(initializerFragment)] 
	
	rule
		<k> getInitializer => initializer(K:K) ...</k>
		<savedInitialization> K:K => . </savedInitialization> 
		<currentObject> _:List => . </currentObject> 
		<currentSubObject> _:List => . </currentSubObject> 
		[structural] 

	rule
		<k> startInitializer(T:KResult, X:Id, CompoundInit(List(L:List{K})))
			=> fillInitializer(L:List{K}) 
			~> getInitializer
		...</k>
		<incompleteLength> _ => 0 </incompleteLength>
		<currentSubObject> .List => ListItem(te(X:Id, T:KResult)) </currentSubObject>
		<currentObject> .List => ListItem(te(X:Id, T:KResult)) </currentObject>
		<savedInitialization>... .K => zero(X:Id) </savedInitialization> 
		when isUnionType(T:KResult) orBool isAggregateType(T:KResult)
		[structural] 
	
	rule
		<k> fillInitializer((InitFragment(K:K, Exp:K),, L:List{K}))
			=> fillInitializer(InitFragment(K:K, Exp:K)) 
			~> fillInitializer(L:List{K})
		...</k>
		[structural] 
	rule
		<k> fillInitializer(.List{K}) => . ...</k>
		[structural] 
	
	syntax ListItem ::= "next" [klabel(next)] 
	syntax ListItem ::= "block" [klabel(block)] 
	
	rule
		<currentSubObject> 
			ListItem(te(K:K, t(S:Set, arrayType(T:KResult, Len:Nat))))
			=> ListItem(te(K:K[0], T:KResult)) ListItem(te(K:K, t(S:Set, arrayType(T:KResult, Len:Nat))))
		...</currentSubObject>
		[structural] 
	rule
		<currentSubObject> 
			ListItem(te(K:K, t(Se:Set, incompleteArrayType(T:KResult))))
			=> ListItem(te(K:K[0], T:KResult)) ListItem(te(K:K, t(Se:Set, incompleteArrayType(T:KResult))))
		...</currentSubObject>
		[structural] 
	rule
		<currentSubObject> 
			ListItem(te(K:K, t(Se:Set, structType(S:Id))))
			=> ListItem(te(K:K . F:Id, T:KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
		...</currentSubObject>
		<structs>... 
			S:Id |-> aggregateInfo((typedDeclaration(T:KResult, F:Id),, _), _, _)
		...</structs> 
		[structural] 
		
	// fixme these are terrible!
	rule
		<currentSubObject> 
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
			(next ListItem(te(K:K[N:Nat], T:KResult)) => ListItem(te(K:K[N:Nat +Int 1], T:KResult)))
			ListItem(te(K:K, t(_, arrayType(_, Len:Nat))))
		...</currentSubObject>
		when Len:Nat >Int N:Nat +Int 1
		[structural] 
	rule [init-next-array-element-done]:
		<currentSubObject>
			next (ListItem(te(K:K[N:Nat], T:KResult)) => .List) ListItem(te(K:K, t(_, arrayType(_, Len:Nat))))
		...</currentSubObject>
		when notBool Len:Nat >Int N:Nat +Int 1
		[structural] 
	
	rule [init-next-incomplete-array-element]:
		<currentSubObject>
			(next ListItem(te(K:K[N:Nat], T:KResult)) => ListItem(te(K:K[N:Nat +Int 1], T:KResult))) 
			ListItem(te(K:K, t(_, incompleteArrayType(_))))
		...</currentSubObject>
		[structural] 
	
	rule [init-next-struct-element]:
		<currentSubObject>
			next ListItem(te(K:K . F:Id, T:KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
			=> ListItem(te(K:K . F':Id, T':KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
		...</currentSubObject>
		<structs>...
			S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),, typedDeclaration(T':KResult, F':Id),, _), _, _)
		...</structs> 
		when F':Id =/=K #NoName
		[structural] 
	 
	rule [init-next-struct-element-noname]:
		<currentSubObject>
			next ListItem(te(K:K . F:Id, T:KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
			=> ListItem(te(K:K . F':Id, T':KResult)) ListItem(te(K:K, t(Se:Set, structType(S:Id))))
		...</currentSubObject>
		<structs>...
			S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),, typedDeclaration(_, #NoName),, typedDeclaration(T':KResult, F':Id),, _), _, _)
		...</structs>
		[structural] 
		
	rule [init-next-struct-element-done]:
		<currentSubObject>
			next (ListItem(te(K:K . F:Id, T:KResult)) => .) ListItem(te(K:K, t(_, structType(S:Id))))
		...</currentSubObject>
		<structs>...
			S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id)), _, _)
		...</structs> 
		[structural] 
	rule [init-next-struct-element-done-noname]:
		<currentSubObject>
			next (ListItem(te(K:K . F:Id, T:KResult)) => .) ListItem(te(K:K, t(_, structType(S:Id))))
		...</currentSubObject>
		<structs>...
			S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),, typedDeclaration(_, #NoName)), _, _)
		...</structs> 
		[structural] 
		
	rule [init-next-union-element-done]:
		<currentSubObject>
			next (ListItem(te(K:K . _:Id, T:KResult)) => .List) ListItem(te(K:K, t(_, unionType(S:Id))))
		...</currentSubObject>
		[structural] 
		
	rule
		<k> fillInitializer(InitFragment(NextInit, Exp:K)) 
			=> fillInitializer(Exp:K) 
		...</k>
		[structural] 
		
	syntax K ::= "finishCompoundInit" "(" List ")" [klabel(finishCompoundInit)] 
	rule
		<k> fillInitializer(CompoundInit(List(L:List{K})))
			=> fillInitializer(L:List{K})
			// ~> debug
			~> finishCompoundInit(next ListItem(te(K:K, T:KResult)) Remainder:ListItem)
		...</k>
		<currentSubObject> (_:List => .) ListItem(te(K:K, T:KResult)) (Remainder:ListItem => .) </currentSubObject>
		<currentObject> (. => ListItem(te(K:K, T:KResult))) ...</currentObject>
		when isAggregateType(T:KResult) orBool isUnionType(T:KResult)
		[structural]
	rule
		<k> finishCompoundInit(L:List) => 
			.K
			// debug
		...</k>
		<currentObject> (ListItem(te(K:K, T:KResult)) => .) ...</currentObject>
		<currentSubObject> (_ => L:List) </currentSubObject>
		[structural] 
			
	context fillInitializer(InitFragment(HOLE, _)) 
	syntax K ::= "buildDesignator" "(" K ")" [klabel(buildDesignator)] 
	
	// note that these clear the current subobject cell, because it will be repopulated when building the designator
	rule
		<k> fillInitializer(InitFragment(InFieldInit(F:Id, K':K), Exp:K))
			=> fillInitializer(InitFragment(buildDesignator(InFieldInit(F:Id, K':K)), Exp:K))
		...</k>
		<currentObject> ListItem(te(K:K, T:KResult)) ...</currentObject>
		<currentSubObject> _:List => block ListItem(te(K:K, T:KResult)) </currentSubObject>
		when isStructType(T:KResult) orBool isUnionType(T:KResult)
		[structural] 
	// fixme does this need to worry about incompleteLength_
	rule
		<k> fillInitializer(InitFragment(AtIndexInit(Index:K, K':K), Exp:K))
			=> fillInitializer(InitFragment(buildDesignator(AtIndexInit(Index:K, K':K)), Exp:K))
		...</k>
		<currentObject> ListItem(te(K:K, T:KResult)) ...</currentObject>
		<currentSubObject> _:List => block ListItem(te(K:K, T:KResult)) </currentSubObject>
		when isArrayType(T:KResult)
		[structural] 
		
	
	// fixme these are also too restrictive on type.  if we try to assign an int to a long-int field, it will fail
	// i don't think this is true anymore
	rule
		<k> buildDesignator(InFieldInit(F:Id, More:K)) 
			=> buildDesignator(More:K)
		...</k>
		<currentSubObject> block (.List => ListItem(te(K:K . F:Id, T:KResult))) ListItem('te(K:K,, 't(_,, KL:KLabel(S:Id)))) ...</currentSubObject>
		<structs>... 
			// S:Id |-> _ :: typedDeclaration(T:KResult, F:Id) :: _ 
			S:Id |-> aggregateInfo(_, (_ F:Id |-> T:KResult), _)
		...</structs>
		when KL:KLabel ==KLabel 'structType 
		orBool KL:KLabel ==KLabel 'unionType
		[structural] 
		
	rule
		<k> buildDesignator(NextInit) => NextInit ...</k>
		<currentSubObject> (block => .List) ...</currentSubObject>
		[structural] 
		
	define [innerType-arrayType]:
		innerType(t(_, arrayType(T:KResult, _:Nat))) => T:KResult
	define [innerType-incompleteArrayType]: 
		innerType(t(_, incompleteArrayType(T:KResult))) => T:KResult
	define [innerType-flexibleArrayType]: 
		innerType(t(_, flexibleArrayType(T:KResult))) => T:KResult
	define [innerType-qualifiedType]:
		innerType(t(_, qualifiedType(T:KResult, _))) => innerType(T:KResult)
	define [innerType-pointerType]:
		innerType(t(_, pointerType(T:KResult))) => T:KResult
	define [innerType-bitfieldType]:
		innerType(t(_, bitfieldType(T:KResult, _:Nat))) => T:KResult
	define [innerType-functionType]:
		innerType(t(_, functionType(T:KResult, _:List{KResult}))) => T:KResult

	context buildDesignator(AtIndexInit((HOLE => reval(HOLE)), _)) 
	rule
		<k> buildDesignator(AtIndexInit(tv(N:Nat, _), More:K)) 
			=> buildDesignator(More:K)
		...</k>
		<currentSubObject> block (.List => ListItem(te(K:K[N:Nat], innerType(T:KResult)))) ListItem(te(K:K, T:KResult)) ...</currentSubObject>
		when isArrayType(T:KResult)
		[structural] 
	
	syntax K ::= "popInit" [klabel(popInit)]
	
	declare getTopArrayUse : K -> Nat 
	define getTopArrayUse(X:Id) => 0
	define getTopArrayUse(X:Id[N:Nat]) => N:Nat +Int 1 // +1 for length instead of index
	define getTopArrayUse(K:K . F:Id) => getTopArrayUse(K:K)
	define getTopArrayUse((K:K[N:Nat])[_]) => getTopArrayUse(K:K[N:Nat])
	define getTopArrayUse((K:K . F:Id)[_]) => getTopArrayUse(K:K)
	
	syntax K ::= "initializeSingleInit" "(" K ")" [klabel(initializeSingleInit)] 
		
	rule
		<k> (.K => typeof(K:K)) ~> initializeSingleInit(K:K) ...</k>
		[structural] 
	
	// fixme want to exclude strings, but not normal arrays
	rule
		<k> T':KResult ~> initializeSingleInit(K':K) => . ...</k>
		<currentSubObject> (.List => next) ListItem(te(K:K, T:KResult)) ...</currentSubObject>
		<incompleteLength> N:Nat => maxInt(N:Nat, getTopArrayUse(K:K)) </incompleteLength>
		<savedInitialization>... .K => Computation(AllowWrite(K:K) := K':K) ~> possiblyMakeConst(T:KResult, K:K) </savedInitialization>
		when (isBasicType(T:KResult) orBool isPointerType(T:KResult) orBool isBitfieldType(T:KResult))
		andBool notBool isStructType(T':KResult)
		andBool notBool isUnionType(T':KResult)
		[structural]
	
	syntax K ::= "possiblyMakeConst" "(" Type "," K ")" [klabel(possiblyMakeConst)]
	
	rule
		<k> possiblyMakeConst(T:KResult, K) => makeUnwritableSubObject(K) ...</k>
		when isConstType(T:KResult)
		[structural]
	rule
		<k> possiblyMakeConst(T:KResult, K) => . ...</k>
		when notBool isConstType(T:KResult)
		[structural]
		
	// this is used to have an aggregate on the RHS of a compound init
	// fixme want to exclude strings, but not normal arrays
	syntax K ::= "initFromAggregateRHS" "(" K "," Type ")" [klabel(initFromAggregateRHS)] 
	rule
		<k> T:KResult ~> initializeSingleInit(K:K) => initFromAggregateRHS(K:K, T:KResult) ...</k>
		when isStructType(T:KResult)
		orBool isUnionType(T:KResult)
		[structural] 
		
	syntax K ::= "initFromStructRHS" "(" K "," Type ")" [klabel(initFromStructRHS)] 
	rule
		<k> initFromAggregateRHS(K:K, t(S:Set, structType(S:Id)))
			=> initFromStructRHS(K:K, t(S:Set, structType(S:Id)))
		...</k>
		<currentSubObject> .List => findStruct(t(S:Set, structType(S:Id))) ...</currentSubObject>
		[structural] 
		
	syntax ListItem ::= "findStruct" "(" Type ")" [klabel(findStruct)] 
		
	rule
		<currentSubObject> findStruct(T:KResult) (ListItem(te(_, T':KResult)) => .List) ...</currentSubObject>
		when T:KResult =/=K T':KResult
		[structural] 
		
	// fixme unsafe, might have started to initialize other things
	rule
		<k> initFromStructRHS(K':K, t(_, structType(S:Id)))
			=> .K
		...</k>
		<currentSubObject> findStruct(t(_, structType(S:Id))) ListItem(te(K:K, t(_, structType(S:Id)))) => next ...</currentSubObject>
		<incompleteLength> N:Nat => maxInt(N:Nat, getTopArrayUse(K:K)) </incompleteLength>
		<savedInitialization>... .K => Computation(AllowWrite(K:K) := K':K) </savedInitialization> 
		[structural] 
	
	rule
		<k> fillInitializer(SingleInit(K:K)) => initializeSingleInit(K:K) ...</k>
		when getKLabel(K:K) =/=KLabel 'Constant
		[structural] 

	rule [fillInit-string-array-eq]:
		<k> fillInitializer(SingleInit(Constant(StringLiteral(S:String))))
			=> fillInitializer-aux(SingleInit(Constant(StringLiteral(S:String))))
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, arrayType(T:KResult, Len:Nat)))) ...</currentSubObject>
		when isCharType(T:KResult)
		andBool lengthString(S:String) ==Int Len:Nat
		[structural] 
	rule [fillInit-wstring-array-eq]:
		<k> fillInitializer(SingleInit(Constant(WStringLiteral(S:List{K}))))
			=> fillInitializer-aux(SingleInit(Constant(WStringLiteral(S:List{K}))))
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, arrayType(T:KResult, Len:Nat)))) ...</currentSubObject>
		when isWCharType(T:KResult)
		andBool lengthList{K}(S:List{K}) ==Int Len:Nat
		[structural] 
	rule [fillInit-string-array-lt]:
		<k> fillInitializer(SingleInit(Constant(StringLiteral(S:String))))
			=> fillInitializer(SingleInit(Constant(StringLiteral(S:String +String "\0"))))
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, arrayType(T:KResult, Len:Nat)))) ...</currentSubObject>
		when isCharType(T:KResult)
		andBool lengthString(S:String) <Int Len:Nat
		[structural] 
	rule [fillInit-wstring-array-lt]:
		<k> fillInitializer(SingleInit(Constant(WStringLiteral(S:List{K}))))
			=> fillInitializer(SingleInit(Constant(WStringLiteral((S:List{K},, 0)))))
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, arrayType(T:KResult, Len:Nat)))) ...</currentSubObject>
		when isWCharType(T:KResult)
		andBool lengthList{K}(S:List{K}) <Int Len:Nat
		[structural] 
	rule [fillInit-string-char]:
		<k> fillInitializer(SingleInit(Constant(StringLiteral(S:String))))
			=> fillInitializer-aux(SingleInit(Constant(StringLiteral(S:String +String "\0"))))
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, incompleteArrayType(T:KResult)))) ...</currentSubObject>
		when isCharType(T:KResult)
		[structural] 
	rule [fillInit-wstring-wchar]:
		<k> fillInitializer(SingleInit(Constant(WStringLiteral(S:List{K}))))
			=> fillInitializer-aux(SingleInit(Constant(WStringLiteral((S:List{K},, 0)))))
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ListItem(te(_, t(_, incompleteArrayType(T:KResult)))) ...</currentSubObject>
		when isWCharType(T:KResult)
		[structural]
	rule [fillInitAux-string-some]:
		<k> fillInitializer-aux(SingleInit(Constant(StringLiteral(S:String))))
			=> fillInitializer(SingleInit(tv(charToAscii(firstChar(S:String)), t(getModifiers(T:KResult), char)))) 
			~> fillInitializer-aux(SingleInit(Constant(StringLiteral(butFirstChar(S:String))))) 
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ...</currentSubObject>
		when S:String =/=String ""
		andBool isCharType(T:KResult)
		[structural]
	rule [fillInitAux-wstring-some]:
		<k> fillInitializer-aux(SingleInit(Constant(WStringLiteral((N:Nat,, S:List{K})))))
			=> fillInitializer(SingleInit(tv(N:Nat, cfg:wcharut)))
			~> fillInitializer-aux(SingleInit(Constant(WStringLiteral(S:List{K})))) 
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ...</currentSubObject>
		when isWCharType(T:KResult)
		[structural]
	// fixme not sure what happens in the case of   char *x = "";
	rule [fillInitAux-string-done]:
		<k> fillInitializer-aux(SingleInit(Constant(StringLiteral("")))) => .K ...</k>
		[structural]
	rule [fillInitAux-wstring-done]:
		<k> fillInitializer-aux(SingleInit(Constant(WStringLiteral(.List{K})))) => .K ...</k>
		[structural] 
		
	// this rule assumes all unrollings have already occurred, so it needs to be a rule
	// alternatively, i've added the condition below which might be enough
	rule [fillInit-string-notchar]:
		<k> fillInitializer(SingleInit(Constant(StringLiteral(S:String))))
			=> initializeSingleInit(Constant(StringLiteral(S:String)))
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ...</currentSubObject>
		when notBool isCharType(T:KResult)
		andBool (isBasicType(T:KResult) orBool isPointerType(T:KResult) orBool isBitfieldType(T:KResult))
		[structural] 
	rule [fillinit-wstring-notwchar]:
		<k> fillInitializer(SingleInit(Constant(WStringLiteral(S:List{K}))))
			=> initializeSingleInit(Constant(WStringLiteral(S:List{K})))
		...</k>
		<currentSubObject> ListItem(te(K:K, T:KResult)) ...</currentSubObject>
		when notBool isWCharType(T:KResult)
		andBool (isBasicType(T:KResult) orBool isPointerType(T:KResult) orBool isBitfieldType(T:KResult))
		[structural]
end module


module COMMON-SEMANTICS-DECLARATIONS-RESOLUTION is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
	
	syntax K ::= "canonicalizeTranslationUnitVariables" [klabel(canonicalizeTranslationUnitVariables)] 
	rule [unpack-TranslationUnit]:
		<k> TranslationUnit(Name:String, Strings:K, K:K, P:String) 
			=> preDeclareStrings(Strings:K)
			~> klistToK(eraseKLabel('StmtCons, K:K))
		...</k>
		<currentTranslationUnit> _ => Name:String </currentTranslationUnit>
		<declarationOrder> DeclOrder:Map => DeclOrder:Map[ListToK(.List) / Name:String] </declarationOrder>
		<internalLocations> ExtLoc:Map => ExtLoc:Map[Map(.) / Name:String] </internalLocations>
		<functionTranslationUnits> Funs:Map => Funs:Map[Map(.) / Name:String] </functionTranslationUnits> 
		<translationUnits>... . => BagItem(Name:String) ...</translationUnits>
		<preLinkage> Linkage:Map => Linkage:Map[Map(.) / Name:String] </preLinkage>
		<preTypes> Types:Map => Types:Map[Map(.) / Name:String] </preTypes>
		<internalDefinitions> Def:Map => Def:Map[Map(.) / Name:String] </internalDefinitions>
		<genv> Env:Map => Env:Map[Map(.) / Name:String] </genv>
		<gtypes> Gtypes:Map => Gtypes:Map[Map(.) / Name:String]</gtypes>
		<programText> M:Map => M:Map[P:String / Name:String] </programText>
		when notBool $hasMapping(Env:Map, Name:String)
		[structural]
		
	syntax K ::= "preDeclareStrings" "(" K ")" [klabel(preDeclareStrings)]
	
	rule
		<k> preDeclareStrings(List((K:K,, L:List{K})))
			=> K:K
			~> discard
			~> preDeclareStrings(List(L:List{K}))
		...</k>
		[structural]
	rule
		<k> preDeclareStrings(List(.List{K})) => .K ...</k>
		[structural]
	
	syntax K ::= "resolve" "(" K ")" [klabel(resolve)] 
	rule
		<k> (. => resolve(Tu:K)) ~> resolveReferences ...</k>
		<translationUnits>... BagItem(Tu:K) => .Bag ...</translationUnits>
		[structural] 
		
	// rule
		// <k> resolveReferences => .K ...</k>
		// <translationUnits> .Bag </translationUnits>
		// [structural] 
	
	syntax K ::= "resolveLeftovers" [klabel(resolveLeftovers)]
	rule
		<k> resolveReferences => resolveLeftovers ...</k>
		<translationUnits> .Bag </translationUnits>
		[structural] 
		
	rule
		<k> (.K =>
			addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:KResult))
			) ~> resolveLeftovers 
		...</k>
		<currentTranslationUnit> _ => Tu:K </currentTranslationUnit>
		<externalLocations>... X:Id |-> Loc:Nat ...</externalLocations>
		<leftoverExterns>... BagItem(leftover(Tu:K, X:Id, T:KResult)) => .Bag ...</leftoverExterns>
		[structural]
	rule
		<k> resolveLeftovers ...</k>
		<externalLocations> Locs:Map </externalLocations>
		<leftoverExterns>... BagItem(leftover(_, X:Id, _)) => .Bag ...</leftoverExterns>
		when notBool $hasMapping(Locs:Map, X:Id)
		[structural]
	
	rule
		<k> resolveLeftovers => .K ...</k>
		<leftoverExterns> .Bag </leftoverExterns>
		[structural]
			
	syntax K ::= "resolveInternal" "(" Id "," K "," K ")" [klabel(resolveInternal)] 
	syntax K ::= "resolveExternal" "(" Id "," K "," Bag "," K ")" [klabel(resolveExternal)] 
	syntax K ::= "resolveExternal-aux" "(" Id "," K "," Bag "," K "," Nat "," K ")" [metadata "strict=(6)" klabel(resolveExternal-aux)]
	
	syntax K ::= "recordFunctionTranslationUnitInformation" "(" K "," Type "," K "," K ")" [klabel(recordFunctionTranslationUnitInformation)] // name, type, context, where defined
	rule
		<k> recordFunctionTranslationUnitInformation(X:Id, T:KResult, Tu:K, DefTu:K) => .K ...</k>
		<functionTranslationUnits>... Tu:K |-> Map((Funs:Map => Funs:Map[DefTu:K / X:Id])) ...</functionTranslationUnits>
		when isFunctionType(T:KResult)
		[structural] 
	rule
		<k> recordFunctionTranslationUnitInformation(_, T:KResult, _, _) => .K ...</k>
		when notBool isFunctionType(T:KResult)
		[structural] 
	
	// fixme
	// should be adding to env after figuring initializer
	// should be changing env to be correct env before figuring initializer
	syntax K ::= "allocateWithInit" "(" K "," Nat ")" [strict klabel(allocateWithInit)] 
	syntax K ::= "noAllocateWithInit" "(" K "," Nat ")" [strict klabel(noAllocateWithInit)] 
	syntax K ::= "resolveInternal-aux" "(" Id "," K "," K "," K ")" [strict(4) klabel(resolveInternal-aux)] 
	rule
		<k> resolveInternal(X:Id, Tu:K, declarationObject(T:KResult, Tu:K, K:K))
			=> resolveInternal-aux(X:Id, Tu:K, declarationObject(T:KResult, Tu:K, K:K), figureInitializer(X:Id, T:KResult, K:K))
		...</k>
		<currentTranslationUnit> _ => Tu:K </currentTranslationUnit>
		[structural] 
	rule
		<k> resolveInternal-aux(X:Id, Tu:K, declarationObject(_, Tu:K, _), initializerValue(X:Id, T:KResult, K:K))
			=> allocateType(Loc:Nat, T:KResult)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:KResult)
			~> initialize(X:Id, T:KResult, K:K)
			~> recordFunctionTranslationUnitInformation(X:Id, T:KResult, Tu:K, Tu:K)
		...</k>
		<nextSharedLoc> Loc:Nat => inc(Loc:Nat) </nextSharedLoc>
		<currentTranslationUnit> _ => Tu:K </currentTranslationUnit>
		[structural] 
			
	rule
		<k> resolveExternal(X:Id, Tu:K, Units:Bag, declarationObject(T:KResult, DefTu:K, K:K))
			=> resolveExternal-aux(X:Id, Tu:K, Units:Bag, declarationObject(T:KResult, DefTu:K, K:K), Loc:Nat, figureInitializer(X:Id, T:KResult, K:K))
		...</k>
		<nextSharedLoc> Loc:Nat => inc(Loc:Nat) </nextSharedLoc>
		[structural] 
	rule
		<k> ( .K
			=> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:KResult)
			~> recordFunctionTranslationUnitInformation(X:Id, T:KResult, Tu':K, DefTu:K)
			) ~> resolveExternal-aux(X:Id, Tu:K, ((BagItem(Tu':K) => .) Units:Bag), declarationObject(_, DefTu:K, _), Loc:Nat, initializerValue(X:Id, T:KResult, K:K))
		...</k>
		<currentTranslationUnit> _ => Tu':K </currentTranslationUnit>
		<preLinkage>... Tu':K |-> Map((_ (X:Id |-> external => .))) ...</preLinkage>
		[structural] 
	rule
		<k> resolveExternal-aux(X:Id, Tu:K, .Bag, declarationObject(_, DefTu:K, _), Loc:Nat, initializerValue(X:Id, T:KResult, K:K))
			=> allocateType(Loc:Nat, T:KResult)
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, T:KResult)
			~> initialize(X:Id, T:KResult, K:K)
			~> recordFunctionTranslationUnitInformation(X:Id, T:KResult, Tu:K, DefTu:K)
		...</k>
		<currentTranslationUnit> _ => Tu:K </currentTranslationUnit>
		<externalLocations> Locs:Map => Locs:Map[Loc:Nat / X:Id] </externalLocations>
		when notBool $hasMapping(Locs:Map, X:Id)
		[structural] 
	rule
		<k> resolveExternal-aux(X:Id, _, ((BagItem(Tu:K) => .) Units:Bag), _, _:Nat, _) ...</k>
		<preLinkage>... Tu:K |-> Map(M:Map) ...</preLinkage>
		when notBool $hasMapping(M:Map, X:Id)
		[structural] 
	rule [resolveExternal-internal]:
		<k> resolveExternal-aux(X:Id, _, ((BagItem(Tu:K) => .) Units:Bag), _, _:Nat, _) ...</k>
		<preLinkage>... Tu:K |-> Map((_ X:Id |-> internal)) ...</preLinkage>
		[structural] 
	
	// 
	rule
		<k> (.K => resolveInternal(X:Id, Tu:K, K:K)) ~> resolve(Tu:K) ...</k>
		<preLinkage>... Tu:K |-> Map((_ (X:Id |-> internal => .Map))) ...</preLinkage>
		<internalDefinitions>... Tu:K |-> Map((_ (X:Id |-> K:K => .Map))) ...</internalDefinitions>
		<declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .List) _) ...</declarationOrder>
		[structural] 
		
	// static variable without an initializer
	rule
		<k> (.K => resolveInternal(X:Id, Tu:K, declarationObject(unqualifyType(T:KResult), Tu:K, initializer(zero(X:Id))))) ~> resolve(Tu:K) ...</k>
		<preLinkage>... Tu:K |-> Map((_ (X:Id |-> internal => .Map))) ...</preLinkage>
		<internalDefinitions>... Tu:K |-> Map(Defs:Map) ...</internalDefinitions>
		<declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .List) _) ...</declarationOrder>
		<preTypes>... Tu:K |-> Map((_ (X:Id |-> T:KResult => .Map))) ...</preTypes>
		when notBool $hasMapping(Defs:Map, X:Id)
		[structural] 
		
	rule
		<k> (.K => resolveExternal(X:Id, Tu:K, Units:Bag, K:K)) ~> resolve(Tu:K) ...</k>
		<preLinkage>... Tu:K |-> Map((_ (X:Id |-> external => .Map))) ...</preLinkage>
		<externalDefinitions> ExtDefs:Map (X:Id |-> K:K => .Map) </externalDefinitions>
		<declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .List) _) ...</declarationOrder>
		<translationUnits> Units:Bag </translationUnits>
		when notBool $hasMapping(ExtDefs:Map, X:Id)
		[structural] 

	
	// fixme this means we've declared it twice (like a prototype maybe_), but already handled it.  happening with getc in clib.c
	rule
		<k> resolve(Tu:K) ...</k>
		<preLinkage>... Tu:K |-> Map(Linkage:Map) ...</preLinkage>
		<declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .) _) ...</declarationOrder>
		<externalDefinitions> ExtDefs:Map </externalDefinitions>
		<internalDefinitions> IntDefs:Map </internalDefinitions>
		when notBool $hasMapping(Linkage:Map, X:Id)
		andBool notBool $hasMapping(ExtDefs:Map, X:Id)
		andBool notBool $hasMapping(IntDefs:Map, X:Id)
		[structural] 
	
	// function prototypes
	rule
		<k> (.K => 
				giveType(X:Id, T:KResult)
				~> recordFunctionTranslationUnitInformation(X:Id, T:KResult, Tu:K, Tu:K)  // fixme fake Tu
			)
			~> resolve(Tu:K) 
		...</k>
		<currentTranslationUnit> _ => Tu:K </currentTranslationUnit>
		<preLinkage>... Tu:K |-> Map((_ (X:Id |-> external => .))) ...</preLinkage>
		<preTypes>... Tu:K |-> Map((_ X:Id |-> t(S:Set, prototype(T:KResult)))) ...</preTypes>
		<declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .) _) ...</declarationOrder>
		<externalDefinitions> Defs:Map </externalDefinitions>
		when isFunctionType(T:KResult)
		andBool notBool $hasMapping(Defs:Map, X:Id)
		[structural] 
		
	// c1x 6.9.2:2 A declaration of an identifier for an object that has file scope without an initializer, and without a storage-class specifier or with the storage-class specifier static, constitutes a tentative definition. If a translation unit contains one or more tentative definitions for an identifier, and the translation unit contains no external definition for that identifier, then the behavior is exactly as if the translation unit contains a file scope declaration of that identifier, with the composite type as of the end of the translation unit, with an initializer equal to 0
	rule
		<k> (. 
			=> allocateType(Loc:Nat, unqualifyType(T:KResult))
			~> addToEnv(X:Id, Loc:Nat)
			~> giveType(X:Id, unqualifyType(T:KResult))
			~> zero(X:Id)
			) ~> resolve(Tu:K)
		...</k>
		<preLinkage>... Tu:K |-> Map((_ (X:Id |-> external => .))) ...</preLinkage>
		<preTypes>... Tu:K |-> Map((_ X:Id |-> T:KResult)) ...</preTypes>
		<declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .) _) ...</declarationOrder>
		<externalDefinitions> Defs:Map </externalDefinitions>
		<currentTranslationUnit> _ => Tu:K </currentTranslationUnit>
		<nextSharedLoc> Loc:Nat => inc(Loc:Nat) </nextSharedLoc>
		<externalLocations> Locs:Map => Locs:Map[Loc:Nat / X:Id] </externalLocations>
		when notBool $hasMapping(Locs:Map, X:Id)
		andBool notBool isFunctionType(T:KResult)
		andBool notBool isIncompleteType(T:KResult)
		andBool notBool isExternType(T:KResult)
		andBool notBool $hasMapping(Defs:Map, X:Id)
		[structural] 
	syntax K ::= "leftover" "(" K "," K "," K ")" [klabel(leftover)]
	rule [resolve-extern-object-nomapping]:
		<k> resolve(Tu:K) ...</k>
		<preLinkage>... Tu:K |-> Map((_ (X:Id |-> external => .))) ...</preLinkage>
		<preTypes>... Tu:K |-> Map((_ X:Id |-> T:KResult)) ...</preTypes>
		<declarationOrder>... Tu:K |-> ListToK((ListItem(X:Id) => .) _) ...</declarationOrder>
		<externalDefinitions> Defs:Map </externalDefinitions>
		<leftoverExterns>... .Bag => BagItem(leftover(Tu:K, X:Id, T:KResult)) ...</leftoverExterns>
		when notBool isFunctionType(T:KResult)
		andBool isExternType(T:KResult)
		andBool notBool $hasMapping(Defs:Map, X:Id)
		[structural] 
		
	rule
		<k> resolve(Tu:K) => . ...</k>
		<preLinkage>... Tu:K |-> Map(.) ...</preLinkage>
		<internalDefinitions>... Tu:K |-> Map(.) ...</internalDefinitions>
		<declarationOrder>... Tu:K |-> ListToK(.List) ...</declarationOrder>
		[structural] 
				
	// need to worry about things that don't have definitions that may override externs
	// want to make it so env is always correct local env, so need to have a set of global envs, one for each tu
	
	
	
	
	rule [initialize-function]:
		<k> initFunction(tv(Loc:Nat, t(_, pointerType(T:KResult))), Fun:KResult) => .K ...</k>
		<functions> M:Map => M:Map[Fun:KResult / Loc:Nat] </functions>
		when isFunctionType(T:KResult)
		andBool notBool $hasMapping(M:Map, Loc:Nat)
		[structural]
		
	rule
		<k> readFunction(Loc:Nat) => Fun:KResult  ...</k>
		<functions>... Loc:Nat |-> Fun:KResult ...</functions>
		[structural]
	
	
end module

module COMMON-SEMANTICS-DECLARATIONS-ENUMS is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
	
	syntax K ::= "fillEnums" "(" K ")" [klabel(fillEnums)] 
	syntax K ::= "fillEnums-aux" "(" K "," K ")" [klabel(fillEnums-aux)] 
	rule
		<k> EnumDef(X:Id, L:K) => fillEnums(EnumDef(X:Id, L:K)) ...</k>
		[structural] 
	rule 
		<k> fillEnums(K:K) => fillEnums-aux(K:K, tv(0, t(.Set, int))) ...</k> 
		[structural]
	rule
		<k> fillEnums-aux(EnumDef(X:Id, List((EnumItem(E:Id),, L:List{K}))), K:K) 
			=> doDeclare(typedDeclaration(t(.Set, int), E:Id), SingleInit(K:K))
			~> fillEnums-aux(EnumDef(X:Id, List(L:List{K})), K:K + tv(1, t(.Set, int)))
		...</k>
		[structural] 
	rule
		<k> fillEnums-aux(EnumDef(X:Id, List((EnumItemInit(E:Id, Exp:K),, L:List{K}))), _)
			=> doDeclare(typedDeclaration(t(.Set, int), E:Id), SingleInit(Exp:K))
			~> fillEnums-aux(EnumDef(X:Id, List(L:List{K})), Exp:K + tv(1, t(.Set, int)))
		...</k>
		when Exp:K =/=K NothingExpression
		[structural] 
	rule
		<k> fillEnums-aux(EnumDef(X:Id, List(.List{K})), _) => .K ...</k> 
		[structural] 
end module

module COMMON-C-DECLARATIONS is
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE 
	
	including COMMON-SEMANTICS-DECLARATIONS-GENERAL 
	including COMMON-SEMANTICS-DECLARATIONS-FUNTION-BODY
	including COMMON-SEMANTICS-DECLARATIONS-INITIALIZATIONS 
	including COMMON-SEMANTICS-DECLARATIONS-ENUMS 
	including COMMON-SEMANTICS-DECLARATIONS-RESOLUTION 
end module
