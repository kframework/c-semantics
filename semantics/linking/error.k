module LINKING-ERROR
     imports C-CONFIGURATION
     imports STRING
     imports K-IO
     imports ERROR-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX

     rule EXIT(E:ErrorMsg)
          => reportError(E, nameOfCurrentTranslationUnit(), currentTranslationScope(), currentTranslationLoc(), .Map, .K)
          ~> HALT

endmodule
