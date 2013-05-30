require "c-configuration.k"
//require "dynamic-c-configuration.k"
require "common-c-semantics.k"
require "modules/uris.k"

require "dynamic-c-expressions.k"
require "dynamic-c-conversions.k"
require "dynamic-c-statements.k"
require "dynamic-c-standard-lib.k"
require "dynamic-c-typing.k"
require "dynamic-c-memory.k"
require "dynamic-c-declarations.k"
// require "dynamic-c-ltl.k"

// this must be below the others
// TODO(chathhorn): xml, ellided
//require "dynamic-c-errors.k"

module DYNAMIC-SEMANTIC-SYNTAX
	imports COMMON-INCLUDE
	imports URIS
endmodule

module DYNAMIC-INCLUDE
	imports DYNAMIC-SEMANTIC-SYNTAX
	imports C-CONFIGURATION
endmodule

module DYNAMIC-C-SEMANTICS-MISC
	imports DYNAMIC-INCLUDE 
      imports C-CONFIGURATION
			
	rule [sequencePoint]:
		<k> sequencePoint => .K ...</k>
		<locsWrittenTo> _ => .Bag </locsWrittenTo>
		[structural, ndlocal]

	// fixme these should be computational, unless I handle that at a higher level
	rule [writeToFD-char]:
		<k> writeToFD(FD:Int, N:Int) => .K ...</k>
		<fid> FD:Int </fid>
		<buff> S:String => S:String +String charString(N:Int %Int 256) </buff>
		[observable]
	rule [writeToFD-string]:
		<k> writeToFD(FD:Int, S':String) => .K ...</k>
		<fid> FD:Int </fid>
		<buff> S:String => S:String +String S':String </buff>
		[observable]
	rule [readFromFD-char]:
		<k> readFromFD(FD:Int) => tv(asciiString(firstChar(S:String)), t(.Set, int))  ...</k>
		<fid> FD:Int </fid>
		<buff> S:String => butFirstChar(S:String) </buff>
		when lengthString(S:String) >Int 0 // don't compare with "" in order to only treat string sort
		[observable]
	rule [readFromFD-empty-buff]:
		<k> readFromFD(FD:Int) ...</k>
		<fid> FD:Int </fid>
		<buff> "" => "" +String charString(#fReadByte(FD:Int)) </buff>
		[structural]
	rule [readFromFD-eof]:
		<k> readFromFD(FD:Int) => tv(-1, t(.Set, int)) ...</k>
		<fid> FD:Int </fid>
		<buff> #EOF </buff>
		[observable]

// TODO(chathhorn): eof, ellided
//	rule [make-eof]:
//		"" +String charString(#EOF)
//			=> #EOF
//		[structural, anywhere]
		
	syntax K ::= "f-sent" "(" Int "," String ")"
	syntax K ::= "f-flush" "(" Int ")"
	syntax K ::= "f-sendString" "(" Int "," String ")"
	
	// can't lex string2KList correctly in #fPrint(N:Int,, string2KList(S:String))
	rule [flush]:
      <k> flush(N:Int) => .K ...</k>
      <fileCommands>... .K
            => f-sendString(N:Int, S:String)
            ~> f-sent(N:Int, S:String)
            ~> f-flush(N:Int)
      </fileCommands>
      <file>...
            <fid> N:Int </fid>
            <buff> S:String => "" </buff>
            <sending>... .List => ListItem(S:String) </sending>
      ...</file>
		[structural]

	rule [sendString-one]:
		<fileCommands> f-sendString(N:Int, S:String) 
			=> (#fPutByte(N:Int, asciiString(firstChar(S:String)))
			~> f-sendString(N:Int, butFirstChar(S:String)))
		...</fileCommands>
		when S:String =/=String ""
		[structural]
	rule [sendString-done]:
		<fileCommands> f-sendString(N:Int, "") => .K ...</fileCommands>
		[structural]

	rule [f-sent]:
		<files>...
			<fileCommands> f-sent(N:Int, S:String) => .K ...</fileCommands>
			<fid> N:Int </fid>
			<sending> ListItem(S:String) => .List ...</sending>
			<done>... .List => ListItem(S:String) </done>
		...</files>
		[structural]
	rule [f-flush]:
		<fileCommands> f-flush(N:Int) => #flush(N:Int) ...</fileCommands>
		[structural]
		
	rule [combine-done]:
		<done> (ListItem(S:String) ListItem(S':String) => ListItem(S:String +String S':String)) ...</done>
		[structural]
		
	syntax List ::= string2List(String) [function] 
                    | "string2List-aux" "(" String "," List ")" [function]
      //syntax "string2List" -/- [\-]
	rule string2List(S:String) => string2List-aux(S:String, .List)
	rule string2List-aux("", L:List) => L
	rule string2List-aux(S:String, L:List)
			=> string2List-aux(butFirstChar(S:String), (L:List ListItem(firstChar(S:String))))
		when S:String =/=String ""
		[structural]
endmodule

module DYNAMIC-C-SEMANTICS
	imports COMMON-C-SEMANTICS
	imports DYNAMIC-INCLUDE
	
	imports DYNAMIC-C-SEMANTICS-MISC
	imports DYNAMIC-C-EXPRESSIONS
      // TODO(chathhorn): xml, ellided
	//imports DYNAMIC-C-ERRORS
	imports DYNAMIC-C-TYPING 
	imports DYNAMIC-C-DECLARATIONS 
	imports DYNAMIC-C-MEMORY 
	imports DYNAMIC-C-STATEMENTS 
	imports DYNAMIC-C-CONVERSIONS 
	imports DYNAMIC-C-STANDARD-LIBRARY
	// imports DYNAMIC-C-LTL
	
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
	
	syntax K ::= "incomingArguments-aux" "(" KList "," Int ")"
	
	rule incomingArguments(L:KList) 
			=> incomingArguments-aux(L:KList, 0) 
		[structural]
	rule incomingArguments-aux((S:String,, L:KList), N:Int) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:Int] := Constant(StringLiteral(S:String)))
			~> incomingArguments-aux(L:KList, N:Int +Int 1)
		[structural]
	rule incomingArguments-aux(.KList, N:Int) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:Int] := NullPointer)
		[structural]
		
		
	syntax K ::= "syntaxInt" "(" Int ")"
	rule [syntaxInt]: syntaxInt(N:Int) => NoSuffix(DecimalConstant(N:Int)) [structural]
	
	syntax K ::= "pgmArgs" "(" KList ")" [function]
	syntax K ::= "argName" "(" KList ")" [function]
	rule
		argName(L:KList)
		=> Name(
			Identifier("#incomingArgumentsArray"), 
			PointerType(ArrayType(JustBase, syntaxInt((lengthKList L:KList) +Int 1), Specifier(klist(.KList))))
		)
	rule
		pgmArgs(L:KList)
		=> DeclarationDefinition(InitNameGroup(
			Specifier(klist(Char)), 
			klist(InitName(argName(L:KList), NoInit))
		))
		[structural]

	rule [eval-noInput]: eval(K:K) => eval(K:K, .KList, "", 0) [structural]
		
	/*@ These helpers are used to get around a bug in \K related to successive ``/''s in strings. */
	syntax K ::= "stdinStr" [function] | "stdoutStr" [function]
	
	rule stdinStr => "stdin:/" +String "/" +String "/"
	rule stdoutStr => "stdout:/" +String "/" +String "/"
	rule [eval-input]: eval(Program(klist(P:KList)), L:KList, Input:String, IsInterp:Int) =>
		<T>...
			<threads>
				<thread>...
					<k> klistToK(P:KList)
							~> pgmArgs(L:KList)
							~> resolveReferences					
							// ~> incomingArguments(L:KList)
							~> callMain(lengthKList L:KList, incomingArguments(L:KList))
					</k>
					<br/>
					<threadId> 1 </threadId>
					<nextLoc> firstLoc(1) </nextLoc>
					<threadLocal>...
						<control>...
							<currentFunction> file-scope </currentFunction>
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
		[structural, large]

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
		<k> callMain(N:Int, Args:K)
			=> callMain-aux(typeof(Identifier("main")), N:Int, Identifier("#incomingArgumentsArray"), Args:K)
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
		callMain-aux(t(.Set, functionType(t(.Set, int), typedDeclaration(t(.Set, void), _:Id))), N:Int, X:Id, _) 
			=> Call(Identifier("main"), klist(.KList))
		[structural]
	rule
		callMain-aux(t(.Set, functionType(t(.Set, int), .KList)), N:Int, X:Id, _) 
			=> Call(Identifier("main"), klist(.KList))
		[structural]
	rule
		callMain-aux(t(.Set, functionType(t(.Set, int), (typedDeclaration(t(.Set, int), _:Id),, typedDeclaration(t(.Set, incompleteArrayType(t(.Set, pointerType(T:KResult)))), _:Id)))), N:Int, X:Id, Args:K)
			=> Args:K 
			~> Call(Identifier("main"), klist((N:Int,, X:Id)))
		when T:KResult ==K t(.Set, char)
		[structural]
	rule
		callMain-aux(t(.Set, functionType(t(.Set, int), (typedDeclaration(t(.Set, int), _:Id),, typedDeclaration(t(.Set, pointerType(t(.Set, pointerType(T:KResult)))), _:Id)))), N:Int, X:Id, Args:K)
			=> Args:K 
			~> Call(Identifier("main"), klist((N:Int,, X:Id)))
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
endmodule
