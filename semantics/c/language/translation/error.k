module C-TRANSLATION-ERROR-SYNTAX
     imports BASIC-K
     imports C-DYNAMIC-SORTS

     syntax K ::= lintZero(RValue) [function]
                | lintEmpty(K) [function]
endmodule

module C-TRANSLATION-ERROR
     imports C-TRANSLATION-ERROR-SYNTAX
     imports BOOL
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports ERROR-SYNTAX
     imports SETTINGS-SYNTAX

     rule lintZero(_) => .K
          requires notBool hasLint
     rule lintEmpty(_) => .K
          requires notBool hasLint

     rule EXIT(E:ErrorMsg)
          => reportError(E, nameOfCurrentTranslationUnit(), currentTranslationScope(), currentTranslationLoc(), .Map, .K)
          ~> HALT

endmodule
