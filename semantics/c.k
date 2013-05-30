require "c-syntax.k"
require "c-configuration.k"
require "dynamic-c-semantics.k"

module C-SEMANTICS
	imports C-CONFIGURATION
	imports DYNAMIC-C-SEMANTICS
endmodule

module C
	imports C-SEMANTICS 
endmodule
