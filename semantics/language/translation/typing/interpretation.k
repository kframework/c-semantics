module C-TYPING-INTERPRETATION
     imports C-ABSTRACT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-CANONICALIZATION-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     // Rules that use specifier should be careful to use extractActualType if
     // going to be used in a typed name.
     syntax Type ::= extractActualType(Type) [function]

     syntax KItem ::= BitFieldType(K, K) [strict]

     rule Specifier(list(L:List)) => canonicalizeType(L)
          [structural]

     rule BitFieldType(T:Type, tv(N:Int, t(SetItem(IntegerConstant) _:Set, _)))
          => t(.Set, bitfieldType(T, N)) [structural]

     rule (.K => CV("CTI3", "The width of a bit field shall be an integer constant expression.", "6.7.2.1:4"))
          ~> BitFieldType(_, tv(N:CValue, T:Type))
          requires notBool fromConstantExpr(T) orBool isInt(N) =/=K true

     syntax KItem ::= makeFunctionType(List)
     syntax KItem ::= makeOldStyleFunctionType(List)
     syntax KItem ::= makePointerType(Set)
     syntax KItem ::= "makeIncompleteArrayType"
     syntax KItem ::= makeArrayType(RValue, K)
     syntax Type ::= pushTypeDown(Type, K) [function]

     context ArrayType(_, (HOLE => reval(HOLE)), _) [ndheat, result(RValue)]
     rule ArrayType(T:Type, tv(N:Int, T':Type), Spec:K)
          => pushTypeDown(T, makeArrayType(tv(N, T'), Spec))
          requires N >Int 0
          [structural]
     rule ArrayType(T:Type, N:RValue, Spec:K)
          => pushTypeDown(T, makeArrayType(N, Spec))
          requires isHold(N) // VLAs.
          [structural]
     rule ArrayType(T:Type, emptyValue, _)
          => pushTypeDown(T, makeIncompleteArrayType)
          [structural]
     rule (.K => UNDEF("CTI1", "Arrays must have integer length.", "6.6:6, J.2:1 item 55"))
          ~> ArrayType(_, tv(_:Float, _), _)
          [structural]
     rule (_:ErrorExit => .K) ~> ArrayType(_, tv((V:Float => Float2Int(V)), _), _)
          requires isErrorRecovery
     rule (.K => CV("CTI2", "Arrays must have positive length.", "6.7.6.2:1"))
          ~> ArrayType(_:Type, tv(Len:Int, _:Type), _)
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
     rule (.K => elaborate(scope(prototypeScope,
               Prototype'(T, L, .List, Var))))
          ~> Prototype(T:Type, list(L:List), Var:Bool)
     rule elaborateDone(T:Type) ~> Prototype(_, _, _) => T

     // We "declare" function prototype parameters in the order they appear,
     // from left to right. This is mostly to (somewhat) handle VLA parameters.
     syntax KItem ::= "Prototype'" "(" Type "," List "," List "," Bool ")"
     rule Prototype'(T:Type, ListItem(K:K) L1:List, L2:List, Var:Bool)
          => K ~> Prototype'(T, L1, L2, Var)
     rule t(Mods:Set, ST:SimpleType)
          ~> Prototype'(T:Type, L1:List, L2:List, Var:Bool)
          => Prototype'(T, L1, L2 ListItem(adjustParam(t(Mods, ST))), Var)
     syntax SymBase ::= vla(CId)
     rule typedDeclaration(DT:Type, X:CId)
          ~> Prototype'(T:Type, L1:List, L2:List, Var:Bool)
          => declareInternalVariable(X, adjustParam(DT), NoInit)
          ~> Prototype'(T, L1, L2 ListItem(typedDeclaration(adjustParam(DT), X)), Var)
          requires X =/=K #NoName
     rule typedDeclaration(DT:Type, X:CId)
          ~> Prototype'(T:Type, L1:List, L2:List, Var:Bool)
          => Prototype'(T, L1, L2 ListItem(typedDeclaration(adjustParam(DT), X)), Var)
          requires X ==K #NoName
     rule <k> Prototype'(T:Type, .List, L:List, false) => .K ...</k>
          <elab> _ => pushTypeDown(T, makeFunctionType(L)) </elab>
     rule <k> Prototype'(T:Type, .List, L:List, true) => .K ...</k>
          <elab> _ => pushTypeDown(T, makeFunctionType(L ListItem(variadic))) </elab>

     rule NoPrototype(T:Type, krlist(L:List), false)
          => pushTypeDown(T, makeOldStyleFunctionType(L))

     rule pushTypeDown(T:BasicType, Lbl:K) => applyTypeFunction(Lbl, T)
     rule pushTypeDown(t(S:Set, arrayType(T:Type, N:Int)), Lbl:K)
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
     rule pushTypeDown(t(S:Set, typedefType(X:CId, T:Type)), Lbl:K)
          => applyTypeFunction(Lbl, t(S, typedefType(X, T)))

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

     rule applyTypeFunction(makeArrayType(tv(N:Int, T':Type), Specifier(list(ListItem(Static)))), T:Type)
          => t(getSpecifiers(T) SetItem(arrayStatic(N)),
               arrayType(stripSpecifiers(T), N))
          requires notBool isHold(tv(N, T'))
     // TODO(chathhorn): Other qualifiers?
     rule applyTypeFunction(makeArrayType(tv(N:Int, T':Type), Specifier(list(.List))), T:Type)
          => t(getSpecifiers(T), arrayType(stripSpecifiers(T), N))
          requires notBool isHold(tv(N, T'))
     rule applyTypeFunction(makeArrayType(N:RValue, Specifier(list(.List))), T:Type)
          => t(getSpecifiers(T), variableLengthArrayType(stripSpecifiers(T), N))
          requires isHold(N)

     syntax List ::= giveNamesToArgs(List) [function]
     syntax List ::= "giveNamesToArgs-aux" "(" Int "," List ")" [function]

     rule giveNamesToArgs(L:List) => giveNamesToArgs-aux(0, L)
     rule giveNamesToArgs-aux(N:Int, ListItem(T:Type) L:List)
          => ListItem(nameArg(N, T)) giveNamesToArgs-aux(N +Int 1, L)
     rule giveNamesToArgs-aux(_, .List) => .List

     syntax Type ::= nameArg(Int, Type) [function]
     rule nameArg(N:Int, typedDeclaration(T:Type, #NoName))
          => typedDeclaration(T, #NoName(N))
     rule nameArg(_, T:Type) => T [owise]

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

     rule extractActualType(T:BasicType) => T
     rule extractActualType(t(S:Set, structType(X:StructId)))
          => t(S, structType(X))
     rule extractActualType(t(S:Set, unionType(X:StructId)))
          => t(S, unionType(X))
     rule extractActualType(t(S:Set, arrayType(T:Type, N:Int)))
          => t(S, arrayType(extractActualType(T), N))
     rule extractActualType(t(S:Set, variableLengthArrayType(T:Type, N:K)))
          => t(S, variableLengthArrayType(extractActualType(T), N))
     rule extractActualType(t(S:Set, incompleteArrayType(T:Type)))
          => t(S, incompleteArrayType(extractActualType(T)))
     rule extractActualType(t(S:Set, bitfieldType(T:Type, N:Int)))
          => t(S, bitfieldType(extractActualType(T), N))
     rule extractActualType(t(S:Set, functionType(T:Type, L:List)))
          => t(S, functionType(extractActualType(T), L))
     rule extractActualType(t(S:Set, pointerType(T:Type)))
          => t(S, pointerType(extractActualType(T)))
     rule extractActualType(t(S:Set, typedefType(_, t(S':Set, T::SimpleType))))
          => extractActualType(addQualifiers(S, t(S', T)))

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

     context Typedef(NameGroup(HOLE, _))

     rule Typedef(NameGroup(T:Type, list(ListItem(K:K) L:List)))
          => defineType(SingleName(T, K)) ~> Typedef(NameGroup(T, list(L)))
          [structural]
     rule Typedef(NameGroup(_:Type, list(.List))) => .K
          [structural]

     syntax KItem ::= defineType(K) [strict]
     rule defineType(typedDeclaration(T:Type, X:CId))
          => typedef(X, T)
          [structural]

     // Turn arrays into pointers in function parameters.
     syntax Type ::= adjustParam(Type) [function]
     rule adjustParam(typedDeclaration(T:Type, X:CId))
          => typedDeclaration(adjustParam(T), X)
     rule adjustParam(t(Mods:Set, functionType(R:Type, Params:List)))
          => t(.Set, pointerType(t(Mods, functionType(R, adjustParams(Params)))))
     rule adjustParam(t(Mods:Set, arrayType(T:Type, _)))
          => t(Mods, pointerType(T))
     rule adjustParam(t(Mods:Set, incompleteArrayType(T:Type)))
          => t(Mods, pointerType(T))
     rule adjustParam(t(Mods:Set, variableLengthArrayType(T:Type, _)))
          => t(Mods, pointerType(T))
     rule adjustParam(T:Type) => T
          requires notBool isTypedDeclaration(T)
               andBool notBool isArrayOrFunctionType(T)

     syntax List ::= adjustParams(List) [function]
     rule adjustParams(ListItem(T:Type) Params:List)
          => ListItem(adjustParam(T)) adjustParams(Params)
     rule adjustParams(.List) => .List

endmodule
