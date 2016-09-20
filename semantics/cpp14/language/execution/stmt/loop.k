module CPP-STMT-LOOP
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX

     rule <k> ForStmt(Control::Expr, Post::Stmt, S::Stmt) ~> K:K
              => loopMarked
              ~> ForStmt(Control, Post, S)
              ~> popLoop
          </k>
          <block-history> ListItem(Num::Int) ...</block-history>
          <loop-stack> .List => ListItem(kpair(Num, K)) ...</loop-stack>

     rule loopMarked ~> ForStmt(Control:Expr, Post::Stmt, S::Stmt)
          => IfStmt(Control, {S ~> Post ~> loopMarked
               ~> ForStmt(Control, Post, S)}:>Stmt, .K)

     rule <k> popLoop ~> _ => K </k>
          <block-history> ListItem(Num::Int) ...</block-history>
          <loop-stack> ListItem(kpair(Num, K:K)) => .List ...</loop-stack>

     rule <k> (.K => popBlock) ~> popLoop ...</k>
          <block-history> ListItem(Num::Int) ...</block-history>
          <loop-stack> ListItem(kpair(Num'::Int, _)) ...</loop-stack>
          requires Num' =/=Int Num

endmodule
