load dynamic-c-configuration
load common-c-semantics
require /modules/uris

module DYNAMIC-SEMANTIC-SYNTAX is
	including COMMON-INCLUDE
	including URIS
end module

module DYNAMIC-INCLUDE is
	including DYNAMIC-SEMANTIC-SYNTAX
	including DYNAMIC-C-CONFIGURATION
end module

module DYNAMIC-C-SEMANTICS-MISC is
	including DYNAMIC-INCLUDE 
			
	rule [sequencePoint]:
		<k> sequencePoint => .K ...</k>
		<locsWrittenTo> _ => .Bag </locsWrittenTo>
		[structural ndlocal]

	// fixme these should be computational, unless I handle that at a higher level
	rule [writeToFD-char]:
		<k> writeToFD(FD:Nat, N:Nat) => .K ...</k>
		<fid> FD:Nat </fid>
		<buff> S:String => S:String +String charString(N:Nat %Int 256) </buff>
		[observable]
	rule [writeToFD-string]:
		<k> writeToFD(FD:Nat, S':String) => .K ...</k>
		<fid> FD:Nat </fid>
		<buff> S:String => S:String +String S':String </buff>
		[observable]
	rule [readFromFD-char]:
		<k> readFromFD(FD:Nat) => tv(charToAscii(firstChar(S:String)), t(.Set, int))  ...</k>
		<fid> FD:Nat </fid>
		<buff> S:String => butFirstChar(S:String) </buff>
		when lengthString(S:String) >Int 0 // don't compare with "" in order to only treat string sort
		[observable]
	rule [readFromFD-empty-buff]:
		<k> readFromFD(FD:Nat) ...</k>
		<fid> FD:Nat </fid>
		<buff> "" => "" +String charString(#fReadByte(FD:Nat)) </buff>
		[structural]
	rule [readFromFD-eof]:
		<k> readFromFD(FD:Nat) => tv(-1, t(.Set, int)) ...</k>
		<fid> FD:Nat </fid>
		<buff> #EOF </buff>
		[observable]
	rule [make-eof]:
		"" +String charString(#EOF)
			=> #EOF
		[structural anywhere]
		
	syntax K ::= "f-sent" "(" Nat "," String ")" [klabel(f-sent)]
	syntax K ::= "f-flush" "(" Nat ")" [klabel(f-flush)]
	syntax K ::= "f-sendString" "(" Nat "," String ")" [klabel(f-sendString)]
	
	// can't lex string2List{K} correctly in #fPrint(N:Nat,, string2List{K}(S:String))
	rule [flush]:
		<k> flush(N:Nat) => .K ...</k>
		<fileCommands>... .K
			=> f-sendString(N:Nat, S:String)
			~> f-sent(N:Nat, S:String)
			~> f-flush(N:Nat)
		</fileCommands>
		<fid> N:Nat </fid>
		<buff> S:String => "" </buff>
		<sending>... .List => ListItem(S:String) </sending>
		[structural]
	rule [sendString-one]:
		<fileCommands> f-sendString(N:Nat, S:String) 
			=> #fPutByte(N:Nat, charToAscii(firstChar(S:String)))
			~> f-sendString(N:Nat, butFirstChar(S:String))
		...</fileCommands>
		when S:String =/=String ""
		[structural]
	rule [sendString-done]:
		<fileCommands> f-sendString(N:Nat, "") => .K ...</fileCommands>
		[structural]

	rule [f-sent]:
		<files>...
			<fileCommands> f-sent(N:Nat, S:String) => .K ...</fileCommands>
			<fid> N:Nat </fid>
			<sending> ListItem(S:String) => .List ...</sending>
			<done>... .List => ListItem(S:String) </done>
		...</files>
		[structural]
	rule [f-flush]:
		<fileCommands> f-flush(N:Nat) => #flush(N:Nat) ...</fileCommands>
		[structural]
		
	rule [combine-done]:
		<done> (ListItem(S:String) ListItem(S':String) => ListItem(S:String +String S':String)) ...</done>
		[structural]
		
	declare string2List : String -> List{K}
	declare string2List-aux : String List{K} -> List{K}
	define string2List(S:String) => string2List-aux(S:String, .List{K})
	define string2List-aux("", L:List{K}) => L:List{K}
	define 
		string2List-aux(S:String, L:List{K})
			=> string2List-aux(butFirstChar(S:String), (L:List{K},, firstChar(S:String)))
		when S:String =/=String ""
		[structural]
end module

load dynamic-c-expressions
load dynamic-c-conversions
load dynamic-c-statements
load dynamic-c-standard-lib
load dynamic-c-typing
load dynamic-c-memory
load dynamic-c-declarations
// load dynamic-c-ltl

// this must be below the others
load dynamic-c-errors

module DYNAMIC-C-SEMANTICS is
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
	// including DYNAMIC-C-LTL
	
/*@ \fromStandard{\source[n1570]{\para{5.1.2.2.1}{2}}}{
If they are declared, the parameters to the main function shall obey the following constraints:
\begin{itemize}
\item The value of \cinline{argc} shall be nonnegative.
\item \cinline{argv[argc]} \cinline{shall} be a null pointer.
\item If the value of \cinline{argc} is greater than zero, the array members \cinline{argv[0]} through \cinline{argv[argc-1]} inclusive shall contain pointers to strings, which are given implementation-defined values by the host environment prior to program startup. The intent is to supply to the program information determined prior to program startup from elsewhere in the hosted environment. If the host environment is not capable of supplying strings with letters in both uppercase and lowercase, the implementation shall ensure that the strings are received in lowercase. 
\item If the value of argc is greater than zero, the string pointed to by \cinline{argv[0]} represents the program name; \cinline{argv[0][0]} shall be the null character if the program name is not available from the host environment. If the value of \cinline{argc} is greater than one, the strings pointed to by \cinline{argv[1]} through \cinline{argv[argc-1]} represent the program parameters.
\item The parameters \cinline{argc} and \cinline{argv} and the strings pointed to by the \cinline{argv} array shall be modifiable by the program, and retain their last-stored values between program startup and program termination.
\end{itemize}
}*/
	
	syntax K ::= "incomingArguments-aux" "(" List{K} "," Nat ")" [klabel(incomingArguments-aux)]
	
	rule incomingArguments(L:List{K}) 
			=> incomingArguments-aux(L:List{K}, 0) 
		[structural]
	rule incomingArguments-aux((S:String,, L:List{K}), N:Nat) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:Nat] := Constant(StringLiteral(S:String)))
			~> incomingArguments-aux(L:List{K}, N:Nat +Int 1)
		[structural]
	rule incomingArguments-aux(.List{K}, N:Nat) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:Nat] := NullPointer)
		[structural]
		
		
	syntax K ::= "syntaxNat" "(" Nat ")" [klabel(syntaxNat)]
	rule [syntaxNat]: syntaxNat(N:Nat) => NoSuffix(DecimalConstant(N:Nat)) [structural]
	
	syntax K ::= "pgmArgs" "(" List{K} ")"
	syntax K ::= "argName" "(" List{K} ")"
	define
		argName(L:List{K})
		=> Name(
			Identifier("#incomingArgumentsArray"), 
			PointerType(ArrayType(JustBase, syntaxNat((lengthList{K} L:List{K}) +Int 1), Specifier(List(.List{K}))))
		)
	define
		pgmArgs(L:List{K})
		=> DeclarationDefinition(InitNameGroup(
			Specifier(List(Char)), 
			List(InitName(argName(L:List{K}), NoInit))
		))
		[structural]

	rule [eval-noInput]: eval(K:K) => eval(K:K, .List{K}, "", 0) [structural]
		
	/*@ These helpers are used to get around a bug in \K related to successive ``/''s in strings. */
	syntax K ::= "stdinStr" | "stdoutStr"
	
	define stdinStr => "stdin:/" +String "/" +String "/"
	define stdoutStr => "stdout:/" +String "/" +String "/"
	
	rule [eval-input]: eval(Program(List(P:List{K})), L:List{K}, Input:String, IsInterp:Int) =>
		<T>...
			<threads>
				<thread>...
					<k> klistToK(P:List{K})
							~> pgmArgs(L:List{K})
							~> resolveReferences					
							// ~> incomingArguments(L:List{K})
							~> callMain(lengthList{K}(L:List{K}), incomingArguments(L:List{K}))
					</k>
					<br/>
					<threadId> 1 </threadId>
					<nextLoc> firstLoc(1) </nextLoc>
					<threadLocal>
						<control>
							<currentFunction> File-Scope </currentFunction>
							<currentProgramLoc> UnknownCabsLoc </currentProgramLoc>
						...</control>
					...</threadLocal>
				...</thread>
			</threads>
			<nextSharedLoc> firstLoc(0) </nextSharedLoc>
		...</T>
		<br/>
		<files>
			<fileCommands> #if IsInterp ==Int 0 #then debug #else .K #fi </fileCommands>
			<br/>
			<file>...
				<fid> 0 </fid>
				<uri> stdinStr </uri>
				<mode> "r" </mode>
				<buff> Input:String </buff>
			...</file>
			<file>...
				<fid> 1 </fid>
				<uri> stdoutStr </uri>
				<mode> "w" </mode>
			...</file>
			<file>...
				<fid> 2 </fid>
				<uri> stdoutStr </uri>
				<mode> "w" </mode>
			...</file>
		</files>
		//<xmessages> .K </xmessages>
		[structural large]

/*@ 
\begin{lrbox}{\LstBox}
\begin{lstlisting}
int main(void) { ... }
\end{lstlisting}
\end{lrbox}
\begin{lrbox}{\LstBoxb}
\begin{lstlisting}
int main(int argc, char *argv[]) { ... }
\end{lstlisting}
\end{lrbox}
\fromStandard{\source[n1570]{\para{5.1.2.2.1}{1}}}{
The function called at program startup is named \cinline{main}. The implementation declares no prototype for this function. It shall be defined with a return type of \cinline{int} and with no parameters:

\usebox{\LstBox}

or with two parameters (referred to here as \cinline{argc} and \cinline{argv}, though any names may be used, as they are local to the function in which they are declared):

\usebox{\LstBoxb}

or equivalent; or in some other implementation-defined manner.
}*/

	//@ this bit of indirection is used to check that the main prototype is correct, and to call it with the appropriate arguments
	
	rule [call-main]:
		<k> callMain(N:Nat, Args:K)
			=> callMain-aux(typeof(Identifier("main")), N:Nat, Identifier("#incomingArgumentsArray"), Args:K)
		...</k>
		<funTUs>... 
			Tu:K |-> Map((_ Identifier("main") |-> Tu:K)) 
		...</funTUs>
		<currTU> _ => Tu:K </currTU>
		[computational]
	
	// FIXME i think these are slightly different
	// fixme void isn't supposed to have a name
	// fixme figure out type of string
	rule
		callMain-aux(t(.Set, functionType(t(.Set, int), typedDeclaration(t(.Set, void), _:Id))), N:Nat, X:Id, _) 
			=> Call(Identifier("main"), List(.List{K}))
		[structural]
	rule
		callMain-aux(t(.Set, functionType(t(.Set, int), .List{K})), N:Nat, X:Id, _) 
			=> Call(Identifier("main"), List(.List{K}))
		[structural]
	rule
		callMain-aux(t(.Set, functionType(t(.Set, int), (typedDeclaration(t(.Set, int), _:Id),, typedDeclaration(t(.Set, incompleteArrayType(t(.Set, pointerType(T:KResult)))), _:Id)))), N:Nat, X:Id, Args:K)
			=> Args:K 
			~> Call(Identifier("main"), List((N:Nat,, X:Id)))
		when T:KResult ==K t(.Set, char)
		[structural]
	rule
		callMain-aux(t(.Set, functionType(t(.Set, int), (typedDeclaration(t(.Set, int), _:Id),, typedDeclaration(t(.Set, pointerType(t(.Set, pointerType(T:KResult)))), _:Id)))), N:Nat, X:Id, Args:K)
			=> Args:K 
			~> Call(Identifier("main"), List((N:Nat,, X:Id)))
		when T:KResult ==K t(.Set, char)
		[structural]


	// fixme I'm not sure threads clean up their memory
	
	rule [terminate]:
		(<T>... <threads>... <thread>... 
			<threadId> 1 </threadId> // main's thread, not the global "thread"
			<k> V:KResult </k>
		...</thread> ...</threads> ...</T>
			=> <resultValue> V:KResult </resultValue>)
		<files>...
			<fileCommands> _ => .K </fileCommands> // to prevent further io commands from firing
			<file>... // stdout
				<fid> 1 </fid>
				<buff> S2'':String </buff>
				<sending> L:List </sending>
				<done> ListItem(S2:String) </done>
			...</file>
		...</files>
		(.Bag =>
			<output> S2:String +String listToString(L:List) +String S2'':String </output>
		)
		[computational]
end module
