load c-syntax
load dynamic-c-semantics

kmod C-SEMANTICS is
	including DYNAMIC-C-CONFIGURATION
	including DYNAMIC-C-SEMANTICS
endkm

kmod C is 
	including C-SEMANTICS 
endkm
