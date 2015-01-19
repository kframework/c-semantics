module C-CONFIGURATION
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TRANSLATION-INIT-SYNTAX
     imports COMPAT-SYNTAX

     configuration
<global>
     <mem> .Map </mem>
     <functions color="lightgray"> .Map </functions>

     <main-tu color="lightgray"> .Set </main-tu>

     // CId |-> Types
     <external-types> .Map </external-types>
     // CId |-> Loc
     <external-defs> .Map </external-defs>

     <linking-state>
          // CId |-> Set(TUs)
          <external-decls> .Map </external-decls>
          // CIds
          <external-uses> SetItem(Identifier("main")) </external-uses>
     </linking-state>

     // dummy link base |-> real base
     <linkings> .Map </linkings>

     <translation-units>
          <tu multiplicity="*">
               <tu-id> "" </tu-id>
               <genv color="lightgray"> .Map </genv>
               <gtypes color="lightgray"> .Map </gtypes>
               <gstructs color="lightgray"> .Map </gstructs>

               // kpair(CId, BlockNum) |-> SymBase
               <local-statics> .Map </local-statics>
               // kpair(CId, BlockNum) |-> Type
               <local-types> .Map </local-types>
               // kpair(CId, BlockNum) |-> FieldInfo
               <local-structs> .Map </local-structs>

               <tu-linking-state>
                    <externals> .Map </externals>
                    <internals> .Map </internals>
                    <next-link-loc> .K </next-link-loc>
                    <next-static-loc> .K </next-static-loc>
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
     // SymLoc |-> Type
     <effective-types> .Map </effective-types>

     <k color="green" multiplicity="?">
          $PGM:K
          ~> load(unwrapObj($OBJ1:Bag), unwrapObj($OBJ2:Bag))
          ~> link
          ~> cleanup
     </k>

     <final-computation multiplicity="?" color="lightgray">
          .K
     </final-computation>

     <goto-map-calc color="cyan">
          <goto-calc multiplicity="*" color="cyan">
               <computation color="cyan"> .K </computation>
               <computation-tail color="cyan">
                    .K
               </computation-tail>
               <decl-stack color="cyan">
                    .List
               </decl-stack>
               <goto-nesting-depth color="cyan">
                    0
               </goto-nesting-depth>
               <goto-block-history color="cyan">
                    .List
               </goto-block-history>
               <goto-loop-stack color="cyan">
                    .List
               </goto-loop-stack>
          </goto-calc>
     </goto-map-calc>
     <control>
          <curr-tu color="lightgray"> "" </curr-tu>
          <curr-function color="lightgray">
               file-scope
          </curr-function>
          <curr-program-loc color="black">
               UnknownCabsLoc
          </curr-program-loc>

          // Toggle to allow writes and other special treatment for
          // initializers.
          <initializing> 0 </initializing>

          <control-details> // TODO(chathhorn): dumb name
               <local>
                    // maps from CIds
                    <env color="red"> .Map </env>
                    <types color="lightgray"> .Map </types>
                    <structs color="lightgray"> .Map </structs>
                    <block-history> .List </block-history>
               </local>
               <block-stack color="violet"> .List </block-stack>

               // Used to figure initializers.
               <curr-object color="cyan">
                    .List
               </curr-object>
               <curr-subobject color="cyan">
                    .List
               </curr-subobject>
               <incomplete-length color="cyan">
                    0
               </incomplete-length>
               <saved-init color="cyan">
                    .K
               </saved-init>

               // Used for typing expressions.
               <type multiplicity="?" color="cyan"> .K </type>
               // Holds the innermost type while we unroll the
               // type around it.
               <decl-type-holder color="cyan">
                    .K
               </decl-type-holder>
          </control-details>
     </control>

</exec>

<error-cell multiplicity="?" color="black"> .K </error-cell>

<status> initializing </status>

<options> $OPTIONS:Set </options>

</T>

endmodule
