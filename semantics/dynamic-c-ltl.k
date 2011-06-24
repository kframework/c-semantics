kmod DYNAMIC-C-LTL-INCLUDE is
	including DYNAMIC-INCLUDE 
	including PL-MODEL-CHECKER-BUILTIN-MODULE
endkm

kmod DYNAMIC-C-LTL is
	including DYNAMIC-C-LTL-INCLUDE
	
	op state : Bag -> Model-Checker-State
	op k2model : K -> LTLFormula
	
	// macro k2model(LTL-True) = LTLTrue
	// macro k2model(LTL-False) = LTLFalse
	// macro k2model(LTL-And(A:K, B:K)) = k2model(A:K) LTL/\ k2model(B:K)
	// macro k2model(LTL-Or(A:K, B:K)) = k2model(A:K) LTL\/ k2model(B:K)
	// macro k2model(LTL-Not(A:K)) = LTL~ k2model(A:K)
	// macro k2model(LTL-Next(A:K)) = LTLO k2model(A:K)
	// macro k2model(LTL-Always(A:K)) = LTL[] k2model(A:K)
	// macro k2model(LTL-Eventually(A:K)) = LTL<> k2model(A:K)
	// macro k2model(LTL-Until(A:K, B:K)) = k2model(A:K) LTLU k2model(B:K)
	// macro k2model(LTL-Release(A:K, B:K)) = k2model(A:K) LTLR k2model(B:K)
	// // rule k2model(LTL-Implies(A:K, B:K)) = k2model(A:K) LTL k2model(B:K)
	// // rule k2model(LTL-Equiv(A:K, B:K)) = k2model(A:K) LTL k2model(B:K)
	// macro k2model(LTL-WeakUntil(A:K, B:K)) = k2model(A:K) LTLW k2model(B:K)

	
endkm
