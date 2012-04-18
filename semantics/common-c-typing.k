// FIXME need to automatically pad structs
kmod COMMON-SEMANTICS-TYPE-INCLUDE is
	including COMMON-INCLUDE 
	
	op MYHOLE : -> K 
	
	op addStruct : #Id List{KResult} -> K 
	op addUnion : #Id List{KResult} -> K 
	op canonicalizeType : Bag -> K 
	
	declare extractActualType : Type -> Type // rules that use specifier should be careful to use extractActualType if going to be used in a typed name
	
	op evalToType : -> K 
	
	declare typeStrictUnaryOperators : -> Set // [memo] 
	define typeStrictUnaryOperators => Set(
		l('-_),, l('+_),, l('*_),, l('&_),, l('~_)
	)
	[structural]
	
	declare typeStrictBinaryOperators : -> Set // [memo] 
	define typeStrictBinaryOperators => Set(
		l('_*_),, l('_/_),, l('_%_),,
		l('_+_),, l('_-_),,
		l('_<_),, l('_>_),, l('_<=_),, l('_>=_),,
		l('_&_),, l('_|_),, l('_^_),,
		l('_`[_`])
	)
	[structural]
	
	declare typeStrictLeftBinaryOperators : -> Set // [memo] 
	define typeStrictLeftBinaryOperators => Set(
		l('_<<_),, l('_>>_),,
		l('_*=_),, l('_/=_),, l('_%=_),, l('_+=_),, l('_-=_),, 
		l('_<<=_),, l('_>>=_),, l('_&=_),, l('_^=_),, l('_|=_),,
		l('_++),, l('_--),, l('--_),, l('++_)
	) 
	[structural]
endkm

kmod COMMON-SEMANTICS-TYPE-DECLARATIONS is
	including COMMON-SEMANTICS-TYPE-INCLUDE 

	op giveGlobalType : K Type -> K 
	op giveLocalType : K Type -> K 
	
	// FIXME these are here until I decide how to handle qualified types
	rule [ignore-volatile]: t(S:Set, qualifiedType(t(S':Set, T:K), Volatile)) 
		=> t(S:Set S':Set, T:K) 
		[structural anywhere]
	rule [ignore-atomic]: t(S:Set, qualifiedType(t(S':Set, T:K), Atomic)) 
		=> t(S:Set S':Set, T:K) 
		[structural anywhere]
	rule [ignore-restrict]: t(S:Set, qualifiedType(t(S':Set, T:K), Restrict)) 
		=> t(S:Set S':Set, T:K) 
		[structural anywhere]
	// rule [ignore-const]: t(S:Set, qualifiedType(t(S':Set, T:K), Const)) 
		// => t(S:Set S':Set, T:K) 
		// [structural]
	rule [ignore-auto]: t(S:Set, qualifiedType(t(S':Set, T:K), Auto)) 
		=> t(S:Set S':Set, T:K) 
		[structural anywhere]
	rule [ignore-register]: t(S:Set, qualifiedType(t(S':Set, T:K), Register)) 
		=> t(S:Set S':Set, T:K)
		[structural anywhere]
	
	
	rule
		< k > giveType(X:#Id, T:KResult) => 
			if (Fun:#Id ==Bool File-Scope) then giveGlobalType(X:#Id, unqualifyType(T:KResult)) else giveLocalType(X:#Id, unqualifyType(T:KResult)) fi
			...</ k >
		< currentFunction > Fun:#Id </ currentFunction >
		// when notBool hasStaticType(T:KResult)
		[structural] 
		
	rule
		< k > giveGlobalType(X:#Id, T:KResult) => .K ...</ k >
		< types > M:Map => M:Map[T:KResult / X:#Id] </ types >
		< gtypes >... Tu:K |-> Map((M':Map => M':Map[T:KResult / X:#Id])) ...</ gtypes >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		[structural] 
	rule
		< k > giveLocalType(X:#Id, T:KResult) => .K ...</ k >
		< types > M:Map => M:Map[T:KResult / X:#Id] </ types >
		[structural]	
endkm

kmod COMMON-SEMANTICS-TYPE-STRICTNESS is
	including COMMON-SEMANTICS-TYPE-INCLUDE

	op waitingOnDeclType : -> K 
	rule [type-Cast-heat]:
		< k > (. => DeclType(Specifier:K, DeclType:K)) ~> evalToType ...</ k >
		< type > Cast(Specifier:K, DeclType:K, _) => waitingOnDeclType ...</ type >
		[structural] 
		
	rule [type-Cast-cool]:
		< k > (T:KResult => .) ~> evalToType ...</ k >
		< type > waitingOnDeclType => T:KResult ...</ type >
		[structural] 
		
	rule [type-ternary-heat-left]:
		< type > K1:K ? K2:K : K3:K => K2:K ~> K1:K ? MYHOLE : K3:K ...</ type >
		when notBool isAType(K2:K)
		[structural] 
	rule [type-ternary-cool-left]:
		< type > T:KResult ~> K1:K ? MYHOLE : K3:K => K1:K ? T:KResult : K3:K ...</ type >
		when isAType(T:KResult)
		[structural] 
	rule [type-ternary-heat-right]:
		< type > K1:K ? K2:K : K3:K => K3:K ~> K1:K ? K2:K : MYHOLE ...</ type >
		when notBool isAType(K3:K)
		[structural] 
	rule [type-ternary-cool-right]:
		< type > T:KResult ~> K1:K ? K2:K : MYHOLE => K1:K ? K2:K : T:KResult ...</ type >
		when isAType(T:KResult)
		[structural] 
		
	rule [type-bin-arith-heat-left]:
		< type > L:KLabel(K:K,, K':K) => K:K ~> L:KLabel(MYHOLE,, K':K) ...</ type >
		when notBool isAType(K:K)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-arith-cool-left]:
		< type > T:KResult ~> L:KLabel(MYHOLE,, K:K) => L:KLabel(T:KResult,, K:K) ...</ type >
		when isAType(T:KResult)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-arith-heat-right]:
		< type > L:KLabel(K:K,, K':K) => K':K ~> L:KLabel(K:K,, MYHOLE) ...</ type >
		when notBool isAType(K':K)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-arith-cool-right]:
		< type > T:KResult ~> L:KLabel(K:K,, MYHOLE) => L:KLabel(K:K,, T:KResult) ...</ type >
		when isAType(T:KResult)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
		
	rule [type-unary-arith-heat]:
		< type > L:KLabel(K:K) => K:K ~> L:KLabel(MYHOLE) ...</ type >
		when notBool isAType(K:K)
		andBool typeStrictUnaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-unary-arith-cool]:
		< type > T:KResult ~> L:KLabel(MYHOLE) => L:KLabel(T:KResult) ...</ type >
		when isAType(T:KResult)
		andBool typeStrictUnaryOperators contains l(L:KLabel)
		[structural] 
		
	rule [type-bin-left-arith-heat]:
		< type > L:KLabel(K:K,, Args:List{K}) => K:K ~> L:KLabel(MYHOLE,, Args:List{K}) ...</ type >
		when notBool isAType(K:K)
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-left-arith-cool]:
		< type > T:KResult ~> L:KLabel(MYHOLE,, Args:List{K}) => L:KLabel(T:KResult,, Args:List{K}) ...</ type >
		when isAType(T:KResult)
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural] 

		
	rule [type-dot-heat]:
		< type > K:K . X:#Id => K:K ~> MYHOLE . X:#Id ...</ type >
		when notBool isAType(K:K)
		[structural] 
	rule [type-dot-cool]:
		< type > T:KResult ~> MYHOLE . X:#Id => T:KResult . X:#Id ...</ type >
		when isAType(T:KResult)
		[structural]
		
	rule [type-call-heat]:
		< type > Call(K:K, L:K) => K:K ~> Call(MYHOLE, L:K) ...</ type >
		when notBool isAType(K:K)
		[structural] 
	rule [type-call-cool]:
		< type > T:KResult ~> Call(MYHOLE, L:K) => Call(T:KResult, L:K) ...</ type >
		when isAType(T:KResult)
		[structural] 
endkm

kmod COMMON-SEMANTICS-TYPE-CANONICALIZATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	
	op canonicalizeType-aux : Bag K Bag Bag Bag -> K 
	context canonicalizeType-aux(_,HOLE,_,_,_) when HOLE =/=Bool .K 

		
	rule
		< k > canonicalizeType(B:Bag) => canonicalizeType-aux(B:Bag, .K, .Bag, .Bag, .Bag) ...</ k >
		[structural] 
		

	
	rule
		< k > (.K => DeclType(K1:K, K2:K))
			~> canonicalizeType-aux((_:Bag BagItem(TAtomic(K1:K, K2:K))), _, _, _, _) 
		...</ k >
		[structural]
	rule
		< k > (.K => DeclType(K1:K, K2:K))
			~> canonicalizeType-aux((_:Bag BagItem(AlignasType(K1:K, K2:K))), _, _, _, _) 
		...</ k >
		[structural]
	rule
		< k > (.K => typeof(K1:K))
			~> canonicalizeType-aux((_:Bag BagItem(AlignasExpression(K1:K))), _, _, _, _) 
		...</ k >
		[structural]
		
	op atomic : Type -> K
	op alignas : Type -> K
	
	rule
		< k > (T:KResult => .K)
			~> canonicalizeType-aux((_:Bag (BagItem(TAtomic(K1:K, K2:K)) => .Bag)), _, (_ (.Bag => BagItem(atomic(T:KResult)))), _, _) 
		...</ k >
			when isAType(T:KResult)
		[structural]
	rule
		< k > (T:KResult => .K)
			~> canonicalizeType-aux((_:Bag (BagItem(AlignasType(K1:K, K2:K)) => .Bag)), _, (_ (.Bag => BagItem(alignas(T:KResult)))), _, _) 
		...</ k >
			when isAType(T:KResult)
		[structural]
	rule
		< k > (T:KResult => .K)
			~> canonicalizeType-aux((_:Bag (BagItem(AlignasExpression(K1:K)) => .Bag)), _, (_ (.Bag => BagItem(alignas(T:KResult)))), _, _) 
		...</ k >
			when isAType(T:KResult)
		[structural]
		
	// specifier, modifier, storage
	rule
		< k > canonicalizeType-aux((_:Bag (BagItem(T:K) => .Bag)), _, (_ (.Bag => BagItem(T:K))), _, _) ...</ k >
		when false
		orBool (T:K ==Bool Void)
		orBool (T:K ==Bool Bool)
		orBool (T:K ==Bool Char)
		orBool (T:K ==Bool Short)
		orBool (T:K ==Bool Int)
		orBool (T:K ==Bool Long)
		orBool (T:K ==Bool Float)
		orBool (T:K ==Bool Double)
		orBool (T:K ==Bool Signed)
		orBool (T:K ==Bool Unsigned)
		orBool (T:K ==Bool Complex)
		orBool (T:K ==Bool Imaginary)
		orBool (getKLabel(T:K) ==Bool 'StructDef)
		orBool (getKLabel(T:K) ==Bool 'UnionDef)
		orBool (getKLabel(T:K) ==Bool 'EnumDef)
		orBool (getKLabel(T:K) ==Bool 'StructRef)
		orBool (getKLabel(T:K) ==Bool 'UnionRef)
		orBool (getKLabel(T:K) ==Bool 'EnumRef)
		orBool (getKLabel(T:K) ==Bool 'Named)
		orBool (getKLabel(T:K) ==Bool 'Attribute)
		[structural] 

	rule
		< k > canonicalizeType-aux(B:Bag (BagItem(T:K) => .Bag), _, _, _, (_ .Bag => BagItem(T:K))) ...</ k >
		when T:K ==Bool Extern
		orBool T:K ==Bool Static
		orBool T:K ==Bool Const
		orBool T:K ==Bool Volatile
		orBool T:K ==Bool Atomic
		orBool T:K ==Bool Restrict
		orBool T:K ==Bool Auto
		orBool T:K ==Bool Register
		orBool T:K ==Bool ThreadLocal
		[structural] 
		
	rule
		< k > canonicalizeType-aux(.Bag, (T:KResult => t(.Set, qualifiedType(T:KResult, Q:K))), .Bag, .Bag, (_ BagItem(Q:K) => .Bag)) ...</ k >
		when Q:K ==Bool Extern
		orBool Q:K ==Bool Static
		orBool Q:K ==Bool Volatile
		orBool Q:K ==Bool Atomic
		orBool Q:K ==Bool Restrict
		orBool Q:K ==Bool Auto
		orBool Q:K ==Bool Register
		orBool Q:K ==Bool ThreadLocal
		[structural]
	rule
		< k > canonicalizeType-aux(.Bag, (t((.Set => SetItem(Const)) _, _)), .Bag, .Bag, (_ BagItem(Q:K) => .Bag)) ...</ k >
		when Q:K ==Bool Const
		[structural]
		
	/*@ \source[n1570]{\para{6.7.3}{9}}
	If the specification of an array type includes any type qualifiers, the element type is so-qualified, not the array type. \ldots
	*/
	rule t(SetItem(Const) S:Set, arrayType(t(S':Set, T:K), N:#Nat))
		=> t(S:Set, arrayType(t(SetItem(Const) S':Set, T:K), N:#Nat))
		[structural anywhere]
	
	rule
		< k > canonicalizeSpecifier(BagItem(Named(X:#Id)))
			=> t(.Set, typedefType(X:#Id, T:KResult))
		...</ k >
		< types >... typedef(X:#Id) |-> T:KResult ...</ types >
		when X:#Id =/=Bool Identifier("")
		[structural]
		
	rule
		< k > canonicalizeSpecifier(BagItem(StructRef(X:#Id)))
			=> t(.Set, structType(X:#Id))
		...</ k >
		when X:#Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(EnumRef(X:#Id)))
			=> t(.Set, enumType(X:#Id))
		...</ k >
		when X:#Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(UnionRef(X:#Id)))
			=> t(.Set, unionType(X:#Id))
		...</ k >
		when X:#Id =/=Bool Identifier("")
		[structural] 
		
	rule
		< k > canonicalizeSpecifier(BagItem(EnumDef(X:#Id, L:K)))
			=> EnumDef(X:#Id, L:K)
			~> t(.Set, enumType(X:#Id))
		...</ k >
		when X:#Id =/=Bool Identifier("")
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(L:KLabel(((Identifier("") => unnamed(N:#Nat)),, _)))) ...</ k >
		< freshNat > N:#Nat => sNat(N:#Nat) </ freshNat >
		when L:KLabel ==Bool 'StructDef
		orBool L:KLabel ==Bool 'EnumDef
		orBool L:KLabel ==Bool 'UnionDef
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(StructDef(X:#Id, L:K)))
			=> StructDef(X:#Id, L:K)
			~> t(.Set, structType(X:#Id))
		...</ k >
		when X:#Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(UnionDef(X:#Id, L:K)))
			=> UnionDef(X:#Id, L:K)
			~> t(.Set, unionType(X:#Id))
		...</ k >
		when X:#Id =/=Bool Identifier("")
		[structural] 
		

	// FIXME what good is this_
	rule BagItem(SpecTypedef) => .Bag [structural anywhere]
	// fixme ignoring inlines
	rule [ignore-inline]: BagItem(Inline) => .Bag [structural anywhere]
	rule [ignore-noreturn]: BagItem(Noreturn) => .Bag [structural anywhere]
	// fixme should save these for later use
	rule BagItem(Attribute(_:#String, _)) => .Bag [structural anywhere]

	rule 
		< k > canonicalizeType-aux(.Bag, (.K => canonicalizeSpecifier(B:Bag)), (B:Bag => .Bag), _, _) ...</ k >
		when B:Bag =/=Bool .Bag
		[structural] 
		
	rule
		< k > canonicalizeType-aux(.Bag, T:KResult, .Bag, .Bag, .Bag) => T:KResult ...</ k >
		[structural] 
		
	declare canonicalizeSpecifier : Bag -> K 
	// C99 6.7.2:2
	define canonicalizeSpecifier(BagItem(Void)) => t(.Set, void) [structural]
	define canonicalizeSpecifier(BagItem(Bool)) => t(.Set, bool) [structural]
	define canonicalizeSpecifier(BagItem(Char)) => t(.Set, char) [structural]
	define canonicalizeSpecifier(BagItem(Signed) BagItem(Char)) => t(.Set, signed-char) [structural]
	define canonicalizeSpecifier(BagItem(Unsigned) BagItem(Char)) => t(.Set, unsigned-char) [structural]
	
	// rule canonicalizeSpecifier(BagItem(atomic(t(S:Set, T:K)))) => t(S:Set SetItem(Atomic), T:K) [structural]
	
	rule BagItem(atomic(_)) => .Bag [structural anywhere]
	rule BagItem(alignas(_)) => .Bag [structural anywhere]
	
	define canonicalizeSpecifier(BagItem(Double)) => t(.Set, double) [structural]
	define canonicalizeSpecifier(BagItem(Float)) => t(.Set, float) [structural]
	define canonicalizeSpecifier(BagItem(Long) BagItem(Double)) => t(.Set, long-double) [structural]
	
	define canonicalizeSpecifier(BagItem(Complex) BagItem(Double)) => t(SetItem(Complex), double) [structural]
	define canonicalizeSpecifier(BagItem(Complex) BagItem(Float)) => t(SetItem(Complex), float) [structural]
	define canonicalizeSpecifier(BagItem(Complex) BagItem(Long) BagItem(Double)) => t(SetItem(Complex), long-double) [structural]
	
	define canonicalizeSpecifier(BagItem(Imaginary) BagItem(Double)) => t(SetItem(Imaginary), double) [structural]
	define canonicalizeSpecifier(BagItem(Imaginary) BagItem(Float)) => t(SetItem(Imaginary), float) [structural]
	define canonicalizeSpecifier(BagItem(Imaginary) BagItem(Long) BagItem(Double)) => t(SetItem(Imaginary), long-double) [structural]
	
	define canonicalizeSpecifier(B:Bag) => t(.Set, short-int)
		when B:Bag ==Bool BagItem(Short)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Short)
		orBool B:Bag ==Bool BagItem(Short) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Short) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-short-int)
		when B:Bag ==Bool BagItem(Unsigned) BagItem(Short)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Short) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, int)
		when B:Bag ==Bool BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-int)
		when B:Bag ==Bool BagItem(Unsigned)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, long-int)
		when B:Bag ==Bool BagItem(Long)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-int)
		when B:Bag ==Bool BagItem(Unsigned) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, long-long-int)
		when B:Bag ==Bool BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Long) BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-long-int)
		when B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
endkm

kmod COMMON-SEMANTICS-TYPE-INTERPRETATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 

	op BitFieldType : K K -> K [metadata "strict=()"] 
	
	rule
		< k > Specifier(List(L:List{K})) => canonicalizeType(Bag(L:List{K})) ...</ k >
		[structural]
		
	rule BitFieldType(T:KResult, tv(N:#Nat, _)) => t(.Set, bitfieldType(T:KResult, N:#Nat)) [structural anywhere]
	
	declare makeArrayType : #Nat -> KLabel 
	declare makeFunctionType : List{KResult} -> KLabel 
	declare pushTypeDown : Type KLabel -> Type 
	declare makePointerType : -> KLabel
	declare makeIncompleteArrayType : -> KLabel
	
	// fixme, throwing away specifier
	rule ArrayType(T:KResult, tv(N:#Nat, _), _) 
		=> pushTypeDown(T:KResult, makeArrayType(N:#Nat)) 
		when N:#Nat >Nat 0
		[structural anywhere]
	rule ArrayType(T:KResult, emptyValue, _) => pushTypeDown(T:KResult, makeIncompleteArrayType) [structural anywhere]
	rule PointerType(T:KResult) => pushTypeDown(T:KResult, makePointerType) [structural anywhere]
	// fixme I'm assuming functiontype is always below a prototype in the ast
	rule FunctionType(T:KResult) => T:KResult [structural anywhere]
	rule Prototype(T:KResult, List(L:List{KResult}), false) 
		=> pushTypeDown(T:KResult, makeFunctionType(L:List{KResult})) 
		[structural anywhere]
	rule Prototype(T:KResult, List(L:List{KResult}), true) 
		=> pushTypeDown(T:KResult, makeFunctionType((L:List{KResult},, t(.Set, variadic)))) 
		[structural anywhere]
	
	define [pushdown-array]: pushTypeDown(t(S:Set, arrayType(T:KResult, N:#Nat)), K:KLabel) => t(S:Set, arrayType(pushTypeDown(T:KResult, K:KLabel), N:#Nat)) [structural]
	define [pushdown-incomplete]: pushTypeDown(t(S:Set, incompleteArrayType(T:KResult)), K:KLabel) => t(S:Set, incompleteArrayType(pushTypeDown(T:KResult, K:KLabel))) [structural]
	define [pushdown-pointer]: pushTypeDown(t(S:Set, pointerType(T:KResult)), K:KLabel) => t(S:Set, pointerType(pushTypeDown(T:KResult, K:KLabel))) [structural]
	define [pushdown-qualified]: pushTypeDown(t(S:Set, qualifiedType(T:KResult, K:K)), K:KLabel) => t(S:Set, qualifiedType(pushTypeDown(T:KResult, K:KLabel), K:K)) [structural]
	define [pushdown-function]: pushTypeDown(t(S:Set, functionType(T:KResult, L:List{KResult})), K:KLabel) => t(S:Set, functionType(pushTypeDown(T:KResult, K:KLabel), L:List{KResult})) [structural]
	define [pushdown-struct]: pushTypeDown(t(S:Set, structType(X:#Id)), K:KLabel) => K:KLabel(t(S:Set, structType(X:#Id))) [structural]
	define [pushdown-union]: pushTypeDown(t(S:Set, unionType(X:#Id)), K:KLabel) => K:KLabel(t(S:Set, unionType(X:#Id))) [structural]
	define [pushdown-enum]: pushTypeDown(t(S:Set, enumType(X:#Id)), K:KLabel) => K:KLabel(t(S:Set, enumType(X:#Id))) [structural]
	
	define [pushdown-typedef]: pushTypeDown(t(S:Set, typedefType(X:#Id, t(S':Set, T:K))), K:KLabel) => K:KLabel(t(S:Set S':Set, T:K)) [structural]
	
	define [pushdown-basic]: pushTypeDown(T:KResult, K:KLabel) => K:KLabel(T:KResult) 
		when isBasicType(T:KResult)
		[structural]
	
	define makeArrayType(N:#Nat)(T:KResult) => t(.Set, arrayType(T:KResult, N:#Nat)) [structural]
	define makeFunctionType(L:List{KResult})(T:KResult) => t(.Set, functionType(T:KResult, giveNamesToArgs(L:List{KResult}))) [structural]
	define makePointerType(T:KResult) => t(.Set, pointerType(T:KResult)) [structural]
	define makeIncompleteArrayType(T:KResult) => t(.Set, incompleteArrayType(T:KResult)) [structural]
	
	declare giveNamesToArgs : List{KResult} -> List{KResult}
	declare giveNamesToArgs-aux : #Nat List{KResult} -> List{KResult}
	
	define giveNamesToArgs(L:List{KResult}) => giveNamesToArgs-aux(0, L:List{KResult}) [structural]
	define giveNamesToArgs-aux(N:#Nat, (typedDeclaration(T:KResult, X:#Id),, L:List{KResult}))
		=> typedDeclaration(T:KResult, X:#Id),, giveNamesToArgs-aux(N:#Nat, L:List{KResult})
		when X:#Id =/=Bool #NoName
		[structural]
	define giveNamesToArgs-aux(N:#Nat, (typedDeclaration(T:KResult, X:#Id),, L:List{KResult}))
		=> typedDeclaration(T:KResult, #NoName(N:#Nat)),, giveNamesToArgs-aux(sNat(N:#Nat), L:List{KResult})
		when X:#Id ==Bool #NoName
		[structural]
	define giveNamesToArgs-aux(_:#Nat, t(.Set, variadic))
		=> t(.Set, variadic)
		[structural]
	define giveNamesToArgs-aux(_:#Nat, .List{K})
		=> .List{K}
		[structural]
	
	rule 
		< k > JustBase => T:KResult ...</ k >
		< declarationTypeHolder > T:KResult => .K ...</ declarationTypeHolder >
		[structural] 

	op extractActualTypeFreezer : -> K 
	rule
		< k > DeclType(T:KResult, K:K) => K:K ~> extractActualTypeFreezer ...</ k >
		< declarationTypeHolder > (. => T:KResult) ...</ declarationTypeHolder >
		[structural] 
	
	rule
		< k > T:KResult ~> extractActualTypeFreezer 
			=> extractActualType(T:KResult)
		...</ k >
		[structural] 
		
	declare fillUnionBitHoles : List{KResult} -> List{KResult} 
	declare fillUnionBitHoles-aux : #Nat List{KResult} -> List{KResult} 
	define fillUnionBitHoles(.List{K}) => .List{K} [structural]
	define fillUnionBitHoles((K:K,, L:List{K})) => fillUnionBitHoles-aux(0, (K:K,, L:List{K})) [structural]
	define fillUnionBitHoles-aux(N:#Nat, (typedDeclaration(T:KResult, X:#Id),, L:List{KResult})) 
			=> typedDeclaration(T:KResult, X:#Id)
			,, fillUnionBitHoles-aux(N:#Nat, L:List{KResult})
		when notBool hasBitfieldType(T:KResult)
		[structural]
	define fillUnionBitHoles-aux(N:#Nat, (typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':#Nat)), X:#Id),, L:List{KResult})) 
			=> typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':#Nat)), X:#Id)
			,, fillUnionBitHoles-aux(maxNat(N:#Nat, N':#Nat), L:List{KResult})
		[structural]
	define fillUnionBitHoles-aux(N:#Nat, .List{K}) 
		=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), NEARESTMULT)), #NoName)
		where NEARESTMULT = N:#Nat +Nat (absInt(numBitsPerByte -Int (N:#Nat %Nat numBitsPerByte)) %Nat numBitsPerByte)
		[structural]
	
	declare fillBitHoles : List{KResult} -> List{KResult} 
	declare fillBitHoles-aux : #Nat List{KResult} -> List{KResult} 
	define [fillBitHoles-none]:
		fillBitHoles(.List{K}) => .List{K} 
		[structural]
	// if we haven't seen bitfields
	define [fillBitHoles-not-bitfield]:
		fillBitHoles((typedDeclaration(T:KResult, X:#Id),, L:List{KResult})) 
			=> typedDeclaration(T:KResult, X:#Id)
			,, fillBitHoles(L:List{KResult})
		when notBool hasBitfieldType(T:KResult) 
		[structural]
	
	define [fillBitHoles-bitfield]:
		fillBitHoles((typedDeclaration(T:KResult, X:#Id),, L:List{KResult})) 
			=> fillBitHoles-aux(0, (typedDeclaration(T:KResult, X:#Id),, L:List{KResult}))
		when hasBitfieldType(T:KResult) 
		[structural]
	
	// if we have seen bitfields
	define [fillBitHoles-aux-not-bitfield]:
		fillBitHoles-aux(N:#Nat, (typedDeclaration(T:KResult, X:#Id),, L:List{KResult})) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), absInt(numBitsPerByte -Int (N:#Nat %Nat numBitsPerByte)) %Nat numBitsPerByte)), #NoName)
			,, fillBitHoles((typedDeclaration(T:KResult, X:#Id),, L:List{KResult}))
		when notBool hasBitfieldType(T:KResult) 
		[structural]
	
	define [fillBitHoles-aux-bitfield-normal]:
		fillBitHoles-aux(N:#Nat, (typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':#Nat)), X:#Id),, L:List{KResult})) 
			=> typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':#Nat)), X:#Id)
			,, fillBitHoles-aux(N:#Nat +Nat N':#Nat, L:List{KResult})
		when N':#Nat =/=Bool 0 
		[structural]
		
	define [fillBitHoles-bitfield-zero]:
		fillBitHoles-aux(N:#Nat, (typedDeclaration(t(_, bitfieldType(T:KResult, N':#Nat)), _:#Id),, L:List{KResult})) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), absInt(numBitsPerByte -Int (N:#Nat %Nat numBitsPerByte)) %Nat numBitsPerByte)), #NoName)
			,, fillBitHoles(L:List{KResult})
		when N':#Nat ==Bool 0
		[structural]
	
	define [fillBitHoles-done]:
		fillBitHoles-aux(N:#Nat, .List{K}) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), absInt(numBitsPerByte -Int (N:#Nat %Nat numBitsPerByte)) %Nat numBitsPerByte)), #NoName) 
		[structural]

	
	rule typedDeclaration(t(_, bitfieldType(_, N:#Nat)), #NoName)
		,, typedDeclaration(t(_, bitfieldType(_, N':#Nat)), #NoName) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), N:#Nat +Nat N':#Nat)), #NoName) 
		[structural anywhere]
	
	// fixme chould check for some struct contraints here
	declare incompleteToFlexibleArrayMember : List{KResult} -> List{KResult} 
	define incompleteToFlexibleArrayMember((typedDeclaration(T:KResult, X:#Id),, L:List{KResult}))
		=> typedDeclaration(T:KResult, X:#Id),, incompleteToFlexibleArrayMember(L:List{KResult}) 
		when notBool hasIncompleteType(T:KResult) 
		[structural]
	define incompleteToFlexibleArrayMember(typedDeclaration(t(S:Set, incompleteArrayType(T:KResult)), X:#Id)) 
		=> typedDeclaration(t(S:Set, flexibleArrayType(T:KResult)), X:#Id) 
		[structural]
	define incompleteToFlexibleArrayMember(.List{K}) => .List{K} [structural]
	
	rule
		< k > StructDef(X:#Id, List(L:List{KResult}))
			=> addStruct(X:#Id, fillBitHoles(incompleteToFlexibleArrayMember(L:List{KResult})))
			~> giveType(X:#Id, t(.Set, structType(X:#Id)))
		...</ k >
		[structural] 
	rule
		< k > UnionDef(X:#Id, List(L:List{KResult}))
			=> addUnion(X:#Id, fillUnionBitHoles(L:List{KResult}))
			~> giveType(X:#Id, t(.Set, unionType(X:#Id)))
		...</ k >
		[structural] 

	// the K will resolve to a type, so throw it away
	rule
		< k > OnlyTypedef(K:K) => K:K ~> discard ...</ k >
		[structural] 
		
			
	rule
		NameAndType(X:#Id, T:KResult) => typedDeclaration(T:KResult, X:#Id)
		[structural anywhere] 
	
	define [extract-basic]: extractActualType(T:KResult) => T:KResult when isBasicType(T:KResult) [structural]
	define [extract-enum]: extractActualType(t(S:Set, enumType(X:#Id))) => t(S:Set, enumType(X:#Id)) [structural]
	define [extract-struct]: extractActualType(t(S:Set, structType(X:#Id))) => t(S:Set, structType(X:#Id)) [structural]
	define [extract-union]: extractActualType(t(S:Set, unionType(X:#Id))) => t(S:Set, unionType(X:#Id)) [structural]
	define [extract-array]: extractActualType(t(S:Set, arrayType(T:KResult, N:#Nat))) => t(S:Set, arrayType(extractActualType(T:KResult), N:#Nat)) [structural]
	define [extract-incompleteArray]: extractActualType(t(S:Set, incompleteArrayType(T:KResult))) => t(S:Set, incompleteArrayType(extractActualType(T:KResult))) [structural]
	define [extract-bitfield]: extractActualType(t(S:Set, bitfieldType(T:KResult, N:#Nat))) => t(S:Set, bitfieldType(extractActualType(T:KResult), N:#Nat)) [structural]
	define [extract-function]: extractActualType(t(S:Set, functionType(T:KResult, List:List{KResult}))) => t(S:Set, functionType(extractActualType(T:KResult), List:List{KResult})) [structural]
	define [extract-pointer]:  extractActualType(t(S:Set, pointerType(T:KResult))) => t(S:Set, pointerType(extractActualType(T:KResult))) [structural]
	define [extract-qualified]: extractActualType(t(S:Set, qualifiedType(T:KResult, K:K))) => t(S:Set, qualifiedType(extractActualType(T:KResult), K:K)) [structural]
	define [extract-typedef]: extractActualType(t(S:Set, typedefType(_:#Id, t(S':Set, T:K)))) => extractActualType(t(S:Set S':Set, T:K)) [structural]
		
	op NameAndType : K K -> K [metadata "strict=(2)"] 
		
	rule
		SingleName(T:KResult, Name(X:#Id, K:K)) => NameAndType(X:#Id, DeclType(T:KResult, K:K))
		[structural anywhere] 
	rule [Separate-FieldGroups]:
		FieldGroup(K:K, List((C:K,, C':K,, L:List{K}))) 
			=> FieldGroup(K:K, List(C:K))
			,, FieldGroup(K:K, List((C':K,, L:List{K})))
		[structural anywhere]

	rule
		FieldGroup(T:KResult, List(Name(X:#Id, K:K))) 
			=> NameAndType(X:#Id, DeclType(T:KResult, K:K))
		[structural anywhere]
		
	rule
		FieldGroup(T:KResult, List(BitFieldName(Name(X:#Id, K:K), Size:K)))
			=> NameAndType(X:#Id, DeclType(T:KResult, BitFieldType(K:K, Size:K)))
		[structural anywhere] 
	rule FieldName(K:K) => K:K [structural anywhere]
endkm

kmod COMMON-SEMANTICS-TYPE-EXPRESSIONS is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	
	rule
		< k > typeof(K:K) => evalToType ~> typeof(MYHOLE) ...</ k >
		(.Bag => < type > K:K </ type >)
		[structural] 
	rule
		< k > evalToType ~> typeof(MYHOLE) => T:KResult ...</ k >
		(< type > T:KResult </ type > => .Bag)
		when isAType T:KResult
		[structural] 

	rule
		< type > emptyValue => t(.Set, void) ...</ type > 
		[structural] 
		
	rule
		< type > T:KResult << _ => T:KResult ...</ type >
		[structural] 
	rule
		< type > T:KResult >> _ => T:KResult ...</ type >
		[structural] 
		
	rule
		< type > tv(_, T:KResult) => T:KResult ...</ type >
		[structural] 
	
	rule
		< type > SizeofExpression(_) => cfg:sizeut ...</ type >
		[structural] 

	rule < type > E1:K[E2:K] => *(E1:K + E2:K) ...</ type > 
		[structural] 
	rule 
		< type > arithInterpret(T:KResult, _) => T:KResult ...</ type > 
		[structural]
	rule
		< type > t(S:Set, pointerType(T:KResult)) + T':KResult => t(S:Set, pointerType(T:KResult)) ...</ type >
		when hasIntegerType(T':KResult)
		[structural] 
	rule
		< type > T':KResult + t(S:Set, pointerType(T:KResult)) => t(S:Set, pointerType(T:KResult)) ...</ type >
		when hasIntegerType(T':KResult)
		[structural] 
	rule
		< type > t(S:Set, pointerType(T:KResult)) - T':KResult => t(S:Set, pointerType(T:KResult)) ...</ type >
		when hasIntegerType(T':KResult)
		[structural] 
	rule
		< type > t(_, pointerType(T:KResult)) - t(_, pointerType(T':KResult)) => cfg:ptrdiffut ...</ type >
		[structural]
	rule
		< type > t(S:Set, arrayType(T:KResult, _:#Nat)) + T':KResult => t(S:Set, pointerType(T:KResult)) ...</ type >
		when hasIntegerType(T':KResult)
		[structural] 
	rule
		< type > T':KResult + t(S:Set, arrayType(T:KResult, _:#Nat)) => t(S:Set, pointerType(T:KResult)) ...</ type >
		when hasIntegerType(T':KResult)
		[structural] 
	rule
		< type > t(S:Set, arrayType(T:KResult, _:#Nat)) - T':KResult => t(S:Set, pointerType(T:KResult)) ...</ type >
		when hasIntegerType(T':KResult)
		[structural]

	// c99 6.4.5
	rule
		< type > Constant(StringLiteral(S:#String)) => t(.Set, arrayType(t(.Set, char), lengthString(S:#String) +Nat 1)) ...</ type >
		[structural]
	rule
		< type > Constant(WStringLiteral(L:List{K})) => t(.Set, arrayType(cfg:wcharut, lengthList{K}(L:List{K}) +Nat 1)) ...</ type >
		[structural]
		
	rule
		< type > K:K => T:KResult ...</ type >
		< types >... K:K |-> T:KResult ...</ types >
		[structural] 
			
	rule
		< type > Comma(List((_,, K:K))) => K:K ...</ type >
		[structural] 

	rule [type-call-func]:
		< type > Call(t(_, functionType(T:KResult, _:List{KResult})), _) => T:KResult ...</ type >
		[structural]
		 		
	rule [type-struct-dot]:
		< type > t(_, structType(S:#Id)) . F:#Id => T:KResult ...</ type >
		< structs >... 
			S:#Id |-> aggregateInfo(_, (_ F:#Id |-> T:KResult), _)
		...</ structs >
		[structural] 
	rule [type-union-dot]:
		< type > t(_, unionType(S:#Id)) . F:#Id => T:KResult ...</ type >
		< structs >... 
			S:#Id |-> aggregateInfo(_, (_ F:#Id |-> T:KResult), _)
		...</ structs >
		[structural] 
	
	rule [type-deref-type]:
		< type > *(t(_, pointerType(T:KResult))) => T:KResult ...</ type >
		[structural] 
	rule [type-deref-array-type]:
		< type > *(t(_, arrayType(T:KResult, _:#Nat))) => T:KResult ...</ type >
		[structural] 

	rule [type-compound-literal]:
		< type > CompoundLiteral(_, Specifier:K, DeclType:K, _)
			=> Cast(Specifier:K, DeclType:K, emptyValue)  // sort of hackish, assumes cast will evaluate to type
		...</ type >
		[structural] 
	
	rule [type-assignment]:
		< type > L:KLabel(K:K,, _) 
			=> K:K
		...</ type >
		when Set(
			l('_:=_),, l('_*=_),, l('_/=_),, l('_%=_),, l('_+=_),, l('_-=_),, 
			l('_<<=_),, l('_>>=_),, l('_&=_),, l('_^=_),, l('_|=_)
		) contains l(L:KLabel)
		[structural]

	rule 
		< type > L:KLabel(T:KResult,, T':KResult) => usualArithmeticConversion(T:KResult, T':KResult) ...</ type >
		when isArithBinConversionOp(L:KLabel)
		andBool (hasIntegerType(T:KResult) orBool hasFloatType(T:KResult))
		andBool (hasIntegerType(T':KResult) orBool hasFloatType(T':KResult))
		[structural] 
		
	rule [type-ternary-arithmetic]:
		< type > _:K ? T:KResult : T':KResult => usualArithmeticConversion(T:KResult, T':KResult) ...</ type >
		when (hasIntegerType(T:KResult) orBool hasFloatType(T:KResult))
		andBool (hasIntegerType(T':KResult) orBool hasFloatType(T':KResult))
		[structural]
	rule [type-ternary-identical]:
		< type > _:K ? T:KResult : T:KResult => T:KResult ...</ type >
		when isAType(T:KResult)
		andBool notBool hasArrayType(T:KResult)
		[structural]
		
	rule [type-ternary-array-left]: < type > _:K ? (t(S:Set, arrayType(T:KResult, _:#Nat)) => t(S:Set, pointerType(T:KResult))) : _ ...</ type > [structural]
	rule [type-ternary-array-right]: < type > _:K ? _:K : (t(S:Set, arrayType(T:KResult, _:#Nat)) => t(S:Set, pointerType(T:KResult))) ...</ type > [structural]
		
	rule [type-ternary-pointer]: // not safe, could be incompatible types
		< type > _:K ? t(S:Set, pointerType(T:KResult)) : t(S':Set, pointerType(T':KResult)) => t(S:Set, pointerType(T:KResult)) ...</ type >
		[structural]

	rule
		< type > L:KLabel(T:KResult) => promote(T:KResult) ...</ type > 
		when isArithUnaryOp(L:KLabel)
		andBool (hasIntegerType(T:KResult) orBool hasFloatType(T:KResult))
		[structural]
	
	rule 
		< type > L:KLabel(T:KResult,, _:List{K}) => promote(T:KResult) ...</ type >
		when (hasIntegerType(T:KResult) orBool hasFloatType(T:KResult))
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural]
		
	rule [type-inc-dec]:
		< type > L:KLabel(T:KResult) => T:KResult ...</ type >
		when hasPointerType(T:KResult)
		andBool (
			L:KLabel ==Bool ('_++)
			orBool L:KLabel ==Bool ('_--)
			orBool L:KLabel ==Bool ('--_)
			orBool L:KLabel ==Bool ('++_)
		)
		[structural]
		
	rule
		< type > L:KLabel(_:K,, _:K) => t(.Set, int) ...</ type >
		when L:KLabel ==Bool '_==_
		orBool L:KLabel ==Bool '_!=_
		orBool L:KLabel ==Bool '_&&_
		orBool L:KLabel ==Bool '_||_
		[structural]
		
	rule [type-address]:
		< type > & T:KResult => t(.Set, pointerType(T:KResult)) ...</ type >
		when isAType(T:KResult)
		[structural]
		
endkm

kmod COMMON-C-TYPING is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	including COMMON-SEMANTICS-TYPE-STRICTNESS 
	including COMMON-SEMANTICS-TYPE-DECLARATIONS 
	including COMMON-SEMANTICS-TYPE-CANONICALIZATION 
	including COMMON-SEMANTICS-TYPE-INTERPRETATION 
	including COMMON-SEMANTICS-TYPE-EXPRESSIONS 
	
	rule [ExpressionLoc-type]:
		< type > ExpressionLoc(K:K, L:CabsLoc) => K:K ...</ type >
		< currentProgramLoc > _ => L:CabsLoc </ currentProgramLoc >
		[structural] 
		
	/*@ \source[n1570]{\para{6.2.7}{1}}
	Two types have compatible type if their types are the same. Additional rules for determining whether two types are compatible are described in 6.7.2 for type specifiers, in 6.7.3 for type qualifiers, and in 6.7.6 for declarators.  Moreover, two structure, union, or enumerated types declared in separate translation units are compatible if their tags and members satisfy the following requirements: If one is declared with a tag, the other shall be declared with the same tag. If both are completed anywhere within their respective translation units, then the following additional requirements apply: there shall be a one-to-one correspondence between their members such that each pair of corresponding members are declared with compatible types; if one member of the pair is declared with an alignment specifier, the other is declared with an equivalent alignment specifier; and if one member of the pair is declared with a name, the other is declared with the same name. For two structures, corresponding members shall be declared in the same order. For two structures or unions, corresponding bit-fields shall have the same widths. For two enumerations, corresponding members shall have the same values.
	
	\source[n1570]{\para{6.7.3}{10}}
	For two qualified types to be compatible, both shall have the identically qualified version of a compatible type; the order of type qualifiers within a list of specifiers or qualifiers does not affect the specified type.
	*/
	
	define [typeCompatible-identical]: isTypeCompatible(T:KResult, T:KResult) 
		=> true 
		[structural]
	define [typeCompatible-two-ints]: isTypeCompatible(T:KResult, T':KResult) 
		=> true 
		when hasIntegerType(T:KResult)
		andBool hasIntegerType(T':KResult) 
		[structural]
	define [typeCompatible-two-ptr]: isTypeCompatible(t(_, pointerType(_)), t(_, pointerType(_)))
		=> true 
		[structural]
	define [typeCompatible-ptr-int]: isTypeCompatible(t(_, pointerType(_)), T:KResult)
		=> true
		when hasIntegerType(T:KResult) 
		[structural]
	define [typeCompatible-int-ptr]: isTypeCompatible(T:KResult, t(_, pointerType(_)))
		=> true
		when hasIntegerType(T:KResult)
		[structural]
		
	define [typeCompatible-declarations]: isTypeCompatible(typedDeclaration(T:KResult, _:#Id), typedDeclaration(T':KResult, _:#Id))
		=> isTypeCompatible(T:KResult, T':KResult) 
		[structural]
	define [typeCompatible-prototypes]: isTypeCompatible(t(_, prototype(T:KResult)), t(_, prototype(T':KResult))) 
		=> isTypeCompatible(T:KResult, T':KResult) 
		[structural]

	define [typeCompatible-array-right]: isTypeCompatible(T:KResult, t(S:Set, arrayType(T':KResult, _:#Nat)))
		=> isTypeCompatible(T:KResult, t(S:Set, pointerType(T':KResult))) 
		[structural]
	define [typeCompatible-array-left]: isTypeCompatible(t(S:Set, arrayType(T:KResult, _:#Nat)), T':KResult)
		=> isTypeCompatible(t(S:Set, pointerType(T:KResult)), T':KResult) 
		[structural]
	
	define [typeCompatible-incompleteArray-right]: isTypeCompatible(T:KResult, t(S:Set, incompleteArrayType(T':KResult)))
		=> isTypeCompatible(T:KResult, t(S:Set, pointerType(T':KResult))) 
		[structural]
	define [typeCompatible-incompleteArray-left]: isTypeCompatible(t(S:Set, incompleteArrayType(T:KResult)), T':KResult)
		=> isTypeCompatible(t(S:Set, pointerType(T:KResult)), T':KResult) 
		[structural]

	define [typeCompatible-function-void-left]: isTypeCompatible(t(_, functionType(T1:KResult, typedDeclaration(t(_, void), _:#Id))), t(_, functionType(T2:KResult, .List{K})))
		=> isTypeCompatible(T1:KResult, T2:KResult) 
		[structural]
	define [typeCompatible-function-void-right]: isTypeCompatible(t(_, functionType(T1:KResult, .List{K})), t(_, functionType(T2:KResult, typedDeclaration(t(_, void), _:#Id))))
		=> isTypeCompatible(T1:KResult, T2:KResult) 
		[structural]
	define [typeCompatible-function]: isTypeCompatible(t(S:Set, functionType(T1:KResult, (T':KResult,, L:List{KResult}))), t(S':Set, functionType(T2:KResult, (T'':KResult,, L':List{KResult}))))
		=> isTypeCompatible(t(S:Set, functionType(T1:KResult, L:List{KResult})), t(S':Set, functionType(T2:KResult, L':List{KResult})))
		andBool isTypeCompatible(T':KResult, T'':KResult) 
		[structural]
	define [typeCompatible-incompleteArray-nil]: isTypeCompatible(t(_, functionType(T1:KResult, .List{K})), t(_, functionType(T2:KResult, .List{K})))
		=> isTypeCompatible(T1:KResult, T2:KResult) 
		[structural]
	define isTypeCompatible(T:KResult, T':KResult) => true
		when (hasIntegerType(T:KResult) orBool hasFloatType(T:KResult))
		andBool (hasIntegerType(T':KResult) orBool hasFloatType(T':KResult)) 
		[structural]
	rule 
		< k > Cast(T:KResult, K:K, V:KResult) => cast(DeclType(T:KResult, K:K), V:KResult) ...</ k >
		[structural] 
			
	op addGlobalAggregate : #Id K -> K 
	op addLocalAggregate : #Id K -> K 
	
	op addStruct-aux : #Id List{KResult} K Map Map List{KResult} -> K [metadata "strict=(3)"]
	op addUnion-aux : #Id List{KResult} Map Map List{KResult} -> K
	rule
		< k > addStruct(S:#Id, L:List{KResult}) 
			=> addStruct-aux(S:#Id, L:List{KResult}, tv(0, cfg:largestUnsigned), .Map, .Map, L:List{KResult})
		...</ k >
		when L:List{KResult} =/=Bool .List{K}
		[structural]
	rule
		< k > addStruct-aux(
				S:#Id
				, (typedDeclaration(T:KResult, Field:#Id),, L:List{KResult})
				, V:KResult
				, Types:Map
				, Offsets:Map
				, L':List{KResult}
			) 
			=> addStruct-aux(S:#Id, L:List{KResult}, V:KResult + bitSizeofType(T:KResult), Types:Map[T:KResult / Field:#Id], Offsets:Map[value(V:KResult) / Field:#Id], L':List{KResult})
		...</ k >
		[structural]
	rule
		< k > addStruct-aux(S:#Id, .List{K}, _, Types:Map, Offsets:Map, L:List{KResult}) 
			=> if (F:#Id ==Bool File-Scope) then 
				(addGlobalAggregate(S:#Id, aggregateInfo(L:List{KResult}, Types:Map, Offsets:Map))) 
			else
				(addLocalAggregate(S:#Id, aggregateInfo(L:List{KResult}, Types:Map, Offsets:Map)))
			fi
		...</ k >
		< currentFunction > F:#Id </ currentFunction >
		[structural]		
		
	rule
		< k > addUnion(S:#Id, L:List{KResult}) 
			=> addUnion-aux(S:#Id, L:List{KResult}, .Map, .Map, L:List{KResult})
		...</ k >
		when L:List{KResult} =/=Bool .List{K}
		[structural]
	rule
		< k > addUnion-aux(
				S:#Id
				, (typedDeclaration(T:KResult, Field:#Id),, L:List{KResult})
				, Types:Map
				, Offsets:Map
				, L':List{KResult}
			) 
			=> addUnion-aux(S:#Id, L:List{KResult}, Types:Map[T:KResult / Field:#Id], Offsets:Map[0 / Field:#Id], L':List{KResult})
		...</ k >
		[structural]
	rule
		< k > addUnion-aux(S:#Id, .List{K}, Types:Map, Offsets:Map, L:List{KResult}) 
			=> if (F:#Id ==Bool File-Scope) then 
				(addGlobalAggregate(S:#Id, aggregateInfo(L:List{KResult}, Types:Map, Offsets:Map))) 
			else
				(addLocalAggregate(S:#Id, aggregateInfo(L:List{KResult}, Types:Map, Offsets:Map)))
			fi
		...</ k >
		< currentFunction > F:#Id </ currentFunction >
		[structural]

	rule
		< k > addGlobalAggregate(X:#Id, K:K) => . ...</ k >
		< structs > M':Map => M':Map[K:K / X:#Id] </ structs >
		< gstructs > M:Map => M:Map[K:K / X:#Id] </ gstructs >
		[structural] 
	rule
		< k > addLocalAggregate(X:#Id, K:K) => . ...</ k >
		< structs > M:Map => M:Map[K:K / X:#Id] </ structs >
		[structural] 
		
	define isAType t(_, T:K) => true
		when setOfTypes contains l(getKLabel(T:K)) 
		[structural]
	define isAType T:KResult => true when isBasicType(T:KResult) [structural]
	define isAType K:K => false
		when getKLabel(K:K) =/=Bool 't
		[structural]
	define isAType t(S:Set, T:K) => false
		when notBool setOfTypes contains l(getKLabel(T:K))
		andBool notBool isBasicType(t(S:Set, T:K)) 
		[structural]
			

	define hasFloatType(t(_, float)) => true [structural]
	define hasFloatType(t(_, double)) => true [structural]
	define hasFloatType(t(_, long-double)) => true [structural]
	define hasFloatType(t(_, T:K)) => false
		when T:K =/=Bool float
		andBool T:K =/=Bool double
		andBool T:K =/=Bool long-double
		andBool getKLabel(T:K) =/=Bool 'qualifiedType
		[structural]
	
	define [hasCharType-char]: hasCharType(t(_, char)) => true [structural]
	define [hasCharType-qualified]: hasCharType(t(_, qualifiedType(T:KResult, _))) => hasCharType(T:KResult) [structural]
	define [hasCharType-unsigned-char]: hasCharType(t(_, unsigned-char)) => true [structural]
	define [hasCharType-signed-char]: hasCharType(t(_, signed-char)) => true [structural]
	define [hasCharType-other]: hasCharType(t(_, T:K)) => false
		when T:K =/=Bool char
		andBool T:K =/=Bool unsigned-char
		andBool T:K =/=Bool signed-char
		andBool getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
		
	define [hasWCharType-wchar]: hasWCharType(t(_, T:K)) => true 
		when T:K ==Bool simpleType(cfg:wcharut)
		[structural]
	define [hasWCharType-other]: hasWCharType(t(_, T:K)) => false
		when T:K =/=Bool simpleType(cfg:wcharut)
		andBool getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
	define [hasWCharType-qualified]: hasWCharType(t(_, qualifiedType(T:KResult, _))) => hasWCharType(T:KResult) [structural]
	
	define [hasPointerType-pointer]: hasPointerType(t(_, pointerType(_))) => true [structural]
	define [hasPointerType-qualified]: hasPointerType(t(_, qualifiedType(T:KResult, _))) => hasPointerType(T:KResult) [structural]
	define [hasPointerType-other]: hasPointerType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'pointerType
		andBool getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
	
	define [hasBoolType-bool]: hasBoolType(t(_, bool)) => true [structural]
	define [hasBoolType-qualifiedType]: hasBoolType(t(_, qualifiedType(T:KResult, _))) => hasBoolType(T:KResult) [structural]
	define [hasBoolType-other]: hasBoolType(t(_, T:K)) => false
		when T:K =/=Bool bool 
		andBool getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
	
	define [hasArrayType-array]: hasArrayType(t(_, arrayType(_, _:#Nat))) => true [structural]
	define [hasArrayType-incompleteArray]: hasArrayType(t(_, incompleteArrayType(_))) => true [structural]
	define [hasArrayType-flexibleArray]: hasArrayType(t(_, flexibleArrayType(_))) => true [structural]
	define [hasArrayType-qualified]: hasArrayType(t(_, qualifiedType(T:KResult, _))) => hasArrayType(T:KResult) [structural]
	define [hasArrayType-other]: hasArrayType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'arrayType 
		andBool getKLabel(T:K) =/=Bool 'incompleteArrayType 
		andBool getKLabel(T:K) =/=Bool 'flexibleArrayType 
		andBool getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
		
	define hasAggregateType(T:KResult) => hasArrayType(T:KResult) orBool hasStructType(T:KResult) [structural]
		
	define [hasStructType-struct]: hasStructType(t(_, structType(_:#Id))) => true [structural]
	define [hasStructType-qualified]: hasStructType(t(_, qualifiedType(T:KResult, _))) => hasStructType(T:KResult) [structural]
	define [hasStructType-other]: hasStructType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'structType
		andBool getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
		
	define [hasUnionType-union]: hasUnionType(t(_, unionType(_:#Id))) => true [structural]
	define [hasUnionType-qualified]: hasUnionType(t(_, qualifiedType(T:KResult, _))) => hasUnionType(T:KResult) [structural]
	define [hasUnionType-other]: hasUnionType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'unionType
		andBool getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]

	define [hasIncompleteType-true]: hasIncompleteType(t(_, incompleteArrayType(_))) => true [structural]
	define [hasIncompleteType-qualified]: hasIncompleteType(t(_, qualifiedType(T:KResult, _))) => hasIncompleteType(T:KResult) [structural]
	define [hasIncompleteType-false]: hasIncompleteType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'incompleteArrayType
		andBool getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
		
	define [hasExternType-qualified]: hasExternType(t(_, qualifiedType(T:KResult, K:K))) => if (K:K ==Bool Extern) then (true) else (hasExternType(T:KResult)) fi 
		[structural]
	define [hasExternType-false]: hasExternType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
		
	define [hasStaticType-qualified]: 
		hasStaticType(t(_, qualifiedType(T:KResult, K:K))) 
			=> if (K:K ==Bool Static) then (true) else (hasStaticType(T:KResult)) fi
		[structural]
	define [hasStaticType-false]: hasStaticType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
	
	define [hasConstType-qualified]: 
		hasConstType(t(_, qualifiedType(T:KResult, K:K))) => hasConstType(T:KResult)
		[structural]
	define [hasConstType-false]: 
		hasConstType(t(S:Set, T:K)) => false
		when getKLabel(T:K) =/=Bool 'qualifiedType 
		andBool notBool Const in S:Set
		[structural]
	define [hasConstType-true]: 
		hasConstType(t(SetItem(Const) _, T:K)) => true
		[structural]		
	
		
	define [hasBitfieldType-true]: hasBitfieldType(t(_, bitfieldType(_, _:#Nat))) => true [structural]
	define [hasBitfieldType-false]: hasBitfieldType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'bitfieldType
		[structural]
		
	define [hasFunctionType-true]: hasFunctionType(t(_, functionType(_, _:List{KResult}))) => true [structural]
	define [hasFunctionType-prototype]: hasFunctionType(t(_, prototype(T:KResult))) => hasFunctionType(T:KResult) [structural]
	define [hasFunctionType-qualified]: hasFunctionType(t(_, qualifiedType(T:KResult, _))) => hasFunctionType(T:KResult) [structural]
	define [hasFunctionType-false]: hasFunctionType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'functionType
		andBool getKLabel(T:K) =/=Bool 'qualifiedType
		andBool getKLabel(T:K) =/=Bool 'prototype 
		[structural]
		
	define [hasFunctionPointerType-fp]: hasFunctionPointerType(t(_, pointerType(t(_, functionType(_, _:List{KResult}))))) => true [structural]
	define [hasFunctionPointerType-qualified]: hasFunctionPointerType(t(_, qualifiedType(T:KResult, _))) => hasFunctionPointerType(T:KResult) [structural]
	define [hasFunctionPointerType-qualified-pointer]: hasFunctionPointerType(t(_, pointerType(t(_, qualifiedType(T:KResult, _))))) => hasFunctionPointerType(t(.Set, pointerType(T:KResult))) [structural]
	define [hasFunctionPointerType-notPointer]: hasFunctionPointerType(t(_, T:K)) => false
		when getKLabel(T:K) =/=Bool 'pointerType
		andBool getKLabel(T:K) =/=Bool 'qualifiedType
		[structural]
	define [hasFunctionPointerType-notFunction]: hasFunctionPointerType(t(_, pointerType(t(_, T:K)))) => false
		when getKLabel(T:K) =/=Bool 'functionType 
		andBool getKLabel(T:K) =/=Bool 'qualifiedType
		[structural]
		
	// /*@ \source[n1570]{\para{6.2.5}{18}}
	// Integer and floating types are collectively called arithmetic types. Each arithmetic type belongs to one type domain: the real type domain comprises the real types, the complex type domain comprises the complex types. 
	// */
	define hasArithmeticType(T:KResult) => hasIntegerType(T:KResult) orBool hasFloatType(T:KResult)
		[structural]
		
		
			
	define unqualifyType(t(_:Set, qualifiedType(T:KResult, _))) => T:KResult [structural]
	define unqualifyType(t(_:Set, T:K)) => t(.Set, T:K)
		when getKLabel(T:K) =/=Bool 'qualifiedType 
		[structural]
		
	define removeStorageSpecifiers(t(_:Set, qualifiedType(T:KResult, _))) => T:KResult [structural]
	define removeStorageSpecifiers(t(S:Set, T:K)) => t(S:Set, T:K)
		when getKLabel(T:K) =/=Bool 'qualifiedType
		[structural]
	
	define getModifiers(t(S:Set, _)) => S:Set
endkm
