module CPP-STMT-LABELED
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-ELABORATOR-SYNTAX

     rule (.K => elaborate(listToK(L))) ~> LabelStmt(_, L::List)
     rule <k> elaborateDone(K:K) ~> LabelStmt(L:CId, _) => .K ...</k>
          <elab>... .K => LabelStmt(L, kSeqToList(K)) </elab>

endmodule
