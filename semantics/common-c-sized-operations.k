// this file is not actually being used; it is experimental
kmod FIXED-WIDTH-SYNTAX is
	including K
	subsort #Nat #Int < K
	
	sort FWInt
	subsort FWInt < K

	op overflow : -> FWInt
	// op uoverflow : K -> FWInt // I don't know of any systems where this is a problem
	op soverflow : K -> FWInt
	op divideByZero : -> FWInt
	
	op _+sInt[_]_ : K #Nat K -> FWInt // operand, width, operand
	op _*sInt[_]_ : K #Nat K -> FWInt
	op _/sInt[_]_ : K #Nat K -> FWInt
	op _%sInt[_]_ : K #Nat K -> FWInt
	op _-sInt[_]_ : K #Nat K -> FWInt
	op -sInt[_]_ : #Nat K -> FWInt
	
	op _+uInt[_]_ : K #Nat K -> FWInt // operand, width, operand
	op _*uInt[_]_ : K #Nat K -> FWInt
	op _/uInt[_]_ : K #Nat K -> FWInt
	op _%uInt[_]_ : K #Nat K -> FWInt
	op _-uInt[_]_ : K #Nat K -> FWInt
	op -uInt[_]_ : #Nat K -> FWInt
	
	op _&sInt[_]_ : K #Nat K -> FWInt
	op _|sInt[_]_ : K #Nat K -> FWInt
	op _^sInt[_]_ : K #Nat K -> FWInt
	op ~sInt[_]_ : #Nat K -> FWInt
	
	op _&uInt[_]_ : K #Nat K -> FWInt
	op _|uInt[_]_ : K #Nat K -> FWInt
	op _^uInt[_]_ : K #Nat K -> FWInt
	op ~uInt[_]_ : #Nat K -> FWInt
	
	op _>>sInt[_]_ : K #Nat K -> FWInt
	op _<<sInt[_]_ : K #Nat K -> FWInt
	
	op _>>uInt[_]_ : K #Nat K -> FWInt
	op _<<uInt[_]_ : K #Nat K -> FWInt

	op umin : #Nat -> #Nat
	op umax : #Nat -> #Nat
	op usize : #Nat -> NzNat
	
	op smin : #Nat -> #Int
	op smax : #Nat -> #Nat
	op ssize : #Nat -> NzNat
	
	macro umin(_) = 0
	macro umax(N:#Nat) = (2 ^Nat N:#Nat) -Int 1
	macro usize(N:#Nat) = 2 ^Nat N:#Nat
endkm


kmod FIXED-UNSIGNED-ARITHMETIC is
	including FIXED-WIDTH-SYNTAX
	// rule [fixed-unsigned-addition-normal]:
		// N:#Nat +uInt[W:#Nat] N':#Nat => Result:#Nat
		// if Result:#Nat <=Nat umax(W:#Nat)
		// where Result:#Nat = (N:#Nat +Nat N':#Nat)
	// rule [fixed-unsigned-addition-overflow]:
		// N:#Nat +uInt[W:#Nat] N':#Nat => Result:#Nat %Nat usize(W:#Nat)
		// if Result:#Nat >Nat umax(W:#Nat)
		// where Result:#Nat = (N:#Nat +Nat N':#Nat)
		
	// rule [fixed-unsigned-multiplication-normal]:
		// N:#Nat *uInt[W:#Nat] N':#Nat => Result:#Nat
		// if Result:#Nat <=Nat umax(W:#Nat)
		// where Result:#Nat = (N:#Nat *Nat N':#Nat)
	// rule [fixed-unsigned-multiplication-overflow]:
		// N:#Nat *uInt[W:#Nat] N':#Nat => Result:#Nat %Nat usize(W:#Nat)
		// if Result:#Nat >Nat umax(W:#Nat)
		// where Result:#Nat = (N:#Nat *Nat N':#Nat)
		
	// rule [fixed-unsigned-division-normal]:
		// N:#Nat /uInt[W:#Nat] N':NzNat => Result:#Nat
		// where Result:#Nat = (N:#Nat /Nat N':NzNat)
	// rule [fixed-unsigned-division-divz]:
		// _ /uInt[W:#Nat] 0 => divideByZero
		
	// rule [fixed-unsigned-modulo-normal]:
		// N:#Nat %uInt[W:#Nat] N':NzNat => Result:#Nat
		// where Result:#Nat = (N:#Nat %Nat N':NzNat)
	// rule [fixed-unsigned-modulo-divz]:
		// _ %uInt[W:#Nat] 0 => divideByZero
		
	// rule [fixed-unsigned-subtraction-normal]:
		// N:#Nat -uInt[W:#Nat] N':#Nat => absInt(Result:#Int)
		// if Result:#Int >=Int umin(W:#Nat)
		// where Result:#Int = (N:#Nat -Int N':#Nat)
	// rule [fixed-unsigned-subtraction-underflow]:
		// N:#Nat -uInt[W:#Nat] N':#Nat 
		// => N:#Nat +Nat usize(W:#Nat) -uInt[W:#Nat] N':#Nat 
		// if Result:#Int <Int umin(W:#Nat)
		// where Result:#Int = (N:#Nat -Int N':#Nat)
endkm

kmod FIXED-SIGNED-ARITHMETIC is
	including FIXED-WIDTH-SYNTAX
	
	// rule [fixed-signed-addition-normal]:
		// N:#Int +sInt[W:#Nat] N':#Int => Result:#Int
		// if Result:#Int <=Int smax(W:#Nat) andBool Result:#Int >=Int smin(W:#Nat)
		// where Result:#Int = (N:#Int +Int N':#Int)
		
	// rule [fixed-signed-multiplication-normal]:
		// N:#Int *sInt[W:#Nat] N':#Int => Result:#Int
		// if Result:#Int <=Int smax(W:#Nat) andBool Result:#Int >=Int smin(W:#Nat)
		// where Result:#Int = (N:#Int *Int N':#Int)
		
	// rule [fixed-signed-division-normal]:
		// N:#Int /sInt[W:#Nat] N':NzInt => Result:#Int
		// where Result:#Int = (N:#Int /Int N':NzInt)
	// rule [fixed-signed-division-divz]:
		// _ /sInt[W:#Nat] 0 => divideByZero
		
	// rule [fixed-signed-modulo-normal]:
		// N:#Int %sInt[W:#Nat] N':NzInt => Result:#Int
		// where Result:#Int = (N:#Int %Int N':NzInt)
	// rule [fixed-signed-modulo-divz]:
		// _ %sInt[W:#Nat] 0 => divideByZero // why do i have to do this_
		
	// rule [fixed-signed-subtraction-normal]:
		// N:#Int -sInt[W:#Nat] N':#Int => Result:#Int
		// if Result:#Int <=Int smax(W:#Nat) andBool Result:#Int >=Int smin(W:#Nat)
		// where Result:#Int = (N:#Int -Int N':#Int)
		
	// rule [fixed-signed-negation-normal]:
		// -sInt[W:#Nat] N:#Int => absInt(Result:#Int)
		// if Result:#Int >=Int smin(W:#Nat) andBool Result:#Int <=Int smax(W:#Nat)
		// where Result:#Int = (-Int N:#Int)
endkm

kmod FIXED-UNSIGNED-BITWISE is
	including FIXED-WIDTH-SYNTAX
	
	// rule [fixed-unsigned-bitwise-and]:
		// N:#Nat &uInt[W:#Nat] N':#Nat => Result:#Nat
		// where Result:#Nat = (N:#Nat &Nat N':#Nat)
	// rule [fixed-unsigned-bitwise-or]:
		// N:#Nat |uInt[W:#Nat] N':#Nat => Result:#Nat
		// where Result:#Nat = (N:#Nat |Nat N':#Nat)
	// rule [fixed-unsigned-bitwise-xor]:
		// N:#Nat ^uInt[W:#Nat] N':#Nat => Result:#Nat
		// where Result:#Nat = (N:#Nat xorNat N':#Nat)
	// rule [fixed-unsigned-bitwise-negation]:
		// ~uInt[W:#Nat] N:#Nat => Result:#Nat
		// where Result:#Nat = (~Int N:#Nat)
		
	// // can shift by signed or unsigned of any non-negative width
	// rule [fixed-unsigned-shift-right]:
		// N:#Nat >>uInt[W:#Nat] N':#Nat => Result:#Nat
		// if N':#Nat <Nat W:#Nat
		// where Result:#Nat = (N:#Nat >>Nat N':#Nat)
	// rule [fixed-unsigned-shift-left]:
		// N:#Nat <<uInt[W:#Nat] N':#Nat => Result:#Nat
		// if N':#Nat <Nat W:#Nat
		// where Result:#Nat = (N:#Nat <<Nat N':#Nat)

endkm

kmod FIXED-SIGNED-BITWISE is
	including FIXED-WIDTH-SYNTAX
	
	// rule [fixed-signed-bitwise-and]:
		// N:#Int &sInt[W:#Nat] N':#Int => Result:#Int
		// where Result:#Int = (N:#Int &Int N':#Int)
	// rule [fixed-signed-bitwise-or]:
		// N:#Int |sInt[W:#Nat] N':#Int => Result:#Int
		// where Result:#Int = (N:#Int |Int N':#Int)
	// rule [fixed-signed-bitwise-xor]:
		// N:#Int ^sInt[W:#Nat] N':#Int => Result:#Int
		// where Result:#Int = (N:#Int xorInt N':#Int)
	// rule [fixed-signed-bitwise-negation]:
		// ~sInt[W:#Nat] N:#Int => Result:#Int
		// where Result:#Int = (~Int N:#Int)
		
	// // can shift by signed or unsigned of any non-negative width
	// rule [fixed-signed-shift-right]:
		// N:#Int >>sInt[W:#Nat] N':#Nat => Result:#Int
		// if N':#Nat <Nat W:#Nat
		// where Result:#Int = (N:#Int >>Int N':#Nat)
	// rule [fixed-signed-shift-left]:
		// N:#Int <<sInt[W:#Nat] N':#Nat => Result:#Int
		// if N':#Nat <Nat W:#Nat
		// where Result:#Int = (N:#Int <<Int N':#Nat)
endkm

kmod FIXED-UNSIGNED-DEFAULT is
	including FIXED-UNSIGNED-ARITHMETIC
	including FIXED-UNSIGNED-BITWISE
endkm

kmod FIXED-SIGNED-DEFAULT is
	including FIXED-SIGNED-ARITHMETIC
	including FIXED-SIGNED-BITWISE
endkm
	
kmod FIXED-C-STYLE-ARITHMETIC is
	including FIXED-WIDTH-SYNTAX
	including FIXED-UNSIGNED-ARITHMETIC
	including FIXED-SIGNED-ARITHMETIC
	
	// rule [fixed-signed-addition-overflow]:
		// N:#Int +sInt[W:#Nat] N':#Int => overflow
		// if Result:#Int >Int smax(W:#Nat) orBool Result:#Int <Int smin(W:#Nat)
		// where Result:#Int = (N:#Int +Int N':#Int)

	// rule [fixed-signed-multiplication-overflow]:
		// N:#Int *sInt[W:#Nat] N':#Int => overflow
		// if Result:#Int >Int smax(W:#Nat) orBool Result:#Int <Int smin(W:#Nat)
		// where Result:#Int = (N:#Int *Int N':#Int)
		
	// rule [fixed-signed-subtraction-overflow]:
		// N:#Int -sInt[W:#Nat] N':#Int => overflow
		// if Result:#Int >Int smax(W:#Nat) orBool Result:#Int <Int smin(W:#Nat)
		// where Result:#Int = (N:#Int -Int N':#Int)
		
	// rule [fixed-signed-negation-overflow]:
		// -sInt[W:#Nat] N:#Int => overflow
		// if Result:#Int <Int smin(W:#Nat) orBool Result:#Int >Int smax(W:#Nat)
		// where Result:#Int = (-Int N:#Int)
endkm


kmod FIXED-C-STYLE-BITWISE is
	including FIXED-WIDTH-SYNTAX
	including FIXED-UNSIGNED-BITWISE
	including FIXED-SIGNED-BITWISE
	// could add checks for shift problems
endkm

kmod FIXED-C-STYLE-TWOS-COMPLEMENT is
	including FIXED-WIDTH-SYNTAX
	
	// rule [fixed-unsigned-negation-normal]:
		// -uInt[W:#Nat] N:#Nat => absInt(Result:#Int +Int usize(W:#Nat)) %Nat usize(W:#Nat)
		// where Result:#Int = (-Int N:#Nat)
endkm
	
kmod FIXED-C-STYLE is
	including FIXED-C-STYLE-ARITHMETIC
	including FIXED-C-STYLE-BITWISE
	
	macro smin(N:#Nat) = -Int (2 ^Nat absInt(_-Int_(N:#Nat, 1)))
	macro smax(N:#Nat) = (2 ^Nat absInt(N:#Nat -Int 1)) -Int 1
	macro ssize(N:#Nat) = 2 ^Nat N:#Nat
endkm




