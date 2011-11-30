// FIXME need to automatically pad structs
kmod COMMON-SEMANTICS-TYPE-INCLUDE is
	including COMMON-INCLUDE 
	
	//op addAggregate : #Id List{Type} -> K 
	op addStruct : #Id List{Type} -> K 
	op addUnion : #Id List{Type} -> K 
	op canonicalizeType : Bag -> K 
	
	op extractActualType : Type -> Type // rules that use specifier should be careful to use extractActualType if going to be used in a typed name
	
	op evalToType : -> K 
	
	op typeStrictUnaryOperators : -> Set [memo] 
	rule typeStrictUnaryOperators => Set(
		l('-_),, l('+_),, l('*_),, l('&_),, l('~_)
	)
	[structural]
	
	op typeStrictBinaryOperators : -> Set [memo] 
	rule typeStrictBinaryOperators => Set(
		l('_*_),, l('_/_),, l('_%_),,
		l('_+_),, l('_-_),,
		l('_<_),, l('_>_),, l('_<=_),, l('_>=_),,
		l('_&_),, l('_|_),, l('_^_),,
		l('_`[_`])
	)
	[structural]
	
	op typeStrictLeftBinaryOperators : -> Set [memo] 
	rule typeStrictLeftBinaryOperators => Set(
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
	rule [ignore-volatile]: t(S:Set, qualifiedType(t(S':Set, T:SimpleType), Volatile)) 
		=> t(S:Set S':Set, T:SimpleType) 
		[structural]
	rule [ignore-restrict]: t(S:Set, qualifiedType(t(S':Set, T:SimpleType), Restrict)) 
		=> t(S:Set S':Set, T:SimpleType) 
		[structural]
	// rule [ignore-const]: t(S:Set, qualifiedType(t(S':Set, T:SimpleType), Const)) 
		// => t(S:Set S':Set, T:SimpleType) 
		// [structural]
	rule [ignore-auto]: t(S:Set, qualifiedType(t(S':Set, T:SimpleType), Auto)) 
		=> t(S:Set S':Set, T:SimpleType) 
		[structural]
	rule [ignore-register]: t(S:Set, qualifiedType(t(S':Set, T:SimpleType), Register)) 
		=> t(S:Set S':Set, T:SimpleType)
		[structural]
	
	
	rule
		< k > giveType(X:#Id, T:Type) => 
			if (Fun:#Id ==Bool File-Scope) then giveGlobalType(X:#Id, T:Type) else giveLocalType(X:#Id, T:Type) fi
			...</ k >
		< currentFunction > Fun:#Id </ currentFunction >
		if notBool hasStaticType(T:Type)
		[structural] 
		
	rule
		< k > giveGlobalType(X:#Id, T:Type) => .K ...</ k >
		< types > M:Map => M:Map[T:Type / X:#Id] </ types >
		< gtypes >... Tu:K |-> Map((M':Map => M':Map[T:Type / X:#Id])) ...</ gtypes >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		[structural] 
	rule
		< k > giveLocalType(X:#Id, T:Type) => .K ...</ k >
		< types > M:Map => M:Map[T:Type / X:#Id] </ types >
		[structural]	
endkm

kmod COMMON-SEMANTICS-TYPE-STRICTNESS is
	including COMMON-SEMANTICS-TYPE-INCLUDE

	op waitingOnDeclType : -> K 
	rule [type-Cast-heat]:
		< k > (. => DeclType(Specifier:K, DeclType:K)) ~> evalToType ...</ k >
		< type > Cast(Specifier:K, DeclType:K, ?) => waitingOnDeclType ...</ type >
		[structural] 
		
	rule [type-Cast-cool]:
		< k > (T:Type => .) ~> evalToType ...</ k >
		< type > waitingOnDeclType => T:Type ...</ type >
		[structural] 
		
	rule [type-ternary-heat-left]:
		< type > K1:K ? K2:K : K3:K => K2:K ~> K1:K ? HOLE : K3:K ...</ type >
		if notBool isAType(K2:K)
		[structural] 
	rule [type-ternary-cool-left]:
		< type > T:Type ~> K1:K ? HOLE : K3:K => K1:K ? T:Type : K3:K ...</ type >
		if isAType(T:Type)
		[structural] 
	rule [type-ternary-heat-right]:
		< type > K1:K ? K2:K : K3:K => K3:K ~> K1:K ? K2:K : HOLE ...</ type >
		if notBool isAType(K3:K)
		[structural] 
	rule [type-ternary-cool-right]:
		< type > T:Type ~> K1:K ? K2:K : HOLE => K1:K ? K2:K : T:Type ...</ type >
		if isAType(T:Type)
		[structural] 
		
	rule [type-bin-arith-heat-left]:
		< type > L:KLabel(K:K,, K':K) => K:K ~> L:KLabel(HOLE,, K':K) ...</ type >
		if notBool isAType(K:K)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-arith-cool-left]:
		< type > T:Type ~> L:KLabel(HOLE,, K:K) => L:KLabel(T:Type,, K:K) ...</ type >
		if isAType(T:Type)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-arith-heat-right]:
		< type > L:KLabel(K:K,, K':K) => K':K ~> L:KLabel(K:K,, HOLE) ...</ type >
		if notBool isAType(K':K)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-arith-cool-right]:
		< type > T:Type ~> L:KLabel(K:K,, HOLE) => L:KLabel(K:K,, T:Type) ...</ type >
		if isAType(T:Type)
		andBool typeStrictBinaryOperators contains l(L:KLabel)
		[structural] 
		
	rule [type-unary-arith-heat]:
		< type > L:KLabel(K:K) => K:K ~> L:KLabel(HOLE) ...</ type >
		if notBool isAType(K:K)
		andBool typeStrictUnaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-unary-arith-cool]:
		< type > T:Type ~> L:KLabel(HOLE) => L:KLabel(T:Type) ...</ type >
		if isAType(T:Type)
		andBool typeStrictUnaryOperators contains l(L:KLabel)
		[structural] 
		
	rule [type-bin-left-arith-heat]:
		< type > L:KLabel(K:K,, Args:List{K}) => K:K ~> L:KLabel(HOLE,, Args:List{K}) ...</ type >
		if notBool isAType(K:K)
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural] 
	rule [type-bin-left-arith-cool]:
		< type > T:Type ~> L:KLabel(HOLE,, Args:List{K}) => L:KLabel(T:Type,, Args:List{K}) ...</ type >
		if isAType(T:Type)
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural] 

		
	rule [type-dot-heat]:
		< type > K:K . X:#Id => K:K ~> HOLE . X:#Id ...</ type >
		if notBool isAType(K:K)
		[structural] 
	rule [type-dot-cool]:
		< type > T:Type ~> HOLE . X:#Id => T:Type . X:#Id ...</ type >
		if isAType(T:Type)
		[structural]
		
	rule [type-call-heat]:
		< type > Call(K:K, L:K) => K:K ~> Call(HOLE, L:K) ...</ type >
		if notBool isAType(K:K)
		[structural] 
	rule [type-call-cool]:
		< type > T:Type ~> Call(HOLE, L:K) => Call(T:Type, L:K) ...</ type >
		if isAType(T:Type)
		[structural] 
endkm

kmod COMMON-SEMANTICS-TYPE-CANONICALIZATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	
	op canonicalizeType-aux : Bag K Bag Bag Bag -> K 
	context canonicalizeType-aux(_,[#],_,_,_) if [#] =/=Bool .K 

		
	rule
		< k > canonicalizeType(B:Bag) => canonicalizeType-aux(B:Bag, .K, .Bag, .Bag, .Bag) ...</ k >
		[structural] 
		

	
	rule
		< k > (.K => DeclType(K1:K, K2:K))
			~> canonicalizeType-aux((?:Bag BagItem(TAtomic(K1:K, K2:K))), ?, ?, ?, ?) 
		...</ k >
		[structural]
		
	op atomic : Type -> K
	
	rule
		< k > (T:Type => .K)
			~> canonicalizeType-aux((?:Bag (BagItem(TAtomic(K1:K, K2:K)) => .Bag)), ?, (? (.Bag => BagItem(atomic(T:Type)))), ?, ?) 
		...</ k >
			if isAType(T:Type)
		[structural]
		
	// specifier, modifier, storage
	rule
		< k > canonicalizeType-aux((?:Bag (BagItem(T:K) => .Bag)), ?, (? (.Bag => BagItem(T:K))), ?, ?) ...</ k >
		if false
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
		orBool (getKLabel(T:K) ==Bool 'AttributeValue)
		[structural] 

	rule
		< k > canonicalizeType-aux(B:Bag (BagItem(T:K) => .Bag), ?, ?, ?, (? .Bag => BagItem(T:K))) ...</ k >
		if T:K ==Bool Extern
		orBool T:K ==Bool Static
		orBool T:K ==Bool Const
		orBool T:K ==Bool Volatile
		orBool T:K ==Bool Restrict
		orBool T:K ==Bool Auto
		orBool T:K ==Bool Register
		[structural] 
		
	rule
		< k > canonicalizeType-aux(.Bag, (T:Type => t(.Set, qualifiedType(T:Type, Q:K))), .Bag, .Bag, (? BagItem(Q:K) => .Bag)) ...</ k >
		if Q:K ==Bool Extern
		orBool Q:K ==Bool Static
		orBool Q:K ==Bool Volatile
		orBool Q:K ==Bool Restrict
		orBool Q:K ==Bool Auto
		orBool Q:K ==Bool Register
		[structural]
	rule
		< k > canonicalizeType-aux(.Bag, (t((.Set => SetItem(Const)) ?, ?)), .Bag, .Bag, (? BagItem(Q:K) => .Bag)) ...</ k >
		if Q:K ==Bool Const
		[structural]
		
	/*@ \source[n1570]{\para{6.7.3}{9}}
	If the specification of an array type includes any type qualifiers, the element type is so-qualified, not the array type. \ldots
	*/
	rule t(SetItem(Const) S:Set, arrayType(t(S':Set, T:SimpleType), N:#Nat))
		=> t(S:Set, arrayType(t(SetItem(Const) S':Set, T:SimpleType), N:#Nat))
		[structural]
	
	rule
		< k > canonicalizeSpecifier(BagItem(Named(X:#Id)))
			=> t(.Set, typedefType(X:#Id, T:Type))
		...</ k >
		< types >... typedef(X:#Id) |-> T:Type ...</ types >
		if X:#Id =/=Bool Identifier("")
		[structural]
		
	rule
		< k > canonicalizeSpecifier(BagItem(StructRef(X:#Id)))
			=> t(.Set, structType(X:#Id))
		...</ k >
		if X:#Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(EnumRef(X:#Id)))
			=> t(.Set, enumType(X:#Id))
		...</ k >
		if X:#Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(UnionRef(X:#Id)))
			=> t(.Set, unionType(X:#Id))
		...</ k >
		if X:#Id =/=Bool Identifier("")
		[structural] 
		
	rule
		< k > canonicalizeSpecifier(BagItem(EnumDef(X:#Id, L:List{C})))
			=> EnumDef(X:#Id, L:List{C})
			~> t(.Set, enumType(X:#Id))
		...</ k >
		if X:#Id =/=Bool Identifier("")
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(L:KLabel(((Identifier("") => unnamed(N:#Nat)),, L:List{C})))) ...</ k >
		< freshNat > N:#Nat => sNat(N:#Nat) </ freshNat >
		if L:KLabel ==Bool 'StructDef
		orBool L:KLabel ==Bool 'EnumDef
		orBool L:KLabel ==Bool 'UnionDef
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(StructDef(X:#Id, L:List{C})))
			=> StructDef(X:#Id, L:List{C})
			~> t(.Set, structType(X:#Id))
		...</ k >
		if X:#Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(UnionDef(X:#Id, L:List{C})))
			=> UnionDef(X:#Id, L:List{C})
			~> t(.Set, unionType(X:#Id))
		...</ k >
		if X:#Id =/=Bool Identifier("")
		[structural] 
		

	// FIXME what good is this?
	rule BagItem(SpecTypedef) => .Bag [structural]
	// fixme ignoring inlines
	rule [ignore-inline]: BagItem(Inline) => .Bag [structural]
	rule [ignore-noreturn]: BagItem(Noreturn) => .Bag [structural]
	// fixme should save these for later use
	rule BagItem(AttributeValue(?, ?)) => .Bag [structural]

	rule 
		< k > canonicalizeType-aux(.Bag, (.K => canonicalizeSpecifier(B:Bag)), (B:Bag => .Bag), ?, ?) ...</ k >
		if B:Bag =/=Bool .Bag
		[structural] 
		
	rule
		< k > canonicalizeType-aux(.Bag, T:Type, .Bag, .Bag, .Bag) => T:Type ...</ k >
		[structural] 
		
	op canonicalizeSpecifier : Bag -> K 
	// C99 6.7.2:2
	rule canonicalizeSpecifier(BagItem(Void)) => t(.Set, void) [structural]
	rule canonicalizeSpecifier(BagItem(Bool)) => t(.Set, bool) [structural]
	rule canonicalizeSpecifier(BagItem(Char)) => t(.Set, char) [structural]
	rule canonicalizeSpecifier(BagItem(Signed) BagItem(Char)) => t(.Set, signed-char) [structural]
	rule canonicalizeSpecifier(BagItem(Unsigned) BagItem(Char)) => t(.Set, unsigned-char) [structural]
	
	rule canonicalizeSpecifier(BagItem(atomic(t(S:Set, T:SimpleType)))) => t(S:Set SetItem(Atomic), T:SimpleType) [structural]
	
	rule canonicalizeSpecifier(BagItem(Double)) => t(.Set, double) [structural]
	rule canonicalizeSpecifier(BagItem(Float)) => t(.Set, float) [structural]
	rule canonicalizeSpecifier(BagItem(Long) BagItem(Double)) => t(.Set, long-double) [structural]
	
	rule canonicalizeSpecifier(BagItem(Complex) BagItem(Double)) => t(SetItem(Complex), double) [structural]
	rule canonicalizeSpecifier(BagItem(Complex) BagItem(Float)) => t(SetItem(Complex), float) [structural]
	rule canonicalizeSpecifier(BagItem(Complex) BagItem(Long) BagItem(Double)) => t(SetItem(Complex), long-double) [structural]
	
	rule canonicalizeSpecifier(BagItem(Imaginary) BagItem(Double)) => t(SetItem(Imaginary), double) [structural]
	rule canonicalizeSpecifier(BagItem(Imaginary) BagItem(Float)) => t(SetItem(Imaginary), float) [structural]
	rule canonicalizeSpecifier(BagItem(Imaginary) BagItem(Long) BagItem(Double)) => t(SetItem(Imaginary), long-double) [structural]
	
	rule canonicalizeSpecifier(B:Bag) => t(.Set, short-int)
		if B:Bag ==Bool BagItem(Short)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Short)
		orBool B:Bag ==Bool BagItem(Short) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Short) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-short-int)
		if B:Bag ==Bool BagItem(Unsigned) BagItem(Short)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Short) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => t(.Set, int)
		if B:Bag ==Bool BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-int)
		if B:Bag ==Bool BagItem(Unsigned)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => t(.Set, long-int)
		if B:Bag ==Bool BagItem(Long)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-int)
		if B:Bag ==Bool BagItem(Unsigned) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => t(.Set, long-long-int)
		if B:Bag ==Bool BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Long) BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-long-int)
		if B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
endkm

kmod COMMON-SEMANTICS-TYPE-INTERPRETATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 

	op structDefType : #Id List{Type} -> Type 
	
	op BitFieldType : K K -> K [metadata "strict=()"] 
	
	rule
		< k > Specifier(L:List{Type}) => canonicalizeType(Bag(getList{K}(L:List{Type}))) ...</ k >
		[structural]
		
	rule BitFieldType(T:Type, tv(N:#Nat, ?)) => t(.Set, bitfieldType(T:Type, N:#Nat)) [structural]
	
	op makeArrayType : #Nat -> KLabel 
	op makeFunctionType : List{Type} -> KLabel 
	op pushTypeDown : Type KLabel -> Type 
	op makePointerType : -> KLabel
	op makeIncompleteArrayType : -> KLabel
	
	// fixme, throwing away specifier
	rule ArrayType(T:Type, tv(N:#Nat, ?), ?) 
		=> pushTypeDown(T:Type, makeArrayType(N:#Nat)) 
		if N:#Nat >Nat 0
		[structural]
	rule ArrayType(T:Type, emptyValue, ?) => pushTypeDown(T:Type, makeIncompleteArrayType) [structural]
	rule PointerType(T:Type) => pushTypeDown(T:Type, makePointerType) [structural]
	// fixme I'm assuming functiontype is always below a prototype in the ast
	rule FunctionType(T:Type) => T:Type [structural]
	rule Prototype(T:Type, L:List{Type}, false) => pushTypeDown(T:Type, makeFunctionType(L:List{Type})) [structural]
	rule Prototype(T:Type, L:List{Type}, true) => pushTypeDown(T:Type, makeFunctionType((L:List{Type} :: t(.Set, variadic)))) [structural]
	
	rule [pushdown-array]: pushTypeDown(t(S:Set, arrayType(T:Type, N:#Nat)), K:KLabel) => t(S:Set, arrayType(pushTypeDown(T:Type, K:KLabel), N:#Nat)) [structural]
	rule [pushdown-incomplete]: pushTypeDown(t(S:Set, incompleteArrayType(T:Type)), K:KLabel) => t(S:Set, incompleteArrayType(pushTypeDown(T:Type, K:KLabel))) [structural]
	rule [pushdown-pointer]: pushTypeDown(t(S:Set, pointerType(T:Type)), K:KLabel) => t(S:Set, pointerType(pushTypeDown(T:Type, K:KLabel))) [structural]
	rule [pushdown-qualified]: pushTypeDown(t(S:Set, qualifiedType(T:Type, K:K)), K:KLabel) => t(S:Set, qualifiedType(pushTypeDown(T:Type, K:KLabel), K:K)) [structural]
	rule [pushdown-function]: pushTypeDown(t(S:Set, functionType(T:Type, L:List{Type})), K:KLabel) => t(S:Set, functionType(pushTypeDown(T:Type, K:KLabel), L:List{Type})) [structural]
	rule [pushdown-struct]: pushTypeDown(t(S:Set, structType(X:#Id)), K:KLabel) => K:KLabel(t(S:Set, structType(X:#Id))) [structural]
	rule [pushdown-union]: pushTypeDown(t(S:Set, unionType(X:#Id)), K:KLabel) => K:KLabel(t(S:Set, unionType(X:#Id))) [structural]
	rule [pushdown-enum]: pushTypeDown(t(S:Set, enumType(X:#Id)), K:KLabel) => K:KLabel(t(S:Set, enumType(X:#Id))) [structural]
	
	rule [pushdown-typedef]: pushTypeDown(t(S:Set, typedefType(X:#Id, t(S':Set, T:SimpleType))), K:KLabel) => K:KLabel(t(S:Set S':Set, T:SimpleType)) [structural]
	
	rule [pushdown-basic]: pushTypeDown(T:Type, K:KLabel) => K:KLabel(T:Type) 
		if isBasicType(T:Type)
		[structural]
	
	rule makeArrayType(N:#Nat)(T:Type) => t(.Set, arrayType(T:Type, N:#Nat)) [structural]
	rule makeFunctionType(L:List{Type})(T:Type) => t(.Set, functionType(T:Type, giveNamesToArgs(L:List{Type}))) [structural]
	rule makePointerType(T:Type) => t(.Set, pointerType(T:Type)) [structural]
	rule makeIncompleteArrayType(T:Type) => t(.Set, incompleteArrayType(T:Type)) [structural]
	
	op giveNamesToArgs : List{Type} -> List{Type}
	op giveNamesToArgs-aux : #Nat List{Type} -> List{Type}
	
	rule giveNamesToArgs(L:List{Type}) => giveNamesToArgs-aux(0, L:List{Type}) [structural]
	rule giveNamesToArgs-aux(N:#Nat, (typedDeclaration(T:Type, X:#Id) :: L:List{Type}))
		=> typedDeclaration(T:Type, X:#Id) :: giveNamesToArgs-aux(N:#Nat, L:List{Type})
		if X:#Id =/=Bool #NoName
		[structural]
	rule giveNamesToArgs-aux(N:#Nat, (typedDeclaration(T:Type, X:#Id) :: L:List{Type}))
		=> typedDeclaration(T:Type, #NoName(N:#Nat)) :: giveNamesToArgs-aux(sNat(N:#Nat), L:List{Type})
		if X:#Id ==Bool #NoName
		[structural]
	rule giveNamesToArgs-aux(?, t(.Set, variadic))
		=> t(.Set, variadic)
		[structural]
	rule giveNamesToArgs-aux(?, Nil)
		=> Nil
		[structural]
	
	rule 
		< k > JustBase => T:Type ...</ k >
		< declarationTypeHolder > T:Type => .K ...</ declarationTypeHolder >
		[structural] 

	op extractActualTypeFreezer : -> K 
	rule
		< k > DeclType(T:Type, K:K) => K:K ~> extractActualTypeFreezer ...</ k >
		< declarationTypeHolder > (. => T:Type) ...</ declarationTypeHolder >
		[structural] 
	
	rule
		< k > T:Type ~> extractActualTypeFreezer 
			=> extractActualType(T:Type)
		...</ k >
		[structural] 
		
	op fillBitHoles : List{Type} -> List{Type} 
	op fillBitHoles : #Nat List{Type} -> List{Type} 
	rule [fillBitHoles-none]:
		fillBitHoles(Nil) => Nil 
		[structural]
	// if we haven't seen bitfields
	rule [fillBitHoles-not-bitfield]:
		fillBitHoles((typedDeclaration(T:Type, X:#Id) :: L:List{Type})) 
			=> typedDeclaration(T:Type, X:#Id) :: fillBitHoles(L:List{Type})
		if notBool hasBitfieldType(T:Type) 
		[structural]
	
	rule [fillBitHoles-bitfield]:
		fillBitHoles((typedDeclaration(T:Type, X:#Id) :: L:List{Type})) 
			=> fillBitHoles(0, typedDeclaration(T:Type, X:#Id) :: L:List{Type})
		if hasBitfieldType(T:Type) 
		[structural]
	
	// if we have seen bitfields
	rule [fillBitHoles-aux-not-bitfield]:
		fillBitHoles(N:#Nat, (typedDeclaration(T:Type, X:#Id) :: L:List{Type})) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), absInt(numBitsPerByte -Int (N:#Nat %Nat numBitsPerByte)) %Nat numBitsPerByte)), #NoName)
				:: fillBitHoles(typedDeclaration(T:Type, X:#Id) :: L:List{Type})
		if notBool hasBitfieldType(T:Type) 
		[structural]
	
	rule [fillBitHoles-aux-bitfield-normal]:
		fillBitHoles(N:#Nat, (typedDeclaration(t(S:Set, bitfieldType(T:Type, N':#Nat)), X:#Id) :: L:List{Type})) 
			=> typedDeclaration(t(S:Set, bitfieldType(T:Type, N':#Nat)), X:#Id)
				:: fillBitHoles(N:#Nat +Nat N':#Nat, L:List{Type})
		if N':#Nat =/=Bool 0 
		[structural]
		
	rule [fillBitHoles-bitfield-zero]:
		fillBitHoles(N:#Nat, (typedDeclaration(t(?, bitfieldType(T:Type, N':#Nat)), ?) :: L:List{Type})) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), absInt(numBitsPerByte -Int (N:#Nat %Nat numBitsPerByte)) %Nat numBitsPerByte)), #NoName)
				:: fillBitHoles(L:List{Type})
		if N':#Nat ==Bool 0
		[structural]
	
	rule [fillBitHoles-done]:
		fillBitHoles(N:#Nat, Nil) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), absInt(numBitsPerByte -Int (N:#Nat %Nat numBitsPerByte)) %Nat numBitsPerByte)), #NoName) 
		[structural]

	
	rule typedDeclaration(t(?, bitfieldType(?, N:#Nat)), #NoName) :: typedDeclaration(t(?, bitfieldType(?, N':#Nat)), #NoName) 
		=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), N:#Nat +Nat N':#Nat)), #NoName) 
		[structural]
	
	// fixme chould check for some struct contraints here
	op incompleteToFlexibleArrayMember : List{Type} -> List{Type} 
	rule incompleteToFlexibleArrayMember(typedDeclaration(T:Type, X:#Id) :: L:List{Type}) 
		=> typedDeclaration(T:Type, X:#Id) :: incompleteToFlexibleArrayMember(L:List{Type}) 
		if notBool hasIncompleteType(T:Type) 
		[structural]
	rule incompleteToFlexibleArrayMember(typedDeclaration(t(S:Set, incompleteArrayType(T:Type)), X:#Id)) => typedDeclaration(t(S:Set, flexibleArrayType(T:Type)), X:#Id) [structural]
	rule incompleteToFlexibleArrayMember(Nil) => Nil [structural]
	
	rule
		< k > StructDef(X:#Id, L:List{Type})
			=> addStruct(X:#Id, fillBitHoles(incompleteToFlexibleArrayMember(L:List{Type})))
			~> giveType(X:#Id, t(.Set, structType(X:#Id)))
		...</ k >
		[structural] 
	rule
		< k > UnionDef(X:#Id, L:List{Type})
			=> addUnion(X:#Id, L:List{Type})
			~> giveType(X:#Id, t(.Set, unionType(X:#Id)))
		...</ k >
		[structural] 

	// the K will resolve to a type, so throw it away
	rule
		< k > OnlyTypedef(K:K) => K:K ~> discard ...</ k >
		[structural] 
		
			
	rule
		NameAndType(X:#Id, T:Type) => typedDeclaration(T:Type, X:#Id)
		[structural] 
	
	rule [extract-basic]: extractActualType(T:Type) => T:Type if isBasicType(T:Type) [structural]
	rule [extract-enum]: extractActualType(t(S:Set, enumType(X:#Id))) => t(S:Set, enumType(X:#Id)) [structural]
	rule [extract-struct]: extractActualType(t(S:Set, structType(X:#Id))) => t(S:Set, structType(X:#Id)) [structural]
	rule [extract-union]: extractActualType(t(S:Set, unionType(X:#Id))) => t(S:Set, unionType(X:#Id)) [structural]
	rule [extract-array]: extractActualType(t(S:Set, arrayType(T:Type, N:#Nat))) => t(S:Set, arrayType(extractActualType(T:Type), N:#Nat)) [structural]
	rule [extract-incompleteArray]: extractActualType(t(S:Set, incompleteArrayType(T:Type))) => t(S:Set, incompleteArrayType(extractActualType(T:Type))) [structural]
	rule [extract-bitfield]: extractActualType(t(S:Set, bitfieldType(T:Type, N:#Nat))) => t(S:Set, bitfieldType(extractActualType(T:Type), N:#Nat)) [structural]
	rule [extract-function]: extractActualType(t(S:Set, functionType(T:Type, List:List{Type}))) => t(S:Set, functionType(extractActualType(T:Type), List:List{Type})) [structural]
	rule [extract-pointer]:  extractActualType(t(S:Set, pointerType(T:Type))) => t(S:Set, pointerType(extractActualType(T:Type))) [structural]
	rule [extract-qualified]: extractActualType(t(S:Set, qualifiedType(T:Type, K:K))) => t(S:Set, qualifiedType(extractActualType(T:Type), K:K)) [structural]
	rule [extract-typedef]: extractActualType(t(S:Set, typedefType(?, t(S':Set, T:SimpleType)))) => extractActualType(t(S:Set S':Set, T:SimpleType)) [structural]
		
	op NameAndType : K K -> K [metadata "strict=(2)"] 
		
	rule
		SingleName(T:Type, Name(X:#Id, K:K)) => NameAndType(X:#Id, DeclType(T:Type, K:K))
		[structural] 
	rule [Separate-FieldGroups]:
		FieldGroup(K:K, (C:C :: C':C :: L:List{C})) => FieldGroup(K:K, C:C) :: FieldGroup(K:K, (C':C :: L:List{C}))
		[structural]
		
	// op shouldFlatten : List{C} -> Type
	// rule C :: shouldFlatten(L':List{C}) => C :: L':List{C} [structural]
	// rule shouldFlatten(L':List{C}) :: C => L':List{C} :: C [structural]
	// fixme WHY CAN'T I WRITE THIS???
	
	// op flattenList : List{C} -> List{C} [metadata "strict=()"]
	// op flattenListAux : List{C} -> List{C} [metadata "strict=()"]
	// rule ('flattenList => 'flattenListAux)(?:List{Type}) [structural]
	// rule 'flattenListAux(('_::_(Lab:KLabel(L:List{K}),, Rem:List{Type})),, (Other:List{Type})) 
		// => 'flattenListAux('_::_(Rem:List{Type}),, (Other:List{Type},, Lab:KLabel(L:List{K}))) 
		// if Lab:KLabel =/=Bool '_::_
		// [structural]
	// rule 'flattenListAux(('_::_('_::_(L:List{K}),, Rem:List{Type})),, (Other:List{Type})) 
		// => 'flattenListAux(('_::_(L:List{K},, Rem:List{Type})),, (Other:List{Type})) 
		// [structural]
	// rule 'flattenListAux(('_::_(.List{K})),, (Other:List{Type})) 
		// => Other:List{Type}
		// [structural]
	rule
		FieldGroup(T:Type, Name(X:#Id, K:K)) => NameAndType(X:#Id, DeclType(T:Type, K:K))
		[structural]
		
	rule
		FieldGroup(T:Type, BitFieldName(Name(X:#Id, K:K), Size:K))
		=> NameAndType(X:#Id, DeclType(T:Type, BitFieldType(K:K, Size:K)))
		[structural] 
	rule FieldName(K:K) => K:K [structural]
endkm

kmod COMMON-SEMANTICS-TYPE-EXPRESSIONS is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	
	op HOLE : -> K 
	rule
		< k > typeof(E:Expression) => evalToType ~> typeof(HOLE) ...</ k >
		(.Bag => < type > E:Expression </ type >)
		[structural] 
	rule
		< k > evalToType ~> typeof(HOLE) => T:Type ...</ k >
		(< type > T:Type </ type > => .Bag)
		if isAType T:Type
		[structural] 

	rule
		< type > emptyValue => t(.Set, void) ...</ type > 
		[structural] 
		
	rule
		< type > T:Type << ? => T:Type ...</ type >
		[structural] 
	rule
		< type > T:Type >> ? => T:Type ...</ type >
		[structural] 
		
	rule
		< type > tv(?, T:Type) => T:Type ...</ type >
		[structural] 
	
	rule
		< type > SizeofExpression(?) => cfg:sizeut ...</ type >
		[structural] 

	rule < type > E1:K[E2:K] => *(E1:K + E2:K) ...</ type > 
		[structural] 
	rule 
		< type > arithInterpret(T:Type, ?) => T:Type ...</ type > 
		[structural]
	rule
		< type > t(S:Set, pointerType(T:Type)) + T':Type => t(S:Set, pointerType(T:Type)) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > T':Type + t(S:Set, pointerType(T:Type)) => t(S:Set, pointerType(T:Type)) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > t(S:Set, pointerType(T:Type)) - T':Type => t(S:Set, pointerType(T:Type)) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > t(?, pointerType(T:Type)) - t(?, pointerType(T':Type)) => cfg:ptrdiffut ...</ type >
		[structural]
	rule
		< type > t(S:Set, arrayType(T:Type, ?)) + T':Type => t(S:Set, pointerType(T:Type)) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > T':Type + t(S:Set, arrayType(T:Type, ?)) => t(S:Set, pointerType(T:Type)) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > t(S:Set, arrayType(T:Type, ?)) - T':Type => t(S:Set, pointerType(T:Type)) ...</ type >
		if hasIntegerType(T':Type)
		[structural]

	// c99 6.4.5
	rule
		< type > Constant(StringLiteral(S:#String)) => t(.Set, arrayType(t(.Set, char), lengthString(S:#String) +Nat 1)) ...</ type >
		[structural]
	rule
		< type > Constant(WStringLiteral(L:List{K})) => t(.Set, arrayType(cfg:wcharut, lengthList{K}(L:List{K}) +Nat 1)) ...</ type >
		[structural]
		
	rule
		< type > K:K => T:Type ...</ type >
		< types >... K:K |-> T:Type ...</ types >
		[structural] 
			
	rule
		< type > Comma(L:List{C} :: K:C) => K:C ...</ type >
		[structural] 

	rule [type-call-func]:
		< type > Call(t(?, functionType(T:Type, ?)), ?) => T:Type ...</ type >
		[structural]
		 		
	rule [type-struct-dot]:
		< type > t(?, structType(S:#Id)) . F:#Id => T:Type ...</ type >
		< structs >... 
			S:#Id |-> aggregateInfo(?, (? F:#Id |-> T:Type), ?)
		...</ structs >
		[structural] 
	rule [type-union-dot]:
		< type > t(?, unionType(S:#Id)) . F:#Id => T:Type ...</ type >
		< structs >... 
			S:#Id |-> aggregateInfo(?, (? F:#Id |-> T:Type), ?)
		...</ structs >
		[structural] 
	
	rule [type-deref-type]:
		< type > *(t(?, pointerType(T:Type))) => T:Type ...</ type >
		[structural] 
	rule [type-deref-array-type]:
		< type > *(t(?, arrayType(T:Type, ?))) => T:Type ...</ type >
		[structural] 

	rule [type-compound-literal]:
		< type > CompoundLiteral(?, Specifier:K, DeclType:K, ?)
			=> Cast(Specifier:K, DeclType:K, emptyValue)  // sort of hackish, assumes cast will evaluate to type
		...</ type >
		[structural] 
	
	rule [type-assignment]:
		< type > L:KLabel(K:K,, ?) 
			=> K:K
		...</ type >
		if Set(
			l('_:=_),, l('_*=_),, l('_/=_),, l('_%=_),, l('_+=_),, l('_-=_),, 
			l('_<<=_),, l('_>>=_),, l('_&=_),, l('_^=_),, l('_|=_)
		) contains l(L:KLabel)
		[structural]

	rule 
		< type > L:KLabel(T:Type,, T':Type) => usualArithmeticConversion(T:Type, T':Type) ...</ type >
		if isArithBinConversionOp(L:KLabel)
		andBool (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type))
		[structural] 
		
	rule [type-ternary-arithmetic]:
		< type > ?:K ? T:Type : T':Type => usualArithmeticConversion(T:Type, T':Type) ...</ type >
		if (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type))
		[structural]
	rule [type-ternary-identical]:
		< type > ?:K ? T:Type : T:Type => T:Type ...</ type >
		if isAType(T:Type)
		andBool notBool hasArrayType(T:Type)
		[structural]
		
	rule [type-ternary-array-left]: < type > ?:K ? (t(S:Set, arrayType(T:Type, ?)) => t(S:Set, pointerType(T:Type))) : ? ...</ type > [structural]
	rule [type-ternary-array-right]: < type > ?:K ? ?:K : (t(S:Set, arrayType(T:Type, ?)) => t(S:Set, pointerType(T:Type))) ...</ type > [structural]
		
	rule [type-ternary-pointer]: // not safe, could be incompatible types
		< type > ?:K ? t(S:Set, pointerType(T:Type)) : t(S':Set, pointerType(T':Type)) => t(S:Set, pointerType(T:Type)) ...</ type >
		[structural]

	rule
		< type > L:KLabel(T:Type) => promote(T:Type) ...</ type > 
		if isArithUnaryOp(L:KLabel)
		andBool (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		[structural]
	
	rule 
		< type > L:KLabel(T:Type,, ?:List{K}) => promote(T:Type) ...</ type >
		if (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural]
		
	rule [type-inc-dec]:
		< type > L:KLabel(T:Type) => T:Type ...</ type >
		if hasPointerType(T:Type)
		andBool (
			L:KLabel ==Bool ('_++)
			orBool L:KLabel ==Bool ('_--)
			orBool L:KLabel ==Bool ('--_)
			orBool L:KLabel ==Bool ('++_)
		)
		[structural]
		
	rule
		< type > L:KLabel(?:K,, ?:K) => t(.Set, int) ...</ type >
		if L:KLabel ==Bool '_==_
		orBool L:KLabel ==Bool '_!=_
		orBool L:KLabel ==Bool '_&&_
		orBool L:KLabel ==Bool '_||_
		[structural]
		
	rule [type-address]:
		< type > & T:Type => t(.Set, pointerType(T:Type)) ...</ type >
		if isAType(T:Type)
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
		< currentProgramLoc > ? => L:CabsLoc </ currentProgramLoc >
		[structural] 
		
	/*@ \source[n1570]{\para{6.2.7}{1}}
	Two types have compatible type if their types are the same. Additional rules for determining whether two types are compatible are described in 6.7.2 for type specifiers, in 6.7.3 for type qualifiers, and in 6.7.6 for declarators.  Moreover, two structure, union, or enumerated types declared in separate translation units are compatible if their tags and members satisfy the following requirements: If one is declared with a tag, the other shall be declared with the same tag. If both are completed anywhere within their respective translation units, then the following additional requirements apply: there shall be a one-to-one correspondence between their members such that each pair of corresponding members are declared with compatible types; if one member of the pair is declared with an alignment specifier, the other is declared with an equivalent alignment specifier; and if one member of the pair is declared with a name, the other is declared with the same name. For two structures, corresponding members shall be declared in the same order. For two structures or unions, corresponding bit-fields shall have the same widths. For two enumerations, corresponding members shall have the same values.
	
	\source[n1570]{\para{6.7.3}{10}}
	For two qualified types to be compatible, both shall have the identically qualified version of a compatible type; the order of type qualifiers within a list of specifiers or qualifiers does not affect the specified type.
	*/
	
	rule [typeCompatible-identical]: isTypeCompatible(T:Type, T:Type) 
		=> true 
		[structural]
	rule [typeCompatible-two-ints]: isTypeCompatible(T:Type, T':Type) 
		=> true 
		if hasIntegerType(T:Type)
		andBool hasIntegerType(T':Type) 
		[structural]
	rule [typeCompatible-two-ptr]: isTypeCompatible(t(?, pointerType(?)), t(?, pointerType(?)))
		=> true 
		[structural]
	rule [typeCompatible-ptr-int]: isTypeCompatible(t(?, pointerType(?)), T:Type)
		=> true
		if hasIntegerType(T:Type) 
		[structural]
	rule [typeCompatible-int-ptr]: isTypeCompatible(T:Type, t(?, pointerType(?)))
		=> true
		if hasIntegerType(T:Type)
		[structural]
		
	rule [typeCompatible-declarations]: isTypeCompatible(typedDeclaration(T:Type, ?), typedDeclaration(T':Type, ?))
		=> isTypeCompatible(T:Type, T':Type) 
		[structural]
	rule [typeCompatible-prototypes]: isTypeCompatible(t(?, prototype(T:Type)), t(?, prototype(T':Type))) 
		=> isTypeCompatible(T:Type, T':Type) 
		[structural]

	rule [typeCompatible-array-right]: isTypeCompatible(T:Type, t(S:Set, arrayType(T':Type, ?)))
		=> isTypeCompatible(T:Type, t(S:Set, pointerType(T':Type))) 
		[structural]
	rule [typeCompatible-array-left]: isTypeCompatible(t(S:Set, arrayType(T:Type, ?)), T':Type)
		=> isTypeCompatible(t(S:Set, pointerType(T:Type)), T':Type) 
		[structural]
	
	rule [typeCompatible-incompleteArray-right]: isTypeCompatible(T:Type, t(S:Set, incompleteArrayType(T':Type)))
		=> isTypeCompatible(T:Type, t(S:Set, pointerType(T':Type))) 
		[structural]
	rule [typeCompatible-incompleteArray-left]: isTypeCompatible(t(S:Set, incompleteArrayType(T:Type)), T':Type)
		=> isTypeCompatible(t(S:Set, pointerType(T:Type)), T':Type) 
		[structural]

	rule [typeCompatible-function-void-left]: isTypeCompatible(t(?, functionType(T1:Type, typedDeclaration(t(?, void), ?))), t(?, functionType(T2:Type, Nil)))
		=> isTypeCompatible(T1:Type, T2:Type) 
		[structural]
	rule [typeCompatible-function-void-right]: isTypeCompatible(t(?, functionType(T1:Type, Nil)), t(?, functionType(T2:Type, typedDeclaration(t(?, void), ?))))
		=> isTypeCompatible(T1:Type, T2:Type) 
		[structural]
	rule [typeCompatible-function]: isTypeCompatible(t(S:Set, functionType(T1:Type, (T':Type :: L:List{Type}))), t(S':Set, functionType(T2:Type, (T'':Type :: L':List{Type}))))
		=> isTypeCompatible(t(S:Set, functionType(T1:Type, L:List{Type})), t(S':Set, functionType(T2:Type, L':List{Type})))
		andBool isTypeCompatible(T':Type, T'':Type) 
		[structural]
	rule [typeCompatible-incompleteArray-nil]: isTypeCompatible(t(?, functionType(T1:Type, Nil)), t(?, functionType(T2:Type, Nil)))
		=> isTypeCompatible(T1:Type, T2:Type) 
		[structural]
	rule isTypeCompatible(T:Type, T':Type) => true
		if (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type)) 
		[structural]
	rule 
		< k > Cast(T:Type, K:K, V:Value) => cast(DeclType(T:Type, K:K), V:Value) ...</ k >
		[structural] 
			
	op addGlobalAggregate : #Id K -> K 
	op addLocalAggregate : #Id K -> K 
	
	op addStruct-aux : #Id List{Type} K Map Map List{Type} -> K [metadata "strict=(3)"]
	op addUnion-aux : #Id List{Type} Map Map List{Type} -> K
	rule
		< k > addStruct(S:#Id, L:List{Type}) 
			=> addStruct-aux(S:#Id, L:List{Type}, tv(0, cfg:largestUnsigned), .Map, .Map, L:List{Type})
		...</ k >
		if L:List{Type} =/=Bool Nil
		[structural]
	rule
		< k > addStruct-aux(
				S:#Id
				, (typedDeclaration(T:Type, Field:#Id) :: L:List{Type})
				, V:Value
				, Types:Map
				, Offsets:Map
				, L':List{Type}
			) 
			=> addStruct-aux(S:#Id, L:List{Type}, V:Value + bitSizeofType(T:Type), Types:Map[T:Type / Field:#Id], Offsets:Map[value(V:Value) / Field:#Id], L':List{Type})
		...</ k >
		[structural]
	rule
		< k > addStruct-aux(S:#Id, Nil, ?, Types:Map, Offsets:Map, L:List{Type}) 
			=> if (F:#Id ==Bool File-Scope) then 
				(addGlobalAggregate(S:#Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map))) 
			else
				(addLocalAggregate(S:#Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map)))
			fi
		...</ k >
		< currentFunction > F:#Id </ currentFunction >
		[structural]		
		
	rule
		< k > addUnion(S:#Id, L:List{Type}) 
			=> addUnion-aux(S:#Id, L:List{Type}, .Map, .Map, L:List{Type})
		...</ k >
		if L:List{Type} =/=Bool Nil
		[structural]
	rule
		< k > addUnion-aux(
				S:#Id
				, (typedDeclaration(T:Type, Field:#Id) :: L:List{Type})
				, Types:Map
				, Offsets:Map
				, L':List{Type}
			) 
			=> addUnion-aux(S:#Id, L:List{Type}, Types:Map[T:Type / Field:#Id], Offsets:Map[0 / Field:#Id], L':List{Type})
		...</ k >
		[structural]
	rule
		< k > addUnion-aux(S:#Id, Nil, Types:Map, Offsets:Map, L:List{Type}) 
			=> if (F:#Id ==Bool File-Scope) then 
				(addGlobalAggregate(S:#Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map))) 
			else
				(addLocalAggregate(S:#Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map)))
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
		
	rule isAType t(?, T:SimpleType) => true
		if setOfTypes contains l(getKLabel(T:SimpleType)) 
		[structural]
	rule isAType T:Type => true if isBasicType(T:Type) [structural]
	rule isAType K:K => false
		if getKLabel(K:K) =/=Bool 't
		[structural]
	rule isAType t(S:Set, T:SimpleType) => false
		if notBool setOfTypes contains l(getKLabel(T:SimpleType))
		andBool notBool isBasicType(t(S:Set, T:SimpleType)) 
		[structural]
			

	rule hasFloatType(t(?, float)) => true [structural]
	rule hasFloatType(t(?, double)) => true [structural]
	rule hasFloatType(t(?, long-double)) => true [structural]
	rule hasFloatType(t(?, T:SimpleType)) => false
		if T:SimpleType =/=Bool float
		andBool T:SimpleType =/=Bool double
		andBool T:SimpleType =/=Bool long-double
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType
		[structural]
	
	rule [hasCharType-char]: hasCharType(t(?, char)) => true [structural]
	rule [hasCharType-qualified]: hasCharType(t(?, qualifiedType(T:Type, ?))) => hasCharType(T:Type) [structural]
	rule [hasCharType-unsigned-char]: hasCharType(t(?, unsigned-char)) => true [structural]
	rule [hasCharType-signed-char]: hasCharType(t(?, signed-char)) => true [structural]
	rule [hasCharType-other]: hasCharType(t(?, T:SimpleType)) => false
		if T:SimpleType =/=Bool char
		andBool T:SimpleType =/=Bool unsigned-char
		andBool T:SimpleType =/=Bool signed-char
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
		
	rule [hasWCharType-wchar]: hasWCharType(t(?, T:SimpleType)) => true 
		if T:SimpleType ==Bool simpleType(cfg:wcharut)
		[structural]
	rule [hasWCharType-other]: hasWCharType(t(?, T:SimpleType)) => false
		if T:SimpleType =/=Bool simpleType(cfg:wcharut)
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
	rule [hasWCharType-qualified]: hasWCharType(t(?, qualifiedType(T:Type, ?))) => hasWCharType(T:Type) [structural]
	
	rule [hasPointerType-pointer]: hasPointerType(t(?, pointerType(?))) => true [structural]
	rule [hasPointerType-qualified]: hasPointerType(t(?, qualifiedType(T:Type, ?))) => hasPointerType(T:Type) [structural]
	rule [hasPointerType-other]: hasPointerType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'pointerType
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
	
	rule [hasBoolType-bool]: hasBoolType(t(?, bool)) => true [structural]
	rule [hasBoolType-qualifiedType]: hasBoolType(t(?, qualifiedType(T:Type, ?))) => hasBoolType(T:Type) [structural]
	rule [hasBoolType-other]: hasBoolType(t(?, T:SimpleType)) => false
		if T:SimpleType =/=Bool bool 
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
	
	rule [hasArrayType-array]: hasArrayType(t(?, arrayType(?, ?))) => true [structural]
	rule [hasArrayType-incompleteArray]: hasArrayType(t(?, incompleteArrayType(?))) => true [structural]
	rule [hasArrayType-flexibleArray]: hasArrayType(t(?, flexibleArrayType(?))) => true [structural]
	rule [hasArrayType-qualified]: hasArrayType(t(?, qualifiedType(T:Type, ?))) => hasArrayType(T:Type) [structural]
	rule [hasArrayType-other]: hasArrayType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'arrayType 
		andBool getKLabel(T:SimpleType) =/=Bool 'incompleteArrayType 
		andBool getKLabel(T:SimpleType) =/=Bool 'flexibleArrayType 
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasAggregateType(T:Type) => hasArrayType(T:Type) orBool hasStructType(T:Type) [structural]
		
	rule [hasStructType-struct]: hasStructType(t(?, structType(?))) => true [structural]
	rule [hasStructType-qualified]: hasStructType(t(?, qualifiedType(T:Type, ?))) => hasStructType(T:Type) [structural]
	rule [hasStructType-other]: hasStructType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'structType
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
		
	rule [hasUnionType-union]: hasUnionType(t(?, unionType(?))) => true [structural]
	rule [hasUnionType-qualified]: hasUnionType(t(?, qualifiedType(T:Type, ?))) => hasUnionType(T:Type) [structural]
	rule [hasUnionType-other]: hasUnionType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'unionType
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]

	rule [hasIncompleteType-true]: hasIncompleteType(t(?, incompleteArrayType(?))) => true [structural]
	rule [hasIncompleteType-qualified]: hasIncompleteType(t(?, qualifiedType(T:Type, ?))) => hasIncompleteType(T:Type) [structural]
	rule [hasIncompleteType-false]: hasIncompleteType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'incompleteArrayType
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
		
	rule [hasExternType-qualified]: hasExternType(t(?, qualifiedType(T:Type, K:K))) => if (K:K ==Bool Extern) then (true) else (hasExternType(T:Type)) fi 
		[structural]
	rule [hasExternType-false]: hasExternType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
		
	rule [hasStaticType-qualified]: hasStaticType(t(?, qualifiedType(T:Type, K:K))) => if (K:K ==Bool Static) then (true) else (hasStaticType(T:Type)) fi 
		[structural]
	rule [hasStaticType-false]: hasStaticType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
	
	rule [hasConstType-qualified]: 
		hasConstType(t(?, qualifiedType(T:Type, K:K))) => hasConstType(T:Type)
		[structural]
	rule [hasConstType-false]: 
		hasConstType(t(S:Set, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		andBool notBool Const in S:Set
		[structural]
	rule [hasConstType-true]: 
		hasConstType(t(SetItem(Const) ?, T:SimpleType)) => true
		[structural]		
	
		
	rule [hasBitfieldType-true]: hasBitfieldType(t(?, bitfieldType(?, ?))) => true [structural]
	rule [hasBitfieldType-false]: hasBitfieldType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'bitfieldType
		[structural]
		
	rule [hasFunctionType-true]: hasFunctionType(t(?, functionType(?, ?))) => true [structural]
	rule [hasFunctionType-prototype]: hasFunctionType(t(?, prototype(T:Type))) => hasFunctionType(T:Type) [structural]
	rule [hasFunctionType-qualified]: hasFunctionType(t(?, qualifiedType(T:Type, ?))) => hasFunctionType(T:Type) [structural]
	rule [hasFunctionType-false]: hasFunctionType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'functionType
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType
		andBool getKLabel(T:SimpleType) =/=Bool 'prototype 
		[structural]
		
	rule [hasFunctionPointerType-fp]: hasFunctionPointerType(t(?, pointerType(t(?, functionType(?, ?))))) => true [structural]
	rule [hasFunctionPointerType-qualified]: hasFunctionPointerType(t(?, qualifiedType(T:Type, ?))) => hasFunctionPointerType(T:Type) [structural]
	rule [hasFunctionPointerType-qualified-pointer]: hasFunctionPointerType(t(?, pointerType(t(?, qualifiedType(T:Type, ?))))) => hasFunctionPointerType(t(.Set, pointerType(T:Type))) [structural]
	rule [hasFunctionPointerType-notPointer]: hasFunctionPointerType(t(?, T:SimpleType)) => false
		if getKLabel(T:SimpleType) =/=Bool 'pointerType
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType
		[structural]
	rule [hasFunctionPointerType-notFunction]: hasFunctionPointerType(t(?, pointerType(t(?, T:SimpleType)))) => false
		if getKLabel(T:SimpleType) =/=Bool 'functionType 
		andBool getKLabel(T:SimpleType) =/=Bool 'qualifiedType
		[structural]
		
	// /*@ \source[n1570]{\para{6.2.5}{18}}
	// Integer and floating types are collectively called arithmetic types. Each arithmetic type belongs to one type domain: the real type domain comprises the real types, the complex type domain comprises the complex types. 
	// */
	rule hasArithmeticType(T:Type) => hasIntegerType(T:Type) orBool hasFloatType(T:Type)
		[structural]
		
		
			
	rule unqualifyType(t(?:Set, qualifiedType(T:Type, ?))) => T:Type [structural]
	rule unqualifyType(t(?:Set, T:SimpleType)) => t(.Set, T:SimpleType)
		if getKLabel(T:SimpleType) =/=Bool 'qualifiedType 
		[structural]
endkm
