module CPP-STMT-TRY
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-ELABORATOR-SYNTAX

     rule (.K => elaborate(Try, listToK(Catch)))
          ~> TryStmt(Try::Stmt, Catch::List)
     rule <k> elaborateDone(Try:K, Catch:K) ~> TryStmt(_, _) => .K ...</k>
          <elab>... .K => TryStmt(Try, kSeqToList(Catch)) </elab>

     rule (.K => elaborate(S)) ~> CatchAnyStmt(S::Stmt)
     rule <k> elaborateDone(S:K) ~> CatchAnyStmt(_) => .K ...</k>
          <elab>... .K => CatchAnyStmt(S) </elab>

endmodule
