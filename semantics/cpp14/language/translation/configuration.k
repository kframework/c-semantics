module C-CONFIGURATION
     imports MAP
     imports SET
     imports C-LINKING-INIT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports COMMON-CONFIGURATION

     configuration
<global />
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
          ~> builtinTu
          ~> load($OBJS:K)
          ~> link
          ~> cleanup
     </k>

     <elab> .K </elab>
     <elab-stack> .List </elab-stack>

     <deferred-class-actions> .K </deferred-class-actions>

     <curr-state>
         <curr-tu color="lightgray"> "" </curr-tu>
         <curr-lang-linkage> CPPLinkage </curr-lang-linkage>
         <curr-extern> false </curr-extern>
         <curr-scope> namespaceScope(GlobalNamespace()):Scope </curr-scope>
         <curr-eval-context color="lightgray"> eval </curr-eval-context>
         <curr-template-context> noTemplate </curr-template-context>
         <curr-program-loc color="black">
               UnknownCabsLoc
         </curr-program-loc>
         <curr-function> .K </curr-function>
     </curr-state>

     <block-stack color="violet"> .List </block-stack>
     <block-control>
          <env color="red"> .Map </env>
          <types color="lightgray"> .Map </types>
          // CId |-> Enum
          <enums> .Map </enums>
          <using-namespaces> .Set </using-namespaces>
          <block-history> .List </block-history>
          <this> .K </this>
     </block-control>

     <template-deduction> .Map </template-deduction>
     <template-arguments> .Map </template-arguments>
</exec>

<generated-annotations> .List </generated-annotations>

<options> $OPTIONS:Set </options>

<uuid> $UUID:String </uuid>

</T>

<json> $JSON:String </json>

endmodule
