module FUNCTION-CALL-SYNTAX
     imports BASIC-K
     imports COMMON-SORTS
     imports COMPAT-SORTS
     imports SYMLOC-SORTS
     imports MEMORY-SORTS

     // syntax for function call regardless of language of caller
     syntax KItem ::= application(CabsLoc, SymBase, K, EffectiveType, LanguageLinkage, StrictList)
endmodule

module C-EXPR-FUNCTION-CALL
     imports FUNCTION-CALL-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports STRING
     imports COMMON-BUILTIN-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BINDING-SYNTAX
     imports C-CHECK-LOC-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-SYNTAX

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

     // Function call (from C function)
     rule <k> Call(
               tv(loc(Base:SymBase, 0), ut(_, pointerType(T:FunctionType))),
               rvlist(L:List))
               => sequencePoint ~> application(CurrLoc, Base, Fun, T, CLinkage, krlist(L))
          ...</k>
          <functions>... Base |-> Fun:RValue ...</functions>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
          [structural]

     rule <k> Call(
               tv(loc(0 @ nativeAddress(), Address:Int), ut(_, pointerType(T:FunctionType))),
               rvlist(L:List))
               => sequencePoint ~> application(CurrLoc, 0 @ nativeAddress(), functionObject(nativeFunction(Address), makeNativeDecl(T), .List, handleBuiltin), T, CLinkage, krlist(L))
          ...</k>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
          [structural]

     rule <k> populateFromGlobal(T::Type) => .K ...</k>
          <curr-tu> "native" </curr-tu>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <types> _ => F |-> T </types>
          <env> _ => .Map </env>

     rule idToString(nativeFunction(Address:Int)) => "<native function at 0x" +String Base2String(Address, 16) +String ">"

     syntax Type ::= makeNativeDecl(Type) [function]
     rule makeNativeDecl(t(Quals::Quals, Mods::Set, functionType(R::UType, L::List)))
          => t(Quals, Mods, functionType(R, makeNativeDeclArgs(L, 0)))
     syntax List ::= makeNativeDeclArgs(List, Int) [function]
     rule makeNativeDeclArgs(ListItem(T::Type) L::List, I::Int) => ListItem(typedDeclaration(T, Identifier("_" +String Int2String(I)))) makeNativeDeclArgs(L, I +Int 1)
     rule makeNativeDeclArgs(.List, _) => .List

     syntax KItem ::= revalParams(K)
                    | #revalParams(HeatList) [strict]
     //TODO(liyili2): context revalParams(list(_ ListItem((HOLE:KItem => reval(HOLE))) _)) [ndheat]
     rule revalParams(list(L:List)) => #revalParams(toHeatList(L))
          [structural]

     rule #revalParams(HL:HeatList) => revalParams(rvlist(hListToList(HL)))
          requires allRValueInHeatList(HL)
          [structural]

     syntax KResult ::= rvlist(List)

     rule checkStackDepth => .K
          requires notBool hasLint

     /*@ This extra step is useful for putting the function name in the
        transition graph. */
     // Function call (into C function)
     rule <k> application(CurrLoc:CabsLoc, Base:SymBase,
                    functionObject(X:CId, DefT:Type, Locals:List, Blk:K),
                    CallT:Type, CallingLang::LanguageLinkage, krlist(L:List))
               ~> K:K
               => sequencePoint
               ~> enterRestrictScope(blockScope(X, 0))
               ~> populateFromGlobal(DefT)
               ~> bind(getParams(DefT), getParams(CallT), L)
               ~> sequencePoint
               ~> checkStackDepth
               ~> Blk
          </k>
          <call-stack> .List => ListItem(
               <call-stack-frame>
                    <continuation> K:K </continuation>
                    <stack-function-control>
                         C
                    </stack-function-control>
                    <stack-lang-linkage> CallingLang </stack-lang-linkage>
               </call-stack-frame>
          ) ...</call-stack>
          (C:FunctionControlCell
          => <function-control>...
               <curr-tu> getTU(loc(Base, 0)) </curr-tu>
               <curr-scope> blockScope(X, 0) </curr-scope>
               <curr-program-loc> CurrLoc </curr-program-loc>
          ...</function-control>)
          <stack-depth> ListItem(Old:Int) => ListItem(Old +Int cfg:stackSize(mapList(L, #klabel(`type`)), Locals)) ListItem(Old) ...</stack-depth>
          requires CallT ==Type toPrototype(DefT)
          [structural]
     rule (.K => UNDEF("EFNC1", "Attempt to call the function " +String
          idToString(X) +String " through a pointer with incompatible type.", "6.5.2.2:9, J.2:1 items 26, 41"))
          ~> application(_, _, functionObject(X:CId, DefT:Type, _, _), CallT:Type, _, _)
          requires CallT =/=Type toPrototype(DefT)
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
               => allocObject(Base, type(no-type))
               ~> addToEnv(X, Base)
               ~> giveType(X, type(no-type))
          ...</k>
          <curr-function-params>...
               (.List => ListItem(X))
          </curr-function-params>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          [structural]

     // TODO(chathhorn): copied from translation -- we only need this in the
     // case of parameter binding.
     rule L:KResult := (R:RValue => cast(utype(L), R))
          requires (isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
               andBool (utype(L) =/=Type utype(R))

     rule L:KResult := (R:RValue => cast(utype(L), R))
          requires isPointerType(type(L)) andBool isPointerType(type(R))
               andBool stripQualifiers(innerType(type(L)))
                    ==Type stripQualifiers(innerType(type(R)))
               andBool getQualifiers(innerType(type(R)))
                    <=Quals getQualifiers(innerType(type(L)))
               andBool getAlignas(innerType(type(L)))
                    <=Int getAlignas(innerType(type(R)))
               andBool utype(L) =/=Type utype(R)

     rule L:KResult := (R:RValue => cast(utype(L), R))
          requires isPointerType(type(L)) andBool isPointerType(type(R))
               andBool (isVoidType(innerType(type(L)))
                    orBool isVoidType(innerType(type(R))))
               andBool (getQualifiers(innerType(type(R)))
                    <=Quals getQualifiers(innerType(type(L))))
               andBool utype(L) =/=Type utype(R)

     rule L:KResult := (R:RValue => cast(utype(L), R))
          requires isPointerType(type(L))
               andBool isNullPointerConstant(R)
               andBool utype(L) =/=Type utype(R)
          [structural] //TODO(dwightguth): this tag is needed for confluence with null pointer constants. Might want to find a better way.

     rule L:KResult := (R:RValue => cast(utype(L), R))
          requires isBoolType(type(L)) andBool isPointerType(type(R))

     rule nclv(_, T::Type => stripConstants(T)) := _:RValue
          requires fromConstantExpr(T)
     rule _:KResult := tv(_:CValue, T::UType => stripConstants(T))
          requires fromConstantExpr(T)

endmodule
