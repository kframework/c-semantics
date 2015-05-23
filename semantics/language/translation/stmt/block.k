module C-STMT-BLOCK
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYNTAX

     imports COMPAT-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.8.2}{2}}}{
     A \emph{compound statement} is a block.
     }*/
     rule BlockStatement(Block(Tag:BlockTag, _, B:K)) => Block(Tag, B)

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
          requires isHold(V)
     rule Computation(V:RValue) => .K
          requires notBool isHold(V)

     rule <k> Nop => .K ...</k>
          <elab>... .K => Nop </elab>

     // First block in a function.
     rule Block(Tag:BlockTag, _, list(Statements:List))
          => Block(Tag, list(Statements))

     rule Block(Tag:BlockTag, list(Statements:List))
          => pushBlock
          ~> enterBlock(Tag)
          ~> listToK(Statements)
          ~> exitBlock(Tag)
          ~> popBlock

     rule <k> enterBlock(Tag:BlockTag) => addToHistory(Tag) ...</k>
          <elab>... .K => enterBlock(Tag) </elab>
     rule <k> exitBlock(Tag:BlockTag) => .K ...</k>
          <elab>... .K => exitBlock(Tag) </elab>

endmodule
