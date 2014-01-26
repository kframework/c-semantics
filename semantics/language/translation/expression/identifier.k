module C-EXPRESSION-IDENTIFIER
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-DYNAMIC-SYNTAX

     rule [lookup-symbolic]:
          <k> X:Id => lv(symVal, T) ...</k>
          <env>  Env:Map </env>
          <types>... X |-> T:Type ...</types>
          when notBool (X in keys Env)
          [structural]
endmodule
