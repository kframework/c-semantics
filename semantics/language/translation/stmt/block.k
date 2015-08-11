module C-STMT-BLOCK
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYNTAX

     imports C-CONFIGURATION

     /*@ \fromStandard{\source[n1570]{\para{6.8.2}{2}}}{
     A \emph{compound statement} is a block.
     }*/
     rule BlockStatement(Block(Tag:Int, _, B:K)) => Block(Tag, B)

     rule <k> pushBlock(Tag:Int) => addToHistory(Tag) ...</k>
          <elab>... .K => pushBlock(Tag) </elab>
          <curr-scope> blockScope(_, (_ => Tag)) </curr-scope>
          C:LocalCell
          <block-stack>
               .List => ListItem(C)
          ...</block-stack>

     rule <k> popBlock => .K ...</k>
          <elab>... .K => popBlock </elab>
          <curr-scope> blockScope(_, (_ => Tag)) </curr-scope>
          (<local>...
               <block-history> ListItem(Tag:Int) ...</block-history>
          ...</local> => C)
          <block-stack>
               ListItem(C:LocalCell) => .List
          ...</block-stack>

     rule <k> Nop => .K ...</k>
          <elab>... .K => Nop </elab>

     // First block in a function.
     rule Block(Tag:Int, _, list(Statements:List))
          => Block(Tag, list(Statements))

     rule Block(Tag:Int, list(Statements:List))
          => pushBlock(Tag)
          ~> listToK(Statements)
          ~> popBlock

endmodule
