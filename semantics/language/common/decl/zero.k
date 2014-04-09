module C-DECL-ZERO-SYNTAX
     syntax K ::= zero(K)
endmodule

module C-DECL-ZERO
     imports C-DECL-ZERO-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX

     rule <k> zero(Sym:K) => zeroType(Sym, T) ...</k>
          <types>... Sym |-> T:Type ...</types>
          [structural] 
          
     syntax K ::= zeroType(K, Type)
     
     rule zeroType(N:K, T:Type)
          => Computation(allowWrite(N) := tv(0, t(.Set, int)))
          when hasIntegerType(T)
          [structural] 
     rule zeroType(N:K, T:Type)
          => Computation(allowWrite(N) := tv(0.0, t(.Set, float)))
          when isFloatType(T)
          [structural] 
          
     syntax K ::= zeroStruct(K, List)
     
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
     
     rule zeroType(N:K, t(_, structType(_, _, 
               fieldInfo(Fields:List, _, _)
          )))
          => zeroStruct(N, Fields)
          [structural] 
          
     // TODO(chathhorn): what does the standard mean by "any padding is
     // initialized to zero bits"? Does it mean the padding around bitfields
     // and other such padding caused by alignment concerns, or the padding
     // caused by the size of other fields in the union? As things are, we set
     // the padding between the end of the first field and the end of the union
     // to unknown.
     rule zeroType(N:K, t(_, unionType(_, _,
               fieldInfo(ListItem(typedDeclaration(T:Type, F:Id)) _, _, _) 
          )))
          => zeroType(N . F, T)
          [structural] 
          
     rule zeroStruct(Sym:K, ListItem(typedDeclaration(T:Type, F:Id)) L:List) 
          => zeroType(Sym . F, T) ~> zeroStruct(Sym, L) 
          [structural] 
     rule zeroStruct(_, .List) => .
          [structural] 

     rule zeroType(Sym:K, T:Type) 
          => Computation(allowWrite(Sym) := tv(NullPointer, T))
          when isPointerType(T)
          [structural]
     rule zeroType(_, T:Type) => .
          when isFunctionType(T)
          [structural]
          
     // fixme snat
     rule zeroType(Sym:K, t(S:Set, arrayType(T:Type, Len:Int))) 
          => zeroType(Sym[Len -Int 1], T)
               ~> zeroType(Sym, t(S:Set, arrayType(T, Len -Int 1))) 
          when Len >Int 0
          [structural] 
     rule zeroType(_, t(_, arrayType(_:Type, 0))) => .
          [structural] 

     rule zeroType(_, t(_, flexibleArrayType(_:Type))) => .
          [structural]
endmodule

