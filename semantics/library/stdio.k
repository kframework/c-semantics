module LIBC-STDIO-SYNTAX
     // offset, type, length, checklength
     syntax C ::= "nextvarg-aux" "(" SymLoc "," Type "," K "," K ")"
          [strict(3, 4)]
endmodule

module LIBC-STDIO
     imports LIBC-STDIO-SYNTAX
     imports LIBC-BOOTSTRAP-SYNTAX
     imports LIBC-IO-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     // fixme might be messing things up elsewhere
     syntax String ::= pointerToString(SymLoc) [function]
     syntax String ::= symBaseToString(SymBase) [function]

     // getString returns the string without the null terminator
     syntax K ::= getString(K)
     syntax K ::= "getString-aux" "(" SymLoc "," String ")"
     rule getString(Loc:SymLoc) => getString-aux(Loc, "")
          [structural, anywhere]
     rule getString(tv(Loc:SymLoc, _)) => getString-aux(Loc, "")
          [structural, anywhere]

     rule [getString-pre]:
          (. => read(Loc, t(.Set, char)))
          ~> getString-aux((Loc:SymLoc => Loc +bytes 1), _)
          [structural]

     syntax KResult ::= str(String)
     rule [getString]:
          tv(N:Int, _) ~> getString-aux(Loc:SymLoc, S:String)
          => getString-aux(Loc, S +String chrChar(N))
          when N =/=Int 0
          [structural]
     rule [getString-done]:
          tv(0, _) ~> getString-aux(_, S:String)
          => str(S)
          [structural]

     rule [pointerToString]:
          pointerToString(Loc:SymLoc)
          => "[sym(" +String symBaseToString(base(Loc)) +String ") + "
               +String Int2String(offset(Loc)) +String "]"
          [structural]

     rule [symBaseToString-thread]:
          symBaseToString(B:Int @ thread(Th:Int))
          => Int2String(B) +String " @ "
          +String "thread(" +String Int2String(Th) +String ")"
          [structural]
     rule [sub-pointerToString-allocated]:
          symBaseToString(B:Int @ allocated)
          => Int2String(B) +String " @ "
          +String "allocated"
          [structural]
     rule [sub-pointerToString-static]:
          symBaseToString(B:Int @ static(Tu:String))
          => Int2String(B) +String " @ "
          +String "static(" +String Tu +String ")"
          [structural]
     rule [sub-pointerToString-link]:
          symBaseToString(B:Int @ link(Tu:String))
          => Int2String(B) +String " @ "
          +String "link(" +String Tu +String ")"
          [structural]

     rule [pointerToString-done]:
          pointerToString(NullPointer) => "NullPointer"
          [structural]

     syntax C ::= nextvarg(SymLoc, K) [strict(2)] // loc, type
     syntax C ::= vpair(K, K) [hybrid, strict]

     rule [nextvarg-start]:
          nextvarg(Loc:SymLoc, T:Type)
          => nextvarg-aux(Loc, T, byteSizeofType(T), sizeofObject(base(Loc)))
          [structural]
     rule [nextvarg]:
          nextvarg-aux(Loc:SymLoc, T:Type, Len:RValue, Len':RValue)
          => vpair(read(Loc, T),
               varg(tv(loc(linc(base(Loc)), offset(Loc)), t(.Set, pointerType(t(.Set, void))))))
          when value(Len) ==Int value(Len')
          [structural]

     rule [putchar]:
          prepareBuiltin(Identifier("putchar"),
               ListItem(tv(N:Int, _)))
          => writeToFD(1, N) ~> tv(N, t(.Set, int))
          [structural]

     rule [fslPutc]:
          prepareBuiltin(Identifier("__fslPutc"),
               ListItem(tv(N:Int, _))
               ListItem(tv(H:Int, _)))
          => writeToFD(H, N) ~> tv(N, t(.Set, int))
          [structural]

     rule [getchar]:
          prepareBuiltin(Identifier("getchar"), .List)
          => flush(1) ~> readFromFD(0)
          [structural]

     rule [fslFGetC]:
          prepareBuiltin(Identifier("__fslFGetC"),
               ListItem(tv(FD:Int, _))
               ListItem(tv(_:Int, _)))
          => readFromFD(FD)
          [structural]

     rule [fslCloseFile]:
          <k> prepareBuiltin(Identifier("__fslCloseFile"),
                    ListItem(tv(FD:Int, t(_, int))))
               => tv(0, t(.Set, int))
          ...</k>
          (<file>... <fid> FD:Int </fid> ...</file> => .Bag)
          [structural]

     rule [fslOpenFile-pre]:
          prepareBuiltin(Identifier("__fslOpenFile"),
               ListItem(Filename:KResult)
               ListItem(Mode:KResult))
          => fsl-open-file(getString(Filename), getString(Mode))
          [structural]

     syntax K ::= "fsl-open-file-aux" "(" String "," String "," K ")"
          [strict(3)]

     rule [fslOpenFile-aux]:
          fsl-open-file(str(Filename:String), str(Mode:String))
          => fsl-open-file-aux("file:" +String Filename, Mode,
               #open(Filename, Mode))
          [structural]

     rule [fslOpenFile]:
          <k> fsl-open-file-aux(FileName:String, Mode:String, tv(FD:Int, _))
               => tv(FD, t(.Set, int))
          ...</k>
          <files>...
               (.Bag =>
                    <file>...
                         <fid> FD </fid>
                         <uri> FileName </uri>
                         <mode> Mode </mode>
                    ...</file>
               )
          ...</files>
          [structural]

     syntax K ::= "fsl-open-file" "(" K "," K ")" [strict]

     //////////////////////////

     // C1X Here we might want to assume different threads cannot interleave
     // wrt printf, based on 7.1.4:5.  However, 7.1.4:4 seems to say exactly
     // the opposite.

     // on second thought, it probably is saying that while the shared data is
     // protected against races, it can still be interleaved

     // fixme despite the above, still need to handle interleaving of user data
     // read during evaluation of printf.  should use something like a buffer
     // to do this
     rule [printf]:
          prepareBuiltin(Identifier("printf"),
               ListItem(Format:KResult)
               ListItem(VarArgs:KResult))
          => new-printf-aux(formatter(getString(Format), VarArgs))
          [structural]

     rule [printf-done]:
          new-printf-aux(formattedResult(S:String))
          => writeToFD(1, S)
               ~> flush(1)
               ~> tv(lengthString(S), t(.Set, int))
          [structural]

     syntax K ::= sprintf(K, SymLoc) [strict(1)]
     rule [sprintf]:
          prepareBuiltin(Identifier("sprintf"),
               ListItem(tv(Dest:SymLoc, _))
               ListItem(Format:KResult)
               ListItem(VarArgs:KResult))
          => sprintf(formatter(getString(Format), VarArgs), Dest)
          [structural]
     rule [sprintf-done]:
          sprintf(formattedResult(S:String), Dest:SymLoc)
          => writeString(Dest, S)
               ~> tv(lengthString(S), t(.Set, int))
          [structural]

     syntax K ::= snprintf(K, SymLoc, Int) [strict(1)]
     rule [snprintf]:
          prepareBuiltin(Identifier("snprintf"),
               ListItem(tv(Dest:SymLoc, _))
               ListItem(tv(Len:Int, _))
               ListItem(Format:KResult)
               ListItem(VarArgs:KResult))
          => snprintf(formatter(getString(Format), VarArgs), Dest, Len)
          [structural]
     rule [snprintf-done-nz]:
          snprintf(formattedResult(S:String), Dest:SymLoc, Len:Int)
          => writeString(Dest, substrString(S, 0, Len -Int 1))
               ~> tv(lengthString(S), t(.Set, int))
          when Len >Int 0
          [structural]
     rule [snprintf-done-0]:
          snprintf(formattedResult(S:String), _, 0)
          => tv(lengthString(S), t(.Set, int))
          [structural]

     syntax K ::= "new-printf-aux" "(" K ")" [strict]
     syntax K ::= formatter(K, K) [strict(1)]
     syntax K ::= "formatter-aux" "(" K ")" [strict]
     syntax K ::= "formatter-next" "(" K ")"
     syntax K ::= "formatter-arg" "(" K ")" [strict(1)]
     rule formatter-next(varg'(tv(Loc:SymLoc, _)))
          => formatter-arg(nextvarg(Loc, getFormatType))
          [structural]
     rule <k> formatter-arg(vpair(tv(K:K, _), V':KResult))
               => formatter-aux(V':KResult)
          ...</k>
          <format-arg> _ => K:K </format-arg>
          [structural]

     rule [format-start]:
          <k> formatter(str(S:String), VarArgs:KResult)
               => formatter-aux(VarArgs:KResult)
          ...</k>
          (.Bag =>
               <formatting>...
                    <format> stringToList(S:String) </format>
               ...</formatting>
          )
          [structural]

     syntax KResult ::= "formattedResult" "(" K ")"

     rule [format-done]:
          <k>
               formatter-aux(_)
               => formattedResult(listToString(Result:List))
          ...</k>
          (
               <formatting>...
                    <format> .List </format>
                    <format-result> Result:List </format-result>
                    <format-state> "normal" </format-state>
                    <format-mods> .Map </format-mods>
               ...</formatting>
               => .Bag
          )
          [structural]

     rule [format-normal]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem(S:String) => .List ...</format>
          <format-result>... .List => ListItem(S:String) </format-result>
          <format-state> "normal" </format-state>
          when S:String =/=String "%"
          [structural]

     rule [format-reset]:
          <k> formatter-aux(_) ...</k>
          <format-mods> _ => .Map </format-mods>
          <format-length> _ => "" </format-length>
          <format-state> "reset" => "normal" </format-state>
          [structural]

     rule [format-%]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem("%") => .List ...</format>
          <format-state> "normal" => "%" </format-state>
          [structural]

     // %[flags][width][.precision][length]type

     /*@ \source[n1570]{\para{7.21.6.1}{4}}
     Each conversion specification is introduced by the character \texttt{\%}.
     After the \texttt{\%}, the following appear in sequence:
     \begin{itemize}
     \item Zero or more flags (in any order) that modify the meaning of the
     conversion specification.

     \item An optional minimum field width. If the converted value has fewer
     characters than the field width, it is padded with spaces (by default) on
     the left (or right, if the left adjustment flag, described later, has been
     given) to the field width. The field width takes the form of an asterisk
     \texttt{*} (described later) or a nonnegative decimal integer.)

     \item An optional precision that gives the minimum number of digits to
     appear for the \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x},
     and \texttt{X} conversions, the number of digits to appear after the
     decimal-point character for \texttt{a}, \texttt{A}, \texttt{e},
     \texttt{E}, \texttt{f}, and \texttt{F} conversions, the maximum number of
     significant digits for the \texttt{g} and \texttt{G} conversions, or the
     maximum number of bytes to be written for s conversions. The precision
     takes the form of a period (\texttt{.}) followed either by an asterisk
     \texttt{*} (described later) or by an optional decimal integer; if only
     the period is specified, the precision is taken as zero. If a precision
     appears with any other conversion specifier, the behavior is undefined.

     \item An optional length modifier that specifies the size of the argument.

     \item A conversion specifier character that specifies the type of
     conversion to be applied.

     \end{itemize}
     */

     /*@ \fromStandard{\source[n1570]{\para{7.21.6.1}{5}}}{
     As noted above, a field width, or precision, or both, may be indicated by
     an asterisk. In this case, an \cinline{int} argument supplies the field
     width or precision. The arguments specifying field width, or precision, or
     both, shall appear (in that order) before the argument (if any) to be
     converted. A negative field width argument is taken as a \texttt{-} flag
     followed by a positive field width. A negative precision argument is taken
     as if the precision were omitted. }*/

     /*@ \fromStandard{\source[n1570]{\para{7.21.6.1}{6}}}{
     The flag characters and their meanings are:
     \begin{description}

     \item[\texttt{-}] \broken{The result of the conversion is left-justified
     within the field. (It is right-justified if this flag is not specified.)}

     \item[\texttt{+}] \broken{The result of a signed conversion always begins
     with a plus or minus sign. (It begins with a sign only when a negative
     value is converted if this flag is not specified.)}

     \item[\emph{space}] \broken{If the first character of a signed conversion
     is not a sign, or if a signed conversion results in no characters, a space
     is prefixed to the result. If the \emph{space} and \texttt{+} flags both
     appear, the \emph{space} flag is ignored.}

     \item[\texttt{\#}] \broken{The result is converted to an ``alternative
     form''. For \texttt{o} conversion, it increases the precision, if and only
     if necessary, to force the first digit of the result to be a zero (if the
     value and precision are both 0, a single 0 is printed). For \texttt{x} (or
     \texttt{X}) conversion, a nonzero result has \texttt{0x} (or \texttt{0X})
     prefixed to it. For \texttt{a}, \texttt{A}, \texttt{e}, \texttt{E},
     \texttt{f}, \texttt{F}, \texttt{g}, and \texttt{G} conversions, the result
     of converting a floating-point number always contains a decimal-point
     character, even if no digits follow it. (Normally, a decimal-point
     character appears in the result of these conversions only if a digit
     follows it.) For \texttt{g} and \texttt{G} conversions, trailing zeros are
     \emph{not} removed from the result. For other conversions, the behavior is
     undefined.}

     \item[\texttt{0}] \broken{For \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, \texttt{X}, \texttt{a}, \texttt{A}, \texttt{e},
     \texttt{E}, \texttt{f}, \texttt{F}, \texttt{g}, and \texttt{G}
     conversions, leading zeros (following any indication of sign or base) are
     used to pad to the field width rather than performing space padding,
     except when converting an infinity or NaN. If the \texttt{0} and
     \texttt{-} flags both appear, the \texttt{0} flag is ignored. For
     \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, and \texttt{X}
     conversions, if a precision is specified, the \texttt{0} flag is ignored.}
     \end{description}
     For other conversions, the behavior is undefined.
     }*/

     // fixme ignoring 0 flag for now
     rule [format-%0]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem("0") => .List ...</format>
          <format-state> "%" </format-state>
          [structural]

     // ignoring num width
     rule [format-width]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem(C:String) => .List ...</format>
          <format-state> "%" </format-state>
          when ordChar(C:String) >Int ordChar("0")
               andBool ordChar(C:String) <=Int ordChar("9")
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{7}}
     The length modifiers and their meanings are:
     \begin{description}
     \item[\texttt{hh}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a
     \cinline{signed char} or \cinline{unsigned char} argument (the argument
     will have been promoted according to the integer promotions, but its value
     shall be converted to \cinline{signed char} or \cinline{unsigned char}
     before printing); or that a following \texttt{n} conversion specifier
     applies to a pointer to a \cinline{signed char} argument.}

     \item[\texttt{h}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a
     \cinline{short int} or \cinline{unsigned short int} argument (the argument
     will have been promoted according to the integer promotions, but its value
     shall be converted to \cinline{short int} or \cinline{unsigned short int}
     before printing); or that a following \texttt{n} conversion specifier
     applies to a pointer to a \cinline{short int} argument.}

     \item[\texttt{l} (ell)]
     Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u},
     \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{long
     int} or \cinline{unsigned long int} argument; that a following \texttt{n}
     conversion specifier applies to a pointer to a \cinline{long int}
     argument; \broken{that a following \texttt{c} conversion specifier applies
     to a \cinline{wint_t} argument; that a following \texttt{s} conversion
     specifier applies to a pointer to a \cinline{wchar_t} argument}; or has no
     effect on a following \texttt{a}, \texttt{A}, \texttt{e}, \texttt{E},
     \texttt{f}, \texttt{F}, \texttt{g}, or \texttt{G} conversion specifier.

     \item[\texttt{ll} (ell-ell)]
     Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u},
     \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{long
     long int} or \cinline{unsigned long long int} argument; or that a
     following \texttt{n} conversion specifier applies to a pointer to a
     \cinline{long long int} argument.

     \item[\texttt{j}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to an
     \cinline{intmax_t} or \cinline{uintmax_t} argument; or that a following
     \texttt{n} conversion specifier applies to a pointer to an
     \cinline{intmax_t} argument.}

     \item[\texttt{z}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a
     \cinline{size_t} or the corresponding signed integer type argument; or
     that a following \texttt{n} conversion specifier applies to a pointer to a
     signed integer type corresponding to \cinline{size_t} argument.}

     \item[\texttt{t}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a
     \cinline{ptrdiff_t} or the corresponding unsigned integer type argument;
     or that a following \texttt{n} conversion specifier applies to a pointer
     to a \cinline{ptrdiff_t} argument.}

     \item[\texttt{L}]
     \broken{Specifies that a following \texttt{a}, \texttt{A}, \texttt{e},
     \texttt{E}, \texttt{f}, \texttt{F}, \texttt{g}, or \texttt{G} conversion
     specifier applies to a \cinline{long double} argument.}

     \end{description}
     If a length modifier appears with any conversion specifier other than as
     specified above, the behavior is undefined.
     */

     syntax K ::= "getFormatType"
     syntax K ::= "getFormatType-aux" "(" K "," K ")"
     rule <k> getFormatType => getFormatType-aux(State:K, Length:K) ...</k>
          <format-length> Length:K </format-length>
          <format-state> State:K </format-state>
          [structural]

     rule getFormatType-aux("%a", _) => t(.Set, double) [structural]
     rule getFormatType-aux("%A", _) => t(.Set, double) [structural]
     rule getFormatType-aux("%e", _) => t(.Set, double) [structural]
     rule getFormatType-aux("%E", _) => t(.Set, double) [structural]
     rule getFormatType-aux("%f", _) => t(.Set, double) [structural]
     rule getFormatType-aux("%F", _) => t(.Set, double) [structural]
     rule getFormatType-aux("%g", _) => t(.Set, double) [structural]
     rule getFormatType-aux("%G", _) => t(.Set, double) [structural]

     rule getFormatType-aux("%c", "")
          => t(.Set, int) [structural]
     rule getFormatType-aux("%s", "")
          => t(.Set, pointerType(t(.Set, char))) [structural]

     rule getFormatType-aux("%p", "")
          => t(.Set, pointerType(t(.Set, void))) [structural]

     rule getFormatType-aux("%d", "")
          => t(.Set, int) [structural]
     rule getFormatType-aux("%o", "")
          => t(.Set, int) [structural]
     rule getFormatType-aux("%u", "")
          => t(.Set, unsigned-int) [structural]
     rule getFormatType-aux("%x", "")
          => t(.Set, unsigned-int) [structural]
     rule getFormatType-aux("%X", "")
          => t(.Set, unsigned-int) [structural]
     rule getFormatType-aux("%n", "")
          => t(.Set, pointerType(t(.Set, int))) [structural]

     rule getFormatType-aux("%d", "l")
          => t(.Set, long-int) [structural]
     rule getFormatType-aux("%o", "l")
          => t(.Set, long-int) [structural]
     rule getFormatType-aux("%u", "l")
          => t(.Set, unsigned-long-int) [structural]
     rule getFormatType-aux("%x", "l")
          => t(.Set, unsigned-long-int) [structural]
     rule getFormatType-aux("%X", "l")
          => t(.Set, unsigned-long-int) [structural]
     rule getFormatType-aux("%n", "l")
          => t(.Set, pointerType(t(.Set, long-int))) [structural]

     rule getFormatType-aux("%d", "ll")
          => t(.Set, long-long-int) [structural]
     rule getFormatType-aux("%o", "ll")
          => t(.Set, long-long-int) [structural]
     rule getFormatType-aux("%u", "ll")
          => t(.Set, unsigned-long-long-int) [structural]
     rule getFormatType-aux("%x", "ll")
          => t(.Set, unsigned-long-long-int) [structural]
     rule getFormatType-aux("%X", "ll")
          => t(.Set, unsigned-long-long-int) [structural]
     rule getFormatType-aux("%n", "ll")
          => t(.Set, pointerType(t(.Set, long-long-int))) [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{d},\texttt{i}]
     The \cinline{int} argument is converted to signed decimal in the style
     \emph{[-]dddd}. \broken{The precision specifies the minimum number of
     digits to appear; if the value being converted can be represented in fewer
     digits, it is expanded with leading zeros. The default precision is 1. The
     result of converting a zero value with a precision of zero is no
     characters.}
     \end{description}
     */
     rule [format-%d-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem(S:String) => .List ...</format>
          <format-state> "%" => "%d" </format-state>
          when S:String ==String "d" orBool S:String ==String "i"
          [structural]
     rule [format-%d]:
          <k> formatter-aux(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-result>...
               .List => ListItem(Int2String(D:Int))
          </format-result>
          <format-state> "%d" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{o},\texttt{u},\texttt{x},\texttt{X}]
     The \cinline{unsigned int} argument is converted to unsigned octal
     (\texttt{o}), unsigned decimal (\texttt{u}), or unsigned hexadecimal
     notation (\texttt{x} or \texttt{X}) in the style \emph{dddd}; the letters
     \texttt{abcdef} are used for \texttt{x} conversion and the letters
     \texttt{ABCDEF} for \texttt{X} conversion. \broken{The precision specifies
     the minimum number of digits to appear; if the value being converted can
     be represented in fewer digits, it is expanded with leading zeros. The
     default precision is 1. The result of converting a zero value with a
     precision of zero is no characters.}
     \end{description}
     */
     rule [format-%o-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("o") => .List ...</format>
          <format-state> "%" => "%o" </format-state>
          [structural]
     rule [format-%o]:
          <k> formatter-aux(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-result>...
               .List => ListItem(base2String(D:Int, 8))
          </format-result>
          <format-state> "%o" => "reset" </format-state>
          [structural]
     rule [format-%u-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("u") => .List ...</format>
          <format-state> "%" => "%u" </format-state>
          [structural]
     rule [format-%u]:
          <k> formatter-aux(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-result>...
               .List => ListItem(Int2String(D:Int))
          </format-result>
          <format-state> "%u" => "reset" </format-state>
          [structural]
     rule [format-%x-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("x") => .List ...</format>
          <format-state> "%" => "%x" </format-state>
          [structural]
     rule [format-%x]:
          <k> formatter-aux(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-result>...
               .List => ListItem(base2String(D:Int, 16))
          </format-result>
          <format-state> "%x" => "reset" </format-state>
          [structural]
     rule [format-%X-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("X") => .List ...</format>
          <format-state> "%" => "%X" </format-state>
          [structural]
     rule [format-%X]:
          <k> formatter-aux(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-result>...
               .List => ListItem(toUpperCase(base2String(D:Int, 16)))
          </format-result>
          <format-state> "%X" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{f},\texttt{F}]
     A \cinline{double} argument representing a floating-point number is
     converted to decimal notation in the style \emph{[-]ddd.ddd},
     \broken{where the number of digits after the decimal-point character is
     equal to the precision specification. If the precision is missing, it is
     taken as 6; if the precision is zero and the \texttt{\#} flag is not
     specified, no decimal-point character appears. If a decimal-point
     character appears, at least one digit appears before it. The value is
     rounded to the appropriate number of digits.}

     A \cinline{double} argument representing an infinity is converted in one
     of the styles \emph{[-]inf} or \emph{[-]infinity}---which style is
     implementation-defined.  A \cinline{double} argument representing a NaN is
     converted in one of the styles \emph{[-]nan} or
     \emph{[-]nan}(\emph{n-char-sequence})---which style, and the meaning of
     any \emph{n-char-sequence}, is implementation-defined. The \texttt{F}
     conversion specifier produces \cinline{INF}, \cinline{INFINITY}, or
     \cinline{NAN} instead of \cinline{inf}, \cinline{infinity}, or
     \cinline{nan}, respectively.
     \end{description}
     */
     rule [format-%f-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("f") => .List ...</format>
          <format-state> "%" => "%f" </format-state>
          [structural]
     rule [format-%f]:
          <k> formatter-aux(_) ...</k>
          <format-arg> D:Float => .K </format-arg>
          <format-result>...
               .List => ListItem(Float2String(D:Float))
          </format-result>
          <format-state> "%f" => "reset" </format-state>
          [structural]
     rule [format-%F-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("F") => .List ...</format>
          <format-state> "%" => "%F" </format-state>
          [structural]
     rule [format-%F]:
          <k> formatter-aux(_) ...</k>
          <format-arg> D:Float => .K </format-arg>
          <format-result>...
               .List => ListItem(toUpperCase(Float2String(D:Float)))
          </format-result>
          <format-state> "%F" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{e},\texttt{E}]
     \broken{A \cinline{double} argument representing a floating-point number
     is converted in the style \emph{[-]d.ddde$\pm{}$dd}, where there is one
     digit (which is nonzero if the argument is nonzero) before the
     decimal-point character and the number of digits after it is equal to the
     precision; if the precision is missing, it is taken as 6; if the precision
     is zero and the \texttt{\#} flag is not specified, no decimal-point
     character appears. The value is rounded to the appropriate number of
     digits. The \texttt{E} conversion specifier produces a number with
     \texttt{E} instead of e introducing the exponent. The exponent always
     contains at least two digits, and only as many more digits as necessary to
     represent the exponent. If the value is zero, the exponent is zero.}

     \broken{A double argument representing an infinity or NaN is converted in
     the style of an \texttt{f} or \texttt{F} conversion specifier.}

     \end{description}
     */

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{g},\texttt{G}]
     A \cinline{double} argument representing a floating-point number is
     converted in style \texttt{f} or \texttt{e} (or in style \texttt{F} or
     \texttt{E} in the case of a \texttt{G} conversion specifier), depending on
     the value converted and the precision. \broken{Let $P$ equal the precision
     if nonzero, 6 if the precision is omitted, or 1 if the precision is zero.
     Then, if a conversion with style \texttt{E} would have an exponent of
     $X$:}
     \begin{itemize}

     \item \broken{if $P > X = -4$, the conversion is with style \texttt{f} (or
     \texttt{F}) and precision $P - (X + 1)$.}

     \item \broken{otherwise, the conversion is with style \texttt{e} (or
     \texttt{E}) and precision $P - 1$.}

     \end{itemize}
     \broken{Finally, unless the \texttt{\#} flag is used, any trailing zeros
     are removed from the fractional portion of the result and the
     decimal-point character is removed if there is no fractional portion
     remaining.}

     A \cinline{double} argument representing an infinity or NaN is converted
     in the style of an \texttt{f} or \texttt{F} conversion specifier.
     \end{description}
     */
     rule [format-%g-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("g") => .List ...</format>
          <format-state> "%" => "%g" </format-state>
          [structural]
     rule [format-%g]:
          <k> formatter-aux(_) ...</k>
          <format-arg> D:Float => .K </format-arg>
          <format-result>...
               .List => ListItem(Float2String(D:Float))
          </format-result>
          <format-state> "%g" => "reset" </format-state>
          [structural]
     rule [format-%G-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("G") => .List ...</format>
          <format-state> "%" => "%G" </format-state>
          [structural]
     rule [format-%G]:
          <k> formatter-aux(_) ...</k>
          <format-arg> D:Float => .K </format-arg>
          <format-result>...
               .List => ListItem(toUpperCase(Float2String(D:Float)))
          </format-result>
          <format-state> "%G" => "reset" </format-state>
          [structural]

     /* \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{a},\texttt{A}]
     \ldots
     \end{description}
     */

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{c}]
     If no \texttt{l} length modifier is present, the \cinline{int} argument is
     converted to an \cinline{unsigned char}, and the resulting character is
     written.

     \broken{If an \texttt{l} length modifier is present, the \cinline{wint_t}
     argument is converted as if by an \texttt{ls} conversion specification
     with no precision and an argument that points to the initial element of a
     two-element array of \cinline{wchar_t}, the first element containing the
     \cinline{wint_t} argument to the \texttt{lc} conversion specification and
     the second a null wide character.}
     \end{description}
     */
     rule [format-%c-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("c") => .List ...</format>
          <format-state> "%" => "%c" </format-state>
          [structural]
     rule [format-%c]:
          <k> formatter-aux(_) ...</k>
          <format-arg> C:Int => .K </format-arg>
          <format-result>...
               .List => ListItem(chrChar(((C:Int %Int 256) +Int 256)
                    %Int 256))
          </format-result>
          <format-state> "%c" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{s}]
     If no \texttt{l} length modifier is present, the argument shall be a
     pointer to the initial element of an array of character type. Characters
     from the array are written up to (but not imports) the terminating null
     character. \broken{If the precision is specified, no more than that many
     bytes are written.} If the precision is not specified or is greater than
     the size of the array, the array shall contain a null character.

     \broken{If an \texttt{l} length modifier is present, the argument shall be
     a pointer to the initial element of an array of \cinline{wchar_t} type.
     Wide characters from the array are converted to multibyte characters (each
     as if by a call to the \cinline{wcrtomb} function, with the conversion
     state described by an \cinline{mbstate_t} object initialized to zero
     before the first wide character is converted) up to and imports a
     terminating null wide character. The resulting multibyte characters are
     written up to (but not imports) the terminating null character (byte). If
     no precision is specified, the array shall contain a null wide character.
     If a precision is specified, no more than that many bytes are written
     (imports shift sequences, if any), and the array shall contain a null wide
     character if, to equal the multibyte character sequence length given by
     the precision, the function would need to access a wide character one past
     the end of the array. In no case is a partial multibyte character
     written.}
     \end{description}
     */
     rule [format-%s-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("s") => .List ...</format>
          <format-state> "%" => "%s" </format-state>
          [structural]
     rule [format-%s]:
          <k> (.K => getString(Loc))
               ~> formatter-aux(_)
          ...</k>
          <format-arg> Loc:SymLoc => .K </format-arg>
          <format-state> "%s" => "%s-read" </format-state>
          [structural]
     rule [format-%s-done]:
          <k> (str(S:String) => .K)
               ~> formatter-aux(_)
          ...</k>
          <format-result>...
               .List => ListItem(S:String)
          </format-result>
          <format-state> "%s-read" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{p}]
     The argument shall be a pointer to \cinline{void}. The value of the
     pointer is converted to a sequence of printing characters, in an
     implementation-defined manner.
     \end{description}
     */
     rule [format-%p-start]:
          <k> formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("p") => .List ...</format>
          <format-state> "%" => "%p" </format-state>
          [structural]
     rule [format-%p]:
          <k> formatter-aux(_) ...</k>
          <format-arg> Loc:SymLoc => .K </format-arg>
          <format-result>...
               .List => ListItem(pointerToString(Loc))
          </format-result>
          <format-state> "%p" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{n}]
     \broken{The argument shall be a pointer to signed integer into which is
     \emph{written} the number of characters written to the output stream so
     far by this call to \cinline{fprintf}. No argument is converted, but one
     is consumed. If the conversion specification includes any flags, a field
     width, or a precision, the behavior is undefined.}
     \end{description}
     */

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{\%}]
     A \texttt{\%} character is written. No argument is converted. The complete
     conversion specification shall be \texttt{\%\%}.
     \end{description}
     */
     rule [format-%%]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem("%") => .List ...</format>
          <format-result>...
               .List => ListItem("%")
          </format-result>
          <format-state> "%" => "reset" </format-state>
          [structural]

     rule [format-%l]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem("l") => .List ...</format>
          <format-state> "%" </format-state>
          <format-length>
               Length:String => Length:String +String "l"
          </format-length>
          [structural]
endmodule

