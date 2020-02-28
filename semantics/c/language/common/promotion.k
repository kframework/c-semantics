module C-COMMON-PROMOTION-SYNTAX
     imports LIST

     // should be K, but is Type for efficiency reasons
     syntax UType ::= promote(UType) [function]
     syntax UType ::= usualArithmeticConversion(UType, UType) [function]
     syntax Bool ::= isPromoted(UType) [function]
     syntax Bool ::= areArgPromoted(List) [function]
     syntax UType ::= argPromoteType(UType) [function]
endmodule

module C-COMMON-PROMOTION
     imports C-COMMON-PROMOTION-SYNTAX
     imports BOOL
     imports INT
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX

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
     syntax Int ::= rank(UType) [function]
     rule rank(ut(_, bool)) => 0
     rule rank(ut(_, _:SimpleSignedCharType)) => 1
     rule rank(ut(_, _:SimpleUnsignedCharType)) => 1
     rule rank(ut(_, short-int)) => 2
     rule rank(ut(_, unsigned-short-int)) => 2
     rule rank(ut(_, int)) => 3
     rule rank(ut(_, signed-int)) => 3
     rule rank(ut(_, unsigned-int)) => 3
     rule rank(ut(_, long-int)) => 4
     rule rank(ut(_, unsigned-long-int)) => 4
     rule rank(ut(_, long-long-int)) => 5
     rule rank(ut(_, unsigned-long-long-int)) => 5
     rule rank(ut(_, oversized-int)) => 6
     rule rank(ut(_, unsigned-oversized-int)) => 6
     rule rank(ut(_, enumType(S::TagId))) => rank(utype(getEnumAlias(S)))
     rule rank(ut(_, bitfieldType(T::SimpleType, _))) => rank(utype(T))

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

     // Although isPromoted doesn't make sense for non-integer types, it makes
     // things more convenient if it's total.
     rule isPromoted(ut(_, enumType(_))) => true
     rule isPromoted(ut(_, int)) => true
     rule isPromoted(ut(_, signed-int)) => true
     rule isPromoted(ut(_, unsigned-int)) => true
     rule isPromoted(ut(_, long-int)) => true
     rule isPromoted(ut(_, unsigned-long-int)) => true
     rule isPromoted(ut(_, long-long-int)) => true
     rule isPromoted(ut(_, unsigned-long-long-int)) => true
     rule isPromoted(ut(_, oversized-int)) => true
     rule isPromoted(ut(_, unsigned-oversized-int)) => true
     rule isPromoted(_) => false [owise]

     // <= so enums become ints
     rule promote(T::UType) => utype(int)
          requires rank(T) <=Int rank(utype(int))
               andBool min(utype(int)) <=Int min(T)
               andBool max(utype(int)) >=Int max(T)

     rule promote(T::UType) => stripBitfield(T)
          requires rank(T) >Int rank(utype(int))

     syntax UType ::= stripBitfield(UType) [function]

     rule stripBitfield(ut(_, bitfieldType(T::SimpleType, _))) => utype(T)
     rule stripBitfield(T::UType) => T [owise]

     rule promote(ut(Mods::Set, bitfieldType(T::SimpleType, Len::Int)))
          => utype(int)
          requires ((T ==K bool) orBool isSimpleIntType(T) orBool (T ==K unsigned-int))
               andBool min(utype(int))
                    <=Int min(utype(bitfieldType(T, Len)))
               andBool max(utype(int))
                    >=Int max(utype(bitfieldType(T, Len)))
     // fixme unclear what 6.3.1.1:3 means

     rule promote(T::UType) => utype(unsigned-int)
          requires rank(T) <=Int rank(utype(int))
               andBool notBool (
                    min(utype(int)) <=Int min(T)
                    andBool max(utype(int)) >=Int max(T)
               )

     rule promote(ut(Mods::Set, bitfieldType(T::SimpleType, Len::Int)))
          => utype(unsigned-int)
          requires (T ==K bool orBool isSimpleIntType(T) orBool T ==K unsigned-int)
               andBool notBool (
                    min(utype(int))
                         <=Int min(utype(bitfieldType(T, Len)))
                    andBool max(utype(int))
                         >=Int max(utype(bitfieldType(T, Len)))
               )


     /*@
     \begin{itemize}
     \item First, if the corresponding real type of either operand is long
     double, the other operand is converted, without change of type domain, to
     a type whose corresponding real type is long double.
     \end{itemize}%
     */
     rule usualArithmeticConversion(ut(_, long-double), _)
          => utype(long-double)
     rule usualArithmeticConversion(_, ut(_, long-double))
          => utype(long-double)

     /*@
     \begin{itemize}
     \item Otherwise, if the corresponding real type of either operand is
     double, the other operand is converted, without change of type domain, to
     a type whose corresponding real type is double.
     \end{itemize}%
     */
     rule usualArithmeticConversion(ut(_, double), ut(_, T::SimpleUType))
          => utype(double)
          requires long-double =/=K T
     rule usualArithmeticConversion(ut(_, T::SimpleUType), ut(_, double))
          => utype(double)
          requires long-double =/=K T

     /*@
     \begin{itemize}
     \item Otherwise, if the corresponding real type of either operand is
     float, the other operand is converted, without change of type domain, to a
     type whose corresponding real type is float.
     \end{itemize}%
     */
     rule usualArithmeticConversion(ut(_, float), ut(_, T::SimpleUType))
          => utype(float)
          requires long-double =/=K T andBool double =/=K T
     rule usualArithmeticConversion(ut(_, T::SimpleUType), ut(_, float))
          => utype(float)
          requires long-double =/=K T andBool double =/=K T

     /*@
     \begin{itemize}
     \item Otherwise, the integer promotions are performed on both operands.
     Then the following rules are applied to the promoted operands:
     \end{itemize}%
     */
     syntax UType ::= "usualArithmeticConversion-aux" "(" UType "," UType ")"
          [function]

     rule usualArithmeticConversion(T::UType, T'::UType)
          => usualArithmeticConversion-aux(promote(T), promote(T'))
          requires notBool isFloatUType(T)
               andBool notBool isFloatUType(T')

     /*@
     \begin{itemize}
     \item \ldots
     \begin{itemize}
     \item If both operands have the same type, then no further conversion is needed.
     \end{itemize}\end{itemize}%
     */
     rule [arithConversion-int-done]:
          usualArithmeticConversion-aux(T::UType, T'::UType)
          => stripConstants(T)
          requires T ==Type T'

     syntax UType ::= maxType(UType, UType) [function]
     rule maxType(T::UType, T'::UType) => T
          requires rank(T) >=Int rank(T')
     rule maxType(T::UType, T'::UType) => T'
          requires rank(T') >=Int rank(T)

     /*@
     \begin{itemize}
     \item \ldots
     \begin{itemize}
     \item Otherwise, if both operands have signed integer types or both have
     unsigned integer types, the operand with the type of lesser integer
     conversion rank is converted to the type of the operand with greater rank.
     \end{itemize}\end{itemize}
     */
     rule usualArithmeticConversion-aux(T::UType, T'::UType)
          => maxType(T, T')
          requires T =/=Type T' andBool hasSameSignedness(T, T')

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
     rule usualArithmeticConversion-aux(signedIntegerUType #as T::UType, unsignedIntegerUType #as T'::UType) => T'
          requires rank(T') >=Int rank(T)
     rule usualArithmeticConversion-aux(unsignedIntegerUType #as T::UType, signedIntegerUType #as T'::UType) => T
          requires rank(T) >=Int rank(T')

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
     rule usualArithmeticConversion-aux(signedIntegerUType #as T::UType, unsignedIntegerUType #as T'::UType) => T
          requires rank(T') <Int rank(T)
               andBool min(T) <=Int min(T')
               andBool max(T) >=Int max(T')
     rule usualArithmeticConversion-aux(unsignedIntegerUType #as T::UType, signedIntegerUType #as T'::UType) => T'
          requires rank(T) <Int rank(T')
               andBool min(T') <=Int min(T)
               andBool max(T') >=Int max(T)

     /*@
     \begin{itemize}
     \item \ldots
     \begin{itemize}
     \item Otherwise, both operands are converted to the unsigned integer type
     corresponding to the type of the operand with signed integer type.
     \end{itemize}\end{itemize}%
     */
     rule usualArithmeticConversion-aux(signedIntegerUType #as T::UType, unsignedIntegerUType #as T'::UType)
          => correspondingUnsignedType(T)
          requires rank(T') <Int rank(T)
               andBool (min(T) >Int min(T')
                    orBool max(T) <Int max(T'))
     rule usualArithmeticConversion-aux(unsignedIntegerUType #as T::UType, signedIntegerUType #as T'::UType)
          => correspondingUnsignedType(T')
          requires rank(T) <Int rank(T')
               andBool (min(T') >Int min(T)
                    orBool max(T') <Int max(T))

     // "integer promotions" are used when doing arithmetic conversions, and
     // for unary ~, +, - "usual arithmetic conversions" are used when doing
     // binary arithmetic on numbers, and are used to find a common type there
     // is another set of promotions called "default argument promotions" used
     // when calling functions where the type information is not complete. This
     // is equivalent to integer promotions + (float => double)
     rule argPromoteType(ut(Mods:Set, float))
          => ut(Mods, double)
     rule argPromoteType(ut(Mods:Set, double))
          => ut(Mods, double)
     rule argPromoteType(ut(Mods:Set, long-double))
          => ut(Mods, long-double)
     rule argPromoteType(ut(Mods:Set, oversized-float))
          => ut(Mods, oversized-float)
     rule argPromoteType(integerUType #as T::UType)
          => promote(T)
     rule argPromoteType(T::UType) => T [owise]

     // "are argument-promoted".
     rule areArgPromoted(ListItem(K:KItem) L:List) => false
          requires notBool isArgPromoted(K)
     rule areArgPromoted(.List) => true
     rule areArgPromoted((ListItem(_) => .List) _) [owise]

     syntax Bool ::= isArgPromoted(K) [function]
     rule isArgPromoted(variadic) => true
     rule isArgPromoted(typedDeclaration(T::Type, _))
          => utype(T) ==Type argPromoteType(utype(T))
     rule isArgPromoted(T:Type)
          => utype(T) ==Type argPromoteType(utype(T))

endmodule
