module C-STMT-LOOP
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX
     
     rule ForClauseExpression(K:K) => Computation(K) [structural]

     rule [for]:
          <k> For(BlockNum:Int, Pre:K, Control:K, Post:K, S:K)
               => pushBlock 
               ~> Pre
               ~> Computation(Control)
               ~> S ~> Computation(Post)
               ~> popBlock
          ...</k>
          <current-block> _ => BlockNum </current-block>
          [structural] 
          
     rule [while]:
          While(B:K, S:K)
          => Computation(B)
          ~> S
          [structural] 
     
     rule [do-while-mark]:
          DoWhile(B:K, S:K)
          => S
          ~> Computation(B)
          [structural] 

     rule [continue]:
          Continue => .
          [structural]
          
endmodule
