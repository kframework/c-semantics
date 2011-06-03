load dynamic-c-configuration
load common-c-semantics

kmod DYNAMIC-SEMANTIC-SYNTAX is
	including COMMON-INCLUDE
endkm

kmod DYNAMIC-INCLUDE is
	including DYNAMIC-SEMANTIC-SYNTAX
	including DYNAMIC-C-CONFIGURATION
endkm

kmod DYNAMIC-C-SEMANTICS-MISC is
	including DYNAMIC-INCLUDE 
			
	rule [sequencePoint]:
		< k > sequencePoint => .K ...</ k >
		< locsWrittenTo > ? => .Bag </ locsWrittenTo >
		[structural metadata "nd=(true)"]
						
	// fixme these should be computational, unless I handle that at a higher level
	rule [writeToFD-char]:
		< k > writeToFD(FD:Nat, N:Nat) => .K ...</ k >
		< openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		< files >... Filename:String |-> (S:String => S:String +String charString(N:Nat %Nat 256)) ...</ files >
		[structural]
	rule [writeToFD-string]:
		< k > writeToFD(FD:Nat, S':String) => .K ...</ k >
		< openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		< files >... Filename:String |-> (S:String => S:String +String S':String) ...</ files >
		[structural]
	rule [readFromFD-char]:
		< k > readFromFD(FD:Nat) => tv(charToAscii(firstChar(S:String)), int)  ...</ k >
		< openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		< files >... Filename:String |-> (S:String => butFirstChar(S:String)) ...</ files >
		if S:String =/=Bool ""
		[structural]
	rule [readFromFD-char-eof]:
		< k > readFromFD(FD:Nat) => tv(-1, int) ...</ k > // -1 should be EOF
		< openFiles >... FD:Nat |-> Filename:String ...</ openFiles >
		< files >... Filename:String |-> (S:String => butFirstChar(S:String)) ...</ files >
		if S:String ==Bool ""
		[structural]
endkm

load dynamic-c-expressions
load dynamic-c-conversions
load dynamic-c-statements
load dynamic-c-standard-lib
load dynamic-c-typing
load dynamic-c-memory
load dynamic-c-declarations

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
	
	op incomingArguments-aux : List{K} Nat -> K
	
	rule incomingArguments(L:List{K}) 
			=> incomingArguments-aux(L:List{K}, 0) 
		[structural]
	rule incomingArguments-aux((S:String,, L:List{K}), N:Nat) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:Nat] := Constant(StringLiteral(S:String)))
			~> incomingArguments-aux(L:List{K}, sNat(N:Nat))
		[structural]
	rule incomingArguments-aux(.List{K}, N:Nat) 
			=> Computation(Identifier("#incomingArgumentsArray")[N:Nat] := NullPointer)
		[structural]
		
		
	op syntaxNat : Nat -> K
	rule syntaxNat(N:Nat) => NoSuffix(DecimalConstant(N:Nat)) [structural]
	
	rule eval(K:K) => eval(K:K, .List{K}, "") [structural]
	rule eval(Program(P:List{C}), L:List{K}, Input:String) =>
		< T >
			< threads >
				< thread >
					< control >
						< k > listToK(P:List{C})
							~> DeclarationDefinition(InitNameGroup(Specifier(Char), InitName(Name(Identifier("#incomingArgumentsArray"), PointerType(ArrayType(JustBase, syntaxNat(sNat(lengthList{K} L:List{K}))))), NoInit)))
							~> resolveReferences					
							// ~> incomingArguments(L:List{K})
							~> callMain(lengthList{K}(L:List{K}), Identifier("#incomingArgumentsArray"), incomingArguments(L:List{K}))
						</ k >
						< currentFunction > File-Scope </ currentFunction >
						< currentProgramLoc > UnknownCabsLoc </ currentProgramLoc >
					...</ control >
					< threadId > 1 </ threadId >
					< nextLoc > sym(threadId(1) +Nat 0) +Nat 0 </ nextLoc >
				...</ thread >
			</ threads >
			<nextSharedLoc> sym(threadId(0) +Nat 0) +Nat 0 </nextSharedLoc>
			< nextFile > 3 </ nextFile >
			< openFiles >
				0 |-> "stdin" // stdin
				1 |-> "stdout" // stdout
				2 |-> "stdout" // stderr
			</ openFiles >
		...</ T >
		< files > 
			"stdin" |-> Input:String
			"stdout" |-> ""
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
	
	rule < k > callMain(N:Nat, X:Id, Args:K)
			=> callMain-aux(typeof(Identifier("main")), N:Nat, X:Id, Args:K)
		...</ k >
		< functionTranslationUnits >... Tu:K |-> Map((? Identifier("main") |-> Tu:K)) ...</ functionTranslationUnits >
		< currentTranslationUnit > ? => Tu:K </ currentTranslationUnit >
		[structural]
	
	// FIXME i think these are slightly different
	// fixme void isn't supposed to have a name
	// fixme figure out type of string
	rule callMain-aux(functionType(int, typedDeclaration(void, ?)), N:Nat, X:Id, ?) => Call(Identifier("main"), Nil) [structural]
	rule callMain-aux(functionType(int, Nil), N:Nat, X:Id, ?) => Call(Identifier("main"), Nil) [structural]
	rule callMain-aux(functionType(int, (typedDeclaration(int, ?) :: typedDeclaration(incompleteArrayType(pointerType(T:Type)), ?))), N:Nat, X:Id, Args:K)
		=> Args:K ~> Call(Identifier("main"), N:Nat :: X:Id)
		if T:Type ==Bool char
		[structural]
	rule callMain-aux(functionType(int, (typedDeclaration(int, ?) :: typedDeclaration(pointerType(pointerType(T:Type)), ?))), N:Nat, X:Id, Args:K)
		=> Args:K ~> Call(Identifier("main"), N:Nat :: X:Id)
		if T:Type ==Bool char
		[structural]


	// fixme I'm not sure threads clean up their memory
	
	rule [terminate]:
		(< T >... < threads >... < thread >... 
			< threadId > 1 </ threadId > // main's thread, not the global "thread"
			< k > V:Value </ k >
		...</ thread > ...</ threads > ...</ T >
			=> < resultValue > V:Value </ resultValue >)
		< files >...
			"stdin" |-> S1:String	"stdout" |-> S2:String => .Map
		...</ files >
		(.Bag => < input > S1:String </ input >	< output > S2:String </ output >)
		
endkm
