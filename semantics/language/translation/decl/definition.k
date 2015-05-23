module C-DECL-DEFINITION-SYNTAX
     imports C-ABSTRACT-SYNTAX

     syntax KItem ::= declare(K, K) [strict(1)]

     // The declare "backend" implemented in the trans or exec semantics.
     syntax KItem ::= "declare'" "(" K "," K ")" [strict(1)]

endmodule

module C-DECL-DEFINITION
     imports C-DECL-DEFINITION-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX

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
               InitNameGroup(T:Type, list(ListItem(K:K) ListItem(K':K) L:List)))
          => DeclarationDefinition(InitNameGroup(T, list(ListItem(K))))
               ~> DeclarationDefinition(InitNameGroup(T, list(ListItem(K') L)))
          [structural]
     rule DeclarationDefinition(
               InitNameGroup(T:Type, list(ListItem(InitName(N:K, Exp:K)))))
          => declare(SingleName(T, N), Exp)
          [structural]

     rule declare(T:Type, K:K)
          => declare'(elideDeclParams(T), K)
          [structural]

endmodule

