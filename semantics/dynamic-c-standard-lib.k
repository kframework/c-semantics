require "dynamic-c-semantics.k"

module DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
     imports DYNAMIC-INCLUDE 
     
     syntax C ::= "vararg" "(" K ")" [hybrid, strict]
     syntax C ::= "nextvarg" "(" SymLoc "," K ")" [strict(2)] // loc, type
     syntax C ::= "vpair" "(" K "," K ")" [hybrid, strict]
     syntax K ::= "prepareBuiltin" "(" Id "," KList ")" 
     syntax K ::= incSymbolic(K)
     syntax K ::= "printString" "(" K ")"
endmodule

module DYNAMIC-C-STANDARD-LIBRARY-HELPERS
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
     
     // TODO(chathhorn): not pretty
     rule rkludge(vararg(K:K)) => vararg(K) [structural, anywhere]

     // offset, type, length, checklength
     syntax C ::= "nextvarg-aux" "(" SymLoc "," Type "," K "," K ")"
     context nextvarg-aux(_, _, value(HOLE), _)
     context nextvarg-aux(_, _, _, value(HOLE))
     
     rule [nextvarg-start]:
          nextvarg(Loc:SymLoc, T:Type)
          => nextvarg-aux(Loc, T, 
               value(byteSizeofType(T)), value(sizeofLocation(Loc)))
          [structural]
     rule [nextvarg]:
          nextvarg-aux(Loc:SymLoc, T:Type, Len:Int, Len:Int)
          => vpair(read(Loc, T), 
               vararg(tv(linc(Loc), t(.Set, pointerType(t(.Set, void))))))
          [structural]
     
     context prepareBuiltin(_, (_,, (HOLE => reval(HOLE)),, _))
     
     syntax KList ::= idsFromDeclList(KList) [function]
     
     rule [idsFromDeclList-one]:
          idsFromDeclList((L:KList,, typedDeclaration(t(_, T:K), X:Id)))
          => idsFromDeclList(L:KList),, X:Id
          when T:K =/=K void
          [structural]
     rule [idsFromDeclList-void]:
          idsFromDeclList((L:KList,, typedDeclaration(t(_, void), _:Id)))
          => idsFromDeclList(L:KList)
          [structural]
     rule [idsFromDeclList-vararg]:
          idsFromDeclList((L:KList,, 
               typedDeclaration(T:KResult, X:Id),, t(_, variadic)))
          => idsFromDeclList((L:KList,, typedDeclaration(T:KResult, X:Id)))
               // assumes variadic args are placed in incremental blocks
               ,, vararg(incSymbolic(cast(t(.Set, 
               pointerType(t(.Set, unsigned-char))), &(X:Id))))
          [structural]
     rule [idsFromDeclList-done]:
          idsFromDeclList(.KList) => .KList [structural]

     context incSymbolic((HOLE => reval(HOLE)))
     rule [incSymbolic]:
          incSymbolic(tv(Loc:SymLoc, T:KResult)) => tv(linc(Loc), T:KResult)
          [structural]
          
     rule [prepareBuiltin]:
          handleBuiltin(F:Id, t(_, functionType(_:KResult, L:KList)))
          => Return(prepareBuiltin(F:Id, idsFromDeclList(L:KList)))
          [structural]
          
     rule printString(S:String)
          => writeToFD(1, asciiString(firstChar(S:String)))
               ~> printString(butFirstChar(S:String))
          when lengthString(S:String) >Int 0
          [structural]
     rule printString("") => writeToFD(1, 10)
          [structural]
endmodule

module DYNAMIC-C-STANDARD-LIBRARY-MATH
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
     rule [sqrt]:
          prepareBuiltin((Identifier("sqrt")), tv(F:Float, t(_, double)))
          => tv(sqrtFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [log]:
          prepareBuiltin((Identifier("log")), tv(F:Float, t(_, double)))
          => tv(logFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [exp]:
          prepareBuiltin((Identifier("exp")), tv(F:Float, t(_, double)))
          => tv(expFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [atan]:
          prepareBuiltin((Identifier("atan")), tv(F:Float, t(_, double)))
          => tv(atanFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [asin]:
          prepareBuiltin((Identifier("asin")), tv(F:Float, t(_, double)))
          => tv(asinFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [atan2]:
          prepareBuiltin((Identifier("atan2")), (tv(F:Float, t(_, double)),, 
               tv(F':Float, t(_, double))))
          => tv(atan2Float(F:Float, F':Float), t(.Set, double))
          [structural]
  
     rule [tan]:
          prepareBuiltin((Identifier("tan")), tv(F:Float, t(_, double)))
          => tv(tanFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [floor]:
          prepareBuiltin((Identifier("floor")), tv(F:Float, t(_, double)))
          => tv(floorFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [cos]:
          prepareBuiltin((Identifier("cos")), tv(F:Float, t(_, double)))
          => tv(cosFloat(F:Float), t(.Set, double))
          [structural]

     rule [fmod]:
          prepareBuiltin((Identifier("fmod")), (tv(F:Float, t(_, double)),, 
               tv(F':Float, t(_, double))))
          => tv(F:Float %Float F':Float, t(.Set, double))
          [structural]

     rule [sin]:
          prepareBuiltin((Identifier("sin")), tv(F:Float, t(_, double)))
          => tv(sinFloat(F:Float), t(.Set, double))
          [structural]

endmodule

module DYNAMIC-C-STANDARD-LIBRARY-SETJMP
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE

     /*@ 
     \fromStandard{\source[n1570]{\para{7.13}{1--3}}}{
     The header \header{<setjmp.h>} defines the macro \cinline{setjmp}, and
     declares one function and one type, for bypassing the normal function call
     and return discipline.

     The type declared
     \cdisplay{jmp_buf}
     which is an array type suitable for holding the information needed to
     restore a calling environment. The environment of a call to the
     \cinline{setjmp} macro consists of information sufficient for a call to
     the \cinline{longjmp} function to return execution to the correct block
     and invocation of that block, were it called recursively. It does not
     include the state of the floating-point status flags, of open files, or of
     any other component of the abstract machine.

     It is unspecified whether \cinline{setjmp} is a macro or an identifier
     declared with external linkage. If a macro definition is suppressed in
     order to access an actual function, or a program defines an external
     identifier with the name \cinline{setjmp}, the behavior is undefined.
     }*/
     
     
     // The (apparent) return value from setjmp indicates whether control
     // reached that point normally or from a call to longjmp
     // fixme check bounds
     // fixme obviously need to rework configuration to make this easy
     syntax K ::= "bag" "(" Bag ")"
     
     syntax K ::= "ignoreLocals"
     
     // there seems to be a problem here related to locals.  what if longjmp is
     // never called?
     rule [ignoreLocals]:
          <k> ignoreLocals => . ...</k>
          <localAddresses> _ => .Set </localAddresses>
          [structural]
          
     /*@ 
     \begin{lrbox}{\LstBox}
     \begin{lstlisting}
     #include <setjmp.h>
     int setjmp(jmp_buf env);
     \end{lstlisting}
     \end{lrbox}    
     \fromStandard{\source[n1570]{\para{7.13.1.1}{1--5}}}{
     \Synopsis
     \usebox{\LstBox}
     
     \Description
     The \cinline{setjmp} macro saves its calling environment in its
     \cinline{jmp_buf} argument for later use by the \cinline{longjmp}
     function.
     
     \Returns
     If the return is from a direct invocation, the \cinline{setjmp} macro
     returns the value zero. If the return is from a call to the
     \cinline{longjmp} function, the \cinline{setjmp} macro returns a nonzero
     value.
     
     \Limits
     An invocation of the \cinline{setjmp} macro shall appear only in one of
     the following contexts:
     \begin{itemize}
     \item the entire controlling expression of a selection or iteration
     statement;

     \item one operand of a relational or equality operator with the other
     operand an integer constant expression, with the resulting expression
     being the entire controlling expression of a selection or iteration
     statement;
     
     \item the operand of a unary \cinline{!} operator with the resulting
     expression being the entire controlling expression of a selection or
     iteration statement; or
     
     \item the entire expression of an expression statement (possibly cast to
     \cinline{void}).
     
     \end{itemize}

     If the invocation appears in any other context, the behavior is undefined.
     }*/
     // fixme doesn't check if loc:Int is const
     rule [setjmp]:
          <k> 
               (prepareBuiltin(Identifier("setjmp"), tv(Loc:SymLoc, 
                    t(_, pointerType(t(_, 
                    structType(Identifier("__jmp_buf_tag")))))))
               => ignoreLocals
                    ~> writeByte(Loc, bag(
                         <threadState>
                              <threadContinuation> K:K </threadContinuation>
                              <savedThreadLocal>C:Bag</savedThreadLocal>
                         </threadState>
                    ))
                    ~> tv(0, t(.Set, int))
               )
               ~> K:K
          </k>
          <threadLocal> C:Bag </threadLocal>
          [structural]

     syntax K ::= "longjmp-aux" "(" K "," K ")" [strict(2)]
     context longjmp-aux(HOLE => reval(HOLE), _)
     rule [longjmp-prepare]:
          prepareBuiltin(Identifier("longjmp"), (V:KResult,, V':KResult))
          => longjmp-aux(*(V:KResult), V':KResult)
          [structural]
     
     // fixme: memory leak here with extra ignoreLocals.  needed for recursive
     // setjmp/longjmp as in Looping.c
     rule [longjmp]:
          <k> 
               longjmp-aux(tv(bag(
                    <threadState>
                         <threadContinuation> K:K </threadContinuation>
                         <savedThreadLocal>C:Bag</savedThreadLocal>
                    </threadState>
               ), t(_, structType(Identifier("__jmp_buf_tag")))), 
                    tv(I:Int, t(_, int))) ~> _
               => ignoreLocals 
                    ~> #if I:Int ==Int 0 
                         #then tv(1, t(.Set, int)) 
                         #else tv(I:Int, t(.Set, int)) #fi 
                    ~> K:K
          </k>
          <threadLocal> _ => C:Bag </threadLocal>
          [structural]
endmodule

module DYNAMIC-C-STANDARD-LIBRARY-STDARG
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
          
     /*@ \fromStandard{\source[n1570]{\para{7.16}{1--3}}}{

     The header \header{<stdarg.h>} declares a type and defines four macros,
     for advancing through a list of arguments whose number and types are not
     known to the called function when it is translated.

     A function may be called with a variable number of arguments of varying
     types. As described in 6.9.1, its parameter list contains one or more
     parameters. The rightmost parameter plays a special role in the access
     mechanism, and will be designated $\mathit{parmN}$ in this description.

     The type declared \cdisplay{va_list} which is a complete object type
     suitable for holding information needed by the macros \cinline{va_start},
     \cinline{va_arg}, \cinline{va_end}, and \cinline{va_copy}. If access to
     the varying arguments is desired, the called function shall declare an
     object (generally referred to as ap in this subclause) having type
     \cinline{va_list}. The object \cinline{ap} may be passed as an argument to
     another function; if that function invokes the \cinline{va_arg} macro with
     parameter \cinline{ap}, the value of \cinline{ap} in the calling function
     is indeterminate and shall be passed to the \cinline{va_end} macro prior
     to any further reference to \cinline{ap}. 

     }*/
     
     ////////////////////////////--
     // Stdarg.h
     ////////////////////////////--
          // ,, "__va_inc"
          // ,, "__va_start"
          // ,, "__va_end"
          // ,, "__va_copy"
          
          
     /*@ \fromStandard{\source[n1570]{\para{7.16.1}{1}}}{
     The \cinline{va_start} and \cinline{va_arg} macros described in this
     subclause shall be implemented as macros, not functions. It is unspecified
     whether \cinline{va_copy} and \cinline{va_end} are macros or identifiers
     declared with external linkage. If a macro definition is suppressed in
     order to access an actual function, or a program defines an external
     identifier with the same name, the behavior is undefined. Each invocation
     of the \cinline{va_start} and \cinline{va_copy} macros shall be matched by
     a corresponding invocation of the \cinline{va_end} macro in the same
     function.
     }*/
          
     // va_list __va_start(va_list* ap, void* pN);
     // fixme can add lots of checks here
     // tool fixme, change Value to K and unquote error
     rule [va-start]:
          prepareBuiltin((Identifier("__va_start")), 
               (ApLoc:KResult,, ArgLoc:KResult))
          => Computation(*(ApLoc:KResult) := incSymbolic(ArgLoc:KResult))
               ~> skipval
          [structural]
     
     syntax K ::= "va-inc-aux" "(" K "," K "," K ")" // [strict(3)]
     context va-inc-aux(_, _, (HOLE => reval(HOLE)))
     // fixme can do lots of checks here too
     
     rule [va-inc-start]:
          prepareBuiltin((Identifier("__va_inc")), 
               (ApLoc:KResult,, Size:KResult))
          => va-inc-aux(ApLoc:KResult, Size:KResult, *ApLoc:KResult)
          [structural]
                    
     rule [va-inc]:
          va-inc-aux(ApLoc:KResult, _:KResult, Ap:KResult)
          => Computation(*(ApLoc:KResult) := incSymbolic(Ap:KResult))
               ~> Ap:KResult
          [structural]                  
          
     // fixme can do lots of checks here too
     rule [va-copy]:
          prepareBuiltin((Identifier("__va_copy")), 
               (ApLoc:KResult,, Other:KResult))
          => Computation(*(ApLoc:KResult) := Other:KResult) ~> skipval
          [structural]
          
     // fixme can do lots of checks here too
     rule [va-end]:
          prepareBuiltin((Identifier("__va_end")), (_:KResult)) => skipval
          [structural]
endmodule

module DYNAMIC-C-STANDARD-LIBRARY-STDDEF
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE

     syntax K ::= "offsetOf" "(" K "," K ")" [strict(1)]
     rule OffsetOf(T:KResult, K:K, F:Id)
          => offsetOf(DeclType(T:KResult, K:K), F:Id)
          [structural]

     // fixme should check for bitfield offset
     rule <k> 
               offsetOf(t(_, structType(S:Id)), F:Id)
               => tv(bitsToBytes(Offset:Int), cfg:sizeut)
          ...</k>
          <structs>...
               S:Id |-> aggregateInfo(_, _, (_ F:Id |-> Offset:Int))
          ...</structs>
          [structural]

     rule offsetOf(t(_, unionType(_:Id)), _) => tv(0, cfg:sizeut)
          [structural]
endmodule


module DYNAMIC-C-STANDARD-LIBRARY-STDIO
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE

     rule [putchar]:
          prepareBuiltin((Identifier("putchar")), tv(N:Int, _))
          => writeToFD(1, N:Int) ~> tv(N:Int, t(.Set, int))
          [structural]

     rule [fslPutc]:
          prepareBuiltin((Identifier("__fslPutc")),
               (tv(N:Int, _),, tv(H:Int, _)))
          => writeToFD(H:Int, N:Int) ~> tv(N:Int, t(.Set, int))
          [structural]

     rule [getchar]:
          prepareBuiltin((Identifier("getchar")), .KList) 
          => flush(1) ~> readFromFD(0) 
          [structural]

     rule [fslFGetC]:
          prepareBuiltin((Identifier("__fslFGetC")),
               (tv(FD:Int, _),, tv(_:Int, _)))
          => readFromFD(FD:Int)
          [structural]

     rule [fslCloseFile]:
          <k> 
               prepareBuiltin((Identifier("__fslCloseFile")),
                    tv(FD:Int, t(_, int))) 
               => tv(0, t(.Set, int))
          ...</k>
          (<file>... <fid> FD:Int </fid> ...</file> => .Bag)
          [structural]

     rule [fslOpenFile-pre]:
          prepareBuiltin((Identifier("__fslOpenFile")),
               (Filename:KResult,, Mode:KResult))
          => fsl-open-file(getString(Filename:KResult), getString(Mode:KResult))
          [structural]
     
     syntax K ::= "fsl-open-file-aux" "(" String "," String "," K ")"
          [strict(3)]
     
     rule [fslOpenFile-aux]:
          fsl-open-file(str(Filename:String), str(Mode:String))
          => fsl-open-file-aux("file:" +String Filename:String, Mode:String,
               #open("file:" +String Filename:String
                    +String "#" +String Mode:String))
          [structural]

     rule [fslOpenFile]:
          <k> 
               fsl-open-file-aux(FileName:String, Mode:String, tv(FD:Int, _)) 
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

     //////////////////////////--  

     // C1X Here we might want to assume different threads cannot interleave
     // wrt printf, based on 7.1.4:5.  However, 7.1.4:4 seems to say exactly
     // the opposite.

     // on second thought, it probably is saying that while the shared data is
     // protected against races, it can still be interleaved

     // fixme despite the above, still need to handle interleaving of user data
     // read during evaluation of printf.  should use something like a buffer
     // to do this
     rule [printf]:
          prepareBuiltin((Identifier("printf")),
               (Format:KResult,, VarArgs:KResult))
          => new-printf-aux(formatter(
               getString(Format:KResult), VarArgs:KResult))
          [structural]
          
     rule [printf-done]:
          new-printf-aux(formattedResult(S:String))
               => writeToFD(1, S:String) 
                    ~> flush(1) 
                    ~> tv(lengthString(S:String), t(.Set, int)) 
          [structural]
     
     syntax K ::= "sprintf" "(" K "," SymLoc ")" [strict(1)]
     rule [sprintf]:
          prepareBuiltin((Identifier("sprintf")),
               (tv(Dest:SymLoc, _),, Format:KResult,, VarArgs:KResult))
          => sprintf(formatter(
               getString(Format:KResult), VarArgs:KResult), Dest)
          [structural]
     rule [sprintf-done]:
          sprintf(formattedResult(S:String), Dest:SymLoc)
          => writeString(Dest, S:String +String "\0") 
               ~> tv(lengthString(S:String), t(.Set, int))
          [structural]
     
     syntax K ::= "snprintf" "(" K "," SymLoc "," Int ")" [strict(1)]
     rule [snprintf]:
          prepareBuiltin((Identifier("snprintf")), 
               (tv(Dest:SymLoc, _),, tv(Len:Int, _),, Format:KResult,, VarArgs:KResult))
          => snprintf(formatter(
               getString(Format:KResult), VarArgs:KResult), Dest, Len:Int)
          [structural]
     rule [snprintf-done-nz]:
          snprintf(formattedResult(S:String), Dest:SymLoc, Len:Int)
          => writeString(Dest, substrString(S:String, 0, Len:Int -Int 1) +String "\0")
               ~> tv(lengthString(S:String), t(.Set, int))
          when Len:Int >Int 0
          [structural]
     rule [snprintf-done-0]:
          snprintf(formattedResult(S:String), _, 0)
          => tv(lengthString(S:String), t(.Set, int))
          [structural]
     
     syntax K ::= "new-printf-aux" "(" K ")" [strict]
     syntax K ::= "formatter" "(" K "," K ")" [strict(1)]
     syntax K ::= "formatter-aux" "(" K ")" [strict]
     syntax K ::= "formatter-next" "(" K ")"
     syntax K ::= "formatter-arg" "(" K ")" [strict(1)]
     rule formatter-next(vararg(tv(Loc:SymLoc, _)))
          => formatter-arg(nextvarg(Loc, getFormatType))
          [structural]
     rule <k> 
               formatter-arg(vpair(tv(K:K, _), V':KResult))
               => formatter-aux(V':KResult)
          ...</k>
          <formatArg> _ => K:K </formatArg>
          [structural]

     rule [format-start]:
          <k> 
               formatter(str(S:String), VarArgs:KResult)
               => formatter-aux(VarArgs:KResult)
          ...</k>
          (.Bag => 
               <formatting>...
                    <format> stringToList(S:String) </format>
               ...</formatting>
          )
          [structural]
     
     syntax Value ::= "formattedResult" "(" K ")"
     
     rule [format-done]:
          <k> 
               formatter-aux(_) 
               => formattedResult(listToString(Result:List))
          ...</k>
          (
               <formatting>...
                    <format> .List </format>
                    <formatResult> Result:List </formatResult>
                    <formatState> "normal" </formatState>
                    <formatModifiers> .Map </formatModifiers>
               ...</formatting>
               => .Bag
          )
          [structural]

     rule [format-normal]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem(S:String) => .List ...</format>
          <formatResult>... .List => ListItem(S:String) </formatResult>
          <formatState> "normal" </formatState>
          when S:String =/=String "%"
          [structural]
          
     rule [format-reset]:
          <k> formatter-aux(_) ...</k>
          <formatModifiers> _ => .Map </formatModifiers>
          <formatLength> _ => "" </formatLength>
          <formatState> "reset" => "normal" </formatState>
          [structural]

     rule [format-%]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem("%") => .List ...</format>
          <formatState> "normal" => "%" </formatState>
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
          <formatState> "%" </formatState>
          [structural]
          
     // ignoring num width
     rule [format-width]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem(C:String) => .List ...</format>
          <formatState> "%" </formatState>
          when asciiString(C:String) >Int asciiString("0")
          andBool asciiString(C:String) <=Int asciiString("9")
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
          <formatLength> Length:K </formatLength>
          <formatState> State:K </formatState>
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
          => t(.Set, pointerType(t(.Set, unsigned-char))) [structural]
     
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
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem(S:String) => .List ...</format>
          <formatState> "%" => "%d" </formatState>
          when S:String ==String "d" orBool S:String ==String "i"
          [structural]
     rule [format-%d]:
          <k> formatter-aux(_) ...</k>
          <formatArg> D:Int => .K </formatArg>
          <formatResult>...
               .List => ListItem(Int2String(D:Int))
          </formatResult>
          <formatState> "%d" => "reset" </formatState>
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
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("o") => .List ...</format>
          <formatState> "%" => "%o" </formatState>
          [structural]
     rule [format-%o]:
          <k> formatter-aux(_) ...</k>
          <formatArg> D:Int => .K </formatArg>
          <formatResult>...
               .List => ListItem(base2String(D:Int, 8))
          </formatResult>
          <formatState> "%o" => "reset" </formatState>
          [structural]
     rule [format-%u-start]:
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("u") => .List ...</format>
          <formatState> "%" => "%u" </formatState>
          [structural]
     rule [format-%u]:
          <k> formatter-aux(_) ...</k>
          <formatArg> D:Int => .K </formatArg>
          <formatResult>... 
               .List => ListItem(Int2String(D:Int))
          </formatResult>
          <formatState> "%u" => "reset" </formatState>
          [structural]
     rule [format-%x-start]:
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("x") => .List ...</format>
          <formatState> "%" => "%x" </formatState>
          [structural]
     rule [format-%x]:
          <k> formatter-aux(_) ...</k>
          <formatArg> D:Int => .K </formatArg>
          <formatResult>... 
               .List => ListItem(base2String(D:Int, 16)) 
          </formatResult>
          <formatState> "%x" => "reset" </formatState>
          [structural]
     rule [format-%X-start]:
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("X") => .List ...</format>
          <formatState> "%" => "%X" </formatState>
          [structural]
     rule [format-%X]:
          <k> formatter-aux(_) ...</k>
          <formatArg> D:Int => .K </formatArg>
          <formatResult>... 
               .List => ListItem(toUpperCase(base2String(D:Int, 16))) 
          </formatResult>
          <formatState> "%X" => "reset" </formatState>
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
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("f") => .List ...</format>
          <formatState> "%" => "%f" </formatState>
          [structural]
     rule [format-%f]:
          <k> formatter-aux(_) ...</k>
          <formatArg> D:Float => .K </formatArg>
          <formatResult>... 
               .List => ListItem(Float2String(D:Float)) 
          </formatResult>
          <formatState> "%f" => "reset" </formatState>
          [structural]
     rule [format-%F-start]:
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("F") => .List ...</format>
          <formatState> "%" => "%F" </formatState>
          [structural]
     rule [format-%F]:
          <k> formatter-aux(_) ...</k>
          <formatArg> D:Float => .K </formatArg>
          <formatResult>... 
               .List => ListItem(toUpperCase(Float2String(D:Float))) 
          </formatResult>
          <formatState> "%F" => "reset" </formatState>
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
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("g") => .List ...</format>
          <formatState> "%" => "%g" </formatState>
          [structural]
     rule [format-%g]:
          <k> formatter-aux(_) ...</k>
          <formatArg> D:Float => .K </formatArg>
          <formatResult>... 
               .List => ListItem(Float2String(D:Float)) 
          </formatResult>
          <formatState> "%g" => "reset" </formatState>
          [structural]
     rule [format-%G-start]:
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("G") => .List ...</format>
          <formatState> "%" => "%G" </formatState>
          [structural]
     rule [format-%G]:
          <k> formatter-aux(_) ...</k>
          <formatArg> D:Float => .K </formatArg>
          <formatResult>... 
               .List => ListItem(toUpperCase(Float2String(D:Float))) 
          </formatResult>
          <formatState> "%G" => "reset" </formatState>
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
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)
          ...</k>
          <format> ListItem("c") => .List ...</format>
          <formatState> "%" => "%c" </formatState>
          [structural]
     rule [format-%c]:
          <k> formatter-aux(_) ...</k>
          <formatArg> C:Int => .K </formatArg>
          <formatResult>... 
               .List => ListItem(#charString(((C:Int %Int 256) +Int 256) 
                    %Int 256)) 
          </formatResult>
          <formatState> "%c" => "reset" </formatState>
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
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)       
          ...</k>
          <format> ListItem("s") => .List ...</format>
          <formatState> "%" => "%s" </formatState>
          [structural]
     rule [format-%s]:
          <k> 
               (.K => getString(Loc))
               ~> formatter-aux(_)
          ...</k>
          <formatArg> Loc:SymLoc => .K </formatArg>
          <formatState> "%s" => "%s-read" </formatState>
          [structural]
     rule [format-%s-done]:
          <k> 
               (str(S:String) => .K)
               ~> formatter-aux(_)
          ...</k>
          <formatResult>... 
               .List => ListItem(S:String)
          </formatResult>
          <formatState> "%s-read" => "reset" </formatState>
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
          <k> 
               formatter-aux(V:KResult)
               => formatter-next(V:KResult)       
          ...</k>
          <format> ListItem("p") => .List ...</format>
          <formatState> "%" => "%p" </formatState>
          [structural]
     rule [format-%p]:
          <k> formatter-aux(_) ...</k>
          <formatArg> Loc:SymLoc => .K </formatArg>
          <formatResult>...
               .List => ListItem(pointerToString(Loc))
          </formatResult>
          <formatState> "%p" => "reset" </formatState>
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
          <formatResult>...
               .List => ListItem("%") 
          </formatResult>
          <formatState> "%" => "reset" </formatState>
          [structural]

     rule [format-%l]:
          <k> formatter-aux(_) ...</k>
          <format> ListItem("l") => .List ...</format>
          <formatState> "%" </formatState>
          <formatLength>
               Length:String => Length:String +String "l"
          </formatLength>
          [structural]
endmodule


module DYNAMIC-C-STANDARD-LIBRARY-STDLIB
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
     
     rule [debug]:
          prepareBuiltin(Identifier("__debug"), _) => skipval
          [interpRule]
     rule [debug-k]: debug => .
          [interpRule]
     rule [debug-m]: debug-m(_) => .
          [interpRule]
     
     rule [exit]:
          <k> 
               prepareBuiltin((Identifier("exit")), tv(I:Int, t(_, int))) ~> _
               => tv(I:Int, t(.Set, int)) 
          </k>
          [structural]

     rule [abort]:
          <k> 
               prepareBuiltin((Identifier("abort")), .KList) ~> _ 
               => printString("Aborted") ~> tv(134, t(.Set, int)) 
          </k>
     
     /*@ \fromStandard{\source[n1570]{\para{7.22.3.4}{2--3}}}{
     The \cinline{malloc} function allocates space for an object whose size is
     specified by \cinline{size} and whose value is indeterminate.

     The malloc function returns either a null pointer or a pointer to the
     allocated space.
     }*/
     syntax K ::= "newAlloc" "(" Int ")" [function]
     rule newAlloc(Fresh:Int) => loc(Fresh @ allocatedDuration, 0, 0)
     
     rule [malloc]:
          <k> 
               prepareBuiltin((Identifier("malloc")), tv(Len:Int, _:KResult))
               => alloc(newAlloc(Fresh:Int), Len:Int)
                    ~> tv(newAlloc(Fresh:Int), 
                         t(.Set, pointerType(t(.Set, void))))
          ...</k>
          <malloced>... .Map => newAlloc(Fresh:Int) |-> Len:Int ...</malloced>
          <freshNat> Fresh:Int => Fresh:Int +Int 1 </freshNat>
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{7.22.3.5}{2--4}}}{
     The \cinline{realloc} function deallocates the old object pointed to by
     \cinline{ptr} and returns a pointer to a new object that has the size
     specified by \cinline{size}. The contents of the new object shall be the
     same as that of the old object prior to deallocation, up to the lesser of
     the new and old sizes. Any bytes in the new object beyond the size of the
     old object have indeterminate values.

     If \cinline{ptr} is a null pointer, the \cinline{realloc} function behaves
     like the \cinline{malloc} function for the specified size. Otherwise, if
     \cinline{ptr} does not match a pointer earlier returned by a memory
     management function, or if the space has been deallocated by a call to the
     \cinline{free} or \cinline{realloc} function, the behavior is undefined.
     If memory for the new object cannot be allocated, the old object is not
     deallocated and its value is unchanged.

     The \cinline{realloc} function returns a pointer to the new object (which
     may have the same value as a pointer to the old object), or a null pointer
     if the new object could not be allocated.
     }*/
     rule [realloc]:
          <k> 
               prepareBuiltin((Identifier("realloc")), (tv(OldLoc:SymLoc, _),, 
                    tv(NewLen:Int, _:KResult)))
               => realloc(OldLoc, newAlloc(Fresh:Int), OldLen:Int, NewLen:Int)
                    ~> tv(newAlloc(Fresh:Int), t(.Set, pointerType(t(.Set, void))))
          ...</k>
          <malloced>... 
               (OldLoc => newAlloc(Fresh:Int)) |-> (OldLen:Int => NewLen:Int) 
          ...</malloced>
          <freshNat> Fresh:Int => Fresh:Int +Int 1 </freshNat>
          when OldLoc =/=K NullPointer
          [structural]
     
     rule [realloc-null]:
          prepareBuiltin((Identifier("realloc")), 
               (tv(NullPointer, _),, Len:KResult)) 
          => prepareBuiltin((Identifier("malloc")), Len:KResult)
          [structural]

     syntax K ::= "calloc-aux"
     rule [calloc]:
          prepareBuiltin((Identifier("calloc")), 
               (tv(N:Int, _),, tv(Size:Int, _)))
          => prepareBuiltin((Identifier("malloc")),
               tv(N:Int *Int Size:Int, cfg:sizeut))
          ~> calloc-aux
          [structural]
     rule [calloc-aux]:
          (. => zeroBlock(Loc:SymLoc) ) 
          ~> tv(Loc, t(_, pointerType(t(_, void))))
          ~> (calloc-aux => .K)
          [structural]

     rule [free]:
          <k> 
               prepareBuiltin((Identifier("free")),
                    tv(Loc:SymLoc, t(_, pointerType(_))))
               => deleteSizedBlock(Loc, Len:Int) 
                    ~> skipval
          ...</k>
          <malloced>... Loc |-> Len:Int => .Map ...</malloced>
          [structural]
          
     // Returns a pseudo-random integral number in the range 0 to RAND_MAX
     // fixme should use RAND_MAX
     rule [rand]:
          <k> 
               prepareBuiltin((Identifier("rand")), .KList)
               => tv(absInt(randomRandom(Fresh:Int)) 
                    %Int max(t(.Set, int)), t(.Set, int))
          ...</k>
          <randNat> Fresh:Int => Fresh:Int +Int 1 </randNat>
          [structural]
          
     rule [srand]:
          <k> 
               prepareBuiltin((Identifier("srand")),
                    tv(N:Int, t(.Set, unsigned-int)))
               => skipval
          ...</k>
          <randNat> _ => N:Int </randNat>
          [structural]

endmodule

module DYNAMIC-C-STANDARD-LIBRARY-STRING
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
     
     // try to use getString
     // fixme should detect overlaps
     syntax K ::= "strcpy" "(" SymLoc "," SymLoc "," SymLoc ")"
     rule [strcpy-start]:
          prepareBuiltin((Identifier("strcpy")), 
               (tv(Dest:SymLoc, t(_, pointerType(_))),, 
               tv(Src:SymLoc, t(_, pointerType(_)))))
          => strcpy(Dest, Src, Dest)
          [structural]
          
     rule [strcpy-pre]:
          (. => read(Src:SymLoc, t(.Set, char))) 
          ~> strcpy(_, (Src => Src +bytes 1), _)
          [structural]
     
     rule [strcpy-some]:
          (tv(I:Int, T:KResult) => write(lv(Dest, t(.Set, char)), tv(I, T)))
          ~> strcpy((Dest:SymLoc => Dest +bytes 1), _, _)
          when I =/=Int 0
          [structural]
     rule [strcpy-done]:
          tv(0, T:KResult) 
               ~> strcpy(Dest:SymLoc, _, Orig:SymLoc)
          => write(lv(Dest, t(.Set, char)), tv(0, T)) 
               ~> tv(Orig, t(.Set, pointerType(t(.Set, char))))
          [structural]
endmodule

module DYNAMIC-C-STANDARD-LIBRARY-THREADS
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
     
     ////////////////////////////--
     // Threads
     ////////////////////////////--
     syntax K ::= "thrd-success" | "thrd-error" | "thrd-timeout" 
                | "thrd-busy" | "thrd-nomem"
     rule thrd-success => tv(0, t(.Set, int)) [macro]
     rule thrd-error => tv(1, t(.Set, int)) [macro]
     rule thrd-timeout => tv(2, t(.Set, int)) [macro]
     rule thrd-busy => tv(3, t(.Set, int)) [macro]
     rule thrd-nomem => tv(4, t(.Set, int)) [macro]
     
     syntax K ::= "threadRunning"
     
     syntax K ::= "spawn-aux" "(" Int "," Value "," Value ")"
     rule [thrd-create-start]:
          <k> 
               prepareBuiltin((Identifier("thrd_create")), 
                    (ThreadIdPointer:KResult,, ThreadFuncPointer:KResult,, 
                    ThreadArg:KResult))
               => Computation(
                    (* ThreadIdPointer:KResult) := tv(Fresh:Int, t(.Set, int)))
                    ~> spawn-aux(
                    Fresh:Int, ThreadFuncPointer:KResult, ThreadArg:KResult)
          ...</k>
          <nextThreadId> Fresh:Int => Fresh:Int +Int 1 </nextThreadId>
          [structural]
     /*
     See http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1521.htm
     */
     rule [thrd-create]:
          <thread>...
               <k> 
                    spawn-aux(
                         ThreadId:Int, ThreadFuncPointer:KResult, ThreadArg:KResult) 
                    => thrd-success 
               ...</k>
               <currTU> Tu:K </currTU>
               <buffer> .List </buffer>
          ...</thread>
          <genv> Env:Map </genv>
          <threadStatus> 
               Status:Map => Status:Map[threadRunning / ThreadId:Int]
          </threadStatus>
          <br/>
          (.Bag =>
          <thread>...
               <nextLoc> firstLoc(ThreadId:Int) </nextLoc>
               <threadId> ThreadId:Int </threadId>
               <k> 
                    Call(ThreadFuncPointer:KResult, klist(ThreadArg:KResult)) 
               </k>
               <env> Env:Map </env>
               <currTU> Tu:K </currTU>
          ...</thread>)
          [large, computational]
          
     rule [thrd-current]:
          <k> 
               prepareBuiltin((Identifier("thrd_current")), .KList)
               => tv(ThreadId:Int, t(.Set, int))
          ...</k>
          <threadId> ThreadId:Int </threadId>
          [structural]
          
     syntax K ::= "join-aux" "(" Int "," Value ")"
          
     rule [thrd-join-start]:
          prepareBuiltin((Identifier("thrd_join")),
               (tv(ThreadId:Int, t(_, int)),, ResultPointer:KResult))
          => join-aux(ThreadId:Int, ResultPointer:KResult)
          [structural]
     
     rule [thrd-join]:
          <thread>...
               <k> 
                    join-aux(ThreadId:Int, tv(Loc:SymLoc, _))
                    => #if (Loc =/=K NullPointer) 
                         #then Computation((* Loc) := V:KResult) 
                         #else .K
                         #fi
                         ~> thrd-success
               ...</k>
               <buffer> .List </buffer>
          ...</thread>
          <thread>...
               <k> V:KResult </k>
               <threadId> ThreadId:Int </threadId>
          ...</thread>
          [computational]

     rule [mtx-init]:
          <k> 
               prepareBuiltin((Identifier("mtx_init")),
               (tv(Loc:Int, _),, tv(Type:Int, _)))
               => thrd-success
          ...</k>
          <mutexes> M:Map (. => Loc |-> Type:Int) </mutexes>
          // only handling plain mutexes for now
          when notBool (Loc in keys M:Map)
               andBool (Type ==Int cfg:mtxPlain) 
          [structural]

     rule [mtx-lock]:
          <k> 
               prepareBuiltin((Identifier("mtx_lock")), (tv(Loc:Int, _)))
               => thrd-success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc |-> Type:Int ...</mutexes>
          <glocks> B:Bag (.Bag => BagItem(Loc)) </glocks>
          <locks>... .Bag => BagItem(Loc) ...</locks>
          when (notBool (Loc #inBag B))
          andBool (Type:Int ==Int cfg:mtxPlain)
          [computational]

     rule [mtx-unlock]:
          <k> 
               prepareBuiltin((Identifier("mtx_unlock")), (tv(Loc:Int, _)))
               => thrd-success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc:Int |-> Type:Int ...</mutexes>
          <glocks>... BagItem(Loc:Int) => .Bag ...</glocks>
          <locks>... BagItem(Loc:Int) => .Bag ...</locks>
          when Type:Int ==Int cfg:mtxPlain
          [computational]

endmodule

module DYNAMIC-C-STANDARD-LIBRARY-TIME
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
     
     // fixme, just a placeholder
     rule [time]:
          prepareBuiltin((Identifier("time")), _:KResult) 
          => tv(0, t(.Set, long-long-int))
          [structural]

endmodule

module DYNAMIC-C-STANDARD-LIBRARY-MISC
     imports DYNAMIC-C-STANDARD-LIBRARY-INCLUDE
endmodule

module DYNAMIC-C-STANDARD-LIBRARY
     ////////////////////////////////
     //- C standard library
     imports DYNAMIC-INCLUDE
     imports DYNAMIC-C-STANDARD-LIBRARY-HELPERS
     
     imports DYNAMIC-C-STANDARD-LIBRARY-MATH
     imports DYNAMIC-C-STANDARD-LIBRARY-SETJMP
     imports DYNAMIC-C-STANDARD-LIBRARY-STDARG
     imports DYNAMIC-C-STANDARD-LIBRARY-STDDEF
     imports DYNAMIC-C-STANDARD-LIBRARY-STDIO 
     imports DYNAMIC-C-STANDARD-LIBRARY-STDLIB
     imports DYNAMIC-C-STANDARD-LIBRARY-STRING
     imports DYNAMIC-C-STANDARD-LIBRARY-THREADS
     imports DYNAMIC-C-STANDARD-LIBRARY-TIME
     
     imports DYNAMIC-C-STANDARD-LIBRARY-MISC
endmodule
