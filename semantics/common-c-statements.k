module COMMON-SEMANTICS-STATEMENTS-INCLUDE is
	including COMMON-INCLUDE 
	
	syntax Statement ::= "loopMarked" [klabel(loopMarked)] 
	syntax K ::= "genLabel" "(" Nat "," K ")" [klabel(genLabel)] //  switchid, value (tv or 'Default)
	syntax K ::= "popLoop" [klabel(popLoop)]
	syntax K ::= "popBlock" [klabel(popBlock)]
	syntax K ::= "frozenDeclaration" "(" Nat "," Nat "," K ")" [klabel(frozenDeclaration)] //  nestingDepth, currentBlock, decl
	syntax K ::= "gotoObject" "(" Nat "," List "," K "," List "," List ")" [latex "\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!)" klabel(gotoObject)] //  nestingDepth, block history, continuation, loop stack, decl stack
	
	
	syntax K ::= "case" "(" Nat ")" [klabel(case)] 
end module 


module COMMON-SEMANTICS-PROCESS-LABELS is
	including COMMON-SEMANTICS-STATEMENTS-INCLUDE 
	// now that we can have different strictnesses in different cells, maybe this can be redone easily
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
	
	syntax K ::= "waitingOnGotoMap" [klabel(waitingOnGotoMap)] 
	rule 
		<k> calculateGotoMap(F:Id, K:K) => waitingOnGotoMap ...</k>
		<gotoMap> M:Map => M:Map[Map(.Map) / kpair(Tu:K, F:Id)] </gotoMap>
		<currentFunction> _ => F:Id </currentFunction>
		<currTU> Tu:K </currTU>
		//<br/>
		<calculateGotoMap>
			. => (<gotoCalculation>... <computation> K:K ~> Return(NothingExpression) </computation> ...</gotoCalculation>)
		</calculateGotoMap>
		[structural] 
		
	rule
		(<gotoCalculation> <computation> .K </computation> ...</gotoCalculation>) => .Bag
		[structural] 


	rule
		<k> waitingOnGotoMap => .K ...</k>
		<calculateGotoMap> .Bag </calculateGotoMap>
		<currentFunction> _ => File-Scope </currentFunction>
		[structural] 

	syntax K ::= "endBlockForGoto" "(" Nat ")" [klabel(endBlockForGoto)] 
	rule 
		<computation> BlockStatement(Block:K)
			=> Block:K ~> popBlock
		...</computation>
		<nestingDepthGoto> N:Nat => N:Nat +Int 1 </nestingDepthGoto>
		<blockHistoryGoto> ListItem(OldNum:Nat) ...</blockHistoryGoto>
		[structural] 
	rule
		<computation> Block(Num:Nat, _, List(L:List{K})) => klistToK(L:List{K}) ...</computation> 
		<blockHistoryGoto> . => ListItem(Num:Nat) ...</blockHistoryGoto>
		//  <declarationStack>... .List => ListItem(.K) </declarationStack>
		[structural] 
		
	rule
		<computation> popBlock => .K ...</computation>
		<nestingDepthGoto> I:Int => I:Int -Int 1 </nestingDepthGoto>
		<blockHistoryGoto> (_:ListItem => .List) ListItem(Num:Nat) ...</blockHistoryGoto>
		when I:Int >Int 0
		[structural] 
		
	rule [DefinitionLoc-computation]:
		<computation> CodeLoc(K:K, L:CabsLoc) => K:K ...</computation>
		<currentProgramLoc> _ => L:CabsLoc </currentProgramLoc>
		[structural] 

	// this rule is different than the dynamic one because we don't enforce T to be reduced yet
	rule
		<computation> DeclarationDefinition(InitNameGroup(T:K, List((K:K,, K':K,, L:List{K}))))
			=> DeclarationDefinition(InitNameGroup(T:K, List(K:K)))
			~> DeclarationDefinition(InitNameGroup(T:K, List((K':K,, L:List{K}))))
		...</computation>
		[structural]
		
	// rule
		// <computation> Typedef(NameGroup(T:K, List((K:K,, K':K,, L:List{K}))))
			// => Typedef(nameGroup-aux(T:K, K:K))
			// ~> Typedef(NameGroup(T:K, List(K':K,, L:List{K})))
		// ...</computation>
		// [structural] 

	//  fixme would like to combine the below rules
	rule
		<computation> DeclarationDefinition(InitNameGroup(T:K, List(K:K))) => .K ...</computation>
		<br/>
		<declarationStack>... 
			.List 
			=> ListItem(frozenDeclaration(Depth:Nat, BlockNum:Nat, DeclarationDefinition(InitNameGroup(T:K, List(K:K))))) 
		</declarationStack>
		//<br/>
		<nestingDepthGoto> Depth:Nat </nestingDepthGoto>
		<blockHistoryGoto> ListItem(BlockNum:Nat) ...</blockHistoryGoto>
		[structural large]
	// rule
		// <computation> DeclarationDefinition(K:K) => .K ...</computation>
		// <declarationStack>... .List 
			// => ListItem(frozenDeclaration(Depth:Nat, BlockNum:Nat, DeclarationDefinition(K:K))) 
		// </declarationStack>
		// <nestingDepthGoto> Depth:Nat </nestingDepthGoto>
		// <blockHistoryGoto> ListItem(BlockNum:Nat) ...</blockHistoryGoto>
		// [structural]
		
	rule
		<computation> OnlyTypedef(K:K) => .K ...</computation>
		<declarationStack>... .List 
			=> ListItem(frozenDeclaration(Depth:Nat, BlockNum:Nat, OnlyTypedef(K:K))) 
		</declarationStack>
		//<br/>
		<nestingDepthGoto> Depth:Nat </nestingDepthGoto>
		<blockHistoryGoto> ListItem(BlockNum:Nat) ...</blockHistoryGoto>
		[structural] 
		
	rule [compute-label-typedef]:
		<computation> Typedef(K:K) => .K ...</computation>
		<declarationStack>... .List 
			=> ListItem(frozenDeclaration(Depth:Nat, BlockNum:Nat, Typedef(K:K))) 
		</declarationStack>
		//<br/>
		<nestingDepthGoto> Depth:Nat </nestingDepthGoto>
		<blockHistoryGoto> ListItem(BlockNum:Nat) ...</blockHistoryGoto>
		[structural] 
		
	rule [compute-label-ignore-non-statement]:
		<computation> L:KLabel(Args:List{K}) => .K ...</computation>
		when false
		orBool L:KLabel ==KLabel 'Nop
		orBool L:KLabel ==KLabel 'Computation
		orBool L:KLabel ==KLabel 'Break
		orBool L:KLabel ==KLabel 'Continue
		orBool L:KLabel ==KLabel 'Return
		orBool L:KLabel ==KLabel 'Goto
		orBool L:KLabel ==KLabel 'CompGoto
		[structural] 
		
	// - should do this with a split
	rule [compute-label-for]:
		<gotoCalculation>
			<computation> (For(ForNum:Nat, Pre:K, Control:K, Post:K, S:K) => .K) ~> K:K </computation>
			<computationTail> Tail:K </computationTail>
			<br/>
			B:Bag
			<nestingDepthGoto> N:Nat </nestingDepthGoto>
			<blockHistoryGoto> ListItem(Num:Nat) OldBlockHistory:List </blockHistoryGoto>
			<loopStackGoto> OldLoopStack:List </loopStackGoto>
		</gotoCalculation>
		<br/>
		(. =>
			<gotoCalculation> 
				<computation> S:K </computation>
				<br/>
				<computationTail>
					Computation(Post:K)
					~> loopMarked
					~> For(ForNum:Nat, Pre:K, (#if Control:K =/=K emptyValue #then Control:K #else tv(1, t(.Set, int)) #fi), Post:K, S:K)
					~> popLoop
					~> K:K 
					~> Tail:K 
				</computationTail>
				<br/>
				B:Bag
				<nestingDepthGoto> N:Nat +Int 1 </nestingDepthGoto>
				<blockHistoryGoto> ListItem(ForNum:Nat) ListItem(Num:Nat) OldBlockHistory:List </blockHistoryGoto>
				<loopStackGoto> ListItem(kpair(Num:Nat, (K:K ~> Tail:K))) OldLoopStack:List </loopStackGoto>
			</gotoCalculation>
		)
		[structural large] 
		
	rule [compute-label-do-while]:
		<gotoCalculation>
			<computation> (DoWhile(E:K, S:K) => .K) ~> K:K </computation>
			<computationTail> Tail:K </computationTail>
			B:Bag
			<blockHistoryGoto> ListItem(Num:Nat) OldBlockHistory:List </blockHistoryGoto>
			<loopStackGoto> OldLoopStack:List </loopStackGoto>
		</gotoCalculation>
		<br/>
		(. =>
			<gotoCalculation> 
				<computation> S:K </computation>
				<br/>
				<computationTail>
					IfThenElse(E:K, (loopMarked ~> DoWhile(E:K, S:K)), Nop)
					~> popLoop
					~> K:K 
					~> Tail:K 
				</computationTail>
				<br/>
				B:Bag
				<blockHistoryGoto> ListItem(Num:Nat) OldBlockHistory:List </blockHistoryGoto>
				<loopStackGoto> ListItem(kpair(Num:Nat, (K:K ~> Tail:K))) OldLoopStack:List </loopStackGoto>
			</gotoCalculation>
		)
		[structural large]
		
	rule [compute-label-while-mark]:
		<computation> (. => S:K ~> loopMarked) ~> While(E:K, S:K) ~> (. => popLoop) ~> K:K </computation>
		//<br/>
		<computationTail> Tail:K </computationTail>
		<blockHistoryGoto> ListItem(Num:Nat) ...</blockHistoryGoto>
		<loopStackGoto> (. => ListItem(kpair(Num:Nat, (K:K ~> Tail:K)))) ...</loopStackGoto>
		[structural] 
	rule [compute-label-while-done]:
		<computation> (loopMarked ~> While(E:K, S:K) => .K) ~> popLoop ~> K:K </computation>
		[structural] 
		
	rule [compute-label-if-then-else]:
		<gotoCalculation>
			<computation> (IfThenElse(_, S1:K, S2:K) => .K) ~> K:K </computation>
			<computationTail> Tail:K </computationTail>
			B:Bag
		</gotoCalculation>
		<br/>
		(. =>
			<gotoCalculation> 
				<computation> S1:K </computation> 
				<computationTail> K:K ~> Tail:K </computationTail>
				B:Bag 
			</gotoCalculation>
		)
		(. =>
			<gotoCalculation> 
				<computation> S2:K </computation>
				<computationTail> K:K ~> Tail:K </computationTail>
				B:Bag 
			</gotoCalculation>
		)
		[structural large] 
		
	rule [compute-label-switch]:
		<computation> (Switch(_, E:K, S:K) => S:K ~> popLoop) ~> K:K </computation>
		<computationTail> Tail:K </computationTail>
		<blockHistoryGoto> ListItem(Num:Nat) ...</blockHistoryGoto>
		<loopStackGoto> (. => ListItem(kpair(Num:Nat, (K:K ~> Tail:K)))) ...</loopStackGoto>
		[structural] 
		
	rule [compute-label-poploop]:
		<computation> popLoop => .K ...</computation>
		<loopStackGoto> (_:ListItem => .) ...</loopStackGoto>
		[structural] 
		
	rule
		<computation> (Label(Target:Id, S:K) => S:K) ~> K:K </computation>
		<computationTail> Tail:K </computationTail>
		<loopStackGoto> LoopStack:List </loopStackGoto>
		<declarationStack> DeclStack:List </declarationStack>
		<br/>
		<gotoMap>... kpair(Tu:K, F:Id) |-> Map((M:Map => M:Map[gotoObject(Depth:Nat, BlockHistory:List, (S:K ~> K:K ~> Tail:K), LoopStack:List, DeclStack:List) / Target:Id])) ...</gotoMap>
		<br/>
		<currentFunction> F:Id </currentFunction>
		<currTU> Tu:K </currTU>
		<nestingDepthGoto> Depth:Nat </nestingDepthGoto>
		<blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
		when notBool $hasMapping(M:Map, Target:Id)
		[structural large]
		
	rule
		<computation> (Case(SwitchNum:Nat, CaseNum:Nat, Val:K, S:K) => S:K) ~> K:K </computation>
		<computationTail> Tail:K </computationTail>
		<loopStackGoto> LoopStack:List </loopStackGoto>
		<declarationStack> DeclStack:List </declarationStack>
		<br/>
		<gotoMap>... 
			kpair(Tu:K, F:Id) |-> Map(
			(M:Map => (M:Map[case(CaseNum:Nat) / genLabel(SwitchNum:Nat, Val:K)])[gotoObject(Depth:Nat, BlockHistory:List, (S:K ~> K:K ~> Tail:K), LoopStack:List, DeclStack:List) / case(CaseNum:Nat)])
		) 
		...</gotoMap>
		<br/>
		<currentFunction> F:Id </currentFunction>
		<currTU> Tu:K </currTU>
		<nestingDepthGoto> Depth:Nat </nestingDepthGoto>
		<blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
		when notBool $hasMapping(M:Map, genLabel(SwitchNum:Nat, Val:K))
		//  andBool hasIntegerType(T:KResult)
		[structural large] 
	rule
		<computation> (Default(SwitchNum:Nat, S:K) => S:K) ~> K:K </computation>
		<computationTail> Tail:K </computationTail>
		<loopStackGoto> LoopStack:List </loopStackGoto>
		<declarationStack> DeclStack:List </declarationStack>
		<br/>
		<gotoMap>... 
			kpair(Tu:K, F:Id) |-> Map((M:Map => M:Map[gotoObject(Depth:Nat, BlockHistory:List, (S:K ~> K:K ~> Tail:K), LoopStack:List, DeclStack:List) / genLabel(SwitchNum:Nat, l('Default))])) 
		...</gotoMap>
		<br/>
		<currentFunction> F:Id </currentFunction>
		<currTU> Tu:K </currTU>
		<nestingDepthGoto> Depth:Nat </nestingDepthGoto>
		<blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
		when notBool $hasMapping(M:Map, genLabel(SwitchNum:Nat, l('Default)))
		[structural large]
end module
 
module COMMON-C-STATEMENTS is
	including COMMON-SEMANTICS-STATEMENTS-INCLUDE 
	including COMMON-SEMANTICS-PROCESS-LABELS
	
end module
