module COMMON-TRANSLATION-UNIT-SYNTAX
     imports STRING-SYNTAX
     imports SORT-K

    syntax String ::= nameOfCurrentTranslationUnit() [function]
    syntax String ::= #nameOfCurrentTranslationUnit(K) [function]
    syntax K ::= getTranslationUnit(tu: String) [function]
    syntax K ::= getCurrentTranslationUnit() [function]

endmodule


module COMMON-TRANSLATION-UNIT
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports K-REFLECTION
     imports C-CONFIGURATION

     rule getCurrentTranslationUnit() => getTranslationUnit(nameOfCurrentTranslationUnit())
     rule nameOfCurrentTranslationUnit() => #nameOfCurrentTranslationUnit(#configuration)

     rule getTranslationUnit(TU::String)
          => #getTranslationUnit(TU, #configuration)
     syntax K ::= #getTranslationUnit(String, K) [function]

     rule #getTranslationUnit(TU::String, <generatedTop>... <tu> <tu-id> TU </tu-id> B::Bag </tu> ...</generatedTop>)
          => <tu> <tu-id> TU </tu-id> B </tu>

endmodule
