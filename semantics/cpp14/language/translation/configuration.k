module C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports C-LINKING-INIT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

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

     <goto-map-calc color="cyan">
          <goto-calc multiplicity="*" color="cyan" type="Set">
               <computation color="cyan"> .K </computation>
               <computation-tail color="cyan"> .K </computation-tail>
               <decl-stack color="cyan"> .List </decl-stack>
               <goto-nesting-depth color="cyan"> 0 </goto-nesting-depth>
               <goto-block-history color="cyan"> .List </goto-block-history>
               <goto-loop-stack color="cyan"> .List </goto-loop-stack>
          </goto-calc>
     </goto-map-calc>

     <k color="green">
          $PGM:K
          ~> load($OBJS:K)
          ~> link
          ~> cleanup
     </k>

     <elab> .K </elab>
     <elab-stack> .List </elab-stack>

     <curr-tu color="lightgray"> "" </curr-tu>
     <curr-lang-linkage> CPPLinkage </curr-lang-linkage>
     <curr-extern> false </curr-extern>
     <curr-scope> namespaceScope(GlobalNamespace()):Scope </curr-scope>
     <curr-eval-context color="lightgray"> eval </curr-eval-context>
     <curr-program-loc color="black">
          UnknownCabsLoc
     </curr-program-loc>
     <curr-function> .K </curr-function>

     <block-stack color="violet"> .List </block-stack>
     <block-control>
          <env color="red"> .Map </env>
          <block-history> .List </block-history>
     </block-control>
</exec>

<generated-annotations> .List </generated-annotations>

<previous-errors> .Set </previous-errors>

<options> $OPTIONS:Set </options>
</T>

endmodule
