require "dynamic-c-semantics.k"

module DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE
     imports DYNAMIC-INCLUDE
     
     syntax Bool ::= hasSameSignedness(Type, Type) [function] // [memo]
     syntax Type ::= correspondingUnsignedType(Type) [function] 
endmodule

module DYNAMIC-SEMANTICS-CONVERSIONS-HELPERS
     imports DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE 
     
     rule [hasSameSignedness]: 
          hasSameSignedness(T:KResult, T':KResult)
          => (hasSignedIntegerType(T:KResult) andBool hasSignedIntegerType(T':KResult))
          orBool (hasUnsignedIntegerType(T:KResult) andBool hasUnsignedIntegerType(T':KResult))
     
     rule [correspondingUnsigned-int]: 
          correspondingUnsignedType(t(S:Set, int)) => t(S:Set, unsigned-int)
     rule [correspondingUnsigned-long-int]: 
          correspondingUnsignedType(t(S:Set, long-int)) => t(S:Set, unsigned-long-int)
     rule [correspondingUnsigned-long-long-int]: 
          correspondingUnsignedType(t(S:Set, long-long-int)) => t(S:Set, unsigned-long-long-int)
     
endmodule


module DYNAMIC-SEMANTICS-PROMOTIONS
     imports DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE
     // \csection{6}{3}{0}{0}{Conversions}
     /*@
     \fromStandard{\source[n1570]{\para{6.3}{1--2}}}{

     Several operators convert operand values from one type to another
     automatically. This subclause specifies the result required from such an
     implicit conversion, as well as those that result from a cast operation
     (an explicit conversion). The list in 6.3.1.8 summarizes the conversions
     performed by most ordinary operators; it is supplemented as required by
     the discussion of each operator in 6.5.

     Conversion of an operand value to a compatible type causes no change to
     the value or the representation.
     }*/

     // "integer promotions" are used when doing arithmetic conversions, and
     // for unary ~, +, - "usual arithmetic conversions" are used when doing
     // binary arithmetic on numbers, and are used to find a common type there
     // is another set of promotions called "default argument promotions" used
     // when calling functions where the type information is not complete. This
     // is equivalent to integer promotions + (float => double) 
          
     rule [argPromote-float]: argPromote(t(_, float)) => t(.Set, double)
     rule [argPromote-double]: argPromote(t(_, double)) => t(.Set, double)
     rule [argPromote-long-double]: argPromote(t(_, long-double)) => t(.Set, long-double)
     rule [argPromote-integer]: argPromote(T:KResult) => promote(T:KResult)
          when hasIntegerType(T:KResult)

     // syntax K ::= "arithConversion-int" "(" KLabel "," K "," K ")"
     syntax Bool ::= isArithBinOp(KLabel) [function]

     syntax Set ::= "arithBinOps" [function] // memo
     syntax Set ::= "arithBinConversionOps" [function] // memo

     rule [arithBinOps]:
          arithBinOps => arithBinConversionOps (SetItem(l('_<<_)) SetItem(l('_>>_))) [structural]
     rule [arithBinConversionOps]:
          arithBinConversionOps => 
               SetItem(l('_*_))
               SetItem(l('_/_))
               SetItem(l('_%_))
               SetItem(l('_+_))
               SetItem(l('_-_))
               SetItem(l('_<_))
               SetItem(l('_>_))
               SetItem(l('_<=_))
               SetItem(l('_>=_))
               SetItem(l('_==_))
               SetItem(l('_!=_))
               SetItem(l('_&_))
               SetItem(l('_|_))
               SetItem(l('_^_))
     [structural]
     
     rule [checkArithBinOp]:
          isArithBinOp(KL:KLabel) => #if l(KL:KLabel) in arithBinOps #then true #else false #fi 
          [structural]
     rule [checkArithBinConversionOp]:
          isArithBinConversionOp(KL:KLabel) => #if l(KL:KLabel) in arithBinConversionOps #then true #else false #fi 
          [structural]

     syntax Set ::= "arithUnaryOps" [function]// [memo] 
     rule [arithUnaryOps]: arithUnaryOps => 
          SetItem(l('-_))
          SetItem(l('+_))
          SetItem(l('~_))

     rule [checkArithUnaryOp]: 
          isArithUnaryOp(KL:KLabel) => #if l(KL:KLabel) in arithUnaryOps #then true #else false #fi 
          [structural]
     
     // \csection{6}{3}{1}{0}{Arithmetic operands}
     // \csection{6}{3}{1}{1}{Boolean, characters, and integers}
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.1}{1}}}{
     Every integer type has an integer conversion rank defined as follows:
     \begin{itemize}

     \item No two signed integer types shall have the same rank, even if they
     have the same representation.

     \item The rank of a signed integer type shall be greater than the rank of
     any signed integer type with less precision.

     \item The rank of \cinline{long long int} shall be greater than the rank
     of \cinline{long int}, which shall be greater than the rank of
     \cinline{int}, which shall be greater than the rank of \cinline{short
     int}, which shall be greater than the rank of \cinline{signed char}.

     \item The rank of any unsigned integer type shall equal the rank of the
     corresponding signed integer type, if any.

     \item The rank of any standard integer type shall be greater than the rank
     of any extended integer type with the same width.

     \item The rank of \cinline{char} shall equal the rank of \cinline{signed
     char} and \cinline{unsigned char}.

     \item The rank of \cinline{_Bool} shall be less than the rank of all other
     standard integer types.

     \item The rank of any enumerated type shall equal the rank of the
     compatible integer type (see 6.7.2.2).

     \item The rank of any extended signed integer type relative to another
     extended signed integer type with the same precision is
     implementation-defined, but still subject to the other rules for
     determining the integer conversion rank.

     \item For all integer types T1, T2, and T3, if T1 has greater rank than T2
     and T2 has greater rank than T3, then T1 has greater rank than T3.

     \end{itemize}%
     }*/
     rule rank(t(_, bool)) => 0
     rule rank(t(_, signed-char)) => 1
     rule rank(t(_, unsigned-char)) => 1
     rule rank(t(_, short-int)) => 2
     rule rank(t(_, unsigned-short-int)) => 2
     rule rank(t(_, int)) => 3
     rule rank(t(_, unsigned-int)) => 3
     rule rank(t(_, long-int)) => 4
     rule rank(t(_, unsigned-long-int)) => 4
     rule rank(t(_, long-long-int)) => 5
     rule rank(t(_, unsigned-long-long-int)) => 5
     rule rank(t(S:Set, enumType(_:Id))) => rank(t(S:Set, int))
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.1}{2}}}{
     The following may be used in an expression wherever an int or unsigned int may be used:
     \begin{itemize}

     \item An object or expression with an integer type (other than
     \cinline{int} or \cinline{unsigned int}) whose integer conversion rank is
     less than or equal to the rank of \cinline{int} and \cinline{unsigned
     int}.

     \item A bit-field of type \cinline{_Bool}, \cinline{int}, \cinline{signed
     int}, or \cinline{unsigned int}.

     \end{itemize}
     If an \cinline{int} can represent all values of the original type (as
     restricted by the width, for a bit-field), the value is converted to an
     \cinline{int}; otherwise, it is converted to an \cinline{unsigned int}.
     These are called the integer promotions. All other types are unchanged by
     the integer promotions.
     }*/
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.1}{3}}}{
     The integer promotions preserve value imports sign. As discussed earlier,
     whether a ``plain'' \cinline{char} is treated as signed is
     implementation-defined.
     }*/
     
     rule isPromoted(t(_, enumType(_:Id))) => true
     rule isPromoted(t(_, int)) => true
     rule isPromoted(t(_, unsigned-int)) => true
     rule isPromoted(t(_, long-int)) => true
     rule isPromoted(t(_, unsigned-long-int)) => true
     rule isPromoted(t(_, long-long-int)) => true
     rule isPromoted(t(_, unsigned-long-long-int)) => true
     
     rule isPromoted(t(_, bool)) => false
     rule isPromoted(t(_, signed-char)) => false
     rule isPromoted(t(_, unsigned-char)) => false
     rule isPromoted(t(_, short-int)) => false
     rule isPromoted(t(_, unsigned-short-int)) => false
     
     rule isPromoted(t(_, bitfieldType(_, _:Int))) => false
     
     rule [promote-unary]:
          L:KLabel(
               (tv(V:K, T:KResult) => tv(V:K, promote(T:KResult)))
          )
          when isArithUnaryOp(L:KLabel)
               andBool notBool isPromoted(T:KResult)
          [structural]
     rule [promote-binary-left]:
          L:KLabel(
               (tv(V:K, T:KResult) => tv(V:K, promote(T:KResult)))
               ,, _
          )
          when isArithBinOp(L:KLabel)
               andBool notBool isPromoted(T:KResult)
          [structural]
     rule [promote-binary-right]:
          L:KLabel(
               _,,
               (tv(V:K, T:KResult) => tv(V:K, promote(T:KResult)))
          ) 
          when isArithBinOp(L:KLabel)
               andBool notBool isPromoted(T:KResult)
          [structural]

          
     // <= so enums become ints
     rule [promote-lte-int-fits]:
          promote(T:KResult) => t(.Set, int)
          when rank(T:KResult) <=Int rank(t(.Set, int))
               andBool min(t(.Set, int)) <=Int min(T:KResult) 
               andBool max(t(.Set, int)) >=Int max(T:KResult)          

     rule [promote-gt-int]:
          promote(T:KResult) => T:KResult
          when rank(T:KResult) >Int rank(t(.Set, int))

     rule [promote-bitfield-fits]:
          promote(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int))) => t(.Set, int)
          when (T:K ==K bool orBool T:K ==K int orBool T:K ==K unsigned-int)
               andBool min(t(.Set, int)) <=Int min(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
               andBool max(t(.Set, int)) >=Int max(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
     // fixme unclear what 6.3.1.1:3 means

     rule [promote-lte-int-nofits]:
          promote(T:KResult) => t(.Set, unsigned-int)
          when rank(T:KResult) <=Int rank(t(.Set, int))
               andBool notBool (
                    min(t(.Set, int)) <=Int min(T:KResult) 
                    andBool max(t(.Set, int)) >=Int max(T:KResult)          
               )

     rule [promote-bitfield-nofits]:
          promote(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int))) => t(.Set, unsigned-int)
          when (T:K ==K bool orBool T:K ==K int orBool T:K ==K unsigned-int)
               andBool notBool (
                    min(t(.Set, int)) <=Int min(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
                    andBool max(t(.Set, int)) >=Int max(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
               )
     
     // fixme these could be done more cleanly

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.8}{1}}}{
     Many operators that expect operands of arithmetic type cause conversions
     and yield result types in a similar way. The purpose is to determine a
     common real type for the operands and result. For the specified operands,
     each operand is converted, without change of type domain, to a type whose
     corresponding real type is the common real type. Unless explicitly stated
     otherwise, the common real type is also the corresponding real type of the
     result, whose type domain is the type domain of the operands if they are
     the same, and complex otherwise. This pattern is called the usual
     arithmetic conversions:
     }*/
     rule L:KLabel(tv(V:K, T:KResult),, tv(V':K, T':KResult))
          => L:KLabel(cast(usualArithmeticConversion(T:KResult, T':KResult), tv(V:K, T:KResult)),, cast(usualArithmeticConversion(T:KResult, T':KResult), tv(V':K, T':KResult)))
          when isArithBinConversionOp(L:KLabel)
               andBool (hasIntegerType(T:KResult) orBool isFloatType(T:KResult))
               andBool (hasIntegerType(T':KResult) orBool isFloatType(T':KResult))
               andBool (T:KResult =/=K T':KResult)
          [structural]

     /*@ 
     \begin{itemize}
     \item First, if the corresponding real type of either operand is long
     double, the other operand is converted, without change of type domain, to
     a type whose corresponding real type is long double.
     \end{itemize}%
     */
     rule usualArithmeticConversion(t(_, long-double), _) => t(.Set, long-double)
     rule usualArithmeticConversion(_, t(_, long-double)) => t(.Set, long-double)
          
     /*@ 
     \begin{itemize}
     \item Otherwise, if the corresponding real type of either operand is
     double, the other operand is converted, without change of type domain, to
     a type whose corresponding real type is double.
     \end{itemize}%
     */
     rule usualArithmeticConversion(t(_, double), t(_, T:K)) => t(.Set, double)
          when long-double =/=K T:K
     rule usualArithmeticConversion(T:K, t(_, double)) => t(.Set, double)
          when long-double =/=K T:K
          
     /*@ 
     \begin{itemize}
     \item Otherwise, if the corresponding real type of either operand is
     float, the other operand is converted, without change of type domain, to a
     type whose corresponding real type is float.
     \end{itemize}%
     */
     rule usualArithmeticConversion(t(_, float), t(_, T:K)) => t(.Set, float)
          when long-double =/=K T:K
               andBool double =/=K T:K
     rule usualArithmeticConversion(t(_, T:K), t(_, float)) => t(.Set, float)
          when long-double =/=K T:K
               andBool double =/=K T:K

     /*@ 
     \begin{itemize}
     \item Otherwise, the integer promotions are performed on both operands.
     Then the following rules are applied to the promoted operands:
     \end{itemize}%
     */
     syntax K ::= "usualArithmeticConversion-aux" "(" K "," K ")" [function]
     
     rule usualArithmeticConversion(T:KResult, T':KResult)
          => usualArithmeticConversion-aux(promote(T:KResult), promote(T':KResult))
          when notBool isFloatType(T:KResult)
               andBool notBool isFloatType(T':KResult)
          
     /*@ 
     \begin{itemize}
     \item \ldots
     \begin{itemize}
     \item If both operands have the same type, then no further conversion is needed.
     \end{itemize}\end{itemize}%
     */
     rule [arithConversion-int-done]: usualArithmeticConversion-aux(T:KResult, T:KResult) => T:KResult
          
     rule [maxType-left]:
          maxType(T:KResult, T':KResult) => T:KResult
          when rank(T:KResult) >=Int rank(T':KResult) 
     rule [maxType-right]:
          maxType(T:KResult, T':KResult) => T':KResult
          when rank(T':KResult) >=Int rank(T:KResult) 
          
     /*@
     \begin{itemize}
     \item \ldots
     \begin{itemize}
     \item Otherwise, if both operands have signed integer types or both have
     unsigned integer types, the operand with the type of lesser integer
     conversion rank is converted to the type of the operand with greater rank.
     \end{itemize}\end{itemize}
     */
     rule [arithmeticConversion-same-signedness]:
          usualArithmeticConversion-aux(T:KResult, T':KResult) => maxType(T:KResult, T':KResult)
          when T:KResult =/=K T':KResult
               andBool hasSameSignedness(T:KResult, T':KResult)
          
     /*@
     \begin{itemize}
     \item \ldots
     \begin{itemize}
     \item Otherwise, if the operand that has unsigned integer type has rank
     greater or equal to the rank of the type of the other operand, then the
     operand with signed integer type is converted to the type of the operand
     with unsigned integer type.
     \end{itemize}\end{itemize}%
     */     
     rule [arithmeticConversion-unsigned-ge-right]:
          usualArithmeticConversion-aux(T:KResult, T':KResult) => T':KResult
          when hasSignedIntegerType(T:KResult) 
               andBool hasUnsignedIntegerType(T':KResult) 
               andBool rank(T':KResult) >=Int rank(T:KResult)
     rule [arithmeticConversion-unsigned-ge-left]:
          usualArithmeticConversion-aux(T:KResult, T':KResult) => T:KResult
          when hasUnsignedIntegerType(T:KResult) 
               andBool hasSignedIntegerType(T':KResult) 
               andBool rank(T:KResult) >=Int rank(T':KResult)
     
     /*@
     \begin{itemize}
     \item \ldots
     \begin{itemize}
     \item Otherwise, if the type of the operand with signed integer type can
     represent all of the values of the type of the operand with unsigned
     integer type, then the operand with unsigned integer type is converted to
     the type of the operand with signed integer type.
     \end{itemize}\end{itemize}%
     */
     rule [arithmeticConversion-signed-big-left]:
          usualArithmeticConversion-aux(T:KResult, T':KResult) => T:KResult
          when hasSignedIntegerType(T:KResult) 
               andBool hasUnsignedIntegerType(T':KResult) 
               andBool rank(T':KResult) <Int rank(T:KResult)
               andBool min(T:KResult) <=Int min(T':KResult)
               andBool max(T:KResult) >=Int max(T':KResult)
     rule [arithmeticConversion-signed-big-right]:
          usualArithmeticConversion-aux(T:KResult, T':KResult) => T':KResult
          when hasUnsignedIntegerType(T:KResult) 
               andBool hasSignedIntegerType(T':KResult) 
               andBool rank(T:KResult) <Int rank(T':KResult)
               andBool min(T':KResult) <=Int min(T:KResult)
               andBool max(T':KResult) >=Int max(T:KResult)
     
     /*@
     \begin{itemize}
     \item \ldots
     \begin{itemize}
     \item Otherwise, both operands are converted to the unsigned integer type
     corresponding to the type of the operand with signed integer type.
     \end{itemize}\end{itemize}%
     */
     rule [arithmeticConversion-to-unsigned-left]:
          usualArithmeticConversion-aux(T:KResult, T':KResult) => correspondingUnsignedType(T:KResult)
          when hasSignedIntegerType(T:KResult) 
               andBool hasUnsignedIntegerType(T':KResult) 
               andBool rank(T':KResult) <Int rank(T:KResult)
               andBool (min(T:KResult) >Int min(T':KResult) orBool max(T:KResult) <Int max(T':KResult))
     rule [arithmeticConversion-to-unsigned-right]:
          usualArithmeticConversion-aux(T:KResult, T':KResult) => correspondingUnsignedType(T':KResult)
          when hasUnsignedIntegerType(T:KResult) 
               andBool hasSignedIntegerType(T':KResult) 
               andBool rank(T:KResult) <Int rank(T':KResult)
               andBool (min(T':KResult) >Int min(T:KResult) orBool max(T':KResult) <Int max(T:KResult))
          
endmodule

module DYNAMIC-SEMANTICS-CONVERSION
     imports DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE
     
     //- switch assumes casts can happen anywhere
     rule cast(T:KResult, tv(L:KList, T:KResult)) => tv(L:KList, T:KResult)
          [anywhere]
          
     rule cast(t(S:Set, T:K), tv(L:KList, t(_, T:K))) => tv(L:KList, t(S:Set, T:K))
          [anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.2}{1}}}{
     When any scalar value is converted to \cinline{_Bool}, the result is 0 if
     the value compares equal to 0; otherwise, the result is 1.
     }*/
     // cleanme only need one rule
     // fixme worried about qualifiers
     rule [cast-integer-to-bool]:
          cast(t(S:Set, bool), tv(I:Int, T:KResult))
               => #if I:Int ==Int 0 #then tv(0, t(S:Set, bool)) #else tv(1, t(S:Set, bool)) #fi
          when hasIntegerType(T:KResult)
          [anywhere]
     rule [cast-non-integer-to-bool]:
          cast(t(S:Set, bool), tv(L:KList, T:KResult)) 
               => cast(t(S:Set, bool), tv(0, t(.Set, int)) != tv(L:KList, T:KResult))
          when notBool hasIntegerType(T:KResult)
          [anywhere]
     
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{1}}}{
     When a value with integer type is converted to another integer type other
     than \cinline{_Bool}, if the value can be represented by the new type, it
     is unchanged.
     }*/
     rule [cast-integer-no-value-change]:
          cast(T:KResult, tv(I:Int, T':KResult)) => tv(I:Int, T:KResult)
          when (min(T:KResult) <=Int I:Int) 
               andBool (max(T:KResult) >=Int I:Int)
               andBool hasIntegerType(T':KResult)
               andBool hasIntegerType(T:KResult)
               andBool notBool isBoolType (T:KResult)
          [anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{2}}}{
     Otherwise, if the new type is unsigned, the value is converted by
     repeatedly adding or subtracting one more than the maximum value that can
     be represented in the new type until the value is in the range of the new
     type.
     }*/
     rule [cast-ubitfield-of-small]:
          cast(T:KResult, tv(I:Int, T':KResult)) 
               => cast(T:KResult, tv(I:Int +Int max(T:KResult) +Int 1, T':KResult))
          when isBitfieldType(T:KResult)
               andBool (I:Int <Int min(T:KResult))
               andBool hasIntegerType(T':KResult)
               andBool hasUnsignedIntegerType(innerType(T:KResult))
          [anywhere]
     rule [cast-uchar-of-small]:
          cast(t(S:Set, unsigned-char), tv(I:Int, T':KResult)) 
               => cast(t(S:Set, unsigned-char), tv(I:Int +Int max(t(S:Set, unsigned-char)) +Int 1, T':KResult))
          when (I:Int <Int min(t(S:Set, unsigned-char)))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-usint-of-small]:
          cast(t(S:Set, unsigned-short-int), tv(I:Int, T':KResult)) 
               => cast(t(S:Set, unsigned-short-int), tv(I:Int +Int max(t(S:Set, unsigned-short-int)) +Int 1, T':KResult))
          when (I:Int <Int min(t(S:Set, unsigned-short-int)))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-uint-of-small]:
          cast(t(S:Set, unsigned-int), tv(I:Int, T':KResult)) 
               => cast(t(S:Set, unsigned-int), tv(I:Int +Int max(t(S:Set, unsigned-int)) +Int 1, T':KResult))
          when (I:Int <Int min(t(S:Set, unsigned-int)))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-ulong-of-small]:
          cast(t(S:Set, unsigned-long-int), tv(I:Int, T':KResult)) 
               => cast(t(S:Set, unsigned-long-int), tv(I:Int +Int max(t(S:Set, unsigned-long-int)) +Int 1, T':KResult))
          when (I:Int <Int min(t(S:Set, unsigned-long-int)))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-ullong-of-small]:
          cast(t(S:Set, unsigned-long-long-int), tv(I:Int, T':KResult)) 
               => cast(t(S:Set, unsigned-long-long-int), tv(I:Int +Int max(t(S:Set, unsigned-long-long-int)) +Int 1, T':KResult))
          when (I:Int <Int min(t(S:Set, unsigned-long-long-int)))
               andBool hasIntegerType(T':KResult)          
          [anywhere]
     
     rule [cast-ubitfield-of-big]:
          cast(T:KResult, tv(I:Int, T':KResult)) 
               => tv(I:Int %Int (max(T:KResult) +Int 1), T:KResult)
          when isBitfieldType(T:KResult)
               andBool (I:Int >Int max(T:KResult))
               andBool hasIntegerType(T':KResult)
               andBool hasUnsignedIntegerType(innerType(T:KResult))
          [anywhere]
     rule [cast-uchar-of-big]:
          cast(t(S:Set, unsigned-char), tv(I:Int, T':Type)) 
               => tv(I %Int (max(t(S, unsigned-char)) +Int 1), t(S, unsigned-char))
          when (I >Int max(t(S, unsigned-char)))
               andBool hasIntegerType(T')
          [anywhere]
     rule [cast-usint-of-big]:
          cast(t(S:Set, unsigned-short-int), tv(I:Int, T':KResult)) 
               => tv(I:Int %Int (max(t(S:Set, unsigned-short-int)) +Int 1), t(S:Set, unsigned-short-int))
          when (I:Int >Int max(t(S:Set, unsigned-short-int)))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-uint-of-big]:
          cast(t(S:Set, unsigned-int), tv(I:Int, T':KResult)) 
               => tv(I:Int %Int (max(t(S:Set, unsigned-int)) +Int 1), t(S:Set, unsigned-int))
          when (I:Int >Int max(t(S:Set, unsigned-int)))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-ulong-of-big]:
          cast(t(S:Set, unsigned-long-int), tv(I:Int, T':KResult)) 
               => tv(I:Int %Int (max(t(S:Set, unsigned-long-int)) +Int 1), t(S:Set, unsigned-long-int))
          when (I:Int >Int max(t(S:Set, unsigned-long-int)))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-ullong-of-big]:
          cast(t(S:Set, unsigned-long-long-int), tv(I:Int, T':KResult)) 
               => tv(I:Int %Int (max(t(S:Set, unsigned-long-long-int)) +Int 1), t(S:Set, unsigned-long-long-int))
          when (I:Int >Int max(t(S:Set, unsigned-long-long-int)))
               andBool hasIntegerType(T':KResult)
          [anywhere]

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.3}{3}}}{
     Otherwise, the new type is signed and the value cannot be represented in
     it; either the result is implementation-defined or an
     implementation-defined signal is raised.
     }*/
     // choice
     rule [cast-sbitfield-of-huge]:
          cast(T:KResult, tv(I:Int, T':KResult)) 
               => cast(T:KResult, tv(I:Int %Int (2 ^Int absInt(numBits(T:KResult))), T':KResult)) 
          when isBitfieldType(T:KResult)
               andBool (absInt(I:Int) >Int (2 ^Int absInt(numBits(T:KResult))))
               andBool hasIntegerType(T':KResult)
               andBool hasSignedIntegerType(innerType(T:KResult))
          [anywhere]
     rule [cast-schar-of-huge]:
          cast(t(S:Set, signed-char), tv(I:Int, T':KResult)) 
               => cast(t(S:Set, signed-char), tv(I:Int %Int (2 ^Int absInt(numBits(t(S:Set, signed-char)))), T':KResult)) 
          when (absInt(I:Int) >Int (2 ^Int absInt(numBits(t(S:Set, signed-char)))))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-sint-of-huge]:
          cast(t(S:Set, short-int), tv(I:Int, T':KResult)) 
               => cast(t(S:Set, short-int), tv(I:Int %Int (2 ^Int absInt(numBits(t(S:Set, short-int)))), T':KResult)) 
          when (absInt(I:Int) >Int (2 ^Int absInt(numBits(t(S:Set, short-int)))))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-int-of-huge]:
          cast(t(S:Set, int), tv(I:Int, T':KResult)) 
               => cast(t(S:Set, int), tv(I:Int %Int (2 ^Int absInt(numBits(t(S:Set, int)))), T':KResult)) 
          when (absInt(I:Int) >Int (2 ^Int absInt(numBits(t(S:Set, int)))))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-long-of-huge]:
          cast(t(S:Set, long-int), tv(I:Int, T':KResult)) 
               => cast(t(S:Set, long-int), tv(I:Int %Int (2 ^Int absInt(numBits(t(S:Set, long-int)))), T':KResult)) 
          when (absInt(I:Int) >Int (2 ^Int absInt(numBits(t(S:Set, long-int)))))
               andBool hasIntegerType(T':KResult)
          [anywhere]
     rule [cast-llong-of-huge]:
          cast(t(S:Set, long-long-int), tv(I:Int, T':KResult))
               => cast(t(S:Set, long-long-int), tv(I:Int %Int (2 ^Int absInt(numBits(t(S:Set, long-long-int)))), T':KResult)) 
          when (absInt(I:Int) >Int (2 ^Int absInt(numBits(t(S:Set, long-long-int)))))
               andBool hasIntegerType(T':KResult)
          [anywhere]
          
     rule [cast-signed-of-small]:
          cast(T:Type, tv(I:Int, T':Type))
               => tv(I +Int (2 ^Int absInt(numBits(T))), T)
          when (I <Int min(T))
               andBool (absInt(I) <=Int (2 ^Int absInt(numBits(T))))
               andBool hasSignedIntegerType(T)
               andBool hasIntegerType(T')
               andBool notBool isBoolType (T)
          [structural, anywhere] 
     rule [cast-signed-of-big]:
          cast(T:Type, tv(I:Int, T':Type)) 
               => tv(I -Int (2 ^Int absInt(numBits(T))), T)
          when (I >Int max(T))
               andBool (absInt(I) <=Int (2 ^Int absInt(numBits(T))))
               andBool hasSignedIntegerType(T)
               andBool hasIntegerType(T')
               andBool notBool isBoolType (T)
          [anywhere]

     // this is starting to get into sketchy land
     rule [cast-unknown-integer]:
          cast(T:Type, tv(piece(unknown(Len:Int), Len:Int), T':Type)) 
               => tv(piece(unknown(value(bitSizeofType(T))), value(bitSizeofType(T))), T)
          when hasIntegerType(T)
               andBool hasIntegerType(T')
          [anywhere]
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.4}{1}}}{
     When a finite value of real floating type is converted to an integer type
     other than \cinline{_Bool}, the fractional part is discarded (i.e., the
     value is truncated toward zero). If the value of the integral part cannot
     be represented by the integer type, the behavior is undefined.
     }*/
     // fixme
     rule cast(T:KResult, tv(V:Float, t(S:Set, double))) 
               => cast(T:KResult, tv(Float2Int(V:Float), t(S:Set, long-long-int)))
          when hasIntegerType(T:KResult)
               andBool notBool isBoolType (T:KResult)
          [anywhere]
     rule cast(T:KResult, tv(V:Float, t(S:Set, float))) 
               => cast(T:KResult, tv(Float2Int(V:Float), t(S:Set, long-long-int)))
          when hasIntegerType(T:KResult)
               andBool notBool isBoolType (T:KResult)
          [anywhere]
     rule cast(T:KResult, tv(V:Float, t(S:Set, long-double))) 
               => cast(T:KResult, tv(Float2Int(V:Float), t(S:Set, long-long-int)))
          when hasIntegerType(T:KResult)
               andBool notBool isBoolType (T:KResult)
          [anywhere]
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.4}{2}}}{
     When a value of integer type is converted to a real floating type, if the
     value being converted can be represented exactly in the new type, it is
     unchanged. If the value being converted is in the range of values that can
     be represented but cannot be represented exactly, the result is either the
     nearest higher or nearest lower representable value, chosen in an
     implementation-defined manner. If the value being converted is outside the
     range of values that can be represented, the behavior is undefined.
     Results of some implicit conversions may be represented in greater range
     and precision than that required by the new type (see 6.3.1.8 and
     6.8.6.4).
     }*/
     rule [cast-int-to-float]:
          cast(t(S:Set, float), tv(I:Int, T:KResult)) 
               => tv(Int2Float(I:Int), t(S:Set, float))
          when hasIntegerType(T:KResult)
          [anywhere]
     rule [cast-int-to-double]:
          cast(t(S:Set, double), tv(I:Int, T:KResult)) 
               => tv(Int2Float(I:Int), t(S:Set, double))
          when hasIntegerType(T:KResult)
          [anywhere]
     rule [cast-int-to-long-double]:
          cast(t(S:Set, long-double), tv(I:Int, T:KResult)) 
               => tv(Int2Float(I:Int), t(S:Set, long-double))
          when hasIntegerType(T:KResult)
          [anywhere]
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.1.5}{2}}}{
     When a value of real floating type is converted to a real floating type,
     if the value being converted can be represented exactly in the new type,
     it is unchanged. If the value being converted is in the range of values
     that can be represented but cannot be represented exactly, the result is
     either the nearest higher or nearest lower representable value, chosen in
     an implementation-defined manner. If the value being converted is outside
     the range of values that can be represented, the behavior is undefined.
     Results of some implicit conversions may be represented in greater range
     and precision than that required by the new type (see 6.3.1.8 and
     6.8.6.4).
     }*/
     // fixme all floats same precision
     rule cast(t(S:Set, T':K), tv(F:Float, t(_, T:K))) 
               => tv(F:Float, t(S:Set, T':K))
          when (T:K ==K float orBool T:K ==K double orBool T:K ==K long-double)
               andBool (T':K ==K float orBool T':K ==K double orBool T':K ==K long-double)
          [anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.2}{1}}}{
     The (nonexistent) value of a void expression (an expression that has type
     \cinline{void}) shall not be used in any way, and implicit or explicit
     conversions (except to \cinline{void}) shall not be applied to such an
     expression. If an expression of any other type is evaluated as a void
     expression, its value or designator is discarded. (A void expression is
     evaluated for its side effects.)
     }*/     
     rule cast(t(_, void), _:KResult) => skipval
          [anywhere]
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{1--2}}}{
     A pointer to void may be converted to or from a pointer to any object
     type. A pointer to any object type may be converted to a pointer to void
     and back again; the result shall compare equal to the original pointer.

     For any qualifier $q$, a pointer to a non-$q$-qualified type may be
     converted to a pointer to the $q$-qualified version of the type; the
     values stored in the original and converted pointers shall compare equal.
     }*/

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{3}}}{
     An integer constant expression with the value 0, or such an expression
     cast to type \cinline{void *}, is called a null pointer constant. If a
     null pointer constant is converted to a pointer type, the resulting
     pointer, called a null pointer, is guaranteed to compare unequal to a
     pointer to any object or function.
     }*/
     rule cast(t(S:Set, pointerType(T:KResult)), tv(N:Int, T':KResult)) 
               => tv(NullPointer, t(S:Set, pointerType(T:KResult)))
          when hasIntegerType(T':KResult)
               andBool N:Int ==K NullPointerConstant
          [anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{4}}}{
     Conversion of a null pointer to another pointer type yields a null pointer
     of that type. Any two null pointers shall compare equal.
     }*/
     
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{5}}}{
     An integer may be converted to any pointer type. Except as previously
     specified, the result is implementation-defined, might not be correctly
     aligned, might not point to an entity of the referenced type, and might be
     a trap representation.
     }*/
     // choice implementation defined behavior
     rule cast(t(S:Set, pointerType(T:KResult)), tv(N:Int, T':KResult)) 
               => tv(N:Int, t(S:Set, pointerType(T:KResult)))
          when hasIntegerType(T':KResult)
               andBool N:Int =/=K NullPointerConstant
          [anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{6}}}{
     Any pointer type may be converted to an integer type. Except as previously
     specified, the result is implementation-defined. If the result cannot be
     represented in the integer type, the behavior is undefined. The result
     need not be in the range of values of any integer type.
     }*/
     // fixme needs to check size
     rule cast(T:KResult, tv(N:Int, t(_, pointerType(_))))
               => tv(N:Int, T:KResult)
          when hasIntegerType(T:KResult)
               andBool notBool isBoolType (T:KResult)
          [anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{7}}}{
     A pointer to an object type may be converted to a pointer to a different
     object type. If the resulting pointer is not correctly aligned for the
     referenced type, the behavior is undefined. Otherwise, when converted back
     again, the result shall compare equal to the original pointer. When a
     pointer to an object is converted to a pointer to a character type, the
     result points to the lowest addressed byte of the object. Successive
     increments of the result, up to the size of the object, yield pointers to
     the remaining bytes of the object.
     }*/
     /*@ \fromStandard{\source[n1570]{\para{6.3.2.3}{8}}}{
     A pointer to a function of one type may be converted to a pointer to a
     function of another type and back again; the result shall compare equal to
     the original pointer. If a converted pointer is used to call a function
     whose type is not compatible with the referenced type, the behavior is
     undefined.
     }*/
     // fixme
     // possibly not true with other endiannesses
     // choice
     // needs to handle alignment
     rule cast(t(S:Set, pointerType(T:KResult)), tv(Loc:SymLoc, t(_, pointerType(_)))) 
               => tv(Loc:SymLoc, t(S:Set, pointerType(T:KResult)))
          [anywhere]
endmodule

module DYNAMIC-SEMANTICS-CONVERSIONS-MISC
     imports DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE

     // fixme not sure about this
     // interpret is used to "cast" values read from memory
     // shouldn't need to do the < min one since values start positive
     syntax K ::= "interpret-aux" "(" Type "," K ")" [function]
     
     rule [interpret-start]:
          interpret(T:Type, piece(N:Int, _)) => interpret-aux(T, N)
          when N >=Int 0
     
     rule [interpret-done]:
          interpret-aux(T:Type, I:Int) => tv(I, T)
          when (min(T) <=Int I) 
               andBool (max(T) >=Int I)
               andBool hasIntegerType(T)
     rule [interpret-too-big]:
          interpret-aux(T:Type, I:Int) => interpret-aux(T, I:Int -Int (2 ^Int absInt(numBits(T))))
          when (I:Int >Int max(T))
               andBool hasIntegerType(T)
          
     rule [arithInterpret-done]:
          arithInterpret(T:Type, I:Int) => tv(I, T)
          when (min(T) <=Int I) 
               andBool (max(T) >=Int I)
               andBool hasIntegerType(T)
          
     rule [arithInterpret-unknown]:
          arithInterpret(T:Type, piece(unknown(N:Int), N:Int)) => tv(piece(unknown(N:Int), N:Int), T)
          
     // these could be so much better...
     rule ~Bits X:Int => ~Int X
     rule [bnot-unknown]: ~Bits piece(unknown(Len:Int), Len:Int) => piece(unknown(Len:Int), Len:Int)
     
     rule X:Int /Bits Y:Int => X /Int Y

     rule X:Int xorBits Y:Int => X xorInt Y
     rule [xor-unknown-right]: N:Bits xorBits piece(unknown(Len:Int), Len:Int) => piece(unknown(Len:Int), Len:Int)
     rule [xor-unknown-left]: piece(unknown(Len:Int), Len:Int) xorBits N:Bits => piece(unknown(Len:Int), Len:Int)

     rule X:Int |Bits Y:Int => X |Int Y
     rule [or-unknown-right]: N:Bits |Bits piece(unknown(Len:Int), Len:Int) => piece(unknown(Len:Int), Len:Int)
     rule [or-unknown-left]: piece(unknown(Len:Int), Len:Int) |Bits N:Bits => piece(unknown(Len:Int), Len:Int)

     rule X:Int &Bits Y:Int => X &Int Y
     rule [and-unknown-zero-right]: N:Int &Bits piece(unknown(Len:Int), Len) => 0
          when N ==Int 0 
     rule [and-unknown-right]: N:Int &Bits piece(unknown(Len:Int), Len) => 0
          when N =/=Int 0 
     rule [and-unknown-zero-left]: piece(unknown(Len:Int), Len) &Bits N:Int => 0
          when N ==Int 0 
     rule [and-unknown-left]: piece(unknown(Len:Int), Len) &Bits N:Int => 0
          when N =/=Int 0
     
     // fixme
     rule [arithInterpret-float]: 
          arithInterpret(t(S:Set, T:K), F:Float) => tv(F:Float, t(S:Set, T:K))
          when (T:K ==K double)
               orBool (T:K ==K float)
               orBool (T:K ==K long-double)
     // signed arithmetic isn't supposed to overflow
     rule [arithInterpret-unsigned-big]:
          arithInterpret(T:Type, I:Int) => tv(I:Int %Int (max(T) +Int 1), T)
          when hasUnsignedIntegerType(T)
               andBool (I:Int >Int max(T))
     rule [arithInterpret-unsigned-small]:
          arithInterpret(T:Type, I:Int) 
          => arithInterpret(T, (I:Int %Int (max(T) +Int 1)) +Int (max(T) +Int 1))
          //=> tv((I:Int %Int (max(T:KResult) +Int 1)) +Int (max(T:KResult) +Int 1), T:KResult)
          when hasUnsignedIntegerType(T)
               andBool (I:Int <Int min(T))
          // must be like this so ((unsigned int)(~((unsigned int)~0)) != 0) will work, but not sure why

     // rule integerTypes => signedIntegerTypes unsignedIntegerTypes [structural]
     rule unsignedIntegerTypes => 
          SetItem(bool)
          SetItem(unsigned-char)
          SetItem(unsigned-short-int)
          SetItem(unsigned-int)
          SetItem(unsigned-long-int)
          SetItem(unsigned-long-long-int)
     rule signedIntegerTypes => 
          SetItem(char)
          SetItem(signed-char)
          SetItem(short-int)
          SetItem(int)
          SetItem(long-int)
          SetItem(long-long-int)

endmodule

module DYNAMIC-C-CONVERSIONS
     imports DYNAMIC-SEMANTICS-CONVERSIONS-INCLUDE
     imports DYNAMIC-SEMANTICS-CONVERSIONS-HELPERS
     imports DYNAMIC-SEMANTICS-CONVERSION
     imports DYNAMIC-SEMANTICS-PROMOTIONS 
     imports DYNAMIC-SEMANTICS-CONVERSIONS-MISC
endmodule
