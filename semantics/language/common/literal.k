module C-LITERAL-SYNTAX
     syntax StringLiteral ::= stringLiteral(String)
     syntax StringLiteral ::= wstringLiteral(List)
endmodule

module C-LITERAL
     imports C-CONVERSION-SYNTAX
     imports C-LITERAL-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX

     imports COMPAT-SYNTAX

     syntax Bool ::= withinRange(Int, SimpleType) [function]
     rule withinRange(I:Int, T:SimpleType)
          => (I <=Int max(t(.Set, T))) andBool (I >=Int min(t(.Set, T)))
     
     syntax String ::= simplifyForHex(String) [function]
     rule simplifyForHex(S:String) => simplifyForHex(butFirstChar(S))
          when (firstChar(S) ==String "0")
               andBool (lengthString(S) >Int 1)
     rule simplifyForHex(S:String) => S
          when (firstChar(S) =/=String "0")
               orBool (lengthString(S) ==Int 1)

     syntax Constant ::= hexOrOctalConstant(Int)
     rule HexConstant(S:String)
          => hexOrOctalConstant(string2Base(simplifyForHex(S), 16))
          [structural, anywhere]
     rule OctalConstant(N:Int)
          => hexOrOctalConstant(string2Base(base2String(N, 10), 8))
          [structural, anywhere]
          
     // Included for symmetry.
     syntax Constant ::= decimalConstant(Int)
     rule DecimalConstant(N:Int) => decimalConstant(N)
          [structural, anywhere]

     rule StringLiteral(S:String) => stringLiteral(S)
          [structural, anywhere]
     rule WStringLiteral(list(S:List)) => wstringLiteral(S)
          [structural, anywhere]

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
     rule NoSuffix(decimalConstant(I:Int)) =>
          #if withinRange(I, int) 
               #then tv(I, t(.Set, int)) 
          #else #if withinRange(I, long-int)
               #then tv(I, t(.Set, long-int)) 
          #else #if withinRange(I, long-long-int)
               #then tv(I, t(.Set, long-long-int)) 
          #else tv(I, t(.Set, no-type))
          #fi #fi #fi
          [structural, anywhere]
     rule NoSuffix(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, int)
               #then tv(I, t(.Set, int)) 
          #else #if withinRange(I, unsigned-int)
               #then tv(I, t(.Set, unsigned-int))
          #else #if withinRange(I, long-int)
               #then tv(I, t(.Set, long-int))
          #else #if withinRange(I, unsigned-long-int)
               #then tv(I, t(.Set, unsigned-long-int))
          #else #if withinRange(I, long-long-int)
               #then tv(I, t(.Set, long-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi #fi #fi #fi #fi
          [structural, anywhere]

     rule LitU(decimalConstant(I:Int)) =>
          #if withinRange(I, unsigned-int)
               #then tv(I, t(.Set, unsigned-int))
          #else #if withinRange(I, unsigned-long-int)
               #then tv(I, t(.Set, unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi #fi
          [structural, anywhere]
     rule LitU(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, unsigned-int)
               #then tv(I, t(.Set, unsigned-int))
          #else #if withinRange(I, unsigned-long-int)
               #then tv(I, t(.Set, unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi #fi
          [structural, anywhere]
          
     rule LitL(decimalConstant(I:Int)) =>
          #if withinRange(I, long-int)
               #then tv(I, t(.Set, long-int))
          #else #if withinRange(I, long-long-int)
               #then tv(I, t(.Set, long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi
          [structural, anywhere]
     rule LitL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, long-int)
               #then tv(I, t(.Set, long-int))
          #else #if withinRange(I, unsigned-long-int)
               #then tv(I, t(.Set, unsigned-long-int))
          #else #if withinRange(I, long-long-int)
               #then tv(I, t(.Set, long-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi #fi #fi
          [structural, anywhere]
          
     rule LitUL(decimalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-int)
               #then tv(I, t(.Set, unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi        
          [structural, anywhere]
     rule LitUL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-int)
               #then tv(I, t(.Set, unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi
          [structural, anywhere]
          
     rule LitLL(decimalConstant(I:Int)) =>
          #if withinRange(I, long-long-int)
               #then tv(I, t(.Set, long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi
          [structural, anywhere]
     rule LitLL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, long-long-int)
               #then tv(I, t(.Set, long-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi
          [structural, anywhere]
     
     rule LitULL(decimalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi
          [structural, anywhere]
     rule LitULL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi
          [structural, anywhere]
          
     /*@ \fromStandard{\source[n1570]{\para{6.4.4.2}{4}}}{
     An unsuffixed floating constant has type \cinline{double}. If suffixed by
     the letter \cinline{f} or \cinline{F}, it has type \cinline{float}. If
     suffixed by the letter \cinline{l} or \cinline{L}, it has type
     \cinline{long double}.
     }*/
     syntax Constant ::= reducedFloat(Float)
     rule DecimalFloatConstant(_, _, F:Float) => reducedFloat(F)
          [structural, anywhere]
     rule HexFloatConstant(_, _, F:Float) => reducedFloat(F)
          [structural, anywhere]
     
     rule NoSuffix(reducedFloat(F:Float)) => tv(F, t(.Set, double))
          [structural, anywhere]
     rule LitL(reducedFloat(F:Float)) => tv(F, t(.Set, long-double))
          [structural, anywhere]
     rule LitF(reducedFloat(F:Float)) => tv(F, t(.Set, float))
          [structural, anywhere]
          
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
     rule CharLiteral(N:Int)
          => cast(t(.Set, int), cast(t(.Set, unsigned-char), tv(N, t(.Set, int))))
          [structural, anywhere]
     rule WCharLiteral(N:Int) => tv(N, cfg:wcharut) 
          [structural, anywhere]
     rule Constant(V:RValue) => V 
          [structural, anywhere]
     rule Constant(S:StringLiteral) => S 
          [structural, anywhere]

endmodule

