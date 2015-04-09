module C-EXPR-FUNCTION-CALL
     imports C-BINDING-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-CHECK-LOC-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

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

     context Call(_, (HOLE => revalParams(HOLE))) [ndheat]

     // Strip prov.
     rule Call(tv((loc(Base:SymBase, Offset:Int, _) => loc(Base, Offset)), _), _)
          [structural]
     // Resolve a linker loc to a real loc.
     rule <k> Call(tv(loc((Base:SymBase => Base'), _), _), _) ...</k>
          <linkings>... Base |-> Base':SymBase ...</linkings>

     rule <k> Call(
               tv(loc(Base:SymBase, 0), t(_, pointerType(T:Type))),
               rvlist(L:List))
               => sequencePoint ~> application(getTU(loc(Base, 0)), Fun, T, L)
          ...</k>
          <functions>... Base |-> Fun:KResult ...</functions>
          requires isFunctionType(T)
          [structural]

     syntax KItem ::= revalParams(K)
                    | #revalParams(HeatList) [strict]
     //TODO(liyili2): context revalParams(list(_ ListItem((HOLE => reval(HOLE))) _)) [ndheat]
     rule revalParams(list(L:List)) => #revalParams(toHeatList(L))

     rule #revalParams(HL:HeatList) => revalParams(rvlist(hListToList(HL)))
          requires isAllKResultInHeatList(HL)
          [structural]

     syntax KResult ::= rvlist(List)

     /*TODO(liyili2): might need this later
     rule revalParams(list(L:List)) => revalParams(rvlist(L))
          requires all(L, isKResult)
          [structural]
     */

     syntax KItem ::= application(String, K, Type, List) [strict(2)]
     context application(_, HOLE, _, _)

     /*@ This extra step is useful for putting the function name in the
        transition graph. */
     rule <k> application(Tu:String,
                    functionObject(X:CId, Params:List, DefT:Type, Blk:K),
                    CallT:Type, L:List)
               => application'(Tu, functionObject(X, Params, DefT, Blk), L)
          ...</k>
          requires areCompatible(CallT, DefT)
          [structural]
     rule (.K => UNDEF("FC1", "attempt to call the function " +String
               idToString(X) +String " through a pointer with incompatible type.", "6.5.2.2:9"))
          ~> application(_, functionObject(X:CId, _, DefT:Type, _), CallT:Type, _)
          requires notBool areCompatible(CallT, DefT)
          [structural]

     syntax KItem ::= "application'" "(" String "," K "," List ")"

     rule <k> application'(Tu:String, functionObject(X:CId, Params:List, DefT:Type, Blk:K), L:List)
               ~> K:K
               => sequencePoint
               ~> enterRestrictScope(X)
               ~> populateFromGlobal
               ~> bind(Params, getParams(DefT), L)
               ~> sequencePoint
               ~> Blk
          </k>
          <call-stack> .List => ListItem(
               bag2K(<call-stack-frame>...
                    <stack-control>
                         <curr-tu> OldTu:String </curr-tu>
                         C:Bag
                    </stack-control>
                    <continuation> K:K </continuation>
                    <stack-curr-function> CurrFun:K </stack-curr-function>
                    <stack-curr-function-params> CurrFunParams:List </stack-curr-function-params>
                    <stack-curr-program-loc> CurrLoc:K </stack-curr-program-loc>
               ...</call-stack-frame>)
          ) ...</call-stack>
          <control>
               <curr-tu> OldTu:String => Tu </curr-tu>
               <curr-function> CurrFun:K => X </curr-function>
               <curr-function-params> CurrFunParams:List => .List </curr-function-params>
               <curr-program-loc> CurrLoc:K </curr-program-loc>
               (C:Bag => <control-details>... .Bag ...</control-details>)
          </control>
          [structural]

     rule <k> bindParam(X:CId, T:Type, V:RValue)
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
               ~> allowInit(Computation(X := V))
          ...</k>
          <curr-function-params>...
               (.List => ListItem(X))
          </curr-function-params>
          <next-loc> Base:SymBase => linc(Base) </next-loc>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          [structural]
     rule <k> bindParam(X:CId)
               => allocObject(Base, t(.Set, no-type))
               ~> addToEnv(X, Base)
               ~> giveType(X, t(.Set, no-type))
          ...</k>
          <curr-function-params>...
               (.List => ListItem(X))
          </curr-function-params>
          <next-loc> Base:SymBase => linc(Base) </next-loc>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          [structural]

endmodule
