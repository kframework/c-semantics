module C-EXPR-ASSIGNMENT
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX

     rule lval(Loc:SymLoc, T:Type) := tv(V:KList, T)
               => write(lv(Loc, T), tv(V, T)) ~> tv(V, T)
          [structural]

endmodule
