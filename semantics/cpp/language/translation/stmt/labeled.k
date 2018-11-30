module CPP-TRANSLATION-STMT-LABELED
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule (.K => elaborate(listToK(L))) ~> TLabelStmt(_, L::List)

     rule <k> elaborateDone(K:K) ~> TLabelStmt(L:CId, _) => .K ...</k>
          <elab>... .K => LabelStmt(L, kSeqToList(K)) </elab>

endmodule
