module C-STMT-LOOP
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-EXPR-LOGICAL-SYNTAX
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

     rule For(Pre:RValue, Control:RValue, Post:RValue, S:K)
          => #for(Pre, simplifyTruth(Control), Post, S)
          requires Control =/=K emptyValue
     rule For(Pre:RValue, emptyValue, Post:RValue, S:K)
          => #for(Pre, emptyValue, Post, S)

     syntax KItem ::= #for(K, K, K, K)
     context #for(_, (HOLE => reval(HOLE)), _, _) [result(RValue)]

     rule (.K => elaborate(S)) ~> #for(_:RValue, _:RValue, _:RValue, S:K)
     rule <k> elaborateDone(S:K)
               ~> #for(Pre:RValue, Control:RValue, Post:RValue, _)
               => .K
          ...</k>
          <elab>... .K => For(Pre, Control, Post, S) </elab>

     context While((HOLE => reval(HOLE)), _) [result(RValue)]
     rule While(B:RValue, S:K) => #while(simplifyTruth(B), S)

     syntax KItem ::= #while(K, K)
     context #while((HOLE => reval(HOLE)), _) [result(RValue)]

     rule (.K => elaborate(S)) ~> #while(_:RValue, S:K)
     rule <k> elaborateDone(S:K) ~> #while(B:RValue, _) => .K ...</k>
          <elab>... .K => While(B, S) </elab>

     context DoWhile((HOLE => reval(HOLE)), _) [result(RValue)]
     rule DoWhile(B:RValue, S:K) => #doWhile(simplifyTruth(B), S)

     syntax KItem ::= #doWhile(K, K)
     context #doWhile((HOLE => reval(HOLE)), _) [result(RValue)]

     rule (.K => elaborate(S)) ~> #doWhile(_:RValue, S:K)
     rule <k> elaborateDone(S:K) ~> #doWhile(B:RValue, _) => .K ...</k>
          <elab>... .K => DoWhile(B, S) </elab>

     rule <k> Continue => .K ...</k>
          <elab>... .K => Continue </elab>

endmodule
