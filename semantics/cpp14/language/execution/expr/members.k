module CPP-EXECUTION-EXPR-MEMBERS 
     imports C-CONFIGURATION
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXPR-MEMBERS-SYNTAX

     rule <k> This() => Obj ...</k>
          <this> Obj::Expr </this>

     rule <k> setThis(Obj:PRVal) => .K ...</k>
          <this> _ => Obj </this>

     rule contrivedObject(_) => noObject()
endmodule