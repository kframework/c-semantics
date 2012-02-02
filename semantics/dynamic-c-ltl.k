kmod DYNAMIC-C-LTL-INCLUDE is
	including DYNAMIC-INCLUDE 
	including #MODEL-CHECKER
	
	op state : Bag -> #Model-Checker-State
	op k2model : K -> #LTLFormula
	op executing : -> #Prop
	op checkTruth : Bag -> #Bool
endkm

kmod DYNAMIC-LTL-BASIC-PREDICATES is
	including DYNAMIC-C-LTL-INCLUDE
endkm

kmod DYNAMIC-C-LTL is
	including DYNAMIC-C-LTL-INCLUDE
	including DYNAMIC-LTL-BASIC-PREDICATES
endkm
