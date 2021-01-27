module C-CONFIGURATION
     imports BOOL-SYNTAX
     imports COMMON-CONFIGURATION
     imports COMMON-SYNTAX
     imports DEFAULT-STRATEGY
     imports INT-SYNTAX
     imports MAP
     imports SET

     configuration
<global />
<s />
<result-value color="red" exit=""> 1 </result-value>
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
               <goto-block-history color="cyan">
                    .List
               </goto-block-history>
               <goto-loop-stack color="cyan">
                    .List
               </goto-loop-stack>
          </goto-calc>
     </goto-map-calc>
     <k color="green">
          initHardwareAddresses($HWADDR)
          ~> $PGM:K
          ~> reportSuccess
          ~> cleanup
     </k>

     <elab> .K </elab>

     <elab-stack> .List </elab-stack>

     <curr-state>
          <curr-tu color="lightgray"> "" </curr-tu>
          <curr-function> .K </curr-function>
          <curr-scope color="lightgray"> fileScope:Scope </curr-scope>
          <curr-eval-context color="lightgray"> eval </curr-eval-context>
          <curr-program-loc color="black">
               UnknownCabsLoc
          </curr-program-loc>
          <curr-expression-loc color="black">
               .List  // Stack of CabsLoc, push and pop at the start.
          </curr-expression-loc>
     </curr-state>

     <block-stack color="violet"> .List </block-stack>
     <block-control>
          // maps from CIds
          <env color="red"> .Map </env>
          <types color="lightgray"> .Map </types>
          // reverse environment
          <renv color="red"> .Map </renv>
          // Like the types cell, but used only for checking local declarations.
          <local-types> .Set </local-types>
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

     <do-not-record-linking-deps> false </do-not-record-linking-deps>
</exec>

<error-cell multiplicity="?" color="black"> .K </error-cell>

<annotation> "" </annotation>

<generated-annotations> .List </generated-annotations>

<status> initializingTu </status>

<options> $OPTIONS:Set </options>

<uuid> $UUID:String </uuid>

</T>

<json> $JSON:String </json>

endmodule
