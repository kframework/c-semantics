module C11-CONFIGURATION
     imports C-DECLARATION-RESOLUTION-SYNTAX
     imports C-STATIC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     configuration 
     <global>
          <gotoMap color="lightgray"> .Map </gotoMap>
          <genv color="lightgray"> .Map </genv>
          <gtypes color="lightgray"> .Map </gtypes>
          <gstructs color="lightgray"> .Map </gstructs>
          <stringLiterals color="lightgray"> .Map </stringLiterals>
          // should be initialized with a pair (threadId, 0)
          <nextSharedLoc color="black"> .K </nextSharedLoc>
          <mem> .Map </mem>

          // map from current tu to (map from id to where function was
          // defined)             
          <funTUs color="lightgray"> .Map </funTUs>
          <mainTU color="lightgray"> .K </mainTU>
          <freshUnnamed color="black"> 0 </freshUnnamed>
          <functions color="lightgray"> .Map </functions>
          <notWritable> .Map </notWritable>
          <internalLocations color="cyan"> .Map </internalLocations>
          <externalLocations color="cyan"> .Map </externalLocations>
     </global>
     <T multiplicity="?">
     <exec>
          <leftoverExterns color="cyan"> .Bag </leftoverExterns>
          <translationUnits color="cyan"> .Bag </translationUnits>
          <declarationOrder color="cyan"> .Map </declarationOrder>
          <externalDefinitions color="cyan"> .Map </externalDefinitions>
          <internalDefinitions color="cyan"> .Map </internalDefinitions>

          <preLinkage color="cyan"> .Map </preLinkage>
          <preTypes color="cyan"> .Map </preTypes>
          <declarations color="cyan"> .Set </declarations>

          <rawTypes> .Map </rawTypes>
          <typeSpecifiers> .Map </typeSpecifiers>

          <mode> $MODE:SemMode </mode>

          <k color="green" multiplicity="?"> 
               $PGM:K 
               ~> resolveReferences 
               ~> initBuiltins
          </k>

          <finalComputation multiplicity="?" color="lightgray">
               .K
          </finalComputation>

          <threadLocal>
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
                         <local>
                              // maps from Ids
                              <env color="red"> .Map </env>
                              <types color="lightgray"> .Map </types>
                              <structs color="lightgray"> .Map </structs>
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

     </exec>

     <errorCell multiplicity="?" color="black"> .K </errorCell>

     <status> initializing </status>

     </T>
          
endmodule
