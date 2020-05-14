module CPP-EXECUTION-STMT-LOOP
     imports C-CONFIGURATION
     imports INT
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX

     rule <k> ForStmt(Control::Expr, Post::K, S::K) ~> K:K
              => loopMarked
              ~> ForStmt(Control, Post, S)
              ~> popLoop
          </k>
          <block-history> ListItem(Num::Int) ...</block-history>
          <loop-stack> .List => ListItem(kpair(Num, K)) ...</loop-stack>

     rule loopMarked ~> ForStmt(Control:Expr, Post::K, S::K)
          => IfStmt(Control, compoundStmt(S, compoundStmt(Post, compoundStmt(loopMarked,
              ForStmt(Control, Post, S)))), nullStmt())

     rule <k> WhileStmt(Control::Expr, S::Stmt) ~> K:K
              => loopMarked
              ~> WhileStmt(Control, S)
              ~> popLoop
          </k>
          <block-history> ListItem(Num::Int) ...</block-history>
          <loop-stack> .List => ListItem(kpair(Num, K)) ...</loop-stack>

     rule loopMarked ~> WhileStmt(Control:Expr, S::K)
          => IfStmt(Control, compoundStmt(S, compoundStmt(loopMarked,
               WhileStmt(Control, S))), nullStmt())

     rule <k> popLoop ~> _ => K </k>
          <block-history> ListItem(Num::Int) ...</block-history>
          <loop-stack> ListItem(kpair(Num, K:K)) => .List ...</loop-stack>

     rule <k> (.K => popBlock(false)) ~> popLoop ...</k>
          <block-history> ListItem(Num::Int) ...</block-history>
          <loop-stack> ListItem(kpair(Num'::Int, _)) ...</loop-stack>
          requires Num' =/=Int Num

     rule BreakStmt() => popLoop

endmodule
