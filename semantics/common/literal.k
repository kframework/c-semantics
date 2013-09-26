module C-LITERAL
     imports C-CONVERSION-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C11-SETTINGS-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX

     imports COMPAT-SYNTAX

     syntax Bool ::= withinRange(Int, SimpleType) [function]
     rule withinRange(I:Int, T:K)
          => (I <=Int max(t(.Set, T))) andBool (I >=Int min(t(.Set, T)))
     
     syntax String ::= simplifyForHex(String) [function]
     rule simplifyForHex(S:String) => simplifyForHex(butFirstChar(S))
          when (firstChar(S) ==String "0")
               andBool (lengthString(S) >Int 1)
     rule simplifyForHex(S:String) => S
          when (firstChar(S) =/=String "0")
               orBool (lengthString(S) ==Int 1)
          
     syntax K ::= "hexOrOctalConstant" "(" K ")"
     rule HexConstant(S:String)
          => hexOrOctalConstant(string2Base(simplifyForHex(S), 16))
          [structural, anywhere]
     rule OctalConstant(N:Int)
          => hexOrOctalConstant(string2Base(base2String(N, 10), 8))
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
     rule NoSuffix(DecimalConstant(I:Int)) =>
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
          
     rule LitUL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-int)
               #then tv(I, t(.Set, unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi
          [structural, anywhere]
          
     rule LitLL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, long-long-int)
               #then tv(I, t(.Set, long-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi
          [structural, anywhere]
     
     rule LitULL(hexOrOctalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi
          [structural, anywhere]
          
     rule LitU(DecimalConstant(I:Int)) =>
          #if withinRange(I, unsigned-int)
               #then tv(I, t(.Set, unsigned-int))
          #else #if withinRange(I, unsigned-long-int)
               #then tv(I, t(.Set, unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi #fi
          [structural, anywhere]
     rule LitL(DecimalConstant(I:Int)) =>
          #if withinRange(I, long-int)
               #then tv(I, t(.Set, long-int))
          #else #if withinRange(I, long-long-int)
               #then tv(I, t(.Set, long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi
          [structural, anywhere]
     rule LitUL(DecimalConstant(I:Int)) =>
          #if withinRange(I, unsigned-long-int)
               #then tv(I, t(.Set, unsigned-long-int))
          #else #if withinRange(I, unsigned-long-long-int)
               #then tv(I, t(.Set, unsigned-long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi #fi        
          [structural, anywhere]
     rule LitLL(DecimalConstant(I:Int)) =>
          #if withinRange(I, long-long-int)
               #then tv(I, t(.Set, long-long-int))
          #else tv(I, t(.Set, no-type))
          #fi
          [structural, anywhere]
     rule LitULL(DecimalConstant(I:Int)) =>
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
     syntax K ::= "reducedFloat" "(" Float ")"
     rule DecimalFloatConstant(_:String, _:Int, F:Float)
          => reducedFloat(F)
          [structural, anywhere]
     rule HexFloatConstant(_:String, _:Int, F:Float)
          => reducedFloat(F)
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
     rule CharLiteral(N:Int) 
          => cast(t(.Set, int), cast(t(.Set, char), tv(N, t(.Set, int))))
          [structural, anywhere]
     rule WCharLiteral(N:Int) => tv(N, cfg:wcharut) 
          [structural, anywhere]
     rule Constant(V:KResult) => V 
          [structural, anywhere]

     rule [create-internal-value]: N:Int 
          => tv(N, cfg:largestUnsigned)
          [structural] // for internal computations
     
     // here we start with a local address, put the string in memory, then
     // change the address to be readonly
     
     /*@ \fromStandard{\source[n1570]{\para{6.4.5}{6}}}{For character string
     literals, the array elements have type \cinline{char}, and are initialized
     with the individual bytes of the multibyte character sequence. \ldots

     For wide string literals prefixed by the letter \cinline{L}, the array
     elements have type \cinline{wchar_t} and are initialized with the sequence
     of wide characters corresponding to the multibyte character sequence\ldots

     }*/  
          
     rule [const-string-notfound]:
          <k> (. => allocString(Loc, S))
               ~> Constant(StringLiteral(S:String))
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <stringLiterals>
               M:Map
               (. => S |-> lv(Loc, t(.Set, 
                    arrayType(t(.Set, char), lengthString(S) +Int 1))))
          </stringLiterals>
          when notBool (S in keys(M))
          [large, structural]
          
     syntax K ::= "wstring" "(" KList ")"
     rule [const-wstring-notfound]:
          <k> (.K => allocWString(Loc, S))
               ~> Constant(WStringLiteral(S:KList))
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <stringLiterals>
               M:Map
               (.Map => wstring(S) |-> lv(Loc, t(.Set, 
                    arrayType(cfg:wcharut, (lengthKList S) +Int 1))))
          </stringLiterals>
          when notBool wstring(S) in keys M
          [large, structural]
          
     rule [const-string-found]:
          <k> Constant(StringLiteral(S:String)) => V ...</k>
          <stringLiterals>... S |-> V:LValue ...</stringLiterals>
          [structural]
     rule [const-wstring-found]:
          <k> Constant(WStringLiteral(S:KList)) => V ...</k>
          <stringLiterals>...
               wstring(S) |-> V:LValue
          ...</stringLiterals>
          [structural]
endmodule

