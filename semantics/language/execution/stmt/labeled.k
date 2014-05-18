module C-STMT-LABELED
     imports C-SYNTAX
     /*@ \fromStandard{\source[n1570]{\para{6.8.1}{4}}}{
     Any statement may be preceded by a prefix that declares an identifier as a
     label name. Labels in themselves do not alter the flow of control, which
     continues unimpeded across them.
     }*/
     rule [skip-label]: 
          Label(_, K:K) => K
          [structural]
     rule [case-fall-through]:
          Case(_, _, _, K:K) => K
          [structural] 
     rule [default-fall-through]:
          Default(_, K:K) => K
          [structural] 
endmodule
