module C-FUNCTION-DEF
     imports C-DECLARATION-GENERAL-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-PROCESS-LABEL-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports COMPAT-SYNTAX

     imports C-EXPRESSION-IDENTIFIER-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     // FIXME check prototypes
     rule [function-definition]:
          FunctionDefinition(typedDeclaration(T:Type, X:Id), Blk:K) 
          => processFunDef(X, T, safeBody(X, Blk))
          when isFunctionType(T)
          [structural]

     syntax K ::= processFunDef(Id, Type, K) 
                | staticEval(Id, Type, K)

     rule processFunDef(X:Id, T:Type, K:K) 
          => doDeclare(
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

     syntax K ::= safeBody(Id, K) [function]

     rule safeBody(X:Id, Blk:K) 
          => Blk ~> Return(NothingExpression)
          when X =/=K Identifier("main")
     rule safeBody(Identifier("main"), Blk:K) 
          => Blk ~> Return(tv(0, t(.Set, int)))

     syntax K ::= "returnToFileScope"

     rule <k> staticEval(X:Id, t(_, functionType(_, P:KList)), Blk:K)
          => populateFromGlobal
          ~> dummyBind(P)
          ~> Blk
          ~> returnToFileScope
          ...</k>
          <currentFunction> _ => X </currentFunction>

     rule <k> returnToFileScope => . ...</k>
          <currentFunction> _ => file-scope </currentFunction>

     syntax K ::= dummyBind(KList)
     
     rule dummyBind((typedDeclaration(t(.Set, void), _),, _:KList)) => .
     rule dummyBind(.KList) => .
     rule dummyBind(t(_, variadic)) => .

     rule dummyBind((typedDeclaration(
          (t(_, (arrayType(T:Type, _:Int) => pointerType(T)))), 
          _),, _:KList))

     rule dummyBind((typedDeclaration(
          (t(_, (incompleteArrayType(T:Type) => pointerType(T)))), 
          _),, _:KList))
          
     rule <k> 
               dummyBind((typedDeclaration(T:Type, X:Id),, P:KList))
               => giveType(X, T)
               ~> dummyBind(P)
          ...</k> 
          when notBool isArrayType(T)
               andBool notBool isVoidType(T)
          [structural] 

endmodule
