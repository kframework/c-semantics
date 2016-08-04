module C-TYPE-BUILDER-SYNTAX
     imports INT-SYNTAX
     imports STRING-SYNTAX
     imports C-TYPING-SORTS
     syntax FlexType ::= Type | SimpleType | Variadic

     syntax Type ::= fun(FlexType) [function, klabel(fun1)]
                   | fun(FlexType, FlexType) [function, klabel(fun2)]
                   | fun(FlexType, FlexType, FlexType) [function, klabel(fun3)]
                   | fun(FlexType, FlexType, FlexType, FlexType) [function, klabel(fun4)]
                   | fun(FlexType, FlexType, FlexType, FlexType, FlexType) [function, klabel(fun5)]

     syntax Type ::= ptr(FlexType) [function]
     syntax Type ::= arr(FlexType, Int) [function]
     syntax Type ::= const(FlexType) [function]
     syntax Type ::= noreturn(FlexType) [function]
     syntax Type ::= restrict(FlexType) [function]
     syntax Type ::= struct(String) [function]
     syntax Type ::= union(String) [function]
     syntax Type ::= typdef(String) [function]
     syntax DType ::= decl(FlexType, String) [function]
     syntax List ::= field(FlexType, String) [function]

     syntax Type ::= "size_t" [function]
endmodule

module C-TYPE-BUILDER
     imports C-CONFIGURATION
     imports COMMON-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX
     imports K-REFLECTION

     rule fun(R:FlexType)
          => fun(R, void)
     rule fun(R:FlexType, T:FlexType)
          => type(functionType(expandut(R),
               ListItem(expand(T))))
     rule fun(R:FlexType, T:FlexType, T':FlexType)
          => type(functionType(expandut(R),
               ListItem(expand(T))
               ListItem(expand(T'))))
     rule fun(R:FlexType, T:FlexType, T':FlexType, T'':FlexType)
          => type(functionType(expandut(R),
               ListItem(expand(T))
               ListItem(expand(T'))
               ListItem(expand(T''))))
     rule fun(R:FlexType, T:FlexType, T':FlexType, T'':FlexType, T''':FlexType)
          => type(functionType(expandut(R),
               ListItem(expand(T))
               ListItem(expand(T'))
               ListItem(expand(T''))
               ListItem(expand(T'''))))

     rule ptr(T:FlexType) => type(pointerType(expand(T)))

     rule arr(T:FlexType, N:Int) => type(arrayType(expand(T), N))

     rule const(T:FlexType) => addQualifier(Const(), expand(T))

     rule noreturn(T:FlexType) => addModifier(Noreturn(), expand(T))

     rule restrict(T:FlexType) => addQualifier(Restrict(), expand(T))

     rule struct(S:String) => #struct(Identifier(S), #configuration)
     rule union(S:String) => #struct(Identifier(S), #configuration)
     syntax Type ::= #struct(CId, K) [function]

     rule #struct(X:CId, <generatedTop>... <external-defs>... X |-> Base:SymBase ...</external-defs> <mem>... Base |-> object(T:Type, _, _) ...</mem> ...</generatedTop>) => T

     rule decl(T:FlexType, S:String)
          => typedDeclaration(expand(T), Identifier(S))

     rule field(T:FlexType, S:String)
          => ListItem(decl(T, S))

     syntax Type ::= expand(FlexType) [function]
     rule expand(T:Type) => T
     rule expand(T:Variadic) => T
     rule expand(T:SimpleType) => type(T)

     syntax UType ::= expandut(FlexType) [function]
     rule expandut(T:Type) => utype(T)
     rule expandut(T:SimpleType) => utype(T)

     rule size_t => expand(cfg:sizeut)

endmodule
