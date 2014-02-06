module C-EXPR-ASSIGNMENT
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX

     rule <k> lval(Loc:SymLoc, T:Type) := tv(V:CValue, T)
               => write(lv(Loc, T), tv(V, T)) ~> tv(V, T)
          ...</k>
          <initializing> true </initializing>
          [structural]

     rule <k> lval(_:SymLoc, T:Type) := tv(V:CValue, T)
               => tv(V, T)
          ...</k>
          <initializing> false </initializing>
          [structural]

endmodule

