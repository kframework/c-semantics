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
               typedDeclaration(emptyParamsToVoid(T), X), 
               initializer(initFunction(
                    &(X),
                    functionObject(X, idsFromParams(getParams(T)),
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

     syntax Type ::= emptyParamsToVoid(Type) [function]
     rule emptyParamsToVoid(t(Mods:Set, functionType(R:Type, .List)))
          => t(Mods, functionType(R,
                    ListItem(typedDeclaration(t(.Set, void), #NoName))))
     rule emptyParamsToVoid(t(Mods:Set, functionType(R:Type, P:List)))
          => t(Mods, functionType(R, P))
          when P =/=List .List

     syntax K ::= processFunDef(Id, K)
                | staticEval(Id, List, List, K)

     rule <k> processFunDef(X:Id, Blk:K)
               => checkFunDefType(T)
               ~> staticEval(X, Ids, getParams(T), Blk)
          ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          // Get the type created by processing the declaration (i.e., with
          // adjusted parameter types).
          <types>... X |-> T:Type ...</types>
          <functions>...
               Loc |-> functionObject(_, Ids:List, _)
          ...</functions>

     syntax K ::= checkFunDefType(Type)
     rule checkFunDefType(t(_, functionType(Ret:Type, Params:List))) => .
          when isVoidOrComplete(Ret) andBool areVoidOrComplete(Params)
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

     rule (. => ERROR("FD2", "incomplete return type in "
               +String "function definition (6.7.6.3p4)."))
          ~> checkFunDefType(t(_, functionType(Ret:Type, _)))
          when notBool isVoidOrComplete(Ret)
          [structural]

     rule (. => ERROR("FD3", "incomplete parameter type in "
               +String "function definition (6.7.6.3p4)."))
          ~> checkFunDefType(t(_, functionType(_, Params:List)))
          when notBool areVoidOrComplete(Params)
          [structural]

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

     rule <k> staticEval(X:Id, Ids:List, P:List, Blk:K)
               => populateFromGlobal
               ~> dummyBind(Ids, P)
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


     syntax K ::= dummyBind(List, List)
     
     rule dummyBind(.List, ListItem(t(.Set, void)) _) => .
          [structural]
     rule dummyBind(.List, ListItem(variadic)) => .
          [structural]
     rule dummyBind(ListItem(X:Id) Ids:List, ListItem(T:Type) P:List)
          => addToEnv(X, symVal)
          ~> giveType(X, T)
          ~> dummyBind(Ids, P)
          when notBool isVoidType(T)
          [structural] 
     rule dummyBind(.List, .List) => .
          [structural]

endmodule
