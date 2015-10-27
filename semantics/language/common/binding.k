module C-BINDING-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     // RValues, Types, CIds
     syntax KItem ::= bind(List, List, List)
     syntax KItem ::= bindParam(CId, Type, K)
     syntax KItem ::= bindParam(CId)
     syntax Type ::= argPromoteType(Type) [function]
     syntax Bool ::= areArgPromoted(List) [function]
endmodule

module C-BINDING
     imports C-BINDING-SYNTAX

     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports C-CONFIGURATION

     // Construct the function parameters. Takes three lists: (1) the formal
     // parameters (ids and types) from the function definition, (2) the
     // prototype from the function definition, if any (as a list of parameter
     // types), and (3) the actual, evaluated arguments being passed during
     // this call. If the second list is empty, then the parameters need to be
     // promoted. If the first list is empty, then we're dealing with a
     // builtin, so we need to make up identifiers.

     // Prototype.
     rule (.K => bindParam(X, T, V))
          ~> bind(
               (ListItem(typedDeclaration(_, X:CId)) => .List) _,
               (ListItem(T:Type) => .List) _,
               (ListItem(V:RValue) => .List) _)
          [structural]
     // No prototype -- but the args must still have ids/types in the def.
     rule (.K => bindParam(X, T, argPromote(V)))
          ~> bind(
               (ListItem(typedDeclaration(T:Type, X:CId)) => .List) _,
               .List,
               (ListItem(V:RValue) => .List) _)
          requires #arePromotedTypesCompat(value(V):>CValue, T, type(V))
          [structural]
     rule (.K => UNDEF("CB1", "types of function call arguments aren't "
               +String "compatible with declared types after promotions.", "6.5.2.2:6, J.2:1 item 39"))
          ~> bind(
               ListItem(typedDeclaration(T:Type, _)) _,
               .List,
               ListItem(V:RValue) _)
          requires notBool #arePromotedTypesCompat(value(V):>CValue, T, type(V))
          [structural]
     rule (_:ErrorExit => bindParam(X, T, argPromote(V))) ~> bind(
               (ListItem(typedDeclaration(T:Type, X:CId)) => .List) _,
               .List,
               (ListItem(V:RValue) => .List) _)
          requires isErrorRecovery
     rule (.K => UNDEF("CB2", "function call has fewer arguments than "
               +String "parameters in function definition.", "6.5.2.2:6, J.2:1 item 38"))
          ~> bind(
               ListItem(typedDeclaration(T:Type, _)) _,
               ListItem(T':Type) _,
               .List)
          requires notBool (isVoidType(T) andBool isVoidType(T'))
     rule (_:ErrorExit => .K) ~> bind(
               (ListItem(typedDeclaration(T:Type, _)) => .List) _,
               (ListItem(T':Type) => .List) _,
               .List)
          requires isErrorRecovery
     rule (.K => UNDEF("CB3", "function call has more arguments than "
               +String "parameters in function definition.", "6.5.2.2:6, J.2:1 item 38"))
          ~> bind(.List, .List, ListItem(_) _)
     rule (_:ErrorExit => .K) ~> bind(.List, .List, (ListItem(_) => .List) _)
          requires isErrorRecovery
     // Variadic.
     rule bind(ListItem(variadic), ListItem(variadic), Vs:List)
          => bindVariadics(Vs, 0)
          [structural]
     // No params.
     rule bind(ListItem(typedDeclaration(t(_, void), _)),
               ListItem(t(_, void)),
               .List)
          => .K
          [structural]
     // Builtins -- they have a prototype but no def.
     rule <k> (.K => bindParam(unnamed(N, Tu), T, V))
          ~> bind(
               .List,
               (ListItem(T:Type) => .List) _,
               (ListItem(V:RValue) => .List) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          requires T =/=K variadic
          [structural]
     // Builtins, variadic.
     rule bind(.List, ListItem(variadic), Vs:List)
          => bindVariadics(Vs, 0)
          [structural]
     // Builtins, no params.
     rule bind(.List, ListItem(t(_, void)), _) => .K
          [structural]
     rule bind(.List, .List, .List) => .K
          [structural]

     syntax KItem ::= bindVariadics(List, Int)
     rule (.K => bindParam(vararg(N), stripConstants(type(argPromote(V))), argPromote(V)))
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
     syntax Bool ::= #arePromotedTypesCompat(CValue, Type, Type)
          [function]

     rule #arePromotedTypesCompat(_, T:Type, T':Type) => true
          requires areCompatible(argPromoteType(T), argPromoteType(T'))

     rule #arePromotedTypesCompat(V:Int, T:Type, T':SignedIntegerType) => true
          requires (argPromoteType(T)
                    ==K correspondingUnsignedType(argPromoteType(T')))
               andBool representable(V, argPromoteType(T))
               andBool representable(V,
                    correspondingUnsignedType(argPromoteType(T')))
     rule #arePromotedTypesCompat(V:Int, T:SignedIntegerType, T':Type) => true
          requires (argPromoteType(T')
                    ==K correspondingUnsignedType(argPromoteType(T)))
               andBool representable(V, argPromoteType(T'))
               andBool representable(V,
                    correspondingUnsignedType(argPromoteType(T)))
     rule #arePromotedTypesCompat(_, T:PointerType, T':PointerType) => true
          requires (isCharType(innerType(argPromoteType(T)))
                    orBool isVoidType(innerType(argPromoteType(T))))
               andBool (isCharType(innerType(argPromoteType(T')))
                    orBool isVoidType(innerType(argPromoteType(T'))))
     rule #arePromotedTypesCompat(_, _, _) => false [owise]

     syntax Bool ::= representable(Int, Type)  [function]
     rule representable(V:Int, T:Type)
          => (V <=Int max(T)) andBool (V >=Int min(T))

     syntax RValue ::= argPromote(K) [function]
     rule argPromote(V:RValue) => cast(argPromoteType(type(V)), V)

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
     rule argPromoteType(T:IntegerType)
          => promote(T)
     rule argPromoteType(T:Type) => T [owise]

     // "are argument-promoted".
     rule areArgPromoted(L:List) => true
          requires all(L, #klabel(`isArgPromoted`))
     rule areArgPromoted(_) => false [owise]

     syntax Bool ::= isArgPromoted(Type) [function]
     rule isArgPromoted(T:Type) => areCompatible(T, argPromoteType(T))

endmodule

