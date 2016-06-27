module COMMON-INIT-SYNTAX
     imports BASIC-K

     syntax KItem ::= loadObj(K)
     syntax K ::= unwrapObj(K) [function]
endmodule

module COMMON-INIT
     imports COMMON-INIT-SYNTAX
     imports C-CONFIGURATION

     rule <k> loadObj(G:GlobalCell) => .K ...</k>
          (<global> _ </global> => G)
          requires (G =/=K .K)
          [structural]

     rule loadObj(.K) => .K
          [structural]

     rule unwrapObj(<generatedTop>...
               <global> G:Bag </global>
          ...</generatedTop>)
          => <global> G </global>

     rule unwrapObj(.K) => .K

endmodule
