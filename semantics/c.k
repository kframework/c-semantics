load k-includes

load c-syntax
load common-c-configuration
load dynamic-c-configuration
load common-c-semantics
load dynamic-c-semantics

kmod C-SEMANTICS is
	including C-SYNTAX
	including C-CONFIGURATION
	including COMMON-C-SEMANTICS
	including DYNAMIC-C-SEMANTICS
endkm

kmod C is 
	including C-SEMANTICS 
endkm
