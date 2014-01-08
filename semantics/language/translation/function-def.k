module C-FUNCTION-DEF
     imports C-DECLARATION-SYNTAX
     imports C-PROCESS-LABEL-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     // FIXME check prototypes
     rule [function-definition]:
          FunctionDefinition(typedDeclaration(T:Type, X:Id), Blk:K) 
          => verifyDecl(typedDeclaration(T, X))
               ~> createNewFun(X, T, safeBody(X, Blk))
               ~> calculateGotoMap(X, safeBody(X, Blk))
          when isFunctionType(T)
          [structural]

     syntax K ::= createNewFun(Id, Type, K) [function]

     rule createNewFun(X:Id, T:Type, Blk:K)
          => declareFunction(
               X, 
               T, 
               initializer(initFunction(
                    &(X), 
                    functionObject(
                         X, 
                         unqualifyType(T), 
                         Blk
                    )
               ))
          )
          
     syntax K ::= safeBody(Id, K) [function]

     rule safeBody(X:Id, Blk:K) 
          => Blk ~> Return(NothingExpression)
          when X =/=K Identifier("main")
     rule safeBody(Identifier("main"), Blk:K) 
          => Blk ~> Return(tv(0, t(.Set, int)))

endmodule
