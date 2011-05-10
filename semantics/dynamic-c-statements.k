kmod DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE is
	including COMMON-SEMANTICS-STATEMENTS-INCLUDE
	including DYNAMIC-INCLUDE

	op pushBlock : -> K 
	op addToHistory : Nat -> K
endkm 
 
kmod DYNAMIC-SEMANTICS-IF-THEN is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
		
	rule [if-then-else-true]:
		< k > IfThenElse(tv(1, int), S:K, ?) => sequencePoint ~> S:K ...</ k >
		[structural]
	rule [if-then-else-false]:
		< k > IfThenElse(tv(0, int), ?, S:K) => sequencePoint ~> S:K ...</ k >
		[structural]
	rule
		< k > IfThenElse((V:Value => simplifyTruth(V:Value)), ?, ?) ...</ k >
		if isNotTruthValue(V:Value)
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-WHILE is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	rule [while-mark]:
		< k > While(B:Expression, S:Statement) ~> K:K
			=> loopMarked ~> While(B:Expression, S:Statement) ~> popLoop
		</ k >
		< blockHistory > ListItem(Num:Nat) ...</ blockHistory >
		< loopStack > .List => ListItem(kpair(Num:Nat, K:K)) ...</ loopStack >
		[structural] 
	rule [while]:
		< k > loopMarked ~> While(B:Expression, S:Statement)
			=> IfThenElse(B:Expression, (S:Statement ~> loopMarked ~> While(B:Expression, S:Statement)), Nop)
		...</ k >
		[structural] 
endkm

kmod DYNAMIC-SEMANTICS-DO-WHILE is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	rule [do-while-mark]:
		< k > DoWhile(B:Expression, S:Statement) ~> K:K
			=> loopMarked ~> DoWhile(B:Expression, S:Statement) ~> popLoop
		</ k >
		< blockHistory > ListItem(Num:Nat) ...</ blockHistory >
		< loopStack > .List => ListItem(kpair(Num:Nat, K:K)) ...</ loopStack >
		[structural] 
	rule [do-while]:
		< k > loopMarked ~> DoWhile(B:Expression, S:Statement)
			=> S:Statement ~> IfThenElse(B:Expression, (loopMarked ~> DoWhile(B:Expression, S:Statement)), Nop)
		...</ k >
		[structural] 
endkm

kmod DYNAMIC-SEMANTICS-FOR is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	rule ForClauseDeclaration(K:K) => K:K [structural]
	rule ForClauseExpression(K:K) => Computation(K:K) [structural]
	
	rule
		< k > addToHistory(Num:Nat) => .K ...</ k >
		< blockHistory > . => ListItem(Num:Nat) ...</ blockHistory >
		//  < xmessages >... (. => "Adding " +String toString(Num:Nat) +String " to history") </ xmessages >
		[structural] 
	
	//  fixme should these blocks be here?
	//  fixme fishy interaction with continue i think
	rule [for-mark]:
		< k > (For(ForNum:Nat, Pre:K, Control:K, Post:K, S:Statement) ~> K:K
			=> pushBlock ~> addToHistory(ForNum:Nat) ~> Pre:K ~> loopMarked ~> For(ForNum:Nat, Pre:K, (if Control:K =/=Bool emptyValue then Control:K else tv(1, int) fi), Post:K, S:Statement) ~> popLoop)
		</ k >
		< blockHistory > ListItem(Num:Nat) ...</ blockHistory >
		< loopStack > . => ListItem(kpair(Num:Nat, K:K)) ...</ loopStack >
		//  < freshNat > Fresh:Nat => sNat(Fresh:Nat) </ freshNat >
		//  < xmessages >... (. => "For: loop in " +String toString(Num:Nat) +String ", creating " +String toString(ForNum:Nat)) </ xmessages >
		[structural] 
		
	rule [for]:
		< k > loopMarked ~> For(ForNum:Nat, Pre:K, Control:K, Post:K, S:Statement)
			=> IfThenElse(Control:K, (S:Statement ~> Computation(Post:K) ~> loopMarked ~> For(ForNum:Nat, Pre:K, Control:K, Post:K, S:Statement)), Nop)
		...</ k >
		< blockHistory > ListItem(Num:Nat) ...</ blockHistory >
		//  < xmessages >... (. => "For: finished a loop, in " +String toString(Num:Nat) +String ", looping...") </ xmessages >
		[structural] 
endkm

kmod DYNAMIC-SEMANTICS-SWITCH is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	//  fixme shouldn't there be sequence points here?
	//  fixme not doing promoting or conversion
	
	op handleSwitch : Nat K -> K [metadata "strict(2)"] //  switch num, promoted value of controlling exp, int value of exp
	op handleSwitch-aux : K Value K -> K 
	
	rule
		< k > Switch(SN:Nat, tv(V:BaseValue, T:Type), ?) 
			=> sequencePoint 
			~> handleSwitch(SN:Nat, cast(promote(T:Type), tv(V:BaseValue, T:Type))) 
		...</ k >
		if hasIntegerType(T:Type)
		[structural] 
		
	rule
		< k > handleSwitch(SN:Nat, V:Value) => handleSwitch-aux(SN:Nat, V:Value, Map(M:Map)) ...</ k >
		< currentFunction > F:Id </ currentFunction >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		< gotoMap >... kpair(Tu:K, F:Id) |-> Map(M:Map) ...</ gotoMap >
		[structural] 
		
	//  fixme feature can't do this :(
	//  mb context handleSwitch-aux(?, ?, ?, Map((? (genLabel(?, `[HOLE`]:K) |-> ?)))) 
	//  mb context handleSwitch-aux(`[HOLE`]:K, ?, ?, ?) 
	
	//  match found in value and type, goto it
	//  don't need to erase the rest of K since we're GOTOing
	rule
		< k > tryCase(V:Value, V:Value, CaseHelper:K) => Goto(CaseHelper:K) ...</ k >
		[structural] 
		
	op tryCase : K Value K -> K //  K to be evaluated, val it should be, casehelper
	context tryCase(([HOLE] => reval([HOLE])), _, _)
	rule
		< k > (. => tryCase(Exp:K, V:Value, CaseHelper:K)) ~> handleSwitch-aux(SN:Nat, V:Value, Map((? ((genLabel(SN:Nat, Exp:K) |-> CaseHelper:K) => .))))
		...</ k >
		if Exp:K =/=Bool l('Default)
		[structural] 
		
	//  if all that's left is a default, do it
	rule
		< k > handleSwitch-aux(SN:Nat, ?, Map((genLabel(SN:Nat, l('Default)) |-> ?))) 
			=> Goto(genLabel(SN:Nat, l('Default)))
		...</ k >
		[structural] 
	
	//  if there's nothing left, no case matches
	rule
		< k > handleSwitch-aux(?, ?, Map(.Map)) => .K ...</ k >
		[structural] 

	rule
		< k > tryCase(tv(V':BaseValue, T:Type), tv(V:BaseValue, T:Type), CaseHelper:K) => .K ...</ k >
		if V:BaseValue =/=Bool V':BaseValue
		[structural] 
		
	rule
		< k > handleSwitch-aux(SN:Nat, ?, Map((? ((genLabel(SN':Nat, ?) |-> ?) => .Map)))) ...</ k >
		if SN:Nat =/=Bool SN':Nat
		[structural] 
	rule
		< k > handleSwitch-aux(SN:Nat, ?, Map((? ((L:KLabel(?) |-> ?) => .Map)))) ...</ k >
		if L:KLabel =/=Bool 'genLabel
		[structural] 
			
	rule
		< k > tryCase((tv(V:BaseValue, T':Type) => cast(T:Type, tv(V:BaseValue, T':Type))), tv(?, T:Type), ?) ...</ k >
		if T:Type =/=Bool T':Type
		[structural] 
	
	rule [case-fall-through]:
		< k > Case(?, ?, ?, K:K) => K:K ...</ k >
		[structural] 
	rule [default-fall-through]:
		< k > Default(?, K:K) => K:K ...</ k >
		[structural] 
endkm

kmod DYNAMIC-SEMANTICS-GOTO is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	//  fixme CONFIRM It seems there are no sequence points for a goto
	
//  c1x 6.2.4:6 For such an object that does not have a variable length array type, its lifetime extends from entry into the block with which it is associated until execution of that block ends in any way. (Entering an enclosed block or calling a function suspends, but does not end, execution of the current block.) If the block is entered recursively, a new instance of the object is created each time. The initial value of the object is indeterminate. If an initialization is specified for the object, it is performed each time the declaration or compound literal is reached in the execution of the block; otherwise, the value becomes indeterminate each time the declaration is reached
		
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

	/* 
		To do the actual goto:
			- Case 1: We are in the same block as the target
				1. We might be jumping forwards or backwards, across declarations, so we need to figure out which variables should be left alone, allocated but not initialized, or deallocated
					a. Skip any entries in the frozen declarationStack where the nestingDepth is smaller than our current nestingDepth
					b. All that remains should be variables in the same block as the target
					c. As we step through the variables in the frozen declarationStack
						i. any variables we see that we have already declared stay allocated and keep their old value
						ii. any variables that are in the declarationStack but have not been declared are variables we must allocate but not initialize
						iii. any variables that have been declared but are not in the declarationStack need to be deallocated
			- Case 2: We are in a different block than the target
				1. We need to unwind blocks from the blockstack until we're in at nestingDepth 1 less than the nesting depth of the target
					a. for each block we pop, we need to unallocate the memory
					b. once we're at the right place, we enter the block and then proceed similarly to case 1, except all the cases will be to allocate and not initialize
		
		The variables mentioned above are meant to be those with automatic storage duration.  Variables with external or static storage duration have their own rules
				
	*/

	op processGoto : K -> K 
	op processGotoDown : K -> K 

	op processGotoSameBlock : List List -> K //  declaration stack, actual local variables
	rule
		< k > Goto(Label:K) ~> ? => processGoto(GotoInfo:K) </ k >
		< currentFunction > F:Id </ currentFunction >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		< gotoMap >... kpair(Tu:K, F:Id) |-> Map((? (Label:K |-> GotoInfo:K))) ...</ gotoMap >
		[structural] 
		
	// - first case, when we're in the same block
	rule
		< k > L:KLabel(gotoObject(Depth:Nat, (ListItem(CurrentBlock:Nat) BlockHistory:List), K:K, LoopStack:List, DeclStack:List)) ~> ? 
			=> addVariablesForBlock(CurrentBlock:Nat, DeclStack:List)
			~> K:K
		</ k >
		< nestingDepth > Depth:Nat </ nestingDepth >
		< blockHistory > ListItem(CurrentBlock:Nat) BlockHistory:List </ blockHistory >
		< loopStack > ? => LoopStack:List </ loopStack >
		< localVariables > Vars:List </ localVariables >
		//  < xmessages >... (. => "Gotoing: in same block " +String toString(CurrentBlock:Nat)) </ xmessages >
		if L:KLabel ==Bool 'processGoto
		orBool L:KLabel ==Bool 'processGotoDown
		[structural] 
		
	// - second case, we're in a different block
	
	//  as long as there are entries in the actual block history that differ from the target block history, we need to pop
	rule
		< k > (. => popBlock) 
			~> processGoto(gotoObject(TargetDepth:Nat, TargetBlockHistory:List, ?, ?, ?))
		...</ k >
		< blockHistory > ListItem(BlockNum:Nat) ActualHistory:List </ blockHistory >
		//  < xmessages >... (. => "Gotoing: popping to find common history, " +String toString(BlockNum:Nat)) </ xmessages >
		if notBool BlockNum:Nat in TargetBlockHistory:List
		[structural] 
		
	//  same
	rule
		< k > (. => popBlock) 
			~> processGoto(gotoObject(TargetDepth:Nat, Prefix:List ListItem(BlockNum:Nat) TargetBlockHistory:List, ?, ?, ?))
		...</ k >
		< blockHistory > ListItem(BlockNum:Nat) ActualHistory:List </ blockHistory >
		//  < xmessages >... (. => "Gotoing: popping to find common history, " +String toString(BlockNum:Nat)) </ xmessages >
		if TargetBlockHistory:List =/=Bool ActualHistory:List
		[structural] 
			
	//  once we share a history, we start to push
	rule
		< k > processGoto(gotoObject(TargetDepth:Nat, (Prefix:List ListItem(TargetBlock:Nat) ActualHistory:List), K:K, LoopStack:List, DeclStack:List))
			=> addVariablesForBlock(CurrentBlock:Nat, DeclStack:List)
			~> processGotoDown(gotoObject(TargetDepth:Nat, (Prefix:List ListItem(CurrentBlock:Nat) ActualHistory:List), K:K, LoopStack:List, DeclStack:List))
		...</ k >
		< nestingDepth > ActualDepth:Nat </ nestingDepth >
		< blockHistory > ListItem(CurrentBlock:Nat) ActualHistory:List </ blockHistory >
		//  < xmessages >... (. => "Gotoing: Have common history, handling " +String toString(CurrentBlock:Nat)) </ xmessages >
		if sNat(ActualDepth:Nat) =/=Bool TargetDepth:Nat
		[structural] 
		
	rule
		< k > ( . 
				=> pushBlock
				~> addToHistory(TargetBlock:Nat)
				~> addVariablesForBlock(TargetBlock:Nat, DeclStack:List)
			)
			~> processGotoDown(gotoObject(TargetDepth:Nat, (? ListItem(TargetBlock:Nat) ActualHistory:List), ?, ?, DeclStack:List))
		...</ k >
		< nestingDepth > ActualDepth:Nat </ nestingDepth >
		< blockHistory > ActualHistory:List </ blockHistory > //  (. => ListItem(TargetBlock:Nat)) 
		//  < xmessages >... (. => "Gotoing: Have common history, pushing " +String toString(TargetBlock:Nat)) </ xmessages >
		if sNat(ActualDepth:Nat) =/=Bool TargetDepth:Nat
		[structural] 
	
	//  We've made it to the block above the target
	rule
		< k > L:KLabel(gotoObject(sNat(Depth:Nat), 
				(ListItem(TargetBlock:Nat) BlockHistory:List),
				K:K, 
				LoopStack:List, 
				DeclStack:List)
			) ~> ?
			=> pushBlock
			~> addToHistory(TargetBlock:Nat)
			~> addVariablesForBlock(TargetBlock:Nat, DeclStack:List)
			~> K:K
		</ k >
		< nestingDepth > Depth:Nat </ nestingDepth >
		< blockHistory > BlockHistory:List </ blockHistory >
		< loopStack > ? => LoopStack:List </ loopStack >
		//  < xmessages >... (. => "Gotoing: above target, pushing " +String toString(TargetBlock:Nat)) </ xmessages >
		if L:KLabel ==Bool 'processGoto
		orBool L:KLabel ==Bool 'processGotoDown
		[structural] 
		
	op addVariablesForBlock : Nat List -> K 
	
	//  skip variables from other blocks
	rule
		< k > addVariablesForBlock(TargetBlock:Nat, 
				((ListItem(frozenDeclaration(?, BlockNum:Nat, ?)) => .) DeclStack:List)
			)
		...</ k >
		< blockHistory > ListItem(TargetBlock:Nat) ...</ blockHistory >
		if BlockNum:Nat =/=Bool TargetBlock:Nat
		[structural] 
		
	//  fixme computational to let transforms finish		
	//  skip variables in the real history
	rule
		< k > addVariablesForBlock(TargetBlock:Nat,
				((ListItem(frozenDeclaration(?, TargetBlock:Nat, Decl:K)) => .) DeclStack:List)
			)
		...</ k >
		< localVariables > Vars:List </ localVariables >
		< blockHistory > ListItem(TargetBlock:Nat) ...</ blockHistory >
		//  < xmessages >... (. => "Goto: skipping variable declaration " +String getIdString(getIdOfDeclaration(Decl:K))) </ xmessages >
		if getIdOfDeclaration(Decl:K) in Vars:List
		[structural]
		
	op getIdString : K -> String 
	rule getIdString(Identifier(S:String)) => S:String [structural]
	
	op enableInits : -> K 
	
	rule
		< k > enableInits => .K ...</ k >
		< shouldInit > ? => true </ shouldInit >
		[structural] 
	
	rule
		< k > (. => Decl:K ~> enableInits) ~> addVariablesForBlock(TargetBlock:Nat, 
				((ListItem(frozenDeclaration(?, TargetBlock:Nat, Decl:K)) => .List) ?)
			)
		...</ k >
		< localVariables > Vars:List </ localVariables >
		< blockHistory > ListItem(TargetBlock:Nat) ...</ blockHistory >
		< shouldInit > ? => false </ shouldInit >
		//  < xmessages >... (. => "Goto: couldn't find variable " +String getIdString(getIdOfDeclaration(Decl:K))) </ xmessages >
		if notBool getIdOfDeclaration(Decl:K) in Vars:List
		[structural]
		
	//  fixme this is wrong
	rule
		< k > addVariablesForBlock(?, .List) => .K ...</ k >
		[structural] 

endkm

kmod DYNAMIC-SEMANTICS-RETURN is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 

	rule [return-clean-local]:
		< k > (. => deleteBlock(Loc:Nat)) ~> Return(V:Value) ...</ k >
		< localAddresses >... SetItem(Loc:Nat) => .Set ...</ localAddresses >	
		[structural] 
		
	rule [fetch-all-locals]:
		< k > Return(V:Value) ...</ k >
		< localAddresses > .Set => Addresses:Set </ localAddresses >
		< blockStack > ListItem(< stackFrame > 
			?
			< localAddresses > Addresses:Set </ localAddresses >
			</ stackFrame >)
			=> .List
		...</ blockStack >
		[structural] 

	//  this is used for returns with no return value as well, since we return "emptyValue", which will hopefully be cast to void
	rule [return]: 
		< control >
			< k > Return(V:Value) ~> ? 
				=> sequencePoint 
				~> cast(T:Type, V:Value) 
				~> K:K
			</ k >
			//  these cells get replaced by the ones in C:Bag, so we can delete them when we match them
			(< local >... < localAddresses > .Set </ localAddresses > ...</ local > => .Bag)
			//  i can't say the below line alone, but i want to :(
			//  (< localAddresses > .Set </ localAddresses > => .Bag)
			< currentFunction > (F:Id => CurrFun:K) </ currentFunction >
			< currentProgramLoc > ? => CurrLoc:K </ currentProgramLoc >
			(< currentTranslationUnit > Tu:K </ currentTranslationUnit > => .Bag)
			(< blockStack > .List </ blockStack > => .Bag)
			(? => C:Bag)
		</ control >
		< gtypes >... Tu:K |-> Map((? (F:Id |-> functionType(T:Type, ?)))) ...</ gtypes >
		< callStack >
			ListItem(
				< stackFrame >
					C:Bag
					< continuation > K:K </ continuation >
					< stackCurrentFunction > CurrFun:K </ stackCurrentFunction >
					< stackCurrentProgramLoc > CurrLoc:K </ stackCurrentProgramLoc >
				</ stackFrame >
			) => .List
		...</ callStack >
		[structural] 
endkm

kmod DYNAMIC-SEMANTICS-BLOCKS is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	rule 
		< k > BlockStatement(Block:K)
			=> pushBlock ~> Block:K ~> popBlock
		...</ k >
		[structural] 
	
	rule [push-block]:
		< k > pushBlock => .K ...</ k >
		< local >
			C:Bag
			< localVariables > Vars:List => .List </ localVariables >
			< localAddresses > Addresses:Set => .Set </ localAddresses >
			< nestingDepth > N:Nat => sNat(N:Nat) </ nestingDepth >
		</ local >
		< blockStack > .List 
			=> ListItem(< stackFrame > C:Bag 
			< nestingDepth > N:Nat </ nestingDepth > 
			< localVariables > Vars:List </ localVariables >
			< localAddresses > Addresses:Set </ localAddresses >
			</ stackFrame >)
		...</ blockStack >
		[structural] 
		
	rule [pop-block-free-memory]:
		< k > (. => deleteBlock(Loc:Nat)) ~> popBlock ...</ k >
		< localAddresses >... (SetItem(Loc:Nat) => .Set) ...</ localAddresses >
		[structural] 
		
	//  this can be simplified without the debugging info
	rule [pop-block]:
		< k > popBlock => .K ...</ k >
		< local > 
			(? => C:Bag)
			(< blockHistory > ListItem(Num:Nat) ...</ blockHistory > => (< blockHistory > ListItem(NewNum:Nat) L:List </ blockHistory >)) /* .Bag */
			(< localAddresses > .Set </ localAddresses > => .Bag)
		</ local >
		//  < xmessages >... (. => "Popblock: popping " +String toString(Num:Nat) +String " to return to " +String toString(NewNum:Nat)) </ xmessages >
		< blockStack > ListItem(< stackFrame > C:Bag < blockHistory > ListItem(NewNum:Nat) L:List </ blockHistory > </ stackFrame >) => .List ...</ blockStack >
		[structural] 
	
	
	rule [dissolve-block]:
		< k > Block(BlockNum:Nat, ?, Statements:List{C}) => listToK(Statements:List{C}) ...</ k >
		< blockHistory > .List => ListItem(BlockNum:Nat) ...</ blockHistory >
		//  < xmessages >... (. => "Real block: pushing " +String toString(BlockNum:Nat)) </ xmessages >
		[structural] 
endkm

kmod DYNAMIC-C-STATEMENTS is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	including DYNAMIC-SEMANTICS-IF-THEN 
	including DYNAMIC-SEMANTICS-FOR 
	including DYNAMIC-SEMANTICS-WHILE 
	including DYNAMIC-SEMANTICS-SWITCH 
	including DYNAMIC-SEMANTICS-GOTO 
	including DYNAMIC-SEMANTICS-RETURN 
	including DYNAMIC-SEMANTICS-BLOCKS 
	including DYNAMIC-SEMANTICS-DO-WHILE 
	
	//  dissolve expression statements that are finished evaluating
	rule [expression-statement]:
		< k > Computation(V:Value) => sequencePoint ...</ k > 
		[structural] 
	
	rule [popLoop]:
		< k > popLoop ~> ? => K:K </ k >
		< blockHistory > ListItem(Num:Nat) ...</ blockHistory >
		< loopStack > ListItem(kpair(Num:Nat, K:K)) => .List ...</ loopStack >
		//  < xmessages >... (. => "Poplooping in " +String toString(Num:Nat)) </ xmessages >
		[structural] 

	rule [popLoop-popBlock]:
		< k > (. => popBlock) ~> popLoop ...</ k >
		< blockHistory > ListItem(Num:Nat) ...</ blockHistory >
		< loopStack > ListItem(kpair(Num':Nat, ?)) ...</ loopStack >
		//  < xmessages >... (. => "Adding a popBlock to get rid of " +String toString(Num:Nat) +String ".  Looking for " +String toString(Num':Nat)) </ xmessages >
		if Num':Nat =/=Bool Num:Nat
		[structural] 
	
	rule [break]:
		< k > Break => popLoop ...</ k >
		//  < xmessages >... (. => "Break encountered, turning into popLoop") </ xmessages >
		[structural] 

	rule [continue]:
		< k > Continue ~> ((L:KLabel)(?) => .) ...</ k >
		if L:KLabel =/=Bool 'loopMarked
		andBool L:KLabel =/=Bool 'popBlock
		andBool L:KLabel =/=Bool 'pushBlock
		andBool L:KLabel =/=Bool 'popLoop
		[structural] //  nondet
	rule [continue-through-pop]:
		< k > Continue ~> popBlock 
			=> popBlock
			~> Continue
		...</ k >
		[structural] //  nondet

	rule [continue-done-for]:
		< k > (Continue => Computation(Post:K)) ~> loopMarked ~> For(?, ?, ?, Post:K, ?) ...</ k >
		[structural] //  nondet
	rule [continue-done]:
		< k > (Continue => .) ~> loopMarked ~> L:KLabel(?) ...</ k >
		if L:KLabel =/=Bool 'For
		[structural] //  nondet		
endkm
