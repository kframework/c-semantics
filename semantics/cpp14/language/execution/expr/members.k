module CPP-EXECUTION-EXPR-MEMBERS-SYNTAX
     imports CPP-SORTS
     syntax KItem ::= setThis(Expr) [strict]
endmodule

module CPP-EXECUTION-EXPR-MEMBERS 
     imports CPP-EXECUTION-EXPR-MEMBERS-SYNTAX
     imports C-CONFIGURATION
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule <k> This() => Obj ...</k>
          <this> Obj::Expr </this>

     rule <k> setThis(Obj:PRVal) => .K ...</k>
          <this> _ => Obj </this>
endmodule