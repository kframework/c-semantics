module COMMON-LINKING-INTERFACE-SYNTAX
     imports COMMON-SORTS
     imports STRING-SYNTAX
     
     syntax Scope ::= currentTranslationScope() [function]
     syntax CabsLoc ::= currentTranslationLoc() [function]

     syntax KItem ::= setTranslationLoc(CabsLoc)
     syntax KItem ::= setTranslationUnit(String)
endmodule
