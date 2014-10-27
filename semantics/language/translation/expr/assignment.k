module C-EXPR-ASSIGNMENT
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule nclv(Loc:SymLoc, T:Type) := tv(V:CValue, T)
          => write(Loc, V, T)
          ~> tv(V, T)
          [structural]

endmodule

