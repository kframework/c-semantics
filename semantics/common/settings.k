module SETTINGS-SYNTAX
     syntax Int ::= "cfg:bitsPerByte" [function]

     syntax Bool ::= "isErrorRecovery" [function]
                   | "hasLint" [function]
                   | "isErrorRecoveryAll" [function]

     syntax Semantics ::= currentSemantics() [function]
                        | CTranslation()
                        | CPPTranslation()
                        | Linking()
                        | ExecutionSemantics()
endmodule
