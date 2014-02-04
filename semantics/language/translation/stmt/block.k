module C-STMT-BLOCK
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports COMPAT-SYNTAX

     rule BlockStatement(B:K)
          => pushBlock ~> B ~> popBlock
          [structural]
          
     rule [push-block]:
          <k> pushBlock => . ...</k>
          <local>
               C:Bag
          </local>
          <blockStack> 
               .List => ListItem(C)
          ...</blockStack>
          [structural, large] 
          
     rule [pop-block]:
          <k> popBlock => . ...</k>
          <local>
               (_ => C)
          </local>
          <blockStack>
               ListItem(C:Bag) => .List 
          ...</blockStack>
          [structural] 
          
     rule [expression-statement]:
          Computation(_:KResult) => .
          [structural]

     rule Nop => .
          [structural]
     
     rule [dissolve-block]:
          <k> Block(_, _, list(Statements:List))
               => listToK(Statements)
          ...</k>
          [structural]
endmodule
