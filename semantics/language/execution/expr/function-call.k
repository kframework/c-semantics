module C-EXPR-FUNCTION-CALL
     imports C-BINDING-SYNTAX
     imports C-CHECK-LOC-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

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

     context Call(_, (HOLE:KItem => revalParams(HOLE))) [ndheat]

     // Strip prov.
     rule Call(tv((loc(Base:SymBase, Offset:Int, _) => loc(Base, Offset)), _),
               _:KResult)
          [structural]
     // Resolve a linker loc to a real loc.
     rule <k> Call(tv(loc((Base:SymBase => Base'), _), _), _) ...</k>
          <linkings>... Base |-> Base':SymBase ...</linkings>
          [structural]

     rule <k> Call(
               tv(loc(Base:SymBase, 0), t(_, pointerType(T:FunctionType))),
               rvlist(L:List))
               => sequencePoint ~> application(getTU(loc(Base, 0)), Fun, T, L)
          ...</k>
          <functions>... Base |-> Fun:KResult ...</functions>
          [structural]

     syntax KItem ::= revalParams(K)
                    | #revalParams(HeatList) [strict]
     //TODO(liyili2): context revalParams(list(_ ListItem((HOLE:KItem => reval(HOLE))) _)) [ndheat]
     rule revalParams(list(L:List)) => #revalParams(toHeatList(L))
          [structural]

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
     context application(_, HOLE:KItem, _, _)

     /*@ This extra step is useful for putting the function name in the
        transition graph. */
     rule <k> application(Tu:String,
                    functionObject(X:CId, Params:List, DefT:Type, Blk:K),
                    CallT:Type, L:List)
               => application'(Tu, functionObject(X, Params, DefT, Blk), L)
          ...</k>
          requires areCompatible(CallT, DefT)
          [structural]
     rule (.K => UNDEF("EFNC1", "attempt to call the function " +String
               idToString(X) +String " through a pointer with incompatible type.", "6.5.2.2:9, J.2:1 item 41"))
          ~> application(_, functionObject(X:CId, _, DefT:Type, _), CallT:Type, _)
          requires notBool areCompatible(CallT, DefT)
          [structural]

     syntax KItem ::= "application'" "(" String "," K "," List ")"

     rule <k> application'(Tu:String, functionObject(X:CId, Params:List, DefT:Type, Blk:K), L:List)
               ~> K:K
               => sequencePoint
               ~> enterRestrictScope(blockScope(X, 0))
               ~> populateFromGlobal
               ~> bind(Params, getParams(DefT), L)
               ~> sequencePoint
               ~> Blk
          </k>
          <call-stack> .List => ListItem(
               <call-stack-frame>...
                    <stack-control>
                         C
                    </stack-control>
                    <continuation> K:K </continuation>
                    <stack-curr-scope> CurrScope </stack-curr-scope>
                    <stack-curr-function-params> CurrFunParams </stack-curr-function-params>
                    <stack-curr-program-loc> CurrLoc </stack-curr-program-loc>
                    <stack-curr-tu> OldTu </stack-curr-tu>
               ...</call-stack-frame>
          ) ...</call-stack>
          <control>
               <curr-tu> OldTu:String => Tu </curr-tu>
               <curr-scope> CurrScope:Scope => blockScope(X, 0) </curr-scope>
               <curr-function-params> CurrFunParams:List => .List </curr-function-params>
               <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
               (C:ControlDetailsCell => <control-details>... .Bag ...</control-details>)
          </control>
          [structural]

     rule <k> bindParam(X:CId, T:Type, V:RValue)
               => bindParamHelper(X, T, V, !I:Int @ D)
          ...</k>
          <duration> D:Duration </duration>
          [structural]
     syntax KItem ::= bindParamHelper(CId, Type, RValue, SymBase)
     rule <k> bindParamHelper(X:CId, T:Type, V:RValue, Base:SymBase)
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
               ~> allowInit(Computation(X := V))
          ...</k>
          <curr-function-params>...
               (.List => ListItem(X))
          </curr-function-params>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          [structural]

     rule <k> bindParam(X:CId) => bindParamHelper(X, !I:Int @ D) ...</k>
          <duration> D:Duration </duration>
          [structural]
     syntax KItem ::= bindParamHelper(CId, SymBase)
     rule <k> bindParamHelper(X:CId, Base:SymBase)
               => allocObject(Base, t(.Set, no-type))
               ~> addToEnv(X, Base)
               ~> giveType(X, t(.Set, no-type))
          ...</k>
          <curr-function-params>...
               (.List => ListItem(X))
          </curr-function-params>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          [structural]

     // TODO(chathhorn): copied from translation -- we only need this in the
     // case of parameter binding.
     rule L:KResult := (R:RValue => cast(type(L), R))
          requires (isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
               andBool (getQualifiers(type(R)) ==K .Set)
               andBool (type(L) =/=Type type(R))

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isStructOrUnionType(type(L))
               andBool areCompatible(stripQualifiers(type(L)), type(R))
               andBool (type(L) =/=Type type(R))

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isPointerType(type(L)) andBool isPointerType(type(R))
               andBool areCompatible(
                    stripQualifiers(stripAlignas(innerType(type(L)))),
                    stripQualifiers(stripAlignas(innerType(type(R)))))
               andBool getQualifiers(innerType(type(R)))
                    <=Set getQualifiers(innerType(type(L)))
               andBool getAlignas(innerType(type(L)))
                    <=Int getAlignas(innerType(type(R)))
               andBool (type(L) =/=Type type(R))

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isPointerType(type(L)) andBool isPointerType(type(R))
               andBool (isVoidType(innerType(type(L)))
                    orBool isVoidType(innerType(type(R))))
               andBool (getQualifiers(innerType(type(R)))
                    <=Set getQualifiers(innerType(type(L))))
               andBool (type(L) =/=Type type(R))

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isPointerType(type(L))
               andBool isNullPointerConstant(R)
               andBool (type(L) =/=Type type(R))
          [structural] //TODO(dwightguth): this tag is needed for confluence with null pointer constants. Might want to find a better way.

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isBoolType(type(L)) andBool isPointerType(type(R))

     rule nclv(_, T:Type => stripConstants(T)) := _:RValue
          requires fromConstantExpr(T)
     rule _:KResult := tv(_:CValue, T:Type => stripConstants(T))
          requires fromConstantExpr(T)

     rule (.K => CV("EFNC2", "incompatible types in function call arguments.", "6.5.16.1:1"))
          ~> L:KResult := R:RValue
          requires type(L) =/=Type type(R) andBool ((isPointerType(type(L)) andBool notBool isPointerType(type(R))
                    andBool notBool isNullPointerConstant(R))
               orBool (isArithmeticType(type(L)) andBool notBool isBoolType(type(L)))
                    andBool notBool isArithmeticType(type(R))
               orBool isStructOrUnionType(type(L))
                    andBool notBool areCompatible(stripQualifiers(type(L)), type(R))
               orBool isBoolType(type(L)) andBool notBool isPointerType(type(R)) andBool notBool isArithmeticType(type(R))
               orBool notBool (isPointerType(type(L))
                    orBool isArithmeticType(type(L))
                    orBool isStructOrUnionType(type(L))
                    orBool isBoolType(type(L))))
          [structural] //TODO(dwightguth): this tag is needed for confluence with null pointer constants. Might want to find a better way.

     rule (.K => CV("EFNC3", "incompatible pointer types in function call arguments.", "6.5.16.1:1"))
          ~> L:KResult := R:RValue
          requires (isPointerType(type(L)) andBool isPointerType(type(R)))
               andBool notBool isVoidType(innerType(type(L)))
               andBool notBool isVoidType(innerType(type(R)))
               andBool (
                    notBool areCompatible(
                         stripQualifiers(stripAlignas(innerType(type(L)))),
                         stripQualifiers(stripAlignas(innerType(type(R)))))
                    orBool notBool (getQualifiers(innerType(type(R)))
                         <=Set getQualifiers(innerType(type(L))))
                    orBool getAlignas(innerType(type(L)))
                         >Int getAlignas(innerType(type(R)))
               )
endmodule
