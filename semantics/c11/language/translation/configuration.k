module C-CONFIGURATION
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-LINKING-INIT-SYNTAX
     imports COMPAT-SYNTAX

     configuration
<global>
     <mem> .Map </mem>
     <functions color="lightgray"> .Map </functions>

     <main-tu color="lightgray"> .Set </main-tu>

     <global-state>
          // CId |-> Types
          <external-types> .Map </external-types>
          // CId |-> Loc
          <external-defs> .Map </external-defs>
          // QualId |-> (Type |-> Loc)
          <odr-defs> .Map </odr-defs>
          // dummy link base |-> real base
          <linkings> .Map </linkings>
     </global-state>

     <linking-state multiplicity="?" initial="">
          // CId |-> Set(TUs)
          <external-decls> .Map </external-decls>
          // CIds
          <external-uses> .Set </external-uses>
          // SymBase |-> Set(ktriple(TU, QualId, Type))
          <odr-decls> .Map </odr-decls>
          // Set(SymBase)
          <odr-uses> .Set </odr-uses>
     </linking-state>

     <structs color="lightgray"> .Map </structs>

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

               // C++ stuff
               <namespaces>
                    <ns multiplicity="*" type="Map">
                         <ns-id> GlobalNamespace() </ns-id>
                         <nenv> .Map </nenv>
                         <using-namespaces> .Set </using-namespaces>
                         <inline-namespaces> .Set </inline-namespaces>
                    </ns>
               </namespaces>
          </tu>
     </translation-units>
</global>
<result-value color="red"> 1 </result-value>
<T multiplicity="?">
<exec>
     // SymLoc |-> Type
     <effective-types> .Map </effective-types>

     <final-computation multiplicity="?" color="lightgray">
          .K
     </final-computation>

     <goto-map-calc color="cyan">
          <goto-calc multiplicity="*" color="cyan" type="Set">
               <saved-env> .Map </saved-env>
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
     <k color="green">
          $PGM:K
          ~> builtinTu
          ~> reportSuccess
          ~> cleanup
     </k>

     <elab> .K </elab>

     <elab-stack> .List </elab-stack>

     // Toggle to allow writes and other special treatment
     // for initializers.
     <initializing> false </initializing>

     <curr-state>
          <curr-tu color="lightgray"> "" </curr-tu>
          <curr-function> .K </curr-function>
          <curr-scope color="lightgray"> fileScope:Scope </curr-scope>
          <curr-eval-context color="lightgray"> eval </curr-eval-context>
          <curr-program-loc color="black">
               UnknownCabsLoc
          </curr-program-loc>
     </curr-state>

     <block-stack color="violet"> .List </block-stack>
     <block-control>
          // maps from CIds
          <env color="red"> .Map </env>
          <types color="lightgray"> .Map </types>
          // Like the types cell, but used only for checking local declarations.
          <local-types> .Map </local-types>
          <enums> .Map </enums>
          <block-history> .List </block-history>
     </block-control>

     <init-calc multiplicity="?" initial="">
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

          // Holds the innermost type while we unroll the
          // type around it.
          <decl-type-holder color="cyan">
               .K
          </decl-type-holder>
     </init-calc>
</exec>

<error-cell multiplicity="?" color="black"> .K </error-cell>

<annotation> "" </annotation>

<generated-annotations> .List </generated-annotations>

<previous-errors> .Set </previous-errors>

<status> initializing </status>

<options> $OPTIONS:Set </options>

</T>

endmodule
