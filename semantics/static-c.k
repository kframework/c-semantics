load k-includes

load c-syntax
load static-c-semantics

kmod C-SEMANTICS is
	including STATIC-C-CONFIGURATION
	including STATIC-C-SEMANTICS
endkm

kmod C is 
	including C-SEMANTICS 
endkm
