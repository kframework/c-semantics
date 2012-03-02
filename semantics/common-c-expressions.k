kmod COMMON-SEMANTICS-EXPRESSIONS-INCLUDE is
	including COMMON-INCLUDE 

endkm

kmod COMMON-C-EXPRESSIONS is
	including COMMON-SEMANTICS-EXPRESSIONS-INCLUDE

	rule NothingExpression => emptyValue [structural anywhere]
endkm
