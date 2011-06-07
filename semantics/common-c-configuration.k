kmod COMMON-C-CONFIGURATION is
	including C-SYNTAX
	
	op k : -> CellLabel
	op stackFrame : -> CellLabel
	op continuation : -> CellLabel
	op stackCurrentFunction : -> CellLabel
	op stackCurrentProgramLoc : -> CellLabel
	op nextFile : -> CellLabel
	op currentProgramLoc : -> CellLabel 
	op structs : -> CellLabel
	
	ops gotoMap gotoCalculation currentFunction computation : -> CellLabel
	ops currentTranslationUnit calculateGotoMap nestingDepthGoto blockHistoryGoto declarationStack : -> CellLabel
	ops computationTail loopStackGoto externalLocations internalLocations : -> CellLabel
	ops blockHistory shouldInit nextSharedLoc preLinkage declarationOrder declarations preTypes : -> CellLabel
	ops nextLoc localVariables externalDefinitions internalDefinitions : -> CellLabel
	ops localAddresses incompleteLength genv env control savedInitialization typedBody currentObject currentSubObject callStack functionTranslationUnits translationUnits gtypes functions programText types type freshNat declarationTypeHolder gstructs  : -> CellLabel
	
	
	configuration 
		<T> 
			// <busy> .Bag </busy>
			<gotoMap color="lightgray"> .Map </gotoMap>
			<genv color="lightgray"> .Map </genv>
			<gtypes color="lightgray"> .Map </gtypes>
			<gstructs color="lightgray"> .Map </gstructs>
			<mem color="red"> .Map </mem>
			<functions color="lightgray"> .Map </functions>
			<freshNat color="green"> 0 </freshNat>
			<nextThreadId color="green"> 2 </nextThreadId> // 0 is global, 1 is main
			<nextFile color="green"> 0 </nextFile>
			<malloced color="lightgray"> .Map </malloced>
			<stringLiterals color="lightgray"> .Map </stringLiterals>
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
			<functionTranslationUnits color="lightgray"> .Map </functionTranslationUnits> // map from current tu to (map from id to where function was defined)			
			<nextSharedLoc color="green"> 0 </nextSharedLoc>
			<threadInformation color="yellow">
				<threadStatus color="yellow"> .Map </threadStatus>
				<joiningMap color="yellow"> .Map </joiningMap>
				<detachingMap color="yellow"> .Map </detachingMap>
			</threadInformation>
			<openFiles color="lightgray"> .Map </openFiles>
			<programText color="black"> .Map </programText>
			<compoundLiteralMap color="lightgray"> .Map </compoundLiteralMap>
			@latex("\\kBR")
			<threads color="yellow">
				<thread multiplicity="*" color="yellow">
					// < parentThreadId > 0 </ parentThreadId >
					<threadId color="yellow"> 0 </threadId>
					<nextLoc color="green"> 0 </nextLoc> // should be initialized with a pair (threadId, 0)
					<buffer color="lightgray"> .List </buffer>
					<blocked color="lightgray"> false </blocked>
					<k color="red" multiplicity="?"> .K </k>
					<threadLocal>
						<callStack color="violet"> .List </callStack> // stack of "control" cells
						@latex("\\kBR")
						<control>
							//<statick> .K </statick>
							//<newk> .K </newk>
							<finalComputation multiplicity="?" color="lightgray"> .K </finalComputation>
							<blockStack color="violet"> .List </blockStack> // stack of "local" cells
							<local>
								// maps from Ids
								<env color="red"> .Map </env>
								<types color="lightgray"> .Map </types>
								<structs color="lightgray"> .Map </structs>

								// information about the block we're in
								<nestingDepth color="lightgray"> 0 </nestingDepth>
								<blockHistory color="lightgray"> .List </blockHistory>
								<localVariables color="lightgray"> .List </localVariables> // used to make sure we don't declare a variable twice in the same scope
								<localAddresses color="lightgray"> .Set </localAddresses> // used to deallocate memory on leaving a block
							</local>
							@latex("\\kBR")
							<shouldInit color="lightgray"> true </shouldInit> // used to control initialization when gotoing
							// used to figure initializers
							<currentObject color="cyan"> .List </currentObject>
							<currentSubObject color="cyan"> .List </currentSubObject>
							<incompleteLength color="cyan"> 0 </incompleteLength>
							<savedInitialization color="cyan"> .K </savedInitialization>
							<loopStack color="violet"> .List </loopStack>
							@latex("\\kBR")
							<locsWrittenTo color="lightgray"> .Bag </locsWrittenTo>
							<holds color="yellow"> .Map </holds>
							<type multiplicity="?" color="cyan"> .K </type> // used for typing expressions
							<declarationTypeHolder color="cyan"> .K </declarationTypeHolder> // holds the innermost type while we unroll the type around it
							
							// general information
							<currentTranslationUnit color="lightgray"> "" </currentTranslationUnit>
							<currentFunction color="lightgray"> .K </currentFunction>
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
					</threadLocal>
				</thread>
			</threads>
		</T>
		@latex("\\kBR")
		<xmessages color="black"> .K </xmessages>
		<files color="lightgray"> .Map </files> // filenames to strings
		<input color="lightgray"> "" </input>
		<output color="lightgray"> "" </output>
		<resultValue color="red"> .K </resultValue>
		<errorCell multiplicity="?" color="black"> .K </errorCell>
	
	subsort Id Int String Float Bool Rat < K
	subsort String < Builtins
	
	subsort C < K
	subsort List{C} < K
	
endkm
