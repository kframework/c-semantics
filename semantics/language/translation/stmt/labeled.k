module C-STMT-LABELED
     imports C-SYNTAX

     rule [skip-label]: 
          Label(_, K:K) => K
          [structural]
     rule [case-fall-through]:
          Case(_, _, Exp:K, Stmt:K) => Computation(Exp) ~> Stmt
          [structural] 
     rule [default-fall-through]:
          Default(_, K:K) => K
          [structural] 
endmodule
