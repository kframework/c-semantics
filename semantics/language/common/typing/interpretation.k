module C-TYPING-INTERPRETATION
     imports C-TYPING-SYNTAX
     imports C-TYPING-CANONICALIZATION-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX

     imports COMPAT-SYNTAX

     // Rules that use specifier should be careful to use extractActualType if
     // going to be used in a typed name.
     syntax Type ::= extractActualType(Type) [function] 

     syntax K ::= BitFieldType(K, K) [strict] 
     
     rule Specifier(list(L:List)) => canonicalizeType(toBag(L))
          [structural]
          
     rule BitFieldType(T:Type, tv(N:CSize, _))
          => t(.Set, bitfieldType(T, N)) [structural]
     
     syntax KLabel ::= makeFunctionType(List)
     syntax KLabel ::= makeOldStyleFunctionType(List)
     syntax KLabel ::= makePointerType(Set)
     syntax KLabel ::= "makeIncompleteArrayType"
     syntax KLabel ::= makeArrayType(CSize)
     syntax Type ::= pushTypeDown(Type, KLabel) [function]
     
     rule ArrayType(T:Type, tv(N:Int, _), _) 
          => pushTypeDown(T, makeArrayType(N)) 
          when N >Int 0
          [structural]
     rule ArrayType(T:Type, tv(N:CSize, _), _) 
          => pushTypeDown(T, makeArrayType(N)) 
          when isInt(N) =/=K true // For possible symbolic values.
          [structural]
     rule ArrayType(T:Type, emptyValue, _)
          => pushTypeDown(T, makeIncompleteArrayType)
          [structural]
     rule (. => UNDEF("CTI1", "Arrays must have integer length.", "6.6:6"))
          ~> ArrayType(_, tv(_:Float, _), _)
          [structural]
     rule (. => CV("CTI2", "Arrays must have positive length.", "6.7.6.2:1"))
          ~> ArrayType(_, tv(Len:Int, _), _)
          when Len <=Int 0
          [structural]
     
     rule PointerType(Specifier(list(Quals:List)), T:Type)
          => pushTypeDown(T, makePointerType(listToSet(Quals)))
          [structural]

     syntax Set ::= listToSet(List) [function]
     rule listToSet(ListItem(K:K) L:List) => SetItem(K) listToSet(L)
     rule listToSet(.List) => .Set

     // FIXME: I'm assuming functiontype is always below a prototype in the
     // AST.
     rule FunctionType(T:Type) => T
          [structural]
     rule Prototype(T:Type, krlist(L:List), false) 
          => pushTypeDown(T, 
               makeFunctionType(L)) 
          [structural]
     rule Prototype(T:Type, krlist(L:List), true) 
          => pushTypeDown(T, 
               makeFunctionType(L ListItem(variadic))) 
          [structural]

     rule NoPrototype(T:Type, krlist(L:List), false) 
          => pushTypeDown(T, 
               makeOldStyleFunctionType(L)) 
          [structural]
     
     rule pushTypeDown(t(S:Set, arrayType(T:Type, N:CSize)), Lbl:KLabel) 
          => t(S, arrayType(pushTypeDown(T, Lbl), N))
     rule pushTypeDown(t(S:Set, incompleteArrayType(T:Type)), Lbl:KLabel) 
          => t(S, incompleteArrayType(pushTypeDown(T, Lbl)))
     rule pushTypeDown(t(S:Set, pointerType(T:Type)), Lbl:KLabel) 
          => t(S, pointerType(pushTypeDown(T, Lbl)))
     rule pushTypeDown(t(S:Set, functionType(T:Type, L:List)), Lbl:KLabel) 
          => t(S, functionType(pushTypeDown(T, Lbl), L))
     rule pushTypeDown(t(S:Set, structType(X:CId, NBits:Int, Info:FieldInfo)), Lbl:KLabel) 
          => Lbl(t(S, structType(X, NBits, Info)))
     rule pushTypeDown(t(S:Set, incompleteStructType(X:CId)), Lbl:KLabel) 
          => Lbl(t(S, incompleteStructType(X)))
     rule pushTypeDown(t(S:Set, unionType(X:CId, NBits:Int, Info:FieldInfo)), Lbl:KLabel) 
          => Lbl(t(S, unionType(X, NBits, Info)))
     rule pushTypeDown(t(S:Set, incompleteUnionType(X:CId)), Lbl:KLabel) 
          => Lbl(t(S, incompleteUnionType(X)))
     rule pushTypeDown(t(S:Set, enumType(X:CId)), Lbl:KLabel) 
          => Lbl(t(S, enumType(X)))
     
     rule pushTypeDown(t(S:Set, typedefType(_, t(S':Set, T:K))), Lbl:KLabel) 
          => Lbl(t(S S', T))
     
     rule pushTypeDown(T:Type, Lbl:KLabel) => Lbl(T) 
          when isBasicType(T)
     
     rule makeArrayType(N:CSize)(T:Type)
          => t(getStorageSpecifiers(T),
               arrayType(stripStorageSpecifiers(T), N)) 
          [structural, anywhere]
     rule makeFunctionType(L:List)(T:Type)
          => t(getStorageSpecifiers(T),
               functionType(stripStorageSpecifiers(T), adjustParams(giveNamesToArgs(L)))) 
          [structural, anywhere]
     rule makeOldStyleFunctionType(L:List)(T:Type)
          => t(getStorageSpecifiers(T) SetItem(oldStyle),
               functionType(stripStorageSpecifiers(T), adjustParams(giveNamesToArgs(L)))) 
          [structural, anywhere]
     rule makePointerType(Quals:Set)(T:Type)
          => t(Quals getStorageSpecifiers(T),
               pointerType(stripStorageSpecifiers(T)))
          [structural, anywhere]
     rule makeIncompleteArrayType(T:Type)
          => t(getStorageSpecifiers(T),
               incompleteArrayType(stripStorageSpecifiers(T)))
          [structural, anywhere]

     syntax List ::= giveNamesToArgs(List) [function]
     syntax List ::= "giveNamesToArgs-aux" "(" Int "," List ")" [function]
     
     rule giveNamesToArgs(L:List) => giveNamesToArgs-aux(0, L)
     rule giveNamesToArgs-aux(N:Int, 
               (ListItem(typedDeclaration(T:Type, X:CId)) L:List))
          => ListItem(typedDeclaration(T, X))
               giveNamesToArgs-aux(N, L)
          when X =/=K #NoName
          [structural]
     rule giveNamesToArgs-aux(N:Int, 
               (ListItem(typedDeclaration(T:Type, X:CId)) L:List))
          => ListItem(typedDeclaration(T, #NoName(N))) 
               giveNamesToArgs-aux(N +Int 1, L)
          when X ==K #NoName
          [structural]
     rule giveNamesToArgs-aux(_, ListItem(variadic))
          => ListItem(variadic)
          [structural]
     rule giveNamesToArgs-aux(_, .List)
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
     
     // The K will resolve to a type, so throw it away.
     rule OnlyTypedef(K:K) => K ~> discard
          [structural]
          
     rule NameAndType(X:CId, T:Type) => typedDeclaration(T, X)
          [structural] 
     
     rule extractActualType(T:Type) => T
          when isBasicType(T)
     rule extractActualType(t(S:Set, enumType(X:CId))) 
          => t(S, enumType(X))
     rule extractActualType(t(S:Set, structType(X:CId, NBits:Int, Info:FieldInfo))) 
          => t(S, structType(X, NBits, Info))
     rule extractActualType(t(S:Set, incompleteStructType(X:CId))) 
          => t(S, incompleteStructType(X))
     rule extractActualType(t(S:Set, unionType(X:CId, NBits:Int, Info:FieldInfo))) 
          => t(S, unionType(X, NBits, Info))
     rule extractActualType(t(S:Set, incompleteUnionType(X:CId))) 
          => t(S, incompleteUnionType(X))
     rule extractActualType(t(S:Set, arrayType(T:Type, N:CSize))) 
          => t(S, arrayType(extractActualType(T), N))
     rule extractActualType(t(S:Set, incompleteArrayType(T:Type))) 
          => t(S, incompleteArrayType(extractActualType(T)))
     rule extractActualType(t(S:Set, bitfieldType(T:Type, N:CSize))) 
          => t(S, bitfieldType(extractActualType(T), N))
     rule extractActualType(t(S:Set, functionType(T:Type, L:List))) 
          => t(S, functionType(extractActualType(T), L))
     rule extractActualType(t(S:Set, pointerType(T:Type))) 
          => t(S, pointerType(extractActualType(T)))
     rule extractActualType(t(S:Set, typedefType(_, t(S':Set, T:K)))) 
          => extractActualType(t(S S', T))
          
     syntax K ::= NameAndType(CId, K) [strict(2)] 
          
     rule SingleName(T:Type, Name(X:CId, K:K)) 
          => NameAndType(X, DeclType(T, K))
          [structural] 
     rule FieldGroup(K:K, list(ListItem(C:K) ListItem(C':K) L:List)) 
          => list(ListItem(FieldGroup(K, list(ListItem(C))))
               ListItem(FieldGroup(K, list(ListItem(C') L))))
          [structural]

     rule FieldGroup(T:Type, list(ListItem(FieldName(Name(X:CId, K:K)))))
          => NameAndType(X, DeclType(T, K))
          [structural]
          
     rule FieldGroup(T:Type, list(ListItem(BitFieldName(Name(X:CId, K:K), Size:K))))
          => NameAndType(X, DeclType(T, BitFieldType(K, Size)))
          [structural] 
endmodule

