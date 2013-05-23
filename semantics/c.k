require "c-syntax.k"
require "dynamic-c-semantics.k"

module C-SEMANTICS
	imports DYNAMIC-C-CONFIGURATION
	imports DYNAMIC-C-SEMANTICS
endmodule

module C
	imports C-SEMANTICS 
endmodule
