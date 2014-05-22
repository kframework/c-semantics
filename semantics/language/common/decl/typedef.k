module C-DECL-TYPEDEF
     imports C-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX
               
     context Typedef(NameGroup(HOLE, _))

     rule Typedef(NameGroup(T:Type, list(ListItem(K:K) L:List))) 
          => defineType(SingleName(T, K)) ~> Typedef(NameGroup(T, list(L)))
          [structural]
     rule Typedef(NameGroup(_:Type, list(.List))) => .K
          [structural]

     syntax K ::= defineType(K) [strict] 

     rule defineType(typedDeclaration(T:Type, X:CId)) 
          => giveType(typedef(X), T) 
          [structural] 

endmodule
