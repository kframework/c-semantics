module COMMON-C-CONFIGURATION is
	including C-SYNTAX

	syntax CellLabel ::= "stackFrame" | "continuation" | "stackCurrentFunction" | "stackCurrentProgramLoc"
	
	configuration 
		<T> 
			// <modelChecking multiplicity="?"> .K </modelChecking>
			// <busy> .Bag </busy>
			<gotoMap color="lightgray"> .Map </gotoMap>
			<genv color="lightgray"> .Map </genv>
			<gtypes color="lightgray"> .Map </gtypes>
			<gstructs color="lightgray"> .Map </gstructs>
			<memory color="red" type="Map">
				<object multiplicity="*">
					<basePtr type="Key"> 0 </basePtr>
					<oLength> 0 </oLength>
					<properties> .Bag </properties>
					<bytes> .Map </bytes>
				</object>
			</memory>
			<notWritable> .Map </notWritable>
			<functions color="lightgray"> .Map </functions>
			<freshNat color="black"> 0 </freshNat>
			<randNat color="black"> 0 </randNat>
			<nextThreadId color="black"> 2 </nextThreadId> // 0 is global, 1 is main
			<malloced color="lightgray"> .Map </malloced>
			<stringLiterals color="lightgray"> .Map </stringLiterals>
			<br/>
			// <staticSemantics multiplicity="?" color="cyan">
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
			// </staticSemantics>
			<br/>
			<functionTranslationUnits color="lightgray"> .Map </functionTranslationUnits> // map from current tu to (map from id to where function was defined)			
			<nextSharedLoc color="black"> 0 </nextSharedLoc>
			<threadInformation color="yellow">
				<threadStatus color="yellow"> .Map </threadStatus>
				<joiningMap color="yellow"> .Map </joiningMap>
				<detachingMap color="yellow"> .Map </detachingMap>
			</threadInformation>
			// <openFiles color="lightgray"> .Map </openFiles>
			<programText color="black"> .Map </programText>
			<compoundLiteralMap color="lightgray"> .Map </compoundLiteralMap>
			<br/>
			<threads color="yellow">
				<thread multiplicity="*" color="yellow">
					<threadId color="yellow"> 0 </threadId>
					<nextLoc color="black"> 0 </nextLoc> // should be initialized with a pair (threadId, 0)
					<buffer color="lightgray"> .List </buffer>
					<blocked color="lightgray"> false </blocked>
					<k color="green" multiplicity="?"> .K </k>
					<br/>
					<threadLocal>
						<callStack color="violet"> .List </callStack> // stack of "control" cells
						<calculateGotoMap color="cyan">
							<gotoCalculation multiplicity="*" color="cyan">
								<computation color="cyan"> .K </computation>
								<computationTail color="cyan"> .K </computationTail>
								<declarationStack color="cyan"> .List </declarationStack>
								<nestingDepthGoto color="cyan"> 0 </nestingDepthGoto>
								<blockHistoryGoto color="cyan"> .List </blockHistoryGoto>
								<loopStackGoto color="cyan"> .List </loopStackGoto>
							</gotoCalculation>
						</calculateGotoMap>
						<br/>
						<control>
							<finalComputation multiplicity="?" color="lightgray"> .K </finalComputation>
							<blockStack color="violet"> .List </blockStack> // stack of "local" cells
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
									<formatModifiers> .Map </formatModifiers>
									<formatLength> "" </formatLength>
								</formatting>
								// information about the block we're in
								<nestingDepth color="lightgray"> 0 </nestingDepth>
								<blockHistory color="lightgray"> .List </blockHistory>
								<localVariables color="lightgray"> .List </localVariables> // used to make sure we don't declare a variable twice in the same scope
								<localAddresses color="lightgray"> .Set </localAddresses> // used to deallocate memory on leaving a block
							</local>
							<br/>
							<shouldInit color="lightgray"> true </shouldInit> // used to control initialization when gotoing
							// used to figure initializers
							<currentObject color="cyan"> .List </currentObject>
							<currentSubObject color="cyan"> .List </currentSubObject>
							<incompleteLength color="cyan"> 0 </incompleteLength>
							<savedInitialization color="cyan"> .K </savedInitialization>
							<loopStack color="violet"> .List </loopStack>
							<br/>
							<locsWrittenTo color="lightgray"> .Bag </locsWrittenTo>
							<holds color="yellow"> .Map </holds>
							<type multiplicity="?" color="cyan"> .K </type> // used for typing expressions
							<declarationTypeHolder color="cyan"> .K </declarationTypeHolder> // holds the innermost type while we unroll the type around it
							
							// general information
							<currentTranslationUnit color="lightgray"> "" </currentTranslationUnit>
							<currentFunction color="lightgray"> .K </currentFunction>
							<currentProgramLoc color="black"> .K </currentProgramLoc>
						</control>
					</threadLocal>
				</thread>
			</threads>
		</T>
		<br/>
		<xmessages color="black"> .K </xmessages>
		<files color="lightgray">
			<fileCommands> .K </fileCommands>
			<file multiplicity="*">
				<fid> .K </fid>
				<uri> .K </uri>
				<pos> 0 </pos>
				<mode> "r" </mode>
				<buff> "" </buff>
				<sending> .List </sending>
				<done> ListItem("") </done>
			</file>
		</files> 
		<input color="lightgray"> "" </input>
		<output color="lightgray"> "" </output>
		//<unflushedOutput color="lightgray"> "" </unflushedOutput>
		<resultValue color="red"> .K </resultValue>
		<errorCell multiplicity="?" color="black"> .K </errorCell>
	
end module
