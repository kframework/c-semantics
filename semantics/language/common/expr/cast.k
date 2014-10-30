module C-COMMON-EXPR-CAST
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX

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
     rule Cast(T:Type, K:K, V:K) => Cast(DeclType(T, K), V)
          [structural]

     rule Cast(T:Type, V:RValue) => cast(elideDeclParams(T), V)
          [structural]

endmodule

