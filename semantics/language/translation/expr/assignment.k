module C-EXPR-ASSIGNMENT
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule nclv(Loc:SymLoc, T:Type) := tv(V:CValue, T':Type)
          => write(Loc, V, T)
          ~> tv(V, T)
          requires T ==Type T'

     // TODO(chathhorn): check types and whatnot (2trans)
     rule e(L:K, T:Type) := e(R:K, _) => e(L := R, T)
     rule e(L:K, T:Type) := tv(V:CValue, T':Type) => e(L := tv(V, T'), T)
     rule nclv(Loc:SymLoc, T:Type) := e(R:K, _) => e(nclv(Loc, T) := R, T)

endmodule

