module C-CONFIGURATION
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TRANSLATION-INIT-SYNTAX
     imports COMPAT-SYNTAX

     configuration 
     <global>
          <mem> .Map </mem>

          <functions color="lightgray"> .Map </functions>
          <gstructs color="lightgray"> .Map </gstructs>
          <stringLiterals color="lightgray"> .Map </stringLiterals>

          <notWritable> .Set </notWritable>

          <mainTU color="lightgray"> .Set </mainTU>

          <linking-state>
               // Id |-> Set(TUs)
               <external-decls> .Map </external-decls>
               // Id |-> Type
               <external-types> .Map </external-types>
               // Id |-> Loc
               <external-defs> .Map </external-defs>
               // Ids
               <external-uses> SetItem(Identifier("main")) </external-uses>
          </linking-state>

          // dummy link loc |-> real loc
          <linkings> .Map </linkings>

          <translation-units>
               <tu multiplicity="*">
                    <tu-id> .K </tu-id>
                    <genv color="lightgray"> .Map </genv>
                    <gtypes color="lightgray"> .Map </gtypes>

                    <tu-linking-state>
                         <externals> .Map </externals>
                         <internals> .Map </internals>
                         <next-link-loc> .K </next-link-loc>
                    </tu-linking-state>

                    <next-static-loc> .K </next-static-loc>

                    <freshUnnamed color="black"> 0 </freshUnnamed>

                    <goto-map color="lightgray"> .Map </goto-map>
               </tu>
          </translation-units>
     </global>
     <T multiplicity="?">
     <exec>
          <rawTypes> .Map </rawTypes>
          <typeSpecifiers> .Map </typeSpecifiers>

          <k color="green" multiplicity="?"> 
               loadObj(mergeObj(
                    unwrapObj($OBJ1:Bag), 
                    unwrapObj($OBJ2:Bag)))
               ~> $PGM:K 
               ~> outputMode($MODE:SemMode, $DEBUG:Bool)
          </k>

          <finalComputation multiplicity="?" color="lightgray">
               .K
          </finalComputation>

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
                    file-scope
               </currentFunction>
               <currentProgramLoc color="black">
                    UnknownCabsLoc
               </currentProgramLoc>

               <controlDetails> // TODO(chathhorn): dumb name
                    <local>
                         // maps from Ids
                         <env color="red"> .Map </env>
                         <types color="lightgray"> .Map </types>
                         <structs color="lightgray"> .Map </structs>
                    </local>
                    <blockStack color="violet"> .List </blockStack>

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

     </exec>

     <errorCell multiplicity="?" color="black"> .K </errorCell>

     <status> initializing </status>

     </T>
          
endmodule
