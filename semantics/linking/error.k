module TRANSLATION-ERROR
     imports C-CONFIGURATION
     imports STRING
     imports K-IO
     imports ERROR-SYNTAX
     imports COMMON-LINKING-INTERFACE-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX

     rule <k> EXIT(E:ErrorMsg) => reportError(E, nameOfCurrentTranslationUnit(), currentTranslationScope(), currentTranslationLoc(), .Map, .K) ~> HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>

endmodule
