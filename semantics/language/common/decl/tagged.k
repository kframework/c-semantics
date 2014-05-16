module C-DECL-TAGGED-SYNTAX
     // Not defined, just used.
     syntax K ::= addGlobalTag(Id, FieldInfo)

     syntax FieldInfo ::= makeStructFieldInfo(List) [function]
     syntax FieldInfo ::= makeUnionFieldInfo(List) [function]
endmodule

module C-DECL-TAGGED
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-TAGGED-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     // TODO(chathhorn): handle global/local differently.
     // note that struct defs might appear buried in a type.
     rule StructDef(X:Id, krlist(L:List))
          => structDef'(X, makeStructFieldInfo(L))
          when L =/=List .List
          [structural]
     rule UnionDef(X:Id, krlist(L:List))
          => unionDef'(X, makeUnionFieldInfo(L))
          when L =/=List .List
          [structural]

     // FIXME: chould check for some struct contraints here.
     syntax List ::= incompleteToFlexibleArrayMember(List) [function]

     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(T:Type, X:Id)) 
          L:List)
          => ListItem(typedDeclaration(T, X)) incompleteToFlexibleArrayMember(L)
          when isCompleteType(T)
     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(t(S:Set, incompleteArrayType(T:Type)), X:Id)))
          => ListItem(typedDeclaration(t(S, flexibleArrayType(T)), X))
     rule incompleteToFlexibleArrayMember(.List) => .List

     syntax List ::= fillBitHoles(List) [function]
     syntax List ::=  fillBitHoles(Int, List) [function]
     rule fillBitHoles(.List) => .List 
     // if we haven't seen bitfields
     rule fillBitHoles(ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => ListItem(typedDeclaration(T, X)) fillBitHoles(L)
          when notBool isBitfieldType(T) 
     
     rule fillBitHoles(ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => fillBitHoles(0, ListItem(typedDeclaration(T, X)) L)
          when isBitfieldType(T) 
     
     // if we have seen bitfields
     rule fillBitHoles(N:Int, 
               ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
                    absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte)) 
                    %Int cfg:bitsPerByte)), #NoName))
               fillBitHoles(ListItem(typedDeclaration(T, X)) L)
          when notBool isBitfieldType(T) 
     
     rule fillBitHoles(N:Int, 
               ListItem(typedDeclaration(t(S:Set,
                    bitfieldType(T:Type, N':Int)), X:Id))
               L:List) 
          => ListItem(typedDeclaration(t(S, bitfieldType(T, N')), X))
               fillBitHoles(N +Int N', L)
          when N' =/=Int 0 
          
     rule fillBitHoles(N:Int, ListItem(typedDeclaration(t(_, 
               bitfieldType(_:Type, N':Int)), _:Id)) L:List) 
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte)) 
               %Int cfg:bitsPerByte)), #NoName))
               fillBitHoles(L)
          when N' ==Int 0
     
     rule fillBitHoles(N:Int, .List) 
          => ListItem(typedDeclaration(
               t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte))
               %Int cfg:bitsPerByte)), #NoName))
          
     syntax List ::= fillUnionBitHoles(List) [function]
     syntax List ::= fillUnionBitHoles(Int, List) [function]
     rule fillUnionBitHoles(.List) => .List
     rule fillUnionBitHoles(ListItem(K:K) L:List) 
          => fillUnionBitHoles(0, ListItem(K) L)
     rule fillUnionBitHoles(N:Int, 
               ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => ListItem(typedDeclaration(T, X))
               fillUnionBitHoles(N, L)
          when notBool isBitfieldType(T)
     rule fillUnionBitHoles(N:Int, ListItem(typedDeclaration(t(S:Set, 
               bitfieldType(T:Type, N':Int)), X:Id)) L:List) 
          => ListItem(typedDeclaration(t(S, bitfieldType(T, N')), X))
               fillUnionBitHoles(maxInt(N, N'), L)
     rule fillUnionBitHoles(N:Int, .List) 
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               N +Int (absInt(cfg:bitsPerByte -Int 
               (N %Int cfg:bitsPerByte)) %Int cfg:bitsPerByte))), #NoName))

     syntax List ::= mergeBitfields(List) [function]
     rule mergeBitfields(
               (ListItem(typedDeclaration(t(_, bitfieldType(_, N:Int)), #NoName))
               ListItem(typedDeclaration(t(_, bitfieldType(_, N':Int)), #NoName))
               => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int),
                    N +Int N')), #NoName)))
               _:List)
     rule mergeBitfields(ListItem(F:Type) ListItem(F':Type) Fs:List)
          => ListItem(F) mergeBitfields(ListItem(F') Fs)
          when (#mergable(F) =/=K true) orBool (#mergable(F') =/=K true)
     rule mergeBitfields(ListItem(F:Type)) => ListItem(F)
     rule mergeBitfields(.List) => .List
     
     syntax Bool ::= "#mergable" "(" Type ")" [function]
     rule #mergable(typedDeclaration(t(_, bitfieldType(_, _)), #NoName))
          => true

     syntax K ::= "structDef'" "(" Id "," FieldInfo ")"
                | "unionDef'" "(" Id "," FieldInfo ")"

     rule structDef'(X:Id, Info:FieldInfo)
          => addTag(X, Info)
          // ~> giveType(X, t(.Set, structType(X, bitSizeofStruct(Info), Info)))
          [structural]

     rule unionDef'(X:Id, Info:FieldInfo)
          => addTag(X, Info)
          // ~> giveType(X, t(.Set, unionType(X, bitSizeofUnion(Info), Info)))
          [structural]

     syntax K ::= addLocalTag(Id, FieldInfo)

     syntax FieldInfo ::= "makeStructFieldInfo'" "(" List "," Int "," Map ","  Map "," List ")"
                         [function]
     rule makeStructFieldInfo(L:List) 
          => makeStructFieldInfo'(
               mergeBitfields(fillBitHoles(incompleteToFlexibleArrayMember(L))),
               0, .Map, .Map, L)
          when L:List =/=List .List
     rule makeStructFieldInfo'(
               ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , V:Int
               , Types:Map
               , Offsets:Map
               , L':List
          )
          => makeStructFieldInfo'(L, V +Int bitSizeofType(T),
               Types:Map[T / Field], Offsets:Map[V / Field], L')
     rule makeStructFieldInfo'(.List, _, Types:Map, Offsets:Map, L:List) 
          => fieldInfo(L, Types, Offsets)

     syntax FieldInfo ::= "makeUnionFieldInfo'" "(" List "," Map ","  Map "," List ")"
                         [function]
     
     rule makeUnionFieldInfo(L:List) 
          => makeUnionFieldInfo'(mergeBitfields(fillUnionBitHoles(L)),
               .Map, .Map, L)
          when L =/=List .List
     rule makeUnionFieldInfo'(
               ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , Types:Map
               , Offsets:Map
               , L':List
          )
          => makeUnionFieldInfo'(L,
               Types:Map[T / Field], Offsets:Map[0 / Field], L')
     rule makeUnionFieldInfo'(.List, Types:Map, Offsets:Map, L:List) 
          => fieldInfo(L, Types, Offsets)

     syntax K ::= addTag(Id, FieldInfo)
     rule <k> addTag(S:Id, fieldInfo(Fs:List, Ts:Map, Offs:Map))
               // Elide function parameter names in struct types.
               => addGlobalTag(S, fieldInfo(elideList(Fs), elideMap(Ts), Offs))
          ...</k>
          <curr-function> file-scope </curr-function>
          [structural]        
     rule <k> addTag(S:Id, fieldInfo(Fs:List, Ts:Map, Offs:Map))
               => addLocalTag(S, fieldInfo(elideList(Fs), elideMap(Ts), Offs))
          ...</k>
          <curr-function> F:Id </curr-function>
          when F =/=K file-scope
          [structural]        

     rule <k> addLocalTag(X:Id, Info:FieldInfo) => . ...</k>
          <structs> Structs:Map => Structs:Map[Info / X] </structs>
          [structural]
endmodule

