module C-TYPE-BUILDER-SYNTAX
     imports INT-SYNTAX
     imports STRING-SYNTAX
     imports C-TYPING-SORTS
     syntax FlexType ::= Type | SimpleType
     syntax FlexParamDecl ::= FlexType | Variadic

     syntax Type ::= fun(FlexType) [function, klabel(fun1)]
                   | fun(FlexType, FlexParamDecl) [function, klabel(fun2)]
                   | fun(FlexType, FlexParamDecl, FlexParamDecl) [function, klabel(fun3)]
                   | fun(FlexType, FlexParamDecl, FlexParamDecl, FlexParamDecl) [function, klabel(fun4)]
                   | fun(FlexType, FlexParamDecl, FlexParamDecl, FlexParamDecl, FlexParamDecl) [function, klabel(fun5)]

     syntax Type ::= ptr(FlexType) [function]
     syntax Type ::= arr(FlexType, Int) [function]
     syntax Type ::= const(FlexType) [function]
     syntax Type ::= noreturn(FlexType) [function]
     syntax Type ::= restrict(FlexType) [function]
     syntax Type ::= volatile(FlexType) [function]
     syntax Type ::= typeref(String) [function]
     syntax Type ::= typdef(String) [function]
     syntax DType ::= decl(FlexType, String) [function]
     syntax List ::= field(FlexType, String) [function]

     syntax CId ::= id(String) [function]
endmodule

module C-TYPE-BUILDER
     imports C-CONFIGURATION
     imports COMMON-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX
     imports K-REFLECTION

     rule id(S::String) => Identifier(S)

     rule fun(R:FlexType)
          => fun(R, void)
     rule fun(R:FlexType, T:FlexParamDecl)
          => type(functionType(expandUT(R),
               ListItem(expandParam(T))))
     rule fun(R:FlexType, T:FlexParamDecl, T':FlexParamDecl)
          => type(functionType(expandUT(R),
               ListItem(expandParam(T))
               ListItem(expandParam(T'))))
     rule fun(R:FlexType, T:FlexType, T':FlexParamDecl, T'':FlexParamDecl)
          => type(functionType(expandUT(R),
               ListItem(expandParam(T))
               ListItem(expandParam(T'))
               ListItem(expandParam(T''))))
     rule fun(R:FlexType, T:FlexParamDecl, T':FlexParamDecl, T'':FlexParamDecl, T''':FlexParamDecl)
          => type(functionType(expandUT(R),
               ListItem(expandParam(T))
               ListItem(expandParam(T'))
               ListItem(expandParam(T''))
               ListItem(expandParam(T'''))))

     rule ptr(T:FlexType) => type(pointerType(expand(T)))

     rule arr(T:FlexType, N:Int) => type(arrayType(expand(T), N))

     rule const(T:FlexType) => addQualifier(Const(), expand(T))

     rule noreturn(T:FlexType) => addModifier(Noreturn(), expand(T))

     rule restrict(T:FlexType) => addQualifier(Restrict(), expand(T))

     rule volatile(T:FlexType) => addQualifier(Volatile(), expand(T))

     rule typeref(S:String) => #typeref(Identifier(S))

     syntax Type ::= #typeref(CId) [function, withConfig]
     rule [[ #typeref(X:CId) => T ]]
          <external-defs>... X |-> Base:SymBase ...</external-defs>
          <mem>... Base |-> object(T:Type, _, _) ...</mem> 

     rule decl(T:FlexType, S:String)
          => typedDeclaration(expand(T), Identifier(S))

     rule field(T:FlexType, S:String)
          => ListItem(decl(T, S))

     syntax Type ::= expand(FlexType) [function]
     rule expand(T:Type) => T
     rule expand(T:SimpleType) => type(T)

     syntax ParamDecl ::= expandParam(FlexParamDecl) [function]
     rule expandParam(T:FlexType) => expand(T)
     rule expandParam(V:Variadic) => V

     syntax UType ::= expandUT(FlexType) [function]
     rule expandUT(T:Type) => utype(T)
     rule expandUT(T:SimpleType) => utype(T)

endmodule
