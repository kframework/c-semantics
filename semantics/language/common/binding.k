module C-BINDING-SYNTAX
     // TypedValues, Types, Ids
     syntax K ::= bind(List, List, List)
     syntax K ::= bindParam(Id, Type, TypedValue)
endmodule

module C-BINDING
     imports C-BINDING-SYNTAX

     imports C-CONVERSION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

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
     
     syntax TypedValue ::= argPromote(TypedValue) [function]
     rule argPromote(tv(V:CValue, t(Mods:Set, T:SimpleType))) 
          => cast(argPromoteType(t(Mods, T)), tv(V, t(Mods, T)))
          when (T ==K float) 
               orElseBool (hasIntegerType(t(Mods, T)) 
                    andBool ((rank(t(Mods, T)) <Int rank(t(.Set, int))) 
                         orElseBool isBitfieldType(t(Mods, T))))
     rule argPromote(tv(V:CValue, t(Mods:Set, T:SimpleType)))
          => tv(V, t(Mods, T))
          when ((notBool(hasIntegerType(t(Mods, T))) 
                    andBool (notBool T ==K float)
                    andBool (notBool isArrayType(t(Mods, T)))) 
               orBool (T ==K double)
               orBool (T ==K long-double))
               orElseBool (rank(t(Mods, T)) >=Int rank(t(.Set, int)))

     // "integer promotions" are used when doing arithmetic conversions, and
     // for unary ~, +, - "usual arithmetic conversions" are used when doing
     // binary arithmetic on numbers, and are used to find a common type there
     // is another set of promotions called "default argument promotions" used
     // when calling functions where the type information is not complete. This
     // is equivalent to integer promotions + (float => double) 
     syntax Type ::= argPromoteType(Type) [function]
     rule argPromoteType(t(_, float))
          => t(.Set, double)
     rule argPromoteType(t(_, double))
          => t(.Set, double)
     rule argPromoteType(t(_, long-double))
          => t(.Set, long-double)
     rule argPromoteType(T:Type)
          => promote(T)
          when hasIntegerType(T)
     
     // Construct the function parameters. Takes three lists: the actual
     // (evaluated) parameters, the formal parameters as found in the function
     // type, and the list of identifiers from the function definition. If the
     // second list is empty, then the parameters need to be promoted because
     // we don't have a prototype. If the third list is empty, then we're
     // dealing with a builtin, so we need to make up identifiers.

     // Prototype.
     rule (. => bindParam(X, T, V))
          ~> bind(
               (ListItem(X:Id) => .List) _,
               (ListItem(T:Type) => .List) _,
               (ListItem(V:TypedValue) => .List) _)
     // No prototype. TODO(chathhorn): identifier lists.
     rule (. => bindParam(X, type(argPromote(V)), argPromote(V)))
          ~> bind(
               (ListItem(X:Id) => .List) _,
               .List,
               (ListItem(V:TypedValue) => .List) _)
     // Builtins.
     rule <k> (. => bindParam(unnamed(N, Tu), T, V))
          ~> bind(
               .List,
               (ListItem(T:Type) => .List) _,
               (ListItem(V:TypedValue) => .List) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
     // Variadic.
     rule bind(.List, ListItem(variadic), Vs:List)
          => bindVariadics(Vs, 0)
     rule bind(.List, ListItem(t(_, void)), .List) => .
     rule bind(.List, .List, .List) => .

     syntax K ::= bindVariadics(List, Int)
     rule (. => bindParam(vararg(N), type(argPromote(V)), argPromote(V)))
          ~> bindVariadics(
               (ListItem(V:TypedValue) => .List) _,
               (N:Int => N +Int 1))
     rule bindVariadics(.List, _) => .

endmodule

