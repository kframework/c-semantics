require "configuration.k"
require "settings.k"
require "expression.k"
require "statement.k"
require "conversion.k"
require "promotion.k"
require "typing.k"
require "memory.k"
require "declaration.k"
require "bitsize.k"
require "helpers.k"
require "io.k"
require "symloc.k"
require "error.k"
require "compat.k"
require "libc.k"

module C-DYNAMIC-SYNTAX
     syntax BaseValue ::= Float | Bits // Int is a subsort of Bits
     syntax C ::= BaseValue | Type | Value
     syntax KResult ::= Value | Type

     syntax K ::= "sequencePoint"
     syntax KResult ::= "skipval"
     syntax Type ::= "t" "(" Set "," SimpleType ")" [klabel('t)]
     syntax Value ::= "tv" "(" KList "," Type ")" 
          [klabel('tv), latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]
     syntax LValue ::= "lv" "(" SymLoc "," Type ")" [klabel('lv)]
     syntax Value ::= "lval" "(" SymLoc "," Type ")" [klabel('lval)]

     syntax Type ::= "type" "(" K ")" [function]
     syntax K ::= "value" "(" K ")" [function]

     syntax K ::= "discard"
     syntax Value ::= "emptyValue"
     
     syntax KResult ::= "dataList" "(" KList ")"

     syntax Int ::= "NullPointerConstant" [function]

     syntax K ::= "resolveReferences"
     syntax K ::= "pgmArgs" "(" KList ")" [function]
     syntax K ::= "incomingArguments" "(" KList ")" [klabel('incomingArguments)]
     syntax K ::= "callMain" "(" Int "," K ")" [klabel('callMain)]
     syntax K ::= "callMain-aux" "(" K "," Int "," Id "," K ")" [strict(1)]
endmodule

module C-DYNAMIC
     imports C-DYNAMIC-SYNTAX

     imports C-SYNTAX
     imports C-SETTINGS
     
     imports C-BITSIZE
     imports C-COMPAT
     imports C-CONFIGURATION
     imports C-CONVERSION
     imports C-DECLARATION
     imports C-ERROR
     imports C-EXPRESSION
     imports C-HELPERS
     imports C-MEMORY 
     imports C-PROMOTION
     imports C-STATEMENT
     imports C-TYPING 
     imports C-SYMLOC
     imports C-IO 

     imports LIBC

     rule value(tv(V:KList, _)) => V:KList
          [structural, anywhere]

     rule type(tv(_, T:KResult)) => T
          [structural, anywhere]
     rule type(T:Type) => T
          [structural, anywhere]
     rule type(lv(_, T:KResult)) => T
          [structural, anywhere]
     rule type(lval(_, T:KResult)) => T
          [structural, anywhere]

     rule NullPointerConstant => 0

     syntax K ::= "UnknownCabsLoc"
     rule [unknown-loc]: 
          CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc 
          [structural, anywhere]

     rule [expression-loc]: ExpressionLoc(K:K, _) => K
          [structural, anywhere]

     rule [CodeLoc-k]:
          <k> CodeLoc(K:K, L:CabsLoc) => K ...</k>
          <currentProgramLoc> _ => L:CabsLoc </currentProgramLoc>
          [structural]
          
     rule [sequencePoint]:
          <k> sequencePoint => .K ...</k>
          <locsWrittenTo> _ => .Bag </locsWrittenTo>
          [structural, ndlocal]

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
          
     rule AttributeWrapper(K:K, _) => K:K [structural, anywhere]
     
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
          
     syntax K ::= "syntaxInt" "(" Int ")"
     rule [syntaxInt]: 
          syntaxInt(N:Int) => NoSuffix(DecimalConstant(N:Int)) [structural]
     
     syntax K ::= "argName" "(" KList ")" [function]
     rule argName(L:KList)
          => Name(
               Identifier("#incomingArgumentsArray"), 
               PointerType(ArrayType(JustBase, 
                    syntaxInt((lengthKList L:KList) +Int 1), 
                    Specifier(klist(.KList))))
          )
     rule pgmArgs(L:KList)
          => DeclarationDefinition(InitNameGroup(
               Specifier(klist(Char)), 
               klist(InitName(argName(L:KList), NoInit))
          ))
          [structural]

     /*@ These helpers are used to get around a bug in \K related to successive
     ``/''s in strings. */
     syntax K ::= "stdinStr" [function] | "stdoutStr" [function]
     
     rule stdinStr => "stdin:/" +String "/" +String "/"
     rule stdoutStr => "stdout:/" +String "/" +String "/"

     rule <threads>
               <thread>...
                    <k> Program(klist(P:KList)) => klistToK(P) ...</k>
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
                         ...</control>
                    ...</threadLocal>
               ...</thread>
          </threads>
          <nextSharedLoc> _ => firstLoc(0) </nextSharedLoc>
          <br/>
          <files>
               <fileCommands> _ => 0 </fileCommands>
               <br/>
               ( _ =>
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
          </files>
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
               => callMain-aux(typeof(Identifier("main")), N:Int,
                    Identifier("#incomingArgumentsArray"), Args:K)
          ...</k>
          <funTUs>... 
               Tu:K |-> map((_ Identifier("main") |-> Tu:K)) 
          ...</funTUs>
          <currTU> _ => Tu:K </currTU>
          [computational]
     
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
               (typedDeclaration(t(.Set, int), _:Id),, 
               typedDeclaration(t(.Set,
               incompleteArrayType(t(.Set,
               pointerType(T:KResult)))), _:Id)))), N:Int, X:Id, Args:K)
          => Args:K ~> Call(Identifier("main"), klist((N:Int,, X:Id)))
          when T:KResult ==K t(.Set, char)
          [structural]
     rule callMain-aux(t(.Set,
               functionType(t(.Set, int),
               (typedDeclaration(t(.Set, int), _:Id),, 
               typedDeclaration(t(.Set,
               pointerType(t(.Set,
               pointerType(T:KResult)))), _:Id)))), N:Int, X:Id, Args:K)
          => Args:K ~> Call(Identifier("main"), klist((N:Int,, X:Id)))
          when T:KResult ==K t(.Set, char)
          [structural]

     // fixme I'm not sure threads clean up their memory
     rule [terminate]:
          (<T>...
               <thread>... 
                    // main's thread, not the global "thread"
                    <threadId> 1 </threadId>
                    <k> V:KResult </k>
               ...</thread>
          ...</T> => .Bag)
          <resultValue> .K => V </resultValue>
          <files>...
               // to prevent further io commands from firing
               <fileCommands> _ => .K </fileCommands>
               <file>... // stdout
                    <fid> 1 </fid>
                    <buff> S2'':String </buff>
                    <sending> L:List </sending>
                    <done> S2:ListItem </done>
               ...</file>
          ...</files>
          <output> _ (.List => S2 L ListItem(S2'')) </output>
          [computational]
endmodule
