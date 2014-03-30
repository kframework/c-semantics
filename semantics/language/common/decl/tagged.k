module C-DECL-TAGGED-SYNTAX
     // Not defined, just used.
     syntax K ::= addGlobalAggregate(Id, Int, AggInfo)
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

     // *** TODO *** Struct/UnionDef *** TODO ***
          
     // First map is for type, second map is for offset.
     syntax AggInfo ::= makeStructAggInfo(List) [function]
     syntax AggInfo ::= makeUnionAggInfo(List) [function]

     // TODO(chathhorn): handle global/local differently.
     // note that struct defs might appear buried in a type.
     rule StructDef(X:Id, krlist(L:List))
          => structDef'(X,
               makeStructAggInfo(fillBitHoles(incompleteToFlexibleArrayMember(L))))
          when L =/=List .List
          [structural]
     rule UnionDef(X:Id, krlist(L:List))
          => unionDef'(X, makeUnionAggInfo(fillUnionBitHoles(L)))
          when L =/=List .List
          [structural]

     // FIXME: chould check for some struct contraints here.
     syntax List ::= incompleteToFlexibleArrayMember(List) [function]

     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(T:Type, X:Id)) 
          L:List)
          => ListItem(typedDeclaration(T, X)) incompleteToFlexibleArrayMember(L)
          when notBool isIncompleteType(T)
          [structural]
     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(t(S:Set, incompleteArrayType(T:Type)), X:Id)))
          => ListItem(typedDeclaration(t(S, flexibleArrayType(T)), X))
          [structural]
     rule incompleteToFlexibleArrayMember(.List) => .List

     syntax List ::= fillBitHoles(List) [function]
     syntax List ::=  "fillBitHoles-aux" "(" Int "," List ")" [function]
     rule [fillBitHoles-none]:
          fillBitHoles(.List) => .List 
          [structural]
     // if we haven't seen bitfields
     rule [fillBitHoles-not-bitfield]:
          fillBitHoles(ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => ListItem(typedDeclaration(T, X)) fillBitHoles(L)
          when notBool isBitfieldType(T) 
          [structural]
     
     rule [fillBitHoles-bitfield]:
          fillBitHoles(ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => fillBitHoles-aux(0, ListItem(typedDeclaration(T, X)) L)
          when isBitfieldType(T) 
          [structural]
     
     // if we have seen bitfields
     rule [fillBitHoles-aux-not-bitfield]:
          fillBitHoles-aux(N:Int, 
               ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte)) 
               %Int cfg:bitsPerByte)), #NoName))
               fillBitHoles(ListItem(typedDeclaration(T, X)) L)
          when notBool isBitfieldType(T) 
          [structural]
     
     rule [fillBitHoles-aux-bitfield-normal]:
          fillBitHoles-aux(N:Int, 
               ListItem(typedDeclaration(t(S:Set,
               bitfieldType(T:Type, N':Int)), X:Id))
               L:List) 
          => ListItem(typedDeclaration(t(S, bitfieldType(T, N')), X))
               fillBitHoles-aux(N +Int N', L)
          when N' =/=Int 0 
          [structural]
          
     rule [fillBitHoles-bitfield-zero]:
          fillBitHoles-aux(N:Int, ListItem(typedDeclaration(t(_, 
               bitfieldType(_:Type, N':Int)), _:Id)) L:List) 
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte)) 
               %Int cfg:bitsPerByte)), #NoName))
               fillBitHoles(L)
          when N' ==Int 0
          [structural]
     
     rule [fillBitHoles-done]:
          fillBitHoles-aux(N:Int, .List) 
          => ListItem(typedDeclaration(
               t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte))
               %Int cfg:bitsPerByte)), #NoName))
          [structural]
          
     syntax List ::= fillUnionBitHoles(List) [function]
     syntax List ::= "fillUnionBitHoles-aux" "(" Int "," List ")" [function]
     rule fillUnionBitHoles(.List) => .List
     rule fillUnionBitHoles(ListItem(K:K) L:List) 
          => fillUnionBitHoles-aux(0, ListItem(K) L)
     rule fillUnionBitHoles-aux(N:Int, 
               ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => ListItem(typedDeclaration(T, X))
               fillUnionBitHoles-aux(N, L)
          when notBool isBitfieldType(T)
          [structural]
     rule fillUnionBitHoles-aux(N:Int, ListItem(typedDeclaration(t(S:Set, 
               bitfieldType(T:Type, N':Int)), X:Id)) L:List) 
          => ListItem(typedDeclaration(t(S, bitfieldType(T, N')), X))
               fillUnionBitHoles-aux(maxInt(N, N'), L)
          [structural]
     rule fillUnionBitHoles-aux(N:Int, .List) 
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               N +Int (absInt(cfg:bitsPerByte -Int 
               (N %Int cfg:bitsPerByte)) %Int cfg:bitsPerByte))), #NoName))
          [structural]
     
     // TODO(chathhorn): this surely doesn't work.
     rule ListItem(typedDeclaration(t(_, bitfieldType(_, N:Int)), #NoName))
          ListItem(typedDeclaration(t(_, bitfieldType(_, N':Int)), #NoName))
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int),
               N +Int N')), #NoName))
          [structural, anywhere]
     
     
     syntax K ::= "structDef'" "(" Id "," AggInfo ")"
                | "unionDef'" "(" Id "," AggInfo ")"

     rule structDef'(X:Id, Info:AggInfo)
          => addAgg(X, bitSizeofStruct(Info), Info)
          ~> giveType(X, t(.Set, structType(X, bitSizeofStruct(Info), Info)))
          [structural]

     rule unionDef'(X:Id, Info:AggInfo)
          => addAgg(X, bitSizeofUnion(Info), Info)
          ~> giveType(X, t(.Set, unionType(X, bitSizeofUnion(Info), Info)))
          [structural]

     syntax K ::= addLocalAggregate(Id, AggInfo)

     syntax AggInfo ::= "makeStructAggInfo'" "(" List "," Int "," Map ","  Map "," List ")"
                         [function]
     rule makeStructAggInfo(L:List) 
          => makeStructAggInfo'(L:List, 0, .Map, .Map, L:List)
          when L:List =/=List .List
     rule makeStructAggInfo'(
               ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , V:Int
               , Types:Map
               , Offsets:Map
               , L':List
          )
          => makeStructAggInfo'(L, V +Int bitSizeofType(T),
               Types:Map[T / Field], Offsets:Map[V / Field], L')
     rule makeStructAggInfo'(.List, _, Types:Map, Offsets:Map, L:List) 
          => aggInfo(L, Types, Offsets)

     syntax AggInfo ::= "makeUnionAggInfo'" "(" List "," Map ","  Map "," List ")"
                         [function]
     
     rule makeUnionAggInfo(L:List) 
          => makeUnionAggInfo'(L, .Map, .Map, L)
          when L =/=List .List
     rule makeUnionAggInfo'(
               ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , Types:Map
               , Offsets:Map
               , L':List
          ) 
          => makeUnionAggInfo'(L,
               Types:Map[T / Field], Offsets:Map[0 / Field],
               L')
     rule makeUnionAggInfo'(.List, Types:Map, Offsets:Map, L:List) 
          => aggInfo(L, Types, Offsets)

     syntax K ::= addAgg(Id, Int, AggInfo)
     rule <k> addAgg(S:Id, NBits:Int, Info:AggInfo)
               => addGlobalAggregate(S, NBits, Info)
          ...</k>
          <curr-function> file-scope </curr-function>
          [structural]        
     rule <k> addAgg(S:Id, _, Info:AggInfo)
               => addLocalAggregate(S, Info)
          ...</k>
          <curr-function> F:Id </curr-function>
          when F =/=K file-scope
          [structural]        

     rule <k> addLocalAggregate(X:Id, Agg:AggInfo) => . ...</k>
          <structs> Structs:Map => Structs:Map[Agg / X] </structs>
          [structural]

endmodule

