module C-EXPR-ASSIGNMENT
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX

     // TODO(chathhorn): it would be nice to just limit this to "initializers
     // of objects with static storage class," but we can't do that yet.
     rule <k> lval(Loc:SymLoc, T:Type) := tv(V:CValue, T)
               => write(lv(Loc, T), tv(V, T)) ~> tv(V, T)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          [structural]

     rule <k> lval(_:SymLoc, T:Type) := tv(V:CValue, T)
               => tv(V, T)
          ...</k>
          <currentFunction> F:Id </currentFunction>
          when F =/=K file-scope
          [structural]

endmodule

