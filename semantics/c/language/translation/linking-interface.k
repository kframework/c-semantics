module C-LINKING-INTERFACE
     imports K-REFLECTION
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports C-CONFIGURATION
     imports C-ERROR-SYNTAX

     rule [[ currentTranslationScope() => S ]]
          <curr-scope>S::Scope</curr-scope>

     rule [[ currentTranslationLoc() => Loc ]]
          <curr-program-loc> Loc::CabsLoc </curr-program-loc>
          <curr-expression-loc> .List </curr-expression-loc>
     rule [[ currentTranslationLoc() => fixLocSystemHeader(ExprLoc, FileLoc) ]]
          <curr-program-loc> FileLoc::CabsLoc </curr-program-loc>
          <curr-expression-loc> ListItem(ExprLoc::CabsLoc) ...</curr-expression-loc>

     rule <k> setTranslationLoc(Loc::CabsLoc) => .K ... </k>
          <curr-program-loc> _ => Loc </curr-program-loc>

     rule <k> setTranslationUnit(TU::String) => .K ... </k>
          <curr-tu> _ => TU </curr-tu>

endmodule
