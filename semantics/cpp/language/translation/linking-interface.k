module CPP-LINKING-INTERFACE
     imports K-REFLECTION
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports C-CONFIGURATION

     rule currentTranslationScope() => #currentTranslationScope(#configuration)

     syntax Scope ::= #currentTranslationScope(K) [function]

     rule #currentTranslationScope(<generatedTop>... <curr-tr-scope>S::Scope</curr-tr-scope> ...</generatedTop>) => S

     rule currentTranslationLoc() => #currentTranslationLoc(#configuration)

     syntax CabsLoc ::= #currentTranslationLoc(K) [function]

     rule #currentTranslationLoc(<generatedTop>... <curr-tr-program-loc>Loc::CabsLoc</curr-tr-program-loc> ...</generatedTop>) => Loc

     rule <k> setTranslationLoc(Loc::CabsLoc) => .K ... </k>
          <curr-tr-program-loc> _ => Loc </curr-tr-program-loc>

     rule <k> setTranslationUnit(TU::String) => .K ... </k>
          <curr-tr-tu> _ => TU </curr-tr-tu>

endmodule
