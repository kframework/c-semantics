// FIXME need to automatically pad structs
kmod COMMON-SEMANTICS-TYPE-INCLUDE is
	including COMMON-INCLUDE 
	
	//op addAggregate : Id List{Type} -> K 
	op addStruct : Id List{Type} -> K 
	op addUnion : Id List{Type} -> K 
	op canonicalizeType : Bag -> K 
	op isAType_ : K -> Bool 
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
	rule qualifiedType(T:Type, Volatile) => T:Type [structural]
	rule qualifiedType(T:Type, Restrict) => T:Type [structural]
	rule qualifiedType(T:Type, Const) => T:Type [structural]
	rule qualifiedType(T:Type, Auto) => T:Type [structural]
	rule qualifiedType(T:Type, Register) => T:Type [structural]
	
	
	rule
		< k > giveType(X:Id, T:Type) => 
			if (Fun:Id ==Bool File-Scope) then giveGlobalType(X:Id, T:Type) else giveLocalType(X:Id, T:Type) fi
			...</ k >
		< currentFunction > Fun:Id </ currentFunction >
		if notBool hasStaticType(T:Type)
		[structural] 
		
	rule
		< k > giveGlobalType(X:Id, T:Type) => .K ...</ k >
		< types > M:Map => M:Map[T:Type / X:Id] </ types >
		< gtypes >... Tu:K |-> Map((M':Map => M':Map[T:Type / X:Id])) ...</ gtypes >
		< currentTranslationUnit > Tu:K </ currentTranslationUnit >
		[structural] 
	rule
		< k > giveLocalType(X:Id, T:Type) => .K ...</ k >
		< types > M:Map => M:Map[T:Type / X:Id] </ types >
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
	
	rule [type-arrow-heat]:
		< type > K:K -> F:Id => K:K ~> HOLE -> F:Id ...</ type >
		if notBool isAType(K:K)
		[structural] 
	rule [type-arrow-cool]:
		< type > T:Type ~> HOLE -> F:Id => T:Type -> F:Id ...</ type >
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
		< type > K:K . X:Id => K:K ~> HOLE . X:Id ...</ type >
		if notBool isAType(K:K)
		[structural] 
	rule [type-dot-cool]:
		< type > T:Type ~> HOLE . X:Id => T:Type . X:Id ...</ type >
		if isAType(T:Type)
		[structural]
		
	rule [type-call-heat]:
		< type > Call(K:K, L:List{C}) => K:K ~> Call(HOLE, L:List{C}) ...</ type >
		if notBool isAType(K:K)
		[structural] 
	rule [type-call-cool]:
		< type > T:Type ~> Call(HOLE, L:List{C}) => Call(T:Type, L:List{C}) ...</ type >
		if isAType(T:Type)
		[structural] 
	// mb context Call(?:K,, (?,, `[HOLE`]:K,, ?)) 
endkm

kmod COMMON-SEMANTICS-TYPE-CANONICALIZATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	
	op canonicalizeType : Bag K Bag Bag Bag -> K [strict(2)] 
		
	rule
		< k > canonicalizeType(B:Bag) => canonicalizeType(B:Bag, .K, .Bag, .Bag, .Bag) ...</ k >
		[structural] 
		
	// specifier, modifier, storage
	rule
		< k > canonicalizeType((B:Bag (BagItem(T:K) => .Bag)), ?, (? (.Bag => BagItem(T:K))), ?, ?) ...</ k >
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
		< k > canonicalizeType(B:Bag (BagItem(T:K) => .Bag), ?, ?, (? .Bag => BagItem(T:K)), ?) ...</ k >
		if (T:K ==Bool SpecTypedef)
		orBool (T:K ==Bool Inline)
		[structural] 

	rule
		< k > canonicalizeType(B:Bag (BagItem(T:K) => .Bag), ?, ?, ?, (? .Bag => BagItem(T:K))) ...</ k >
		if T:K ==Bool Extern
		orBool T:K ==Bool Static
		orBool T:K ==Bool Const
		orBool T:K ==Bool Volatile
		orBool T:K ==Bool Restrict
		orBool T:K ==Bool Auto
		orBool T:K ==Bool Register
		[structural] 
		
	rule
		< k > canonicalizeType(.Bag, (T:Type => qualifiedType(T:Type, Q:K)), .Bag, .Bag, (? BagItem(Q:K) => .Bag)) ...</ k >
		if Q:K ==Bool Extern
		orBool Q:K ==Bool Static
		orBool Q:K ==Bool Const
		orBool Q:K ==Bool Volatile
		orBool Q:K ==Bool Restrict
		orBool Q:K ==Bool Auto
		orBool Q:K ==Bool Register
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(Named(X:Id)))
			=> typedefType(X:Id, T:Type)
		...</ k >
		< types >... typedef(X:Id) |-> T:Type ...</ types >
		if X:Id =/=Bool Identifier("")
		[structural] 
		
	rule
		< k > canonicalizeSpecifier(BagItem(StructRef(X:Id)))
			=> structType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(EnumRef(X:Id)))
			=> enumType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(UnionRef(X:Id)))
			=> unionType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
		
	rule
		< k > canonicalizeSpecifier(BagItem(EnumDef(X:Id, L:List{C})))
			=> EnumDef(X:Id, L:List{C})
			~> enumType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(L:KLabel(((Identifier("") => unnamed(N:Nat)),, L:List{C})))) ...</ k >
		< freshNat > N:Nat => sNat(N:Nat) </ freshNat >
		if L:KLabel ==Bool 'StructDef
		orBool L:KLabel ==Bool 'EnumDef
		orBool L:KLabel ==Bool 'UnionDef
		[structural] 
	
	rule
		< k > canonicalizeSpecifier(BagItem(StructDef(X:Id, L:List{C})))
			=> StructDef(X:Id, L:List{C})
			~> structType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
	rule
		< k > canonicalizeSpecifier(BagItem(UnionDef(X:Id, L:List{C})))
			=> UnionDef(X:Id, L:List{C})
			~> unionType(X:Id)
		...</ k >
		if X:Id =/=Bool Identifier("")
		[structural] 
		
		
	// FIXME what good is this?
	rule BagItem(SpecTypedef) => .Bag [structural]
	// fixme ignoring inlines since they shouldn't change the semantics?
	rule BagItem(Inline) => .Bag [structural]
	// fixme should save these for later use
	rule BagItem(AttributeValue(?, ?)) => .Bag [structural]

	rule 
		< k > canonicalizeType(.Bag, (.K => canonicalizeSpecifier(B:Bag)), (B:Bag => .Bag), ?, ?) ...</ k >
		if B:Bag =/=Bool .Bag
		[structural] 
	// fixme not sure where this is specified, but if i say "static x;" i think it means int
	rule 
		< k > canonicalizeType(.Bag, (.K => canonicalizeSpecifier(BagItem(Int))), .Bag, ?, ?) ...</ k >
		[structural] 
		
	rule
		< k > canonicalizeType(.Bag, T:Type, .Bag, .Bag, .Bag) => T:Type ...</ k >
		[structural] 
		
	op canonicalizeSpecifier : Bag -> K 
	// C99 6.7.2:2
	rule canonicalizeSpecifier(BagItem(Void)) => void [structural]
	rule canonicalizeSpecifier(BagItem(Bool)) => bool [structural]
	rule canonicalizeSpecifier(BagItem(Char)) => char [structural]
	rule canonicalizeSpecifier(BagItem(Signed) BagItem(Char)) => signed-char [structural]
	rule canonicalizeSpecifier(BagItem(Unsigned) BagItem(Char)) => unsigned-char [structural]
	
	rule canonicalizeSpecifier(BagItem(Double)) => double [structural]
	rule canonicalizeSpecifier(BagItem(Float)) => float [structural]
	rule canonicalizeSpecifier(BagItem(Long) BagItem(Double)) => long-double [structural]
	
	rule canonicalizeSpecifier(B:Bag) => short-int
		if B:Bag ==Bool BagItem(Short)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Short)
		orBool B:Bag ==Bool BagItem(Short) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Short) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => unsigned-short-int
		if B:Bag ==Bool BagItem(Unsigned) BagItem(Short)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Short) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => int
		if B:Bag ==Bool BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => unsigned-int
		if B:Bag ==Bool BagItem(Unsigned)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => long-int
		if B:Bag ==Bool BagItem(Long)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => unsigned-long-int
		if B:Bag ==Bool BagItem(Unsigned) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => long-long-int
		if B:Bag ==Bool BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Long) BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bool BagItem(Signed) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
	rule canonicalizeSpecifier(B:Bag) => unsigned-long-long-int
		if B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bool BagItem(Unsigned) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
endkm

kmod COMMON-SEMANTICS-TYPE-INTERPRETATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 

	op structDefType : Id List{Type} -> Type 
	
	op BitFieldType : K K -> K [seqstrict] 
	
	rule
		< k > Specifier(L:List{Type}) => canonicalizeType(Bag(getList{K}(L:List{Type}))) ...</ k >
		[structural] 
	rule
		< k > StructRef(X:Id) => structType(X:Id) ...</ k >
		[structural] 
		
	rule BitFieldType(T:Type, tv(N:Nat, ?)) => bitfieldType(T:Type, N:Nat) [structural]
	
	op makeArrayType : Nat -> KLabel 
	op makeFunctionType : List{Type} -> KLabel 
	op pushTypeDown : Type KLabel -> Type 
	
	rule ArrayType(T:Type, tv(N:Nat, ?)) => pushTypeDown(T:Type, makeArrayType(N:Nat)) [structural]
	rule ArrayType(T:Type, emptyValue) => pushTypeDown(T:Type, 'incompleteArrayType) [structural]
	rule PointerType(T:Type) => pushTypeDown(T:Type, 'pointerType) [structural]
	// fixme I'm assuming functiontype is always below a prototype in the ast
	rule FunctionType(T:Type) => T:Type [structural]
	rule Prototype(T:Type, L:List{Type}, false) => pushTypeDown(T:Type, makeFunctionType(L:List{Type})) [structural]
	rule Prototype(T:Type, L:List{Type}, true) => pushTypeDown(T:Type, makeFunctionType((L:List{Type} :: variadic))) [structural]
	
	rule pushTypeDown(arrayType(T:Type, N:Nat), K:KLabel) => arrayType(pushTypeDown(T:Type, K:KLabel), N:Nat) [structural]
	rule pushTypeDown(incompleteArrayType(T:Type), K:KLabel) => incompleteArrayType(pushTypeDown(T:Type, K:KLabel)) [structural]
	rule pushTypeDown(pointerType(T:Type), K:KLabel) => pointerType(pushTypeDown(T:Type, K:KLabel)) [structural]
	rule pushTypeDown(qualifiedType(T:Type, K:K), K:KLabel) => qualifiedType(pushTypeDown(T:Type, K:KLabel), K:K) [structural]
	rule pushTypeDown(functionType(T:Type, L:List{Type}), K:KLabel) => functionType(pushTypeDown(T:Type, K:KLabel), L:List{Type}) [structural]
	rule pushTypeDown(flexibleArrayType(T:Type), K:KLabel) => flexibleArrayType(pushTypeDown(T:Type, K:KLabel)) [structural]
	rule pushTypeDown(structType(X:Id), K:KLabel) => K:KLabel(structType(X:Id)) [structural]
	rule pushTypeDown(unionType(X:Id), K:KLabel) => K:KLabel(unionType(X:Id)) [structural]
	rule pushTypeDown(enumType(X:Id), K:KLabel) => K:KLabel(enumType(X:Id)) [structural]
	
	rule pushTypeDown(typedefType(X:Id, T:Type), K:KLabel) => K:KLabel(T:Type) [structural]
	
	rule pushTypeDown(T:Type, K:KLabel) => K:KLabel(T:Type) 
		if isBasicType(T:Type)
		[structural]
	
	rule makeArrayType(N:Nat)(T:Type) => arrayType(T:Type, N:Nat) [structural]
	rule makeFunctionType(L:List{Type})(T:Type) => functionType(T:Type, L:List{Type}) [structural]
			
	
	rule 
		< k > JustBase => T:Type ...</ k >
		< declarationTypeHolder > T:Type => . ...</ declarationTypeHolder >
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
	op fillBitHoles : Nat List{Type} -> List{Type} 
	rule fillBitHoles(Nil) => Nil [structural]
	// if we haven't seen bitfields
	rule fillBitHoles((typedDeclaration(T:Type, X:Id) :: L:List{Type})) 
		=> typedDeclaration(T:Type, X:Id) :: fillBitHoles(L:List{Type})
		if notBool hasBitfieldType(T:Type) 
		[structural]
	
	rule fillBitHoles((typedDeclaration(T:Type, X:Id) :: L:List{Type})) 
		=> fillBitHoles(0, typedDeclaration(T:Type, X:Id) :: L:List{Type})
		if hasBitfieldType(T:Type) 
		[structural]
	
	// if we have seen bitfields
	rule fillBitHoles(N:Nat, (typedDeclaration(T:Type, X:Id) :: L:List{Type})) 
		=> typedDeclaration(bitfieldType(unsigned-int, absInt(numBitsPerByte -Int (N:Nat %Nat numBitsPerByte)) %Nat numBitsPerByte), #NoName)
		:: fillBitHoles(typedDeclaration(T:Type, X:Id) :: L:List{Type})
		if notBool hasBitfieldType(T:Type) 
		[structural]
	
	rule fillBitHoles(N:Nat, (typedDeclaration(bitfieldType(T:Type, N':Nat), X:Id) :: L:List{Type})) 
		=> typedDeclaration(bitfieldType(T:Type, N':Nat), X:Id)
		:: fillBitHoles(N:Nat +Nat N':Nat, L:List{Type})
		if N':Nat =/=Bool 0 
		[structural]
		
	rule fillBitHoles(N:Nat, (typedDeclaration(bitfieldType(T:Type, N':Nat), ?) :: L:List{Type})) 
		=> typedDeclaration(bitfieldType(unsigned-int, absInt(numBitsPerByte -Int (N:Nat %Nat numBitsPerByte)) %Nat numBitsPerByte), #NoName)
		:: fillBitHoles(L:List{Type})
		if N':Nat ==Bool 0 
	
	rule fillBitHoles(N:Nat, Nil) => typedDeclaration(bitfieldType(unsigned-int, absInt(numBitsPerByte -Int (N:Nat %Nat numBitsPerByte)) %Nat numBitsPerByte), #NoName) 
		[structural]

	
	rule typedDeclaration(bitfieldType(?, N:Nat), #NoName) :: typedDeclaration(bitfieldType(?, N':Nat), #NoName) 
		=> typedDeclaration(bitfieldType(unsigned-int, N:Nat +Nat N':Nat), #NoName) 
		[structural]
	
	// fixme chould check for some struct contraints here
	op incompleteToFlexibleArrayMember : List{Type} -> List{Type} 
	rule incompleteToFlexibleArrayMember(typedDeclaration(T:Type, X:Id) :: L:List{Type}) 
		=> typedDeclaration(T:Type, X:Id) :: incompleteToFlexibleArrayMember(L:List{Type}) 
		if notBool hasIncompleteType(T:Type) 
		[structural]
	rule incompleteToFlexibleArrayMember(typedDeclaration(incompleteArrayType(T:Type), X:Id)) => typedDeclaration(flexibleArrayType(T:Type), X:Id) [structural]
	rule incompleteToFlexibleArrayMember(Nil) => Nil [structural]
	
	rule
		< k > StructDef(X:Id, L:List{Type})
			=> addStruct(X:Id, fillBitHoles(incompleteToFlexibleArrayMember(L:List{Type})))
			~> giveType(X:Id, structType(X:Id))
		...</ k >
		[structural] 
	rule
		< k > UnionDef(X:Id, L:List{Type})
			=> addUnion(X:Id, L:List{Type})
			~> giveType(X:Id, unionType(X:Id))
		...</ k >
		[structural] 

	// the K will resolve to a type, so throw it away
	rule
		< k > OnlyTypedef(K:K) => K:K ~> discard ...</ k >
		[structural] 
		
			
	rule
		NameAndType(X:Id, T:Type) => typedDeclaration(T:Type, X:Id)
		[structural] 
		
	rule extractActualType(T:Type) => T:Type if isBasicType(T:Type) [structural]
	rule extractActualType(enumType(X:Id)) => enumType(X:Id) [structural]
	rule extractActualType(structType(X:Id)) => structType(X:Id) [structural]
	rule extractActualType(unionType(X:Id)) => unionType(X:Id) [structural]
	rule extractActualType(arrayType(T:Type, N:Nat)) => arrayType(extractActualType(T:Type), N:Nat) [structural]
	rule extractActualType(incompleteArrayType(T:Type)) => incompleteArrayType(extractActualType(T:Type)) [structural]
	rule extractActualType(flexibleArrayType(T:Type)) => flexibleArrayType(extractActualType(T:Type)) [structural]
	rule extractActualType(bitfieldType(T:Type, N:Nat)) => bitfieldType(extractActualType(T:Type), N:Nat)[structural]
	rule extractActualType(functionType(T:Type, List:List{Type})) => functionType(extractActualType(T:Type), List:List{Type}) [structural]
	rule extractActualType(pointerType(T:Type)) => pointerType(extractActualType(T:Type)) [structural]
	rule extractActualType(qualifiedType(T:Type, K:K)) => qualifiedType(extractActualType(T:Type), K:K) [structural]
	rule extractActualType(prototype(T:Type)) => prototype(extractActualType(T:Type)) [structural]
	rule extractActualType(typedefType(?, T:Type)) => extractActualType(T:Type) [structural]
		
	op NameAndType : K K -> K [strict(2)] 
	
	// rule FieldGroup(T:Type, L:List{C}) => fieldGroup-aux(T:Type, L:List{C}, Nil) [structural]
	// rule fieldGroup-aux(T:Type, (C:C :: C':C :: L:List{C}), L':List{C})
		// => fieldGroup-aux(T:Type, C':C :: L:List{C}, (L':List{C} :: singleField(T:Type, C:C))) 
		// [structural]
	// rule fieldGroup-aux(T:Type, Nil, L':List{C})
		// => handleFields(L':List{C})
		// [structural]
		
	// rule handleFields(L:List{Type}) => eraseKLabel('_::_, L:List{Type})
	
	rule
		SingleName(T:Type, Name(X:Id, K:K)) => NameAndType(X:Id, DeclType(T:Type, K:K))
		[structural] 
	rule [Separate-FieldGroups]:
		FieldGroup(K:K, (C:C :: C':C :: L:List{C})) => FieldGroup(K:K, C:C) :: FieldGroup(K:K, (C':C :: L:List{C}))
		[structural]
	rule
		FieldGroup(?:K, Nil) => Nil
		[structural] 
		
	// op shouldFlatten : List{C} -> Type
	// rule C :: shouldFlatten(L':List{C}) => C :: L':List{C} [structural]
	// rule shouldFlatten(L':List{C}) :: C => L':List{C} :: C [structural]
	// fixme WHY CAN'T I WRITE THIS???
	
	// op flattenList : List{C} -> List{C} [strict]
	// op flattenListAux : List{C} -> List{C} [strict]
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
		FieldGroup(T:Type, Name(X:Id, K:K)) => NameAndType(X:Id, DeclType(T:Type, K:K))
		[structural]
	rule
		< k > FieldGroup(structType(unnamed(Anon:Nat)), Name(AnonAggregate, JustBase))
			=> L:List{Type}
		...</ k >
		< structs >...
			unnamed(Anon:Nat) |-> aggregateInfo(L:List{Type}, ?, ?)
		...</ structs >
		[structural]
	rule
		FieldGroup(T:Type, BitFieldName(Name(X:Id, K:K), Size:K))
		=> NameAndType(X:Id, DeclType(T:Type, BitFieldType(K:K, Size:K)))
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
		< type > emptyValue => void ...</ type > 
		[structural] 
		
	rule
		< type > functionObject(?, T:Type, ?) => T:Type ...</ type >
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
	// rule
		// < type > arrayType(T:Type, ?)[T':Type] => T:Type ...</ type >
		// if hasIntegerType(T':Type)
		// [structural] 
	// rule
		// < type > pointerType(T:Type)[T':Type] => T:Type ...</ type >
		// if hasIntegerType(T':Type)
		// [structural] 
	rule 
		< type > arithInterpret(T:Type, ?) => T:Type ...</ type >
	rule
		< type > pointerType(T:Type) + T':Type => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > T':Type + pointerType(T:Type) => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > pointerType(T:Type) - T':Type => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > pointerType(T:Type) - pointerType(T':Type) => cfg:ptrdiffut ...</ type >
		[structural]
	rule
		< type > arrayType(T:Type, ?) + T':Type => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > T':Type + arrayType(T:Type, ?) => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural] 
	rule
		< type > arrayType(T:Type, ?) - T':Type => pointerType(T:Type) ...</ type >
		if hasIntegerType(T':Type)
		[structural]

	// c99 6.4.5
	rule
		< type > Constant(StringLiteral(S:String)) => arrayType(char, lengthString(S:String) +Nat 1) </ type >
		[structural] 
	rule
		< type > K:K => T:Type ...</ type >
		< types >... K:K |-> T:Type ...</ types >
		[structural] 
		
	rule
		< type > Comma(L:List{C} :: K:C) => K:C ...</ type >
		[structural] 

	rule [type-call-func]:
		< type > Call(functionType(T:Type, ?), L:List{C}) => T:Type ...</ type >
		[structural] 
	rule [type-call-func-ptr]:
		< type > Call(pointerType(functionType(T:Type, ?)), ?) => T:Type ...</ type >
		[structural] 
		 		
	rule [type-struct-dot]:
		< type > structType(S:Id) . F:Id => T:Type ...</ type >
		< structs >... 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), ?)
		...</ structs >
		[structural] 
	rule [type-union-dot]:
		< type > unionType(S:Id) . F:Id => T:Type ...</ type >
		< structs >... 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), ?)
		...</ structs >
		[structural] 
		
	rule [type-struct-arrow]:
		< type > pointerType(structType(S:Id)) -> F:Id => T:Type ...</ type >
		< structs >... 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), ?)
		...</ structs >
		[structural] 
	rule [type-union-arrow]:
		< type > pointerType(unionType(S:Id)) -> F:Id => T:Type ...</ type >
		< structs >... 
			S:Id |-> aggregateInfo(?, (? F:Id |-> T:Type), ?)
		...</ structs >
		[structural] 

	// internal numbers, not literals
	rule < type > N:Nat => cfg:largestUnsigned ...</ type > 
		[structural] 

	rule [type-deref-type]:
		< type > *(pointerType(T:Type)) => T:Type ...</ type >
		[structural] 
	rule [type-deref-array-type]:
		< type > *(arrayType(T:Type, ?)) => T:Type ...</ type >
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
	
	// rule 
		// < type > L:KLabel(T:Type,, T':Type) => maxType(T:Type, T':Type) ...</ type >
		// if typeStrictBinaryOperators contains l(L:KLabel)
		// andBool hasIntegerType(T:Type)
		// andBool hasIntegerType(T':Type)
		// [structural] 
	rule 
		< type > L:KLabel(T:Type,, T':Type) => usualArithmeticConversion(T:Type, T':Type) ...</ type >
		if isArithBinConversionOp(L:KLabel)
		andBool (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type))
		[structural] 
		
	rule 
		< type > ?:K ? T:Type : T':Type => usualArithmeticConversion(T:Type, T':Type) ...</ type >
		if (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type))
		[structural]
	rule 
		< type > ?:K ? T:Type : T:Type => T:Type ...</ type >
		if isAType(T:Type)
		andBool notBool hasArrayType(T:Type)
		[structural]
		
	rule < type > ?:K ? (arrayType(T:Type, ?) => pointerType(T:Type)) : ? ...</ type > [structural]
	rule < type > ?:K ? ?:K : (arrayType(T:Type, ?) => pointerType(T:Type)) ...</ type > [structural]
		
	rule // not safe, could be incompatible types
		< type > ?:K ? pointerType(T:Type) : pointerType(T':Type) => pointerType(T:Type) ...</ type >
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
		
	rule 
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
		< type > L:KLabel(?:K,, ?:K) => int ...</ type >
		if L:KLabel ==Bool '_==_
		orBool L:KLabel ==Bool '_!=_
		orBool L:KLabel ==Bool '_&&_
		orBool L:KLabel ==Bool '_||_
		[structural]
		
	rule [type-address]:
		< type > & T:Type => pointerType(T:Type) ...</ type >
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
	
	rule isTypeCompatible(T:Type, T:Type) 
		=> true 
		[structural]
	rule isTypeCompatible(T:Type, T':Type) 
		=> true 
		if hasIntegerType(T:Type)
		andBool hasIntegerType(T':Type) 
		[structural]
	rule isTypeCompatible(pointerType(?), pointerType(?))
		=> true 
		[structural]
	rule isTypeCompatible(pointerType(?), T:Type)
		=> true
		if hasIntegerType(T:Type) 
		[structural]
	rule isTypeCompatible(T:Type, pointerType(?))
		=> true
		if hasIntegerType(T:Type)
		[structural]
		
	rule isTypeCompatible(typedDeclaration(T:Type, ?), typedDeclaration(T':Type, ?))
		=> isTypeCompatible(T:Type, T':Type) 
		[structural]
	rule isTypeCompatible(prototype(T:Type), prototype(T':Type)) 
		=> isTypeCompatible(T:Type, T':Type) 
		[structural]

	rule isTypeCompatible(T:Type, arrayType(T':Type, ?))
		=> isTypeCompatible(T:Type, pointerType(T':Type)) 
		[structural]
	rule isTypeCompatible(arrayType(T:Type, ?), T':Type)
		=> isTypeCompatible(pointerType(T:Type), T':Type) 
		[structural]
	
	rule isTypeCompatible(T:Type, incompleteArrayType(T':Type))
		=> isTypeCompatible(T:Type, pointerType(T':Type)) 
		[structural]
	rule isTypeCompatible(incompleteArrayType(T:Type), T':Type)
		=> isTypeCompatible(pointerType(T:Type), T':Type) 
		[structural]

	rule isTypeCompatible(functionType(T1:Type, typedDeclaration(void, ?)), functionType(T2:Type, Nil))
		=> isTypeCompatible(T1:Type, T2:Type) 
		[structural]
	rule isTypeCompatible(functionType(T1:Type, Nil), functionType(T2:Type, typedDeclaration(void, ?)))
		=> isTypeCompatible(T1:Type, T2:Type) 
		[structural]
	rule isTypeCompatible(functionType(T1:Type, (T':Type :: L:List{Type})), functionType(T2:Type, (T'':Type :: L':List{Type})))
		=> isTypeCompatible(functionType(T1:Type, L:List{Type}), functionType(T2:Type, L':List{Type}))
		andBool isTypeCompatible(T':Type, T'':Type) 
		[structural]
	rule isTypeCompatible(functionType(T1:Type, Nil), functionType(T2:Type, Nil))
		=> isTypeCompatible(T1:Type, T2:Type) 
		[structural]
	rule isTypeCompatible(T:Type, T':Type) => true
		if (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type)) 
		[structural]
	rule 
		< k > Cast(T:Type, K:K, V:Value) => cast(DeclType(T:Type, K:K), V:Value) ...</ k >
		[structural] 
			
	op addGlobalAggregate : Id K -> K 
	op addLocalAggregate : Id K -> K 
	
	op addStruct-aux : Id List{Type} K Map Map List{Type} -> K [strict(3)]
	op addUnion-aux : Id List{Type} Map Map List{Type} -> K
	rule
		< k > addStruct(S:Id, L:List{Type}) 
			=> addStruct-aux(S:Id, L:List{Type}, tv(0, cfg:largestUnsigned), .Map, .Map, L:List{Type})
		...</ k >
		[structural]
	rule
		< k > addStruct-aux(
				S:Id
				, (typedDeclaration(T:Type, Field:Id) :: L:List{Type})
				, V:Value
				, Types:Map
				, Offsets:Map
				, L':List{Type}
			) 
			=> addStruct-aux(S:Id, L:List{Type}, V:Value + bitSizeofType(T:Type), Types:Map[T:Type / Field:Id], Offsets:Map[value(V:Value) / Field:Id], L':List{Type})
		...</ k >
		[structural]
	rule
		< k > addStruct-aux(S:Id, Nil, ?, Types:Map, Offsets:Map, L:List{Type}) 
			=> if (F:Id ==Bool File-Scope) then 
				(addGlobalAggregate(S:Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map))) 
			else
				(addLocalAggregate(S:Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map)))
			fi
		...</ k >
		< currentFunction > F:Id </ currentFunction >
		[structural]		
		
	rule
		< k > addUnion(S:Id, L:List{Type}) 
			=> addUnion-aux(S:Id, L:List{Type}, .Map, .Map, L:List{Type})
		...</ k >
		[structural]
	rule
		< k > addUnion-aux(
				S:Id
				, (typedDeclaration(T:Type, Field:Id) :: L:List{Type})
				, Types:Map
				, Offsets:Map
				, L':List{Type}
			) 
			=> addUnion-aux(S:Id, L:List{Type}, Types:Map[T:Type / Field:Id], Offsets:Map[0 / Field:Id], L':List{Type})
		...</ k >
		[structural]
	rule
		< k > addUnion-aux(S:Id, Nil, Types:Map, Offsets:Map, L:List{Type}) 
			=> if (F:Id ==Bool File-Scope) then 
				(addGlobalAggregate(S:Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map))) 
			else
				(addLocalAggregate(S:Id, aggregateInfo(L:List{Type}, Types:Map, Offsets:Map)))
			fi
		...</ k >
		< currentFunction > F:Id </ currentFunction >
		[structural]
	// fixme looks like i don't actually need global and local, although possibly with vlas in structs?
	// rule
		// < k > addAggregate-aux(X:Id, L:List{Type}) 
			// => if (F:Id ==Bool File-Scope) then 
				// (addGlobalAggregate(X:Id, L:List{Type})) 
			// else
				// (addLocalAggregate(X:Id, L:List{Type}))
			// fi
		// ...</ k >
		// < currentFunction > F:Id </ currentFunction >
		// [structural] 
	rule
		< k > addGlobalAggregate(X:Id, K:K) => . ...</ k >
		< structs > M':Map => M':Map[K:K / X:Id] </ structs >
		< gstructs > M:Map => M:Map[K:K / X:Id] </ gstructs >
		[structural] 
	rule
		< k > addLocalAggregate(X:Id, K:K) => . ...</ k >
		< structs > M:Map => M:Map[K:K / X:Id] </ structs >
		[structural] 
		
	rule isAType T:Type => true
		if setOfTypes contains l(getKLabel(T:Type)) 
		[structural]
	rule isAType T:Type => true if isBasicType(T:Type) [structural]
	rule isAType K:K => false
		if notBool setOfTypes contains l(getKLabel(K:K))
		andBool notBool isBasicType(K:K) [structural]
			

	// FIXME most of these don't take into consideration modifiers

	rule hasFloatType(float) => true [structural]
	rule hasFloatType(double) => true [structural]
	rule hasFloatType(long-double) => true [structural]
	rule hasFloatType(T:Type) => false
		if T:Type =/=Bool float
		andBool T:Type =/=Bool double
		andBool T:Type =/=Bool long-double
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType
		[structural]
	
	rule hasCharType(char) => true [structural]
	rule hasCharType(qualifiedType(T:Type, ?)) => hasCharType(T:Type) [structural]
	rule hasCharType(unsigned-char) => true [structural]
	rule hasCharType(signed-char) => true [structural]
	rule hasCharType(T:Type) => false
		if T:Type =/=Bool char
		andBool T:Type =/=Bool unsigned-char
		andBool T:Type =/=Bool signed-char
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasWCharType(T:Type) => true 
		if T:Type ==Bool cfg:wcharut 
		[structural]
	rule hasWCharType(T:Type) => false
		if T:Type =/=Bool cfg:wcharut
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
	rule hasWCharType(qualifiedType(T:Type, ?)) => hasWCharType(T:Type) [structural]
	
	rule hasPointerType(pointerType(?)) => true [structural]
	rule hasPointerType(qualifiedType(T:Type, ?)) => hasPointerType(T:Type) [structural]
	rule hasPointerType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'pointerType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
	
	rule hasTypedefType(typedefType(?, ?)) => true [structural]
	rule hasTypedefType(qualifiedType(T:Type, ?)) => hasTypedefType(T:Type) [structural]
	rule hasTypedefType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'typedefType 
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
	
	rule hasBoolType(bool) => true [structural]
	rule hasBoolType(qualifiedType(T:Type, ?)) => hasBoolType(T:Type) [structural]
	rule hasBoolType(T:Type) => false
		if T:Type =/=Bool bool 
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
	
	rule hasArrayType(arrayType(?, ?)) => true [structural]
	rule hasArrayType(incompleteArrayType(?)) => true [structural]
	rule hasArrayType(qualifiedType(T:Type, ?)) => hasArrayType(T:Type) [structural]
	rule hasArrayType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'arrayType 
		andBool getKLabel(T:Type) =/=Bool 'incompleteArrayType 
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasAggregateType(T:Type) => hasArrayType(T:Type) orBool hasStructType(T:Type) [structural]
		
	rule hasStructType(structType(?)) => true [structural]
	rule hasStructType(qualifiedType(T:Type, ?)) => hasStructType(T:Type) [structural]
	rule hasStructType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'structType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasUnionType(unionType(?)) => true [structural]
	rule hasUnionType(qualifiedType(T:Type, ?)) => hasUnionType(T:Type) [structural]
	rule hasUnionType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'unionType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]

	rule hasIncompleteType(incompleteArrayType(?)) => true [structural]
	rule hasIncompleteType(qualifiedType(T:Type, ?)) => hasIncompleteType(T:Type) [structural]
	rule hasIncompleteType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'incompleteArrayType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasExternType(qualifiedType(T:Type, K:K)) => if (K:K ==Bool Extern) then (true) else (hasExternType(T:Type)) fi 
		[structural]
	rule hasExternType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasStaticType(qualifiedType(T:Type, K:K)) => if (K:K ==Bool Static) then (true) else (hasStaticType(T:Type)) fi 
		[structural]
	rule hasStaticType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
		
	rule hasBitfieldType(bitfieldType(?, ?)) => true [structural]
	rule hasBitfieldType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'bitfieldType
		[structural]
		
	rule hasFunctionType(functionType(?, ?)) => true [structural]
	rule hasFunctionType(prototype(T:Type)) => hasFunctionType(T:Type) [structural]
	rule hasFunctionType(qualifiedType(T:Type, ?)) => hasFunctionType(T:Type) [structural]
	rule hasFunctionType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'functionType
		andBool getKLabel(T:Type) =/=Bool 'qualifiedType
		andBool getKLabel(T:Type) =/=Bool 'prototype 
		[structural]
		
	rule hasFunctionPointerType(pointerType(functionType(?, ?))) => true [structural]
	rule hasFunctionPointerType(T:Type) => false
		if getKLabel(T:Type) =/=Bool 'pointerType 
		[structural]
	rule hasFunctionPointerType(pointerType(T:Type)) => false
		if getKLabel(T:Type) =/=Bool 'functionType 
		[structural]
		
	/*@ \source[n1570]{\para{6.2.5}{18}}
	Integer and floating types are collectively called arithmetic types. Each arithmetic type belongs to one type domain: the real type domain comprises the real types, the complex type domain comprises the complex types. 
	*/
	rule hasArithmeticType(T:Type) => hasIntegerType(T:Type) orBool hasFloatType(T:Type)
		[structural]
		
		
			
	rule unqualifyType(qualifiedType(T:Type, ?)) => T:Type [structural]
	rule unqualifyType(T:Type) => T:Type
		if getKLabel(T:Type) =/=Bool 'qualifiedType 
		[structural]
endkm
