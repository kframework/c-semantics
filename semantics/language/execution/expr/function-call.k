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
     imports C-SETTINGS-SYNTAX

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

     rule (.K => UNDEF("EFNC2", "Invoking a null pointer.", "6.5.2.2"))
          ~> Call(tv(NullPointer, _), _)

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
               => sequencePoint ~> application(CurrLoc, getTU(loc(Base, 0)), Fun, T, L)
          ...</k>
          <functions>... Base |-> Fun:RValue ...</functions>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
          [structural]

     syntax KItem ::= revalParams(K)
                    | #revalParams(HeatList) [strict]
     //TODO(liyili2): context revalParams(list(_ ListItem((HOLE:KItem => reval(HOLE))) _)) [ndheat]
     rule revalParams(list(L:List)) => #revalParams(toHeatList(L))
          [structural]

     rule #revalParams(HL:HeatList) => revalParams(rvlist(hListToList(HL)))
          requires allRValueInHeatList(HL)
          [structural]

     syntax KResult ::= rvlist(List)

     syntax KItem ::= application(CabsLoc, String, RValue, Type, List)
     rule checkStackDepth => .K
          requires notBool hasLint

     /*@ This extra step is useful for putting the function name in the
        transition graph. */
     rule <k> application(CurrLoc:CabsLoc, Tu:String,
                    functionObject(X:CId, DefT:Type, Locals:List, Blk:K),
                    CallT:Type, L:List)
               ~> K:K
               => sequencePoint
               ~> enterRestrictScope(blockScope(X, 0))
               ~> populateFromGlobal
               ~> bind(getParams(DefT), getParams(CallT), L)
               ~> sequencePoint
               ~> checkStackDepth
               ~> Blk
          </k>
          <call-stack> .List => ListItem(
               <call-stack-frame>...
                    <continuation> K:K </continuation>
                    <stack-function-control>
                         C
                    </stack-function-control>
               ...</call-stack-frame>
          ) ...</call-stack>
          (C:FunctionControlCell
          => <function-control>...
               <curr-tu> Tu </curr-tu>
               <curr-scope> blockScope(X, 0) </curr-scope>
               <curr-program-loc> CurrLoc </curr-program-loc>
          ...</function-control>)
          <stack-depth> ListItem(Old:Int) => ListItem(Old +Int cfg:stackSize(mapList(L, #klabel(`type`)), Locals)) ListItem(Old) ...</stack-depth>
          requires areCompatible(CallT, toPrototype(DefT))
          [structural]
     rule (.K => UNDEF("EFNC1", "Attempt to call the function " +String
          idToString(X) +String " through a pointer with incompatible type.", "6.5.2.2:9, J.2:1 item 41"))
          ~> application(_, _, functionObject(X:CId, DefT:Type, _, _), CallT:Type, _)
          requires notBool areCompatible(CallT, toPrototype(DefT))
          [structural]

     rule <k> bindParam(X:CId, T:Type, V:RValue)
               => bindParamHelper(X, T, V, !I:Int @ D)
          ...</k>
          <duration> D:Duration </duration>
          [structural]
     syntax KItem ::= bindParamHelper(CId, Type, RValue, SymBase) [klabel(bindParamHelper4)]
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

endmodule
