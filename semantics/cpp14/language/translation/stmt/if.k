module CPP-STMT-IF
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-ERROR-SYNTAX
     imports CPP-TYPING-SYNTAX

     context IfStmt((HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]

     rule IfStmt((C:PRVal => convertType(type(bool), C)), TrueBr:Block, FalseBr:Block)
          requires notBool isCPPBoolType(type(C))

     rule (.K => elaborate(TrueBr, FalseBr))
          ~> IfStmt(C:PRVal, TrueBr:Block, FalseBr:Block)
          requires isCPPBoolType(type(C))

     rule <k> elaborateDone(TrueBr:K, FalseBr:K) ~> IfStmt(C:PRVal, _, _)
              => lintZero(C) ~> lintEmpty(TrueBr)
          ...</k>
          <elab>... .K => IfStmt(C, TrueBr, FalseBr) </elab>

endmodule
