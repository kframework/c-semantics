module C-DECLARATION-GENERAL-SYNTAX
     syntax K ::= doDeclare(K, K) [strict(1)] 
endmodule

module C-DECLARATION-GENERAL
     imports C-DECLARATION-GENERAL-SYNTAX
     imports C-DECLARATION-INITIALIZATION-SYNTAX
     imports C-DECLARATION-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     // c99 6.7.8:9 Except where explicitly stated otherwise, for the purposes
     // of this subclause unnamed members of objects of structure and union
     // type do not participate in initialization. Unnamed members of
     // structure objects have indeterminate value even after initialization

     // c99 6.7.8:10 If an object that has automatic storage duration is not
     // initialized explicitly, its value is indeterminate. If an object that
     // has static storage duration is not initialized explicitly, then:

     // -- if it has pointer type, it is initialized to a null pointer;

     // -- if it has arithmetic type, it is initialized to (positive or
     // unsigned) zero;

     // if it is an aggregate, every member is initialized (recursively)
     // according to these rules;

     // -- if it is a union, the first named member is initialized
     // (recursively) according to these rules

     // id, type, initializer
     syntax K ::= "figureInit-aux" "(" Id "," Type "," K ")" [strict(3)]

     context DeclarationDefinition(InitNameGroup(HOLE, _)) 

     rule DeclarationDefinition(
               InitNameGroup(T:Type, klist((K:K,, K':K,, L:KList))))
          => DeclarationDefinition(InitNameGroup(T, klist(K)))
               ~> DeclarationDefinition(InitNameGroup(T, klist((K',, L))))
          [structural]
     rule DeclarationDefinition(
               InitNameGroup(T:Type, klist(InitName(N:K, Exp:K))))
          => doDeclare(SingleName(T, N), Exp)
          [structural]
               
     rule figureInit(X:Id, T:Type, CodeLoc(K:K, L:K)) 
          => CodeLoc(.K, L) ~> figureInit(X, T, K) 
          [structural]
     
     // aggregates
     rule figureInit(X:Id, T:Type, CompoundInit(L:K))
          => giveType(X, T)
               ~> figureInit-aux(X, T,
                    startInit(T, X, CompoundInit(L)))
          when isAggregateType(T) orBool isUnionType(T)
          [structural] 

     rule figureInit(
               _:Id, 
               t(_:Set, arrayType(T:Type, Len:Int)), 
               (SingleInit(Constant(StringLiteral(S:String))) 
               => CompoundInit(klist(InitFragment(NextInit,
                    SingleInit(Constant(StringLiteral(S)))))))
          )
          when isCharType(T) andBool (lengthString(S) <=Int Len)
          [structural]

     rule figureInit(
               _:Id, 
               t(_:Set, arrayType(T:Type, Len:Int)), 
               (SingleInit(Constant(WStringLiteral(S:KList))) 
               => CompoundInit(klist(InitFragment(NextInit,
                    SingleInit(Constant(WStringLiteral(S)))))))
          )
          when isWCharType(T) andBool (lengthKList S <=Int Len)
          [structural] 
     
     rule figureInit(_:Id, t(_, (incompleteArrayType(T:Type) 
          => arrayType(T, lengthString(S) +Int 1))),
               SingleInit(Constant(StringLiteral(S:String)))) 
          when isCharType(T)
          [structural]

     rule figureInit(_:Id, t(_, (incompleteArrayType(T:Type)
          => arrayType(T, lengthKList S +Int 1))),
               SingleInit(Constant(WStringLiteral(S:KList)))) 
          when isWCharType(T)
          [structural] 
          
     rule figureInit(X:Id, t(Se:Set, incompleteArrayType(T:Type)),
               CompoundInit(klist(InitFragment(NextInit,
               SingleInit(Constant(StringLiteral(S:String)))))))
          => figureInit(X, t(Se, incompleteArrayType(T)),
               SingleInit(Constant(StringLiteral(S))))
          [structural] 
          
     // this comes from function declarations.  should probably adjust this
     rule figureInit(X:Id, T:Type, initializer(K:K))
          => figureInit-aux(X, T, initializer(K))
          [structural] 

     rule figureInit-aux(X:Id, T:Type, initializer(K:K))
          => initValue(X, T, K)
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T)
               andBool notBool isConstType(T)
          [structural]
     rule figureInit-aux(X:Id, T:Type, initializer(K:K))
          => initValue(X, T, (K ~> makeUnwritableVar(X)))
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T)
               andBool isConstType(T)
          [structural]
     
     // base types
     rule figureInit(X:Id, T:Type, SingleInit(K:K))
          => figureInit-aux(X, T, 
               initializer(Computation(allowWrite(X) := K)))
          when notBool isArrayType(T)
          [structural] 
     // c1x 6.7.8:11
     rule figureInit(X:Id, T:Type,
               CompoundInit(klist(InitFragment(NextInit, SingleInit(K:K)))))
          => figureInit-aux(X, T,
               initializer(Computation(allowWrite(X) := K)))
          when notBool (isAggregateType(T) orBool isUnionType(T))
          [structural] 
               
     rule <k> 
               figureInit-aux(_:Id, t(_, 
                    (incompleteArrayType(T:Type) 
                    => arrayType(T, N))), initializer(_))
          ...</k>
          <incompleteLength> N:Int </incompleteLength>
          [structural] 
          
     context Typedef(NameGroup(HOLE, _))

     rule Typedef(NameGroup(T:Type, klist((K:K,, L:KList)))) 
          => defineType(SingleName(T, K))
               ~> Typedef(NameGroup(T, klist(L)))
          [structural]
     rule Typedef(NameGroup(_:Type, klist(.KList))) => .K
          [structural]

     syntax K ::= "defineType" "(" K ")" [strict] 

     rule defineType(typedDeclaration(T:Type, X:Id)) 
          => giveType(typedef(X), T) 
          [structural] 

     syntax K ::= "addToLinkage" "(" Id "," Type ")"
     syntax K ::= "addToGlobalEnv" "(" K "," SymLoc ")"
     syntax K ::= "addToLocalEnv" "(" K "," SymLoc ")"
     
     rule <k> addToEnv(X:Id, Loc:SymLoc) => addToGlobalEnv(X, Loc) ...</k>
          <currentFunction> file-scope </currentFunction>
          [structural] 
     rule <k> addToEnv(X:Id, Loc:SymLoc) => addToLocalEnv(X, Loc) ...</k>
          <currentFunction> F:K </currentFunction>
          when F =/=K file-scope
          [structural] 
          
     rule <k> addToGlobalEnv(X:Id, Loc:SymLoc) => . ...</k>
          <genv>... Tu:K |-> map((M':Map => M':Map[Loc / X:Id])) ...</genv>
          <currTU> Tu:K </currTU>
          <env> E:Map => E:Map[Loc / X] </env>
          [structural] 
     rule <k> addToLocalEnv(X:Id, Loc:SymLoc) => . ...</k>
          <env> E:Map => E:Map[Loc / X] </env>
          [structural] 
     
endmodule

