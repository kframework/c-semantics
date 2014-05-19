module C-FUNCTION-DEF-SYNTAX
     syntax K ::= initFunction(K, K) [strict]
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

     rule FunctionDefinition(typedDeclaration(T:Type, X:Id), Blk:K) 
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
          when isFunctionType(T) andBool notBool hasDupParams(T)
          [structural]
     rule (. => ERROR("FD1", "duplicate parameters in "
               +String "function definition."))
          ~> FunctionDefinition(typedDeclaration(T:Type, _), _) 
          when hasDupParams(T)
     
     // TODO(chathhorn): possibly check that old-style declarations are
     // promoted types?

     // Turns empty param list into void and turns an old-style param list into
     // the empty list so that arguments will be promoted on call.
     syntax Type ::= toPrototype(Type) [function]
     rule toPrototype(T:Type) => elideDeclParams(emptyToVoid(T))
          when notBool isOldStyleFunctionType(T)
     rule toPrototype(T:Type) => setParams(T, .List)
          when isOldStyleFunctionType(T)

     syntax Type ::= emptyToVoid(Type) [function]
     rule emptyToVoid(T:Type)
          => setParams(T, ListItem(typedDeclaration(t(.Set, void), #NoName)))
          when isFunctionType(T)
               andBool (getParams(T) ==List .List)
     rule emptyToVoid(T:Type) => T
          when notBool isFunctionType(T)
               orBool (getParams(T) =/=List .List)
     
     // syntax List ::= toIds(List) [function]
     // rule toIds(ListItem(typedDeclaration(T:Type, X:Id)) L:List)
     //      => ListItem(X) toIds(L)
     //      when notBool isVoidType(T)
     // rule toIds(ListItem(typedDeclaration(T:Type, _))) => .List
     //      when isVoidType(T)
     // rule toIds(ListItem(variadic)) => .List
     // rule toIds(.List) => .List

     syntax K ::= processFunDef(Id, K)

     rule <k> processFunDef(X:Id, Blk:K)
               => checkFunDefType(X, Proto)
               ~> staticEval(X, Params, Blk)
          ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <functions>...
               Loc |-> functionObject(_, Params:List, Proto:Type, _)
          ...</functions>
          [structural]

     syntax K ::= checkFunDefType(Id, Type)
     rule checkFunDefType(X:Id, T:Type) => .
          when isVoidOrComplete(getReturn(T))
               andBool areVoidOrComplete(getParams(T))
               andBool notBool ((X ==K Identifier("main"))
                    andBool isOldStyleFunctionType(T))
          [structural]
     rule (. => ERROR("FD2", "incomplete return type in "
               +String "function definition (6.7.6.3p4)."))
          ~> checkFunDefType(_, T:Type)
          when notBool isVoidOrComplete(getReturn(T))
          [structural]
     rule (. => ERROR("FD3", "incomplete parameter type in "
               +String "function definition (6.7.6.3p4)."))
          ~> checkFunDefType(_, T:Type)
          when notBool areVoidOrComplete(getParams(T))
          [structural]
     rule (. => ERROR("FD3", "definition of main requires "
               +String "a prototype (5.1.2.2.1p1)."))
          ~> checkFunDefType(X:Id, T:Type)
          when (X ==K Identifier("main"))
               andBool isOldStyleFunctionType(T)
          [structural]

     syntax Bool ::= isVoidOrComplete(Type) [function]
     rule isVoidOrComplete(T:Type)
          => isCompleteType(T)
          orBool isVoidType(T)
          orBool isIncompleteArrayType(T)

     syntax Bool ::= areVoidOrComplete(List) [function]
     rule areVoidOrComplete(ListItem(Head:Type) Tail:List)
          => isVoidOrComplete(Head) andBool areVoidOrComplete(Tail)
     rule areVoidOrComplete(.List) => true

     rule <k> initFunction(tv(Loc:SymLoc, t(_, pointerType(T:Type))), Fun:KResult) 
               => .
          ...</k>
          <functions> M:Map => M:Map[Fun / Loc] </functions>
          when isFunctionType(T)
               andBool notBool $hasMapping(M, Loc)
          [structural]

     syntax K ::= safeBody(Id, K) [function]

     rule safeBody(X:Id, Blk:K) 
          => Blk ~> Return(NothingExpression)
          when X =/=K Identifier("main")
     rule safeBody(Identifier("main"), Blk:K) 
          => Blk ~> Return(tv(0, t(.Set, int)))

     syntax K ::= "returnToFileScope"

     syntax K ::= staticEval(Id, List, K)
     rule <k> staticEval(X:Id, Params:List, Blk:K)
               => populateFromGlobal
               ~> dummyBind(Params)
               ~> Blk
               ~> returnToFileScope
          ...</k>
          <curr-function> _ => X </curr-function>
          [structural]

     rule <k> returnToFileScope => . ...</k>
          <curr-function> _ => file-scope </curr-function>
          [structural]

     syntax Bool ::= "#hasDupParams'" "(" Type ")" [function]
     rule hasDupParams(T:Type) => #hasDupParams'(T) ==K true
     rule #hasDupParams'(typedDeclaration(T:Type, _)) => #hasDupParams'(T)
     rule #hasDupParams'(t(_, functionType(_, P:List))) => #hasDupIds'(P)

     syntax Bool ::= hasDupIds(List) [function]
     syntax Bool ::= "#hasDupIds'" "(" List ")" [function]
     rule hasDupIds(P:List) => #hasDupIds'(P) ==K true
     rule #hasDupIds'(
               _
               ListItem(typedDeclaration(_, X:Id))
               _
               ListItem(typedDeclaration(_, X:Id))
               _
          ) => true

     syntax K ::= dummyBind(List)
     
     rule dummyBind(.List) => .
          [structural]
     rule dummyBind(ListItem(variadic)) => .
          [structural]
     rule dummyBind(ListItem(typedDeclaration(T:Type, _))) => .
          when isVoidType(T)
          [structural]
     rule dummyBind(ListItem(typedDeclaration(T:Type, X:Id)) Params:List)
          => addToEnv(X, symVal)
          ~> giveType(X, T)
          ~> dummyBind(Params)
          when notBool isVoidType(T)
          [structural] 
endmodule
