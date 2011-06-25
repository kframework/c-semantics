kmod DYNAMIC-C-LTL-INCLUDE is
	including DYNAMIC-INCLUDE 
	including PL-MODEL-CHECKER-BUILTIN-MODULE
	
	op state : Bag -> Model-Checker-State
	op k2model : K -> LTLFormula
	op expAtom : LTLFormula -> Prop
	
	op executing : -> Prop
endkm

kmod DYNAMIC-LTL-BASIC-PREDICATES is
	including DYNAMIC-C-LTL-INCLUDE
	
	macro k2model(LTL-Builtin(Identifier("executing"))) = executing
	
	macro state(
		B0:Bag
		< T > B1:Bag
			< threads > B2:Bag
				< thread > B3:Bag
					< control > B4:Bag
						< currentFunction >
							File-Scope
						</ currentFunction >
					</ control >
				</ thread >
			</ threads >
		</ T >
	) LTL|= executing = false
endkm

kmod DYNAMIC-C-LTL is
	including DYNAMIC-C-LTL-INCLUDE
	including DYNAMIC-LTL-BASIC-PREDICATES

	
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
	// rule k2model(LTL-Implies(A:K, B:K)) = k2model(A:K) LTL k2model(B:K)
	// rule k2model(LTL-Equiv(A:K, B:K)) = k2model(A:K) LTL k2model(B:K)
	macro k2model(LTL-WeakUntil(A:K, B:K)) = k2model(A:K) LTLW k2model(B:K)
	
	macro k2model(LTL-Atom(A:K)) = expAtom(k2model(A:K))
	
	// eq state(
		// B0:Bag
		// < T > 
			// B1:Bag
			// < threads >
				// B2:Bag
				// < thread >
					// B3:Bag
					// < k > 'Apply('Closure(Id X:Id(.List{K}),, K0:K,, K1:K),, K3:K) ~> K:K </ k >
				// </ thread >
			// </ threads >
		// </ T >
	// ) |= expAtom(k2model(A:K)) = true .
	
	
endkm
