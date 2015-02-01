module C-DECL-ZERO-SYNTAX
     imports C-SYNTAX

     syntax KItem ::= zero(CId)
endmodule

module C-DECL-ZERO
     imports C-DECL-ZERO-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-BITS-SYNTAX

     imports DEBUG-SYNTAX

     rule <k> zero(X:CId) => zeroType(X, T) ...</k>
          <types>... X |-> T:Type ...</types>
          [structural]

     syntax KItem ::= zeroType(K, Type)

     // c1x 6.7.9:10 If an object that has automatic storage duration is not
     // initialized explicitly, its value is indeterminate. If an object that
     // has static or thread storage duration is not initialized explicitly,
     // then:
     // -- if it has pointer type, it is initialized to a null pointer;
     // -- if it has arithmetic type, it is initialized to (positive or
     // unsigned) zero;
     // -- if it is an aggregate, every member is initialized (recursively)
     // according to these rules, and any padding is initialized to zero bits;
     // -- if it is a union, the first named member is initialized
     // (recursively) according to these rules, and any padding is initialized
     // to zero bits;

     rule zeroType(X:K, T:Type)
          => Computation(X := tv(getZero(T), stripQualifiers(T)))
          requires isPointerType(T) orBool hasArithmeticType(T)
          [structural]

     rule zeroType(X:K, t(S:Set, arrayType(T:Type, Len:Int)))
          => zeroType(X[Len -Int 1], T)
               ~> zeroType(X, t(S:Set, arrayType(T, Len -Int 1)))
          requires Len >Int 0
          [structural]
     rule zeroType(_, t(_, arrayType(_:Type, 0))) => .K
          [structural]

     rule zeroType(X:K, t(_, structType(_,
               fieldInfo(Fields:List, _, _, _)
          )))
          => zeroStruct(X, Fields)
          [structural]

     rule zeroType(X:K, t(_, unionType(_,
               fieldInfo(ListItem(typedDeclaration(T:Type, F:CId)) _, _, _, _)
          )))
          => zeroType(X . F, T)
          [structural]

     rule zeroType(_, T:Type) => .K
          requires isFunctionType(T)
          [structural]

     rule zeroType(_, t(_, flexibleArrayType(_))) => .K
          [structural]

     syntax KItem ::= zeroStruct(K, List)
     rule zeroStruct(X:K, ListItem(typedDeclaration(T:Type, F:CId)) L:List)
          => zeroType(X . F, T) ~> zeroStruct(X, L)
          [structural]
     rule zeroStruct(_, .List) => .K
          [structural]

     syntax KItem ::= getZero(Type) [function]
     rule getZero(T:Type) => 0
          requires hasIntegerType(T)
     rule getZero(T:Type) => 0.0
          requires hasFloatType(T)
     rule getZero(T:Type) => NullPointer
          requires isPointerType(T)

endmodule

