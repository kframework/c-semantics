module FUNCTION-CALL-SYNTAX
     imports BASIC-K
     imports COMMON-SORTS
     imports COMPAT-SORTS
     imports SYMLOC-SORTS
     imports MEMORY-SORTS

     // syntax for function call regardless of language of caller
     syntax KItem ::= application(CabsLoc, SymBase, KItem, EffectiveType, LanguageLinkage, StrictList)
endmodule
