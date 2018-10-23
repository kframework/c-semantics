module COMMON-TRANSLATION-UNIT-SYNTAX
     imports STRING-SYNTAX
     imports SORT-K

     syntax Scope ::= currentTranslationScope() [function]
     syntax CabsLoc ::= currentTranslationLoc() [function]

     syntax KItem ::= setTranslationLoc(CabsLoc)
     syntax KItem ::= setTranslationUnit(String)

     syntax String ::= nameOfCurrentTranslationUnit() [function]
     syntax String ::= #nameOfCurrentTranslationUnit(K) [function]
     syntax K ::= getTranslationUnit(tu: String) [function]
     syntax K ::= getCurrentTranslationUnit() [function]

     syntax KItem ::= makeTu(String)

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

     rule <k> makeTu(TU:String) => setTranslationUnit(TU) ...</k>
          <translation-units>...
               (.Bag => <tu>...
                    <tu-id> TU </tu-id>
                    // without this line the tu-linking-state cell doesn't get created
                    // this is a bug in krun but I'm going with a temporary fix for now.
                    <externals> .Map </externals>
               ...</tu>)
          ...</translation-units>
          [structural]

endmodule
