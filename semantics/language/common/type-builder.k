module C-TYPE-BUILDER-SYNTAX
     syntax FlexType ::= Type | SimpleType

     syntax Type ::= fun(FlexType) [function]
                   | fun(FlexType, FlexType) [function]
                   | fun(FlexType, FlexType, FlexType) [function]
                   | fun(FlexType, FlexType, FlexType, FlexType) [function]
                   | fun(FlexType, FlexType, FlexType, FlexType, FlexType) [function]

     syntax Type ::= ptr(FlexType) [function]
     syntax Type ::= arr(FlexType, Int) [function]
     syntax Type ::= const(FlexType) [function]
     syntax Type ::= restrict(FlexType) [function]
     syntax Type ::= struct(String, List) [function]
     syntax Type ::= union(String, List) [function]
     syntax Type ::= decl(FlexType, String) [function]
     syntax List ::= field(FlexType, String) [function]

     syntax List ::= adjustParams(List) [function]
endmodule

module C-TYPE-BUILDER
     imports C-TYPE-BUILDER-SYNTAX
     imports C-DECL-TAGGED-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX

     rule fun(R:FlexType)
          => fun(R, void)
     rule fun(R:FlexType, T:FlexType)
          => t(.Set, functionType(expand(R), adjustParams(
               ListItem(expand(T)))))
     rule fun(R:FlexType, T:FlexType, T':FlexType)
          => t(.Set, functionType(expand(R), adjustParams(
               ListItem(expand(T))
               ListItem(expand(T')))))
     rule fun(R:FlexType, T:FlexType, T':FlexType, T'':FlexType)
          => t(.Set, functionType(expand(R), adjustParams(
               ListItem(expand(T))
               ListItem(expand(T'))
               ListItem(expand(T'')))))
     rule fun(R:FlexType, T:FlexType, T':FlexType, T'':FlexType, T''':FlexType)
          => t(.Set, functionType(expand(R), adjustParams(
               ListItem(expand(T))
               ListItem(expand(T'))
               ListItem(expand(T''))
               ListItem(expand(T''')))))

     rule ptr(T:FlexType) => t(.Set, pointerType(expand(T)))

     rule arr(T:FlexType, N:Int) => t(.Set, arrayType(expand(T), N))

     rule const(T:FlexType) => addQualifier(Const, expand(T))

     rule restrict(T:FlexType) => addQualifier(Restrict, expand(T))

     rule struct(S:String, Decls:List)
          => t(.Set, structType(Identifier(S),
               bitSizeofStruct(makeStructFieldInfo(Decls)),
               makeStructFieldInfo(Decls)))

     rule union(S:String, Decls:List)
          => t(.Set, unionType(Identifier(S),
               bitSizeofUnion(makeUnionFieldInfo(Decls)),
               makeUnionFieldInfo(Decls)))

     rule decl(T:FlexType, S:String)
          => typedDeclaration(expand(T), Identifier(S))

     rule field(T:FlexType, S:String)
          => ListItem(decl(T, S))

     syntax Type ::= expand(FlexType) [function]
     rule expand(T:Type) => T
     rule expand(T:SimpleType) => t(.Set, T)

     rule adjustParams(ListItem(T:Type) Params:List)
          => ListItem(adjustParam(T)) adjustParams(Params)
     rule adjustParams(.List) => .List

     syntax Type ::= adjustParam(Type) [function]
     rule adjustParam(typedDeclaration(T:Type, X:CId))
          => typedDeclaration(adjustParam(T), X)
     rule adjustParam(t(Mods:Set, functionType(R:Type, Params:List)))
          => t(.Set, pointerType(t(Mods, functionType(R, adjustParams(Params)))))
     rule adjustParam(t(Mods:Set, arrayType(T:Type, _)))
          => t(Mods, pointerType(T))
     rule adjustParam(t(Mods:Set, incompleteArrayType(T:Type)))
          => t(Mods, pointerType(T))
     rule adjustParam(T:Type) => T
          when notBool isTypedDeclaration(T)
               andBool notBool isFunctionType(T)
               andBool notBool isArrayType(T)
endmodule
