module C-STMT-LOOP
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-PROCESS-LABEL-SYNTAX
     imports C-SYNTAX

     imports COMPAT-SYNTAX

     rule For(Tag:BlockTag, E1:K, E2:K, E3:K, B:K)
          => Block(Tag, list(ListItem(For(E1, E2, E3, B))))

     rule ForClauseExpression(K:K) => K
          requires K =/=K .K
     rule ForClauseExpression(.K) => voidVal

     context For((HOLE => reval(HOLE)), _, _, _) [result(RValue)]
     context For(_, (HOLE => reval(HOLE)), _, _) [result(RValue)]
     context For(_, _, (HOLE => reval(HOLE)), _) [result(RValue)]
     rule (.K => elaborate(S)) ~> For(_:RValue, _:RValue, _:RValue, S:K)
     rule <k> elaborateDone(S:K)
               ~> For(Pre:RValue, Control:RValue, Post:RValue, _)
               => .K
          ...</k>
          <elab>... .K => For(Pre, Control, Post, S) </elab>

     context While((HOLE => reval(HOLE)), _) [result(RValue)]
     rule (.K => elaborate(S)) ~> While(_:RValue, S:K)
     rule <k> elaborateDone(S:K) ~> While(B:RValue, _) => .K ...</k>
          <elab>... .K => While(B, S) </elab>

     context DoWhile((HOLE => reval(HOLE)), _) [result(RValue)]
     rule (.K => elaborate(S)) ~> DoWhile(_:RValue, S:K)
     rule <k> elaborateDone(S:K) ~> DoWhile(B:RValue, _) => .K ...</k>
          <elab>... .K => DoWhile(B, S) </elab>

     rule <k> Continue => .K ...</k>
          <elab>... .K => Continue </elab>

endmodule
