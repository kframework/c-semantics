module CPP-LINKING-INTERFACE
     imports K-REFLECTION
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports C-CONFIGURATION

     rule [[ currentTranslationScope() => S ]]
          <curr-tr-scope>S::Scope</curr-tr-scope>

     rule [[ currentTranslationLoc() => Loc ]]
          <curr-tr-program-loc>Loc::CabsLoc</curr-tr-program-loc>

     rule <k> setTranslationLoc(Loc::CabsLoc) => .K ... </k>
          <curr-tr-program-loc> _ => Loc </curr-tr-program-loc>

     rule <k> setTranslationUnit(TU::String) => .K ... </k>
          <curr-tr-tu> _ => TU </curr-tr-tu>

endmodule
