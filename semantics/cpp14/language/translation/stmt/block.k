module CPP-STMT-BLOCK
     imports C-CONFIGURATION
     imports CPP-ENV-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX

     rule <k> pushBlock(Tag::Int) => pushLocals ...</k>
          <curr-scope> blockScope(_, _, (_ => Tag)) </curr-scope>
          <block-history> .List => ListItem(Tag) ...</block-history>
          <elab>... .K => pushBlock(Tag) </elab>
     rule <k> popBlock => popLocals ~> setScope(blockScope(F, Base, Tag)) ...</k>
          <curr-scope> blockScope(F::QualId, Base::SymBase, _) </curr-scope>
          <block-history> (ListItem(_) => .List) ListItem(Tag::Int) ...</block-history>
          <elab>... .K => popBlock </elab>
     rule <k> popBlock => popLocals ~> setScope(blockScope(F, Base, 0)) ...</k>
          <curr-scope> blockScope(F::QualId, Base::SymBase, _) </curr-scope>
          <block-history> (ListItem(_) => .List) </block-history>
          <elab>... .K => popBlock </elab>

     rule BlockStmt(Tag::Int, L::List) => pushBlock(Tag) ~> listToK(L) ~> popBlock

endmodule
