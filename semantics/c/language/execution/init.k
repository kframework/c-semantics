module C-EXECUTION-INIT-SYNTAX
     imports LIST
     imports STRING
     imports SET
     imports COMMON-SORTS
     syntax KItem ::= pgmArgs(List) [function]
     syntax KItem ::= incomingArguments(List)
     syntax KItem ::= callEntryPoint(String, Int, KItem)
     syntax KItem ::= initMainThread(String)
     syntax KItem ::= "initMainThread'" "(" String ")"
     syntax KItem ::= "callAtExit" | "callAtQuickExit"
     syntax RValue ::= "NullPointerConstant" [function]
endmodule

module C-EXECUTION-INIT
     imports C-EXECUTION-INIT-SYNTAX
     imports C-CONFIGURATION

     imports K-EQUAL
     imports K-IO
     imports STRING

     imports BITS-SYNTAX
     imports COMMON-BUILTIN-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports OPTIONS-SYNTAX
     imports SETTINGS-SYNTAX

     imports C-CHECK-RESTRICT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-IO-SYNTAX
     imports LIBCPP-BOOTSTRAP-SYNTAX

     syntax TCell ::= ".TCell" [klabel(.TCell), symbol]

     /*@ \fromStandard{\source[n1570]{\para{5.1.2.2.1}{2}}}{
     If they are declared, the parameters to the main function shall obey the
     following constraints:
     \begin{itemize}
     \item The value of \cinline{argc} shall be nonnegative.

     \item \cinline{argv[argc]} \cinline{shall} be a null pointer.

     \item If the value of \cinline{argc} is greater than zero, the array
     members \cinline{argv[0]} through \cinline{argv[argc-1]} inclusive shall
     contain pointers to strings, which are given implementation-defined values
     by the host environment prior to program startup. The intent is to supply
     to the program information determined prior to program startup from
     elsewhere in the hosted environment. If the host environment is not
     capable of supplying strings with letters in both uppercase and lowercase,
     the implementation shall ensure that the strings are received in
     lowercase.

     \item If the value of argc is greater than zero, the string pointed to by
     \cinline{argv[0]} represents the program name; \cinline{argv[0][0]} shall
     be the null character if the program name is not available from the host
     environment. If the value of \cinline{argc} is greater than one, the
     strings pointed to by \cinline{argv[1]} through \cinline{argv[argc-1]}
     represent the program parameters.

     \item The parameters \cinline{argc} and \cinline{argv} and the strings
     pointed to by the \cinline{argv} array shall be modifiable by the program,
     and retain their last-stored values between program startup and program
     termination.

     \end{itemize}
     }*/

     rule V:Hold => value(V)
          [structural]

     rule toRVal(R:RValue) => R
          [structural]

     rule NullPointerConstant
          => tv(NullPointer, utype(pointerType(type(void))))

     syntax Type ::= strType(String) [function]
     rule strType(S::String)
          => type(arrayType(type(char), lengthString(S) +Int 1))

     rule incomingArguments(L::List) => #incomingArguments(L, 0)
          [structural]

     syntax KItem ::= #incomingArguments(List, Int)
     rule #incomingArguments(ListItem(S:String) L::List, N::Int)
          => allocObject(bnew(N +Int 1, strType(S), argv), strType(S))
          ~> writeString(lnew(bnew(N +Int 1, strType(S), argv)), S)
          ~> Initializer(*(mainArguments + tv(N, utype(int))) := lv(lnew(bnew(N +Int 1, strType(S), argv)), strType(S)))
          ~> #incomingArguments(L, N +Int 1)
          [structural]
     rule #incomingArguments(.List, N::Int)
          => Initializer(*(mainArguments + tv(N, utype(int))) := NullPointerConstant)
          [structural]

     rule pgmArgs(L:List)
          => makeArgv(mainArguments,
               type(arrayType(type(pointerType(type(char))),
               size(L) +Int 1)))
          [structural]

     syntax KItem ::= makeArgv(CId, Type)
     rule makeArgv(X::CId, T::Type)
          => allocObject(bnew(0, T, argv), T)
          ~> addToEnv(X, bnew(0, T, argv))
          ~> giveType(X, T)
          [structural]

     /*@ These helpers are used to get around a bug in \K related to successive
     ``/''s in strings. */
     syntax KItem ::= "stdinStr" [function] | "stdoutStr" [function]

     rule stdinStr => "stdin:/" +String "/" +String "/"
     rule stdoutStr => "stdout:/" +String "/" +String "/"

     rule <k> initMainThread(EP::String) => initMainThread'(getTU(Base)) ...</k>
          <external-defs>... Identifier(EP) |-> Base::SymBase ...</external-defs>
          [structural]

     rule <threads>
               <thread>...
                    <k> initMainThread'(MainTU:String)
                         => initBuiltins
                         ~> initCPPBuiltins
                         ~> populateFromGlobal(.K)
                    ...</k>
                    <duration> _ => auto(0) </duration>
                    <curr-tu> _ => MainTU </curr-tu>
               ...</thread>
          </threads>
          <open-files> _ => (#stdin |-> "") (#stdout |-> "") (#stderr |-> "") </open-files>
          <files>...
               ( .Bag =>
               <file>...
                    <fid> #stdin </fid>
                    <uri> stdinStr </uri>
                    <mode> "r" </mode>
                    <buffer-mode> lineBuf </buffer-mode>
               ...</file>
               <file>...
                    <fid> #stdout </fid>
                    <uri> stdoutStr </uri>
                    <mode> "w" </mode>
                    <buffer-mode> lineBuf </buffer-mode>
               ...</file>
               <file>...
                    <fid> #stderr </fid>
                    <uri> stdoutStr </uri>
                    <mode> "w" </mode>
                    <buffer-mode> noBuf </buffer-mode>
               ...</file>)
          ...</files>
          requires MainTU =/=K .K
          [structural]

     /*@
     \begin{lrbox}{\LstBox}
     \begin{lstlisting}
     int main(void) { ... }
     \end{lstlisting}
     \end{lrbox}
     \begin{lrbox}{\LstBoxb}
     \begin{lstlisting}
     int main(int argc, char *argv[]) { ... }
     \end{lstlisting}
     \end{lrbox}
     \fromStandard{\source[n1570]{\para{5.1.2.2.1}{1}}}{
     The function called at program startup is named \cinline{main}. The
     implementation declares no prototype for this function. It shall be
     defined with a return type of \cinline{int} and with no parameters:

     \usebox{\LstBox}

     or with two parameters (referred to here as \cinline{argc} and
     \cinline{argv}, though any names may be used, as they are local to the
     function in which they are declared):

     \usebox{\LstBoxb}

     or equivalent; or in some other implementation-defined manner.
     }*/

     /*@ this bit of indirection is used to check that the main prototype is
      correct, and to call it with the appropriate arguments */
     rule <k> callEntryPoint(EP::String, N::Int, Args::KItem)
               => enterRestrictTU
               ~> reval(#callEntryPoint(EP, N, Args, T))
               ~> callAtExit
          ...</k>
          <types>... Identifier(EP) |-> T::Type ...</types>
          <status> _ => mainCalled </status>
          [ndtrans]

     // int main(void) -- also, int main() gets normalized to main(void)
     syntax K ::= #callEntryPoint(String, Int, KItem, Type) [function]
     rule #callEntryPoint(Entry::String, _, _,
               t(quals(.Set), _, functionType(ut(.Set, int),
                    ListItem(typedDeclaration(t(quals(.Set), .Set, void), _)))))
          => Call(Identifier(Entry), list(.List))
     // int main(int argc, char* argv[]), int main(int argc, char** argv), and old style (no prototype).
     rule #callEntryPoint(Entry::String, N::Int, Args::KItem, _)
          => Args ~> Call(Identifier(Entry), list(ListItem(tv(N, utype(int))) ListItem(mainArguments)))
          [owise]

     rule <k> reval(V:RValue) ~> callAtExit => AtExit ~> reval(V) ~> callAtExit ...</k>
          <atexit> AtExit:KItem => .K ...</atexit>
          <status> _ => mainExited </status>
     rule <k> reval(V:RValue) ~> callAtExit => reval(V) ...</k>
          <atexit> .K </atexit>
          <status> _ => mainExited </status>

     rule <k> reval(V:RValue) ~> callAtQuickExit => AtExit:KItem ~> reval(V) ~> callAtQuickExit ...</k>
          <at-quick-exit> AtExit:KItem => .K ...</at-quick-exit>
          <status> _ => mainExited </status>
     rule <k> reval(V:RValue) ~> callAtQuickExit => reval(V) ...</k>
          <at-quick-exit> .K </at-quick-exit>
          <status> _ => mainExited </status>

     // fixme I'm not sure threads clean up their memory
     rule <exec>...
               (<thread>...
                    // main's thread, not the global "thread"
                    <thread-id> 0 </thread-id>
                    <k> reval(tv(I:Int, _)) </k>
               ...</thread> => .Bag)
          ...</exec>
          <status> _ => terminated </status>
          <result-value> _ => I </result-value>
          [ndtrans, priority(75)]

     rule <thread>...
               <thread-id> 0 </thread-id>
               <k> reval(tv(V::CValue => unknown(V), _)) </k>
          ...</thread>
          requires notBool isInt(V) andBool notBool isUnknown(V) [priority(75)]
     rule <thread>...
               <thread-id> 0 </thread-id>
               <k> (.K => UNSPEC("CEER6", "Unspecified value returned from main function."))
                    ~> reval(tv(unknown(_), _))
               </k>
          ...</thread> [priority(75)]

     rule <k> CabsLoc(File'::String, File::String, Line::Int, Col::Int, Sys::Bool) => breakpoint ...</k>
          <curr-program-loc> _ => CabsLoc(File', File, Line, Col, Sys) </curr-program-loc>
          <options>... SetItem(Breakpoint(File, Line) => ActiveBreakpoint(File, Line)) ...</options>
          [structural]
     rule <k> CabsLoc(File'::String, File::String, Line::Int, Col::Int, Sys::Bool) => .K ...</k>
          <curr-program-loc> _ => CabsLoc(File', File, Line, Col, Sys) </curr-program-loc>
          <options> Opts::Set => clearActiveBreakpoints(Opts) </options>
          requires notBool (Breakpoint(File, Line) in Opts)
          [structural]

     syntax Set ::= clearActiveBreakpoints(Set) [function]
     rule clearActiveBreakpoints(SetItem(ActiveBreakpoint(File::String, Line::Int)) Opts::Set)
          => SetItem(Breakpoint(File, Line)) clearActiveBreakpoints(Opts)
     rule clearActiveBreakpoints(SetItem(K:KItem) Opts::Set)
          => SetItem(K) clearActiveBreakpoints(Opts) [owise]
     rule clearActiveBreakpoints(.Set) => .Set

     /*@ \fromStandard{\source[n1570]{\para{6.8.3}{3}}}{
     A null statement (consisting of just a semicolon) performs no operations.
     }*/
     rule Nop() => .K
          [structural]

     rule [[ nameOfCurrentTranslationUnit() => TU ]]
          <curr-tu>TU::String</curr-tu>

     rule currentSemantics() => ExecutionSemantics()
endmodule

