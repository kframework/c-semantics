module CPP-STMT-LABELED
     imports CPP-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports C-CONFIGURATION

     rule (.K => elaborate(listToK(L))) ~> LabelStmt(_, L::List)
     rule <k> elaborateDone(K:K) ~> LabelStmt(L:CId, _) => .K ...</k>
          <elab>... .K => LabelStmt(L, kSeqToList(K)) </elab>

endmodule
