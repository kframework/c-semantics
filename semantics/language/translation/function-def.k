module C-FUNCTION-DEF-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax KItem ::= initFunction(K, CId, RValue) [strict(1)]
endmodule

module C-FUNCTION-DEF
     imports C-FUNCTION-DEF-SYNTAX

     imports C-ABSTRACT-SYNTAX
     imports C-ANNOTATION-SYNTAX
     imports C-BINDING-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-PROCESS-LABEL-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports C-CONFIGURATION

     rule FunctionDefinition(typedDeclaration(T:FunctionType, X:CId), Blk:K)
          => declare'(
               typedDeclaration(toPrototype(emptyToVoid(T)), X),
               initializer(Computation(initFunction(
                    &(X),
                    X,
                    functionObject(X,
                         // The return and parameter types from the definition.
                         t(getQualifiers(T), getModifiers(T), functionType(utype(elideDeclParams(innerType(T))),
                              elideList(getParams(emptyToVoid(T))))), .List,
                         Goto(funLabel(X)))
               )))
          )
          ~> processFunDef(X, Blk)
          requires notBool hasDupParams(T)
          [structural]
     rule (.K => CV("FD1", "Duplicate parameters in "
               +String "function definition.", "6.7:3"))
          ~> FunctionDefinition(typedDeclaration(T:Type, _), _)
          requires hasDupParams(T)

     // TODO(chathhorn): possibly check that old-style declarations are
     // promoted types?

     syntax Type ::= emptyToVoid(Type) [function]
     rule emptyToVoid(T:FunctionType)
          => setParams(T, ListItem(typedDeclaration(type(void), #NoName)))
          requires (getParams(T) ==K .List)
     rule emptyToVoid(T:Type) => T [owise]

     syntax KItem ::= processFunDef(CId, K)
     rule <k> processFunDef(X:CId, Blk:K)
               => checkFunDefType(X, elideDeclParams(DefT))
               ~> staticEval(X, DefT, Blk)
          ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <functions>...
               Base |-> functionObject(_, DefT::Type, _, _)
          ...</functions>
          <curr-function> _ => Base </curr-function>
          [structural]

     syntax KItem ::= checkFunDefType(CId, Type)
     rule checkFunDefType(X:CId, t(_, _, functionType(R::UType, P:List))) => .K
          requires notBool isArrayOrFunctionUType(R)
               andBool areVoidOrComplete(P)
               andBool (X =/=K Identifier("main"))
          [structural]
     rule checkFunDefType(X:CId, T:Type) => checkMainDef(T)
          requires isVoidOrComplete(innerType(T))
               andBool areVoidOrComplete(getParams(T))
               andBool (X ==K Identifier("main"))
          [structural]
     rule (.K => CV("FD2", "Invalid return type in function definition.",
               "6.7.6.3:1"))
          ~> checkFunDefType(_, t(_, _, functionType(_:ArrayOrFunctionUType, _)))
          [structural]
     rule (.K => CV("FD3", "Incomplete parameter type in "
               +String "function definition.", "6.7.6.3:4"))
          ~> checkFunDefType(_, T:Type)
          requires notBool areVoidOrComplete(getParams(T))
          [structural]

     syntax Bool ::= isVoidOrComplete(K) [function]
     rule isVoidOrComplete(T:Type)
          => isCompleteType(T) orBool isVoidType(T)
               orBool isIncompleteArrayType(T)
     rule isVoidOrComplete(_) => true [owise]

     syntax Bool ::= areVoidOrComplete(List) [function]
     rule areVoidOrComplete(L:List) => true
          requires all(L, #klabel(`isVoidOrComplete`))
     rule areVoidOrComplete(_) => false [owise]

     syntax KItem ::= checkMainDef(Type)
     rule checkMainDef(t(_, _, functionType(ut(_, int),
               ListItem(t(_, _, void)))))
          => .K
          [structural]
     rule checkMainDef(t(_, Mods:Set, functionType(ut(_, int),
               ListItem(t(_, _, int)) ListItem(T:Type))))
          => .K
          requires (notBool oldStyle in Mods) andBool isArgvType(T)
          [structural]
     rule (.K => UNDEF("FD4", "Definition of main requires a prototype.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, Mods:Set, functionType(ut(_, int), ListItem(T:Type) _)))
          requires (oldStyle in Mods) andBool notBool isVoidType(T)
          [structural]
     rule (.K => UNDEF("FD5", "Function main must return an int.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, _, functionType(ut(_, T::SimpleUType), _)))
          requires T =/=K int
          [structural]
     rule (.K => UNDEF("FD6", "If main has parameters, the type of the first parameter must be equivalent to int.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, _, functionType(_, ListItem(t(_, _, T::SimpleType)) _)))
          requires T =/=K int andBool T =/=K void
          [structural]
     rule (.K => UNDEF("FD7", "If main has parameters, the type of the second parameter must be equivalent to char**.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, _, functionType(_, ListItem(_) ListItem(T:Type))))
          requires notBool isArgvType(T)
          [structural]
     rule (.K => UNDEF("FD8", "Function main must have zero or two parameters.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, _, functionType(_, Params::List)))
          requires size(Params) >Int 2
          [structural]
     rule (.K => UNDEF("FD9", "Function main must have zero or two parameters.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, _, functionType(_, ListItem(t(_, _, T::SimpleType)))))
          requires T =/=K void
          [structural]

     syntax Bool ::= isArgvType(Type) [function]
     rule isArgvType(t(_, _, incompleteArrayType(t(_, _, pointerType(t(_, _, T:SimpleType))))))
          => true
          requires T ==K char // char is an alias.
     rule isArgvType(t(_, _, pointerType(t(_, _, pointerType(t(_, _, T:SimpleType))))))
          => true
          requires T ==K char
     rule isArgvType(_) => false [owise]

     rule initFunction(tv(Loc:SymLoc, T::UType), X:CId, Fun:RValue)
          => te(initFunction(&(X), X, Fun), T)
          requires isLinkerLoc(Loc)
     rule <k> initFunction(
               tv(Loc:SymLoc, ut(_, pointerType(_:FunctionType))), _, Fun:RValue)
               => voidVal
          ...</k>
          <functions> M:Map => M[base(Loc) <- Fun] </functions>
          requires notBool isLinkerLoc(Loc)

     syntax KItem ::= safeBody(CId, K) [function]

     rule safeBody(X:CId, Blk:K)
          => Blk ~> Return(NothingExpression)
          requires X =/=K Identifier("main")
     rule safeBody(Identifier("main"), Blk:K)
          => Blk ~> Return(tv(0, utype(int)))

     syntax KItem ::= staticEval(CId, Type, K)
     syntax KItem ::= calculateGotoMap(CId)

     rule staticEval(X:CId, DefT:Type, Blk:K)
          => scope(blockScope(X, 0),
               generateRuleAnnotation(X)
               ~> elaborate(dummyBind(getParams(DefT)) ~> Label(funLabel(X), safeBody(X, Blk)))
               ~> calculateGotoMap(X))

     rule elaborateDone(K:K) ~> calculateGotoMap(X:CId)
          => calculateGotoMap(X, K)

     syntax Bool ::= hasDupParams(Type) [function]
     rule hasDupParams(t(_, _, functionType(_, P:List))) => hasDupIds(P)
     rule hasDupParams(_) => false [owise]

     // TODO(liyili2): no associative matching in Java currently, we will do it once we
     // have the associative matching.
     syntax Bool ::= hasDupIds(List) [function]
     syntax Bool ::= idInList(CId, List) [function]

     rule idInList(_, .List) => false
     rule idInList(X:CId, ListItem(typedDeclaration(_, X)) _)
          => true
     rule idInList(X:CId, ListItem(typedDeclaration(_, Y:CId)) Tail:List => Tail)
          requires X =/=K Y
     rule idInList(_, ListItem(_:Type) Tail:List => Tail)
     rule idInList(_, ListItem(_:Variadic) Tail:List => Tail)

     rule hasDupIds(.List) => false
     rule hasDupIds(
               ListItem(typedDeclaration(_, X:CId))
               Tail:List)
          => true
          requires idInList(X, Tail)
     rule hasDupIds(
               ListItem(typedDeclaration(_, X:CId))
               Tail:List => Tail)
          requires notBool idInList(X, Tail)
     rule hasDupIds(ListItem(_:Type) Tail:List => Tail)
     rule hasDupIds(ListItem(_:Variadic) Tail:List => Tail)

     syntax KItem ::= dummyBind(List)
     rule dummyBind(.List) => .K
          [structural]
     rule dummyBind(ListItem(variadic)) => .K
          [structural]
     rule dummyBind(ListItem(typedDeclaration(_:VoidType, _))) => .K
          [structural]
     rule dummyBind(ListItem(typedDeclaration(T:Type, X:CId)) Params:List)
          => addToEnv(X, nonStatic)
          ~> giveType(X, T)
          ~> dummyBind(Params)
          requires notBool isVoidType(T)
          [structural]
endmodule
