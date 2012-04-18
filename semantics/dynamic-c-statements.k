kmod DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE is
	including COMMON-SEMANTICS-STATEMENTS-INCLUDE
	including DYNAMIC-INCLUDE

	op pushBlock : -> K 
	op addToHistory : #Nat -> K
endkm 
 
kmod DYNAMIC-SEMANTICS-IF-THEN is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
		
	/*@ \source[n1570]{\para{6.8}{4}}
	\ldots There is a sequence point between the evaluation of a full expression and the evaluation of the next full expression to be evaluated.
	*/
		
	/*@ \source[n1570]{\para{6.4.4.4}{10}}
	In both forms, the first substatement is executed if the expression compares unequal to 0. In the \cinline{else} form, the second substatement is executed if the expression compares equal to 0. If the first substatement is reached via a label, the second substatement is not executed.
	*/

	rule [if-then-else-true]:
		< k > IfThenElse(tv(1, t(_, int)), S:K, _) => sequencePoint ~> S:K ...</ k >
		[structural]
	rule [if-then-else-false]:
		< k > IfThenElse(tv(0, t(_, int)), _, S:K) => sequencePoint ~> S:K ...</ k >
		[structural]
	rule
		< k > IfThenElse((V:KResult => simplifyTruth(V:KResult)), _, _) ...</ k >
		when isNotTruthValue(V:KResult)
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-WHILE is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	/*@ \source[n1570]{\para{6.8.5.1}{1}}
	The evaluation of the controlling expression takes place before each execution of the loop body.
	*/
	
	rule [while-mark]:
		< k > While(B:K, S:K) ~> K:K
			=> loopMarked ~> While(B:K, S:K) ~> popLoop
		</ k >
		< blockHistory > ListItem(Num:#Nat) ...</ blockHistory >
		< loopStack > .List => ListItem(kpair(Num:#Nat, K:K)) ...</ loopStack >
		[structural] 
	rule [while]:
		< k > loopMarked ~> While(B:K, S:K)
			=> IfThenElse(B:K, (S:K ~> loopMarked ~> While(B:K, S:K)), Nop)
		...</ k >
		[metadata "computational=()"]
		// [structural]  // rule so that looping programs see repetition
endkm

kmod DYNAMIC-SEMANTICS-DO-WHILE is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	/*@\source[n1570]{\para{6.8.5.2}{1}}
	The evaluation of the controlling expression takes place after each execution of the loop body.
	*/
	
	rule [do-while-mark]:
		< k > DoWhile(B:K, S:K) ~> K:K
			=> loopMarked ~> DoWhile(B:K, S:K) ~> popLoop
		</ k >
		< blockHistory > ListItem(Num:#Nat) ...</ blockHistory >
		< loopStack > .List => ListItem(kpair(Num:#Nat, K:K)) ...</ loopStack >
		[structural] 
	rule [do-while]:
		< k > loopMarked ~> DoWhile(B:K, S:K)
			=> S:K ~> IfThenElse(B:K, (loopMarked ~> DoWhile(B:K, S:K)), Nop)
		...</ k >
		[metadata "computational=()"]
		// [structural]  // rule so that looping programs see repetition
endkm

kmod DYNAMIC-SEMANTICS-FOR is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	/*@ \source[n1570]{\para{6.8.5.2}{1}}
	The statement 
	\cdisplay{for ( $\textit{clause-1}$ ; $\textit{expression-2}$ ; $\textit{expression-3}$ ) $\textit{statement}$ }
	 behaves as follows: The expression $\textit{expression-2}$ is the controlling expression that is evaluated before each execution of the loop body. The expression $\textit{expression-3}$ is evaluated as a void expression after each execution of the loop body. If $\textit{clause-1}$ is a declaration, the scope of any identifiers it declares is the remainder of the declaration and the entire loop, including the other two expressions; it is reached in the order of execution before the first evaluation of the controlling expression. If $\textit{clause-1}$ is an expression, it is evaluated as a void expression before the first evaluation of the controlling expression.

	\source[n1570]{\para{6.8.5.2}{1}}
Both $\textit{clause-1}$ and $\textit{expression-3}$ can be omitted. An omitted $\textit{expression-2}$ is replaced by a nonzero constant.
	*/
	
	rule ForClauseExpression(K:K) => Computation(K:K) [structural]
	
	rule
		< k > addToHistory(Num:#Nat) => .K ...</ k >
		< blockHistory > .List => ListItem(Num:#Nat) ...</ blockHistory >
		[structural] 
	
	//  fixme fishy interaction with continue i think
	rule [for-mark]:
		< k > (For(ForNum:#Nat, Pre:K, Control:K, Post:K, S:K) ~> K:K
			=> pushBlock ~> addToHistory(ForNum:#Nat) ~> Pre:K ~> loopMarked ~> For(ForNum:#Nat, Pre:K, (if Control:K =/=Bool emptyValue then Control:K else tv(1, t(.Set, int)) fi), Post:K, S:K) ~> popLoop)
		</ k >
		@latex("\\kBR")
		< blockHistory > ListItem(Num:#Nat) ...</ blockHistory >
		< loopStack > .List => ListItem(kpair(Num:#Nat, K:K)) ...</ loopStack >
		[structural large] 
		
	rule [for]:
		< k > loopMarked ~> For(ForNum:#Nat, Pre:K, Control:K, Post:K, S:K)
			=> IfThenElse(Control:K, (S:K ~> Computation(Post:K) ~> loopMarked ~> For(ForNum:#Nat, Pre:K, Control:K, Post:K, S:K)), Nop)
		...</ k >
		< blockHistory > ListItem(Num:#Nat) ...</ blockHistory >
		[metadata "computational=()"]
		// [structural] // rule so that looping programs see repetition 
endkm

kmod DYNAMIC-SEMANTICS-SWITCH is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	//  fixme shouldn't there be sequence points here?
	//  fixme not doing promoting or conversion
	
	op handleSwitch : #Nat K -> K [metadata "strict=(2)"] //  switch num, promoted value of controlling exp, int value of exp
	op handleSwitch-aux : K Value K -> K 
	
	/*@ \source[n1570]{\para{6.8.5.2}{4}}
	A \cinline{switch} statement causes control to jump to, into, or past the statement that is the switch body, depending on the value of a controlling expression, and on the presence of a \cinline{default} label and the values of any \cinline{case} labels on or in the switch body. A \cinline{case} or \cinline{default} label is accessible only within the closest enclosing \cinline{switch} statement.
	
	\source[n1570]{\para{6.8.5.2}{5}}
	The integer promotions are performed on the controlling expression. The constant expression in each \cinline{case} label is converted to the promoted type of the controlling expression. If a converted value matches that of the promoted controlling expression, control jumps to the statement following the matched \cinline{case} label. Otherwise, if there is a default label, control jumps to the labeled statement. If no converted \cinline{case} constant expression matches and there is no \cinline{default} label, no part of the switch body is executed.
	*/
	
	rule
		< k > Switch(SN:#Nat, tv(V:K, T:KResult), _) 
			=> sequencePoint 
			~> handleSwitch(SN:#Nat, cast(promote(T:KResult), tv(V:K, T:KResult))) 
		...</ k >
		when hasIntegerType(T:KResult)
		[structural] 
		
	rule
		< k > handleSwitch(SN:#Nat, V:KResult) => handleSwitch-aux(SN:#Nat, V:KResult, Map(M:Map)) ...</ k >
		< currentFunction > F:#Id </ currentFunction >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		< gotoMap >... kpair(Tu:K, F:#Id) |-> Map(M:Map) ...</ gotoMap >
		[structural] 
		
	//  match found in value and type, goto it
	//  don't need to erase the rest of K since we're GOTOing
	rule
		< k > tryCase(V:KResult, V:KResult, CaseHelper:K) => Goto(CaseHelper:K) ...</ k >
		[structural]
		
	op tryCase : K Value K -> K //  K to be evaluated, val it should be, casehelper
	context tryCase((HOLE => reval(HOLE)), _, _)
	rule
		< k > (.K => tryCase(Exp:K, V:KResult, CaseHelper:K)) ~> handleSwitch-aux(SN:#Nat, V:KResult, Map((_ ((genLabel(SN:#Nat, Exp:K) |-> CaseHelper:K) => .Map))))
		...</ k >
		when Exp:K =/=Bool l('Default)
		[structural] 
		
	//  if all that's left is a default, do it
	rule
		< k > handleSwitch-aux(SN:#Nat, _, Map((genLabel(SN:#Nat, l('Default)) |-> _))) 
			=> Goto(genLabel(SN:#Nat, l('Default)))
		...</ k >
		[structural] 
	
	//  if there's nothing left, no case matches
	rule
		< k > handleSwitch-aux(_, _, Map(.Map)) => .K ...</ k >
		[structural] 

	rule
		< k > tryCase(tv(V':K, T:KResult), tv(V:K, T:KResult), CaseHelper:K) => .K ...</ k >
		when V:K =/=Bool V':K
		[structural] 
		
	rule
		< k > handleSwitch-aux(SN:#Nat, _, Map((_ ((genLabel(SN':#Nat, _) |-> _) => .Map)))) ...</ k >
		when SN:#Nat =/=Bool SN':#Nat
		[structural] 
	rule
		< k > handleSwitch-aux(SN:#Nat, _, Map((_ ((L:KLabel(_) |-> _) => .Map)))) ...</ k >
		when L:KLabel =/=Bool 'genLabel
		[structural] 
			
	rule
		< k > tryCase((tv(V:K, T':KResult) => cast(T:KResult, tv(V:K, T':KResult))), tv(_, T:KResult), _) ...</ k >
		when T:KResult =/=Bool T':KResult
		[structural] 
	
	rule [case-fall-through]:
		< k > Case(_:#Nat, _:#Nat, _, K:K) => K:K ...</ k >
		[structural] 
	rule [default-fall-through]:
		< k > Default(_:#Nat, K:K) => K:K ...</ k >
		[structural] 
endkm

kmod DYNAMIC-SEMANTICS-GOTO is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
	
	/*@ \source[n1570]{\para{6.8.6.1}{2}}
	A \cinline{goto} statement causes an unconditional jump to the statement prefixed by the named label in the enclosing function.
	*/
	
	//  fixme CONFIRM It seems there are no sequence points for a goto
	
/*@ \source[n1570]{\para{6.2.4}{6}} For such an object that does not have a variable length array type, its lifetime extends from entry into the block with which it is associated until execution of that block ends in any way. (Entering an enclosed block or calling a function suspends, but does not end, execution of the current block.) If the block is entered recursively, a new instance of the object is created each time. The initial value of the object is indeterminate. If an initialization is specified for the object, it is performed each time the declaration or compound literal is reached in the execution of the block; otherwise, the value becomes indeterminate each time the declaration is reached.
*/
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
		< k > Goto(Label:K) ~> _ => processGoto(GotoInfo:K) </ k >
		< currentFunction > F:#Id </ currentFunction >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		< gotoMap >... kpair(Tu:K, F:#Id) |-> Map((_ (Label:K |-> GotoInfo:K))) ...</ gotoMap >
		[metadata "computational=()"]
		// [structural]  // rule so that looping programs see repetition
		
	// - first case, when we're in the same block
	rule
		< k > L:KLabel(gotoObject(Depth:#Nat, (ListItem(CurrentBlock:#Nat) BlockHistory:List), K:K, LoopStack:List, DeclStack:List)) ~> _ 
			=> addVariablesForBlock(CurrentBlock:#Nat, DeclStack:List)
			~> K:K
		</ k >
		< nestingDepth > Depth:#Nat </ nestingDepth >
		< blockHistory > ListItem(CurrentBlock:#Nat) BlockHistory:List </ blockHistory >
		< loopStack > _ => LoopStack:List </ loopStack >
		< localVariables > Vars:List </ localVariables >
		when L:KLabel ==Bool 'processGoto
		orBool L:KLabel ==Bool 'processGotoDown
		[structural] 
		
	// - second case, we're in a different block
	
	//  as long as there are entries in the actual block history that differ from the target block history, we need to pop
	rule [processGoto-pop-differing-1]:
		< k > (. => popBlock) 
			~> processGoto(gotoObject(TargetDepth:#Nat, TargetBlockHistory:List, _, _, _))
		...</ k >
		< blockHistory > ListItem(BlockNum:#Nat) ActualHistory:List </ blockHistory >
		when notBool BlockNum:#Nat in TargetBlockHistory:List
		[structural] 
		
	//  same
	rule [processGoto-pop-differing-2]:
		< k > (. => popBlock) 
			~> processGoto(gotoObject(TargetDepth:#Nat, Prefix:List ListItem(BlockNum:#Nat) TargetBlockHistory:List, _, _, _))
		...</ k >
		< blockHistory > ListItem(BlockNum:#Nat) ActualHistory:List </ blockHistory >
		when TargetBlockHistory:List =/=Bool ActualHistory:List
		[structural] 
			
	//  once we share a history, we start to push
	rule
		< k > processGoto(gotoObject(TargetDepth:#Nat, (Prefix:List ListItem(TargetBlock:#Nat) ActualHistory:List), K:K, LoopStack:List, DeclStack:List))
			=> addVariablesForBlock(CurrentBlock:#Nat, DeclStack:List)
			~> processGotoDown(gotoObject(TargetDepth:#Nat, (Prefix:List ListItem(CurrentBlock:#Nat) ActualHistory:List), K:K, LoopStack:List, DeclStack:List))
		...</ k >
		@latex("\\kBR")
		< nestingDepth > ActualDepth:#Nat </ nestingDepth >
		< blockHistory > ListItem(CurrentBlock:#Nat) ActualHistory:List </ blockHistory >
		when sNat(ActualDepth:#Nat) =/=Bool TargetDepth:#Nat
		[structural large] 
		
	rule
		< k > ( . 
				=> pushBlock
				~> addToHistory(TargetBlock:#Nat)
				~> addVariablesForBlock(TargetBlock:#Nat, DeclStack:List)
			)
			~> processGotoDown(gotoObject(TargetDepth:#Nat, (_ ListItem(TargetBlock:#Nat) ActualHistory:List), _, _, DeclStack:List))
		...</ k >
		@latex("\\kBR")
		< nestingDepth > ActualDepth:#Nat </ nestingDepth >
		< blockHistory > ActualHistory:List </ blockHistory > //  (. => ListItem(TargetBlock:#Nat)) 
		when sNat(ActualDepth:#Nat) =/=Bool TargetDepth:#Nat
		[structural large] 
	
	//  We've made it to the block above the target
	rule
		< k > L:KLabel(gotoObject(sNat(Depth:#Nat), 
				(ListItem(TargetBlock:#Nat) BlockHistory:List),
				K:K, 
				LoopStack:List, 
				DeclStack:List)
			) ~> _
			=> pushBlock
			~> addToHistory(TargetBlock:#Nat)
			~> addVariablesForBlock(TargetBlock:#Nat, DeclStack:List)
			~> K:K
		</ k >
		< nestingDepth > Depth:#Nat </ nestingDepth >
		< blockHistory > BlockHistory:List </ blockHistory >
		< loopStack > _ => LoopStack:List </ loopStack >
		when L:KLabel ==Bool 'processGoto
		orBool L:KLabel ==Bool 'processGotoDown
		[structural] 
		
	op addVariablesForBlock : #Nat List -> K 
	
	//  skip variables from other blocks
	rule
		< k > addVariablesForBlock(TargetBlock:#Nat, 
				((ListItem(frozenDeclaration(_:#Nat, BlockNum:#Nat, _)) => .) DeclStack:List)
			)
		...</ k >
		< blockHistory > ListItem(TargetBlock:#Nat) ...</ blockHistory >
		when BlockNum:#Nat =/=Bool TargetBlock:#Nat
		[structural] 
		
	//  skip variables in the real history
	rule
		< k > addVariablesForBlock(TargetBlock:#Nat,
				((ListItem(frozenDeclaration(_:#Nat, TargetBlock:#Nat, Decl:K)) => .) DeclStack:List)
			)
		...</ k >
		< localVariables > Vars:List </ localVariables >
		< blockHistory > ListItem(TargetBlock:#Nat) ...</ blockHistory >
		when getIdOfDeclaration(Decl:K) in Vars:List
		[structural]
		
	// op getIdString : K -> #String 
	// rule getIdString(Identifier(S:#String)) => S:#String [structural]
	
	op enableInits : -> K 
	
	rule
		< k > enableInits => .K ...</ k >
		< shouldInit > _ => true </ shouldInit >
		[structural] 
	
	rule
		< k > (. => Decl:K ~> enableInits) ~> addVariablesForBlock(TargetBlock:#Nat, 
				((ListItem(frozenDeclaration(_:#Nat, TargetBlock:#Nat, Decl:K)) => .List) _)
			)
		...</ k >
		< localVariables > Vars:List </ localVariables >
		< blockHistory > ListItem(TargetBlock:#Nat) ...</ blockHistory >
		< shouldInit > _ => false </ shouldInit >
		when notBool getIdOfDeclaration(Decl:K) in Vars:List
		[structural]
		
	//  fixme this is wrong
	rule
		< k > addVariablesForBlock(_:#Nat, .List) => .K ...</ k >
		[structural] 

endkm

kmod DYNAMIC-SEMANTICS-RETURN is
	including DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 

	
	/*@ \source[n1570]{\para{6.8.6.4}{2}}
	A \cinline{return} statement terminates execution of the current function and returns control to its caller. A function may have any number of \cinline{return} statements.
	
	\source[n1570]{\para{6.8.6.4}{3}}
	If a \cinline{return} statement with an expression is executed, the value of the expression is returned to the caller as the value of the function call expression. If the expression has a type different from the return type of the function in which it appears, the value is converted as if by assignment to an object having the return type of the function.
	*/
	
	rule [return-clean-local]:
		< k > (.K => deleteBlock(Loc:#Nat)) ~> Return(V:KResult) ...</ k >
		< localAddresses >... SetItem(Loc:#Nat) => .Set ...</ localAddresses >	
		[structural] 
		
	rule [fetch-all-locals]:
		< k > Return(V:KResult) ...</ k >
		< localAddresses > .Set => Addresses:Set </ localAddresses >
		< blockStack > ListItem(< stackFrame > 
			_
			< localAddresses > Addresses:Set </ localAddresses >
			</ stackFrame >)
			=> .List
		...</ blockStack >
		[structural] 

	//  this is used for returns with no return value as well, since we return "emptyValue", which will hopefully be cast to void
	rule [return]: 
		< k > Return(V:KResult) ~> _ 
			=> sequencePoint 
			~> cast(T:KResult, V:KResult) 
			~> K:K
		</ k >
		< control >
			//  these cells get replaced by the ones in C:Bag, so we can delete them when we match them
			(< local >... < localAddresses > .Set </ localAddresses > ...</ local > => .Bag)
			< currentFunction > (F:#Id => CurrFun:K) </ currentFunction >
			< currentProgramLoc > _ => CurrLoc:K </ currentProgramLoc >
			(< currentTranslationUnit > Tu:K </ currentTranslationUnit > => .Bag)
			(< blockStack > .List </ blockStack > => .Bag)
			(_ => C:Bag)
		</ control >
		@latex("\\kBR")
		< gtypes >... Tu:K |-> Map((_ (F:#Id |-> t(_, functionType(T:KResult, _))))) ...</ gtypes >
		< callStack >
			ListItem(
				< stackFrame >
					< continuation > K:K </ continuation >
					C:Bag
					< stackCurrentFunction > CurrFun:K </ stackCurrentFunction >
					< stackCurrentProgramLoc > CurrLoc:K </ stackCurrentProgramLoc >
				</ stackFrame >
			) => .List
		...</ callStack >
		[structural large] 
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
			< nestingDepth > N:#Nat => sNat(N:#Nat) </ nestingDepth >
		</ local >
		< blockStack > .List 
			=> ListItem(< stackFrame > C:Bag 
			< nestingDepth > N:#Nat </ nestingDepth > 
			< localVariables > Vars:List </ localVariables >
			< localAddresses > Addresses:Set </ localAddresses >
			</ stackFrame >)
		...</ blockStack >
		[structural] 
		
	rule [pop-block-free-memory]:
		< k > (.K => deleteBlock(Loc:#Nat)) ~> popBlock ...</ k >
		< localAddresses >... (SetItem(Loc:#Nat) => .Set) ...</ localAddresses >
		[structural] 
		
	//  this can be simplified without the debugging info
	rule [pop-block]:
		< k > popBlock => .K ...</ k >
		< local > 
			(_ => C:Bag)
			(< localAddresses > .Set </ localAddresses > => .Bag)
		</ local >
		< blockStack > ListItem(
			< stackFrame > C:Bag </ stackFrame >
		) => .List 
		...</ blockStack >
		[structural] 
	
	
	/*@ \source[n1570]{\para{6.8}{3}}
	A block allows a set of declarations and statements to be grouped into one syntactic unit.  The initializers of objects that have automatic storage duration, and the variable length array declarators of ordinary identifiers with block scope, are evaluated and the values are stored in the objects (including storing an indeterminate value in objects without an initializer) each time the declaration is reached in the order of execution, as if it were a statement, and within each declaration in the order that declarators appear.
	*/
	rule [dissolve-block]:
		< k > Block(BlockNum:#Nat, _, List(Statements:List{K})) => klistToK(Statements:List{K}) ...</ k >
		< blockHistory > .List => ListItem(BlockNum:#Nat) ...</ blockHistory >
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
	
	
	/*@ \source[n1570]{\para{6.8.3}{2}}
	The expression in an expression statement is evaluated as a void expression for its side effects.
	*/
	rule [expression-statement]:
		< k > Computation(V:KResult) => sequencePoint ...</ k > 
		[structural] 
	
	rule [popLoop]:
		< k > popLoop ~> _ => K:K </ k >
		< blockHistory > ListItem(Num:#Nat) ...</ blockHistory >
		< loopStack > ListItem(kpair(Num:#Nat, K:K)) => .List ...</ loopStack >
		[structural] 

	rule [popLoop-popBlock]:
		< k > (. => popBlock) ~> popLoop ...</ k >
		< blockHistory > ListItem(Num:#Nat) ...</ blockHistory >
		< loopStack > ListItem(kpair(Num':#Nat, _)) ...</ loopStack >
		when Num':#Nat =/=Bool Num:#Nat
		[structural] 
	
	/*@ \source[n1570]{\para{6.8.6.2}{2}}
	A continue statement causes a jump to the loop-continuation portion of the smallest enclosing iteration statement; that is, to the end of the loop body. \ldots
	*/
	rule [continue]:
		< k > Continue ~> ((L:KLabel)(_) => .) ...</ k >
		when L:KLabel =/=Bool 'loopMarked
		andBool L:KLabel =/=Bool 'popBlock
		andBool L:KLabel =/=Bool 'pushBlock
		andBool L:KLabel =/=Bool 'popLoop
		[structural]
	rule [continue-through-pop]:
		< k > Continue ~> popBlock 
			=> popBlock
			~> Continue
		...</ k >
		[structural]

	rule [continue-done-for]:
		< k > (Continue => Computation(Post:K)) ~> loopMarked ~> For(_:#Nat, _, _, Post:K, _) ...</ k >
		[structural]
	rule [continue-done]:
		< k > (Continue => .K) ~> loopMarked ~> L:KLabel(_) ...</ k >
		when L:KLabel =/=Bool 'For
		[structural]
		
	/*@ \source[n1570]{\para{6.8.6.3}{2}}
	A break statement terminates execution of the smallest enclosing switch or iteration statement.
	*/
	rule [break]:
		< k > Break => popLoop ...</ k >
		[structural] 
endkm
