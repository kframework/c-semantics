require "dynamic-c-semantics.k"

module DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE
     imports DYNAMIC-INCLUDE 
     imports COMMON-SEMANTICS-DECLARATIONS-INCLUDE
endmodule

module DYNAMIC-SEMANTICS-DECLARATIONS-BINDING
     imports DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 

     // empty binding
     // fixme not really a sequence point
     
     syntax K ::= "bind-aux" "(" SymLoc "," KList "," KList ")"
     rule <k> bind(L:KList, L':KList) 
               => bind-aux(NullPointer, L:KList, L':KList) ...</k> 
          [structural] 
     
     rule [bind-empty-void]:
          <k> bind-aux(_, .KList, typedDeclaration(t(.Set, void), _:Id)) => sequencePoint ...</k> 
          [structural] 
     rule [bind-empty]:
          <k> bind-aux(_, .KList, .KList) => sequencePoint ...</k> 
          [structural] 
          
          
     // n1494 6.5.2.2:6 If the expression that denotes the called function has
     // a type that does not include a prototype, the integer promotions are
     // performed on each argument, and arguments that have type float are
     // promoted to double. These are called the default argument promotions.
     // If the number of arguments does not equal the number of parameters, the
     // behavior is undefined. If the function is defined with a type that
     // includes a prototype, and either the prototype ends with an ellipsis (,
     // ...) or the types of the arguments after promotion are not compatible
     // with the types of the parameters, the behavior is undefined. If the
     // function is defined with a type that does not include a prototype, and
     // the types of the arguments after promotion are not compatible with
     // those of the parameters after promotion, the behavior is undefined,
     // except for the following cases: 
     //
     // -- one promoted type is a signed integer type, the other promoted type
     // is the corresponding unsigned integer type, and the value is
     // representable in both types;
     //
     // -- both types are pointers to qualified or unqualified versions of a
     // character type or void
     
     // chathhorn: these two rules only mutate the head of the list now.
     rule [bind-coerce-array]:
          bind-aux(
               _
               , _:KList
               , (typedDeclaration(
                        (t(_, (arrayType(T:KResult, _:Int) => pointerType(T:KResult)))), X:Id
               ),, _:KList)
          )
          [structural, anywhere] 
     rule [bind-coerce-incompleteArray]:
          bind-aux(
               _
               , _:KList
               , (typedDeclaration(
                        (t(_, (incompleteArrayType(T:KResult) => pointerType(T:KResult)))), X:Id
               ),, _:KList)
          )
          [structural, anywhere] 
          
     rule [bind-one]:
          <k> true ~> bind-aux(_, (tv(V:KList, T':KResult),, L:KList), (typedDeclaration(T:KResult, X:Id),, P:KList))
               => allocateType(Loc, T:KResult)
               ~> addToEnv(X:Id, Loc)
               ~> giveType(X:Id, T:KResult)
               ~> initialize(X:Id, T:KResult, Computation(AllowWrite(X:Id) := tv(V:KList, T':KResult)))
               ~> bind-aux(Loc, L:KList, P:KList)
          ...</k> 
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          when notBool isArrayType(T:KResult)
          [structural] 
          
     rule [bind-one-check-type]:
          <k> (.K => isTypeCompatible(T:KResult, T':KResult)) 
               ~> bind-aux(_, (tv(V:KList, T':KResult),, L:KList), (typedDeclaration(T:KResult, X:Id),, P:KList))
          ...</k> 
          [structural] 
     
     syntax KList ::= promoteList(KList) [function]
     rule [promoteList-needs-promoting]: promoteList((tv(V:KList, t(S:Set, T:K)),, L:KList)) 
          => cast(argPromote(t(S:Set, T:K)), tv(V:KList, t(S:Set, T:K))),, promoteList(L:KList)
          when (T:K ==K float)
               orElseBool (((rank(t(S:Set, T:K)) <Int rank(t(.Set, int))) orBool isBitfieldType(t(S:Set, T:K))) 
                    andBool hasIntegerType(t(S:Set, T:K))) 
          [structural]
     rule [promoteList-promoted]: promoteList((tv(V:KList, t(S:Set, T:K)),, L:KList)) 
          => (tv(V:KList, t(S:Set, T:K)),, promoteList(L:KList))
          when ((notBool(hasIntegerType(t(S:Set, T:K))) 
                    andBool (notBool T:K ==K float)
                    andBool (notBool isArrayType(t(S:Set, T:K)))) 
               orBool (T:K ==K double)
               orBool (T:K ==K long-double))
               orElseBool (rank(t(S:Set, T:K)) >=Int rank(t(.Set, int)))
          [structural]
     rule promoteList(.KList) => .KList
     
     syntax K ::= "bindVariadic" "(" SymLoc "," KList ")"
     syntax K ::= "bindVariadic-pre" "(" SymLoc "," KList ")"
     
     // the idea here is that there should have been a previous argument, so we
     // can use its address to append all of the variadic arguments 
     rule [bind-variadic-pre]:
          <k> bind-aux(Loc:SymLoc, L:KList, t(_, variadic))
               => bindVariadic-pre(Loc, promoteList(L))
          ...</k>
          [structural] 

     rule [bind-variadic-start]:
          <k> bindVariadic-pre(Loc:SymLoc, L:KList) 
               => bindVariadic(Loc, L)
          ...</k>
          [structural]
     
     // fixme don't forget to get rid of append
     
     // this rule assumes it will be run immediately after other normal
     // bindings for the same function.  This is all wrong if it is
     // computational instead of structural because of other threads
     // interleaving
     rule [bind-variadic]:
          <k> (.K 
                    => allocateType(Loc, type(V:K))
                    ~> Computation(*(tv(Loc, t(.Set, pointerType(type(V:K))))) := V:K)
               ) 
               ~> bindVariadic(_, ((V:K => .KList),, _:KList)) 
          ...</k>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          [structural]
     
     rule [bind-variadic-done]:
          <k> bindVariadic(_, .KList) => sequencePoint ...</k> 
          [structural]
endmodule

module DYNAMIC-SEMANTICS-DECLARATIONS-GENERAL
     imports DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 
     
     // c1x 6.7.8:21 ... the remainder of the aggregate shall be initialized
     // implicitly the same as objects that have static storage duration
     rule <k> initialize(X:Id, T:KResult, K:K)
               => #if (F:Id ==K file-scope) #then zero(X:Id) #else (.) #fi 
               ~> K:K
               ~> sequencePoint
          ...</k>
          <currentFunction> F:Id </currentFunction>
          [structural] 

     rule <k> zero(Name:K) => zeroType(Name:K, unqualifyType(T:KResult)) ...</k>
          <types>... Name:K |-> T:KResult ...</types>
          [structural] 
          
     syntax K ::= "zeroType" "(" K "," Type ")"
     
     rule <k> zeroType(Name:K, T:KResult) 
               => Computation(AllowWrite(Name:K) := tv(0, t(.Set, int))) ...</k>
          when hasIntegerType(T:KResult)
          [structural] 
     rule <k> zeroType(Name:K, T:KResult) 
               => Computation(AllowWrite(Name:K) := tv(0.0, t(.Set, float))) ...</k>
          when isFloatType(T:KResult)
          [structural] 
          
     syntax K ::= "zeroStruct" "(" K "," KList ")"
     
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
     
     rule <k> zeroType(Name:K, t(_, structType(S:Id))) 
               => zeroStruct(Name:K, Fields:KList)
          ...</k>
          <structs>... S:Id |-> aggregateInfo(Fields:KList, _, _) ...</structs> 
          [structural] 
          
     rule <k> zeroType(Name:K, t(_, unionType(S:Id))) 
               => zeroType(Name:K . F:Id, T:KResult)
          ...</k>
          <structs>... 
               S:Id |-> aggregateInfo((typedDeclaration(T:KResult, F:Id),, _), _, _) 
          ...</structs> 
          [structural] 
          
     rule <k> zeroStruct(Name:K, (typedDeclaration(T:KResult, F:Id),, L:KList)) 
               => zeroType(Name:K . F:Id, T:KResult)
               ~> zeroStruct(Name:K, L:KList) 
          ...</k>
          [structural] 
     rule <k> zeroStruct(Name:K, .KList) => .K ...</k>
          [structural] 

     rule <k> zeroType(Name:K, T:KResult) 
               => Computation(AllowWrite(Name:K) := tv(NullPointer, T:KResult)) ...</k>
          when isPointerType(T:KResult)
          [structural]
     rule <k> zeroType(Name:K, T:KResult) => .K ...</k>
          when isFunctionType(T:KResult)
          [structural]
          
     // fixme snat
     rule <k> zeroType(Name:K, t(S:Set, arrayType(T:KResult, Len:Int))) 
               => zeroType(Name:K[Len:Int -Int 1], T:KResult)
               ~> zeroType(Name:K, t(S:Set, arrayType(T:KResult, Len:Int -Int 1))) 
          ...</k>
          when Len:Int >Int 0
          [structural] 
     rule <k> zeroType(Name:K, t(_, arrayType(T:KResult, 0))) => .K ...</k>
          [structural] 

     rule <k> zeroType(Name:K, t(_, flexibleArrayType(T:KResult)))
               => .K
          ...</k>
          [structural]
endmodule

module DYNAMIC-SEMANTICS-DECLARATIONS-INITIALIZATIONS
     imports DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 
endmodule


module DYNAMIC-SEMANTICS-DECLARATIONS-RESOLUTION
     imports DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 
endmodule

module DYNAMIC-SEMANTICS-DECLARATIONS-ENUMS
     imports DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE 
endmodule

module DYNAMIC-C-DECLARATIONS
     imports DYNAMIC-SEMANTICS-DECLARATIONS-INCLUDE
     
     imports DYNAMIC-SEMANTICS-DECLARATIONS-BINDING 
     imports DYNAMIC-SEMANTICS-DECLARATIONS-GENERAL 
     imports DYNAMIC-SEMANTICS-DECLARATIONS-INITIALIZATIONS 
     imports DYNAMIC-SEMANTICS-DECLARATIONS-ENUMS 
     imports DYNAMIC-SEMANTICS-DECLARATIONS-RESOLUTION 
endmodule
