module C-DECL-TAGGED-SYNTAX
     // Not defined, just used.
     syntax K ::= addGlobalTag(CId, FieldInfo)
     syntax K ::= addLocalTag(CId, FieldInfo)

     syntax FieldInfo ::= makeStructFieldInfo(List) [function]
     syntax FieldInfo ::= makeUnionFieldInfo(List) [function]
endmodule

module C-DECL-TAGGED
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-TAGGED-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     // TODO(chathhorn): handle global/local differently.
     // note that struct defs might appear buried in a type.
     rule StructDef(X:CId, krlist(L:List))
          => addTag(X, makeStructFieldInfo(L))
          when L =/=List .List
          [structural]
     rule (. => UNDEF("CDT1", "structs cannot be empty.", "6.7.2.1") )
          ~> StructDef(_, krlist(.List))
          [structural]
     rule UnionDef(X:CId, krlist(L:List))
          => addTag(X, makeUnionFieldInfo(L))
          when L =/=List .List
          [structural]
     rule (. => UNDEF("CDT2", "unions cannot be empty.", "6.7.2.1") )
          ~> UnionDef(_, krlist(.List))
          [structural]

     rule makeStructFieldInfo(L:List) 
          => makeStructFieldInfo'(
               incompleteToFlexibleArrayMember(L),
               0, .Map, .Map,
               incompleteToFlexibleArrayMember(L))
          when L =/=List .List

     syntax FieldInfo ::= "makeStructFieldInfo'" "(" List "," Int "," Map ","  Map "," List ")"
                         [function]
     rule makeStructFieldInfo'(
               ListItem(typedDeclaration(T:Type, Field:CId)) L:List
               , V:Int
               , Types:Map
               , Offsets:Map
               , L':List
          )
          => makeStructFieldInfo'(L, V +Int byteSizeofType(T),
               Types[T <- Field], Offsets[V <- Field], L')
     rule makeStructFieldInfo'(.List, _, Types:Map, Offsets:Map, L:List) 
          => fieldInfo(L, Types, Offsets)

     // FIXME: chould check for some struct contraints here.
     syntax List ::= incompleteToFlexibleArrayMember(List) [function]
     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(T:Type, X:CId)) 
          L:List)
          => ListItem(typedDeclaration(T, X)) incompleteToFlexibleArrayMember(L)
          when isCompleteType(T)
     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(t(Mods:Set, incompleteArrayType(T:Type)), X:CId)))
          => ListItem(typedDeclaration(t(Mods, flexibleArrayType(T)), X))
     rule incompleteToFlexibleArrayMember(.List) => .List

     rule makeUnionFieldInfo(L:List) => makeUnionFieldInfo'(L, .Map, .Map, L)
          when L =/=List .List

     syntax FieldInfo ::= "makeUnionFieldInfo'" "(" List "," Map ","  Map "," List ")"
                         [function]
     rule makeUnionFieldInfo'(
               ListItem(typedDeclaration(T:Type, Field:CId)) L:List
               , Types:Map
               , Offsets:Map
               , L':List
          )
          => makeUnionFieldInfo'(L,
               Types[T <- Field], Offsets[0 <- Field], L')
     rule makeUnionFieldInfo'(.List, Types:Map, Offsets:Map, L:List) 
          => fieldInfo(L, Types, Offsets)

     syntax K ::= addTag(CId, FieldInfo)
     rule <k> addTag(S:CId, fieldInfo(Fs:List, Ts:Map, Offs:Map))
               // Elide function parameter names in struct types.
               => addGlobalTag(S, fieldInfo(elideList(Fs), elideMap(Ts), Offs))
          ...</k>
          <curr-function> file-scope </curr-function>
          [structural]
     rule <k> addTag(S:CId, fieldInfo(Fs:List, Ts:Map, Offs:Map))
               => addLocalTag(S, fieldInfo(elideList(Fs), elideMap(Ts), Offs))
          ...</k>
          <curr-function> F:CId </curr-function>
          when F =/=K file-scope
          [structural]

endmodule

