kmod DYNAMIC-C-LTL-INCLUDE is
	including DYNAMIC-INCLUDE 
	including #MODEL-CHECKER
	
	op state : Bag -> Model-Checker-State
	op k2model : K -> LTLFormula
	op expAtom : LTLFormula -> Prop
	
	op executing : -> Prop
	
	op checkTruth : Bag -> Bool
endkm

kmod DYNAMIC-LTL-BASIC-PREDICATES is
	including DYNAMIC-C-LTL-INCLUDE
	
	macro k2model(LTL-Builtin(Identifier("executing"))) = executing
	
	ceq state(
		B0:Bag
		< T > B1:Bag
			< threads > B2:Bag
				< thread > B3:Bag
					< threadLocal > B4:Bag
						< control > B5:Bag
							< currentFunction >
								Fun:K
							</ currentFunction >
						</ control >
					</ threadLocal > 
				</ thread >
			</ threads >
		</ T >
	) LTL|= executing = true
	if Fun:K =/=Bool File-Scope
endkm

// load maudeLib/modelcheck

kmod DYNAMIC-C-LTL is
	including DYNAMIC-C-LTL-INCLUDE
	including DYNAMIC-LTL-BASIC-PREDICATES
	// including MODEL-CHECK
	
	macro k2model(LTL-True) = LTLTrue
	macro k2model(LTL-False) = LTLFalse
	macro k2model(LTL-And(A:K, B:K)) = k2model(A:K) LTL/\ k2model(B:K)
	macro k2model(LTL-Or(A:K, B:K)) = k2model(A:K) LTL\/ k2model(B:K)
	macro k2model(LTL-Not(A:K)) = LTL~ k2model(A:K)
	macro k2model(LTL-Next(A:K)) = LTLO k2model(A:K)
	macro k2model(LTL-Always(A:K)) = LTL[] k2model(A:K)
	macro k2model(LTL-Eventually(A:K)) = LTL<> k2model(A:K)
	macro k2model(LTL-Until(A:K, B:K)) = k2model(A:K) LTLU k2model(B:K)
	macro k2model(LTL-Release(A:K, B:K)) = k2model(A:K) LTLR k2model(B:K)
	macro k2model(LTL-Implies(A:K, B:K)) = k2model(A:K) LTL-> k2model(B:K)
	macro k2model(LTL-Equiv(A:K, B:K)) = k2model(A:K) LTL<-> k2model(B:K)
	macro k2model(LTL-WeakUntil(A:K, B:K)) = k2model(A:K) LTLW k2model(B:K)
	
	macro k2model(LTL-Atom(A:K)) = expAtom(k2model(A:K))
	
	macro checkTruth(
		B0:Bag
		< T > B1:Bag
			< threads > B2:Bag
				< thread > B3:Bag
					< k > tv(1, int) ~> debug </ k > 
				</ thread >
			</ threads >
		</ T >
	) = true
	macro checkTruth(
		B0:Bag
		< T > B1:Bag
			< threads > B2:Bag
				< thread > B3:Bag
					< k > tv(0, int) ~> debug </ k > 
				</ thread >
			</ threads >
		</ T >
	) = false
	
endkm
