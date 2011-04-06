kmod DYNAMIC-C-SEMANTICS is
	including COMMON-C-SEMANTICS
		
/*@ \source{C99 5.1.2.2.1:2}
If they are declared, the parameters to the main function shall obey the following constraints:
\begin{itemize}
\item The value of argc shall be nonnegative.
\item argv[argc] shall be a null pointer.
\item If the value of \cinline{argc} is greater than zero, the array members \cinline{argv[0]} through \cinline{argv[argc-1]} inclusive shall contain pointers to strings, which are given implementation-defined values by the host environment prior to program startup. The intent is to supply to the program information determined prior to program startup from elsewhere in the hosted environment. If the host environment is not capable of supplying strings with letters in both uppercase and lowercase, the implementation shall ensure that the strings are received in lowercase. 
\item If the value of argc is greater than zero, the string pointed to by \cinline{argv[0]} represents the program name; \cinline{argv[0][0]} shall be the null character if the program name is not available from the host environment. If the value of argc is greater than one, the strings pointed to by \cinline{argv[1]} through argv[argc-1] represent the program parameters.
\item The parameters argc and argv and the strings pointed to by the argv array shall be modifiable by the program, and retain their last-stored values between program startup and program termination.
\end{itemize}
*/
	op incomingArguments : List{K} -> K
	op incomingArguments-aux : List{K} Nat -> K
	
	eq incomingArguments(L:List{K}) = incomingArguments-aux(L:List{K}, 0)
	eq incomingArguments-aux((S:String,, L:List{K}), N:Nat) 
		= (Identifier("#incomingArgumentsArray")[N:Nat] := StringLiteral(S:String))
			~> discard
			~> incomingArguments-aux(L:List{K}, sNat(N:Nat))
	eq incomingArguments-aux(.List{K}, N:Nat) 
		= (Identifier("#incomingArgumentsArray")[N:Nat] := NullPointer)
			~> discard

/*@ \source{C99 5.1.2.2.1:1}
The function called at program startup is named main. The implementation declares no prototype for this function. It shall be defined with a return type of int and with no parameters:
\clisting{int main(void) { ... }}
or with two parameters (referred to here as argc and argv, though any names may be used, as they are local to the function in which they are declared):
\clisting{int main(int argc, char *argv[]) { ... }}
or equivalent;9) or in some other implementation-defined manner
*/

	//@ this bit of indirection is used to check that the main prototype is correct, and to call it with the appropriate arguments
	op callMain : Nat Id -> K
	op callMain-aux : K Nat Id -> K [strict(1)]
	
	op startMainThread : -> K --- used only to start main thread
	
	rule < k > callMain(N:Nat, X:Id)
			=> callMain-aux(typeof(Identifier("main")), N:Nat, X:Id)
		...</ k >
		< functionTranslationUnits >... Tu:K |-> Map((? Identifier("main") |-> Tu:K)) ...</ functionTranslationUnits >
		< currentTranslationUnit > ? => Tu:K </ currentTranslationUnit >
		[structural]
	
	--- FIXME i think these are slightly different
	--- fixme void isn't supposed to have a name
	--- fixme figure out type of string
	eq callMain-aux(functionType(int, typedDeclaration(void, ?)), N:Nat, X:Id) = Call(Identifier("main"), Nil)
	eq callMain-aux(functionType(int, Nil), N:Nat, X:Id) = Call(Identifier("main"), Nil)
	ceq callMain-aux(functionType(int, (typedDeclaration(int, ?) :: typedDeclaration(incompleteArrayType(pointerType(T:Type)), ?))), N:Nat, X:Id)
		= Call(Identifier("main"), N:Nat :: X:Id)
		if T:Type ==Bool char
	ceq callMain-aux(functionType(int, (typedDeclaration(int, ?) :: typedDeclaration(pointerType(pointerType(T:Type)), ?))), N:Nat, X:Id)
		= Call(Identifier("main"), N:Nat :: X:Id)
		if T:Type ==Bool char

	op syntaxNat : Nat -> K
	eq syntaxNat(N:Nat) = Constant(IntLiteral(NoSuffix(DecimalConstant(N:Nat))))
	
	
	eq eval(K:K) = eval(K:K, .List{K}, "")
	eq eval(Program(P:List{C}), L:List{K}, Input:String) = 
		< T >
			< threads >
				< thread >
					< control >
						< k > listToK(P:List{C})
							~> DeclarationDefinition(InitNameGroup(Specifier(Char), (InitName(AttributeWrapper(NameLoc(Name(Identifier("#incomingArgumentsArray"), AttributeWrapper(PointerType(AttributeWrapper(ArrayType(JustBase, syntaxNat(sNat(lengthList{K} L:List{K}))), Nil)), Nil)), UnknownCabsLoc), Nil), NoInit))))
							~> resolveReferences							
							~> incomingArguments(L:List{K})
							~> callMain(lengthList{K}(L:List{K}), Identifier("#incomingArgumentsArray"))
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
				0 |-> "stdin" --- stdin
				1 |-> "stdout" --- stdout
				2 |-> "stdout" --- stderr
			</ openFiles >
		...</ T >
		< files > 
			"stdin" |-> Input:String
			"stdout" |-> ""
		</ files >
		< xmessages > .K </ xmessages >
		

	--- fixme I'm not sure threads clean up their memory
	
	rule [terminate]:
		(< T >... < threads >... < thread >... 
			< threadId > 1 </ threadId > --- main's thread, not the global "thread"
			< k > V:Value </ k >
		...</ thread > ...</ threads > ...</ T >
			=> < resultValue > V:Value </ resultValue >)
		< files >...
			"stdin" |-> S1:String	"stdout" |-> S2:String => .Map
		...</ files >
		(.Bag => < input > S1:String </ input >	< output > S2:String </ output >)
		
endkm
