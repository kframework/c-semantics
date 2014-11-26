module C-STMT-GOTO
     imports C-SYNTAX
     imports COMPAT-SYNTAX

     syntax KItem ::= verifyGoto(K, CId)

     rule <k> Goto(Lbl:CId) => verifyGoto(K, Lbl) ...</k>
          <curr-function> F:CId </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               F |-> K:K
          ...</goto-map>
          [structural]
     rule verifyGoto(map(M:Map), Lbl:CId) => .K
          requires Lbl in keys(M)
          [structural]

endmodule
