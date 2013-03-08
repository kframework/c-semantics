module COMMON-SEMANTICS-EXPRESSIONS-INCLUDE is
	including COMMON-INCLUDE 

end module

module COMMON-C-EXPRESSIONS is
	including COMMON-SEMANTICS-EXPRESSIONS-INCLUDE

	rule NothingExpression => emptyValue [structural anywhere]
end module
