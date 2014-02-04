module C-FUNCTION-DEF-SYNTAX
     syntax K ::= initFunction(K, K) [strict]
endmodule

module C-FUNCTION-DEF
     imports C-FUNCTION-DEF-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX

     imports C-PROCESS-LABEL-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports COMPAT-SYNTAX

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
          <currentFunction> _ => X </currentFunction>

     rule <k> returnToFileScope => . ...</k>
          <currentFunction> _ => file-scope </currentFunction>

     syntax K ::= dummyBind(List)
     
     rule dummyBind(ListItem(typedDeclaration(t(.Set, void), _)) _:List) => .
     rule dummyBind(.List) => .
     rule dummyBind(ListItem(t(_, variadic))) => .

     rule dummyBind(ListItem(typedDeclaration(
          (t(_, (arrayType(T:Type, _:Int) => pointerType(T)))),
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
