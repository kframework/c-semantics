module C-DECLARATION-ENUM
     imports C-SYNTAX
     imports C-SEMANTIC-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX

     syntax K ::= "fillEnums" "(" K ")"
     syntax K ::= "fillEnums-aux" "(" K "," K ")"
     rule EnumDef(X:Id, L:K) => fillEnums(EnumDef(X, L))
          [structural] 
     rule fillEnums(K:K) => fillEnums-aux(K, tv(0, t(.Set, int))) 
          [structural]
     rule fillEnums-aux(EnumDef(X:Id, klist((EnumItem(E:Id),, L:KList))), K:K) 
          => doDeclare(typedDeclaration(t(.Set, int), E), SingleInit(K))
               ~> fillEnums-aux(EnumDef(X, klist(L)), 
               K + tv(1, t(.Set, int)))
          [structural] 
     rule fillEnums-aux(EnumDef(X:Id, klist((
               EnumItemInit(E:Id, Exp:K),, L:KList))), _)
          => doDeclare(typedDeclaration(t(.Set, int), E), SingleInit(Exp))
               ~> fillEnums-aux(EnumDef(X, klist(L)), 
               Exp + tv(1, t(.Set, int)))
          when Exp =/=K NothingExpression
          [structural] 
     rule fillEnums-aux(EnumDef(_:Id, klist(.KList)), _) => . 
          [structural] 
endmodule

