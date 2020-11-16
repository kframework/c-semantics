module C-LITERAL
     imports FLOAT-SYNTAX
     imports K-EQUAL
     imports STRING
     imports COMPAT-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports FLOAT

     syntax Constant ::= RValue

     syntax String ::= simplifyForHex(String) [function]
     rule simplifyForHex(S:String) => simplifyForHex(butFirstChar(S))
          requires (firstChar(S) ==String "0")
               andBool (lengthString(S) >Int 1)
     rule simplifyForHex(S:String) => S [owise]

     syntax IntConstant ::= hexOrOctalConstant(Int)
     rule HexConstant(S:String)
          => hexOrOctalConstant(String2Base(simplifyForHex(S), 16))

     rule OctalConstant(N:Int)
          => hexOrOctalConstant(String2Base(Base2String(N, 10), 8))

     /*@ \fromStandard{\source[n1570]{\para{6.4.4.1}{4--6}}}{

     The value of a decimal constant is computed base 10; that of an octal
     constant, base 8; that of a hexadecimal constant, base 16. The lexically
     first digit is the most significant.

     The type of an integer constant is the first of the corresponding list in
     which its value can be represented.\\
     \begin{tabular}{@{}lll@{}}
     \toprule
     Suffix    &    Decimal Constant    &         Octal or Hexadecimal Constant  \\
     \midrule
     none      &         \cinline{int}                           &    \cinline{int} \\
               &         \cinline{long int}                 &    \cinline{unsigned int} \\
               &         \cinline{long long int}            &    \cinline{long int} \\
               &                                       &    \cinline{unsigned long int} \\
               &                                       &    \cinline{long long int} \\
               &                                       &    \cinline{unsigned long long int} \\
     \midrule
     \cinline{u} or \cinline{U}    &         \cinline{unsigned int}             &    \cinline{unsigned int} \\
               &         \cinline{unsigned long int}        &    \cinline{unsigned long int} \\
               &         \cinline{unsigned long long int}   &    \cinline{unsigned long long int} \\
     \midrule
     \cinline{l} or \cinline{L}    &         \cinline{long int}                 &    \cinline{long int} \\
               &         \cinline{long long int}            &    \cinline{unsigned long int} \\
               &                                       &    \cinline{long long int} \\
               &                                       &    \cinline{unsigned long long int} \\
     \midrule
     Both \cinline{u} or \cinline{U} and \cinline{l} or \cinline{L}   &    \cinline{unsigned long int}        &    \cinline{unsigned long int} \\
                                   &    \cinline{unsigned long long int}   &    \cinline{unsigned long long int} \\
     \midrule
     \cinline{ll} or \cinline{LL}  &    \cinline{long long int}            &    \cinline{long long int} \\
                    &                                  &    \cinline{unsigned long long int} \\
     \midrule
     Both \cinline{u} or \cinline{U} and \cinline{ll} or \cinline{LL} &    \cinline{unsigned long long int}   &    \cinline{unsigned long long int} \\
     \bottomrule
     \end{tabular}

     If an integer constant cannot be represented by any type in its list, it
     may have an extended integer type, if the extended integer type can
     represent its value. If all of the types in the list for the constant are
     signed, the extended integer type shall be signed. If all of the types in
     the list for the constant are unsigned, the extended integer type shall be
     unsigned. If the list contains both signed and unsigned types, the
     extended integer type may be signed or unsigned. If an integer constant
     cannot be represented by any type in its list and has no extended integer
     type, then the integer constant has no type.
     }*/
     rule NoSuffix(DecimalConstant(I:Int)) =>
          #if withinRange(I, int)
               #then tv(I, ut(SetItem(IntegerConstant), int))
          #else #if withinRange(I, long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-int))
          #else #if withinRange(I, long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi #fi #fi

     rule NoSuffix(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, int)
               #then tv(I, ut(SetItem(IntegerConstant), int))
          #else #if withinRange(I, unsigned-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-int))
          #else #if withinRange(I, long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-int))
          #else #if withinRange(I, unsigned-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-int))
          #else #if withinRange(I, long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi #fi #fi #fi #fi #fi

     rule LitU(DecimalConstant(I:Int)) =>
          #if withinRange(I, unsigned-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-int))
          #else #if withinRange(I, unsigned-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi #fi #fi

     rule LitU(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, unsigned-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-int))
          #else #if withinRange(I, unsigned-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi #fi #fi

     rule LitL(DecimalConstant(I:Int)) =>
          #if withinRange(I, long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-int))
          #else #if withinRange(I, long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi #fi

     rule LitL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-int))
          #else #if withinRange(I, unsigned-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-int))
          #else #if withinRange(I, long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi #fi #fi #fi

     rule LitUL(DecimalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi #fi

     rule LitUL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi #fi

     rule LitLL(DecimalConstant(I:Int)) =>
          #if withinRange(I, long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi

     rule LitLL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), long-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi #fi

     rule LitULL(DecimalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi

     rule LitULL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-long-int)
               #then tv(I, ut(SetItem(IntegerConstant), unsigned-long-long-int))
          #else tv(I, ut(SetItem(IntegerConstant), no-type))
          #fi

     /*@ \fromStandard{\source[n1570]{\para{6.4.4.2}{4}}}{
     An unsuffixed floating constant has type \cinline{double}. If suffixed by
     the letter \cinline{f} or \cinline{F}, it has type \cinline{float}. If
     suffixed by the letter \cinline{l} or \cinline{L}, it has type
     \cinline{long double}.
     }*/
     //TODO(traiansf): The float used here is the approximation of the original float using the precision given by ocaml.
     syntax FloatConstant ::= reducedFloat(Float)
     rule DecimalFloatConstant(_, _, F:Float) => reducedFloat(F)
     rule HexFloatConstant(_, _, F:Float) => reducedFloat(F)

     rule NoSuffix(reducedFloat(F:Float)) => tv(roundCFloat(utype(double), F), utype(double))

     rule LitL(reducedFloat(F:Float)) => tv(roundCFloat(utype(long-double), F), utype(long-double))

     rule LitF(reducedFloat(F:Float)) => tv(roundCFloat(utype(float), F), utype(float))

     /*@ \fromStandard{\source[n1570]{\para{6.4.4.4}{10}}}{
     An integer character constant has type \cinline{int}. The value of an
     integer character constant containing a single character that maps to a
     single-byte execution character is the numerical value of the
     representation of the mapped character interpreted as an integer. The
     value of an integer character constant containing more than one character
     (e.g., \cinline{'ab'}), or containing a character or escape sequence that
     does not map to a single-byte execution character, is
     implementation-defined. If an integer character constant contains a single
     character or escape sequence, its value is the one that results when an
     object with type \cinline{char} whose value is that of the single
     character or escape sequence is converted to type \cinline{int}.
     }*/

     // TODO(chathhorn): using unsigned-char here even though the standard
     // seems to call for char. Using (signed) char could potentially introduce
     // a trap, it seems to me, which really doesn't seem right.
     syntax Constant ::= Cast
     rule CharLiteral(N:Int)
          => cast(utype(int), cast(utype(unsigned-char), tv(N, ut(SetItem(IntegerConstant), int))))
     rule WCharLiteral(N:Int) => tv(N, utype(cfg:wcharut))
     rule Constant(K:KItem) => K

endmodule

