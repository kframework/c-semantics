module C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX

     syntax FlexType ::= Type | SimpleType

     syntax Type ::= fun(FlexType) [function, klabel(fun1)]
                   | fun(FlexType, FlexType) [function, klabel(fun2)]
                   | fun(FlexType, FlexType, FlexType) [function, klabel(fun3)]
                   | fun(FlexType, FlexType, FlexType, FlexType) [function, klabel(fun4)]
                   | fun(FlexType, FlexType, FlexType, FlexType, FlexType) [function, klabel(fun5)]

     syntax Type ::= ptr(FlexType) [function]
     syntax Type ::= arr(FlexType, Int) [function]
     syntax Type ::= const(FlexType) [function]
     syntax Type ::= restrict(FlexType) [function]
     syntax Type ::= struct(String) [function]
     syntax Type ::= union(String) [function]
     syntax Type ::= decl(FlexType, String) [function]
     syntax List ::= field(FlexType, String) [function]

endmodule

module C-TYPE-BUILDER
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX

     rule fun(R:FlexType)
          => fun(R, void)
     rule fun(R:FlexType, T:FlexType)
          => t(.Set, functionType(expand(R),
               ListItem(expand(T))))
     rule fun(R:FlexType, T:FlexType, T':FlexType)
          => t(.Set, functionType(expand(R),
               ListItem(expand(T))
               ListItem(expand(T'))))
     rule fun(R:FlexType, T:FlexType, T':FlexType, T'':FlexType)
          => t(.Set, functionType(expand(R),
               ListItem(expand(T))
               ListItem(expand(T'))
               ListItem(expand(T''))))
     rule fun(R:FlexType, T:FlexType, T':FlexType, T'':FlexType, T''':FlexType)
          => t(.Set, functionType(expand(R),
               ListItem(expand(T))
               ListItem(expand(T'))
               ListItem(expand(T''))
               ListItem(expand(T'''))))

     rule ptr(T:FlexType) => t(.Set, pointerType(expand(T)))

     rule arr(T:FlexType, N:Int) => t(.Set, arrayType(expand(T), N))

     rule const(T:FlexType) => addQualifier(Const, expand(T))

     rule restrict(T:FlexType) => addQualifier(Restrict, expand(T))

     rule struct(S:String)
          => t(.Set, structType(global(Identifier(S), "builtin")))

     rule union(S:String)
          => t(.Set, unionType(global(Identifier(S), "builtin")))

     rule decl(T:FlexType, S:String)
          => typedDeclaration(expand(T), Identifier(S))

     rule field(T:FlexType, S:String)
          => ListItem(decl(T, S))

     syntax Type ::= expand(FlexType) [function]
     rule expand(T:Type) => T
     rule expand(T:SimpleType) => t(.Set, T)

endmodule
