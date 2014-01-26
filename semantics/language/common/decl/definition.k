module C-DECL-DEFINITION-SYNTAX
     syntax K ::= doDeclare(K, K) [strict(1)] 
endmodule

module C-DECL-DEFINITION
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX

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

endmodule

