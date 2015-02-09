module C-TYPING-INTERPRETATION-SYNTAX
     syntax List ::= adjustParams(List) [function]
     syntax CId ::= prototype(CId)
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

     syntax KItem ::= BitFieldType(K, K) [strict]

     rule Specifier(list(L:List)) => canonicalizeType(L)
          [structural]

     rule BitFieldType(T:Type, tv(N:CSize, t(SetItem(IntegerConstant) _:Set, _)))
          => t(.Set, bitfieldType(T, N)) [structural]

     rule (.K => CV("CTI3", "The width of a bit field shall be an integer constant expression", "6.7.2.1:4"))
          ~> BitFieldType(_, tv(N:CValue, t(Modifiers:Set, _)))
          requires notBool IntegerConstant in Modifiers orBool isCSize(N) =/=K true

     syntax KItem ::= makeFunctionType(List)
     syntax KItem ::= makeOldStyleFunctionType(List)
     syntax KItem ::= makePointerType(Set)
     syntax KItem ::= "makeIncompleteArrayType"
     syntax KItem ::= makeArrayType(K, K)
     syntax Type ::= pushTypeDown(Type, K) [function]

     rule ArrayType(T:Type, K:K, Spec:K)
          => ArrayType'(T, K, K, Spec)

     // We need to keep the unevaluated size expression around in the case of
     // VLA function parameters.
     syntax KItem ::= "ArrayType'" "(" Type "," K "," K "," K ")"
     context ArrayType'(_, (HOLE => reval(HOLE)), _, _) [ndheat]
     rule ArrayType'(T:Type, tv(N:Int, _), _, Spec:K)
          => pushTypeDown(T, makeArrayType(N, Spec))
          requires N >Int 0
          [structural]
     rule ArrayType'(T:Type, tv(N:CSize, _), K:K, Spec:K)
          => pushTypeDown(T, makeArrayType(K, Spec))
          requires isInt(N) =/=K true // VLAs.
          [structural]
     rule ArrayType'(T:Type, emptyValue, _, _)
          => pushTypeDown(T, makeIncompleteArrayType)
          [structural]
     rule (.K => UNDEF("CTI1", "Arrays must have integer length.", "6.6:6"))
          ~> ArrayType'(_, tv(_:Float, _), _, _)
          [structural]
     rule (.K => CV("CTI2", "Arrays must have positive length.", "6.7.6.2:1"))
          ~> ArrayType'(_, tv(Len:Int, _), _, _)
          requires Len <=Int 0
          [structural]

     syntax Type ::= applyTypeFunction(K, Type) [function]

     rule PointerType(Specifier(list(Quals:List)), T:Type)
          => pushTypeDown(T, makePointerType(listToSet(Quals)))
          [structural]

     syntax Set ::= listToSet(List) [function]
     rule listToSet(ListItem(K:K) L:List) => SetItem(K) listToSet(L)
     rule listToSet(.List) => .Set

     rule FunctionType(T:Type) => T
          [structural]

     // "Prototype scope."
     rule <k> Prototype(T:Type, list(L:List), Var:Bool)
               => pushBlock ~> Prototype'(T, L, .List, Var)
          ...</k>
          <curr-function> X:CId => prototype(X) </curr-function>
          [structural]

     // We "declare" function prototype parameters in the order they appear,
     // from left to right. This is mostly to (somewhat) handle VLA parameters.
     syntax KItem ::= "Prototype'" "(" Type "," List "," List "," Bool ")"
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
          requires X =/=K #NoName
          [structural]
     rule typedDeclaration(DT:Type, X:CId)
          ~> Prototype'(T:Type, L1:List, L2:List, Var:Bool)
          => Prototype'(T, L1, L2 ListItem(typedDeclaration(adjustParam(DT), X)), Var)
          requires X ==K #NoName
          [structural]
     rule Prototype'(T:Type, .List, L2:List, Var:Bool)
          => Prototype''(T, L2, Var)
          [structural]

     syntax KItem ::= "Prototype''" "(" Type "," List "," Bool ")"
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
          => pushTypeDown(T, makeOldStyleFunctionType(L))
          [structural]

     rule pushTypeDown(t(S:Set, arrayType(T:Type, N:CSize)), Lbl:K)
          => t(S, arrayType(pushTypeDown(T, Lbl), N))
     rule pushTypeDown(t(S:Set, variableLengthArrayType(T:Type, N:K)), Lbl:K)
          => t(S, variableLengthArrayType(pushTypeDown(T, Lbl), N))
     rule pushTypeDown(t(S:Set, incompleteArrayType(T:Type)), Lbl:K)
          => t(S, incompleteArrayType(pushTypeDown(T, Lbl)))
     rule pushTypeDown(t(S:Set, pointerType(T:Type)), Lbl:K)
          => t(S, pointerType(pushTypeDown(T, Lbl)))
     rule pushTypeDown(t(S:Set, functionType(T:Type, L:List)), Lbl:K)
          => t(S, functionType(pushTypeDown(T, Lbl), L))
     rule pushTypeDown(t(S:Set, structType(X:StructId)), Lbl:K)
          => applyTypeFunction(Lbl, t(S, structType(X)))
     rule pushTypeDown(t(S:Set, unionType(X:StructId)), Lbl:K)
          => applyTypeFunction(Lbl, t(S, unionType(X)))
     rule pushTypeDown(t(S:Set, enumType(X:CId)), Lbl:K)
          => applyTypeFunction(Lbl, t(S, enumType(X)))

     rule pushTypeDown(t(S:Set, typedefType(_, t(S':Set, T:K))), Lbl:K)
          => applyTypeFunction(Lbl, t(S S', T))

     rule pushTypeDown(T:Type, Lbl:K) => applyTypeFunction(Lbl, T)
          requires isBasicType(T)

     rule applyTypeFunction(makeFunctionType(L:List), T:Type)
          => t(getSpecifiers(T),
               functionType(stripSpecifiers(T), giveNamesToArgs(L)))

     rule applyTypeFunction(makeOldStyleFunctionType(L:List), T:Type)
          => t(getSpecifiers(T) SetItem(oldStyle),
               functionType(stripSpecifiers(T), giveNamesToArgs(L)))

     rule applyTypeFunction(makePointerType(Quals:Set), T:Type)
          => t(Quals getSpecifiers(T),
               pointerType(stripSpecifiers(T)))

     rule applyTypeFunction(makeIncompleteArrayType, T:Type)
          => t(getSpecifiers(T),
               incompleteArrayType(stripSpecifiers(T)))

     rule applyTypeFunction(makeArrayType(N:CSize, Specifier(list(ListItem(Static)))), T:Type)
          => t(getSpecifiers(T) SetItem(arrayStatic(N)),
               arrayType(stripSpecifiers(T), N))
          [structural, anywhere]
     // TODO(chathhorn): Other qualifiers?
     rule applyTypeFunction(makeArrayType(N:K, Specifier(list(.List))), T:Type)
          => t(getSpecifiers(T), arrayType(stripSpecifiers(T), N))
          requires isInt(N) ==K true
          [structural, anywhere]
     // TODO(chathhorn): better VLA support (need to keep around the
     // un-evaluated size expression).
     rule applyTypeFunction(makeArrayType(N:K, Specifier(list(.List))), T:Type)
          => t(getSpecifiers(T), variableLengthArrayType(stripSpecifiers(T), N))
          requires isInt(N) =/=K true
          [structural, anywhere]

     syntax List ::= giveNamesToArgs(List) [function]
     syntax List ::= "giveNamesToArgs-aux" "(" Int "," List ")" [function]

     rule giveNamesToArgs(L:List) => giveNamesToArgs-aux(0, L)
     rule giveNamesToArgs-aux(N:Int,
               (ListItem(typedDeclaration(T:Type, X:CId)) L:List))
          => ListItem(typedDeclaration(T, X))
               giveNamesToArgs-aux(N, L)
          requires X =/=K #NoName
          [structural]
     rule giveNamesToArgs-aux(N:Int,
               (ListItem(typedDeclaration(T:Type, X:CId)) L:List))
          => ListItem(typedDeclaration(T, #NoName(N)))
               giveNamesToArgs-aux(N +Int 1, L)
          requires X ==K #NoName
          [structural]
     rule giveNamesToArgs-aux(_, ListItem(variadic))
          => ListItem(variadic)
          [structural]
     rule giveNamesToArgs-aux(_, .List)
          => .List
          [structural]

     rule <k> JustBase => T ...</k>
          <decl-type-holder> T:Type => .K ...</decl-type-holder>
          [structural]

     syntax KItem ::= "extractActualTypeFreezer"
     rule <k> DeclType(T:Type, K:K) => K:K ~> extractActualTypeFreezer ...</k>
          <decl-type-holder> (.K => T) ...</decl-type-holder>
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
          requires isBasicType(T)
     rule extractActualType(t(S:Set, enumType(X:CId)))
          => t(S, enumType(X))
     rule extractActualType(t(S:Set, structType(X:StructId)))
          => t(S, structType(X))
     rule extractActualType(t(S:Set, unionType(X:StructId)))
          => t(S, unionType(X))
     rule extractActualType(t(S:Set, arrayType(T:Type, N:CSize)))
          => t(S, arrayType(extractActualType(T), N))
     rule extractActualType(t(S:Set, variableLengthArrayType(T:Type, N:K)))
          => t(S, variableLengthArrayType(extractActualType(T), N))
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

     syntax KItem ::= NameAndType(CId, K) [strict(2)]

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
          requires notBool isTypedDeclaration(T)
               andBool notBool isFunctionType(T)
               andBool notBool isArrayType(T)

endmodule
