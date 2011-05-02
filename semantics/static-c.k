load ../../../../k-prelude


---load programs-gen
load c-syntax
load common-c-configuration
load static-c-configuration
load static-c-semantics

kmod C-SEMANTICS is
	including C-SYNTAX
	including C-CONFIGURATION
	including STATIC-C-SEMANTICS
endkm

kmod C is 
	including C-SEMANTICS 
endkm
