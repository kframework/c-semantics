module C-DECL-RESOLUTION-SYNTAX
     syntax K ::= "allocateIncompleteInternals"
     syntax K ::= "resolveReferences"
endmodule

module C-DECL-RESOLUTION
     imports C-DECL-RESOLUTION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     // TODO(chathhorn): actually do it.
     rule <k> allocateIncompleteInternals => . ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          (<tu-linking-state>... .Bag ...</tu-linking-state> => .Bag)

     // Add the real location at which an external reference is defined to the
     // environment of every TU where it appears.
     rule <k> resolveReferences ...</k>
          <external-uses>...
               SetItem(X:Id)
          ...</external-uses>
          <external-decls>...
               X |-> set((SetItem(Tu:String) => .) _)
          ...</external-decls>
          <external-defs>...
               X |-> Loc':SymLoc
          ...</external-defs>
          <external-types>...
               X |-> T:Type
          ...</external-types>
          <tu-id> Tu </tu-id>
          <genv>...
               X |-> (Loc:SymLoc => Loc')
          ...</genv>
          <gtypes>...
               X |-> (_ => T)
          ...</gtypes>
          <linkings>...
               (. => Loc |-> Loc')
          ...</linkings>

     rule <k> resolveReferences ...</k>
          <external-uses>...
               (SetItem(X:Id) => .)
          ...</external-uses>
          <external-decls>...
               (X:Id |-> set(.Set) => .Map)
          ...</external-decls>
          <external-defs>...
               (X |-> _ => .Map)
          ...</external-defs>
          <external-types>...
               (X |-> _ => .Map)
          ...</external-types>
          when X =/=K Identifier("main")

     rule <k> resolveReferences ...</k>
          <mainTU>... (.Set => SetItem(MainTu)) </mainTU>
          <external-uses>...
               (SetItem(Identifier("main")) => .Set)
          ...</external-uses>
          <external-decls>...
               (Identifier("main") |-> set(.Set) => .Map)
          ...</external-decls>
          <external-defs>...
               (Identifier("main") |-> 
                    loc(_ @ static(MainTu:String), _, _) => .Map)
          ...</external-defs>
          <external-types>...
               (Identifier("main") |-> _ => .Map)
          ...</external-types>

     // Now everything left in <external-uses> should be an unresolved
     // reference.
     
     rule <k> resolveReferences => .K ...</k>
          (<linking-state>...
               <external-uses> .Set </external-uses>
          ...</linking-state> => .Bag)

endmodule
