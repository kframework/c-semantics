module CPP-TRANSLATION-STMT-IF
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-ERROR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule IfTStmt((C:PRVal => convertType(type(bool), C)), _TrueBr:Block, _FalseBr:Block)
          requires notBool isCPPBoolType(type(C))

     rule (.K => elaborate(TrueBr, FalseBr))
          ~> IfTStmt(C:PRVal, TrueBr:Block, FalseBr:Block)
          requires isCPPBoolType(type(C))

     rule <k> elaborateDone(TrueBr:K, FalseBr:K) ~> IfTStmt(C:PRVal, _, _)
              => lintZero(C) ~> lintEmpty(TrueBr)
          ...</k>
          <elab>... .K => IfStmt(C, TrueBr, FalseBr) </elab>

endmodule
