module C-EXPR-FUNCTION-CALL
     imports FUNCTION-CALL-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports STRING
     imports COMMON-BUILTIN-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BINDING-SYNTAX
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
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

     rule (.K => UNDEF("EFNC2", "Invoking a null pointer."))
          ~> Call(tv(NullPointer, _), _)

     // Strip prov.
     rule Call(tv((loc(Base:SymBase, Offset:Int, _) => loc(Base, Offset)), _),
               _:KResult)
          [structural]

     // Function call (from C function)
     rule <k> Call(
               tv(loc(Base:SymBase, 0), ut(_, pointerType(T:FunctionType))),
               rvlist(L:List))
               => sequencePoint
               ~> application(CurrLoc, Base, Fun, T, CLinkage, krlist(L))
          ...</k>
          <functions>... Base |-> Fun:RValue ...</functions>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
          [structural]
     rule <k> Call(tv(loc(obj(0, Align::Int, nativeAddress()), Address:Int), ut(_, pointerType(T:FunctionType))),
               rvlist(L:List))
               => sequencePoint
               ~> application(CurrLoc, obj(0, Align, nativeAddress()), functionObject(nativeFunction(Address), makeNativeDecl(T), .List), T, CLinkage, krlist(L))
          ...</k>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
          [structural]
     rule <k> Call(tv(loc(obj(0, Align::Int, nativeSymbol(S::String)), _), ut(_, pointerType(_:FunctionType))),
               rvlist(L:List))
               => sequencePoint
               ~> application(CurrLoc, obj(0, Align, nativeSymbol(S)), functionObject(Identifier(S), T, .List), T, CLinkage, krlist(L))
          ...</k>
          <external-types>... Identifier(S) |-> T::Type ...</external-types>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
          [structural]

     rule showCId(nativeFunction(Address:Int)) => "<native function at 0x" +String Base2String(Address, 16) +String ">"

     syntax Type ::= makeNativeDecl(Type) [function]
     rule makeNativeDecl(t(Quals::Quals, Mods::Set, functionType(R::UType, L::List)))
          => t(Quals, Mods, functionType(R, makeNativeDeclArgs(L, 0)))
     syntax List ::= makeNativeDeclArgs(List, Int) [function]
     rule makeNativeDeclArgs(ListItem(T::Type) L::List, I::Int) => ListItem(typedDeclaration(T, Identifier("_" +String showInt(I)))) makeNativeDeclArgs(L, I +Int 1)
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

     syntax K ::= checkRecursion(CId, String, Map) [function]
     rule checkRecursion(_, _, _) => .K
          requires notBool hasLint

     /*@ This extra step is useful for putting the function name in the
        transition graph. */
     // Function call (into C function)
     rule <k> application(CurrLoc:CabsLoc, Base:SymBase,
                    functionObject(X:CId, DefT:Type, Locals:List),
                    CallT:Type, CallingLang::LanguageLinkage, krlist(L:List))
               ~> K:K
               => enterNewTu(X, Base, DefT)
               ~> sequencePoint
               ~> enterRestrictBlock(blockScope(X, 0))
               ~> populateFromGlobal(DefT)
               ~> declareInternalVariable(funLabel, type(no-type), initValue(funLabel, type(no-type), .K))
               ~> bind(getParams(DefT), getParams(CallT), L)
               ~> sequencePoint
               ~> #if isNativeLoc(Base) orBool isBuiltinLoc(Base)
                  #then callBuiltin #else Goto(funLabel) #fi
          </k>
          <external-defs> Defs::Map </external-defs>
          <call-stack> (.List => ListItem(
               <call-stack-frame>
                    <continuation> K:K </continuation>
                    <stack-function-control>
                         <function-control>
                              C
                              <curr-tu> OldTu </curr-tu>
                              <stack-depth> OldStackDepth </stack-depth>
                         </function-control>
                    </stack-function-control>
                    <stack-lang-linkage> CallingLang </stack-lang-linkage>
               </call-stack-frame>
          )) ...</call-stack>
          (<function-control>
               C::Bag
               <curr-tu> OldTu::String </curr-tu>
               <stack-depth> OldStackDepth:Int </stack-depth>
          </function-control>
          => <function-control>...
               <curr-tu> OldTu </curr-tu>
               <curr-scope> blockScope(X, 0) </curr-scope>
               <curr-program-loc> CurrLoc </curr-program-loc>
               <stack-depth> OldStackDepth +Int cfg:stackSize(mapList(L, #klabel(`type`)), Locals) </stack-depth>
          ...</function-control>)
          requires CallT ==Type toPrototype(DefT)
          [structural]
     rule (.K => UNDEF("EFNC1", "Attempt to call the function "
               +String showCId(X) +String " through a pointer with incompatible type."))
          ~> application(_, _, functionObject(X::CId, DefT::Type, _), CallT:Type, _, _)
          requires CallT =/=Type toPrototype(DefT)
          [structural]

     syntax KItem ::= enterNewTu(CId, SymBase, Type)
     rule <k> enterNewTu(F::CId, _, t(_, SetItem(SpecExtendsTuOf(X::CId)) _, _))
               => extendTu(F, G, GT)
               ~> #if (getTU(Base) =/=String OldTu) #then enterRestrictTU #else .K #fi
               ~> checkStackDepth
               ~> checkRecursion(F, getTU(Base), Calls)
          ...</k>
          <called-functions> Calls::Map => incrementCalled(F, getTU(Base), Calls) </called-functions>
          <external-defs>... X |-> Base::SymBase ...</external-defs>
          <curr-tu> OldTu::String => getTU(Base) </curr-tu>
          <tu-id> OldTu </tu-id>
          <goto-map>... F |-> G::Map ... </goto-map>
          <gtypes>... F |-> GT::Type ... </gtypes>
          [structural]
     rule <k> enterNewTu(F::CId, Base::SymBase, T::Type)
               => #if (getTU(Base) =/=String OldTu) #then enterRestrictTU #else .K #fi
               ~> checkStackDepth
               ~> checkRecursion(F, getTU(Base), Calls)
          ...</k>
          <called-functions> Calls::Map => incrementCalled(F, getTU(Base), Calls) </called-functions>
          <curr-tu> OldTu::String => getTU(Base) </curr-tu>
          requires notBool extendsTu(T)
          [structural]

     syntax KItem ::= extendTu(CId, Map, Type)
     rule <k> extendTu(F::CId, G'::Map, GT'::Type) => .K ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map> G::Map => G[F <- G'] </goto-map>
          <gtypes> GT::Map => GT[F <- GT'] </gtypes>
          [structural]

     syntax Bool ::= extendsTu(Type) [function]
     rule extendsTu(t(_, SetItem(SpecExtendsTuOf(X::CId)) _, _)) => true
     rule extendsTu(_) => false [owise]

     rule <k> bindParam(X:CId, T:Type, V:RValue)
               => declareInternalVariable(X, T, initValue(X, T, Initializer(X := V)))
          ...</k>
          <curr-function-params>...
               .List => ListItem(X)
          </curr-function-params>
          [structural]

     syntax Map ::= incrementCalled(CId, String, Map) [function]
     rule incrementCalled(X::CId, Tu::String, (kpair(X, Tu) |-> N::Int) Calls::Map)
          => (kpair(X, Tu) |-> (N +Int 1)) Calls
     rule incrementCalled(X::CId, Tu::String, Calls::Map)
          => (kpair(X, Tu) |-> 1) Calls
          [owise]

endmodule
