module C-DECL-ENUM
     imports C-DECL-DEFINITION-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     syntax K ::= fillEnums(K)
     syntax K ::= "fillEnums-aux" "(" K "," K ")"

     rule EnumDef(X:Id, L:K) => fillEnums(EnumDef(X, L))
          [structural] 

     rule fillEnums(K:K) => fillEnums-aux(K, tv(0, t(.Set, int))) 
          [structural]

     rule fillEnums-aux(EnumDef(X:Id, list(ListItem(EnumItem(E:Id)) L:List)), K:K) 
          => declare(typedDeclaration(
               t(SetItem(Static) SetItem(Const), int), E),
               SingleInit(K))
          ~> fillEnums-aux(
               EnumDef(X, list(L)), K + tv(1, t(.Set, int)))
          [structural] 
     rule fillEnums-aux(EnumDef(X:Id, list(
               ListItem(EnumItemInit(E:Id, Exp:K)) L:List)), _)
          => declare(typedDeclaration(
               t(SetItem(Static) SetItem(Const), int), E),
               SingleInit(Exp))
          ~> fillEnums-aux(
               EnumDef(X, list(L)), Exp + tv(1, t(.Set, int)))
          when Exp =/=K NothingExpression
          [structural] 
     rule fillEnums-aux(EnumDef(_, list(.List)), _) => . 
          [structural] 

endmodule

