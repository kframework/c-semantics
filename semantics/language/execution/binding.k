module C-BINDING-SYNTAX
     syntax K ::= bind(KList, KList)
endmodule

module C-BINDING
     imports C-BINDING-SYNTAX
     imports C-DECL-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX

     // empty binding
     // fixme not really a sequence point
     
     syntax K ::= "bind-aux" "(" SymLoc "," KList "," KList ")"
     rule bind(L:KList, L':KList) 
          => bind-aux(NullPointer, L, L')
          [structural] 
     
     rule [bind-empty-void]:
          bind-aux(_, .KList, typedDeclaration(t(.Set, void), _:Id))
          => sequencePoint
          [structural] 
     rule [bind-empty]:
          bind-aux(_, .KList, .KList)
          => sequencePoint
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
     
     rule [bind-coerce-array]:
          bind-aux(
               _
               , _:KList
               , (typedDeclaration(
                        (t(_, (arrayType(T:Type, _:Int)
                        => pointerType(T)))), _:Id
               ),, _:KList)
          )
          [structural, anywhere] 
     rule [bind-coerce-incompleteArray]:
          bind-aux(
               _
               , _:KList
               , (typedDeclaration(
                        (t(_, (incompleteArrayType(T:Type)
                        => pointerType(T)))), _:Id
               ),, _:KList)
          )
          [structural, anywhere] 
          
     rule [bind-one]:
          <k> 
               bind-aux(_, (tv(V:KList, T':Type),, L:KList), 
                    (typedDeclaration(T:Type, X:Id),, P:KList))
               => allocateType(Loc, T)
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, T)
                    ~> Computation(allowWrite(X) := tv(V, T'))
                    ~> bind-aux(Loc, L, P)
          ...</k> 
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          when notBool isArrayType(T)
               andBool notBool isVoidType(T)
          [structural] 
          
     // TODO(chathhorn): consider adding back a check here, isTypeCompat no
     // longer makes sense in this context.
     // rule [bind-one-check-type]:
     //      (. => isTypeCompatible(T, T')) 
     //      ~> bind-aux(_, (tv(_:KList, T':Type),, _:KList), 
     //           (typedDeclaration(T:Type, _:Id),, _:KList))
     //      [structural] 
     
     syntax KList ::= promoteList(KList) [function]
     rule [promoteList-needs-promoting]: 
          promoteList((tv(V:KList, t(S:Set, T:K)),, L:KList)) 
          => cast(argPromote(t(S, T)), tv(V, t(S, T))),, promoteList(L)
          when (T ==K float) 
               orElseBool (hasIntegerType(t(S:Set, T:K)) 
                    andBool ((rank(t(S, T)) <Int rank(t(.Set, int))) 
                         orElseBool isBitfieldType(t(S, T))))

     rule [promoteList-promoted]: 
          promoteList((tv(V:KList, t(S:Set, T:K)),, L:KList)) 
          => (tv(V, t(S, T)),, promoteList(L))
          when ((notBool(hasIntegerType(t(S, T))) 
                    andBool (notBool T ==K float)
                    andBool (notBool isArrayType(t(S, T)))) 
               orBool (T ==K double)
               orBool (T ==K long-double))
               orElseBool (rank(t(S, T)) >=Int rank(t(.Set, int)))

     rule promoteList(.KList) => .KList
     
     syntax K ::= bindVariadic(SymLoc, KList)
     syntax K ::= "bindVariadic-pre" "(" SymLoc "," KList ")"
     
     // the idea here is that there should have been a previous argument, so we
     // can use its address to append all of the variadic arguments 
     rule [bind-variadic-pre]:
          bind-aux(Loc:SymLoc, L:KList, t(_, variadic))
          => bindVariadic-pre(Loc, promoteList(L))
          [structural] 

     rule [bind-variadic-start]:
          bindVariadic-pre(Loc:SymLoc, L:KList)
          => bindVariadic(Loc, L)
          [structural]
     
     // fixme don't forget to get rid of append
     
     // this rule assumes it will be run immediately after other normal
     // bindings for the same function.  This is all wrong if it is
     // computational instead of structural because of other threads
     // interleaving
     rule [bind-variadic]:
          <k> 
               (.K 
               => allocateType(Loc, type(V))
                    ~> Computation(
                         *(tv(Loc, t(.Set, pointerType(type(V))))) := V)
               ) 
               ~> bindVariadic(_, ((V:K => .KList),, _:KList)) 
          ...</k>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          [structural]
     
     rule [bind-variadic-done]:
          bindVariadic(_, .KList) => sequencePoint
          [structural]
endmodule

