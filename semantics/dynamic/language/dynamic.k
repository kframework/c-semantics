require "expression.k"
require "statement.k"
require "binding.k"
require "builtin.k"

module C-DYNAMIC-SYNTAX
     syntax K ::= "sequencePoint"
     syntax Type ::= t(Set, SimpleType) [klabel('t)]

     syntax Value ::= "skipval"
     syntax TypedValue ::= tv(KList, Type) 
          [klabel('tv), latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]
     syntax LValue ::= "lv" "(" SymLoc "," Type ")" [klabel('lv)]
     syntax Value ::= "lval" "(" SymLoc "," Type ")" [klabel('lval)]

     syntax Type ::= type(K) [function]
     syntax K ::= value(TypedValue) [function]

     syntax K ::= "discard"
     syntax Value ::= "emptyValue"
     
     syntax Int ::= "NullPointerConstant" [function]

     syntax K ::= "resolveReferences"
     syntax K ::= "pgmArgs" "(" KList ")" [function]
     syntax K ::= "incomingArguments" "(" KList ")" [klabel('incomingArguments)]
     syntax K ::= "callMain" "(" Int "," K ")" [klabel('callMain)]
     syntax K ::= "callMain-aux" "(" K "," Int "," Id "," K ")" [strict(1)]
     syntax K ::= "initMainThread"

     syntax Status ::= "initializing" | "mainCalled" | "mainExited"

     syntax BaseValue ::= Float | Bits // Int is a subsort of Bits
     syntax C ::= BaseValue | Type | Value
     syntax Value ::= TypedValue
     syntax KResult ::= Value | Type
endmodule

module C-DYNAMIC
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-EXPRESSION-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX

     imports COMPAT-SYNTAX

     imports LIBC-IO-SYNTAX

     rule value(tv(V:KList, _)) => V

     rule type(tv(_, T:Type)) => T
     rule type(T:Type) => T
     rule type(lv(_, T:Type)) => T
     rule type(lval(_, T:Type)) => T

     rule NullPointerConstant => 0

     syntax CabsLoc ::= "UnknownCabsLoc"
     rule [unknown-loc]: 
          CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc 
          [structural, anywhere]

     rule [expression-loc]: ExpressionLoc(K:K, _) => K
          [structural, anywhere]

     rule [CodeLoc-k]:
          <k> CodeLoc(K:K, L:CabsLoc) => K ...</k>
          <currentProgramLoc> _ => L </currentProgramLoc>
          [structural]
          
     rule [sequencePoint]:
          <k> sequencePoint => .K ...</k>
          <locsWrittenTo> _ => .Bag </locsWrittenTo>
          [structural]

     rule [discard]:
          _:KResult ~> discard => .
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.10.6}{1}}}{
     A preprocessing directive of the form
     \cdisplay{# pragma pp-tokensoptnew-line}
     \broken{where the preprocessing token \cinline{STDC} does not immediately
     follow pragma in the directive (prior to any macro replacement)} causes the
     implementation to behave in an implementation-defined manner. The behavior
     might cause translation to fail or cause the translator or the resulting
     program to behave in a non-conforming manner. Any such pragma that is not
     recognized by the implementation is ignored.
     }*/
     rule [Pragma]: Pragma(_:K) => .
          [structural]
          
     rule AttributeWrapper(K:K, _) => K [structural, anywhere]
     
     rule Identifier("___missing_field_name") => #NoName [structural, anywhere]

     rule NothingExpression => emptyValue
     
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
          
     // syntax K ::= "syntaxInt" "(" Int ")"
     // rule [syntaxInt]: 
     // syntaxInt(N:Int) => NoSuffix(DecimalConstant(N:Int)) [structural]
     // 
     // syntax K ::= "argName" "(" KList ")" [function]
     // rule argName(L:KList)
     //      => Name(
     //           Identifier("#incomingArgumentsArray"), 
     //           PointerType(ArrayType(JustBase, 
     //                syntaxInt((lengthKList L) +Int 1), 
     //                Specifier(klist(.KList))))
     //      )
     // rule pgmArgs(L:KList)
     //      => DeclarationDefinition(InitNameGroup(
     //           Specifier(klist(Char)), 
     //           klist(InitName(argName(L), NoInit))
     //      ))
     //      [structural]

     rule pgmArgs(L:KList)
          => declareOnly(
               Identifier("#incomingArgumentsArray"), 
               t(.Set, arrayType(t(.Set, pointerType(t(.Set, char))), lengthKList L)),
               noLinkage)
          [structural]

     /*@ These helpers are used to get around a bug in \K related to successive
     ``/''s in strings. */
     syntax K ::= "stdinStr" [function] | "stdoutStr" [function]
     
     rule stdinStr => "stdin:/" +String "/" +String "/"
     rule stdoutStr => "stdout:/" +String "/" +String "/"

     rule <threads>
               <thread>...
                    <k> initMainThread => populateFromGlobal ...</k>
                    <br/>
                    <threadId> _ => 1 </threadId>
                    <nextLoc> _ => firstLoc(1) </nextLoc>
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
                    <threadId> 1 </threadId>
                    <k> V:KResult </k>
               ...</thread>
          ...</exec> => .Bag)
          <status> _ => mainExited </status>
          <resultValue> .K => V </resultValue>
          <files>...
               // To prevent further io commands from firing and flush stdout.
               <fileCommands> _ => f-flush(1) </fileCommands>
          ...</files>
          [ndtrans]
endmodule

module C
     imports C-SYNTAX

     imports C-COMMON

     imports C-DYNAMIC
     imports C-EXPRESSION
     imports C-STATEMENT
     imports C-BINDING
     imports C-BUILTIN
endmodule
