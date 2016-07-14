module CPP-STMT-BLOCK
     imports CPP-ENV-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports C-CONFIGURATION

     rule <k> popBlock => .K ...</k>
          <elab>... .K => popBlock </elab>

     rule <k> BlockStmt(Tag::Int, L::List)
              => scope(blockScope(F, Tag), listToK(L) ~> popBlock)
          ...</k>
          <curr-scope> blockScope(F::QualId, _) </curr-scope>
          <block-history> .List => ListItem(Tag) ...</block-history>
          <elab>... .K => pushBlock(Tag) </elab>

     rule CompoundStmt(L::List) => listToK(L)

endmodule
