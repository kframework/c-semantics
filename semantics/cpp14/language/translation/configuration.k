module CPP-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports SET
     imports MAP
     imports STRING
     imports INT

     configuration
<global>
     <mem> .Map </mem>
     <functions color="lightgray"> .Map </functions>

     <main-tu color="lightgray"> .Set </main-tu>

     // CId |-> Types
     <external-types> .Map </external-types>
     // CId |-> Loc
     <external-defs> .Map </external-defs>

     <linking-state multiplicity="?" initial="">
          // CId |-> Set(TUs)
          <external-decls> .Map </external-decls>
          // CIds
          <external-uses> SetItem(Identifier("main")) </external-uses>
     </linking-state>

     <structs color="lightgray"> .Map </structs>

     // dummy link base |-> real base
     <linkings> .Map </linkings>

     <translation-units>
          <tu multiplicity="*" type="Map">
               <tu-id> "" </tu-id>
               <genv color="lightgray"> .Map </genv>
               <gtypes color="lightgray"> .Map </gtypes>

               // kpair(CId, Scope) |-> kpair(SymBase, Type)
               <local-statics> .Map </local-statics>

               <tu-linking-state multiplicity="?" initial="">
                    <externals> .Map </externals>
                    <internals> .Map </internals>
                    <next-link-loc> .K </next-link-loc>
                    <next-static-loc> .K </next-static-loc>
                    <uses> SetItem(Identifier("main")) </uses>
                    <genums> .Map </genums>
               </tu-linking-state>

               <next-unnamed color="black"> 0 </next-unnamed>

               <goto-map color="lightgray"> .Map </goto-map>

               // TODO(chathhorn): move.
               <incomplete-tags> .Set </incomplete-tags>
          </tu>
     </translation-units>
</global>
<result-value color="red"> 1 </result-value>
<T multiplicity="?">
<k> $PGM:K </k>
</T>

endmodule
