module C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports C-LINKING-INIT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX

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
<exec>
     <k color="green">
          $PGM:K
          ~> load($OBJS:K)
          ~> link
          ~> cleanup
     </k>
     <curr-tu color="lightgray"> "" </curr-tu>
     <curr-eval-context color="lightgray"> eval </curr-eval-context>
     <curr-program-loc color="black">
          UnknownCabsLoc
     </curr-program-loc>
</exec>

<generated-annotations> .List </generated-annotations>

<previous-errors> .Set </previous-errors>

<options> $OPTIONS:Set </options>
</T>

endmodule
