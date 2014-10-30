module C-BINDING-SYNTAX
     // RValues, Types, CIds
     syntax K ::= bind(List, List, List)
     syntax K ::= bindParam(CId, Type, K)
     syntax K ::= bindParam(CId)
     syntax Type ::= argPromoteType(Type) [function]
     syntax Bool ::= areArgPromoted(List) [function]
endmodule

module C-BINDING
     imports C-BINDING-SYNTAX

     imports C-CONVERSION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     // Construct the function parameters. Takes three lists: (1) the formal
     // parameters (ids and types) from the function definition, (2) the
     // prototype from the function definition, if any (as a list of parameter
     // types), and (3) the actual, evaluated arguments being passed during
     // this call. If the second list is empty, then the parameters need to be
     // promoted. If the first list is empty, then we're dealing with a
     // builtin, so we need to make up identifiers.

     // Prototype.
     rule (. => bindParam(X, T, V))
          ~> bind(
               (ListItem(typedDeclaration(_, X:CId)) => .List) _,
               (ListItem(T:Type) => .List) _,
               (ListItem(V:RValue) => .List) _)
          [structural]
     // No prototype -- but the args must still have ids/types in the def.
     rule (. => bindParam(X, T, argPromote(V)))
          ~> bind(
               (ListItem(typedDeclaration(T:Type, X:CId)) => .List) _,
               .List,
               (ListItem(V:RValue) => .List) _)
          when #arePromotedTypesCompat(value(V), T, type(V)) ==K true
          [structural]
     rule (. => ERROR("B1", "types of function call arguments aren't "
               +String "compatible with declared types after promotions."))
          ~> bind(
               ListItem(typedDeclaration(T:Type, _)) _,
               .List,
               ListItem(V:RValue) _)
          when #arePromotedTypesCompat(value(V), T, type(V)) =/=K true
          [structural]
     // Variadic.
     rule bind(ListItem(variadic), ListItem(variadic), Vs:List)
          => bindVariadics(Vs, 0)
          [structural]
     // No params.
     rule bind(ListItem(typedDeclaration(t(_, void), _)),
               ListItem(t(_, void)),
               .List)
          => .
          [structural]
     // Builtins -- they have a prototype but no def.
     rule <k> (. => bindParam(unnamed(N, Tu), T, V))
          ~> bind(
               .List,
               (ListItem(T:Type) => .List) _,
               (ListItem(V:RValue) => .List) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          when T =/=K variadic
          [structural]
     // Builtins, variadic.
     rule bind(.List, ListItem(variadic), Vs:List)
          => bindVariadics(Vs, 0)
          [structural]
     // Builtins, no params.
     rule bind(.List, ListItem(t(_, void)), _) => .
          [structural]
     rule bind(.List, .List, .List) => .
          [structural]

     syntax K ::= bindVariadics(List, Int)
     rule (. => bindParam(vararg(N), type(argPromote(V)), argPromote(V)))
          ~> bindVariadics(
               (ListItem(V:RValue) => .List) _,
               (N:Int => N +Int 1))
          [structural]
     // Make one past the last variadic a legal address.
     rule bindVariadics(.List, N:Int) => bindParam(vararg(N))
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

     syntax Bool ::= "#arePromotedTypesCompat" "(" CValue "," Type "," Type ")"
          [function]

     rule #arePromotedTypesCompat(_, T:Type, T':Type) => true
          when areCompatible(argPromoteType(T), argPromoteType(T'))

     rule #arePromotedTypesCompat(V:Int, T:Type, T':Type) => true
          when (argPromoteType(T)
                    ==K correspondingUnsignedType(argPromoteType(T')))
               andBool representable(V, argPromoteType(T))
               andBool representable(V,
                    correspondingUnsignedType(argPromoteType(T')))
     rule #arePromotedTypesCompat(V:Int, T:Type, T':Type) => true
          when (argPromoteType(T')
                    ==K correspondingUnsignedType(argPromoteType(T)))
               andBool representable(V, argPromoteType(T'))
               andBool representable(V,
                    correspondingUnsignedType(argPromoteType(T)))
     rule #arePromotedTypesCompat(_, T:Type, T':Type) => true
          when isPointerType(T) andBool isPointerType(T')
               andBool (hasCharType(innerType(argPromoteType(T)))
                    orBool isVoidType(innerType(argPromoteType(T))))
               andBool (hasCharType(innerType(argPromoteType(T')))
                    orBool isVoidType(innerType(argPromoteType(T'))))

     syntax Bool ::= representable(Int, Type)  [function]
     rule representable(V:Int, T:Type)
          => (V <=Int max(T)) andBool (V >=Int min(T))

     syntax RValue ::= argPromote(K) [function]
     rule argPromote(tv(V:CValue, T:Type))
          => cast(argPromoteType(T), tv(V, T))

     // "integer promotions" are used when doing arithmetic conversions, and
     // for unary ~, +, - "usual arithmetic conversions" are used when doing
     // binary arithmetic on numbers, and are used to find a common type there
     // is another set of promotions called "default argument promotions" used
     // when calling functions where the type information is not complete. This
     // is equivalent to integer promotions + (float => double)
     rule argPromoteType(t(Mods:Set, float))
          => t(Mods, double)
     rule argPromoteType(t(Mods:Set, double))
          => t(Mods, double)
     rule argPromoteType(t(Mods:Set, long-double))
          => t(Mods, long-double)
     rule argPromoteType(T:Type)
          => promote(T)
          when hasIntegerType(T)
     rule argPromoteType(T:Type) => T
          when notBool hasIntegerType(T)
               andBool notBool hasFloatType(T)

     // "are argument-promoted".
     rule areArgPromoted(L:List) => all(L, 'isArgPromoted) ==K true

     syntax Bool ::= isArgPromoted(Type) [function]
     rule isArgPromoted(T:Type) => areCompatible(T, argPromoteType(T))

endmodule

