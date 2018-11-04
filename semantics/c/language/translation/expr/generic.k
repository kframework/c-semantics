module C-EXPR-GENERIC
     imports LIST
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports COMPAT-SYNTAX
     imports C-TYPING-EXPR-SYNTAX
     imports C-TYPING-SYNTAX

     rule (.K => typeof(E)) ~> Generic(E:K, _)
     rule typeof(T:Type) ~> Generic(_, list(Assocs::List))
          => evalGeneric(T, Assocs, .List, .K)

     syntax KItem ::= evalGeneric(Type, List, List, K)
     rule (.K => DeclType(T', X))
          ~> evalGeneric(_, ListItem(GenericPair(T':K, X:K, _)) _, _, _)
     rule (T':Type => .K) ~> evalGeneric(T::Type, (ListItem(K:KItem) => .List) _, _::List (.List => ListItem(K)), _)
          requires T ==Type T'
     rule (T':Type => .K) ~> evalGeneric(T::Type, (ListItem(_) => .List) _, _, _)
          requires T =/=Type T'
     rule evalGeneric(_, (ListItem(GenericDefault(E:K)) => .List) _, _, .K => GenericDefault(E))

     rule evalGeneric(_, .List, ListItem(GenericPair(_, _, E:K)), _) => E
     rule evalGeneric(_, .List, .List, GenericDefault(E:K)) => E

     rule (.K => CV("TEG1", "Generic selection with a controlling expression compatible with multiple types in the association list."))
          ~> evalGeneric(_, .List, ListItem(_) ListItem(_) _::List, _)
     rule (.K => CV("TEG2", "Generic selection with a controlling expression not compatible with any type in the association list (with no default)."))
          ~> evalGeneric(_, .List, .List, .K)
     rule (.K => CV("TEG3", "Generic selection with multiple defaults."))
          ~> evalGeneric(_, ListItem(GenericDefault(_)) _::List, _, GenericDefault(_))

endmodule

