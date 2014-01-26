module C-DECL-RESOLUTION-SYNTAX
     syntax K ::= "allocateIncompleteInternals"
     syntax K ::= "resolveReferences"
endmodule

module C-DECL-RESOLUTION
     imports C-DECL-RESOLUTION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-SYNTAX

     imports C-BUILTINS-SYNTAX

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
          <external-decls>...
               X:Id |-> set((SetItem(Tu:String) => .) _)
          ...</external-decls>
          <external-defs>...
               X |-> Loc:SymLoc
          ...</external-defs>
          <external-types>...
               X |-> T:Type
          ...</external-types>
          <tu-id> Tu </tu-id>
          <genv>...
               X |-> (_ => Loc)
          ...</genv>
          <gtypes>...
               X |-> (_ => T)
          ...</gtypes>

     // Resolve references to builtins by just ignoring them (but we go ahead
     // and add the complete type to every TU where it appears).
     rule <k> resolveReferences ...</k>
          <external-decls>...
               X:Id |-> set((SetItem(Tu:String) => .) _)
          ...</external-decls>
          <external-defs> Defs:Map </external-defs>
          <external-types>...
               X |-> T:Type
          ...</external-types>
          <tu-id> Tu </tu-id>
          <gtypes>...
               X |-> (_ => T)
          ...</gtypes>
          when (notBool X in keys Defs)
               andBool idToString(X) in builtins

     rule <k> resolveReferences ...</k>
          <external-decls>...
               (X:Id |-> set(.Set) => .)
          ...</external-decls>
          <external-defs>...
               (X |-> _ => .)
          ...</external-defs>
          <external-types>...
               (X |-> _ => .)
          ...</external-types>
          when X =/=K Identifier("main")

     rule <k> resolveReferences ...</k>
          <mainTU> . => MainTu </mainTU>
          <external-decls>...
               (Identifier("main") |-> set(.Set) => .)
          ...</external-decls>
          <external-defs>...
               (Identifier("main") |-> 
                    loc(_ @ static(MainTu:String), _, _) => .)
          ...</external-defs>
          <external-types>...
               (Identifier("main") |-> _ => .)
          ...</external-types>

     // Clean up builtins.
     rule <k> resolveReferences ...</k>
          <external-decls>...
               (X:Id |-> set(.Set) => .)
          ...</external-decls>
          <external-defs> Defs:Map </external-defs>
          <external-types>...
               (X |-> _ => .)
          ...</external-types>
          when notBool X in keys Defs

     // Now everything left in <external-decls> should be an unresolved
     // reference.
     
     rule <k> resolveReferences => . ...</k>
          (<linking-state>
               <external-decls> .Map </external-decls>
               <external-defs> .Map </external-defs>
               <external-types> .Map </external-types>
          </linking-state> => .Bag)

endmodule
