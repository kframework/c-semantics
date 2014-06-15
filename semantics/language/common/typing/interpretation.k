module C-TYPING-INTERPRETATION-SYNTAX
     syntax List ::= adjustParams(List) [function]
endmodule

module C-TYPING-INTERPRETATION
     imports C-TYPING-INTERPRETATION-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-CANONICALIZATION-SYNTAX
     imports C-TYPING-SYNTAX

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
     syntax KLabel ::= makeArrayType(CSize, K)
     syntax Type ::= pushTypeDown(Type, KLabel) [function]

     rule ArrayType(T:Type, tv(N:Int, _), Spec:K)
          => pushTypeDown(T, makeArrayType(N, Spec))
          when N >Int 0
          [structural]
     rule ArrayType(T:Type, tv(N:CSize, _), Spec:K)
          => pushTypeDown(T, makeArrayType(N, Spec))
          when isInt(N) =/=K true // VLAs.
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

     rule FunctionType(T:Type) => T
          [structural]

     syntax CId ::= prototype(CId)
     // "Prototype scope."
     rule <k> Prototype(T:Type, list(L:List), Var:Bool)
               => pushBlock ~> Prototype'(T, L, .List, Var)
          ...</k>
          <curr-function> X:CId => prototype(X) </curr-function>
          [structural]

     // We "declare" function prototype parameters in the order they appear,
     // from left to right. This is mostly to (somewhat) handle VLA parameters.
     syntax K ::= "Prototype'" "(" Type "," List "," List "," Bool ")"
     rule Prototype'(T:Type, ListItem(K:K) L1:List, L2:List, Var:Bool)
          => K ~> Prototype'(T, L1, L2, Var)
          [structural]
     rule t(Mods:Set, ST:SimpleType)
          ~> Prototype'(T:Type, L1:List, L2:List, Var:Bool)
          => Prototype'(T, L1, L2 ListItem(adjustParam(t(Mods, ST))), Var)
          [structural]
     syntax SymBase ::= vla(CId)
     rule typedDeclaration(DT:Type, X:CId)
          ~> Prototype'(T:Type, L1:List, L2:List, Var:Bool)
          => declareInternalVariable(X, adjustParam(DT), NoInit)
          ~> Prototype'(T, L1, L2 ListItem(typedDeclaration(adjustParam(DT), X)), Var)
          when X =/=K #NoName
          [structural]
     rule typedDeclaration(DT:Type, X:CId)
          ~> Prototype'(T:Type, L1:List, L2:List, Var:Bool)
          => Prototype'(T, L1, L2 ListItem(typedDeclaration(adjustParam(DT), X)), Var)
          when X ==K #NoName
          [structural]
     rule Prototype'(T:Type, .List, L2:List, Var:Bool)
          => Prototype''(T, L2, Var)
          [structural]

     syntax K ::= "Prototype''" "(" Type "," List "," Bool ")"
     rule <k> Prototype''(T:Type, L:List, false)
               => popBlock ~> pushTypeDown(T, makeFunctionType(L))
          ...</k>
          <curr-function> prototype(X:CId) => X </curr-function>
          [structural]
     rule <k> Prototype''(T:Type, L:List, true)
               => popBlock ~> pushTypeDown(T, makeFunctionType(L ListItem(variadic)))
          ...</k>
          <curr-function> prototype(X:CId) => X </curr-function>
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

     rule makeArrayType(N:CSize, Specifier(list(ListItem(Static))))(T:Type)
          => t(getSpecifiers(T) SetItem(arrayStatic(N)),
               arrayType(stripSpecifiers(T), N))
          [structural, anywhere]
     // TODO(chathhorn): Other qualifiers?
     rule makeArrayType(N:CSize, Specifier(list(.List)))(T:Type)
          => t(getSpecifiers(T), arrayType(stripSpecifiers(T), N))
          when isInt(N) ==K true
          [structural, anywhere]
     // TODO(chathhorn): better VLA support (need to keep around the
     // un-evaluated size expression).
     rule makeArrayType(N:CSize, Specifier(list(.List)))(T:Type)
          => t(getSpecifiers(T), variableLengthArrayType(stripSpecifiers(T)))
          when isInt(N) =/=K true
          [structural, anywhere]
     rule makeFunctionType(L:List)(T:Type)
          => t(getSpecifiers(T),
               functionType(stripSpecifiers(T), giveNamesToArgs(L)))
          [structural, anywhere]
     rule makeOldStyleFunctionType(L:List)(T:Type)
          => t(getSpecifiers(T) SetItem(oldStyle),
               functionType(stripSpecifiers(T), giveNamesToArgs(L)))
          [structural, anywhere]
     rule makePointerType(Quals:Set)(T:Type)
          => t(Quals getSpecifiers(T),
               pointerType(stripSpecifiers(T)))
          [structural, anywhere]
     rule makeIncompleteArrayType(T:Type)
          => t(getSpecifiers(T),
               incompleteArrayType(stripSpecifiers(T)))
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
     rule extractActualType(t(S:Set, variableLengthArrayType(T:Type)))
          => t(S, variableLengthArrayType(extractActualType(T)))
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
