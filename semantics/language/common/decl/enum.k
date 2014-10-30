module C-DECL-ENUM
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ERROR-SYNTAX
     imports COMPAT-SYNTAX

     syntax K ::= fillEnums(K)
     syntax K ::= "fillEnums-aux" "(" K "," K ")"

     rule EnumDef(X:CId, L:K) => fillEnums(EnumDef(X, L))
          [structural] 

     rule fillEnums(K:K) => fillEnums-aux(K, tv(0, t(.Set, int))) 
          [structural]

     rule fillEnums-aux(EnumDef(X:CId, list(ListItem(EnumItem(E:CId)) L:List)), K:K) 
          => declare(typedDeclaration(
               t(SetItem(Static) SetItem(Const), int), E),
               // Skip calculating the initializer so we can force int type.
               initializer(enumInit(E, K)))
          ~> fillEnums-aux(
               EnumDef(X, list(L)), K + tv(1, t(.Set, int)))
          [structural] 
     rule fillEnums-aux(EnumDef(X:CId, list(
               ListItem(EnumItemInit(E:CId, Exp:K)) L:List)), _)
          => declare(typedDeclaration(
               t(SetItem(Static) SetItem(Const), int), E),
               initializer(enumInit(E, Exp)))
          ~> fillEnums-aux(
               EnumDef(X, list(L)), Exp + tv(1, t(.Set, int)))
          when Exp =/=K NothingExpression
          [structural] 
     rule fillEnums-aux(EnumDef(_, list(.List)), _) => . 
          [structural] 

     syntax K ::= enumInit(CId, K) [strict(2)]
     rule enumInit(X:CId, V:RValue)
          => Computation(X := V)
          when hasIntegerType(type(V))
     rule (. => CV("CDE1", "Enum initializer not an integer constant expression.", "6.7.2.2:2"))
          ~> enumInit(_, tv(_, T:Type))
          when notBool hasIntegerType(T)

endmodule

