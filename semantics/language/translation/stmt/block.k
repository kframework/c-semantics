module C-STMT-BLOCK
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYNTAX

     imports COMPAT-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.8.2}{2}}}{
     A \emph{compound statement} is a block.
     }*/
     rule BlockStatement(B:K)
          => pushBlock ~> B ~> popBlock

     rule <k> pushBlock => .K ...</k>
          <elab>... .K => pushBlock </elab>
          <local> C:Bag </local>
          <block-stack>
               .List => ListItem(bag2K(C))
          ...</block-stack>

     rule <k> popBlock => .K ...</k>
          <elab>... .K => popBlock </elab>
          <local> _:Bag => C </local>
          <block-stack>
               ListItem(bag2K(C:Bag)) => .List
          ...</block-stack>

     rule <k> Computation(V:RValue) => .K ...</k>
          <elab>... .K => Computation(V) </elab>

     rule <k> Nop => .K ...</k>
          <elab>... .K => Nop </elab>

     rule Block(BlockNum:Int, _, list(Statements:List))
          => enterBlock(BlockNum)
          ~> listToK(Statements)
          ~> exitBlock(BlockNum)

     rule <k> enterBlock(BlockNum:Int) => addToHistory(BlockNum) ...</k>
          <elab>... .K => enterBlock(BlockNum) </elab>
     rule <k> exitBlock(BlockNum:Int) => .K ...</k>
          <elab>... .K => exitBlock(BlockNum) </elab>

endmodule
