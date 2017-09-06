module C-CONFIGURATION
     imports BOOL-SYNTAX
     imports C-CONFIGURATION-EXTENSIONS
     imports C-EXECUTION-INIT-SYNTAX
     imports COMMON-CONFIGURATION
     imports COMMON-INIT-SYNTAX
     imports COMMON-SYNTAX
     imports INT-SYNTAX
     imports LIBC-IO-SYNTAX
     imports LIST
     imports MAP
     imports SET
     imports SYMLOC-SYNTAX

     configuration
<global/>
<result-value color="red" exit=""> 139:EffectiveValue </result-value>
<T>
<exec multiplicity="?">
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

               // Used for verifying the aliasing restrictions on
               // restrict-qualified pointers.
               <restrict> .List </restrict>

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

                         // this pointer
                         <this> .K </this>
                         // object being constructed
                         <constructing> .K </constructing>
                         // most derived class being constructed
                         <most-derived-class> .K </most-derived-class>

                         // stack of block-control cells
                         <block-stack color="violet"> .List </block-stack>
                         <block-control>
                              // maps from CIds
                              <env color="red"> .Map </env>
                              <renv color="red"> .Map </renv>
                              <types color="lightgray"> .Map </types>
                              <compound-lit-map> .Map </compound-lit-map>
                              <new-size-map> .Map </new-size-map>

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
                              // used to call destructors on leaving a block
                              <locally-constructed> .List </locally-constructed>
                              // used to store the catch handlers if this
                              // block is a try block in C++
                              <catch-handlers> .List </catch-handlers>
                              <current-exception> .K </current-exception>
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

                         <uncaught-exception> false </uncaught-exception>

                         // stdarg
                         <live-va-lists> .Set </live-va-lists>

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
                              <format-alt-form> false </format-alt-form>
                              <format-field-width> "" </format-field-width>
                              <format-length> "" </format-length>
                              <format-precision> "" </format-precision>
                              <format-matched> 0 </format-matched>
                              <format-nread> 0 </format-nread>
                              <format-item> "" </format-item>
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

<error-cell multiplicity="?" color="black"> .K </error-cell>

<status> initializingTu </status>

<options> $OPTIONS:Set </options>

<library>
     // stdlib.h support
     <malloced color="lightgray"> .Map </malloced>
     // Stderr is unbuffered by default, but it can be changed.
     <atexit> flush(#stdout) ~> flush(#stderr) </atexit>
     <at-quick-exit> .K </at-quick-exit>

     // stdarg.h support.
     <va-lists> .Map </va-lists>
     // setjmp.h support.
     <jmp-bufs> .Map </jmp-bufs>

     <open-files> .Set </open-files>

     <files color="lightgray">
          <file multiplicity="*" type="Set">
               <fid> .K </fid>
               <uri> .K </uri>
               <pos> 0 </pos>
               <mode> "r" </mode>
               <next-byte> .K </next-byte>
               <read-buffer> "" </read-buffer>
               <write-buffer> "" </write-buffer>
               <buffer-mode> fullBuf </buffer-mode>
               <buffer-size> bufSiz </buffer-size>
               <sending> .List </sending>
               <done> "" </done>
               <feof> false </feof>
               <ferror> 0 </ferror>
               <last-op> noLastOp </last-op>
          </file>
     </files>
     <input color="lightgray"> .List </input>
     <output color="lightgray"> .List </output>
</library>


</T>

<json> $JSON:String </json>

endmodule
