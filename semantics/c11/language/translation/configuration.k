module C-CONFIGURATION
     imports BOOL-SYNTAX
     imports INT-SYNTAX
     imports MAP
     imports SET
     imports COMMON-SYNTAX
     imports C-LINKING-INIT-SYNTAX
     imports COMMON-CONFIGURATION

     configuration
<global/>
<result-value color="red"> 1 </result-value>
<T multiplicity="?">
<exec>
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

<status> initializingTu </status>

<options> $OPTIONS:Set </options>

</T>

endmodule
