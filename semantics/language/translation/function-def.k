module C-FUNCTION-DEF-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax KItem ::= initFunction(K, CId, RValue) [strict(1)]
     syntax Bool ::= hasDupParams(Type) [function]
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
          => declare(
               typedDeclaration(toPrototype(T), X),
               initializer(Computation(initFunction(
                    &(X),
                    X,
                    functionObject(X,
                         // The sanitized declared parameters.
                         elideList(getParams(emptyToVoid(T))),
                         // The "prototype" -- basically a type with the same
                         // parameters as above, but the parameters are set to
                         // .List if there isn't actually a prototype.
                         toPrototype(T),
                         Goto(funLabel(X)))
               )))
          )
          ~> processFunDef(X, Blk)
          requires notBool hasDupParams(T)
          [structural]
     rule (.K => CV("FD1", "duplicate parameters in "
               +String "function definition.", "6.7:3"))
          ~> FunctionDefinition(typedDeclaration(T:Type, _), _)
          requires hasDupParams(T)

     // TODO(chathhorn): possibly check that old-style declarations are
     // promoted types?

     // Turns empty param list into void and turns an old-style param list into
     // the empty list so that arguments will be promoted on call.
     syntax Type ::= toPrototype(Type) [function]
     rule toPrototype(T:Type) => elideDeclParams(emptyToVoid(T))
          requires notBool isOldStyleFunctionType(T)
     rule toPrototype(T:Type) => setParams(T, .List)
          requires isOldStyleFunctionType(T)

     syntax Type ::= emptyToVoid(Type) [function]
     rule emptyToVoid(T:FunctionType)
          => setParams(T, ListItem(typedDeclaration(t(.Set, void), #NoName)))
          requires (getParams(T) ==K .List)
     rule emptyToVoid(T:Type) => T
          requires notBool isFunctionType(T)
               orBool (getParams(T) =/=K .List)

     syntax KItem ::= processFunDef(CId, K)
     rule <k> processFunDef(X:CId, Blk:K)
               => checkFunDefType(X, Proto)
               ~> staticEval(X, Params, Blk)
          ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <functions>...
               Base |-> functionObject(_, Params:List, Proto:Type, _)
          ...</functions>
          [structural]

     syntax KItem ::= checkFunDefType(CId, Type)
     rule checkFunDefType(X:CId, t(_, functionType(R:Type, P:List))) => .K
          requires notBool isArrayOrFunctionType(R)
               andBool areVoidOrComplete(P)
               andBool (X =/=K Identifier("main"))
          [structural]
     rule checkFunDefType(X:CId, t(Mods:Set, functionType(R:Type, P:List))) 
          => checkMainDef(t(Mods, functionType(R, P)))
          requires isVoidOrComplete(R)
               andBool areVoidOrComplete(P)
               andBool (X ==K Identifier("main"))
          [structural]
     rule (.K => CV("FD2", "invalid return type in function definition.",
               "6.7.6.3:1"))
          ~> checkFunDefType(_, t(_, functionType(_:ArrayOrFunctionType, _)))
          [structural]
     rule (.K => CV("FD3", "incomplete parameter type in "
               +String "function definition.", "6.7.6.3:4"))
          ~> checkFunDefType(_, t(_, functionType(_, P:List)))
          requires notBool areVoidOrComplete(P)
          [structural]
     rule _:ErrorExit ~> checkFunDefType(_, _) => .K
          requires isErrorRecovery

     syntax Bool ::= isVoidOrComplete(Type) [function]
     rule isVoidOrComplete(T:Type)
          => isCompleteType(T)
          orBool isVoidType(T)
          orBool isIncompleteArrayType(T)

     syntax Bool ::= areVoidOrComplete(List) [function]
     rule areVoidOrComplete(L:List) => true
          requires all(L, #klabel(`isVoidOrComplete`))
     rule areVoidOrComplete(_) => false [owise]

     syntax KItem ::= checkMainDef(Type)
     rule checkMainDef(t(_, functionType(t(_, int),
               ListItem(t(_, void)))))
          => .K
          [structural]
     rule checkMainDef(t(_, functionType(t(_, int),
               ListItem(t(_, int)) ListItem(T:Type))))
          => .K
          requires isArgvType(T)
          [structural]
     rule (.K => UNDEF("FD4", "definition of main requires a prototype.", "5.1.2.2.1:1, J.2:1 item 4"))
          ~> checkMainDef(T:Type)
          requires isOldStyleFunctionType(T)
          [structural]
     rule (.K => UNDEF("FD5", "main must return an int.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, functionType(t(_, T:SimpleType), _)))
          requires T =/=K int
          [structural]
     rule (.K => UNDEF("FD6", "if main has arguments, the type of the first argument must be equivalent to int.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, functionType(_, ListItem(t(_, T:SimpleType)) _)))
          requires T =/=K int andBool T =/=K void
          [structural]
     rule (.K => UNDEF("FD7", "if main has arguments, the type of the second argument must be equivalent to char**.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, functionType(_, ListItem(_:Type) ListItem(T:Type))))
          requires notBool isArgvType(T)
          [structural]
     rule (.K => UNDEF("FD8", "main must have zero or two parameters.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, functionType(_, Params:List)))
          requires size(Params) >Int 2
          [structural]
     rule (.K => UNDEF("FD9", "main must have zero or two parameters.", "5.1.2.2.1:1, J.2:1 item 4") )
          ~> checkMainDef(t(_, functionType(_, ListItem(t(_, T:SimpleType)))))
          requires T =/=K void
          [structural]

     syntax Bool ::= isArgvType(Type) [function]
     rule isArgvType(t(_, incompleteArrayType(t(_, pointerType(t(_, T:SimpleType))))))
          => true
          requires T ==K char // char is an alias.
     rule isArgvType(t(_, pointerType(t(_, pointerType(t(_, T:SimpleType))))))
          => true
          requires T ==K char
     rule isArgvType(_) => false [owise]

     rule initFunction(tv(Loc:SymLoc, T:Type), X:CId, Fun:RValue)
          => te(initFunction(&(X), X, Fun), T)
          requires isLinkerLoc(Loc)
     rule <k> initFunction(
               tv(Loc:SymLoc, t(_, pointerType(_:FunctionType))), _, Fun:RValue)
               => voidVal
          ...</k>
          <functions> M:Map => M[base(Loc) <- Fun] </functions>
          requires notBool isLinkerLoc(Loc)

     syntax KItem ::= safeBody(CId, K) [function]

     rule safeBody(X:CId, Blk:K)
          => Blk ~> Return(NothingExpression)
          requires X =/=K Identifier("main")
     rule safeBody(Identifier("main"), Blk:K)
          => Blk ~> Return(tv(0, t(.Set, int)))

     syntax KItem ::= staticEval(CId, List, K)
     syntax KItem ::= calculateGotoMap(CId)

     rule staticEval(X:CId, Params:List, Blk:K)
          => scope(blockScope(X, 0),
               generateRuleAnnotation(X)
               ~> elaborate(dummyBind(Params)
                    ~> Label(funLabel(X), safeBody(X, Blk)))
               ~> calculateGotoMap(X))

     rule elaborateDone(K:K) ~> calculateGotoMap(X:CId)
          => calculateGotoMap(X, K)

     syntax Bool ::= "#hasDupParams'" "(" Type ")" [function]
     rule hasDupParams(T:Type) => #hasDupParams'(T)
     rule #hasDupParams'(typedDeclaration(T:Type, _)) => #hasDupParams'(T)
     rule #hasDupParams'(t(_, functionType(_, P:List))) => #hasDupIds'(P)
     rule #hasDupParams'(_) => false [owise]

     // TODO(liyili2): no associative matching in Java currently, we will do it once we
     // have the associative matching.
     syntax Bool ::= hasDupIds(List) [function]
     syntax Bool ::= "#hasDupIds'" "(" List ")" [function]
     syntax Bool ::= cIdIsInList(CId, List) [function]

     rule cIdIsInList(_:CId, .List) => false
     rule cIdIsInList(X:CId, (ListItem(typedDeclaration(_, X:CId)) _:List))
          => true
     rule cIdIsInList(X:CId, (ListItem(typedDeclaration(_, Y:CId)) Tail:List))
          => cIdIsInList(X, Tail)
          requires X =/=K Y
     rule cIdIsInList(X:CId, (ListItem(_:K) Tail:List))
          => cIdIsInList(X, Tail) [owise]

     rule hasDupIds(P:List) => #hasDupIds'(P)

     rule #hasDupIds'(.List) => false
     rule #hasDupIds'(
               ListItem(typedDeclaration(_, X:CId))
               Tail:List)
          => true
          requires cIdIsInList(X, Tail)

     rule #hasDupIds'(
               ListItem(typedDeclaration(_, X:CId))
               Tail:List)
          => #hasDupIds'(Tail)
          requires notBool cIdIsInList(X, Tail)
     rule #hasDupIds'(ListItem(_) Tail:List) => #hasDupIds'(Tail) [owise]

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
