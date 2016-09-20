module CPP-STMT-LOOP
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-ERROR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule ForStmt(Decl::Stmt, Condition:Expr, Inc::Stmt, Block::Stmt)
          => CompoundAStmt(ListItem(Decl) ListItem(ForStmt(Condition, Inc, Block)))

     context ForStmt((HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]
     rule ForStmt((Condition:PRVal => convertType(type(bool), Condition)), Inc::Stmt, Block::Stmt)
          requires notBool isCPPBoolType(type(Condition))

     rule (.K => elaborate(Inc, Block)) ~> ForStmt(Condition:PRVal, Inc::Stmt, Block::Stmt)
          requires isCPPBoolType(type(Condition))
     rule <k> elaborateDone(Inc:K, Block:K)
              ~> ForStmt(Condition::PRVal, _, _)
              => lintZero(Condition) ~> lintEmpty(Block)
          ...</k>
          <elab>... .K => ForStmt(Condition, Inc, Block) </elab>

endmodule
