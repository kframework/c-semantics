module CPP-STMT-TRY
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX

     rule TryStmt({pushBlock(Tag::Int) ~> Rest:K}:>Block, Catch::List)
          => pushBlock(Tag) ~> enterTryBlock(Catch) ~> Rest

     syntax KItem ::= enterTryBlock(List)

     rule <k> enterTryBlock(Catch::List) => .K ...</k>
          <catch-handlers> _ => Catch </catch-handlers>

endmodule
