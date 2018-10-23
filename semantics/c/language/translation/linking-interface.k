module C-LINKING-INTERFACE
     imports K-REFLECTION
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports C-CONFIGURATION

     rule currentTranslationScope() => #currentTranslationScope(#configuration)
     syntax Scope ::= #currentTranslationScope(K) [function]
     rule #currentTranslationScope(<generatedTop>... <curr-scope>S::Scope</curr-scope> ...</generatedTop>) => S

     rule currentTranslationLoc() => #currentTranslationLoc(#configuration)
     syntax CabsLoc ::= #currentTranslationLoc(K) [function]
     rule #currentTranslationLoc(<generatedTop>... <curr-program-loc>Loc::CabsLoc</curr-program-loc> ...</generatedTop>) => Loc

     rule <k> setTranslationLoc(Loc::CabsLoc) => .K ... </k>
          <curr-program-loc> _ => Loc </curr-program-loc>

     rule <k> setTranslationUnit(TU::String) => .K ... </k>
          <curr-tu> _ => TU </curr-tu>

endmodule
