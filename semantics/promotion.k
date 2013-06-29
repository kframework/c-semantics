module C-PROMOTION-SYNTAX
     // should be K, but is Type for efficiency reasons
     syntax Type ::= promote(K) [function]
     syntax K ::= argPromote(K) [function]
     syntax Bool ::= isArithBinConversionOp(KLabel) [function]
     syntax Bool ::= isArithUnaryOp(KLabel) [function]
     syntax K ::= "usualArithmeticConversion" "(" Type "," Type ")" [function]
     syntax Bool ::= isPromoted(Type) [function]

     syntax Int ::= rank(Type) [function]
endmodule

module C-PROMOTION
     imports C-PROMOTION-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-COMPAT-SYNTAX

     syntax Type ::= "maxType" "(" Type "," Type ")" [function]

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
     rule [argPromote-float]: argPromote(t(_, float))
          => t(.Set, double)
     rule [argPromote-double]: argPromote(t(_, double))
          => t(.Set, double)
     rule [argPromote-long-double]: argPromote(t(_, long-double))
          => t(.Set, long-double)
     rule [argPromote-integer]: argPromote(T:KResult)
          => promote(T:KResult)
          when hasIntegerType(T:KResult)

     syntax Bool ::= isArithBinOp(KLabel) [function]

     syntax Set ::= "arithBinOps" [function]
     syntax Set ::= "arithBinConversionOps" [function]

     rule [arithBinOps]:
          arithBinOps
          => arithBinConversionOps (SetItem(l('_<<_)) SetItem(l('_>>_)))
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
     
     rule [checkArithBinOp]:
          isArithBinOp(KL:KLabel) 
          => #if l(KL:KLabel) in arithBinOps #then true #else false #fi 
          [structural]
     rule [checkArithBinConversionOp]:
          isArithBinConversionOp(KL:KLabel) 
          => #if l(KL:KLabel) in arithBinConversionOps #then true #else false #fi 
          [structural]

     syntax Set ::= "arithUnaryOps" [function]// [memo] 
     rule [arithUnaryOps]: arithUnaryOps => 
          SetItem(l('-_))
          SetItem(l('+_))
          SetItem(l('~_))

     rule [checkArithUnaryOp]: 
          isArithUnaryOp(KL:KLabel) 
          => #if l(KL:KLabel) in arithUnaryOps #then true #else false #fi 
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
     The following may be used in an expression wherever an int or unsigned int
     may be used:
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
          promote(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
          => t(.Set, int)
          when ((T:K ==K bool) orBool (T:K ==K int) 
                    orBool (T:K ==K unsigned-int))
               andBool min(t(.Set, int)) 
                    <=Int min(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
               andBool max(t(.Set, int)) 
                    >=Int max(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
     // fixme unclear what 6.3.1.1:3 means

     rule [promote-lte-int-nofits]:
          promote(T:KResult) => t(.Set, unsigned-int)
          when rank(T:KResult) <=Int rank(t(.Set, int))
               andBool notBool (
                    min(t(.Set, int)) <=Int min(T:KResult) 
                    andBool max(t(.Set, int)) >=Int max(T:KResult)          
               )

     rule [promote-bitfield-nofits]:
          promote(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
          => t(.Set, unsigned-int)
          when (T:K ==K bool orBool T:K ==K int orBool T:K ==K unsigned-int)
               andBool notBool (
                    min(t(.Set, int))
                         <=Int min(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
                    andBool max(t(.Set, int))
                         >=Int max(t(S:Set, bitfieldType(t(S':Set, T:K), Len:Int)))
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
          => L:KLabel(cast(
               usualArithmeticConversion(T:KResult, T':KResult), tv(V:K, T:KResult)),, 
               cast(usualArithmeticConversion(T:KResult, T':KResult), tv(V':K, T':KResult)))
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
     rule [arithConversion-int-done]:
          usualArithmeticConversion-aux(T:KResult, T:KResult)
          => T:KResult
          
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
          usualArithmeticConversion-aux(T:KResult, T':KResult)
          => maxType(T:KResult, T':KResult)
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
          usualArithmeticConversion-aux(T:KResult, T':KResult)
          => correspondingUnsignedType(T:KResult)
          when hasSignedIntegerType(T:KResult) 
               andBool hasUnsignedIntegerType(T':KResult) 
               andBool rank(T':KResult) <Int rank(T:KResult)
               andBool (min(T:KResult) >Int min(T':KResult) 
                    orBool max(T:KResult) <Int max(T':KResult))
     rule [arithmeticConversion-to-unsigned-right]:
          usualArithmeticConversion-aux(T:KResult, T':KResult)
          => correspondingUnsignedType(T':KResult)
          when hasUnsignedIntegerType(T:KResult) 
               andBool hasSignedIntegerType(T':KResult) 
               andBool rank(T:KResult) <Int rank(T':KResult)
               andBool (min(T':KResult) >Int min(T:KResult) 
                    orBool max(T':KResult) <Int max(T:KResult))
          
endmodule

