module C-STMT-LOOP
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-EXPR-LOGICAL-SYNTAX
     imports C-PROCESS-LABEL-SYNTAX
     imports C-SYNTAX

     imports C-CONFIGURATION

     rule For(Tag:Int, E1:K, E2:K, E3:K, B:K)
          => Block(Tag, list(ListItem(E1) ListItem(For(E2, E3, B))))

     // This is the first child of the for if it's not a declaration.
     rule ForClauseExpression(K:K) => Computation(K)

     context For((HOLE:KItem => reval(HOLE)), _, _) [result(RValue)]
     context For(_, (HOLE:KItem => reval(HOLE)), _) [result(RValue)]

     rule For(Control:RValue, Post:RValue, S:K)
          => #for(simplifyTruth(Control), Post, S)
          requires Control =/=K emptyValue
     rule For(emptyValue, Post:RValue, S:K)
          => #for(emptyValue, Post, S)

     syntax KItem ::= #for(K, RValue, K)
     context #for((HOLE:KItem => reval(HOLE)), _, _) [result(RValue)]

     rule (.K => elaborate(S)) ~> #for(_:RValue, _, S:K)
     rule <k> elaborateDone(S:K)
               ~> #for(Control:RValue, Post:RValue, _)
               => .K
          ...</k>
          <elab>... .K => For(compoundExp(L ~> Control), Post, S) </elab>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          requires Control =/=K emptyValue
     rule <k> elaborateDone(S:K)
               ~> #for(emptyValue, Post:RValue, _)
               => .K
          ...</k>
          <elab>... .K => For(emptyValue, Post, S) </elab>

     context While((HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     rule While(B:RValue, S:K) => #while(simplifyTruth(B), S)

     syntax KItem ::= #while(K, K)
     context #while((HOLE:KItem => reval(HOLE)), _) [result(RValue)]

     rule (.K => elaborate(S)) ~> #while(_:RValue, S:K)
     rule <k> elaborateDone(S:K) ~> #while(B:RValue, _) => .K ...</k>
          <elab>... .K => While(compoundExp(L ~> B), S) </elab>
          <curr-program-loc> L:CabsLoc </curr-program-loc>

     context DoWhile((HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     rule DoWhile(B:RValue, S:K) => #doWhile(simplifyTruth(B), S)

     syntax KItem ::= #doWhile(K, K)
     context #doWhile((HOLE:KItem => reval(HOLE)), _) [result(RValue)]

     rule (.K => elaborate(S)) ~> #doWhile(_:RValue, S:K)
     rule <k> elaborateDone(S:K) ~> #doWhile(B:RValue, _) => .K ...</k>
          <elab>... .K => DoWhile(compoundExp(L ~> B), S) </elab>
          <curr-program-loc> L:CabsLoc </curr-program-loc>

     rule <k> Continue => .K ...</k>
          <elab>... .K => Continue </elab>

endmodule
