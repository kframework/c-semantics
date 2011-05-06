// this file is an experiment in progress.  please ignore it if you're looking to read the semantics.

load static-c-configuration
load common-c-semantics

kmod STATIC-SEMANTIC-SYNTAX is
	including COMMON-INCLUDE
endkm

kmod STATIC-INCLUDE is
	including STATIC-SEMANTIC-SYNTAX
	including STATIC-C-CONFIGURATION
endkm

kmod STATIC-C-SEMANTICS-MISC is
	including STATIC-INCLUDE
endkm

load static-c-statements
load static-c-declarations
load static-c-typing

kmod STATIC-C-SEMANTICS is
	including COMMON-C-SEMANTICS
	including STATIC-INCLUDE
	
	including STATIC-C-STATEMENTS
	including STATIC-C-DECLARATIONS
	including STATIC-C-TYPING
	
	op syntaxNat : Nat -> K
	rule syntaxNat(N:Nat) => Constant(IntLiteral(NoSuffix(DecimalConstant(N:Nat)))) [structural]
	
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
	
	including STATIC-C-SEMANTICS-MISC
	//including STATIC-C-EXPRESSIONS
endkm
