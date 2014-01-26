module C-EXPR-FUNCTION-CALL-SYNTAX
     syntax K ::= "application'" "(" String "," K "," KList ")" [strict(2)]
endmodule

module C-EXPR-FUNCTION-CALL
     imports C-EXPR-FUNCTION-CALL-SYNTAX
     imports C-COMMON-EXPR-IDENTIFIER-SYNTAX

     imports C-DECL-INITIALIZER-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-BINDING-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX

     imports COMPAT-SYNTAX

     syntax K ::= application(String, K, KList) [strict(2)]

     // TODO(chathhorn): KList heating bug
     rule application(Tu:String, K:K, L:KList) 
          => K ~> application(Tu, HOLE, L) [heat]
     rule K:K ~> application(Tu:String, HOLE, L:KList) 
          => application(Tu, K, L) [cool]

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.2}{3}}}{
     A postfix expression followed by parentheses \cinline{()} containing a
     possibly empty, comma-separated list of expressions is a function call.
     The postfix expression denotes the called function. The list of
     expressions specifies the arguments to the function.
     }*/
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.2}{6}}}{
     \broken{If the expression that denotes the called function has a type that
     does not include a prototype, the integer promotions are performed on each
     argument, and arguments that have type \cinline{float} are promoted to
     \cinline{double}. These are called the default argument promotions. If the
     number of arguments does not equal the number of parameters, the behavior
     is undefined. If the function is defined with a type that includes a
     prototype, and either the prototype ends with an ellipsis (\cinline{,
     ...}) or the types of the arguments after promotion are not compatible
     with the types of the parameters, the behavior is undefined. If the
     function is defined with a type that does not include a prototype, and the
     types of the arguments after promotion are not compatible with those of
     the parameters after promotion, the behavior is undefined, except for the
     following cases: 
     
     \begin{itemize}
     \item one promoted type is a signed integer type, the other promoted type
     is the corresponding unsigned integer type, and the value is representable
     in both types;

     \item both types are pointers to qualified or unqualified versions of a
     character type or \cinline{void}.

     \end{itemize}
     }}*/

     syntax K ::= "Call'" "(" K "," K ")"
     syntax KResult ::= rvlist(KList)

     syntax K ::= revalParams(K)
     context revalParams(klist(_,, (HOLE => reval(HOLE)),, _)) [ndheat]
     rule revalParams(klist(L:KList)) => revalParams(rvlist(L))
          when all(L, isKResult)
          [structural]
     
     rule Call(F:KResult, K:K) 
          => sequencePoint ~> Call'(F, K) 

     context Call'(_, (HOLE => revalParams(HOLE)))

     rule [function-application-pre]:
          <k> Call'(tv(Loc:SymLoc, t(_, pointerType(T:Type))), rvlist(L:KList))
          => sequencePoint ~> application(getTU(Loc), Fun, L)
          ...</k>
          <functions>... Loc |-> Fun:KResult ...</functions>
          when isFunctionType(T)
          [structural]

     /*@ This extra step is useful for putting the function name in the
        transition graph. */
     rule [call]:
          application(Tu:String, Fun:KResult, L:KList) 
          => application'(Tu, Fun, L:KList)
          [structural]

     rule [function-application]:
          <k> 
               application'(Tu:String, functionObject(X:Id, 
                    t(_, functionType(_:Type, P:KList)), B:K), L:KList) 
                    ~> K:K 
               => sequencePoint
                    ~> populateFromGlobal
                    ~> bind(L, P)
                    ~> B
          </k>
          <callStack> .List => ListItem(
               <callStackFrame>...
                    <stackControl> 
                         <currTU> OldTu:K </currTU>
                         C:Bag 
                    </stackControl>
                    <continuation> K:K </continuation>
                    <stackCurrentFunction> CurrFun:K </stackCurrentFunction>
                    <stackCurrentProgramLoc> CurrLoc:K </stackCurrentProgramLoc>
               ...</callStackFrame>
          ) ...</callStack>
          <control>
               <currTU> OldTu:K => Tu </currTU>
               <currentFunction> CurrFun:K => X </currentFunction>
               <currentProgramLoc> CurrLoc:K </currentProgramLoc>
               // TODO(chathhorn): better way to initialize?
               (C:Bag => <controlDetails>... .Bag ...</controlDetails>)
          </control>
          [structural, large]
endmodule

