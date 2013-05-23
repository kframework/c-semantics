module COMMON-SEMANTICS-EXPRESSIONS-INCLUDE
	imports COMMON-INCLUDE 

endmodule

module COMMON-C-EXPRESSIONS
	imports COMMON-SEMANTICS-EXPRESSIONS-INCLUDE

	rule NothingExpression => emptyValue [structural anywhere]
endmodule
