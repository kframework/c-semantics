kmod COMMON-C-CONFIGURATION is
	including C-SYNTAX
	
	op k : -> CellLabel
	op stackFrame : -> CellLabel
	op continuation : -> CellLabel
	op stackCurrentFunction : -> CellLabel
	op stackCurrentProgramLoc : -> CellLabel
	op nextFile : -> CellLabel
	op currentProgramLoc : -> CellLabel 
	op structs : -> CellLabel
	
	
	subsort Id Int String Float Bool Rat < K
	subsort String < Builtins
	
	subsort C < K
	subsort List{C} < K
	
endkm
