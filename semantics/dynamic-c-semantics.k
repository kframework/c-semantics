load dynamic-c-configuration
load common-c-semantics
require /modules/uris

kmod DYNAMIC-SEMANTIC-SYNTAX is
	including COMMON-INCLUDE
	including URIS
endkm

kmod DYNAMIC-INCLUDE is
	including DYNAMIC-SEMANTIC-SYNTAX
	including DYNAMIC-C-CONFIGURATION
endkm

kmod DYNAMIC-C-SEMANTICS-MISC is
	including DYNAMIC-INCLUDE 
			
	rule [sequencePoint]:
		< k > sequencePoint => .K ...</ k >
		< locsWrittenTo > _ => .Bag </ locsWrittenTo >
		[structural ndlocal]

	// fixme these should be computational, unless I handle that at a higher level
	rule [writeToFD-char]:
		< k > writeToFD(FD:#Nat, N:#Nat) => .K ...</ k >
		< fid > FD:#Nat </ fid >
		< buff > S:#String => S:#String +String charString(N:#Nat %Nat 256) </ buff >
		[structural]
	rule [writeToFD-string]:
		< k > writeToFD(FD:#Nat, S':#String) => .K ...</ k >
		< fid > FD:#Nat </ fid >
		< buff > S:#String => S:#String +String S':#String ...</ buff >
		[structural]
	rule [readFromFD-char]:
		< k > readFromFD(FD:#Nat) => tv(charToAscii(firstChar(S:#String)), t(.Set, int))  ...</ k >
		< fid > FD:#Nat </ fid >
		< buff > S:#String => butFirstChar(S:#String) </ buff >
		when lengthString(S:#String) >Int 0 // don't compare with "" in order to only treat string sort
		[structural]
	rule [readFromFD-empty-buff]:
		< k > readFromFD(FD:#Nat) ...</ k >
		< fid > FD:#Nat </ fid >
		< buff > "" => "" +String charString(K2Nat(#fReadByte(FD:#Nat))) </ buff >
		[structural]
	rule [readFromFD-eof]:
		< k > readFromFD(FD:#Nat) => tv(-1, t(.Set, int)) ...</ k >
		< fid > FD:#Nat </ fid >
		< buff > #EOF </ buff >
		[structural]
	rule [make-eof]:
		"" +String charString(K2Nat(#EOF))
			=> #EOF
		[structural anywhere]
	// rule [readFromFD-char-eof]:
		// < k > readFromFD(FD:#Nat) => tv(-1, t(.Set, int)) ...</ k > // -1 should be EOF
		// < fid > FD:#Nat </ fid >
		// < buff > S:#String => butFirstChar(S:#String) </ buff >
		// if S:#String ==Bool ""
		// [structural]
		
	op f-sent : #Nat #String -> K
	op f-flush : #Nat -> K
	op f-sendString : #Nat #String -> K
	
	// can't lex string2List{K} correctly in #fPrint(N:#Nat,, string2List{K}(S:#String))
	rule [flush]:
		<k> flush(N:#Nat) => .K ...</k>
		<fileCommands>... .K
			=> f-sendString(N:#Nat, S:#String)
			~> f-sent(N:#Nat, S:#String)
			~> f-flush(N:#Nat)
		</fileCommands>
		<fid> N:#Nat </fid>
		<buff> S:#String => "" </buff>
		<sending>... .List => ListItem(S:#String) </sending>
		[structural]
	rule [sendString-one]:
		<fileCommands> f-sendString(N:#Nat, S:#String) 
			=> #fPutByte(N:#Nat, charToAscii(firstChar(S:#String)))
			~> f-sendString(N:#Nat, butFirstChar(S:#String))
		...</fileCommands>
		when S:#String =/=Bool ""
		[structural]
	rule [sendString-done]:
		<fileCommands> f-sendString(N:#Nat, "") => .K ...</fileCommands>
		[structural]

	rule [f-sent]:
		<files>...
			<fileCommands> f-sent(N:#Nat, S:#String) => .K ...</fileCommands>
			<fid> N:#Nat </fid>
			<sending> ListItem(S:#String) => .List ...</sending>
			<done>... .List => ListItem(S:#String) </done>
		...</files>
		[structural]
	rule [f-flush]:
		<fileCommands> f-flush(N:#Nat) => #flush(N:#Nat) ...</fileCommands>
		[structural]
		
	rule [combine-done]:
		<done> (ListItem(S:#String) ListItem(S':#String) => ListItem(S:#String +String S':#String)) ...</done>
		[structural]
		
	declare string2List : #String -> List{K}
	declare string2List-aux : #String List{K} -> List{K}
	define string2List(S:#String) => string2List-aux(S:#String, .List{K}) [structural]
	define string2List-aux("", L:List{K}) => L:List{K} [structural]
	define 
		string2List-aux(S:#String, L:List{K})
			=> string2List-aux(butFirstChar(S:#String), (L:List{K},, firstChar(S:#String)))
		when S:#String =/=Bool ""
		[structural]
		
	// op flushString : #Nat #String -> K
	
	// rule [flush-out-start]: 
		// < k > .K => flushString(1, S:#String) ...</ k >
		// <fid> 1 </fid>
		// <buff> S:#String => "" </buff>
		// <mode> "w" </mode>
		// if S:#String =/=Bool ""
		// [structural]
		
	// op flushSuccess : #Nat K -> K
	
	// rule [flush-success]: 
		// < k > flushSuccess(FD:#Nat, S:#String) => .K ...</ k >
		// <fid> FD:#Nat </fid>
		// <done> Done:#String => Done:#String +String S:#String </done>
		// [structural]
		
	// rule [flush-out-one]: 
		// < k > (.K 
				// => #fPutByte(FD:#Nat, charToAscii(firstChar(S:#String))) 
				// ~> flushSuccess(FD:#Nat, firstChar(S:#String))
			// )
			// ~> flushString(FD:#Nat, (S:#String => butFirstChar(S:#String)))
		// ...</ k >
		// if S:#String =/=Bool ""
		// [structural]
	// rule [flush-out-done]: 
		// < k > flushString(_, "") => .K ...</ k >
		// [structural]
endkm

load dynamic-c-expressions
load dynamic-c-conversions
load dynamic-c-statements
load dynamic-c-standard-lib
load dynamic-c-typing
load dynamic-c-memory
load dynamic-c-declarations
load dynamic-c-ltl

// this must be below the others
load dynamic-c-errors

kmod DYNAMIC-C-SEMANTICS is
	including COMMON-C-SEMANTICS
	including DYNAMIC-INCLUDE
	
	including DYNAMIC-C-SEMANTICS-MISC
	including DYNAMIC-C-EXPRESSIONS
	including DYNAMIC-C-ERRORS
	including DYNAMIC-C-TYPING 
	including DYNAMIC-C-DECLARATIONS 
	including DYNAMIC-C-MEMORY 
	including DYNAMIC-C-STATEMENTS 
	including DYNAMIC-C-CONVERSIONS 
	including DYNAMIC-C-STANDARD-LIBRARY
	including DYNAMIC-C-LTL
	
/*@ \source{C99 5.1.2.2.1:2}
If they are declared, the parameters to the main function shall obey the following constraints:
\begin{itemize}
\item The value of \cinline{argc} shall be nonnegative.
\item \cinline{argv[argc]} \cinline{shall} be a null pointer.
\item If the value of \cinline{argc} is greater than zero, the array members \cinline{argv[0]} through \cinline{argv[argc-1]} inclusive shall contain pointers to strings, which are given implementation-defined values by the host environment prior to program startup. The intent is to supply to the program information determined prior to program startup from elsewhere in the hosted environment. If the host environment is not capable of supplying strings with letters in both uppercase and lowercase, the implementation shall ensure that the strings are received in lowercase. 
\item If the value of argc is greater than zero, the string pointed to by \cinline{argv[0]} represents the program name; \cinline{argv[0][0]} shall be the null character if the program name is not available from the host environment. If the value of \cinline{argc} is greater than one, the strings pointed to by \cinline{argv[1]} through \cinline{argv[argc-1]} represent the program parameters.
\item The parameters \cinline{argc} and \cinline{argv} and the strings pointed to by the \cinline{argv} array shall be modifiable by the program, and retain their last-stored values between program startup and program termination.
\end{itemize}
*/
	
	op incomingArguments-aux : List{K} #Nat -> K
	
	rule incomingArguments(L:List{K}) 
			=> incomingArguments-aux(L:List{K}, 0) 
		[structural]
	rule incomingArguments-aux((S:#String,, L:List{K}), N:#Nat) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:#Nat] := Constant(StringLiteral(S:#String)))
			~> incomingArguments-aux(L:List{K}, sNat(N:#Nat))
		[structural]
	rule incomingArguments-aux(.List{K}, N:#Nat) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:#Nat] := NullPointer)
		[structural]
		
		
	op syntaxNat : #Nat -> K
	rule [syntaxNat]: syntaxNat(N:#Nat) => NoSuffix(DecimalConstant(N:#Nat)) [structural]
	
	rule [eval-noInput]: eval(K:K) => eval(K:K, .List{K}, "") [structural]
	rule [eval-input]: eval(Program(List(P:List{K})), L:List{K}, Input:#String) =>
		< T >
			< threads >
				< thread >
					< threadId > 1 </ threadId >
					< nextLoc > sym(threadId(1) +Nat 0) +Nat 0 </ nextLoc >
					< k > klistToK(P:List{K})
							~> DeclarationDefinition(InitNameGroup(Specifier(List(Char)), List(InitName(Name(Identifier("#incomingArgumentsArray"), PointerType(ArrayType(JustBase, syntaxNat(sNat(lengthList{K} L:List{K})), Specifier(List(.List{K}))))), NoInit))))
							~> resolveReferences					
							// ~> incomingArguments(L:List{K})
							~> callMain(lengthList{K}(L:List{K}), Identifier("#incomingArgumentsArray"), incomingArguments(L:List{K}))
					</ k >
					< threadLocal >
						< control >
							< currentFunction > File-Scope </ currentFunction >
							< currentProgramLoc > UnknownCabsLoc </ currentProgramLoc >
						...</ control >
					...</threadLocal>
				...</ thread >
			</ threads >
			<nextSharedLoc> sym(threadId(0) +Nat 0) +Nat 0 </nextSharedLoc>
		...</ T >
		< files >
			<fileCommands> .K </fileCommands>
			<file>...
				<fid> 0 </fid>
				<uri> "stdin:/" +String "/" +String "/" </uri>
				<mode> "r" </mode>
				<buff> Input:#String </buff>
			...</file>
			<file>...
				<fid> 1 </fid>
				<uri> "stdout:/" +String "/" +String "/" </uri>
				<mode> "w" </mode>
			...</file>
			<file>...
				<fid> 2 </fid>
				<uri> "stdout:/" +String "/" +String "/" </uri>
				<mode> "w" </mode>
			...</file>
		</ files >
		< xmessages > .K </ xmessages >
		[structural]

/*@ \source{C99 5.1.2.2.1:1}
The function called at program startup is named main. The implementation declares no prototype for this function. It shall be defined with a return type of int and with no parameters:
\clisting{int main(void) { ... }}
or with two parameters (referred to here as \cinline{argc} and \cinline{argv}, though any names may be used, as they are local to the function in which they are declared):
\clisting{int main(int argc, char *argv[]) { ... }}
or equivalent;9) or in some other implementation-defined manner
*/

	//@ this bit of indirection is used to check that the main prototype is correct, and to call it with the appropriate arguments
	
	rule < k > callMain(N:#Nat, X:#Id, Args:K)
			=> callMain-aux(typeof(Identifier("main")), N:#Nat, X:#Id, Args:K)
		...</ k >
		< functionTranslationUnits >... Tu:K |-> Map((_ Identifier("main") |-> Tu:K)) ...</ functionTranslationUnits >
		< currentTranslationUnit > _ => Tu:K </ currentTranslationUnit >
		[structural]
	
	// FIXME i think these are slightly different
	// fixme void isn't supposed to have a name
	// fixme figure out type of string
	rule callMain-aux(t(.Set, functionType(t(.Set, int), typedDeclaration(t(.Set, void), _:#Id))), N:#Nat, X:#Id, _) 
		=> Call(Identifier("main"), List(.List{K}))
		[structural]
	rule callMain-aux(t(.Set, functionType(t(.Set, int), .List{K})), N:#Nat, X:#Id, _) 
		=> Call(Identifier("main"), List(.List{K}))
		[structural]
	rule callMain-aux(t(.Set, functionType(t(.Set, int), (typedDeclaration(t(.Set, int), _:#Id),, typedDeclaration(t(.Set, incompleteArrayType(t(.Set, pointerType(T:KResult)))), _:#Id)))), N:#Nat, X:#Id, Args:K)
			=> Args:K 
			~> Call(Identifier("main"), List((N:#Nat,, X:#Id)))
		when T:KResult ==Bool t(.Set, char)
		[structural]
	rule callMain-aux(t(.Set, functionType(t(.Set, int), (typedDeclaration(t(.Set, int), _:#Id),, typedDeclaration(t(.Set, pointerType(t(.Set, pointerType(T:KResult)))), _:#Id)))), N:#Nat, X:#Id, Args:K)
			=> Args:K 
			~> Call(Identifier("main"), List((N:#Nat,, X:#Id)))
		when T:KResult ==Bool t(.Set, char)
		[structural]


	// fixme I'm not sure threads clean up their memory
	
	rule [terminate]:
		(< T >... < threads >... < thread >... 
			< threadId > 1 </ threadId > // main's thread, not the global "thread"
			< k > V:KResult </ k >
		...</ thread > ...</ threads > ...</ T >
			=> < resultValue > V:KResult </ resultValue >)
		< files >...
			<fileCommands> _ => .K </fileCommands> // to prevent further io commands from firing
			<file>... // stdout
				<fid> 1 </fid>
				<buff> S2'':#String </buff>
				<sending> L:List </sending>
				<done> ListItem(S2:#String) </done>
			...</file>
		...</ files >
		(.Bag =>
			< output > S2:#String +String listToString(L:List) +String S2'':#String </ output >
			//< unflushedOutput > listToString(L:List) +String S2'':#String </ unflushedOutput >
		)
		
 // < buff > # ""(.List{K}) </ buff > 
  // < fid > # 0(.List{K}) </ fid > 
  // < mode > # "r"(.List{K}) </ mode > 
  // < pos > # 0(.List{K}) </ pos > 
  // < uri > # "stdin:///"(.List{K}) </ uri > 
  // < done > ListItem(# ""(.List{K})) </ done > 
  // < (sending).CellLabel > (.).List </ (sending).CellLabel > </ file > 
 // < file > 
  // < buff > # ""(.List{K}) </ buff > 
  // < fid > # 1(.List{K}) </ fid > 
  // < mode > # "w"(.List{K}) </ mode > 
  // < pos > # 0(.List{K}) </ pos > 
  // < uri > # "stdout:///"(.List{K}) </ uri > 
  // < done > ListItem(# ""(.List{K})) </ done > 
  // < (sending).CellLabel > ListItem(# "Hello world\n"(.List{K})) </ (sending).CellLabel > </ file > 
	
	op listToString : List -> #String
	op listToString-aux : List #String -> #String
	
	rule [listToString-start]:
		listToString(L:List) => listToString-aux(L:List, "")
		[structural]
		
	rule [listToString-one]:
		listToString-aux(ListItem(S:#String) L:List, S':#String)
			=> listToString-aux(L:List, S':#String +String S:#String)
		[structural]
		
	rule [listToString-done]:
		listToString-aux(.List, S:#String) => S:#String
		[structural]
		
endkm
