module C-BINDING-SYNTAX
     syntax K ::= bind(List, List)
endmodule

module C-BINDING
     imports C-BINDING-SYNTAX

     imports C-CONVERSION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     // empty binding
     // fixme not really a sequence point
     
     syntax K ::= "bind-aux" "(" SymLoc "," List "," List ")"
     rule bind(L:List, L':List) => bind-aux(NullPointer, L, L')
          [structural] 
     
     rule [bind-empty-void]:
          bind-aux(_, .List, ListItem(typedDeclaration(t(.Set, void), _:Id)))
          => sequencePoint
          [structural] 
     rule [bind-empty]:
          bind-aux(_, .List, .List)
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
     
     // Array to pointer.
     rule bind-aux(_, _,
               ListItem(typedDeclaration(t(_,
                    (arrayType(T:Type, _) => pointerType(T))), _
               )) _:List
          )
          [structural] 
     // Incomplete array to pointer.
     rule bind-aux(_, _,
               ListItem(typedDeclaration(t(_,
                    (incompleteArrayType(T:Type) => pointerType(T))), _
               )) _:List
          )
          [structural] 
          
     rule <k> bind-aux(_, ListItem(tv(V:CValue, T':Type)) L:List, 
                    ListItem(typedDeclaration(T:Type, X:Id)) P:List)
               => allocateType(Loc, T)
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, T)
                    ~> Computation(allowWrite(X) := tv(V, T'))
                    ~> bind-aux(Loc, L, P)
          ...</k> 
          <next-loc> Loc:SymLoc => linc(Loc) </next-loc>
          <local-addresses>... .Set => SetItem(Loc) ...</local-addresses>
          when notBool isArrayType(T)
               andBool notBool isVoidType(T)
          [structural] 
          
     // TODO(chathhorn): consider adding back a check here, isTypeCompat no
     // longer makes sense in this context.
     // rule [bind-one-check-type]:
     //      (. => isTypeCompatible(T, T')) 
     //      ~> bind-aux(_, ListItem(tv(_:CValue, T':Type)) _:List, 
     //           ListItem(typedDeclaration(T:Type, _:Id)) _:List)
     //      [structural] 
     
     syntax List ::= promoteList(List) [function]
     rule promoteList(ListItem(tv(V:CValue, t(S:Set, T:K))) L:List) 
          => ListItem(cast(argPromote(t(S, T)), tv(V, t(S, T)))) 
               promoteList(L)
          when (T ==K float) 
               orElseBool (hasIntegerType(t(S:Set, T:K)) 
                    andBool ((rank(t(S, T)) <Int rank(t(.Set, int))) 
                         orElseBool isBitfieldType(t(S, T))))

     rule promoteList(ListItem(tv(V:CValue, t(S:Set, T:K))) L:List) 
          => ListItem(tv(V, t(S, T))) promoteList(L)
          when ((notBool(hasIntegerType(t(S, T))) 
                    andBool (notBool T ==K float)
                    andBool (notBool isArrayType(t(S, T)))) 
               orBool (T ==K double)
               orBool (T ==K long-double))
               orElseBool (rank(t(S, T)) >=Int rank(t(.Set, int)))

     rule promoteList(.List) => .List
     
     syntax K ::= bindVariadic(SymLoc, List)
     syntax K ::= "bindVariadic-pre" "(" SymLoc "," List ")"
     
     // the idea here is that there should have been a previous argument, so we
     // can use its address to append all of the variadic arguments 
     rule bind-aux(Loc:SymLoc, L:List, ListItem(variadic))
          => bindVariadic-pre(Loc, promoteList(L))
          [structural] 

     rule bindVariadic-pre(Loc:SymLoc, L:List)
          => bindVariadic(Loc, L)
          [structural]
     
     // fixme don't forget to get rid of append
     
     // this rule assumes it will be run immediately after other normal
     // bindings for the same function.  This is all wrong if it is
     // computational instead of structural because of other threads
     // interleaving
     rule <k> (. => allocateType(Loc, type(V))
                    ~> Computation(
                         allowWrite(*(tv(Loc, t(.Set, pointerType(type(V)))))) := V)
               )
               ~> bindVariadic(_, (ListItem(V:K) => .List) _:List) 
          ...</k>
          <next-loc> Loc:SymLoc => linc(Loc) </next-loc>
          <local-addresses>... .Set => SetItem(Loc) ...</local-addresses>
          [structural]
     
     rule bindVariadic(_, .List) => sequencePoint
          [structural]
endmodule

