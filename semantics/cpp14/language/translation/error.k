module CPP-TRANSLATION-ERROR-SYNTAX
     imports BASIC-K
     imports CPP-DYNAMIC-SORTS

     syntax K ::= lintZero(PRVal) [function]
                | lintEmpty(K) [function]

endmodule

module CPP-TRANSLATION-ERROR
     imports CPP-TRANSLATION-ERROR-SYNTAX
     imports BOOL
     imports SETTINGS-SYNTAX

     rule lintZero(_) => .K
          requires notBool hasLint
     rule lintEmpty(_) => .K
          requires notBool hasLint

endmodule
