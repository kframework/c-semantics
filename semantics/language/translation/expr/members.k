module C-EXPR-MEMBERS
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> e(K:K, t(Mods:Set, structType(S:StructId))) . F:CId
               => e(K . F, addQualifiers(Mods, T))
          ...</k>
          <structs>... S |-> fieldInfo(_, _, F |-> T:Type _, _) ...</structs>

endmodule
