module C-EXECUTION-INIT-SYNTAX
     syntax K ::= pgmArgs(KList) [function]
     syntax K ::= incomingArguments(KList) [klabel('incomingArguments)]
     syntax K ::= callMain(Int, K) [klabel('callMain)]
     syntax K ::= "callMain-aux" "(" K "," Int "," Id "," K ")" [strict(1)]
     syntax K ::= "initMainThread"

     syntax K ::= loadConfig(Bag)

endmodule

module C-EXECUTION-INIT
     imports C-EXECUTION-INIT-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-COMMON-EXPRESSION-IDENTIFIER-SYNTAX
     imports C-DECLARATION-LOCAL-SYNTAX
     imports LIBC-IO-SYNTAX
     imports COMPAT-SYNTAX
          
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
     
     syntax K ::= "incomingArguments-aux" "(" KList "," Int ")"
     
     rule incomingArguments(L:KList) 
          => incomingArguments-aux(L, 0) 
          [structural]
     rule incomingArguments-aux((S:String,, L:KList), N:Int) 
          => Computation(
               Identifier("#incomingArgumentsArray")[N] 
                    := Constant(StringLiteral(S)))
          ~> incomingArguments-aux(L:KList, N:Int +Int 1)
          [structural]
     rule incomingArguments-aux(.KList, N:Int) 
          => Computation(
               Identifier("#incomingArgumentsArray")[N] := NullPointerConstant)
          [structural]
          
     rule pgmArgs(L:KList)
          => makeArgv(
               Identifier("#incomingArgumentsArray"), 
               t(.Set, arrayType(t(.Set, pointerType(t(.Set, char))),
               (lengthKList L) +Int 1)))
          [structural]

     syntax K ::= makeArgv(Id, Type)
     rule makeArgv(X:Id, T:Type) 
          => allocateType(argvLoc, T)
          ~> addToEnv(X, argvLoc)
          ~> giveType(X, T)
          [structural]

     /*@ These helpers are used to get around a bug in \K related to successive
     ``/''s in strings. */
     syntax K ::= "stdinStr" [function] | "stdoutStr" [function]
     
     rule stdinStr => "stdin:/" +String "/" +String "/"
     rule stdoutStr => "stdout:/" +String "/" +String "/"

     rule <threads>
               <thread>...
                    <k> initMainThread => populateFromGlobal ...</k>
                    <nextLoc> _ => firstLoc(thread(0)) </nextLoc>
                    <threadLocal>...
                         <control>...
                              <currentFunction> 
                                   _ => file-scope
                              </currentFunction>
                              <currentProgramLoc>
                                   _ => UnknownCabsLoc
                              </currentProgramLoc>
                              <currTU> _ => MainTU </currTU>
                         ...</control>
                    ...</threadLocal>
               ...</thread>
          </threads>
          <mainTU> MainTU:K </mainTU>
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
          when MainTU =/=K .K
          [structural, large]
     
     syntax K ::= "loadConfig'" "(" TCellFragment ")"

     rule loadConfig(<generatedTop> <global> P:Bag </global> </generatedTop>) 
          => loadConfig'(P)

     rule <exec>
               <k> loadConfig'(C:Bag) => . ...</k>
               <global> (_:Bag => C) </global>
          ...</exec>
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
          <k> 
               callMain(N:Int, Args:K)
               => callMain-aux(typeof(Identifier("main")), N,
                    Identifier("#incomingArgumentsArray"), Args)
          ...</k>
          <status> _ => mainCalled </status>
          [ndtrans]
     
     // FIXME i think these are slightly different
     // fixme void isn't supposed to have a name
     // fixme figure out type of string
     rule callMain-aux(t(.Set, functionType(t(.Set, int),
               typedDeclaration(t(.Set, void), _:Id))), _:Int, _:Id, _) 
          => Call(Identifier("main"), klist(.KList))
          [structural]
     rule callMain-aux(t(.Set,
               functionType(t(.Set, int), .KList)), _:Int, _:Id, _) 
          => Call(Identifier("main"), klist(.KList))
          [structural]
     rule callMain-aux(t(.Set, functionType(t(.Set, int),
               (typedDeclaration(t(.Set, int), _:Id),, typedDeclaration(t(.Set, 
                    incompleteArrayType(t(.Set, 
                    pointerType(T:Type)))), _:Id)))), 
               N:Int, X:Id, Args:K)
          => Args ~> Call(Identifier("main"), klist((N,, X)))
          when T ==K t(.Set, char)
          [structural]
     rule callMain-aux(t(.Set,
               functionType(t(.Set, int),
               (typedDeclaration(t(.Set, int), _:Id),, typedDeclaration(t(.Set, 
                    pointerType(t(.Set,
                    pointerType(T:Type)))), _:Id)))), 
               N:Int, X:Id, Args:K)
          => Args ~> Call(Identifier("main"), klist((N,, X)))
          when T ==K t(.Set, char)
          [structural]

     // fixme I'm not sure threads clean up their memory
     rule [terminate]:
          (<exec>...
               <thread>... 
                    // main's thread, not the global "thread"
                    <threadId> 0 </threadId>
                    <k> V:KResult </k>
               ...</thread>
          ...</exec> => .Bag)
          <status> _ => mainExited </status>
          <resultValue> .K => V </resultValue>
          <files>...
               // Flush stdout.
               <fileCommands>... (. => f-flush(1)) </fileCommands>
          ...</files>
          [ndtrans]
endmodule

