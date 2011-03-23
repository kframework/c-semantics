kmod C-CONFIGURATION is
	including C-SYNTAX
	including COMMON-C-CONFIGURATION
	op nextFile : -> CellLabel
	configuration 
		<T> 
			<busy> .Bag </busy>
			<gotoMap> .Map </gotoMap>
			<genv> .Map </genv>
			<gtypes> .Map </gtypes>
			<gstructs> .Map </gstructs>
			<mem> .Map </mem>
			<freshNat> 0 </freshNat>
			<nextThreadId> 2 </nextThreadId> --- 0 is global, 1 is main
			<nextFile> 0 </nextFile>
			<malloced> .Map </malloced>
			<statics> .Map </statics>
			@latex("\\kBR")
			<internalLocations> .Map </internalLocations>
			<externalLocations> .Map </externalLocations>
			<openFiles> .Map </openFiles>
			
			<programText> .Map </programText>
			<externalDefinitions> .Map </externalDefinitions>
			<internalDefinitions> .Map </internalDefinitions>
			@latex("\\kBR")
			<declarations> .Set </declarations>
			<preLinkage> .Map </preLinkage>
			<preTypes> .Map </preTypes>
			
			<translationUnits> .Bag </translationUnits>
			<functionTranslationUnits> .Map </functionTranslationUnits>
			<declarationOrder> .Map </declarationOrder>
			--- <messages> .List </messages>
			--- <formula> .K </formula>
			<nextSharedLoc> 0 </nextSharedLoc>
			@latex("\\kBR")
			<threads>
				<thread multiplicity="*">
					--- < parentThreadId > 0 </ parentThreadId >
					<threadId> 0 </threadId>
					<nextLoc> 0 </nextLoc> --- should be initialized with a pair (threadId, 0)
					<callStack> .List </callStack> --- stack of "control" cells
					<buffer> (.).List </buffer>
					<blocked> false </blocked>
					<control>
						<k> .K </k>
						<blockStack> .List </blockStack> --- stack of "local" cells
						<local>
							--- maps from Ids
							<env> .Map </env>
							<types> .Map </types>
							<structs> .Map </structs>

							--- information about the block we're in
							<nestingDepth> 0 </nestingDepth>
							<blockHistory> .List </blockHistory>
							<localVariables> .List </localVariables> --- used to make sure we don't declare a variable twice in the same scope
							<localAddresses> .Set </localAddresses> --- used to deallocate memory on leaving a block
						</local>
						@latex("\\kBR")
						<shouldInit> true </shouldInit> --- used to control initialization when gotoing
						--- used to figure initializers
						<currentObject> .List </currentObject>
						<currentSubObject> .List </currentSubObject>
						<incompleteLength> 0 </incompleteLength>
						<savedInitialization> .K </savedInitialization>
						<loopStack> .List </loopStack>
						@latex("\\kBR")
						<locsWrittenTo> .Bag </locsWrittenTo>
						<holds> .Map </holds>
						<type multiplicity="?"> .K </type> --- used for typing expressions
						<declarationTypeHolder> .K </declarationTypeHolder> --- holds the innermost type while we unroll the type around it
						
						--- general information
						<currentTranslationUnit> "" </currentTranslationUnit>
						<currentFunction> .K </currentFunction>
						<currentProgramLoc> .K </currentProgramLoc>
						@latex("\\kBR")
						<calculateGotoMap>
							<gotoCalculation multiplicity="?">
								<computation> .K </computation>
								<computationTail> .K </computationTail>
								<declarationStack> .List </declarationStack>
								<nestingDepthGoto> 0 </nestingDepthGoto>
								<blockHistoryGoto> .List </blockHistoryGoto>
								<loopStackGoto> .List </loopStackGoto>
							</gotoCalculation>
						</calculateGotoMap>
					</control>
				</thread>
			</threads>
			@latex("\\kBR")
			<threadInformation>
				<threadStatus> .Map </threadStatus>
				<joiningMap> .Map </joiningMap>
				<detachingMap> .Map </detachingMap>
			</threadInformation>
			<compoundLiteralMap> .Map </compoundLiteralMap>
			<unfinishedComputation> .K </unfinishedComputation> --- this is here to make it easy to check if we've terminated.  it disappears when we terminate
		</T>
		@latex("\\kBR")
		<xmessages> .K </xmessages>
		<files> .Map </files> --- filenames to strings
		<input> "" </input>
		<output> "" </output>
		<resultValue> .K </resultValue>
		<errorCell multiplicity="?"> .K </errorCell>

endkm
