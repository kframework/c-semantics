module C-CONFIGURATION
     imports C-EXECUTION-INIT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     configuration 
     <T>
     <exec>
          <global>
               <gstructs color="lightgray"> .Map </gstructs>
               <stringLiterals color="lightgray"> .Map </stringLiterals>

               <mem> .Map </mem>

               <mainTU color="lightgray"> .K </mainTU>
               <freshUnnamed color="black"> 0 </freshUnnamed>
               <functions color="lightgray"> .Map </functions>
               <notWritable> .Map </notWritable>
               <externalLocations color="cyan"> .Map </externalLocations>

               <translation-units>
                    <tu multiplicity="*">
                         <tu-id> .K </tu-id>
                         <genv color="lightgray"> .Map </genv>
                         <gtypes color="lightgray"> .Map </gtypes>
                         <externals> .Map </externals>
                         <internals> .Map </internals>
                         // dummy link loc |-> real loc
                         <linkings> .Map </linkings> 
                         // TODO(chathhorn): consider combining.
                         <next-link-loc> .K </next-link-loc>
                         <next-static-loc> .K </next-static-loc>

                         <goto-map color="lightgray"> .Map </goto-map>
                    </tu>
               </translation-units>
          </global>

          // stdlib
          <randNat color="black"> 0 </randNat>
          // stdlib
          <malloced color="lightgray"> .Map </malloced>
          <nextMalloced> 0 </nextMalloced>

          <nextThreadId color="black"> 0 </nextThreadId>
          <internalLocations color="cyan"> .Map </internalLocations>

          <threadInformation color="yellow">
               <threadStatus color="yellow"> .Map </threadStatus>
               <mutexes color="yellow"> .Map </mutexes>
               <glocks color="yellow"> .Bag </glocks>
          </threadInformation>
          <compoundLiteralMap> .Map </compoundLiteralMap>
          <threads color="yellow">
               <thread multiplicity="*" color="yellow">
                    <threadId color="yellow"> 0 </threadId>
                    <buffer color="lightgray"> .List </buffer>

                    <k color="green" multiplicity="?"> 
                         loadConfig($PGM:Bag)
                         ~> initMainThread
                         ~> pgmArgs($ARGV:KList) 
                         ~> callMain($ARGC:Int, incomingArguments($ARGV:KList))
                    </k>

                    <nextLoc color="black"> 0 </nextLoc>
                    <finalComputation multiplicity="?" color="lightgray">
                         .K
                    </finalComputation>
                    <threadLocal>
                         // stack of "control" cells
                         <callStack color="violet"> .List </callStack>
                         <locks> .Bag </locks>
                         <control>
                              // general information
                              <currTU color="lightgray"> "" </currTU>
                              <currentFunction color="lightgray">
                                   .K
                              </currentFunction>
                              <currentProgramLoc color="black">
                                   .K
                              </currentProgramLoc>

                              <controlDetails> // TODO(chathhorn): dumb name
                                   // stack of "local" cells
                                   <blockStack color="violet"> .List </blockStack>
                                   <local>
                                        // maps from Ids
                                        <env color="red"> .Map </env>
                                        <types color="lightgray"> .Map </types>
                                        <structs color="lightgray"> .Map </structs>



                                        // printf
                                        <formatting multiplicity="?">
                                             <format> .List </format>
                                             <formatArg> .K </formatArg>
                                             <formatResult> .List </formatResult>
                                             <formatState> "normal" </formatState>
                                             <formatModifiers>
                                                  .Map
                                             </formatModifiers>
                                             <formatLength> "" </formatLength>
                                        </formatting>
                                        // information about the block we're in
                                        <nestingDepth color="lightgray">
                                             0
                                        </nestingDepth>
                                        <blockHistory color="lightgray">
                                             .List
                                        </blockHistory>
                                        // used to make sure we don't declare a
                                        // variable twice in the same scope
                                        <localVariables color="lightgray">
                                             .List
                                        </localVariables> 
                                        // used to deallocate memory on leaving a
                                        // block
                                        <localAddresses color="lightgray">
                                             .Set
                                        </localAddresses> 
                                   </local>
                                   // used to control initialization when gotoing
                                   <shouldInit color="lightgray"> true </shouldInit>
                                   // used to figure initializers
                                   <currentObject color="cyan">
                                        .List
                                   </currentObject>
                                   <currentSubObject color="cyan">
                                        .List
                                   </currentSubObject>
                                   <incompleteLength color="cyan">
                                        0
                                   </incompleteLength>
                                   <savedInitialization color="cyan">
                                        .K
                                   </savedInitialization>
                                   <loopStack color="violet"> .List </loopStack>
                                   <locsWrittenTo color="lightgray">
                                        .Bag
                                   </locsWrittenTo>
                                   // used for typing expressions
                                   <type multiplicity="?" color="cyan"> .K </type>
                                   // holds the innermost type while we unroll the
                                   // type around it
                                   <declarationTypeHolder color="cyan">
                                        .K
                                   </declarationTypeHolder>
                              </controlDetails>        
                         </control>
                    </threadLocal>
               </thread>
          </threads>

     // TODO(chathhorn): not sure where to put these.
     <callStackFrame multiplicity="*">
          <continuation> .K </continuation>
          <stackCurrentFunction> .K </stackCurrentFunction>
          <stackCurrentProgramLoc> .K </stackCurrentProgramLoc>
          <stackControl> .Bag </stackControl>
     </callStackFrame>

     <threadState multiplicity="*">
          <threadContinuation> .K </threadContinuation>
          <savedThreadLocal> .Bag </savedThreadLocal>
     </threadState>

     </exec>

     <files color="lightgray">
          <fileCommands> .K </fileCommands>
          <file multiplicity="*">
               <fid> .K </fid>
               <uri> .K </uri>
               <pos> 0 </pos>
               <mode> "r" </mode>
               <nextByte> .K </nextByte>
               <buff> "" </buff>
               <sending> .List </sending>
               <done> ListItem("") </done>
          </file>
     </files> 
     <input color="lightgray"> .List </input>
     <output color="lightgray"> .List </output>
     <resultValue color="red"> .K </resultValue>
     <errorCell multiplicity="?" color="black"> .K </errorCell>
     <status> initializing </status>

     </T>
          
endmodule
