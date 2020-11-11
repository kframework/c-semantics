module C-EXPR-CAST
     imports C-CONVERSION-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.4}{5--6}}}{
     Preceding an expression by a parenthesized type name converts the value of
     the expression to the named type. This construction is called a cast.  A
     cast that specifies no conversion has no effect on the type or value of an
     expression.

     If the value of the expression is represented with greater range or
     precision than required by the type named by the cast (6.3.1.8), then the
     cast specifies a conversion even if the type of the expression is the same
     as the named type and removes any extra range and precision.
     }*/
     rule (.K => DeclType(T, K)) ~> Cast(T:Type, K:KItem, V:RValue, _)
          [structural]
     rule T:Type ~> Cast(_, _, V:RValue, E::Bool) => Cast(elideDeclParams(T), V, E)
          [structural]

     // TODO: Figure out how this should work.
     rule cast(T'::UType, te(K:KItem, _), E::Bool) => te(Cast(type(T'), K, E), T')

endmodule

