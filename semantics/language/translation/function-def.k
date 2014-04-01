module C-FUNCTION-DEF-SYNTAX
     syntax K ::= initFunction(K, K) [strict]
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

     imports COMPAT-SYNTAX

     // FIXME check prototypes
     // TODO(chathhorn): the parameters in a function must be complete types
     // (but not necessarily in a function prototype, I don't think).
     rule [function-definition]:
          FunctionDefinition(typedDeclaration(T:Type, X:Id), Blk:K) 
          => processFunDef(X, completeTags(T), safeBody(X, Blk))
          when isFunctionType(T)
          [structural]

     syntax K ::= processFunDef(Id, K, K) [strict(2)]
                | staticEval(Id, Type, K)

     rule processFunDef(X:Id, T:Type, K:K) 
          => checkFunctionDef(X, T)
          ~> doDeclare(
               typedDeclaration(T, X), 
               initializer(initFunction(
                    &(X), 
                    functionObject(
                         X, 
                         unqualifyType(T), 
                         K
                    )
               ))
          )
          // TODO(chathhorn): could these be combined?
          ~> calculateGotoMap(X, K)
          ~> staticEval(X, unqualifyType(T), K)

     syntax K ::= checkFunctionDef(Id, Type) [function]
     rule checkFunctionDef(X:Id, t(_, qualifiedType(T:Type, _)))
          => checkFunctionDef(X, T)
     rule checkFunctionDef(_, t(_, functionType(Ret:Type, Params:List))) => .
          when isVoidOrComplete(Ret) andBool areVoidOrComplete(Params)

     syntax Bool ::= isVoidOrComplete(Type) [function]
     rule isVoidOrComplete(T:Type)
          => isCompleteType(T) orBool isVoidType(T)

     syntax Bool ::= areVoidOrComplete(List) [function]
     rule areVoidOrComplete(ListItem(Head:Type) Tail:List)
          => isVoidOrComplete(Head) andBool areVoidOrComplete(Tail)
     rule areVoidOrComplete(.List) => true

     rule (. => ERROR("FD1", "incomplete return type in the definition for "
               +String "function " +String idToString(X) +String " (6.7.6.3p4)."))
          ~> checkFunctionDef(X:Id, t(_, functionType(Ret:Type, _)))
          when notBool isVoidOrComplete(Ret)

     rule (. => ERROR("FD2", "incomplete parameter type in the definition for "
               +String "function " +String idToString(X) +String " (6.7.6.3p4)."))
          ~> checkFunctionDef(X:Id, t(_, functionType(_, Params:List)))
          when notBool areVoidOrComplete(Params)

     rule [initialize-function]:
          <k> initFunction(tv(Loc:SymLoc, t(_, pointerType(T:Type))), 
                    Fun:KResult) 
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

     rule <k> staticEval(X:Id, t(_, functionType(_, P:List)), Blk:K)
          => populateFromGlobal
          ~> dummyBind(P)
          ~> Blk
          ~> returnToFileScope
          ...</k>
          <curr-function> _ => X </curr-function>

     rule <k> returnToFileScope => . ...</k>
          <curr-function> _ => file-scope </curr-function>

     syntax K ::= dummyBind(List)
     
     rule dummyBind(ListItem(typedDeclaration(t(.Set, void), _)) _:List) => .
     rule dummyBind(.List) => .
     rule dummyBind(ListItem(t(_, variadic))) => .

     rule dummyBind(ListItem(typedDeclaration(
          (t(_, (arrayType(T:Type, _) => pointerType(T)))),
          _)) _:List)

     rule dummyBind(ListItem(typedDeclaration(
          (t(_, (incompleteArrayType(T:Type) => pointerType(T)))), 
          _)) _:List)
          
     rule dummyBind(ListItem(typedDeclaration(T:Type, X:Id)) P:List)
          => addToEnv(X, symVal)
          ~> giveType(X, T)
          ~> dummyBind(P)
          when notBool isArrayType(T)
               andBool notBool isVoidType(T)
          [structural] 

endmodule
