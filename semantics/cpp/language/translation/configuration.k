module C-CONFIGURATION
     imports COMMON-CONFIGURATION
     imports COMMON-THREAD-LOCAL
     imports CPP-DYNAMIC-SYNTAX
     imports DEFAULT-STRATEGY
     imports MAP
     imports SET

     configuration
<global />
<s />
<result-value color="red" exit=""> 1 </result-value>
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
          ~> reportSuccess
          ~> cleanup
     </k>

     <elab> .K </elab>
     <elab-stack> .List </elab-stack>

     <deferred-class-actions> .K </deferred-class-actions>

     <compile-time-evaluation> false </compile-time-evaluation>
     <thread-local />

     <curr-state>
         <curr-tr-tu color="lightgray"> "" </curr-tr-tu>
         <curr-lang-linkage> CPPLinkage </curr-lang-linkage>
         <curr-extern> false </curr-extern>
         <curr-tr-scope> namespaceScope(GlobalNamespace()):Scope </curr-tr-scope>
         <curr-eval-context color="lightgray"> eval </curr-eval-context>
         <curr-template-context> noTemplate </curr-template-context>
         <curr-template-depth> 0 </curr-template-depth>
         <curr-tr-program-loc color="black">
               UnknownCabsLoc
         </curr-tr-program-loc>
         <curr-function> .K </curr-function>
     </curr-state>

     <tr-block-stack color="violet"> .List </tr-block-stack>
     <tr-block-control>
          <tr-env color="red"> .Map </tr-env>
          <tr-types color="lightgray"> .Map </tr-types>
          // CId |-> Enum
          <enums> .Map </enums>
          <using-namespaces> .Set </using-namespaces>
          <tr-block-history> .List </tr-block-history>
          <tr-this> .K </tr-this>
     </tr-block-control>

     <template-deduction> .Map </template-deduction>
     <template-arguments> .Map </template-arguments>
</exec>

<generated-annotations> .List </generated-annotations>

<options> $OPTIONS:Set </options>

<uuid> $UUID:String </uuid>

</T>

<json> $JSON:String </json>

endmodule
