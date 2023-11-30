module CPP-TRANSLATION-STMT-LOOP
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-ERROR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule ForTStmt(Decl::Stmt, Condition:Expr, Inc::Stmt, Blk::Stmt)
          => CompoundAStmt(ListItem(Decl) ListItem(ForTStmt(Condition, Inc, Blk)))

     context ForTStmt((HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]

     rule ForTStmt((Condition:PRVal => convertType(type(bool), Condition)), _Inc::Stmt, _Blk::Stmt)
          requires notBool isCPPBoolType(type(Condition))

     rule (.K => elaborate(Inc, Blk)) ~> ForTStmt(Condition:PRVal, Inc::Stmt, Blk::Stmt)
          requires isCPPBoolType(type(Condition))

     rule <k> elaborateDone(Inc:K, Blk:K)
              ~> ForTStmt(Condition::PRVal, _, _)
              => lintZero(Condition) ~> lintEmpty(Blk)
          ...</k>
          <elab>... .K => ForStmt(Condition, Inc, Blk) </elab>

     context WhileTStmt((HOLE:Expr => reval(HOLE)), _) [result(PRVal)]

     rule WhileTStmt((Condition:PRVal => convertType(type(bool), Condition)), _::Stmt)
          requires notBool isCPPBoolType(type(Condition))

     rule (.K => elaborate(Blk)) ~> WhileTStmt(Condition:PRVal, Blk::Stmt)
          requires isCPPBoolType(type(Condition))

     rule <k> elaborateDone(Blk:K)
              ~> WhileTStmt(Condition::PRVal, _)
              => lintZero(Condition) ~> lintEmpty(Blk)
          ...</k>
          <elab>... .K => WhileStmt(Condition, Blk) </elab>

     rule <k> TBreakStmt() => .K ...</k>
          <elab>... .K => BreakStmt() </elab>

endmodule
