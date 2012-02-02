kmod DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE is
	including DYNAMIC-INCLUDE 
	including COMMON-SEMANTICS-DECLARATIONS-INCLUDE

endkm

kmod DYNAMIC-SEMANTICS-DECLARATIONS-BINDING is
	including DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 

	// empty binding
	// fixme not really a sequence point
	
	op bind-aux : #Nat List{KResult} List{KResult} -> K 
	rule
		< k > bind(L:List{KResult}, L':List{KResult}) 
			=> bind-aux(NullPointer, L:List{KResult}, L':List{KResult}) ...</ k > 
		[structural] 
	
	rule [bind-empty-void]:
		< k > bind-aux(?:#Nat, .List{K}, typedDeclaration(t(.Set, void), ?)) => sequencePoint ...</ k > 
		[structural] 
	rule [bind-empty]:
		< k > bind-aux(?:#Nat, .List{K}, .List{K}) => sequencePoint ...</ k > 
		[structural] 
		
		
	// n1494 6.5.2.2:6 If the expression that denotes the called function has a type that does not include a prototype, the integer promotions are performed on each argument, and arguments that have type float are promoted to double. These are called the default argument promotions. If the number of arguments does not equal the number of parameters, the behavior is undefined. If the function is defined with a type that includes a prototype, and either the prototype ends with an ellipsis (, ...) or the types of the arguments after promotion are not compatible with the types of the parameters, the behavior is undefined. If the function is defined with a type that does not include a prototype, and the types of the arguments after promotion are not compatible with those of the parameters after promotion, the behavior is undefined, except for the following cases: 
	// -- one promoted type is a signed integer type, the other promoted type is the corresponding unsigned integer type, and the value is representable in both types;
	// -- both types are pointers to qualified or unqualified versions of a character type or void
	
	rule [bind-coerce-array]:
		bind-aux(
			?:#Nat
			, L:List{KResult}
			, (
				?:List{KResult}
				,, typedDeclaration(
					(t(?, (arrayType(T:Type, ?:#Nat) => pointerType(T:Type))))
					, X:#Id
				)
				,, ?:List{KResult}
			)
		)
		[structural] 
	rule [bind-coerce-incompleteArray]:
		bind-aux(
			?:#Nat
			, L:List{KResult}
			, (
				?:List{KResult} 
				,, typedDeclaration(
					(t(?, (incompleteArrayType(T:Type) => pointerType(T:Type))))
					, X:#Id
				) 
				,, ?:List{KResult})
		)
		[structural] 
		
	rule [bind-one]:
		< k > true ~> bind-aux(?:#Nat, (tv(V:List{K}, T':Type),, L:List{KResult}), (typedDeclaration(T:Type, X:#Id),, P:List{KResult}))
			=> allocateType(Loc:#Nat, T:Type)
			~> addToEnv(X:#Id, Loc:#Nat)
			~> giveType(X:#Id, T:Type)
			~> initialize(X:#Id, T:Type, Computation(AllowWrite(X:#Id) := tv(V:List{K}, T':Type)))
			~> bind-aux(Loc:#Nat, L:List{KResult}, P:List{KResult})
		...</ k > 
		< nextLoc > Loc:#Nat => inc(Loc:#Nat) </ nextLoc >
		< localAddresses >... .Set => SetItem(Loc:#Nat) ...</ localAddresses >
		when notBool hasArrayType(T:Type)
		[structural] 
		
	rule [bind-one-check-type]:
		< k > (.K => isTypeCompatible(T:Type, T':Type)) 
			~> bind-aux(?:#Nat, (tv(V:List{K}, T':Type),, L:List{KResult}), (typedDeclaration(T:Type, X:#Id),, P:List{KResult}))
		...</ k > 
		[structural] 
	
	op promoteList : List{KResult} -> List{K} 
	rule [promoteList-needs-promoting]: promoteList((tv(V:List{K}, t(S:Set, T:SimpleType)),, L:List{KResult})) 
		=> cast(argPromote(t(S:Set, T:SimpleType)), tv(V:List{K}, t(S:Set, T:SimpleType))),, promoteList(L:List{KResult})
		when ((rank(t(S:Set, T:SimpleType)) <Int rank(t(.Set, int)) orBool hasBitfieldType(t(S:Set, T:SimpleType))) andBool hasIntegerType(t(S:Set, T:SimpleType))) 
		orBool T:SimpleType ==Bool float 
		[structural]
	rule [promoteList-promoted]: promoteList((tv(V:List{K}, t(S:Set, T:SimpleType)),, L:List{KResult})) 
		=> (tv(V:List{K}, t(S:Set, T:SimpleType)),, promoteList(L:List{KResult}))
		when (notBool(hasIntegerType(t(S:Set, T:SimpleType))) 
			andBool notBool T:SimpleType ==Bool float
			andBool notBool hasArrayType(t(S:Set, T:SimpleType))
		) 
		orBool rank(t(S:Set, T:SimpleType)) >=Int rank(t(.Set, int))
		orBool T:SimpleType ==Bool double 
		orBool T:SimpleType ==Bool long-double
		[structural]
	rule promoteList(.List{K}) => .List{K} [structural]
	
	op bindVariadic : K List{KResult} -> K 
	op bindVariadic-pre : K List{K} -> K 
	
	
	// the idea here is that there should have been a previous argument, so we can use its address to append all of the variadic arguments	
	rule [bind-variadic-pre]:
		< k > bind-aux(Loc:#Nat, L:List{KResult}, t(?, variadic))
			=> bindVariadic-pre(Loc:#Nat, promoteList(L:List{KResult}))
		...</ k >
		[structural] 

	rule [bind-variadic-start]:
		< k > bindVariadic-pre(Loc:#Nat, L:List{KResult}) 
			=> bindVariadic(Loc:#Nat, L:List{KResult})
		...</ k >
		[structural]
	
	// fixme don't forget to get rid of append
	
	// this rule assumes it will be run immediately after other normal bindings for the same function.  This is all wrong if it is computational instead of structural because of other threads interleaving
	rule [bind-variadic]:
		< k > (.K 
				=> allocateType(Loc:#Nat, Type)
				~> Computation(*(tv(Loc:#Nat, t(.Set, pointerType(Type)))) := V:Value)
			) 
			~> bindVariadic(?, ((V:Value => .List{K}),, ?:List{KResult})) 
		...</ k >
		< nextLoc > Loc:#Nat => inc(Loc:#Nat) </ nextLoc >
		< localAddresses >... .Set => SetItem(Loc:#Nat) ...</ localAddresses >
		where Type = type(V:Value)
		[structural]
	
	rule [bind-variadic-done]:
		< k > bindVariadic(?, .List{K}) => sequencePoint ...</ k > 
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-DECLARATIONS-GENERAL is
	including DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 
	
	
	// c1x 6.7.8:21 ... the remainder of the aggregate shall be initialized implicitly the same as objects that have static storage duration
	rule
		< k > initialize(X:#Id, T:Type, K:K)
			=> if (F:#Id ==Bool File-Scope) then zero(X:#Id) else (.) fi 
			~> K:K
			~> sequencePoint
		...</ k >
		< currentFunction > F:#Id </ currentFunction >
		[structural] 

	rule
		< k > zero(Name:K) => zeroType(Name:K, unqualifyType(T:Type)) ...</ k >
		< types >... Name:K |-> T:Type ...</ types >
		[structural] 
		
	op zeroType : K Type -> K 
	
	rule
		< k > zeroType(Name:K, T:Type) 
			=> Computation(AllowWrite(Name:K) := tv(0, t(.Set, int))) ...</ k >
		when hasIntegerType(T:Type)
		[structural] 
	rule
		< k > zeroType(Name:K, T:Type) 
			=> Computation(AllowWrite(Name:K) := tv(0.0, t(.Set, float))) ...</ k >
		when hasFloatType(T:Type)
		[structural] 
		
	op zeroStruct : K List{KResult} -> K 
	
	// c1x 6.7.9:10 If an object that has automatic storage duration is not initialized explicitly, its value is indeterminate. If an object that has static or thread storage duration is not initialized explicitly, then:
	// -- if it has pointer type, it is initialized to a null pointer;
	// -- if it has arithmetic type, it is initialized to (positive or unsigned) zero;
	// -- if it is an aggregate, every member is initialized (recursively) according to these rules, and any padding is initialized to zero bits;
	// -- if it is a union, the first named member is initialized (recursively) according to these rules, and any padding is initialized to zero bits;
	
	rule
		< k > zeroType(Name:K, t(?, structType(S:#Id))) 
			=> zeroStruct(Name:K, Fields:List{KResult})
		...</ k >
		< structs >... S:#Id |-> aggregateInfo(Fields:List{KResult}, ?, ?) ...</ structs > 
		[structural] 
		
	rule
		< k > zeroType(Name:K, t(?, unionType(S:#Id))) 
			=> zeroType(Name:K . F:#Id, T:Type)
		...</ k >
		< structs >... 
			S:#Id |-> aggregateInfo((typedDeclaration(T:Type, F:#Id),, ?), ?, ?) 
		...</ structs > 
		[structural] 
		
	rule
		< k > zeroStruct(Name:K, (typedDeclaration(T:Type, F:#Id),, L:List{KResult})) 
			=> zeroType(Name:K . F:#Id, T:Type)
			~> zeroStruct(Name:K, L:List{KResult}) 
		...</ k >
		[structural] 
	rule
		< k > zeroStruct(Name:K, .List{K}) => .K ...</ k >
		[structural] 

	rule
		< k > zeroType(Name:K, T:Type) 
			=> Computation(AllowWrite(Name:K) := tv(NullPointer, T:Type)) ...</ k >
		when hasPointerType(T:Type)
		[structural]
	rule
		< k > zeroType(Name:K, T:Type) => .K ...</ k >
		when hasFunctionType(T:Type)
		[structural]
		
	rule
		< k > zeroType(Name:K, t(S:Set, arrayType(T:Type, sNat(Len:#Nat)))) 
			=> zeroType(Name:K[Len:#Nat], T:Type)
			~> zeroType(Name:K, t(S:Set, arrayType(T:Type, Len:#Nat))) 
		...</ k >
		[structural] 
	rule
		< k > zeroType(Name:K, t(?, arrayType(T:Type, 0))) => .K ...</ k >
		[structural] 

	rule
		< k > zeroType(Name:K, t(?, flexibleArrayType(T:Type)))
			=> .K
		...</ k >
		[structural]
endkm

kmod DYNAMIC-SEMANTICS-DECLARATIONS-INITIALIZATIONS is
	including DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 
endkm


kmod DYNAMIC-SEMANTICS-DECLARATIONS-RESOLUTION is
	including DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 
endkm

kmod DYNAMIC-SEMANTICS-DECLARATIONS-ENUMS is
	including DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 
endkm

kmod DYNAMIC-C-DECLARATIONS is
	including DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE
	
	including DYNAMIC-SEMANTICS-DECLARATIONS-BINDING 
	including DYNAMIC-SEMANTICS-DECLARATIONS-GENERAL 
	including DYNAMIC-SEMANTICS-DECLARATIONS-INITIALIZATIONS 
	including DYNAMIC-SEMANTICS-DECLARATIONS-ENUMS 
	including DYNAMIC-SEMANTICS-DECLARATIONS-RESOLUTION 
endkm
