module C-TRANSLATION-ERROR-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax KItem ::= lintZero(RValue) [function]
                    | lintEmpty(K) [function]
endmodule

module C-TRANSLATION-ERROR
     imports C-TRANSLATION-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule lintZero(_) => .K
          requires notBool hasLint
     rule lintEmpty(_) => .K
          requires notBool hasLint

endmodule
