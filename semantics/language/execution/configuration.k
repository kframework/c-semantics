module C-CONFIGURATION
     imports C-EXECUTION-INIT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SYMLOC-SYNTAX

     configuration
<global>
     <mem> .Map </mem>
     <functions color="lightgray"> .Map </functions>

     <main-tu color="lightgray"> .Set </main-tu>

     // CId |-> Type
     <external-types> .Map </external-types>
     // CId |-> SymBase
     <external-defs> .Map </external-defs>

     // placeholder from translation semantics
     <linking-state multiplicity="?"> .K </linking-state>

     <structs color="lightgray"> .Map </structs>

     // dummy link base |-> real base
     <linkings> .Map </linkings>

     <translation-units>
          <tu multiplicity="*" type="Set">
               <tu-id> "" </tu-id>
               <genv color="lightgray"> .Map </genv>
               <gtypes color="lightgray"> .Map </gtypes>

               // kpair(CId, Scope) |-> kpair(SymBase, Type)
               <local-statics> .Map </local-statics>

               // placeholder from translation semantics
               <tu-linking-state multiplicity="?"> .K </tu-linking-state>

               <next-unnamed color="black"> 0 </next-unnamed>

               <goto-map color="lightgray"> .Map </goto-map>

               // TODO(chathhorn): remove.
               <incomplete-tags> .Set </incomplete-tags>
          </tu>
     </translation-units>
</global>
<result-value color="red"> 139:CValue </result-value>
<T>
<exec multiplicity="?">
     // SymLoc |-> Type
     <effective-types> .Map </effective-types>

     // These are used for verifying the aliasing restrictions on
     // restrict-qualified pointers.
     // SymLoc |-> set(basedOns)
     <restrict> .Map </restrict>
     // Scope |-> activity(Int, SymLoc |-> Int)
     <activeBlocks> .Map </activeBlocks>

     // stdlib
     <malloced color="lightgray"> .Map </malloced>
     <next-malloced> 0 @ alloc </next-malloced>

     <next-thread-id color="black"> 1 </next-thread-id>

     <thread-info color="yellow">
          <thread-status color="yellow"> .Map </thread-status>
          <mutexes color="yellow"> .Map </mutexes>
          <glocks color="yellow"> .List </glocks>
     </thread-info>
     <threads color="yellow">
          <thread multiplicity="*" color="yellow" type="Set">
               <thread-id color="yellow"> 0 </thread-id>
               <buffer color="lightgray"> .List </buffer>

               <k color="green" multiplicity="?">
                    loadObj(unwrapObj($PGM:K))
                    ~> initMainThread
                    ~> pgmArgs($ARGV:List)
                    ~> callMain(size($ARGV:List), incomingArguments($ARGV:List))
               </k>
               <initializing> false </initializing>

               <duration color="black"> auto(0) </duration>
               <final-computation multiplicity="?" color="lightgray">
                    .K
               </final-computation>
               <thread-local>
                    // stack of "control" cells
                    <call-stack color="violet"> .List </call-stack>
                    <locks> .List </locks>
                    <control>
                         // general information
                         <curr-tu color="lightgray"> "" </curr-tu>
                         <curr-scope color="lightgray">
                              fileScope:Scope
                         </curr-scope>
                         // The identifiers that params are bound to. This
                         // is used for builtins and var-args.
                         <curr-function-params> .List </curr-function-params>
                         <curr-program-loc color="black">
                              UnknownCabsLoc
                         </curr-program-loc>

                         <control-details> // TODO(chathhorn): dumb name
                              // stack of "local" cells
                              <block-stack color="violet">
                                   .List
                              </block-stack>
                              <local>
                                   // maps from CIds
                                   <env color="red"> .Map </env>
                                   <types color="lightgray"> .Map </types>
                                   <compound-lit-map> .Map </compound-lit-map>

                                   // printf
                                   <formatting multiplicity="?">
                                        <format> .List </format>
                                        <format-arg> .K </format-arg>
                                        <format-result>
                                             .List
                                        </format-result>
                                        <format-state>
                                             "normal"
                                        </format-state>
                                        <format-mods>
                                             .Map
                                        </format-mods>
                                        <format-length> "" </format-length>
                                   </formatting>
                                   // information about the block we're in
                                   <nesting-depth color="lightgray">
                                        0
                                   </nesting-depth>
                                   <block-history color="lightgray">
                                        .List
                                   </block-history>
                                   // used to make sure we don't declare a
                                   // variable twice in the same scope
                                   <local-vars color="lightgray">
                                        .List
                                   </local-vars>
                                   // used to deallocate memory on leaving a
                                   // block
                                   <local-addresses color="lightgray">
                                        .Set
                                   </local-addresses>

                              </local>
                              // used to control initialization when gotoing
                              <should-init color="lightgray">
                                   true
                              </should-init>
                              <loop-stack color="violet">
                                   .List
                              </loop-stack>
                              <locs-written color="lightgray">
                                   .List
                              </locs-written>
                         </control-details>
                    </control>
               </thread-local>
          </thread>
     </threads>

     // TODO(chathhorn): not sure where to put these.
     <call-stack-frame multiplicity="?">
          <continuation> .K </continuation>
          <stack-curr-scope> .K </stack-curr-scope>
          <stack-curr-function-params> .List </stack-curr-function-params>
          <stack-curr-program-loc> .K </stack-curr-program-loc>
          <stack-curr-tu> .K </stack-curr-tu>
          <stack-control> .K </stack-control>
     </call-stack-frame>

     <thread-state multiplicity="?">
          <thread-continuation> .K </thread-continuation>
          <saved-thread-local> .K </saved-thread-local>
     </thread-state>

</exec>

<files color="lightgray">
     <file-commands> .K </file-commands>
     <file multiplicity="*" type="Set">
          <fid> .K </fid>
          <uri> .K </uri>
          <pos> 0 </pos>
          <mode> "r" </mode>
          <next-byte> .K </next-byte>
          <buff> "" </buff>
          <sending> .List </sending>
          <done> ListItem("") </done>
     </file>
</files>
<input color="lightgray"> .List </input>
<output color="lightgray"> .List </output>

<error-cell multiplicity="?" color="black"> .K </error-cell>

<previous-errors> .Set </previous-errors>

<status> initializing </status>

<options> $OPTIONS:Set </options>

</T>

endmodule
