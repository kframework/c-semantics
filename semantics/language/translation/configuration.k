module C-CONFIGURATION
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TRANSLATION-INIT-SYNTAX
     imports COMPAT-SYNTAX

     configuration 
     <global>
          <mem> .Map </mem>

          <functions color="lightgray"> .Map </functions>

          <not-writable> .Set </not-writable>

          <main-tu color="lightgray"> .Set </main-tu>

          // Id |-> Type
          <external-types> .Map </external-types>
          // Id |-> Loc
          <external-defs> .Map </external-defs>

          <linking-state>
               // Id |-> Set(TUs)
               <external-decls> .Map </external-decls>
               // Ids
               <external-uses> SetItem(Identifier("main")) </external-uses>
          </linking-state>

          // dummy link loc |-> real loc
          <linkings> .Map </linkings>

          <translation-units>
               <tu multiplicity="*">
                    <tu-id> "" </tu-id>
                    <genv color="lightgray"> .Map </genv>
                    <gtypes color="lightgray"> .Map </gtypes>
                    <gstructs color="lightgray"> .Map </gstructs>

                    // kpair(Id, BlockNum) |-> SymLoc
                    <local-statics> .Map </local-statics>
                    // kpair(Id, BlockNum) |-> Type
                    <local-types> .Map </local-types>
                    // kpair(Id, BlockNum) |-> FieldInfo
                    <local-structs> .Map </local-structs>

                    <tu-linking-state>
                         <externals> .Map </externals>
                         <internals> .Map </internals>
                         <next-link-loc> .K </next-link-loc>
                         <next-static-loc> .K </next-static-loc>
                    </tu-linking-state>

                    <next-unnamed color="black"> 0 </next-unnamed>

                    <goto-map color="lightgray"> .Map </goto-map>
                    <string-lits color="lightgray"> .Map </string-lits>

                    // TODO(chathhorn): move.
                    <incomplete-tags> .Set </incomplete-tags>
               </tu>
          </translation-units>
     </global>
     <T multiplicity="?">
     <exec>
          <k color="green" multiplicity="?"> 
               loadObj(mergeObj(
                    unwrapObj($OBJ1:Bag), 
                    unwrapObj($OBJ2:Bag)))
               ~> $PGM:K 
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

               // Toggle to allow writes for initializers.
               <initializing> false </initializing>

               <control-details> // TODO(chathhorn): dumb name
                    <local>
                         // maps from Ids
                         <env color="red"> .Map </env>
                         <types color="lightgray"> .Map </types>
                         <structs color="lightgray"> .Map </structs>
                         <curr-block> 0 </curr-block>
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
