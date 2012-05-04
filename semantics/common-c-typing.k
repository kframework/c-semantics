module COMMON-SEMANTICS-TYPE-INCLUDE is
	// FIXME need to automatically pad structs
	including COMMON-INCLUDE 
	
	syntax K ::= "MYHOLE" [klabel(MYHOLE)]
	
	syntax K ::= "addStruct" "(" Id "," List{KResult} ")" [klabel(addStruct)]
	syntax K ::= "addUnion" "(" Id "," List{KResult} ")" [klabel(addUnion)]
	syntax K ::= "canonicalizeType" "(" Bag ")" [klabel(canonicalizeType)]
	
	declare extractActualType : Type -> Type // rules that use specifier should be careful to use extractActualType if going to be used in a typed name
	
	syntax K ::= "evalToType" [klabel(evalToType)] 
	
	// declare typeStrictUnaryOperators : -> Set // [memo] 
	// define typeStrictUnaryOperators => Set(
		// l('-_),, l('+_),, l('*_),, l('&_),, l('~_)
	// )
	// [structural]
	
	// declare typeStrictBinaryOperators : -> Set // [memo] 
	// define typeStrictBinaryOperators => Set(
		// l('_*_),, l('_/_),, l('_%_),,
		// l('_+_),, l('_-_),,
		// l('_<_),, l('_>_),, l('_<=_),, l('_>=_),,
		// l('_&_),, l('_|_),, l('_^_),,
		// l('_`[_`])
	// )
	// [structural]
	
	declare typeStrictLeftBinaryOperators : -> Set // [memo] 
	define typeStrictLeftBinaryOperators => Set(
		l('_<<_),, l('_>>_),,
		l('_*=_),, l('_/=_),, l('_%=_),, l('_+=_),, l('_-=_),, 
		l('_<<=_),, l('_>>=_),, l('_&=_),, l('_^=_),, l('_|=_),,
		l('_++),, l('_--),, l('--_),, l('++_)
	) 
	[structural]
end module

module COMMON-SEMANTICS-TYPE-DECLARATIONS is
	including COMMON-SEMANTICS-TYPE-INCLUDE 

	syntax K ::= "giveGlobalType" "(" K "," Type ")" [klabel(giveGlobalType)] 
	syntax K ::= "giveLocalType" "(" K "," Type ")" [klabel(giveLocalType)] 
	
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
		<k> giveType(X:Id, T:KResult) => 
			#if (Fun:Id ==K File-Scope) #then giveGlobalType(X:Id, unqualifyType(T:KResult)) #else giveLocalType(X:Id, unqualifyType(T:KResult)) #fi
			...</k>
		<currentFunction> Fun:Id </currentFunction>
		// when notBool isStaticType(T:KResult)
		[structural]
		
	rule
		<k> giveGlobalType(X:Id, T:KResult) => .K ...</k>
		<types> M:Map => M:Map[T:KResult / X:Id] </types>
		<gtypes>... Tu:K |-> Map((M':Map => M':Map[T:KResult / X:Id])) ...</gtypes>
		<currentTranslationUnit> Tu:K </currentTranslationUnit>
		[structural]
	rule
		<k> giveLocalType(X:Id, T:KResult) => .K ...</k>
		<types> M:Map => M:Map[T:KResult / X:Id] </types>
		[structural]	
end module

module COMMON-SEMANTICS-TYPE-CANONICALIZATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 
	
	syntax K ::= "canonicalizeType-aux" "(" Bag "," K "," Bag "," Bag "," Bag ")" [klabel(canonicalizeType-aux)] 
	context canonicalizeType-aux(_,HOLE,_,_,_) when HOLE =/=K .K 

	rule
		<k> canonicalizeType(B:Bag) => canonicalizeType-aux(B:Bag, .K, .Bag, .Bag, .Bag) ...</k>
		[structural]

	rule
		<k> (.K => DeclType(K1:K, K2:K))
			~> canonicalizeType-aux((_:Bag BagItem(TAtomic(K1:K, K2:K))), _, _, _, _) 
		...</k>
		[structural]
	rule
		<k> (.K => DeclType(K1:K, K2:K))
			~> canonicalizeType-aux((_:Bag BagItem(AlignasType(K1:K, K2:K))), _, _, _, _) 
		...</k>
		[structural]
	rule
		<k> (.K => typeof(K1:K))
			~> canonicalizeType-aux((_:Bag BagItem(AlignasExpression(K1:K))), _, _, _, _) 
		...</k>
		[structural]
		
	syntax K ::= "atomic" "(" Type ")" [klabel(atomic)]
	syntax K ::= "alignas" "(" Type ")" [klabel(alignas)]
	
	rule
		<k> (T:KResult => .K)
			~> canonicalizeType-aux((_:Bag (BagItem(TAtomic(K1:K, K2:K)) => .Bag)), _, (_ (.Bag => BagItem(atomic(T:KResult)))), _, _) 
		...</k>
			when 'isTypeResult(T:KResult)
		[structural]
	rule
		<k> (T:KResult => .K)
			~> canonicalizeType-aux((_:Bag (BagItem(AlignasType(K1:K, K2:K)) => .Bag)), _, (_ (.Bag => BagItem(alignas(T:KResult)))), _, _) 
		...</k>
			when 'isTypeResult(T:KResult)
		[structural]
	rule
		<k> (T:KResult => .K)
			~> canonicalizeType-aux((_:Bag (BagItem(AlignasExpression(K1:K)) => .Bag)), _, (_ (.Bag => BagItem(alignas(T:KResult)))), _, _) 
		...</k>
			when 'isTypeResult(T:KResult)
		[structural]
		
	// specifier, modifier, storage
	rule
		<k> canonicalizeType-aux((_:Bag (BagItem(T:K) => .Bag)), _, (_ (.Bag => BagItem(T:K))), _, _) ...</k>
		when false
		orBool (T:K ==K Void)
		orBool (T:K ==K Bool)
		orBool (T:K ==K Char)
		orBool (T:K ==K Short)
		orBool (T:K ==K Int)
		orBool (T:K ==K Long)
		orBool (T:K ==K Float)
		orBool (T:K ==K Double)
		orBool (T:K ==K Signed)
		orBool (T:K ==K Unsigned)
		orBool (T:K ==K Complex)
		orBool (T:K ==K Imaginary)
		orBool (getKLabel(T:K) ==KLabel 'StructDef)
		orBool (getKLabel(T:K) ==KLabel 'UnionDef)
		orBool (getKLabel(T:K) ==KLabel 'EnumDef)
		orBool (getKLabel(T:K) ==KLabel 'StructRef)
		orBool (getKLabel(T:K) ==KLabel 'UnionRef)
		orBool (getKLabel(T:K) ==KLabel 'EnumRef)
		orBool (getKLabel(T:K) ==KLabel 'Named)
		orBool (getKLabel(T:K) ==KLabel 'Attribute)
		[structural]

	rule
		<k> canonicalizeType-aux(B:Bag (BagItem(T:K) => .Bag), _, _, _, (_ .Bag => BagItem(T:K))) ...</k>
		when T:K ==K Extern
		orBool T:K ==K Static
		orBool T:K ==K Const
		orBool T:K ==K Volatile
		orBool T:K ==K Atomic
		orBool T:K ==K Restrict
		orBool T:K ==K Auto
		orBool T:K ==K Register
		orBool T:K ==K ThreadLocal
		[structural]
		
	rule
		<k> canonicalizeType-aux(.Bag, (T:KResult => t(.Set, qualifiedType(T:KResult, Q:K))), .Bag, .Bag, (_ BagItem(Q:K) => .Bag)) ...</k>
		when Q:K ==K Extern
		orBool Q:K ==K Static
		orBool Q:K ==K Volatile
		orBool Q:K ==K Atomic
		orBool Q:K ==K Restrict
		orBool Q:K ==K Auto
		orBool Q:K ==K Register
		orBool Q:K ==K ThreadLocal
		[structural]
	rule
		<k> canonicalizeType-aux(.Bag, (t((.Set => SetItem(Const)) _, _)), .Bag, .Bag, (_ BagItem(Q:K) => .Bag)) ...</k>
		when Q:K ==K Const
		[structural]
		
	/*@ \fromStandard{\source[n1570]{\para{6.7.3}{9}}}{
	If the specification of an array type includes any type qualifiers, the element type is so-qualified, not the array type. \ldots
	}*/
	rule t(SetItem(Const) S:Set, arrayType(t(S':Set, T:K), N:Nat))
		=> t(S:Set, arrayType(t(SetItem(Const) S':Set, T:K), N:Nat))
		[structural anywhere]
	
	rule
		<k> canonicalizeSpecifier(BagItem(Named(X:Id)))
			=> t(.Set, typedefType(X:Id, T:KResult))
		...</k>
		<types>... typedef(X:Id) |-> T:KResult ...</types>
		when X:Id =/=K Identifier("")
		[structural]
		
	rule
		<k> canonicalizeSpecifier(BagItem(StructRef(X:Id)))
			=> t(.Set, structType(X:Id))
		...</k>
		when X:Id =/=K Identifier("")
		[structural]
	rule
		<k> canonicalizeSpecifier(BagItem(EnumRef(X:Id)))
			=> t(.Set, enumType(X:Id))
		...</k>
		when X:Id =/=K Identifier("")
		[structural]
	rule
		<k> canonicalizeSpecifier(BagItem(UnionRef(X:Id)))
			=> t(.Set, unionType(X:Id))
		...</k>
		when X:Id =/=K Identifier("")
		[structural]
		
	rule
		<k> canonicalizeSpecifier(BagItem(EnumDef(X:Id, L:K)))
			=> EnumDef(X:Id, L:K)
			~> t(.Set, enumType(X:Id))
		...</k>
		when X:Id =/=K Identifier("")
		[structural]
	
	rule
		<k> canonicalizeSpecifier(BagItem(L:KLabel(((Identifier("") => unnamed(N:Nat)),, _)))) ...</k>
		<freshNat> N:Nat => N:Nat +Int 1 </freshNat>
		when L:KLabel ==KLabel 'StructDef
		orBool L:KLabel ==KLabel 'EnumDef
		orBool L:KLabel ==KLabel 'UnionDef
		[structural]
	
	rule
		<k> canonicalizeSpecifier(BagItem(StructDef(X:Id, L:K)))
			=> StructDef(X:Id, L:K)
			~> t(.Set, structType(X:Id))
		...</k>
		when X:Id =/=K Identifier("")
		[structural]
	rule
		<k> canonicalizeSpecifier(BagItem(UnionDef(X:Id, L:K)))
			=> UnionDef(X:Id, L:K)
			~> t(.Set, unionType(X:Id))
		...</k>
		when X:Id =/=K Identifier("")
		[structural]
		

	// FIXME what good is this_
	rule BagItem(SpecTypedef) => .Bag [structural anywhere]
	// fixme ignoring inlines
	rule [ignore-inline]: BagItem(Inline) => .Bag [structural anywhere]
	rule [ignore-noreturn]: BagItem(Noreturn) => .Bag [structural anywhere]
	// fixme should save these for later use
	rule BagItem(Attribute(_:String, _)) => .Bag [structural anywhere]

	rule 
		<k> canonicalizeType-aux(.Bag, (.K => canonicalizeSpecifier(B:Bag)), (B:Bag => .Bag), _, _) ...</k>
		when B:Bag =/=Bag .Bag
		[structural]
		
	rule
		<k> canonicalizeType-aux(.Bag, T:KResult, .Bag, .Bag, .Bag) => T:KResult ...</k>
		[structural]
		
	declare canonicalizeSpecifier : Bag -> K 
	// C99 6.7.2:2
	define canonicalizeSpecifier(BagItem(Void)) => t(.Set, void)
	define canonicalizeSpecifier(BagItem(Bool)) => t(.Set, bool)
	define canonicalizeSpecifier(BagItem(Char)) => t(.Set, char)
	define canonicalizeSpecifier(BagItem(Signed) BagItem(Char)) => t(.Set, signed-char)
	define canonicalizeSpecifier(BagItem(Unsigned) BagItem(Char)) => t(.Set, unsigned-char)
	
	// rule canonicalizeSpecifier(BagItem(atomic(t(S:Set, T:K)))) => t(S:Set SetItem(Atomic), T:K) [structural]
	
	rule BagItem(atomic(_)) => .Bag [structural anywhere]
	rule BagItem(alignas(_)) => .Bag [structural anywhere]
	
	define canonicalizeSpecifier(BagItem(Double)) => t(.Set, double)
	define canonicalizeSpecifier(BagItem(Float)) => t(.Set, float)
	define canonicalizeSpecifier(BagItem(Long) BagItem(Double)) => t(.Set, long-double)
	
	define canonicalizeSpecifier(BagItem(Complex) BagItem(Double)) => t(SetItem(Complex), double)
	define canonicalizeSpecifier(BagItem(Complex) BagItem(Float)) => t(SetItem(Complex), float)
	define canonicalizeSpecifier(BagItem(Complex) BagItem(Long) BagItem(Double)) => t(SetItem(Complex), long-double)
	
	define canonicalizeSpecifier(BagItem(Imaginary) BagItem(Double)) => t(SetItem(Imaginary), double)
	define canonicalizeSpecifier(BagItem(Imaginary) BagItem(Float)) => t(SetItem(Imaginary), float)
	define canonicalizeSpecifier(BagItem(Imaginary) BagItem(Long) BagItem(Double)) => t(SetItem(Imaginary), long-double)
	
	define canonicalizeSpecifier(B:Bag) => t(.Set, short-int)
		when B:Bag ==Bag BagItem(Short)
		orBool B:Bag ==Bag BagItem(Signed) BagItem(Short)
		orBool B:Bag ==Bag BagItem(Short) BagItem(Int)
		orBool B:Bag ==Bag BagItem(Signed) BagItem(Short) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-short-int)
		when B:Bag ==Bag BagItem(Unsigned) BagItem(Short)
		orBool B:Bag ==Bag BagItem(Unsigned) BagItem(Short) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, int)
		when B:Bag ==Bag BagItem(Int)
		orBool B:Bag ==Bag BagItem(Signed)
		orBool B:Bag ==Bag BagItem(Signed) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-int)
		when B:Bag ==Bag BagItem(Unsigned)
		orBool B:Bag ==Bag BagItem(Unsigned) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, long-int)
		when B:Bag ==Bag BagItem(Long)
		orBool B:Bag ==Bag BagItem(Signed) BagItem(Long)
		orBool B:Bag ==Bag BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bag BagItem(Signed) BagItem(Long) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-int)
		when B:Bag ==Bag BagItem(Unsigned) BagItem(Long)
		orBool B:Bag ==Bag BagItem(Unsigned) BagItem(Long) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, long-long-int)
		when B:Bag ==Bag BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bag BagItem(Signed) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bag BagItem(Long) BagItem(Long) BagItem(Int)
		orBool B:Bag ==Bag BagItem(Signed) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
	define canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-long-int)
		when B:Bag ==Bag BagItem(Unsigned) BagItem(Long) BagItem(Long)
		orBool B:Bag ==Bag BagItem(Unsigned) BagItem(Long) BagItem(Long) BagItem(Int) 
		[structural]
end module

module COMMON-SEMANTICS-TYPE-INTERPRETATION is
	including COMMON-SEMANTICS-TYPE-INCLUDE 

	syntax K ::= "BitFieldType" "(" K "," K ")" [strict klabel(BitFieldType)] 
	
	rule
		<k> Specifier(List(L:List{K})) => canonicalizeType(Bag(L:List{K})) ...</k>
		[structural]
		
	rule BitFieldType(T:KResult, tv(N:Nat, _)) => t(.Set, bitfieldType(T:KResult, N:Nat)) [structural anywhere]
	
	declare makeArrayType : Nat -> KLabel 
	declare makeFunctionType : List{KResult} -> KLabel 
	declare pushTypeDown : Type KLabel -> Type 
	declare makePointerType : -> KLabel
	declare makeIncompleteArrayType : -> KLabel
	
	// fixme, throwing away specifier
	rule ArrayType(T:KResult, tv(N:Nat, _), _) 
		=> pushTypeDown(T:KResult, makeArrayType(N:Nat)) 
		when N:Nat >Int 0
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
	
	define [pushdown-array]: pushTypeDown(t(S:Set, arrayType(T:KResult, N:Nat)), K:KLabel) => t(S:Set, arrayType(pushTypeDown(T:KResult, K:KLabel), N:Nat))
	define [pushdown-incomplete]: pushTypeDown(t(S:Set, incompleteArrayType(T:KResult)), K:KLabel) => t(S:Set, incompleteArrayType(pushTypeDown(T:KResult, K:KLabel)))
	define [pushdown-pointer]: pushTypeDown(t(S:Set, pointerType(T:KResult)), K:KLabel) => t(S:Set, pointerType(pushTypeDown(T:KResult, K:KLabel)))
	define [pushdown-qualified]: pushTypeDown(t(S:Set, qualifiedType(T:KResult, K:K)), K:KLabel) => t(S:Set, qualifiedType(pushTypeDown(T:KResult, K:KLabel), K:K))
	define [pushdown-function]: pushTypeDown(t(S:Set, functionType(T:KResult, L:List{KResult})), K:KLabel) => t(S:Set, functionType(pushTypeDown(T:KResult, K:KLabel), L:List{KResult}))
	define [pushdown-struct]: pushTypeDown(t(S:Set, structType(X:Id)), K:KLabel) => K:KLabel(t(S:Set, structType(X:Id)))
	define [pushdown-union]: pushTypeDown(t(S:Set, unionType(X:Id)), K:KLabel) => K:KLabel(t(S:Set, unionType(X:Id)))
	define [pushdown-enum]: pushTypeDown(t(S:Set, enumType(X:Id)), K:KLabel) => K:KLabel(t(S:Set, enumType(X:Id)))
	
	define [pushdown-typedef]: pushTypeDown(t(S:Set, typedefType(X:Id, t(S':Set, T:K))), K:KLabel) => K:KLabel(t(S:Set S':Set, T:K))
	
	define [pushdown-basic]: pushTypeDown(T:KResult, K:KLabel) => K:KLabel(T:KResult) 
		when isBasicType(T:KResult)
		[structural]
	
	define makeArrayType(N:Nat)(T:KResult) => t(.Set, arrayType(T:KResult, N:Nat))
	define makeFunctionType(L:List{KResult})(T:KResult) => t(.Set, functionType(T:KResult, giveNamesToArgs(L:List{KResult})))
	define makePointerType(T:KResult) => t(.Set, pointerType(T:KResult))
	define makeIncompleteArrayType(T:KResult) => t(.Set, incompleteArrayType(T:KResult))
	
	declare giveNamesToArgs : List{KResult} -> List{KResult}
	declare giveNamesToArgs-aux : Nat List{KResult} -> List{KResult}
	
	define giveNamesToArgs(L:List{KResult}) => giveNamesToArgs-aux(0, L:List{KResult})
	define giveNamesToArgs-aux(N:Nat, (typedDeclaration(T:KResult, X:Id),, L:List{KResult}))
		=> typedDeclaration(T:KResult, X:Id),, giveNamesToArgs-aux(N:Nat, L:List{KResult})
		when X:Id =/=K #NoName
		[structural]
	define giveNamesToArgs-aux(N:Nat, (typedDeclaration(T:KResult, X:Id),, L:List{KResult}))
		=> typedDeclaration(T:KResult, #NoName(N:Nat)),, giveNamesToArgs-aux(N:Nat +Int 1, L:List{KResult})
		when X:Id ==K #NoName
		[structural]
	define giveNamesToArgs-aux(_:Nat, t(.Set, variadic))
		=> t(.Set, variadic)
		[structural]
	define giveNamesToArgs-aux(_:Nat, .List{K})
		=> .List{K}
		[structural]
	
	rule 
		<k> JustBase => T:KResult ...</k>
		<declarationTypeHolder> T:KResult => .K ...</declarationTypeHolder>
		[structural]

	syntax K ::= "extractActualTypeFreezer" [klabel(extractActualTypeFreezer)] 
	rule
		<k> DeclType(T:KResult, K:K) => K:K ~> extractActualTypeFreezer ...</k>
		<declarationTypeHolder> (. => T:KResult) ...</declarationTypeHolder>
		[structural]
	
	rule
		<k> T:KResult ~> extractActualTypeFreezer 
			=> extractActualType(T:KResult)
		...</k>
		[structural]
		
	declare fillUnionBitHoles : List{KResult} -> List{KResult} 
	declare fillUnionBitHoles-aux : Nat List{KResult} -> List{KResult} 
	define fillUnionBitHoles(.List{K}) => .List{K}
	define fillUnionBitHoles((K:K,, L:List{K})) => fillUnionBitHoles-aux(0, (K:K,, L:List{K}))
	define fillUnionBitHoles-aux(N:Nat, (typedDeclaration(T:KResult, X:Id),, L:List{KResult})) 
			=> typedDeclaration(T:KResult, X:Id)
			,, fillUnionBitHoles-aux(N:Nat, L:List{KResult})
		when notBool isBitfieldType(T:KResult)
		[structural]
	define fillUnionBitHoles-aux(N:Nat, (typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':Nat)), X:Id),, L:List{KResult})) 
			=> typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':Nat)), X:Id)
			,, fillUnionBitHoles-aux(maxInt(N:Nat, N':Nat), L:List{KResult})
		[structural]
	define fillUnionBitHoles-aux(N:Nat, .List{K}) 
		=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), NEARESTMULT)), #NoName)
		where NEARESTMULT = N:Nat +Int (absInt(numBitsPerByte -Int (N:Nat %Int numBitsPerByte)) %Int numBitsPerByte)
		[structural]
	
	declare fillBitHoles : List{KResult} -> List{KResult} 
	declare fillBitHoles-aux : Nat List{KResult} -> List{KResult} 
	define [fillBitHoles-none]:
		fillBitHoles(.List{K}) => .List{K} 
		[structural]
	// if we haven't seen bitfields
	define [fillBitHoles-not-bitfield]:
		fillBitHoles((typedDeclaration(T:KResult, X:Id),, L:List{KResult})) 
			=> typedDeclaration(T:KResult, X:Id)
			,, fillBitHoles(L:List{KResult})
		when notBool isBitfieldType(T:KResult) 
		[structural]
	
	define [fillBitHoles-bitfield]:
		fillBitHoles((typedDeclaration(T:KResult, X:Id),, L:List{KResult})) 
			=> fillBitHoles-aux(0, (typedDeclaration(T:KResult, X:Id),, L:List{KResult}))
		when isBitfieldType(T:KResult) 
		[structural]
	
	// if we have seen bitfields
	define [fillBitHoles-aux-not-bitfield]:
		fillBitHoles-aux(N:Nat, (typedDeclaration(T:KResult, X:Id),, L:List{KResult})) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), absInt(numBitsPerByte -Int (N:Nat %Int numBitsPerByte)) %Int numBitsPerByte)), #NoName)
			,, fillBitHoles((typedDeclaration(T:KResult, X:Id),, L:List{KResult}))
		when notBool isBitfieldType(T:KResult) 
		[structural]
	
	define [fillBitHoles-aux-bitfield-normal]:
		fillBitHoles-aux(N:Nat, (typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':Nat)), X:Id),, L:List{KResult})) 
			=> typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':Nat)), X:Id)
			,, fillBitHoles-aux(N:Nat +Int N':Nat, L:List{KResult})
		when N':Nat =/=Int 0 
		[structural]
		
	define [fillBitHoles-bitfield-zero]:
		fillBitHoles-aux(N:Nat, (typedDeclaration(t(_, bitfieldType(T:KResult, N':Nat)), _:Id),, L:List{KResult})) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), absInt(numBitsPerByte -Int (N:Nat %Int numBitsPerByte)) %Int numBitsPerByte)), #NoName)
			,, fillBitHoles(L:List{KResult})
		when N':Nat ==Int 0
		[structural]
	
	define [fillBitHoles-done]:
		fillBitHoles-aux(N:Nat, .List{K}) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), absInt(numBitsPerByte -Int (N:Nat %Int numBitsPerByte)) %Int numBitsPerByte)), #NoName) 
		[structural]

	
	rule typedDeclaration(t(_, bitfieldType(_, N:Nat)), #NoName)
		,, typedDeclaration(t(_, bitfieldType(_, N':Nat)), #NoName) 
			=> typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), N:Nat +Int N':Nat)), #NoName) 
		[structural anywhere]
	
	// fixme chould check for some struct contraints here
	declare incompleteToFlexibleArrayMember : List{KResult} -> List{KResult} 
	define incompleteToFlexibleArrayMember((typedDeclaration(T:KResult, X:Id),, L:List{KResult}))
		=> typedDeclaration(T:KResult, X:Id),, incompleteToFlexibleArrayMember(L:List{KResult}) 
		when notBool isIncompleteType(T:KResult) 
		[structural]
	define incompleteToFlexibleArrayMember(typedDeclaration(t(S:Set, incompleteArrayType(T:KResult)), X:Id)) 
		=> typedDeclaration(t(S:Set, flexibleArrayType(T:KResult)), X:Id) 
		[structural]
	define incompleteToFlexibleArrayMember(.List{K}) => .List{K}
	
	rule
		<k> StructDef(X:Id, List(L:List{KResult}))
			=> addStruct(X:Id, fillBitHoles(incompleteToFlexibleArrayMember(L:List{KResult})))
			~> giveType(X:Id, t(.Set, structType(X:Id)))
		...</k>
		[structural]
	rule
		<k> UnionDef(X:Id, List(L:List{KResult}))
			=> addUnion(X:Id, fillUnionBitHoles(L:List{KResult}))
			~> giveType(X:Id, t(.Set, unionType(X:Id)))
		...</k>
		[structural]

	// the K will resolve to a type, so throw it away
	rule
		<k> OnlyTypedef(K:K) => K:K ~> discard ...</k>
		[structural]
		
			
	rule
		NameAndType(X:Id, T:KResult) => typedDeclaration(T:KResult, X:Id)
		[structural anywhere] 
	
	define [extract-basic]: extractActualType(T:KResult) => T:KResult when isBasicType(T:KResult)
	define [extract-enum]: extractActualType(t(S:Set, enumType(X:Id))) => t(S:Set, enumType(X:Id))
	define [extract-struct]: extractActualType(t(S:Set, structType(X:Id))) => t(S:Set, structType(X:Id))
	define [extract-union]: extractActualType(t(S:Set, unionType(X:Id))) => t(S:Set, unionType(X:Id))
	define [extract-array]: extractActualType(t(S:Set, arrayType(T:KResult, N:Nat))) => t(S:Set, arrayType(extractActualType(T:KResult), N:Nat))
	define [extract-incompleteArray]: extractActualType(t(S:Set, incompleteArrayType(T:KResult))) => t(S:Set, incompleteArrayType(extractActualType(T:KResult)))
	define [extract-bitfield]: extractActualType(t(S:Set, bitfieldType(T:KResult, N:Nat))) => t(S:Set, bitfieldType(extractActualType(T:KResult), N:Nat))
	define [extract-function]: extractActualType(t(S:Set, functionType(T:KResult, List:List{KResult}))) => t(S:Set, functionType(extractActualType(T:KResult), List:List{KResult}))
	define [extract-pointer]:  extractActualType(t(S:Set, pointerType(T:KResult))) => t(S:Set, pointerType(extractActualType(T:KResult)))
	define [extract-qualified]: extractActualType(t(S:Set, qualifiedType(T:KResult, K:K))) => t(S:Set, qualifiedType(extractActualType(T:KResult), K:K))
	define [extract-typedef]: extractActualType(t(S:Set, typedefType(_:Id, t(S':Set, T:K)))) => extractActualType(t(S:Set S':Set, T:K))
		
	syntax K ::= "NameAndType" "(" K "," K ")" [strict(2) klabel(NameAndType)] 
		
	rule
		SingleName(T:KResult, Name(X:Id, K:K)) => NameAndType(X:Id, DeclType(T:KResult, K:K))
		[structural anywhere] 
	rule [Separate-FieldGroups]:
		FieldGroup(K:K, List((C:K,, C':K,, L:List{K}))) 
			=> FieldGroup(K:K, List(C:K))
			,, FieldGroup(K:K, List((C':K,, L:List{K})))
		[structural anywhere]

	rule
		FieldGroup(T:KResult, List(Name(X:Id, K:K))) 
			=> NameAndType(X:Id, DeclType(T:KResult, K:K))
		[structural anywhere]
		
	rule
		FieldGroup(T:KResult, List(BitFieldName(Name(X:Id, K:K), Size:K)))
			=> NameAndType(X:Id, DeclType(T:KResult, BitFieldType(K:K, Size:K)))
		[structural anywhere] 
	rule FieldName(K:K) => K:K [structural anywhere]
end module

module COMMON-SEMANTICS-TYPE-MISC is
	including COMMON-SEMANTICS-TYPE-INCLUDE
	
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
		
	define [typeCompatible-declarations]: isTypeCompatible(typedDeclaration(T:KResult, _:Id), typedDeclaration(T':KResult, _:Id))
		=> isTypeCompatible(T:KResult, T':KResult) 
		[structural]
	define [typeCompatible-prototypes]: isTypeCompatible(t(_, prototype(T:KResult)), t(_, prototype(T':KResult))) 
		=> isTypeCompatible(T:KResult, T':KResult) 
		[structural]

	define [typeCompatible-array-right]: isTypeCompatible(T:KResult, t(S:Set, arrayType(T':KResult, _:Nat)))
		=> isTypeCompatible(T:KResult, t(S:Set, pointerType(T':KResult))) 
		[structural]
	define [typeCompatible-array-left]: isTypeCompatible(t(S:Set, arrayType(T:KResult, _:Nat)), T':KResult)
		=> isTypeCompatible(t(S:Set, pointerType(T:KResult)), T':KResult) 
		[structural]
	
	define [typeCompatible-incompleteArray-right]: isTypeCompatible(T:KResult, t(S:Set, incompleteArrayType(T':KResult)))
		=> isTypeCompatible(T:KResult, t(S:Set, pointerType(T':KResult))) 
		[structural]
	define [typeCompatible-incompleteArray-left]: isTypeCompatible(t(S:Set, incompleteArrayType(T:KResult)), T':KResult)
		=> isTypeCompatible(t(S:Set, pointerType(T:KResult)), T':KResult) 
		[structural]

	define [typeCompatible-function-void-left]: isTypeCompatible(t(_, functionType(T1:KResult, typedDeclaration(t(_, void), _:Id))), t(_, functionType(T2:KResult, .List{K})))
		=> isTypeCompatible(T1:KResult, T2:KResult) 
		[structural]
	define [typeCompatible-function-void-right]: isTypeCompatible(t(_, functionType(T1:KResult, .List{K})), t(_, functionType(T2:KResult, typedDeclaration(t(_, void), _:Id))))
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
		when (hasIntegerType(T:KResult) orBool isFloatType(T:KResult))
		andBool (hasIntegerType(T':KResult) orBool isFloatType(T':KResult)) 
		[structural]
			
	syntax K ::= "addGlobalAggregate" "(" Id "," K ")" [klabel(addGlobalAggregate)] 
	syntax K ::= "addLocalAggregate" "(" Id "," K ")" [klabel(addLocalAggregate)] 
	
	syntax K ::= "addStruct-aux" "(" Id "," List{KResult} "," K "," Map "," Map "," List{KResult} ")" [strict(3) klabel(addStruct-aux)]
	syntax K ::= "addUnion-aux" "(" Id "," List{KResult} "," Map "," Map "," List{KResult} ")" [klabel(addUnion-aux)]
	rule
		<k> addStruct(S:Id, L:List{KResult}) 
			=> addStruct-aux(S:Id, L:List{KResult}, tv(0, cfg:largestUnsigned), .Map, .Map, L:List{KResult})
		...</k>
		when L:List{KResult} =/=List{K} .List{K}
		[structural]
	rule
		<k> addStruct-aux(
				S:Id
				, (typedDeclaration(T:KResult, Field:Id),, L:List{KResult})
				, V:KResult
				, Types:Map
				, Offsets:Map
				, L':List{KResult}
			) 
			=> addStruct-aux(S:Id, L:List{KResult}, V:KResult + bitSizeofType(T:KResult), Types:Map[T:KResult / Field:Id], Offsets:Map[value(V:KResult) / Field:Id], L':List{KResult})
		...</k>
		[structural]
	rule
		<k> addStruct-aux(S:Id, .List{K}, _, Types:Map, Offsets:Map, L:List{KResult}) 
			=> #if (F:Id ==K File-Scope) #then 
				(addGlobalAggregate(S:Id, aggregateInfo(L:List{KResult}, Types:Map, Offsets:Map))) 
			#else
				(addLocalAggregate(S:Id, aggregateInfo(L:List{KResult}, Types:Map, Offsets:Map)))
			#fi
		...</k>
		<currentFunction> F:Id </currentFunction>
		[structural]		
		
	rule
		<k> addUnion(S:Id, L:List{KResult}) 
			=> addUnion-aux(S:Id, L:List{KResult}, .Map, .Map, L:List{KResult})
		...</k>
		when L:List{KResult} =/=List{K} .List{K}
		[structural]
	rule
		<k> addUnion-aux(
				S:Id
				, (typedDeclaration(T:KResult, Field:Id),, L:List{KResult})
				, Types:Map
				, Offsets:Map
				, L':List{KResult}
			) 
			=> addUnion-aux(S:Id, L:List{KResult}, Types:Map[T:KResult / Field:Id], Offsets:Map[0 / Field:Id], L':List{KResult})
		...</k>
		[structural]
	rule
		<k> addUnion-aux(S:Id, .List{K}, Types:Map, Offsets:Map, L:List{KResult}) 
			=> #if (F:Id ==K File-Scope) #then 
				(addGlobalAggregate(S:Id, aggregateInfo(L:List{KResult}, Types:Map, Offsets:Map))) 
			#else
				(addLocalAggregate(S:Id, aggregateInfo(L:List{KResult}, Types:Map, Offsets:Map)))
			#fi
		...</k>
		<currentFunction> F:Id </currentFunction>
		[structural]

	rule
		<k> addGlobalAggregate(X:Id, K:K) => . ...</k>
		<structs> M':Map => M':Map[K:K / X:Id] </structs>
		<gstructs> M:Map => M:Map[K:K / X:Id] </gstructs>
		[structural]
	rule
		<k> addLocalAggregate(X:Id, K:K) => . ...</k>
		<structs> M:Map => M:Map[K:K / X:Id] </structs>
		[structural]
		
	define 'isTypeResult(t(_, T:K)) => true
		when setOfTypes contains l(getKLabel(T:K)) 
	define 'isTypeResult(T:KResult) => true when isBasicType(T:KResult)
	define 'isTypeResult(K:K) => false
		when getKLabel(K:K) =/=KLabel 't
	define 'isTypeResult(t(S:Set, T:K)) => false
		when notBool setOfTypes contains l(getKLabel(T:K))
		andBool notBool isBasicType(t(S:Set, T:K)) 
			

	define isFloatType(t(_, float)) => true 
	define isFloatType(t(_, double)) => true 
	define isFloatType(t(_, long-double)) => true 
	define isFloatType(t(_, T:K)) => false
		when T:K =/=K float
		andBool T:K =/=K double
		andBool T:K =/=K long-double
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType
		
	
	define [isCharType-char]: isCharType(t(_, char)) => true 
	define [isCharType-qualified]: isCharType(t(_, qualifiedType(T:KResult, _))) => isCharType(T:KResult) 
	define [isCharType-unsigned-char]: isCharType(t(_, unsigned-char)) => true 
	define [isCharType-signed-char]: isCharType(t(_, signed-char)) => true 
	define [isCharType-other]: isCharType(t(_, T:K)) => false
		when T:K =/=K char
		andBool T:K =/=K unsigned-char
		andBool T:K =/=K signed-char
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType 
		
		
	define [isWCharType-wchar]: isWCharType(t(_, T:K)) => true 
		when T:K ==K simpleType(cfg:wcharut)
		
	define [isWCharType-other]: isWCharType(t(_, T:K)) => false
		when T:K =/=K simpleType(cfg:wcharut)
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType 
		
	define [isWCharType-qualified]: isWCharType(t(_, qualifiedType(T:KResult, _))) => isWCharType(T:KResult) 
	
	define [isPointerType-pointer]: isPointerType(t(_, pointerType(_))) => true 
	define [isPointerType-qualified]: isPointerType(t(_, qualifiedType(T:KResult, _))) => isPointerType(T:KResult) 
	define [isPointerType-other]: isPointerType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'pointerType
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType 
		
	
	define [isBoolType-bool]: isBoolType(t(_, bool)) => true 
	define [isBoolType-qualifiedType]: isBoolType(t(_, qualifiedType(T:KResult, _))) => isBoolType(T:KResult) 
	define [isBoolType-other]: isBoolType(t(_, T:K)) => false
		when T:K =/=K bool 
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType 
		
	
	define [isArrayType-array]: isArrayType(t(_, arrayType(_, _:Nat))) => true 
	define [isArrayType-incompleteArray]: isArrayType(t(_, incompleteArrayType(_))) => true 
	define [isArrayType-flexibleArray]: isArrayType(t(_, flexibleArrayType(_))) => true 
	define [isArrayType-qualified]: isArrayType(t(_, qualifiedType(T:KResult, _))) => isArrayType(T:KResult) 
	define [isArrayType-other]: isArrayType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'arrayType 
		andBool getKLabel(T:K) =/=KLabel 'incompleteArrayType 
		andBool getKLabel(T:K) =/=KLabel 'flexibleArrayType 
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType 
		
		
	define isAggregateType(T:KResult) => isArrayType(T:KResult) orBool isStructType(T:KResult) 
		
	define [isStructType-struct]: isStructType(t(_, structType(_:Id))) => true 
	define [isStructType-qualified]: isStructType(t(_, qualifiedType(T:KResult, _))) => isStructType(T:KResult) 
	define [isStructType-other]: isStructType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'structType
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType 
		
		
	define [isUnionType-union]: isUnionType(t(_, unionType(_:Id))) => true 
	define [isUnionType-qualified]: isUnionType(t(_, qualifiedType(T:KResult, _))) => isUnionType(T:KResult) 
	define [isUnionType-other]: isUnionType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'unionType
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType 
		

	define [isIncompleteType-true]: isIncompleteType(t(_, incompleteArrayType(_))) => true 
	define [isIncompleteType-qualified]: isIncompleteType(t(_, qualifiedType(T:KResult, _))) => isIncompleteType(T:KResult) 
	define [isIncompleteType-false]: isIncompleteType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'incompleteArrayType
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType 
		
		
	define [isExternType-qualified]: isExternType(t(_, qualifiedType(T:KResult, K:K))) => #if (K:K ==K Extern) #then (true) #else (isExternType(T:KResult)) #fi 
		
	define [isExternType-false]: isExternType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'qualifiedType 
		
		
	define [isStaticType-qualified]: 
		isStaticType(t(_, qualifiedType(T:KResult, K:K))) 
			=> #if (K:K ==K Static) #then (true) #else (isStaticType(T:KResult)) #fi
		
	define [isStaticType-false]: isStaticType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'qualifiedType 
		
	
	define [isConstType-qualified]: 
		isConstType(t(_, qualifiedType(T:KResult, K:K))) => isConstType(T:KResult)
		
	define [isConstType-false]: 
		isConstType(t(S:Set, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'qualifiedType 
		andBool notBool Const in S:Set
		
	define [isConstType-true]: 
		isConstType(t(SetItem(Const) _, T:K)) => true
				
	
		
	define [isBitfieldType-true]: isBitfieldType(t(_, bitfieldType(_, _:Nat))) => true 
	define [isBitfieldType-false]: isBitfieldType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'bitfieldType
		
		
	define [isFunctionType-true]: isFunctionType(t(_, functionType(_, _:List{KResult}))) => true 
	define [isFunctionType-prototype]: isFunctionType(t(_, prototype(T:KResult))) => isFunctionType(T:KResult) 
	define [isFunctionType-qualified]: isFunctionType(t(_, qualifiedType(T:KResult, _))) => isFunctionType(T:KResult) 
	define [isFunctionType-false]: isFunctionType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'functionType
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType
		andBool getKLabel(T:K) =/=KLabel 'prototype 
		
		
	define [isFunctionPointerType-fp]: isFunctionPointerType(t(_, pointerType(t(_, functionType(_, _:List{KResult}))))) => true 
	define [isFunctionPointerType-qualified]: isFunctionPointerType(t(_, qualifiedType(T:KResult, _))) => isFunctionPointerType(T:KResult) 
	define [isFunctionPointerType-qualified-pointer]: isFunctionPointerType(t(_, pointerType(t(_, qualifiedType(T:KResult, _))))) => isFunctionPointerType(t(.Set, pointerType(T:KResult))) 
	define [isFunctionPointerType-notPointer]: isFunctionPointerType(t(_, T:K)) => false
		when getKLabel(T:K) =/=KLabel 'pointerType
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType
		
	define [isFunctionPointerType-notFunction]: isFunctionPointerType(t(_, pointerType(t(_, T:K)))) => false
		when getKLabel(T:K) =/=KLabel 'functionType 
		andBool getKLabel(T:K) =/=KLabel 'qualifiedType
		
		
	// /*@ \source[n1570]{\para{6.2.5}{18}}
	// Integer and floating types are collectively called arithmetic types. Each arithmetic type belongs to one type domain: the real type domain comprises the real types, the complex type domain comprises the complex types. 
	// */
	define isArithmeticType(T:KResult) => hasIntegerType(T:KResult) orBool isFloatType(T:KResult)

	define unqualifyType(t(_:Set, qualifiedType(T:KResult, _))) => T:KResult 
	define unqualifyType(t(_:Set, T:K)) => t(.Set, T:K)
		when getKLabel(T:K) =/=KLabel 'qualifiedType 
		
		
	define removeStorageSpecifiers(t(_:Set, qualifiedType(T:KResult, _))) => T:KResult 
	define removeStorageSpecifiers(t(S:Set, T:K)) => t(S:Set, T:K)
		when getKLabel(T:K) =/=KLabel 'qualifiedType
		
	
	define getModifiers(t(S:Set, _)) => S:Set
end module


module COMMON-C-TYPING is
	including COMMON-SEMANTICS-TYPE-INCLUDE
	
	including COMMON-SEMANTICS-TYPE-DECLARATIONS 
	including COMMON-SEMANTICS-TYPE-CANONICALIZATION 
	including COMMON-SEMANTICS-TYPE-INTERPRETATION
	including COMMON-SEMANTICS-TYPE-MISC
end module
