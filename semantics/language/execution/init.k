module C-EXECUTION-INIT-SYNTAX
     imports LIST
     syntax KItem ::= pgmArgs(List) [function]
     syntax KItem ::= incomingArguments(List)
     syntax KItem ::= callMain(Int, K)
     syntax KItem ::= "initMainThread"
endmodule

module C-EXECUTION-INIT
     imports C-EXECUTION-INIT-SYNTAX

     imports C-CHECK-LOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports LIBC-IO-SYNTAX

     imports C-CONFIGURATION

     syntax TCell ::= ".TCell"

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

     syntax RValue ::= "NullPointerConstant" [function]
     rule NullPointerConstant
          => tv(NullPointer, t(.Set, pointerType(t(.Set, void))))

     syntax Type ::= strType(String) [function]
     rule strType(S:String)
          => t(.Set, arrayType(t(.Set, char), lengthString(S) +Int 1))

     syntax KItem ::= "incomingArguments-aux" "(" List "," Int ")"

     rule incomingArguments(L:List) => incomingArguments-aux(L, 0)
          [structural]
     rule incomingArguments-aux(ListItem(S:String) L:List, N:Int)
          => allocObject(N +Int 1 @ argv, strType(S))
          ~> writeString(lnew(N +Int 1 @ argv, strType(S)), S)
          ~> allowInit(Computation(
               *(Identifier("#incomingArgumentsArray") + tv(N, t(.Set, int)))
                    := lv(lnew(N +Int 1 @ argv, strType(S)), strType(S))))
          ~> incomingArguments-aux(L:List, N:Int +Int 1)
          [structural]
     rule incomingArguments-aux(.List, N:Int)
          => allowInit(Computation(
               *(Identifier("#incomingArgumentsArray") + tv(N, t(.Set, int)))
                    := NullPointerConstant))
          [structural]

     rule pgmArgs(L:List)
          => makeArgv(
               Identifier("#incomingArgumentsArray"),
               t(.Set, arrayType(t(.Set, pointerType(t(.Set, char))),
               (size(L)) +Int 1)))
          [structural]

     syntax KItem ::= makeArgv(CId, Type)
     rule makeArgv(X:CId, T:Type)
          => allocObject(0 @ argv, T)
          ~> addToEnv(X, 0 @ argv)
          ~> giveType(X, T)
          [structural]

     /*@ These helpers are used to get around a bug in \K related to successive
     ``/''s in strings. */
     syntax KItem ::= "stdinStr" [function] | "stdoutStr" [function]

     rule stdinStr => "stdin:/" +String "/" +String "/"
     rule stdoutStr => "stdout:/" +String "/" +String "/"

     syntax KItem ::= "initMainThread'" "(" String ")"

     rule <k> initMainThread => initMainThread'(MainTU) ...</k>
          <main-tu> SetItem(MainTU:String) </main-tu>
          [structural]

     rule <threads>
               <thread>...
                    <k> initMainThread'(MainTU:String)
                         => enterRestrictScope(fileScope)
                         ~> populateFromGlobal
                    ...</k>
                    <duration> _ => auto(0) </duration>
                    <curr-tu> _ => MainTU </curr-tu>
               ...</thread>
          </threads>
          <files>...
               ( .Bag =>
               <file>...
                    <fid> 0 </fid>
                    <uri> stdinStr </uri>
                    <mode> "r" </mode>
                    <buff> "" </buff>
               ...</file>
               <file>...
                    <fid> 1 </fid>
                    <uri> stdoutStr </uri>
                    <mode> "w" </mode>
               ...</file>
               <file>...
                    <fid> 2 </fid>
                    <uri> stdoutStr </uri>
                    <mode> "w" </mode>
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
     rule [call-main]:
          <k> callMain(N:Int, Args:K)
               => #callMain(T, N, Identifier("#incomingArgumentsArray"), Args)
          ...</k>
          <types>... Identifier("main") |-> T:Type ...</types>
          <status> _ => mainCalled </status>
          [ndtrans]

     // int main(void) -- also, int main() gets normalized to main(void)
     syntax KItem ::= #callMain(K, Int, CId, K) [strict(1)]
     rule #callMain(t(_,
          functionType(t(.Set, int), ListItem(typedDeclaration(t(.Set, void), _)))), _, _, _)
          => Call(Identifier("main"), list(.List))
          [structural]
     // int main(int argc, char* argv[])
     rule #callMain(t(_, functionType(t(.Set, int),
               ListItem(typedDeclaration(t(.Set, int), _))
               ListItem(typedDeclaration(t(.Set, incompleteArrayType(t(.Set, pointerType(T:Type)))), _)))),
               N:Int, X:CId, Args:K)
          => Args ~> Call(Identifier("main"), list(ListItem(N) ListItem(X)))
          requires T ==K t(.Set, char)
          [structural]
     // int main(int argc, char** argv)
     rule #callMain(t(_,
               functionType(t(.Set, int),
               ListItem(typedDeclaration(t(.Set, int), _))
               ListItem(typedDeclaration(t(.Set, pointerType(t(.Set, pointerType(T:Type)))), _)))),
               N:Int, X:CId, Args:K)
          => Args ~> Call(Identifier("main"), list(ListItem(N) ListItem(X)))
          requires T ==K t(.Set, char)
          [structural]

     // fixme I'm not sure threads clean up their memory
     rule [terminate]:
          (<exec>...
               <thread>...
                    // main's thread, not the global "thread"
                    <thread-id> 0 </thread-id>
                    <k> V:RValue </k>
               ...</thread>
          ...</exec> => .Bag)
          <status> _ => mainExited </status>
          <result-value> _ => value(V):>CValue </result-value>
          <files>...
               // Flush stdout.
               <file-commands>... (.K => f-flush(1)) </file-commands>
          ...</files>
          [ndtrans]

     rule <k> L:CabsLoc => .K ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
          [structural]

endmodule

