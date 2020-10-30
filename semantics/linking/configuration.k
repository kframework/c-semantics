module C-CONFIGURATION
     imports LINKING-INIT-SYNTAX
     imports COMMON-INIT-SYNTAX
     imports COMMON-CONFIGURATION
     imports DEFAULT-STRATEGY
     imports CPP-DYNAMIC-SYNTAX
     imports MAP
     imports SET

     configuration

<global />
<s />

<result-value color="red" exit=""> 1 </result-value>
<T multiplicity="?">

<exec>
     <k color="green">
          load($OBJS:KItem)
          ~> linkProgram(getEntryPoint($OPTIONS:Set))
          ~> cleanup
     </k>

     <elab> .K </elab>
     <elab-stack> .List </elab-stack>

     <curr-tr-tu color="lightgray"> "" </curr-tr-tu>
     <curr-lang-linkage> CPPLinkage </curr-lang-linkage>
     <curr-tr-scope> namespaceScope(GlobalNamespace()):Scope </curr-tr-scope>
     <curr-extern> false </curr-extern>
     <curr-template-context> noTemplate </curr-template-context>
     <curr-template-depth> 0 </curr-template-depth>
     <curr-tr-program-loc color="black"> UnknownCabsLoc </curr-tr-program-loc>
     <curr-function> .K </curr-function>

     <deferred-class-actions> .K </deferred-class-actions>

     <compile-time-evaluation> false </compile-time-evaluation>

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

     <thread-local>
          // TODO(chathhorn): clearly(?) the call stack should not be needed while linking.
          <call-stack-frame multiplicity="?">
               <continuation> .K </continuation>
               <stack-function-control> .K </stack-function-control>
               <stack-lang-linkage> CLinkage </stack-lang-linkage>
          </call-stack-frame>
          <call-stack color="violet"> .List </call-stack>

          <function-control>
               <curr-tu color="lightgray"> "" </curr-tu>
               <curr-scope color="lightgray"> none </curr-scope>
               <curr-program-loc color="black"> UnknownCabsLoc </curr-program-loc>
               <curr-eval-context color="lightgray"> eval </curr-eval-context>
          </function-control>
     </thread-local>
</exec>

<options> $OPTIONS:Set </options>

<uuid> $UUID:String </uuid>

</T>

<json> $JSON:String </json>

endmodule
