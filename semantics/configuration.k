module C11-CONFIGURATION
     imports C-DYNAMIC-SYNTAX

     configuration 
     <status> initializing </status>
     <T>
          <gotoMap color="lightgray"> .Map </gotoMap>
          <genv color="lightgray"> .Map </genv>
          <gtypes color="lightgray"> .Map </gtypes>
          <gstructs color="lightgray"> .Map </gstructs>

          <mem> .Map </mem>

          <notWritable> .Map </notWritable>
          <functions color="lightgray"> .Map </functions>
          <freshNat color="black"> 0 </freshNat>
          <randNat color="black"> 0 </randNat>
          // 0 is global, 1 is main
          <nextThreadId color="black"> 2 </nextThreadId>
          <malloced color="lightgray"> .Map </malloced>
          <stringLiterals color="lightgray"> .Map </stringLiterals>
          <br/>
          <leftoverExterns color="cyan"> .Bag </leftoverExterns>
          <translationUnits color="cyan"> .Bag </translationUnits>
          <declarationOrder color="cyan"> .Map </declarationOrder>
          <externalDefinitions color="cyan"> .Map </externalDefinitions>
          <internalDefinitions color="cyan"> .Map </internalDefinitions>
          <internalLocations color="cyan"> .Map </internalLocations>
          <externalLocations color="cyan"> .Map </externalLocations>
          <preLinkage color="cyan"> .Map </preLinkage>
          <preTypes color="cyan"> .Map </preTypes>
          <declarations color="cyan"> .Set </declarations>
          <br/>
          // map from current tu to (map from id to where function was defined)             
          <funTUs color="lightgray"> .Map </funTUs>
          <mainTU color="lightgray"> .K </mainTU>
          <nextSharedLoc color="black"> 0 </nextSharedLoc>
          <threadInformation color="yellow">
               <threadStatus color="yellow"> .Map </threadStatus>
               <mutexes color="yellow"> .Map </mutexes>
               <glocks color="yellow"> .Bag </glocks>
          </threadInformation>
          <programText color="black"> .Map </programText>
          <compoundLiteralMap color="lightgray"> .Map </compoundLiteralMap>
          <br/>
          <threads color="yellow">
               <thread multiplicity="*" color="yellow">
                    <threadId color="yellow"> 1 </threadId>
                    // should be initialized with a pair (threadId, 0)
                    <nextLoc color="black"> 0 </nextLoc>
                    <buffer color="lightgray"> .List </buffer>
                    <k color="green" multiplicity="?"> 
                         $PGM:K 
                         ~> pgmArgs($ARGV:KList) 
                         ~> resolveReferences
                         ~> callMain($ARGC:Int, incomingArguments($ARGV:KList))
                    </k>
                    <br/>
                    <threadLocal>
                         // stack of "control" cells
                         <callStack color="violet"> .List </callStack>
                         <locks> .Bag </locks>
                         <calculateGotoMap color="cyan">
                              <gotoCalculation multiplicity="*" color="cyan">
                                   <computation color="cyan"> .K </computation>
                                   <computationTail color="cyan">
                                        .K
                                   </computationTail>
                                   <declarationStack color="cyan">
                                        .List
                                   </declarationStack>
                                   <nestingDepthGoto color="cyan">
                                        0
                                   </nestingDepthGoto>
                                   <blockHistoryGoto color="cyan">
                                        .List
                                   </blockHistoryGoto>
                                   <loopStackGoto color="cyan">
                                        .List
                                   </loopStackGoto>
                              </gotoCalculation>
                         </calculateGotoMap>
                         <br/>
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
                                   <finalComputation multiplicity="?" color="lightgray">
                                        .K
                                   </finalComputation>
                                   // stack of "local" cells
                                   <blockStack color="violet"> .List </blockStack>
                                   <local>
                                        // maps from Ids
                                        <env color="red"> .Map </env>
                                        <types color="lightgray"> .Map </types>
                                        <structs color="lightgray"> .Map </structs>

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
                                   <br/>
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
                                   <br/>
                                   <locsWrittenTo color="lightgray">
                                        .Bag
                                   </locsWrittenTo>
                                   <holds color="yellow"> .Map </holds>
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
     </T>

     <br/>

     // TODO(chathhorn): I'm not sure what to do with these. Also,
     // multiplicity...?
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
     <input color="lightgray" stream="stdin"> .List </input>
     <output color="lightgray" stream="stdout"> .List </output>
     <resultValue color="red"> .K </resultValue>
     <errorCell multiplicity="?" color="black"> .K </errorCell>
          
endmodule
