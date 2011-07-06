kmod DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE is
	including DYNAMIC-INCLUDE 
endkm

kmod DYNAMIC-SEMANTICS-PROMOTIONS is
	including DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE 
	
	// "integer promotions" are used when doing arithmetic conversions, and for unary ~, +, -
	// "usual arithmetic conversions" are used when doing binary arithmetic on numbers, and are used to find a common type
	// there is another set of promotions called "default argument promotions" used when calling functions where the type information is not complete.  This is equivalent to integer promotions + (float => double) 
	
	
	op usualArithmeticConversion-aux : K K -> K
	
	rule usualArithmeticConversion(T:Type, T':Type)
			=> usualArithmeticConversion-aux(promote(T:Type), promote(T':Type))
		[structural]
		

	// op arithConversion-int : KLabel K K -> K
	op isArithBinOp : KLabel -> Bool 

	op arithBinOps : -> Set [memo] 
	op arithBinConversionOps : -> Set [memo] 

	rule [arithBinOps]:
		arithBinOps => arithBinConversionOps Set(l('_<<_),, l('_>>_)) [structural]
	rule [arithBinConversionOps]:
		arithBinConversionOps => Set(
		l('_*_),, l('_/_),, l('_%_),,
		l('_+_),, l('_-_),,
		l('_<_),, l('_>_),, l('_<=_),, l('_>=_),,
		l('_==_),, l('_!=_),,
		l('_&_),, l('_|_),, l('_^_)
	) [structural]
	
	rule [checkArithBinOp]:
		isArithBinOp(KL:KLabel) => if arithBinOps contains l(KL:KLabel) then true else false fi 
		[structural]
	rule [checkArithBinConversionOp]:
		isArithBinConversionOp(KL:KLabel) => if arithBinConversionOps contains l(KL:KLabel) then true else false fi [structural]

	op arithUnaryOps : -> Set [memo] 
	rule [arithUnaryOps]: arithUnaryOps => Set(l('-_),, l('+_),, l('~_)) [structural]

	rule [checkArithUnaryOp]: 
		isArithUnaryOp(KL:KLabel) => if arithUnaryOps contains l(KL:KLabel) then true else false fi [structural]
	
	rule [hasBeenPromoted-true]:
		hasBeenPromoted(T:Type) => true
		if rank(T:Type) >=Int rank(int)
		andBool notBool hasBitfieldType(T:Type) 
		[structural]
	rule [hasBeenPromoted-false]:
		hasBeenPromoted(T:Type) => false
		if rank(T:Type) <Int rank(int)
		orBool hasBitfieldType(T:Type)
		[structural]
	rule isPromotedInteger(T:Type) => hasIntegerType(T:Type) andBool hasBeenPromoted(T:Type) [structural]
	
	rule
		< k > L:KLabel((tv(V:BaseValue, T:Type) => cast(promote(T:Type), tv(V:BaseValue, T:Type)))) ...</ k > 
		if isArithUnaryOp(L:KLabel)
		andBool notBool hasBeenPromoted(T:Type)
		andBool hasIntegerType(T:Type)
		[structural]
	rule
		< k > L:KLabel((tv(V:BaseValue, T:Type) => cast(promote(T:Type), tv(V:BaseValue, T:Type))),, ?) ...</ k > 
		if isArithBinOp(L:KLabel)
		andBool notBool hasBeenPromoted(T:Type)
		andBool hasIntegerType(T:Type)
		[structural] 
	rule
		< k > L:KLabel(?,, (tv(V:BaseValue, T:Type) => cast(promote(T:Type), tv(V:BaseValue, T:Type)))) ...</ k > 
		if isArithBinOp(L:KLabel)
		andBool notBool hasBeenPromoted(T:Type)
		andBool hasIntegerType(T:Type)
		[structural] 
	// rule
		// arithConversion-int(?, tv(?, (enumType(?) => int)), ?)
		// [structural] 
	// rule
		// arithConversion-int(?, ?, tv(?, (enumType(?) => int)))
		// [structural] 
	rule
		< k > L:KLabel(tv(V:BaseValue, T:Type),, tv(V':BaseValue, T':Type))
			=> L:KLabel(cast(finalType, tv(V:BaseValue, T:Type)),, cast(finalType, tv(V':BaseValue, T':Type)))
		...</ k >
		if isArithBinConversionOp(L:KLabel)
		andBool (hasIntegerType(T:Type) orBool hasFloatType(T:Type))
		andBool (hasIntegerType(T':Type) orBool hasFloatType(T':Type))
		andBool (
			T:Type =/=Bool T':Type
			orBool notBool hasBeenPromoted(T:Type) 
			orBool notBool hasBeenPromoted(T':Type)
		)
		where finalType = usualArithmeticConversion(T:Type, T':Type)
		[structural] 
		

	// fixme these could be done more cleanly

	//C99 6.3.1.8
	// First, if the corresponding real type of either operand is long double, the other operand is converted, without change of type domain, to a type whose corresponding real type is long double
	rule usualArithmeticConversion-aux(long-double, ?) => long-double [structural]
	rule usualArithmeticConversion-aux(?, long-double) => long-double [structural] 
		
	// Otherwise, if the corresponding real type of either operand is double, the other operand is converted, without change of type domain, to a type whose corresponding real type is double
	rule
		usualArithmeticConversion-aux(double, T:Type) => double
		if long-double =/=Bool T:Type
		[structural] 
	rule
		usualArithmeticConversion-aux(T:Type, double) => double
		if long-double =/=Bool T:Type
		[structural] 
		
	// // Otherwise, if the corresponding real type of either operand is float, the other operand is converted, without change of type domain, to a type whose corresponding real type is float. 53) For example, addition of a double _Complex and a float entails just the conversion of the float operand to double (and yields a double _Complex result)
	rule
		usualArithmeticConversion-aux(float, T:Type) => float
		if long-double =/=Bool T:Type
		andBool double =/=Bool T:Type
		[structural] 
	rule
		usualArithmeticConversion-aux(T:Type, float) => float
		if long-double =/=Bool T:Type
		andBool double =/=Bool T:Type
		[structural] 

	
	// Otherwise, the integer promotions are performed on both operands ..
	
	//C99 6.3.1.1:2 For objects or expressions with an integer type  whose integer conversion rank is less than or equal to the rank of int and unsigned int, and a bit field of type _Bool, int, signed int, or unsigned int, If an int can represent all values of the original type, the value is converted to an int; otherwise, it is converted to an unsigned int.  These are called the integer promotions.  All other types are unchanged by the integer promotions
	//C99 6.3.1.1:3 The integer promotions preserve value including sign. As discussed earlier, whether a "plain" char is treated as signed is implementation-defined

	rule [argPromote-float]: argPromote(float) => double [structural]
	rule [argPromote-double]: argPromote(double) => double [structural]
	rule [argPromote-long-double]: argPromote(long-double) => long-double [structural]
	rule [argPromote-integer]: argPromote(T:Type) => promote(T:Type)
		if hasIntegerType(T:Type)
		[structural]
	
	rule promote(T:Type) => T:Type
		if hasFloatType(T:Type)
		[structural]
	
	rule
		promote(T:Type) => int
		if hasIntegerType(T:Type)
		andBool rank(T:Type) <=Int rank(int)
		andBool min(int) <=Int min(T:Type) 
		andBool max(int) >=Int max(T:Type)		
		[structural]

	rule
		promote(T:Type) => T:Type
		if hasIntegerType(T:Type)
		andBool rank(T:Type) >Int rank(int)
		andBool notBool hasBitfieldType(T:Type)
		[structural]

	rule
		promote(bitfieldType(T:Type, Len:Nat)) => int
		if (T:Type ==Bool bool orBool T:Type ==Bool int orBool T:Type ==Bool unsigned-int)
		andBool min(int) <=Int min(bitfieldType(T:Type, Len:Nat))
		andBool max(int) >=Int max(bitfieldType(T:Type, Len:Nat))
		[structural] 
	// fixme unclear what 6.3.1.1:3 means

	rule
		promote(T:Type) => unsigned-int
		if hasIntegerType(T:Type)
		andBool rank(T:Type) <=Int rank(int)
		andBool notBool (
			min(int) <=Int min(T:Type) 
			andBool max(int) >=Int max(T:Type)		
		)
		[structural]

	rule
		promote(bitfieldType(T:Type, Len:Nat)) => unsigned-int
		if (T:Type ==Bool bool orBool T:Type ==Bool int orBool T:Type ==Bool unsigned-int)
		andBool notBool (
			min(int) <=Int min(bitfieldType(T:Type, Len:Nat))
			andBool max(int) >=Int max(bitfieldType(T:Type, Len:Nat))	
		)
		[structural]		
	
	// this only happens for argument promotions
	// rule
		// promote(tv(F:Float, float)) => tv(F:Float, double)
		// [structural]
	
	// Then the following rules are applied to the promoted operands:
	
	// If both operands have the same type, then no further conversion is needed
	rule [arithConversion-int-done]: usualArithmeticConversion-aux(T:Type, T:Type) => T:Type [structural]
		
	rule [maxType-left]:
		maxType(T:Type, T':Type) => T:Type
		if rank(T:Type) >=Int rank(T':Type) 
		[structural]
	rule [maxType-right]:
		maxType(T:Type, T':Type) => T':Type
		if rank(T':Type) >=Int rank(T:Type) 
		[structural]

	op hasSameSignedness : Type Type -> Bool [memo]
	rule hasSameSignedness(T:Type, T':Type)
		=> (hasSignedIntegerType(T:Type) andBool hasSignedIntegerType(T':Type))
			orBool (hasUnsignedIntegerType(T:Type) andBool hasUnsignedIntegerType(T':Type))
		[structural]
		
	// Otherwise, if both operands have signed integer types or both have unsigned integer types, the operand with the type of lesser integer conversion rank is converted to the type of the operand with greater rank
	rule
		usualArithmeticConversion-aux(T:Type, T':Type) => maxType(T:Type, T':Type)
		if T:Type =/=Bool T':Type
		andBool hasSameSignedness(T:Type, T':Type)
		[structural]
	
		
	// Otherwise, if the operand that has unsigned integer type has rank greater or equal to the rank of the type of the other operand, then the operand with signed integer type is converted to the type of the operand with unsigned integer type
	rule
		usualArithmeticConversion-aux(T:Type, T':Type) => T':Type
		if T:Type =/=Bool T':Type
		andBool hasSignedIntegerType(T:Type) 
		andBool hasUnsignedIntegerType(T':Type) 
		andBool rank(T':Type) >=Int rank(T:Type)
		[structural] 
	rule
		usualArithmeticConversion-aux(T:Type, T':Type) => T:Type
		if T:Type =/=Bool T':Type
		andBool hasUnsignedIntegerType(T:Type) 
		andBool hasSignedIntegerType(T':Type) 
		andBool rank(T:Type) >=Int rank(T':Type)
		[structural] 
		
	// Otherwise, if the type of the operand with signed integer type can represent all of the values of the type of the operand with unsigned integer type, then the operand with unsigned integer type is converted to the type of the operand with signed integer type
	rule
		usualArithmeticConversion-aux(T:Type, T':Type) => T:Type
		if T:Type =/=Bool T':Type
		andBool hasSignedIntegerType(T:Type) 
		andBool hasUnsignedIntegerType(T':Type) 
		andBool rank(T':Type) <Int rank(T:Type)
		andBool min(T:Type) <=Int min(T':Type)
		andBool max(T:Type) >=Int max(T':Type)
		[structural] 
	rule
		usualArithmeticConversion-aux(T:Type, T':Type) => T':Type
		if T:Type =/=Bool T':Type
		andBool hasUnsignedIntegerType(T:Type) 
		andBool hasSignedIntegerType(T':Type) 
		andBool rank(T:Type) <Int rank(T':Type)
		andBool min(T':Type) <=Int min(T:Type)
		andBool max(T':Type) >=Int max(T:Type)
		[structural] 
		
	// Otherwise, both operands are converted to the unsigned integer type corresponding to the type of the operand with signed integer type
	rule
		usualArithmeticConversion-aux(T:Type, T':Type) => correspondingUnsignedType(T:Type)
		if T:Type =/=Bool T':Type
		andBool hasSignedIntegerType(T:Type) 
		andBool hasUnsignedIntegerType(T':Type) 
		andBool rank(T':Type) <Int rank(T:Type)
		andBool (min(T:Type) >Int min(T':Type) orBool max(T:Type) <Int max(T':Type))
		[structural] 
	rule
		usualArithmeticConversion-aux(T:Type, T':Type) => correspondingUnsignedType(T':Type)
		if T:Type =/=Bool T':Type
		andBool hasUnsignedIntegerType(T:Type) 
		andBool hasSignedIntegerType(T':Type) 
		andBool rank(T:Type) <Int rank(T':Type)
		andBool (min(T':Type) >Int min(T:Type) orBool max(T':Type) <Int max(T:Type))
		[structural] 
		
		
	op correspondingUnsignedType : Type -> Type 
	
	rule [correspondingUnsigned-int]: correspondingUnsignedType(int) => unsigned-int [structural]
	rule [correspondingUnsigned-long-int]: correspondingUnsignedType(long-int) => unsigned-long-int [structural]
	rule [correspondingUnsigned-long-long-int]: correspondingUnsignedType(long-long-int) => unsigned-long-long-int [structural]
	
endkm

kmod DYNAMIC-SEMANTICS-CAST is 
	including DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE 
	
	// op qualify : K -> K
	// rule qualify(T:Type, K:K) => qualifiedType(T:Type, K:K) [structural]
	
	//- switch assumes casts can happen anywhere
	rule 
		cast(void, ?) => skipval
		[structural] 
		
	rule
		cast(T:Type, tv(L:List{K}, T:Type)) => tv(L:List{K}, T:Type)
		[structural] 
	
	//c99 6.3.1.2:1 to _Bool
	// fixme worried about qualifiers
	rule [cast-integer-to-bool]:
		cast(bool, tv(I:Int, T:Type))
			=> if I:Int ==Bool 0 then tv(0, bool) else tv(1, bool) fi
		if hasIntegerType(T:Type)
		[structural]
	rule [cast-non-integer-to-bool]:
		cast(bool, tv(L:List{K}, T:Type)) 
			=> cast(bool, tv(0, int) != tv(L:List{K}, T:Type))
		if notBool hasIntegerType(T:Type)
		[structural] 
	
	//c99 6.3.1.3:1 When a value with integer type is converted to another integer type other than _Bool, if the value can be represented by the new type, it is unchanged. 
	rule [cast-integer-no-value-change]:
		cast(T:Type, tv(I:Int, T':Type)) => tv(I:Int, T:Type)
		if min(T:Type) <=Int I:Int andBool max(T:Type) >=Int I:Int 
		andBool hasIntegerType(T':Type)
		andBool hasIntegerType(T:Type)
		andBool notBool hasBoolType (T:Type)
		[structural] 
		
	//c99 6.3.1.3:2 Otherwise, if the new type is unsigned, the value is converted by repeatedly adding or subtracting one more than the maximum value that can be represented in the new type until the value is in the range of the new type

	rule [cast-ubitfield-of-small]:
		cast(bitfieldType(T:Type, Len:Nat), tv(I:Int, T':Type)) 
			=> cast(bitfieldType(T:Type, Len:Nat), tv(I:Int +Int max(bitfieldType(T:Type, Len:Nat)) +Int 1, T':Type))
		if I:Int <Int min(bitfieldType(T:Type, Len:Nat))
		andBool hasIntegerType(T':Type)
		andBool hasUnsignedIntegerType(T:Type)
		[structural]
	rule [cast-uchar-of-small]:
		cast(unsigned-char, tv(I:Int, T':Type)) 
			=> cast(unsigned-char, tv(I:Int +Int max(unsigned-char) +Int 1, T':Type))
		if I:Int <Int min(unsigned-char)
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-usint-of-small]:
		cast(unsigned-short-int, tv(I:Int, T':Type)) 
			=> cast(unsigned-short-int, tv(I:Int +Int max(unsigned-short-int) +Int 1, T':Type))
		if I:Int <Int min(unsigned-short-int)
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-uint-of-small]:
		cast(unsigned-int, tv(I:Int, T':Type)) 
			=> cast(unsigned-int, tv(I:Int +Int max(unsigned-int) +Int 1, T':Type))
		if I:Int <Int min(unsigned-int)
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-ulong-of-small]:
		cast(unsigned-long-int, tv(I:Int, T':Type)) 
			=> cast(unsigned-long-int, tv(I:Int +Int max(unsigned-long-int) +Int 1, T':Type))
		if I:Int <Int min(unsigned-long-int)
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-ullong-of-small]:
		cast(unsigned-long-long-int, tv(I:Int, T':Type)) 
			=> cast(unsigned-long-long-int, tv(I:Int +Int max(unsigned-long-long-int) +Int 1, T':Type))
		if I:Int <Int min(unsigned-long-long-int)
		andBool hasIntegerType(T':Type)
		[structural]
		
	

	rule [cast-ubitfield-of-big]:
		cast(bitfieldType(T:Type, Len:Nat), tv(I:Int, T':Type)) 
			=> tv(I:Int %Int (max(bitfieldType(T:Type, Len:Nat)) +Int 1), bitfieldType(T:Type, Len:Nat))
		if I:Int >Int max(bitfieldType(T:Type, Len:Nat))
		andBool hasIntegerType(T':Type)
		andBool hasUnsignedIntegerType(T:Type)
		[structural]
	rule [cast-uchar-of-big]:
		cast(unsigned-char, tv(I:Int, T':Type)) 
			=> tv(I:Int %Int (max(unsigned-char) +Int 1), unsigned-char)
		if I:Int >Int max(unsigned-char)
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-usint-of-big]:
		cast(unsigned-short-int, tv(I:Int, T':Type)) 
			=> tv(I:Int %Int (max(unsigned-short-int) +Int 1), unsigned-short-int)
		if I:Int >Int max(unsigned-short-int)
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-uint-of-big]:
		cast(unsigned-int, tv(I:Int, T':Type)) 
			=> tv(I:Int %Int (max(unsigned-int) +Int 1), unsigned-int)
		if I:Int >Int max(unsigned-int)
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-ulong-of-big]:
		cast(unsigned-long-int, tv(I:Int, T':Type)) 
			=> tv(I:Int %Int (max(unsigned-long-int) +Int 1), unsigned-long-int)
		if I:Int >Int max(unsigned-long-int)
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-ullong-of-big]:
		cast(unsigned-long-long-int, tv(I:Int, T':Type)) 
			=> tv(I:Int %Int (max(unsigned-long-long-int) +Int 1), unsigned-long-long-int)
		if I:Int >Int max(unsigned-long-long-int)
		andBool hasIntegerType(T':Type)
		[structural]

	
	//c99 6.3.1.3:3 Otherwise, the new type is signed and the value cannot be represented in it; either the result is implementation-defined or an implementation-defined signal is raised
	// choice
	rule [cast-sbitfield-of-huge]:
		cast(bitfieldType(T:Type, Len:Nat), tv(I:Int, T':Type)) 
			=> cast(bitfieldType(T:Type, Len:Nat), tv(I:Int %Int (2 ^Nat absInt(numBits(bitfieldType(T:Type, Len:Nat)))), T':Type)) 
		if absInt(I:Int) >Int (2 ^Nat absInt(numBits(bitfieldType(T:Type, Len:Nat))))
		andBool hasIntegerType(T':Type)
		andBool hasSignedIntegerType(T:Type)
		[structural]
	rule [cast-schar-of-huge]:
		cast(signed-char, tv(I:Int, T':Type)) 
			=> cast(signed-char, tv(I:Int %Int (2 ^Nat absInt(numBits(signed-char))), T':Type)) 
		if absInt(I:Int) >Int (2 ^Nat absInt(numBits(signed-char)))
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-sint-of-huge]:
		cast(short-int, tv(I:Int, T':Type)) 
			=> cast(short-int, tv(I:Int %Int (2 ^Nat absInt(numBits(short-int))), T':Type)) 
		if absInt(I:Int) >Int (2 ^Nat absInt(numBits(short-int)))
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-int-of-huge]:
		cast(int, tv(I:Int, T':Type)) 
			=> cast(int, tv(I:Int %Int (2 ^Nat absInt(numBits(int))), T':Type)) 
		if absInt(I:Int) >Int (2 ^Nat absInt(numBits(int)))
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-long-of-huge]:
		cast(long-int, tv(I:Int, T':Type)) 
			=> cast(long-int, tv(I:Int %Int (2 ^Nat absInt(numBits(long-int))), T':Type)) 
		if absInt(I:Int) >Int (2 ^Nat absInt(numBits(long-int)))
		andBool hasIntegerType(T':Type)
		[structural]
	rule [cast-llong-of-huge]:
		cast(long-long-int, tv(I:Int, T':Type))
			=> cast(long-long-int, tv(I:Int %Int (2 ^Nat absInt(numBits(long-long-int))), T':Type)) 
		if absInt(I:Int) >Int (2 ^Nat absInt(numBits(long-long-int)))
		andBool hasIntegerType(T':Type)
		[structural]
		
		
		
	rule [cast-signed-of-small]:
		cast(T:Type, tv(I:Int, T':Type))
			=> tv(I:Int +Int (2 ^Nat absInt(numBits(T:Type))), T:Type)
		if I:Int <Int min(T:Type)
		andBool absInt(I:Int) <=Int (2 ^Nat absInt(numBits(T:Type)))
		andBool hasSignedIntegerType(T:Type)
		andBool hasIntegerType(T':Type)
		andBool notBool hasBoolType (T:Type)
		[structural] 
	rule [cast-signed-of-big]:
		cast(T:Type, tv(I:Int, T':Type)) 
			=> tv(_-Int_(I:Int, (2 ^Nat absInt(numBits(T:Type)))), T:Type)
		if I:Int >Int max(T:Type)
		andBool absInt(I:Int) <=Int (2 ^Nat absInt(numBits(T:Type)))
		andBool hasSignedIntegerType(T:Type)
		andBool hasIntegerType(T':Type)
		andBool notBool hasBoolType (T:Type)
		[structural] 

	// this is starting to get into sketchy land
	rule [cast-unknown-char]:
		cast(T:Type, tv(piece(unknown(Len:Nat), Len:Nat), T':Type)) 
			=> tv(piece(unknown(K2Nat(bitSizeofType(T:Type))), K2Nat(bitSizeofType(T:Type))), T:Type)
		if hasIntegerType(T:Type)
		andBool hasIntegerType(T':Type)
		// andBool Len:Nat ==Bool numBitsPerByte
		[structural]	
	
	//C99 6.3.1.4:1 When a finite value of real floating type is converted to an integer type other than _Bool, the fractional part is discarded (i.e., the value is truncated toward zero). If the value of the integral part cannot be represented by the integer type, the behavior is undefined.52) The remaindering operation performed when a value of integer type is converted to unsigned type need not be performed when a value of real floating type is converted to unsigned type. Thus, the range of portable real floating values is (-1, Utype_MAX+1)
	// fixme
	rule
		cast(T:Type, tv(V:Float, double)) => cast(T:Type, tv(truncRat(Float2Rat(V:Float)), long-long-int))
		if hasIntegerType(T:Type)
		andBool notBool hasBoolType (T:Type)
		[structural] 
	rule
		cast(T:Type, tv(V:Float, float)) => cast(T:Type, tv(truncRat(Float2Rat(V:Float)), long-long-int))
		if hasIntegerType(T:Type)
		andBool notBool hasBoolType (T:Type)
		[structural] 
	rule
		cast(T:Type, tv(V:Float, long-double)) => cast(T:Type, tv(truncRat(Float2Rat(V:Float)), long-long-int))
		if hasIntegerType(T:Type)
		andBool notBool hasBoolType (T:Type)
		[structural] 
	
	//C99 6.3.1.4:2 When a value of integer type is converted to a real floating type, if the value being converted can be represented exactly in the new type, it is unchanged. If the value being converted is in the range of values that can be represented but cannot be represented exactly, the result is either the nearest higher or nearest lower representable value, chosen in an implementation-defined manner. If the value being converted is outside the range of values that can be represented, the behavior is undefined

	// rule [cast-int-to-floating]:
		// cast(T':Type, tv(I:Int, T:Type)) => tv(Rat2Float(I:Int), T':Type)
		// if hasIntegerType(T:Type)
		// andBool (T':Type ==Bool float orBool T':Type ==Bool double orBool T':Type ==Bool long-double)
		// [structural]
	rule [cast-int-to-float]:
		cast(float, tv(I:Int, T:Type)) => tv(Rat2Float(I:Int), float)
		if hasIntegerType(T:Type)
		[structural] 
	rule [cast-int-to-double]:
		cast(double, tv(I:Int, T:Type)) => tv(Rat2Float(I:Int), double)
		if hasIntegerType(T:Type)
		[structural] 
	rule [cast-int-to-long-double]:
		cast(long-double, tv(I:Int, T:Type)) => tv(Rat2Float(I:Int), long-double)
		if hasIntegerType(T:Type)
		[structural] 
	
	// fixme all floats same precision
	rule
		cast(T':Type, tv(F:Float, T:Type)) => tv(F:Float, T':Type)
		if (T:Type ==Bool float orBool T:Type ==Bool double orBool T:Type ==Bool long-double)
		andBool (T':Type ==Bool float orBool T':Type ==Bool double orBool T':Type ==Bool long-double)
		[structural] 
	
	// choice implementation defined behavior
	rule
		cast(pointerType(T:Type), tv(N:Nat, T':Type)) => tv(N:Nat, pointerType(T:Type))
		if hasIntegerType(T':Type)
		andBool N:Nat =/=Bool NullPointerConstant
		[structural] 
	rule
		cast(pointerType(T:Type), tv(N:Nat, T':Type)) => tv(NullPointer, pointerType(T:Type))
		if hasIntegerType(T':Type)
		andBool N:Nat ==Bool NullPointerConstant
		[structural] 
	
	// fixme needs to check size
	rule
		cast(T:Type, tv(N:Nat, pointerType(?)))
			=> tv(N:Nat, T:Type)
		if hasIntegerType(T:Type)
		andBool notBool hasBoolType (T:Type)
		[structural] 
		
	// fixme
	// possibly not true with other endiannesses
	// choice
	// needs to handle alignment
	rule
		cast(pointerType(T:Type), tv(N:Nat, pointerType(?))) => tv(N:Nat, pointerType(T:Type))
		[structural] 

endkm

kmod DYNAMIC-C-CONVERSIONS is
	including DYNAMIC-SEMANTICS-CAST 
	including DYNAMIC-SEMANTICS-PROMOTIONS 

	// fixme generalize this should be done generically
	// rule < k > *(tv(?, (arrayType(T:Type, ?) => pointerType(T:Type)))) ...</ k > 
		// [structural] 
	// rule < k > *(tv(?, (incompleteArrayType(T:Type) => pointerType(T:Type)))) ...</ k > 
		// [structural] 
		
	// rule < k > _+_(tv(?, (incompleteArrayType(T:Type) => pointerType(T:Type))), ?) ...</ k > 
		// [structural] 
	// rule < k > _+_(?, tv(?, (incompleteArrayType(T:Type) => pointerType(T:Type)))) ...</ k > 
		// [structural] 
	// rule < k > _+_(tv(?, (arrayType(T:Type, ?) => pointerType(T:Type))), ?) ...</ k > 
		// [structural] 
	// rule < k > _+_(?, tv(Loc:Nat, (arrayType(T:Type, ?) => pointerType(T:Type)))) ...</ k > 
		// [structural]
	
	// rule unknown(Len:Nat) >>Nat N:Nat => unknown(absInt(Len:Nat -Int N:Nat))
		// if N:Nat <=Nat Len:Nat 
		// [structural]
		
	// rule (N:Nat bit:: piece(?, 1)) >>Nat 1 => N:Nat 
		// [structural]

	// fixme not sure about this
	// interpret is used to "cast" values read from memory
	// shouldn't need to do the < min one since values start positive
	op interpret-aux : Type K -> K 
	
	rule [interpret-start]:
		interpret(T:Type, piece(N:Nat, ?)) => interpret-aux(T:Type, N:Nat)
		if N:Nat >=Nat 0 
		[structural]
	
	rule [interpret-done]:
		interpret-aux(T:Type, I:Int) => tv(I:Int, T:Type)
		if min(T:Type) <=Int I:Int andBool max(T:Type) >=Int I:Int
		andBool hasIntegerType(T:Type)
		[structural] 
	rule [interpret-too-big]:
		interpret-aux(T:Type, I:Int) => interpret-aux(T:Type, _-Int_(I:Int, (2 ^Nat absInt(numBits(T:Type)))))
		if I:Int >Int max(T:Type)
		andBool hasIntegerType(T:Type)
		andBool _-Int_(I:Int, (2 ^Nat absInt(numBits(T:Type)))) >=Int min(T:Type)
		[structural] 
		
	rule [arithInterpret-done]:
		arithInterpret(T:Type, I:Int) => tv(I:Int, T:Type)
		if min(T:Type) <=Int I:Int andBool max(T:Type) >=Int I:Int
		andBool hasIntegerType(T:Type)
		[structural] 
	
	// rule [arithInterpret-bignum]:
		// arithInterpret(bignum, I:Int) => tv(I:Int, bignum)
		// [structural]
		
	rule [arithInterpret-unknown]:
		arithInterpret(T:Type, piece(unknown(N:Nat), N:Nat)) => tv(piece(unknown(N:Nat), N:Nat), T:Type)
		[structural]
		
	// these could be so much better...
	rule [bnot-unknown]: ~Int piece(unknown(Len:Nat), Len:Nat) => piece(unknown(Len:Nat), Len:Nat) [structural]
	
	rule [xor-unknown-right]: N:Nat xorInt piece(unknown(Len:Nat), Len:Nat) => piece(unknown(Len:Nat), Len:Nat) [structural]
	rule [or-unknown-right]: N:Nat |Int piece(unknown(Len:Nat), Len:Nat) => piece(unknown(Len:Nat), Len:Nat) [structural]
	rule [and-unknown-zero-right]: N:Nat &Int piece(unknown(Len:Nat), Len:Nat) => 0 if N:Nat ==Bool 0 [structural]
	rule [and-unknown-right]: N:Nat &Int piece(unknown(Len:Nat), Len:Nat) => 0 if N:Nat =/=Bool 0 [structural]

	rule [xor-unknown-left]: piece(unknown(Len:Nat), Len:Nat) xorInt N:Nat => piece(unknown(Len:Nat), Len:Nat) [structural]
	rule [or-unknown-left]: piece(unknown(Len:Nat), Len:Nat) |Int N:Nat => piece(unknown(Len:Nat), Len:Nat) [structural]
	rule [and-unknown-zero-left]: piece(unknown(Len:Nat), Len:Nat) &Int N:Nat => 0 if N:Nat ==Bool 0 [structural]
	rule [and-unknown-left]: piece(unknown(Len:Nat), Len:Nat) &Int N:Nat => 0 if N:Nat =/=Bool 0 [structural]
		
	// c99 6.5.7:4 The result of E1 << E2 is E1 left-shifted E2 bit positions; vacated bits are filled with zeros. If E1 has an unsigned type, the value of the result is E1 times 2^(E2), reduced modulo one more than the maximum value representable in the result type. If E1 has a signed type and nonnegative value, and E1 times 2^(E2) is representable in the result type, then that is the resulting value; otherwise, the behavior is undefined. 
	// e1 = 2147483647; e1 * 2^(1) = 2147483647 * 2 = 4294967294
	rule leftShiftInterpret(T:Type, I:Int, tv(E1:Int, T:Type)) => tv(I:Int %Int (max(T:Type) +Int 1), T:Type)
		if hasUnsignedIntegerType(T:Type)
		[structural] 
	rule leftShiftInterpret(T:Type, I:Int, tv(E1:Nat, T:Type)) => interpret-aux(T:Type, I:Int)
		if hasSignedIntegerType(T:Type)
		andBool I:Int <=Int (2 ^Nat absInt(numBits(T:Type)))
		[structural] 
		
	// c99 6.5.7:5 The result of E1 >> E2 is E1 right-shifted E2 bit positions. If E1 has an unsigned type or if E1 has a signed type and a nonnegative value, the value of the result is the integral part of the quotient of E1 / 2^(E2). If E1 has a signed type and a negative value, the resulting value is implementation-defined
	rule rightShiftInterpret(T:Type, I:Int) => tv(I:Int, T:Type)
		if hasIntegerType(T:Type)
		[structural] 
	
	// fixme
	rule arithInterpret(T:Type, F:Float) => tv(F:Float, T:Type)
		if (T:Type ==Bool double)
		orBool T:Type ==Bool float
		orBool T:Type ==Bool long-double
		[structural] 
	// signed arithmetic isn't supposed to overflow
	rule
		arithInterpret(T:Type, I:Int) => 
		tv(I:Int %Int (max(T:Type) +Int 1), T:Type)
		if hasUnsignedIntegerType(T:Type)
		andBool I:Int >Int max(T:Type)
		[structural] 
	rule
		arithInterpret(T:Type, I:Int) => arithInterpret(T:Type, _+Int_(I:Int, (max(T:Type) +Int 1)))
		if hasUnsignedIntegerType(T:Type)
		andBool I:Int <Int min(T:Type)
		andBool _+Int_(I:Int, (max(T:Type) +Int 1)) <=Int max(T:Type)
		[structural] 

	// rule integerTypes => signedIntegerTypes unsignedIntegerTypes [structural]
	rule unsignedIntegerTypes => Set(bool,, unsigned-char,, unsigned-short-int,, unsigned-int,, unsigned-long-int,, unsigned-long-long-int) [structural]
	rule signedIntegerTypes => Set(char,, signed-char,, short-int,, int,, long-int,, long-long-int) [structural]
endkm
