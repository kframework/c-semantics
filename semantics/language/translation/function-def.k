module C-FUNCTION-DEF-SYNTAX
     syntax KItem ::= initFunction(K, K) [strict]
     syntax Bool ::= hasDupParams(Type) [function]
endmodule

module C-FUNCTION-DEF
     imports C-FUNCTION-DEF-SYNTAX

     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-PROCESS-LABEL-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BINDING-SYNTAX

     imports COMPAT-SYNTAX

     rule FunctionDefinition(typedDeclaration(T:Type, X:CId), Blk:K)
          => declare(
               typedDeclaration(toPrototype(T), X),
               initializer(initFunction(
                    &(X),
                    functionObject(X,
                         // The sanitized declared parameters.
                         elideList(getParams(emptyToVoid(T))),
                         // The "prototype" -- basically a type with the same
                         // parameters as above, but the parameters are set to
                         // .List if there isn't actually a prototype.
                         toPrototype(T),
                         Goto(funLabel(X)))
               ))
          )
          ~> calculateGotoMap(X, Label(funLabel(X), safeBody(X, Blk)))
          ~> processFunDef(X, Blk)
          requires isFunctionType(T) andBool notBool hasDupParams(T)
          [structural]
     rule (.K => ERROR("FD1", "duplicate parameters in "
               +String "function definition."))
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
     rule emptyToVoid(T:Type)
          => setParams(T, ListItem(typedDeclaration(t(.Set, void), #NoName)))
          requires isFunctionType(T)
               andBool (getParams(T) ==K .List)
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
     rule checkFunDefType(X:CId, T:Type) => .K
          requires notBool isFunctionType(getReturn(T))
               andBool notBool isArrayType(getReturn(T))
               andBool areVoidOrComplete(getParams(T))
               andBool (X =/=K Identifier("main"))
          [structural]
     rule checkFunDefType(X:CId, T:Type) => checkMainDef(T)
          requires isVoidOrComplete(getReturn(T))
               andBool areVoidOrComplete(getParams(T))
               andBool (X ==K Identifier("main"))
          [structural]
     rule (.K => UNDEF("FD2", "invalid return type in function definition.",
               "6.7.6.3:1"))
          ~> checkFunDefType(_, T:Type)
          requires isFunctionType(getReturn(T)) orBool isArrayType(getReturn(T))
          [structural]
     rule (.K => UNDEF("FD3", "incomplete parameter type in "
               +String "function definition.", "6.7.6.3:4"))
          ~> checkFunDefType(_, T:Type)
          requires notBool areVoidOrComplete(getParams(T))
          [structural]

     syntax Bool ::= isVoidOrComplete(Type) [function]
     rule isVoidOrComplete(T:Type)
          => isCompleteType(T)
          orBool isVoidType(T)
          orBool isIncompleteArrayType(T)

     syntax Bool ::= areVoidOrComplete(List) [function]
     rule areVoidOrComplete(L:List) => true
          requires all(L, 'isVoidOrComplete)
     rule areVoidOrComplete(_) => false [owise]

     syntax KItem ::= checkMainDef(Type)
     rule checkMainDef(t(_, functionType(t(_, int),
               ListItem(t(_, void)))))
          => .K
          [structural]
     rule checkMainDef(t(_, functionType(t(_, int),
               ListItem(t(_, int)) ListItem(T:Type))))
          => .K
          requires #isArgvType(T) ==K true
          [structural]
     rule (.K => ERROR("FD4", "definition of main requires a prototype (5.1.2.2.1p1)."))
          ~> checkMainDef(T:Type)
          requires isOldStyleFunctionType(T)
          [structural]
     rule (.K => ERROR("FD5", "main must return an int.", 4) )
          ~> checkMainDef(t(_, functionType(t(_, T:SimpleType), _)))
          requires T =/=K int
          [structural]
     rule (.K => ERROR("FD6", "if main has arguments, the type of the first argument must be equivalent to int.", 4) )
          ~> checkMainDef(t(_, functionType(_, ListItem(t(_, T:SimpleType)) _)))
          requires T =/=K int andBool T =/=K void
          [structural]
     rule (.K => ERROR("FD7", "if main has arguments, the type of the second argument must be equivalent to char**.") )
          ~> checkMainDef(t(_, functionType(_, ListItem(_:Type) ListItem(T:Type))))
          requires #isArgvType(T) =/=K true
          [structural]
     rule (.K => ERROR("FD8", "main must have zero or two parameters.") )
          ~> checkMainDef(t(_, functionType(_, Params:List)))
          requires size(Params) >Int 2
          [structural]
     rule (.K => ERROR("FD9", "main must have zero or two parameters.") )
          ~> checkMainDef(t(_, functionType(_, ListItem(t(_, T:SimpleType)))))
          requires T =/=K void
          [structural]

     syntax Bool ::= #isArgvType(Type) [function]
     rule #isArgvType(t(_, incompleteArrayType(t(_, pointerType(t(_, T:SimpleType))))))
          => true
          requires T ==K char // char is an alias.
     rule #isArgvType(t(_, pointerType(t(_, pointerType(t(_, T:SimpleType))))))
          => true
          requires T ==K char
     rule #isArgvType(_) => false [owise]

     rule <k> initFunction(
               tv(Loc:SymLoc, t(_, pointerType(T:Type))), Fun:KResult)
               => .K
          ...</k>
          <functions> M:Map => M[base(Loc) <- Fun] </functions>
          requires isFunctionType(T) andBool (notBool (base(Loc) in keys(M)))
          [structural]

     syntax KItem ::= safeBody(CId, K) [function]

     rule safeBody(X:CId, Blk:K)
          => Blk ~> Return(NothingExpression)
          requires X =/=K Identifier("main")
     rule safeBody(Identifier("main"), Blk:K)
          => Blk ~> Return(tv(0, t(.Set, int)))

     syntax KItem ::= "returnToFileScope"

     syntax KItem ::= staticEval(CId, List, K)
     rule <k> staticEval(X:CId, Params:List, Blk:K)
               => pushBlock
               ~> dummyBind(Params)
               ~> Blk
               ~> popBlock
               ~> returnToFileScope
          ...</k>
          <curr-function> _ => X </curr-function>
          [structural]

     rule <k> returnToFileScope => .K ...</k>
          <curr-function> _ => file-scope </curr-function>
          [structural]

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
     rule dummyBind(ListItem(typedDeclaration(T:Type, _))) => .K
          requires isVoidType(T)
          [structural]
     rule dummyBind(ListItem(typedDeclaration(T:Type, X:CId)) Params:List)
          => addToEnv(X, symVal)
          ~> giveType(X, T)
          ~> dummyBind(Params)
          requires notBool isVoidType(T)
          [structural]
endmodule
