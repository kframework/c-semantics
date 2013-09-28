module C-EXPRESSION-FUNCTION-CALL-SYNTAX
     syntax K ::= "application'" "(" K "," KList ")" [strict(1)]
endmodule

module C-EXPRESSION-FUNCTION-CALL
     imports C-EXPRESSION-FUNCTION-CALL-SYNTAX
     imports C-EXPRESSION-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-BINDING-SYNTAX

     imports COMPAT-SYNTAX

     syntax K ::= application(K, KList) [strict(1)]

     // TODO(chathhorn): KList heating bug
     rule application(K:K, L:KList) => K ~> application(HOLE, L) [heat]
     rule K:K ~> application(HOLE, L:KList) => application(K, L) [cool]

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
     
     rule Call(F:KResult, K:K) 
          => sequencePoint ~> Call'(F, K) 

     context Call'(_, (HOLE => revalParams(HOLE)))

     rule [function-application-pre]:
          Call'(tv(Loc:SymLoc, t(_, pointerType(T:Type))), rvlist(L:KList))
          => sequencePoint ~> application(readFunction(Loc), L)
          when isFunctionType(T)
          [structural]

     /*@ this extra step is useful for putting the function name in the
        transition graph */
     rule [call]:
          application(Fun:KResult, L:KList) 
          => application'(Fun, L:KList)
          [structural]

     rule [populateFromGlobal]:
          <k> populateFromGlobal => . ...</k>
          <currTU> Tu:K </currTU>
          <genv>... Tu |-> map(G:Map) ...</genv> 
          <env> _ => G </env>
          <gtypes>... Tu |-> map(GT:Map) ...</gtypes> 
          <types> _ => GT </types>
          <gstructs> GS:Map </gstructs> 
          <structs> _ => GS </structs>
          [structural]

     rule [function-application]:
          <k> 
               application'(functionObject(X:Id, 
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
          <funTUs>... OldTu |-> map((_ X |-> Tu:K)) ...</funTUs>
          [structural, large]
endmodule

