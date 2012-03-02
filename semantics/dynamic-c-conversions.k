kmod DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE is
	including DYNAMIC-INCLUDE 
endkm

kmod DYNAMIC-SEMANTICS-PROMOTIONS is
	including DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE 
	
	// "integer promotions" are used when doing arithmetic conversions, and for unary ~, +, -
	// "usual arithmetic conversions" are used when doing binary arithmetic on numbers, and are used to find a common type
	// there is another set of promotions called "default argument promotions" used when calling functions where the type information is not complete.  This is equivalent to integer promotions + (float => double) 
	
	
	op usualArithmeticConversion-aux : K K -> K
	
	rule usualArithmeticConversion(T:KResult, T':KResult)
			=> usualArithmeticConversion-aux(promote(T:KResult), promote(T':KResult))
		[structural]
		

	// op arithConversion-int : KLabel K K -> K
	op isArithBinOp : KLabel -> #Bool 

	op arithBinOps : -> Set // [memo] 
	op arithBinConversionOps : -> Set // [memo] 

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

	op arithUnaryOps : -> Set // [memo] 
	rule [arithUnaryOps]: arithUnaryOps => Set(l('-_),, l('+_),, l('~_)) [structural]

	rule [checkArithUnaryOp]: 
		isArithUnaryOp(KL:KLabel) => if arithUnaryOps contains l(KL:KLabel) then true else false fi [structural]
	
	
	rule hasBeenPromoted(t(_, enumType(_:#Id))) => true [structural]
	rule hasBeenPromoted(t(_, int)) => true [structural]
	rule hasBeenPromoted(t(_, unsigned-int)) => true [structural]
	rule hasBeenPromoted(t(_, long-int)) => true [structural]
	rule hasBeenPromoted(t(_, unsigned-long-int)) => true [structural]
	rule hasBeenPromoted(t(_, long-long-int)) => true [structural]
	rule hasBeenPromoted(t(_, unsigned-long-long-int)) => true [structural]
	
	rule hasBeenPromoted(t(_, bool)) => false [structural]
	rule hasBeenPromoted(t(_, signed-char)) => false [structural]
	rule hasBeenPromoted(t(_, unsigned-char)) => false [structural]
	rule hasBeenPromoted(t(_, short-int)) => false [structural]
	rule hasBeenPromoted(t(_, unsigned-short-int)) => false [structural]
	
	rule hasBeenPromoted(t(_, bitfieldType(_, _:#Nat))) => false [structural]
	
	
	rule [promote-unary]:
		< k > L:KLabel((tv(V:K, T:KResult) 
			=> tv(V:K, promote(T:KResult)))) 
		...</ k > 
		when isArithUnaryOp(L:KLabel)
		andBool notBool hasBeenPromoted(T:KResult)
		//andBool hasIntegerType(T:KResult)
		[structural]
	rule [promote-binary-left]:
		< k > L:KLabel((tv(V:K, T:KResult) => tv(V:K, promote(T:KResult))),, _) ...</ k > 
		when isArithBinOp(L:KLabel)
		andBool notBool hasBeenPromoted(T:KResult)
		//andBool hasIntegerType(T:KResult) // implicity in notBool hasBeenPromoted
		[structural] 
	rule [promote-binary-right]:
		< k > L:KLabel(_,, (tv(V:K, T:KResult) => tv(V:K, promote(T:KResult)))) ...</ k > 
		when isArithBinOp(L:KLabel)
		andBool notBool hasBeenPromoted(T:KResult)
		//andBool hasIntegerType(T:KResult)
		[structural]
	
	

	rule
		< k > L:KLabel(tv(V:K, T:KResult),, tv(V':K, T':KResult))
			=> L:KLabel(cast(finalType, tv(V:K, T:KResult)),, cast(finalType, tv(V':K, T':KResult)))
		...</ k >
		when isArithBinConversionOp(L:KLabel)
		andBool (hasIntegerType(T:KResult) orBool hasFloatType(T:KResult))
		andBool (hasIntegerType(T':KResult) orBool hasFloatType(T':KResult))
		andBool (T:KResult =/=Bool T':KResult)
		where finalType = usualArithmeticConversion(T:KResult, T':KResult)
		[structural] 
		

	// fixme these could be done more cleanly

	//C99 6.3.1.8
	// First, if the corresponding real type of either operand is long double, the other operand is converted, without change of type domain, to a type whose corresponding real type is long double
	rule usualArithmeticConversion-aux(t(_, long-double), _) => t(.Set, long-double) [structural]
	rule usualArithmeticConversion-aux(_, t(_, long-double)) => t(.Set, long-double) [structural] 
		
	// Otherwise, if the corresponding real type of either operand is double, the other operand is converted, without change of type domain, to a type whose corresponding real type is double
	rule
		usualArithmeticConversion-aux(t(_, double), t(_, T:K)) => t(.Set, double)
		when long-double =/=Bool T:K
		[structural] 
	rule
		usualArithmeticConversion-aux(T:K, t(_, double)) => t(.Set, double)
		when long-double =/=Bool T:K
		[structural] 
		
	// Otherwise, if the corresponding real type of either operand is float, the other operand is converted, without change of type domain, to a type whose corresponding real type is float. 53) For example, addition of a double _Complex and a float entails just the conversion of the float operand to double (and yields a double _Complex result)
	rule
		usualArithmeticConversion-aux(t(_, float), t(_, T:K)) => t(.Set, float)
		when long-double =/=Bool T:K
		andBool double =/=Bool T:K
		[structural] 
	rule
		usualArithmeticConversion-aux(t(_, T:K), t(_, float)) => t(.Set, float)
		when long-double =/=Bool T:K
		andBool double =/=Bool T:K
		[structural] 

	
	// Otherwise, the integer promotions are performed on both operands ..
	
	//C99 6.3.1.1:2 For objects or expressions with an integer type  whose integer conversion rank is less than or equal to the rank of int and unsigned int, and a bit field of type _Bool, int, signed int, or unsigned int, If an int can represent all values of the original type, the value is converted to an int; otherwise, it is converted to an unsigned int.  These are called the integer promotions.  All other types are unchanged by the integer promotions
	//C99 6.3.1.1:3 The integer promotions preserve value including sign. As discussed earlier, whether a "plain" char is treated as signed is implementation-defined

	rule [argPromote-float]: argPromote(t(_, float)) => t(.Set, double) [structural]
	rule [argPromote-double]: argPromote(t(_, double)) => t(.Set, double) [structural]
	rule [argPromote-long-double]: argPromote(t(_, long-double)) => t(.Set, long-double) [structural]
	rule [argPromote-integer]: argPromote(T:KResult) => promote(T:KResult)
		when hasIntegerType(T:KResult)
		[structural]
	
	rule [promote-float]:
		promote(T:KResult) => T:KResult
		when hasFloatType(T:KResult)
		[structural]
		
	// rule [promote-float]: promote(t(S:Set, float)) => t(S:Set, float)
		// [structural]
	// rule [promote-float]: promote(t(S:Set, float)) => t(S:Set, float)
		// [structural]
	// rule [promote-double]: promote(t(S:Set, double)) => t(S:Set, double)
		// [structural]
	// rule [promote-long-double]: promote(t(S:Set, long-double)) => t(S:Set, long-double)
		// [structural]

	// <= so enums become ints
	rule [promote-lte-int-fits]:
		promote(T:KResult) => t(.Set, int)
		when rank(T:KResult) <=Int rank(t(.Set, int))
		andBool min(t(.Set, int)) <=Int min(T:KResult) 
		andBool max(t(.Set, int)) >=Int max(T:KResult)		
		[structural]

	rule [promote-gt-int]:
		promote(T:KResult) => T:KResult
		when rank(T:KResult) >Int rank(t(.Set, int))
		[structural]

	rule [promote-bitfield-fits]:
		promote(t(S:Set, bitfieldType(t(S':Set, T:K), Len:#Nat))) => t(.Set, int)
		when (T:K ==Bool bool orBool T:K ==Bool int orBool T:K ==Bool unsigned-int)
		andBool min(t(.Set, int)) <=Int min(t(S:Set, bitfieldType(t(S':Set, T:K), Len:#Nat)))
		andBool max(t(.Set, int)) >=Int max(t(S:Set, bitfieldType(t(S':Set, T:K), Len:#Nat)))
		[structural] 
	// fixme unclear what 6.3.1.1:3 means

	rule [promote-lte-int-nofits]:
		promote(T:KResult) => t(.Set, unsigned-int)
		when rank(T:KResult) <=Int rank(t(.Set, int))
		andBool notBool (
			min(t(.Set, int)) <=Int min(T:KResult) 
			andBool max(t(.Set, int)) >=Int max(T:KResult)		
		)
		[structural]

	rule [promote-bitfield-nofits]:
		promote(t(S:Set, bitfieldType(t(S':Set, T:K), Len:#Nat))) => t(.Set, unsigned-int)
		when (T:K ==Bool bool orBool T:K ==Bool int orBool T:K ==Bool unsigned-int)
		andBool notBool (
			min(t(.Set, int)) <=Int min(t(S:Set, bitfieldType(t(S':Set, T:K), Len:#Nat)))
			andBool max(t(.Set, int)) >=Int max(t(S:Set, bitfieldType(t(S':Set, T:K), Len:#Nat)))
		)
		[structural]		
		
	// Then the following rules are applied to the promoted operands:
	
	// If both operands have the same type, then no further conversion is needed
	rule [arithConversion-int-done]: usualArithmeticConversion-aux(T:KResult, T:KResult) => T:KResult [structural]
		
	rule [maxType-left]:
		maxType(T:KResult, T':KResult) => T:KResult
		when rank(T:KResult) >=Int rank(T':KResult) 
		[structural]
	rule [maxType-right]:
		maxType(T:KResult, T':KResult) => T':KResult
		when rank(T':KResult) >=Int rank(T:KResult) 
		[structural]

	op hasSameSignedness : Type Type -> #Bool // [memo]
	rule [hasSameSignedness]: 
		hasSameSignedness(T:KResult, T':KResult)
			=> (hasSignedIntegerType(T:KResult) andBool hasSignedIntegerType(T':KResult))
		orBool (hasUnsignedIntegerType(T:KResult) andBool hasUnsignedIntegerType(T':KResult))
		[structural]
		
	// Otherwise, if both operands have signed integer types or both have unsigned integer types, the operand with the type of lesser integer conversion rank is converted to the type of the operand with greater rank
	rule [arithmeticConversion-same-signedness]:
		usualArithmeticConversion-aux(T:KResult, T':KResult) => maxType(T:KResult, T':KResult)
		when T:KResult =/=Bool T':KResult
		andBool hasSameSignedness(T:KResult, T':KResult)
		[structural]
	
		
	// Otherwise, if the operand that has unsigned integer type has rank greater or equal to the rank of the type of the other operand, then the operand with signed integer type is converted to the type of the operand with unsigned integer type
	rule [arithmeticConversion-unsigned-ge-right]:
		usualArithmeticConversion-aux(T:KResult, T':KResult) => T':KResult
		when T:KResult =/=Bool T':KResult
		andBool hasSignedIntegerType(T:KResult) 
		andBool hasUnsignedIntegerType(T':KResult) 
		andBool rank(T':KResult) >=Int rank(T:KResult)
		[structural] 
	rule [arithmeticConversion-unsigned-ge-left]:
		usualArithmeticConversion-aux(T:KResult, T':KResult) => T:KResult
		when T:KResult =/=Bool T':KResult
		andBool hasUnsignedIntegerType(T:KResult) 
		andBool hasSignedIntegerType(T':KResult) 
		andBool rank(T:KResult) >=Int rank(T':KResult)
		[structural] 
		
	// Otherwise, if the type of the operand with signed integer type can represent all of the values of the type of the operand with unsigned integer type, then the operand with unsigned integer type is converted to the type of the operand with signed integer type
	rule [arithmeticConversion-signed-big-left]:
		usualArithmeticConversion-aux(T:KResult, T':KResult) => T:KResult
		when T:KResult =/=Bool T':KResult
		andBool hasSignedIntegerType(T:KResult) 
		andBool hasUnsignedIntegerType(T':KResult) 
		andBool rank(T':KResult) <Int rank(T:KResult)
		andBool min(T:KResult) <=Int min(T':KResult)
		andBool max(T:KResult) >=Int max(T':KResult)
		[structural] 
	rule [arithmeticConversion-signed-big-right]:
		usualArithmeticConversion-aux(T:KResult, T':KResult) => T':KResult
		when T:KResult =/=Bool T':KResult
		andBool hasUnsignedIntegerType(T:KResult) 
		andBool hasSignedIntegerType(T':KResult) 
		andBool rank(T:KResult) <Int rank(T':KResult)
		andBool min(T':KResult) <=Int min(T:KResult)
		andBool max(T':KResult) >=Int max(T:KResult)
		[structural] 
		
	// Otherwise, both operands are converted to the unsigned integer type corresponding to the type of the operand with signed integer type
	rule [arithmeticConversion-to-unsigned-left]:
		usualArithmeticConversion-aux(T:KResult, T':KResult) => correspondingUnsignedType(T:KResult)
		when T:KResult =/=Bool T':KResult
		andBool hasSignedIntegerType(T:KResult) 
		andBool hasUnsignedIntegerType(T':KResult) 
		andBool rank(T':KResult) <Int rank(T:KResult)
		andBool (min(T:KResult) >Int min(T':KResult) orBool max(T:KResult) <Int max(T':KResult))
		[structural] 
	rule [arithmeticConversion-to-unsigned-right]:
		usualArithmeticConversion-aux(T:KResult, T':KResult) => correspondingUnsignedType(T':KResult)
		when T:KResult =/=Bool T':KResult
		andBool hasUnsignedIntegerType(T:KResult) 
		andBool hasSignedIntegerType(T':KResult) 
		andBool rank(T:KResult) <Int rank(T':KResult)
		andBool (min(T':KResult) >Int min(T:KResult) orBool max(T':KResult) <Int max(T:KResult))
		[structural] 
		
		
	op correspondingUnsignedType : Type -> Type 
	
	rule [correspondingUnsigned-int]: 
		correspondingUnsignedType(t(S:Set, int)) 
			=> t(S:Set, unsigned-int)
		[structural]
	rule [correspondingUnsigned-long-int]: 
		correspondingUnsignedType(t(S:Set, long-int))
			=> t(S:Set, unsigned-long-int)
		[structural]
	rule [correspondingUnsigned-long-long-int]: 
		correspondingUnsignedType(t(S:Set, long-long-int))
			=> t(S:Set, unsigned-long-long-int)
		[structural]
	
endkm

kmod DYNAMIC-SEMANTICS-CAST is 
	including DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE 
		
	//- switch assumes casts can happen anywhere
	rule 
		cast(t(_, void), _:KResult) => skipval
		[structural] 
		
	rule
		cast(T:KResult, tv(L:List{K}, T:KResult)) => tv(L:List{K}, T:KResult)
		[structural]
		
	rule
		cast(t(S:Set, T:K), tv(L:List{K}, t(_, T:K))) => tv(L:List{K}, t(S:Set, T:K))
		[structural]
	
	//c99 6.3.1.2:1 to _Bool
	// fixme worried about qualifiers
	rule [cast-integer-to-bool]:
		cast(t(S:Set, bool), tv(I:#Int, T:KResult))
			=> if I:#Int ==Bool 0 then tv(0, t(S:Set, bool)) else tv(1, t(S:Set, bool)) fi
		when hasIntegerType(T:KResult)
		[structural]
	rule [cast-non-integer-to-bool]:
		cast(t(S:Set, bool), tv(L:List{K}, T:KResult)) 
			=> cast(t(S:Set, bool), tv(0, t(.Set, int)) != tv(L:List{K}, T:KResult))
		when notBool hasIntegerType(T:KResult)
		[structural] 
	
	//c99 6.3.1.3:1 When a value with integer type is converted to another integer type other than _Bool, if the value can be represented by the new type, it is unchanged. 
	rule [cast-integer-no-value-change]:
		cast(T:KResult, tv(I:#Int, T':KResult)) => tv(I:#Int, T:KResult)
		when min(T:KResult) <=Int I:#Int andBool max(T:KResult) >=Int I:#Int 
		andBool hasIntegerType(T':KResult)
		andBool hasIntegerType(T:KResult)
		andBool notBool hasBoolType (T:KResult)
		[structural] 
		
	//c99 6.3.1.3:2 Otherwise, if the new type is unsigned, the value is converted by repeatedly adding or subtracting one more than the maximum value that can be represented in the new type until the value is in the range of the new type

	rule [cast-ubitfield-of-small]:
		cast(t(S:Set, bitfieldType(T:KResult, Len:#Nat)), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, bitfieldType(T:KResult, Len:#Nat)), tv(I:#Int +Int max(t(S:Set, bitfieldType(T:KResult, Len:#Nat))) +Int 1, T':KResult))
		when I:#Int <Int min(t(S:Set, bitfieldType(T:KResult, Len:#Nat)))
		andBool hasIntegerType(T':KResult)
		andBool hasUnsignedIntegerType(T:KResult)
		[structural]
	rule [cast-uchar-of-small]:
		cast(t(S:Set, unsigned-char), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, unsigned-char), tv(I:#Int +Int max(t(S:Set, unsigned-char)) +Int 1, T':KResult))
		when I:#Int <Int min(t(S:Set, unsigned-char))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-usint-of-small]:
		cast(t(S:Set, unsigned-short-int), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, unsigned-short-int), tv(I:#Int +Int max(t(S:Set, unsigned-short-int)) +Int 1, T':KResult))
		when I:#Int <Int min(t(S:Set, unsigned-short-int))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-uint-of-small]:
		cast(t(S:Set, unsigned-int), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, unsigned-int), tv(I:#Int +Int max(t(S:Set, unsigned-int)) +Int 1, T':KResult))
		when I:#Int <Int min(t(S:Set, unsigned-int))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-ulong-of-small]:
		cast(t(S:Set, unsigned-long-int), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, unsigned-long-int), tv(I:#Int +Int max(t(S:Set, unsigned-long-int)) +Int 1, T':KResult))
		when I:#Int <Int min(t(S:Set, unsigned-long-int))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-ullong-of-small]:
		cast(t(S:Set, unsigned-long-long-int), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, unsigned-long-long-int), tv(I:#Int +Int max(t(S:Set, unsigned-long-long-int)) +Int 1, T':KResult))
		when I:#Int <Int min(t(S:Set, unsigned-long-long-int))
		andBool hasIntegerType(T':KResult)
		[structural]
		
	

	rule [cast-ubitfield-of-big]:
		cast(t(S:Set, bitfieldType(T:KResult, Len:#Nat)), tv(I:#Int, T':KResult)) 
			=> tv(I:#Int %Int (max(t(S:Set, bitfieldType(T:KResult, Len:#Nat))) +Int 1), t(S:Set, bitfieldType(T:KResult, Len:#Nat)))
		when I:#Int >Int max(t(S:Set, bitfieldType(T:KResult, Len:#Nat)))
		andBool hasIntegerType(T':KResult)
		andBool hasUnsignedIntegerType(T:KResult)
		[structural]
	rule [cast-uchar-of-big]:
		cast(t(S:Set, unsigned-char), tv(I:#Int, T':KResult)) 
			=> tv(I:#Int %Int (max(t(S:Set, unsigned-char)) +Int 1), t(S:Set, unsigned-char))
		when I:#Int >Int max(t(S:Set, unsigned-char))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-usint-of-big]:
		cast(t(S:Set, unsigned-short-int), tv(I:#Int, T':KResult)) 
			=> tv(I:#Int %Int (max(t(S:Set, unsigned-short-int)) +Int 1), t(S:Set, unsigned-short-int))
		when I:#Int >Int max(t(S:Set, unsigned-short-int))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-uint-of-big]:
		cast(t(S:Set, unsigned-int), tv(I:#Int, T':KResult)) 
			=> tv(I:#Int %Int (max(t(S:Set, unsigned-int)) +Int 1), t(S:Set, unsigned-int))
		when I:#Int >Int max(t(S:Set, unsigned-int))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-ulong-of-big]:
		cast(t(S:Set, unsigned-long-int), tv(I:#Int, T':KResult)) 
			=> tv(I:#Int %Int (max(t(S:Set, unsigned-long-int)) +Int 1), t(S:Set, unsigned-long-int))
		when I:#Int >Int max(t(S:Set, unsigned-long-int))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-ullong-of-big]:
		cast(t(S:Set, unsigned-long-long-int), tv(I:#Int, T':KResult)) 
			=> tv(I:#Int %Int (max(t(S:Set, unsigned-long-long-int)) +Int 1), t(S:Set, unsigned-long-long-int))
		when I:#Int >Int max(t(S:Set, unsigned-long-long-int))
		andBool hasIntegerType(T':KResult)
		[structural]

	
	//c99 6.3.1.3:3 Otherwise, the new type is signed and the value cannot be represented in it; either the result is implementation-defined or an implementation-defined signal is raised
	// choice
	rule [cast-sbitfield-of-huge]:
		cast(t(S:Set, bitfieldType(T:KResult, Len:#Nat)), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, bitfieldType(T:KResult, Len:#Nat)), tv(I:#Int %Int (2 ^Nat absInt(numBits(t(S:Set, bitfieldType(T:KResult, Len:#Nat))))), T':KResult)) 
		when absInt(I:#Int) >Int (2 ^Nat absInt(numBits(t(S:Set, bitfieldType(T:KResult, Len:#Nat)))))
		andBool hasIntegerType(T':KResult)
		andBool hasSignedIntegerType(T:KResult)
		[structural]
	rule [cast-schar-of-huge]:
		cast(t(S:Set, signed-char), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, signed-char), tv(I:#Int %Int (2 ^Nat absInt(numBits(t(S:Set, signed-char)))), T':KResult)) 
		when absInt(I:#Int) >Int (2 ^Nat absInt(numBits(t(S:Set, signed-char))))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-sint-of-huge]:
		cast(t(S:Set, short-int), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, short-int), tv(I:#Int %Int (2 ^Nat absInt(numBits(t(S:Set, short-int)))), T':KResult)) 
		when absInt(I:#Int) >Int (2 ^Nat absInt(numBits(t(S:Set, short-int))))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-int-of-huge]:
		cast(t(S:Set, int), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, int), tv(I:#Int %Int (2 ^Nat absInt(numBits(t(S:Set, int)))), T':KResult)) 
		when absInt(I:#Int) >Int (2 ^Nat absInt(numBits(t(S:Set, int))))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-long-of-huge]:
		cast(t(S:Set, long-int), tv(I:#Int, T':KResult)) 
			=> cast(t(S:Set, long-int), tv(I:#Int %Int (2 ^Nat absInt(numBits(t(S:Set, long-int)))), T':KResult)) 
		when absInt(I:#Int) >Int (2 ^Nat absInt(numBits(t(S:Set, long-int))))
		andBool hasIntegerType(T':KResult)
		[structural]
	rule [cast-llong-of-huge]:
		cast(t(S:Set, long-long-int), tv(I:#Int, T':KResult))
			=> cast(t(S:Set, long-long-int), tv(I:#Int %Int (2 ^Nat absInt(numBits(t(S:Set, long-long-int)))), T':KResult)) 
		when absInt(I:#Int) >Int (2 ^Nat absInt(numBits(t(S:Set, long-long-int))))
		andBool hasIntegerType(T':KResult)
		[structural]
		
		
		
	rule [cast-signed-of-small]:
		cast(T:KResult, tv(I:#Int, T':KResult))
			=> tv(I:#Int +Int (2 ^Nat absInt(numBits(T:KResult))), T:KResult)
		when I:#Int <Int min(T:KResult)
		andBool absInt(I:#Int) <=Int (2 ^Nat absInt(numBits(T:KResult)))
		andBool hasSignedIntegerType(T:KResult)
		andBool hasIntegerType(T':KResult)
		andBool notBool hasBoolType (T:KResult)
		[structural] 
	rule [cast-signed-of-big]:
		cast(T:KResult, tv(I:#Int, T':KResult)) 
			=> tv(_-Int_(I:#Int, (2 ^Nat absInt(numBits(T:KResult)))), T:KResult)
		when I:#Int >Int max(T:KResult)
		andBool absInt(I:#Int) <=Int (2 ^Nat absInt(numBits(T:KResult)))
		andBool hasSignedIntegerType(T:KResult)
		andBool hasIntegerType(T':KResult)
		andBool notBool hasBoolType (T:KResult)
		[structural] 

	// this is starting to get into sketchy land
	rule [cast-unknown-integer]:
		cast(T:KResult, tv(piece(unknown(Len:#Nat), Len:#Nat), T':KResult)) 
			=> tv(piece(unknown(K2Nat(bitSizeofType(T:KResult))), K2Nat(bitSizeofType(T:KResult))), T:KResult)
		when hasIntegerType(T:KResult)
		andBool hasIntegerType(T':KResult)
		// andBool Len:#Nat ==Bool numBitsPerByte
		[structural]	
	
	//C99 6.3.1.4:1 When a finite value of real floating type is converted to an integer type other than _Bool, the fractional part is discarded (i.e., the value is truncated toward zero). If the value of the integral part cannot be represented by the integer type, the behavior is undefined.52) The remaindering operation performed when a value of integer type is converted to unsigned type need not be performed when a value of real floating type is converted to unsigned type. Thus, the range of portable real floating values is (-1, Utype_MAX+1)
	// fixme
	rule
		cast(T:KResult, tv(V:#Float, t(S:Set, double))) 
			=> cast(T:KResult, tv(truncRat(Float2Rat(V:#Float)), t(S:Set, long-long-int)))
		when hasIntegerType(T:KResult)
		andBool notBool hasBoolType (T:KResult)
		[structural] 
	rule
		cast(T:KResult, tv(V:#Float, t(S:Set, float))) 
			=> cast(T:KResult, tv(truncRat(Float2Rat(V:#Float)), t(S:Set, long-long-int)))
		when hasIntegerType(T:KResult)
		andBool notBool hasBoolType (T:KResult)
		[structural] 
	rule
		cast(T:KResult, tv(V:#Float, t(S:Set, long-double))) 
			=> cast(T:KResult, tv(truncRat(Float2Rat(V:#Float)), t(S:Set, long-long-int)))
		when hasIntegerType(T:KResult)
		andBool notBool hasBoolType (T:KResult)
		[structural] 
	
	//C99 6.3.1.4:2 When a value of integer type is converted to a real floating type, if the value being converted can be represented exactly in the new type, it is unchanged. If the value being converted is in the range of values that can be represented but cannot be represented exactly, the result is either the nearest higher or nearest lower representable value, chosen in an implementation-defined manner. If the value being converted is outside the range of values that can be represented, the behavior is undefined

	rule [cast-int-to-float]:
		cast(t(S:Set, float), tv(I:#Int, T:KResult)) 
			=> tv(Rat2Float(I:#Int), t(S:Set, float))
		when hasIntegerType(T:KResult)
		[structural] 
	rule [cast-int-to-double]:
		cast(t(S:Set, double), tv(I:#Int, T:KResult)) 
			=> tv(Rat2Float(I:#Int), t(S:Set, double))
		when hasIntegerType(T:KResult)
		[structural] 
	rule [cast-int-to-long-double]:
		cast(t(S:Set, long-double), tv(I:#Int, T:KResult)) 
			=> tv(Rat2Float(I:#Int), t(S:Set, long-double))
		when hasIntegerType(T:KResult)
		[structural] 
	
	// fixme all floats same precision
	rule
		cast(t(S:Set, T':K), tv(F:#Float, t(_, T:K))) 
			=> tv(F:#Float, t(S:Set, T':K))
		when (T:K ==Bool float orBool T:K ==Bool double orBool T:K ==Bool long-double)
		andBool (T':K ==Bool float orBool T':K ==Bool double orBool T':K ==Bool long-double)
		[structural] 
	
	// choice implementation defined behavior
	rule
		cast(t(S:Set, pointerType(T:KResult)), tv(N:#Nat, T':KResult)) 
			=> tv(N:#Nat, t(S:Set, pointerType(T:KResult)))
		when hasIntegerType(T':KResult)
		andBool N:#Nat =/=Bool NullPointerConstant
		[structural] 
	rule
		cast(t(S:Set, pointerType(T:KResult)), tv(N:#Nat, T':KResult)) 
			=> tv(NullPointer, t(S:Set, pointerType(T:KResult)))
		when hasIntegerType(T':KResult)
		andBool N:#Nat ==Bool NullPointerConstant
		[structural] 
	
	// fixme needs to check size
	rule
		cast(T:KResult, tv(N:#Nat, t(_, pointerType(_))))
			=> tv(N:#Nat, T:KResult)
		when hasIntegerType(T:KResult)
		andBool notBool hasBoolType (T:KResult)
		[structural] 
		
	// fixme
	// possibly not true with other endiannesses
	// choice
	// needs to handle alignment
	rule
		cast(t(S:Set, pointerType(T:KResult)), tv(N:#Nat, t(_, pointerType(_)))) => tv(N:#Nat, t(S:Set, pointerType(T:KResult)))
		[structural] 

endkm

kmod DYNAMIC-C-CONVERSIONS is
	including DYNAMIC-SEMANTICS-CAST 
	including DYNAMIC-SEMANTICS-PROMOTIONS 

	// fixme not sure about this
	// interpret is used to "cast" values read from memory
	// shouldn't need to do the < min one since values start positive
	op interpret-aux : Type K -> K 
	
	rule [interpret-start]:
		interpret(T:KResult, piece(N:#Nat, _:#Nat)) => interpret-aux(T:KResult, N:#Nat)
		when N:#Nat >=Nat 0 
		[structural]
	
	rule [interpret-done]:
		interpret-aux(T:KResult, I:#Int) => tv(I:#Int, T:KResult)
		when min(T:KResult) <=Int I:#Int andBool max(T:KResult) >=Int I:#Int
		andBool hasIntegerType(T:KResult)
		[structural] 
	rule [interpret-too-big]:
		interpret-aux(T:KResult, I:#Int) => interpret-aux(T:KResult, _-Int_(I:#Int, (2 ^Nat absInt(numBits(T:KResult)))))
		when I:#Int >Int max(T:KResult)
		andBool hasIntegerType(T:KResult)
		//andBool _-Int_(I:#Int, (2 ^Nat absInt(numBits(T:KResult)))) >=Int min(T:KResult)
		[structural] 
		
	rule [arithInterpret-done]:
		arithInterpret(T:KResult, I:#Int) => tv(I:#Int, T:KResult)
		when min(T:KResult) <=Int I:#Int andBool max(T:KResult) >=Int I:#Int
		andBool hasIntegerType(T:KResult)
		[structural] 
		
	rule [arithInterpret-unknown]:
		arithInterpret(T:KResult, piece(unknown(N:#Nat), N:#Nat)) => tv(piece(unknown(N:#Nat), N:#Nat), T:KResult)
		[structural]
		
	// these could be so much better...
	rule [bnot-unknown]: ~Int piece(unknown(Len:#Nat), Len:#Nat) => piece(unknown(Len:#Nat), Len:#Nat) [structural]
	
	rule [xor-unknown-right]: N:#Nat xorInt piece(unknown(Len:#Nat), Len:#Nat) => piece(unknown(Len:#Nat), Len:#Nat) [structural]
	rule [or-unknown-right]: N:#Nat |Int piece(unknown(Len:#Nat), Len:#Nat) => piece(unknown(Len:#Nat), Len:#Nat) [structural]
	rule [and-unknown-zero-right]: N:#Nat &Int piece(unknown(Len:#Nat), Len:#Nat) => 0
		when N:#Nat ==Bool 0 
		[structural]
	rule [and-unknown-right]: N:#Nat &Int piece(unknown(Len:#Nat), Len:#Nat) => 0
		when N:#Nat =/=Bool 0 
		[structural]

	rule [xor-unknown-left]: piece(unknown(Len:#Nat), Len:#Nat) xorInt N:#Nat => piece(unknown(Len:#Nat), Len:#Nat) [structural]
	rule [or-unknown-left]: piece(unknown(Len:#Nat), Len:#Nat) |Int N:#Nat => piece(unknown(Len:#Nat), Len:#Nat) [structural]
	rule [and-unknown-zero-left]: piece(unknown(Len:#Nat), Len:#Nat) &Int N:#Nat => 0
		when N:#Nat ==Bool 0 
		[structural]
	rule [and-unknown-left]: piece(unknown(Len:#Nat), Len:#Nat) &Int N:#Nat => 0
		when N:#Nat =/=Bool 0 [structural]
		
	// c99 6.5.7:4 The result of E1 << E2 is E1 left-shifted E2 bit positions; vacated bits are filled with zeros. If E1 has an unsigned type, the value of the result is E1 times 2^(E2), reduced modulo one more than the maximum value representable in the result type. If E1 has a signed type and nonnegative value, and E1 times 2^(E2) is representable in the result type, then that is the resulting value; otherwise, the behavior is undefined. 
	// e1 = 2147483647; e1 * 2^(1) = 2147483647 * 2 = 4294967294
	rule leftShiftInterpret(T:KResult, I:#Int, tv(E1:#Int, T:KResult)) => tv(I:#Int %Int (max(T:KResult) +Int 1), T:KResult)
		when hasUnsignedIntegerType(T:KResult)
		[structural] 
	rule leftShiftInterpret(T:KResult, I:#Int, tv(E1:#Nat, T:KResult)) => tv(I:#Int, T:KResult)
		when hasSignedIntegerType(T:KResult)
		// andBool I:#Int <=Int (2 ^Nat absInt(numBits(T:KResult)))
		andBool I:#Int <=Int max(T:KResult)
		andBool I:#Int >=Int min(T:KResult)
		[structural] 
		
	// c99 6.5.7:5 The result of E1 >> E2 is E1 right-shifted E2 bit positions. If E1 has an unsigned type or if E1 has a signed type and a nonnegative value, the value of the result is the integral part of the quotient of E1 / 2^(E2). If E1 has a signed type and a negative value, the resulting value is implementation-defined
	rule rightShiftInterpret(T:KResult, I:#Int) => tv(I:#Int, T:KResult)
		when hasIntegerType(T:KResult)
		[structural] 
	
	// fixme
	rule [arithInterpret-float]: arithInterpret(t(S:Set, T:K), F:#Float) => tv(F:#Float, t(S:Set, T:K))
		when (T:K ==Bool double)
		orBool T:K ==Bool float
		orBool T:K ==Bool long-double
		[structural] 
	// signed arithmetic isn't supposed to overflow
	rule [arithInterpret-unsigned-big]:
		arithInterpret(T:KResult, I:#Int) 
		=> tv(I:#Int %Int (max(T:KResult) +Int 1), T:KResult)
		when hasUnsignedIntegerType(T:KResult)
		andBool I:#Int >Int max(T:KResult)
		[structural] 
	rule [arithInterpret-unsigned-small]:
		arithInterpret(T:KResult, I:#Int) 
		=> arithInterpret(T:KResult, _+Int_(I:#Int %Int (max(T:KResult) +Int 1), (max(T:KResult) +Int 1)))
		//=> tv(_+Int_(I:#Int %Int (max(T:KResult) +Int 1), (max(T:KResult) +Int 1)), T:KResult)
		when hasUnsignedIntegerType(T:KResult)
		andBool I:#Int <Int min(T:KResult)
		[structural]
		// must be like this so ((unsigned int)(~((unsigned int)~0)) != 0) will work, but not sure why

	// rule integerTypes => signedIntegerTypes unsignedIntegerTypes [structural]
	rule unsignedIntegerTypes => Set(bool,, unsigned-char,, unsigned-short-int,, unsigned-int,, unsigned-long-int,, unsigned-long-long-int) [structural]
	rule signedIntegerTypes => Set(char,, signed-char,, short-int,, int,, long-int,, long-long-int) [structural]
endkm
