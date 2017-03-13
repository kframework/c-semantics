module COMMON-INIT-SYNTAX
     imports BASIC-K

     syntax KItem ::= loadObj(K)
     // this takes input from a file which is not split by thread, so we don't want to split this rule.
     syntax K ::= unwrapObj(K) [function, noThread]
endmodule

module COMMON-INIT
     imports COMMON-INIT-SYNTAX
     imports C-CONFIGURATION
     imports K-EQUAL

     rule <k> loadObj(G:GlobalCell) => .K ...</k>
          (<global> _ </global> => G)
          requires (G =/=K .K)
          [structural]

     rule loadObj(.K) => .K
          [structural]

     rule unwrapObj(<generatedTop>...
               <global> G::Bag </global>
          ...</generatedTop>)
          => <global> G </global>

     rule unwrapObj(.K) => .K

endmodule
