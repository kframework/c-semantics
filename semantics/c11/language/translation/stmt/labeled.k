module C-STMT-LABELED
     imports C-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-CONFIGURATION

     /*@ \fromStandard{\source[n1570]{\para{6.8.1}{4}}}{
     Any statement may be preceded by a prefix that declares an identifier as a
     label name. Labels in themselves do not alter the flow of control, which
     continues unimpeded across them.
     }*/

     rule (.K => elaborate(K)) ~> Label(_, K:K)
     rule <k> elaborateDone(K:K) ~> Label(L:CId, _) => .K ...</k>
          <elab>... .K => Label(L, K) </elab>

     context Case(_, _, (HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     rule (.K => elaborate(K)) ~> Case(_, _, _:RValue, K:K)
     rule <k> elaborateDone(K:K) ~> Case(SN:Int, CN:Int, Exp:RValue, _) => .K ...</k>
          <elab>... .K => Case(SN, CN, Exp, K) </elab>

     rule (.K => elaborate(K)) ~> Default(_, K:K)
     rule <k> elaborateDone(K:K) ~> Default(SN:Int, _) => .K ...</k>
          <elab>... .K => Default(SN, K) </elab>

endmodule
