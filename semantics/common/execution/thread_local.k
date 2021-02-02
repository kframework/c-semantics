module COMMON-THREAD-LOCAL
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports LIST
  imports MAP
  imports SET
  imports STRING-SYNTAX
  imports COMMON-SYNTAX
  imports SYMLOC-SYNTAX

  configuration
  <thread-local>
       <buffer color="lightgray"> .List </buffer>
       <duration color="black"> auto(0) </duration>

       // Used for verifying the aliasing restrictions on
       // restrict-qualified pointers.
       <restrict> .List </restrict>

       <locks> .List </locks>
       <pthread-keys> .Map </pthread-keys>
       <pthread-active-keys> .Map </pthread-active-keys>
       // For detecting recursive calls.
       <called-functions> .Map </called-functions>
       // TODO(chathhorn, h0nzZik): not sure where to put these.
       <call-stack-frame multiplicity="?">
            <continuation> .K </continuation>
            <stack-function-control> .K </stack-function-control>
            <stack-lang-linkage> CLinkage </stack-lang-linkage>
       </call-stack-frame>

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
            <curr-expression-loc color="black">
                           .List  // Stack of CabsLoc, push and pop at the start.
            </curr-expression-loc>

            // this pointer
            // Why it is not in block-control? And why it is in block-control in translation?
            <this> .K </this>
            // object being constructed
            <constructing> .K </constructing>
            <constructing-history> .List </constructing-history>
            // most derived class being constructed
            <most-derived-class> .K </most-derived-class>

            <constructed-temporaries> .List </constructed-temporaries>
            <ret-constructed-temporary> .K </ret-constructed-temporary>

            // stack of block-control cells
            <block-stack color="violet"> .List </block-stack>
            <block-control>
                 // maps from CIds
                 <env color="red"> .Map </env>
                 <renv color="red"> .Map </renv>
                 <types color="lightgray"> .Map </types>
                 <new-size-map> .Map </new-size-map>

                 <block-history color="lightgray">
                                .List
                 </block-history>
                 // used to make sure we don't declare a
                 // variable twice in the same scope
                 <local-vars color="lightgray">
                                .Set
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

            // Used to catch potential stack size overflows.
            <stack-depth> 0 </stack-depth>

            <current-exception> .K </current-exception>
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

endmodule
