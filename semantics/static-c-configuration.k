load common-c-configuration

kmod STATIC-C-CONFIGURATION is
	including C-SYNTAX
	including COMMON-C-CONFIGURATION
	configuration 
		<T> 
			<gotoMap> .Map </gotoMap>
			<genv> .Map </genv>
			<gtypes> .Map </gtypes>
			<gstructs> .Map </gstructs>
			<mem color="red"> .Map </mem>
			<functions> .Map </functions>
			<freshNat color="green"> 0 </freshNat>
			<nextThreadId color="green"> 2 </nextThreadId> // 0 is global, 1 is main
			<nextFile color="green"> 0 </nextFile>
			<malloced> .Map </malloced>
			<stringLiterals> .Map </stringLiterals>
			@latex("\\kBR")
			// <staticSemantics multiplicity="?" color="cyan">
				<translationUnits color="cyan"> .Bag </translationUnits>
				<declarationOrder color="cyan"> .Map </declarationOrder>
				<externalDefinitions color="cyan"> .Map </externalDefinitions>
				<internalDefinitions color="cyan"> .Map </internalDefinitions>
				<internalLocations color="cyan"> .Map </internalLocations>
				<externalLocations color="cyan"> .Map </externalLocations>
				<preLinkage color="cyan"> .Map </preLinkage>
				<preTypes color="cyan"> .Map </preTypes>
				<declarations color="cyan"> .Set </declarations>
			// </staticSemantics>
			@latex("\\kBR")
			<functionTranslationUnits> .Map </functionTranslationUnits> // map from current tu to (map from id to where function was defined)			
			<nextSharedLoc color="green"> 0 </nextSharedLoc>
			<threadInformation color="yellow">
				<threadStatus color="yellow"> .Map </threadStatus>
				<joiningMap color="yellow"> .Map </joiningMap>
				<detachingMap color="yellow"> .Map </detachingMap>
			</threadInformation>
			<openFiles> .Map </openFiles>
			<programText color="black"> .Map </programText>
			<compoundLiteralMap> .Map </compoundLiteralMap>
			@latex("\\kBR")
			<threads>
				<thread multiplicity="*">
					// < parentThreadId > 0 </ parentThreadId >
					<threadId color="yellow"> 0 </threadId>
					<nextLoc color="green"> 0 </nextLoc> // should be initialized with a pair (threadId, 0)
					<callStack> .List </callStack> // stack of "control" cells
					<buffer> .List </buffer>
					<blocked> false </blocked>
					@latex("\\kBR")
					<control>
						<k color="red" multiplicity="?"> .K </k>
						<finalComputation multiplicity="?"> .K </finalComputation>
						<blockStack> .List </blockStack> // stack of "local" cells
						<local>
							// maps from Ids
							<env color="red"> .Map </env>
							<types> .Map </types>
							<structs> .Map </structs>

							// information about the block we're in
							<nestingDepth> 0 </nestingDepth>
							<blockHistory> .List </blockHistory>
							<localVariables> .List </localVariables> // used to make sure we don't declare a variable twice in the same scope
							<localAddresses> .Set </localAddresses> // used to deallocate memory on leaving a block
						</local>
						@latex("\\kBR")
						<shouldInit> true </shouldInit> // used to control initialization when gotoing
						// used to figure initializers
						<currentObject color="cyan"> .List </currentObject>
						<currentSubObject color="cyan"> .List </currentSubObject>
						<incompleteLength color="cyan"> 0 </incompleteLength>
						<savedInitialization color="cyan"> .K </savedInitialization>
						<loopStack> .List </loopStack>
						@latex("\\kBR")
						<locsWrittenTo> .Bag </locsWrittenTo>
						<holds color="yellow"> .Map </holds>
						<type multiplicity="?" color="cyan"> .K </type> // used for typing expressions
						<declarationTypeHolder color="cyan"> .K </declarationTypeHolder> // holds the innermost type while we unroll the type around it
						
						// general information
						<currentTranslationUnit> "" </currentTranslationUnit>
						<currentFunction> .K </currentFunction>
						<currentProgramLoc color="black"> .K </currentProgramLoc>
						@latex("\\kBR")
						<calculateGotoMap color="cyan">
							<gotoCalculation multiplicity="?" color="cyan">
								<computation color="cyan"> .K </computation>
								<computationTail color="cyan"> .K </computationTail>
								<declarationStack color="cyan"> .List </declarationStack>
								<nestingDepthGoto color="cyan"> 0 </nestingDepthGoto>
								<blockHistoryGoto color="cyan"> .List </blockHistoryGoto>
								<loopStackGoto color="cyan"> .List </loopStackGoto>
							</gotoCalculation>
						</calculateGotoMap>
					</control>
				</thread>
			</threads>
		</T>
		@latex("\\kBR")
		<xmessages color="black"> .K </xmessages>
		<files> .Map </files> // filenames to strings
		<input> "" </input>
		<output> "" </output>
		<resultValue> .K </resultValue>
		<errorCell multiplicity="?"> .K </errorCell>

endkm
