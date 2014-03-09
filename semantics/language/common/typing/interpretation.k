module C-TYPING-INTERPRETATION
     imports C-TYPING-SYNTAX
     imports C-TYPING-MISC-SYNTAX
     imports C-TYPING-CANONICALIZATION-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     // Rules that use specifier should be careful to use extractActualType if
     // going to be used in a typed name.
     syntax Type ::= extractActualType(Type) [function] 

     syntax K ::= BitFieldType(K, K) [strict] 
     
     rule Specifier(list(L:List)) => canonicalizeType(toBag(L))
          [structural]
          
     rule BitFieldType(T:Type, tv(N:Int, _))
          => t(.Set, bitfieldType(T, N)) [structural, anywhere]
     
     syntax KLabel ::= makeFunctionType(List)
     syntax KLabel ::= "makePointerType"
     syntax KLabel ::= "makeIncompleteArrayType"
     syntax KLabel ::= makeArrayType(ArraySize)
     syntax Type ::= pushTypeDown(Type, KLabel) [function]
     
     // FIXME: throwing away specifier.
     rule ArrayType(T:Type, tv(N:Int, _), _) 
          => pushTypeDown(T, makeArrayType(N)) 
          when N >Int 0
          [structural, anywhere]
     rule ArrayType(T:Type, tv(N:ArraySize, _), _) 
          => pushTypeDown(T, makeArrayType(N)) 
          when notBool isInt(N) // For possible symbolic values.
          [structural, anywhere]
     rule ArrayType(T:Type, emptyValue, _)
          => pushTypeDown(T, makeIncompleteArrayType)
          [structural, anywhere]
     rule PointerType(T:Type)
          => pushTypeDown(T, makePointerType)
          [structural, anywhere]
     // FIXME: I'm assuming functiontype is always below a prototype in the
     // AST.
     rule FunctionType(T:Type) => T
          [structural, anywhere]
     rule Prototype(T:Type, krlist(L:List), false) 
          => pushTypeDown(T, 
               makeFunctionType(L)) 
          [structural, anywhere]
     rule Prototype(T:Type, krlist(L:List), true) 
          => pushTypeDown(T, 
               makeFunctionType(L ListItem(t(.Set, variadic)))) 
          [structural, anywhere]
     
     rule [pushdown-array]: 
          pushTypeDown(t(S:Set, arrayType(T:Type, N:Int)), Lbl:KLabel) 
          => t(S, arrayType(pushTypeDown(T, Lbl), N))
     rule [pushdown-incomplete]: 
          pushTypeDown(t(S:Set, incompleteArrayType(T:Type)), Lbl:KLabel) 
          => t(S, incompleteArrayType(pushTypeDown(T, Lbl)))
     rule [pushdown-pointer]: 
          pushTypeDown(t(S:Set, pointerType(T:Type)), Lbl:KLabel) 
          => t(S, pointerType(pushTypeDown(T, Lbl)))
     rule [pushdown-qualified]: 
          pushTypeDown(t(S:Set, qualifiedType(T:Type, K:K)), Lbl:KLabel) 
          => t(S, qualifiedType(pushTypeDown(T, Lbl), K))
     rule [pushdown-function]: 
          pushTypeDown(t(S:Set, functionType(T:Type, L:List)), Lbl:KLabel) 
          => t(S, functionType(pushTypeDown(T, Lbl), L))
     rule [pushdown-struct]: 
          pushTypeDown(t(S:Set, structType(X:Id)), Lbl:KLabel) 
          => Lbl(t(S, structType(X)))
     rule [pushdown-union]: 
          pushTypeDown(t(S:Set, unionType(X:Id)), Lbl:KLabel) 
          => Lbl(t(S, unionType(X)))
     rule [pushdown-enum]: 
          pushTypeDown(t(S:Set, enumType(X:Id)), Lbl:KLabel) 
          => Lbl(t(S, enumType(X)))
     
     rule [pushdown-typedef]: 
          pushTypeDown(t(S:Set, typedefType(_:Id, t(S':Set, T:K))), Lbl:KLabel) 
          => Lbl(t(S S', T))
     
     rule [pushdown-basic]: 
          pushTypeDown(T:Type, Lbl:KLabel) => Lbl(T) 
          when isBasicType(T)
          [structural]
     
     rule makeArrayType(N:Int)(T:Type)
          => t(.Set, arrayType(T, N)) 
          [structural, anywhere]
     rule makeFunctionType(L:List)(T:Type)
          => t(.Set, functionType(T, giveNamesToArgs(L))) 
          [structural, anywhere]
     rule makePointerType(T:Type)
          => t(.Set, pointerType(T))
          [structural, anywhere]
     rule makeIncompleteArrayType(T:Type)
          => t(.Set, incompleteArrayType(T))
          [structural, anywhere]
     
     syntax List ::= giveNamesToArgs(List) [function]
     syntax List ::= "giveNamesToArgs-aux" "(" Int "," List ")" [function]
     
     rule giveNamesToArgs(L:List) => giveNamesToArgs-aux(0, L)
     rule giveNamesToArgs-aux(N:Int, 
               (ListItem(typedDeclaration(T:Type, X:Id)) L:List))
          => ListItem(typedDeclaration(T, X))
               giveNamesToArgs-aux(N, L)
          when X =/=K #NoName
          [structural]
     rule giveNamesToArgs-aux(N:Int, 
               (ListItem(typedDeclaration(T:Type, X:Id)) L:List))
          => ListItem(typedDeclaration(T, #NoName(N))) 
               giveNamesToArgs-aux(N +Int 1, L)
          when X ==K #NoName
          [structural]
     rule giveNamesToArgs-aux(_:Int, ListItem(t(.Set, variadic)))
          => ListItem(t(.Set, variadic))
          [structural]
     rule giveNamesToArgs-aux(_:Int, .List)
          => .List
          [structural]
     
     rule <k> JustBase => T ...</k>
          <decl-type-holder> T:Type => . ...</decl-type-holder>
          [structural]

     syntax K ::= "extractActualTypeFreezer"
     rule <k> DeclType(T:Type, K:K) => K:K ~> extractActualTypeFreezer ...</k>
          <decl-type-holder> (. => T) ...</decl-type-holder>
          [structural]
     
     rule T:Type ~> extractActualTypeFreezer 
          => extractActualType(T)
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
               ListItem(typedDeclaration(t(S:Set, bitfieldType(T:Type, N':Int)), X:Id)) 
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
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte))
               %Int cfg:bitsPerByte)), #NoName))
          [structural]
     
     rule typedDeclaration(t(_, bitfieldType(_, N:Int)), #NoName),,
               typedDeclaration(t(_, bitfieldType(_, N':Int)), #NoName) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int),
               N +Int N')), #NoName) 
          [structural, anywhere]
     
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
     
     rule StructDef(X:Id, krlist(L:List))
          => addStruct(X, fillBitHoles(incompleteToFlexibleArrayMember(L)))
               ~> giveType(X, t(.Set, structType(X)))
          [structural]
     rule UnionDef(X:Id, krlist(L:List))
          => addUnion(X, fillUnionBitHoles(L))
               ~> giveType(X, t(.Set, unionType(X)))
          [structural]

     // The K will resolve to a type, so throw it away.
     rule OnlyTypedef(K:K) => K ~> discard
          [structural]
          
     rule NameAndType(X:Id, T:Type) => typedDeclaration(T, X)
          [structural, anywhere] 
     
     rule [extract-basic]: 
          extractActualType(T:Type) => T
          when isBasicType(T)
     rule [extract-enum]: 
          extractActualType(t(S:Set, enumType(X:Id))) 
          => t(S, enumType(X))
     rule [extract-struct]:
          extractActualType(t(S:Set, structType(X:Id))) 
          => t(S, structType(X))
     rule [extract-union]:
          extractActualType(t(S:Set, unionType(X:Id))) 
          => t(S, unionType(X))
     rule [extract-array]:
          extractActualType(t(S:Set, arrayType(T:Type, N:Int))) 
          => t(S, arrayType(extractActualType(T), N))
     rule [extract-incompleteArray]:
          extractActualType(t(S:Set, incompleteArrayType(T:Type))) 
          => t(S, incompleteArrayType(extractActualType(T)))
     rule [extract-bitfield]:
          extractActualType(t(S:Set, bitfieldType(T:Type, N:Int))) 
          => t(S, bitfieldType(extractActualType(T), N))
     rule [extract-function]:
          extractActualType(t(S:Set, functionType(T:Type, L:List))) 
          => t(S, functionType(extractActualType(T), L))
     rule [extract-pointer]:
          extractActualType(t(S:Set, pointerType(T:Type))) 
          => t(S, pointerType(extractActualType(T)))
     rule [extract-qualified]:
          extractActualType(t(S:Set, qualifiedType(T:Type, K:K))) 
          => t(S, qualifiedType(extractActualType(T), K))
     rule [extract-typedef]:
          extractActualType(t(S:Set, typedefType(_:Id, t(S':Set, T:K)))) 
          => extractActualType(t(S S', T))
          
     syntax K ::= NameAndType(K, K) [strict(2)] 
          
     rule SingleName(T:Type, Name(X:Id, K:K)) 
          => NameAndType(X, DeclType(T, K))
          [structural, anywhere] 
     rule [Separate-FieldGroups]:
          FieldGroup(K:K, list(ListItem(C:K) ListItem(C':K) L:List)) 
          => FieldGroup(K, list(ListItem(C))),, 
               FieldGroup(K, list(ListItem(C') L))
          [structural, anywhere]

     rule FieldGroup(T:Type, list(ListItem(Name(X:Id, K:K)))) 
          => NameAndType(X, DeclType(T, K))
          [structural, anywhere]
          
     rule FieldGroup(T:Type, list(ListItem(BitFieldName(Name(X:Id, K:K), Size:K))))
          => NameAndType(X, DeclType(T, BitFieldType(K, Size)))
          [structural, anywhere] 
     rule FieldName(K:K) => K [structural, anywhere]
endmodule

