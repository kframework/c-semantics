kmod COMMON-SEMANTICS-STATEMENTS-INCLUDE is
	including COMMON-INCLUDE 
	
	op loopMarked : -> Statement 
	op genLabel : Nat K -> K //  switchid, value (tv or 'Default)
	op popLoop : -> K
	op popBlock : -> K
	op frozenDeclaration : Nat Nat K -> K //  nestingDepth, currentBlock, decl
	op gotoObject : Nat List K List List -> K //  nestingDepth, block history, continuation, loop stack, decl stack
	
	
	op caseHelper : Nat -> K 
endkm 


kmod COMMON-SEMANTICS-PROCESS-LABELS is
	including COMMON-SEMANTICS-STATEMENTS-INCLUDE 
/*
	things I have to keep track of:
		in goto map:
			remaining computation
			which variables are allocated on the path
			...
		in blocks:
			which variables i've allocated so far
	
	I need to adjust the block stack, 
		
	When we goto, we need to take the variables on the goto path and subtract the variables we've already allocated in the real history.  Then we need to declare the remaining variables
		
*/
	
	op waitingOnGotoMap : -> K 
	rule 
		< k > calculateGotoMap(F:Id, K:K) => waitingOnGotoMap ...</ k >
		< gotoMap > M:Map => M:Map[Map(.Map) / kpair(Tu:K, F:Id)] </ gotoMap >
		< currentFunction > ? => F:Id </ currentFunction >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		< calculateGotoMap >
			. => (< gotoCalculation >... < computation > K:K ~> Return(NothingExpression) </ computation > ...</ gotoCalculation >)
		</ calculateGotoMap >
		[structural] 
		
	rule
		(< gotoCalculation > < computation > .K </ computation > ...</ gotoCalculation >) => .Bag
		[structural] 


	rule
		< k > waitingOnGotoMap => .K ...</ k >
		< calculateGotoMap > .Bag </ calculateGotoMap >
		< currentFunction > ? => File-Scope </ currentFunction >
		[structural] 

	op endBlockForGoto : Nat -> K 
	rule 
		< computation > BlockStatement(Block:K)
			=> Block:K ~> popBlock
		...</ computation >
		< nestingDepthGoto > N:Nat => sNat(N:Nat) </ nestingDepthGoto >
		< blockHistoryGoto > ListItem(OldNum:Nat) ...</ blockHistoryGoto >
		[structural] 
	rule
		< computation > Block(Num:Nat, ?, L:List{C}) => listToK(L:List{C}) ...</ computation > 
		< blockHistoryGoto > . => ListItem(Num:Nat) ...</ blockHistoryGoto >
		//  < declarationStack >... .List => ListItem(.K) </ declarationStack >
		[structural] 
		
	rule
		< computation > popBlock => .K ...</ computation >
		< nestingDepthGoto > sNat(N:Nat) => N:Nat </ nestingDepthGoto >
		< blockHistoryGoto > (?:ListItem => .List) ListItem(Num:Nat) ...</ blockHistoryGoto >
		[structural] 
		
	// rule [StatementLoc-computation]:
		// < computation > StatementLoc(K:K, L:CabsLoc) => K:K ...</ computation >
		// < currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		// [structural] 
	// rule [StatementLoc-computation]:
		// < computation > StatementLoc(K:K, CabsLoc(S:String, N:Nat, N':Nat, N'':Nat)) => K:K ...</ computation >
		// < currentProgramLoc > ? => CabsLoc(S:String, N:Nat, N':Nat, N'':Nat) </ currentProgramLoc >
		// if N:Nat =/=Bool 268
		// [structural] 

	// - fixme i hate that i have to do this twice.  once here, once in the dynamic semantics
	// rule
		// < computation > LocalDefinition(CodeLoc(K:K, Loc:K)) => CodeLoc(K:K, Loc:K) ...</ computation >
		// [structural] 
	// rule [DefinitionLoc-computation]:
		// < computation > DefinitionLoc(K:K, L:CabsLoc) => K:K ...</ computation >
		// < currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		// [structural] 
	rule [DefinitionLoc-computation]:
		< computation > CodeLoc(K:K, L:CabsLoc) => K:K ...</ computation >
		< currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		[structural] 
	// rule [DefinitionLoc-computation]:
		// < computation > DefinitionLoc(K:K, CabsLoc(S:String, N:Nat, N':Nat, N'':Nat)) => K:K ...</ computation >
		// < currentProgramLoc > ? => CabsLoc(S:String, N:Nat, N':Nat, N'':Nat) </ currentProgramLoc >
		// if N:Nat =/=Bool 268
		// [structural]
		
	//  eq getIdOfDeclaration(DeclarationDefinition(InitNameGroup(?, K:C))) = getIdOfName(K:C) 
		
	rule
		< computation > DeclarationDefinition(InitNameGroup(T:K, (K:C :: K':C :: L:List{C}))) 
			=> DeclarationDefinition(InitNameGroup(T:K, K:C))
			~> DeclarationDefinition(InitNameGroup(T:K, K':C :: L:List{C})) 
		...</ computation >
		[structural] 
	rule
		< computation > Typedef(NameGroup(T:K, (K:C :: K':C :: L:List{C}))) 
			=> Typedef(NameGroup(T:K, K:C))
			~> Typedef(NameGroup(T:K, K':C :: L:List{C})) 
		...</ computation >
		[structural] 
	rule
		< computation > Typedef(NameGroup(T:K, (K:C :: K':C :: L:List{C}))) 
			=> Typedef(NameGroup(T:K, K:C))
			~> Typedef(NameGroup(T:K, K':C :: L:List{C})) 
		...</ computation >
		[structural] 
		
	//  fixme would like to combine the below rules
	rule
		< computation > DeclarationDefinition(InitNameGroup(T:K, K:C)) => .K ...</ computation >
		< declarationStack >... .List => ListItem(frozenDeclaration(Depth:Nat, BlockNum:Nat, DeclarationDefinition(InitNameGroup(T:K, K:C)))) </ declarationStack >
		< nestingDepthGoto > Depth:Nat </ nestingDepthGoto >
		< blockHistoryGoto > ListItem(BlockNum:Nat) ...</ blockHistoryGoto >
		[structural] 
		
	rule
		< computation > OnlyTypedef(K:K) => .K ...</ computation >
		< declarationStack >... .List => ListItem(frozenDeclaration(Depth:Nat, BlockNum:Nat, OnlyTypedef(K:K))) </ declarationStack >
		< nestingDepthGoto > Depth:Nat </ nestingDepthGoto >
		< blockHistoryGoto > ListItem(BlockNum:Nat) ...</ blockHistoryGoto >
		[structural] 
		
	rule
		< computation > Typedef(K:K) => .K ...</ computation >
		< declarationStack >... .List => ListItem(frozenDeclaration(Depth:Nat, BlockNum:Nat, Typedef(K:K))) </ declarationStack >
		< nestingDepthGoto > Depth:Nat </ nestingDepthGoto >
		< blockHistoryGoto > ListItem(BlockNum:Nat) ...</ blockHistoryGoto >
		[structural] 
		
	rule 
		< computation > L:KLabel(Args:List{K}) => .K ...</ computation >
		if false
		orBool L:KLabel ==Bool 'Nop
		orBool L:KLabel ==Bool 'Computation
		orBool L:KLabel ==Bool 'Break
		orBool L:KLabel ==Bool 'Continue
		orBool L:KLabel ==Bool 'Return
		orBool L:KLabel ==Bool 'Goto
		orBool L:KLabel ==Bool 'CompGoto
		[structural] 
		
	// - should do this with a split
	rule
		< gotoCalculation >
			< computation > (For(ForNum:Nat, Pre:K, Control:K, Post:K, S:K) => .K) ~> K:K </ computation >
			< computationTail > Tail:K </ computationTail >
			B:Bag
			< nestingDepthGoto > N:Nat </ nestingDepthGoto >
			< blockHistoryGoto > ListItem(Num:Nat) OldBlockHistory:List </ blockHistoryGoto >
			< loopStackGoto > OldLoopStack:List </ loopStackGoto >
		</ gotoCalculation >
		(. =>
			< gotoCalculation > 
				< computation > S:K </ computation > 
				< computationTail >
					Computation(Post:K)
					~> loopMarked
					~> For(ForNum:Nat, Pre:K, (if Control:K =/=Bool emptyValue then Control:K else tv(1, int) fi), Post:K, S:K)
					~> popLoop
					~> K:K 
					~> Tail:K 
				</ computationTail >
				B:Bag
				< nestingDepthGoto > sNat(N:Nat) </ nestingDepthGoto >
				< blockHistoryGoto > ListItem(ForNum:Nat) ListItem(Num:Nat) OldBlockHistory:List </ blockHistoryGoto >
				< loopStackGoto > ListItem(kpair(Num:Nat, (K:K ~> Tail:K))) OldLoopStack:List </ loopStackGoto >
			</ gotoCalculation >
		)
		[structural] 
		
	rule
		< gotoCalculation >
			< computation > (DoWhile(E:K, S:K) => .K) ~> K:K </ computation >
			< computationTail > Tail:K </ computationTail >
			B:Bag
			< blockHistoryGoto > ListItem(Num:Nat) OldBlockHistory:List </ blockHistoryGoto >
			< loopStackGoto > OldLoopStack:List </ loopStackGoto >
		</ gotoCalculation >
		(. =>
			< gotoCalculation > 
				< computation > S:K </ computation >
				< computationTail >
					IfThenElse(E:K, (loopMarked ~> DoWhile(E:K, S:K)), Nop)
					~> popLoop
					~> K:K 
					~> Tail:K 
				</ computationTail >
				B:Bag
				< blockHistoryGoto > ListItem(Num:Nat) OldBlockHistory:List </ blockHistoryGoto >
				< loopStackGoto > ListItem(kpair(Num:Nat, (K:K ~> Tail:K))) OldLoopStack:List </ loopStackGoto >
			</ gotoCalculation >
		)
		[structural]
		
	rule
		< computation > (. => S:K ~> loopMarked) ~> While(E:K, S:K) ~> (. => popLoop) ~> K:K </ computation >
		< computationTail > Tail:K </ computationTail >
		< blockHistoryGoto > ListItem(Num:Nat) ...</ blockHistoryGoto >
		< loopStackGoto > (. => ListItem(kpair(Num:Nat, (K:K ~> Tail:K)))) ...</ loopStackGoto >
		[structural] 
	rule
		< computation > (loopMarked ~> While(E:K, S:K) => .K) ~> popLoop ~> K:K </ computation >
		[structural] 
		
	rule
		< gotoCalculation >
			< computation > (IfThenElse(?, S1:K, S2:K) => .K) ~> K:K </ computation >
			< computationTail > Tail:K </ computationTail >
			B:Bag
		</ gotoCalculation >
		(. =>
			< gotoCalculation > 
				< computation > S1:K </ computation > 
				< computationTail > K:K ~> Tail:K </ computationTail >
				B:Bag 
			</ gotoCalculation >
		)
		(. =>
			< gotoCalculation > 
				< computation > S2:K </ computation >
				< computationTail > K:K ~> Tail:K </ computationTail >
				B:Bag 
			</ gotoCalculation >
		)
		[structural] 
		
	rule
		< computation > (Switch(?, E:K, S:K) => S:K ~> popLoop) ~> K:K </ computation >
		< computationTail > Tail:K </ computationTail >
		< blockHistoryGoto > ListItem(Num:Nat) ...</ blockHistoryGoto >
		< loopStackGoto > (. => ListItem(kpair(Num:Nat, (K:K ~> Tail:K)))) ...</ loopStackGoto >
		[structural] 
		
	rule
		< computation > popLoop => .K ...</ computation >
		< loopStackGoto > (?:ListItem => .) ...</ loopStackGoto >
		[structural] 
		
	rule
		< computation > (Label(Target:Id, S:K) => S:K) ~> K:K </ computation >
		< computationTail > Tail:K </ computationTail >
		< loopStackGoto > LoopStack:List </ loopStackGoto >
		< declarationStack > DeclStack:List </ declarationStack >
		< gotoMap >... kpair(Tu:K, F:Id) |-> Map((M:Map => M:Map[gotoObject(Depth:Nat, BlockHistory:List, (S:K ~> K:K ~> Tail:K), LoopStack:List, DeclStack:List) / Target:Id])) ...</ gotoMap >
		< currentFunction > F:Id </ currentFunction >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		< nestingDepthGoto > Depth:Nat </ nestingDepthGoto >
		< blockHistoryGoto > BlockHistory:List </ blockHistoryGoto >
		if notBool $hasMapping(M:Map, Target:Id)
		[structural]
		
	rule
		< computation > (Case(SwitchNum:Nat, CaseNum:Nat, Val:K, S:K) => S:K) ~> K:K </ computation >
		< computationTail > Tail:K </ computationTail >
		< loopStackGoto > LoopStack:List </ loopStackGoto >
		< declarationStack > DeclStack:List </ declarationStack >
		//  < freshNat > Fresh:Nat => sNat(Fresh:Nat) </ freshNat >
		< gotoMap >... kpair(Tu:K, F:Id) |-> Map(
			(M:Map => (M:Map[caseHelper(CaseNum:Nat) / genLabel(SwitchNum:Nat, Val:K)])[gotoObject(Depth:Nat, BlockHistory:List, (S:K ~> K:K ~> Tail:K), LoopStack:List, DeclStack:List) / caseHelper(CaseNum:Nat)])
		) ...</ gotoMap >
		< currentFunction > F:Id </ currentFunction >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		< nestingDepthGoto > Depth:Nat </ nestingDepthGoto >
		< blockHistoryGoto > BlockHistory:List </ blockHistoryGoto >
		if notBool $hasMapping(M:Map, genLabel(SwitchNum:Nat, Val:K))
		//  andBool hasIntegerType(T:Type)
		[structural] 
	rule
		< computation > (Default(SwitchNum:Nat, S:K) => S:K) ~> K:K </ computation >
		< computationTail > Tail:K </ computationTail >
		< loopStackGoto > LoopStack:List </ loopStackGoto >
		< declarationStack > DeclStack:List </ declarationStack >
		//  < freshNat > Fresh:Nat => sNat(Fresh:Nat) </ freshNat >
		< gotoMap >... kpair(Tu:K, F:Id) |-> Map((M:Map => M:Map[gotoObject(Depth:Nat, BlockHistory:List, (S:K ~> K:K ~> Tail:K), LoopStack:List, DeclStack:List) / genLabel(SwitchNum:Nat, l('Default))])) ...</ gotoMap >
		< currentFunction > F:Id </ currentFunction >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		< nestingDepthGoto > Depth:Nat </ nestingDepthGoto >
		< blockHistoryGoto > BlockHistory:List </ blockHistoryGoto >
		if notBool $hasMapping(M:Map, genLabel(SwitchNum:Nat, l('Default)))
		[structural]
endkm
 
kmod COMMON-C-STATEMENTS is
	including COMMON-SEMANTICS-STATEMENTS-INCLUDE 
	including COMMON-SEMANTICS-PROCESS-LABELS
	
	rule Nop => .K
		[structural] 

	/*@ \source[n1570]{\para{6.8.1}{4}}
	Any statement may be preceded by a prefix that declares an identifier as a label name. Labels in themselves do not alter the flow of control, which continues unimpeded across them.
	*/
	rule [skip-label]: < k > Label(L:Id, K:K) => K:K ...</ k >
		[structural] 	
endkm
