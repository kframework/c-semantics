module C-CONFIGURATION
     imports BOOL-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports MAP
     imports SET
     imports COMMON-INIT-SYNTAX
     imports COMMON-CONFIGURATION
     imports COMMON-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-EXECUTION-INIT-SYNTAX
     imports C-CONFIGURATION-EXTENSIONS

     configuration
<global/>
<result-value color="red"> 139:EffectiveValue </result-value>
<T>
<exec multiplicity="?">
     // These are used for verifying the aliasing restrictions on
     // restrict-qualified pointers.
     // SymLoc |-> set(basedOns)
     <restrict> .Map </restrict>
     // Scope |-> activity(Int, SymLoc |-> Int)
     <active-blocks> .Map </active-blocks>

     // stdlib.h support
     <malloced color="lightgray"> .Map </malloced>
     <next-malloced> 0 @ alloc </next-malloced>
     <atexit> .K </atexit>
     <at-quick-exit> .K </at-quick-exit>

     // stdarg.h support.
     <va-lists> .Map </va-lists>
     // setjmp.h support.
     <jmp-bufs> .Map </jmp-bufs>

     <extensions-global/>

     <next-thread-id color="black"> 1 </next-thread-id>

     <thread-info color="yellow">
          <thread-status color="yellow"> .Map </thread-status>
          <stack-depth> ListItem(0) </stack-depth>
          <mutexes color="yellow"> .Map </mutexes>
          <glocks color="yellow"> .Map </glocks>
     </thread-info>
     <threads color="yellow" thread="">
          <thread multiplicity="*" color="yellow" type="Map">
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
                    <locks> .List </locks>
                    // stack of function-control cells
                    <call-stack color="violet"> .List </call-stack>
                    <function-control>
                         // general information
                         <curr-tu color="lightgray"> "" </curr-tu>
                         <curr-scope color="lightgray">
                              none
                         </curr-scope>
                         // The identifiers that params are bound to. This
                         // is used for builtins and var-args.
                         <curr-function-params> .List </curr-function-params>
                         <curr-program-loc color="black">
                              UnknownCabsLoc
                         </curr-program-loc>

                         <live-va-lists> .Set </live-va-lists>

                         // stack of block-control cells
                         <block-stack color="violet"> .List </block-stack>
                         <block-control>
                              // maps from CIds
                              <env color="red"> .Map </env>
                              <types color="lightgray"> .Map </types>
                              <compound-lit-map> .Map </compound-lit-map>

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
                         </block-control>

                         // used to control initialization when gotoing
                         <should-init color="lightgray">
                              true
                         </should-init>
                         <loop-stack color="violet">
                              .List
                         </loop-stack>
                         <locs-written color="lightgray">
                              .Set
                         </locs-written>

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
                              <format-pad-zero> false </format-pad-zero>
                              <format-field-width> "" </format-field-width>
                              <format-length> "" </format-length>
                              <format-precision> "" </format-precision>
                         </formatting>
                    </function-control>
               </thread-local>
          </thread>
     </threads>

     // TODO(chathhorn): not sure where to put these.
     <call-stack-frame multiplicity="?">
          <continuation> .K </continuation>
          <stack-function-control> .K </stack-function-control>
          <stack-lang-linkage> CLinkage </stack-lang-linkage>
     </call-stack-frame>

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
          <done> "" </done>
     </file>
</files>
<input color="lightgray"> .List </input>
<output color="lightgray"> .List </output>

<error-cell multiplicity="?" color="black"> .K </error-cell>

<previous-errors> .Set </previous-errors>

<status> initializingTu </status>

<options> $OPTIONS:Set </options>

</T>

endmodule
