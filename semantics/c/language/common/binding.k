module C-BINDING-SYNTAX
     imports LIST
     imports C-TYPING-SORTS
     imports COMMON-SORTS

     // RValues, Types, CIds
     syntax KItem ::= bind(List, List, List)
     syntax KItem ::= bindParam(CId, Type, KItem) [strict(3), klabel(bindParam3)]
endmodule

module C-BINDING
     imports C-BINDING-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports STRING
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-TYPING-SYNTAX

     // Construct the function parameters. Takes three lists: (1) the formal
     // parameters (ids and types) from the function definition, (2) the
     // prototype for the function, if any (as a list of parameter types), and
     // (3) the actual, evaluated arguments being passed during this call. If
     // the second list is empty, then the parameters need to be promoted. If
     // the first list doesn't have ids, then we're dealing with a builtin, so
     // we need to make up identifiers.

     // Prototype.
     rule (.K => bindParam(X, T, V))
          ~> bind(
               (ListItem(typedDeclaration(T::Type, X:CId)) => .List) _,
               (ListItem(_) => .List) _,
               (ListItem(V:RValue) => .List) _)
          requires notBool isVoidType(T)
          [structural]
     rule bind(ListItem(typedDeclaration(t(... st: void), _)),
               ListItem(t(... st: void)), .List) => .K
          [structural]
     rule bind(ListItem(typedDeclaration(t(... st: void), _)),
               ListItem(typedDeclaration(t(... st: void), _)), .List) => .K
          [structural]
     // No prototype -- but the args must still have ids/types in the def.
     rule (.K => bindParam(X, T, argPromote(V)))
          ~> bind(
               (ListItem(typedDeclaration(T::Type, X:CId)) => .List) _,
               .List,
               (ListItem(V:RValue) => .List) _)
          requires #arePromotedTypesCompat({value(V)}:>CValue, utype(T), utype(V))
          [structural]
     rule (.K => UNDEF("CB1", "Types of function call arguments aren't "
               +String "compatible with declared types after promotions."))
          ~> bind(
               ListItem(typedDeclaration(T::Type, _)) _,
               .List,
               ListItem(V:RValue) _)
          requires notBool #arePromotedTypesCompat({value(V)}:>CValue, utype(T), utype(V))
               andBool notBool isVoidType(T)
          [structural]
     rule (.K => UNDEF("CB2", "Function call has fewer arguments than "
               +String "parameters in function definition."))
          ~> bind(
               ListItem(typedDeclaration(T::Type, _)) _,
               _,
               .List)
          requires notBool isVoidType(T)
     rule (.K => UNDEF("CB2", "Function call has fewer arguments than "
               +String "parameters in function definition."))
          ~> bind(
               ListItem(T:Type) _,
               _,
               .List)
          requires notBool isVoidType(T)
     rule (.K => UNDEF("CB3", "Function call has more arguments than "
               +String "parameters in function definition."))
          ~> bind(.List, _, ListItem(_) _)
     rule (.K => UNDEF("CB4", "Function defined with no parameters "
               +String "called with arguments."))
          ~> bind(ListItem(typedDeclaration(t(... st: void) #as T::Type, _)), _, ListItem(_) _)
     // Variadic.
     rule bind(ListItem(variadic), ListItem(variadic), Vs:List)
          => bindVariadics(Vs, 0)
          [structural]
     // No params.
     rule bind(ListItem(t(... st: void)), .List, .List) => .K
          [structural]
     rule bind(ListItem(typedDeclaration(t(... st: void) #as T::Type, _)),
               .List, .List) => .K
          [structural]
     // Builtins -- they don't have named parameters.
     rule <k> (.K => bindParam(unnamed(N, Tu), T, V))
          ~> bind(
               (ListItem(T:Type) => .List) _,
               (ListItem(_) => .List) _,
               (ListItem(V:RValue) => .List) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          requires T =/=K variadic
          [structural]
     rule <k> (.K => bindParam(unnamed(N, Tu), T, V))
          ~> bind(
               (ListItem(T:Type) => .List) _,
               .List,
               (ListItem(V:RValue) => .List) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          requires T =/=K variadic
          [structural]
     rule bind(ListItem(t(... st: void) #as T::Type),
               ListItem(t(... st: void) #as T'::Type), .List) => .K
          [structural]
     rule bind(.List, .List, .List) => .K
          [structural]

     syntax KItem ::= bindVariadics(List, Int)
     rule (.K => bindParam(vararg(N), stripConstants(type(argPromoteType(utype(V)))), argPromote(V)))
          ~> bindVariadics(
               (ListItem(V:RValue) => .List) _,
               (N:Int => N +Int 1))
          [structural]
     rule bindVariadics(.List, _) => .K
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
     syntax Bool ::= #arePromotedTypesCompat(CValue, UType, UType)
          [function]

     rule #arePromotedTypesCompat(_, T::UType, T'::UType) => true
          requires type(argPromoteType(T)) ==Type type(argPromoteType(T'))

     rule #arePromotedTypesCompat(V:Int, T::UType, signedIntegerUType #as T'::UType) => true
          requires (argPromoteType(T)
                    ==K correspondingUnsignedType(argPromoteType(T')))
               andBool intInRange(V, argPromoteType(T))
               andBool intInRange(V,
                    correspondingUnsignedType(argPromoteType(T')))
     rule #arePromotedTypesCompat(V:Int, signedIntegerUType #as T::UType, T'::UType) => true
          requires (argPromoteType(T') ==K correspondingUnsignedType(argPromoteType(T)))
               andBool intInRange(V, argPromoteType(T'))
               andBool intInRange(V,
                    correspondingUnsignedType(argPromoteType(T)))
     rule #arePromotedTypesCompat(_, ut(... st: pointerType(_)) #as T::UType, ut(... st: pointerType(_)) #as T'::UType) => true
          requires (isCharType(innerType(argPromoteType(T)))
                    orBool isVoidType(innerType(argPromoteType(T))))
               andBool (isCharType(innerType(argPromoteType(T')))
                    orBool isVoidType(innerType(argPromoteType(T'))))
     rule #arePromotedTypesCompat(_, _, _) => false [owise]

     syntax KItem ::= argPromote(RValue) [function]
     rule argPromote(V::RValue) => cast(argPromoteType(utype(V)), V)

endmodule

