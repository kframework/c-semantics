module CPP-TRANSLATION-STMT-LOOP
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-ERROR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule ForTStmt(Decl::Stmt, Condition:Expr, Inc::Stmt, Block::Stmt)
          => CompoundAStmt(ListItem(Decl) ListItem(ForTStmt(Condition, Inc, Block)))

     context ForTStmt((HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]
     rule ForTStmt((Condition:PRVal => convertType(type(bool), Condition)), Inc::Stmt, Block::Stmt)
          requires notBool isCPPBoolType(type(Condition))

     rule (.K => elaborate(Inc, Block)) ~> ForTStmt(Condition:PRVal, Inc::Stmt, Block::Stmt)
          requires isCPPBoolType(type(Condition))
     rule <k> elaborateDone(Inc:K, Block:K)
              ~> ForTStmt(Condition::PRVal, _, _)
              => lintZero(Condition) ~> lintEmpty(Block)
          ...</k>
          <elab>... .K => ForStmt(Condition, Inc, Block) </elab>

     context WhileTStmt((HOLE:Expr => reval(HOLE)), _) [result(PRVal)]
     rule WhileTStmt((Condition:PRVal => convertType(type(bool), Condition)), Block::Stmt)
          requires notBool isCPPBoolType(type(Condition))

     rule (.K => elaborate(Block)) ~> WhileTStmt(Condition:PRVal, Block::Stmt)
          requires isCPPBoolType(type(Condition))
     rule <k> elaborateDone(Block:K)
              ~> WhileTStmt(Condition::PRVal, _)
              => lintZero(Condition) ~> lintEmpty(Block)
          ...</k>
          <elab>... .K => WhileStmt(Condition, Block) </elab>

     rule <k> TBreakStmt() => .K ...</k>
          <elab>... .K => BreakStmt() </elab>

endmodule
