module C-STMT-IF-THEN
     imports C-ELABORATOR-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule (.K => elaborate(TrueBr, FalseBr))
               ~> IfThenElse(_:RValue, TrueBr:K, FalseBr:K)
     rule <k> (elaborateDone(TrueBr:K, FalseBr:K) ~> IfThenElse(Cond:RValue, _, _))
               => .K
          ...</k>
          <elab>... .K => IfThenElse(Cond, TrueBr, FalseBr) </elab>

endmodule

