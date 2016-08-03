module C-TYPING-INTERPRETATION-SYNTAX
     imports BASIC-K
     imports C-DYNAMIC-SORTS

     syntax Type ::= pushTypeDown(Type, K) [function]
     syntax KItem ::= makeArrayType(RValue, K)
endmodule

module C-TYPING-INTERPRETATION
     imports C-TYPING-INTERPRETATION-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports COMMON-SORTS
     imports COMPAT-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-CANONICALIZATION-SYNTAX
     imports C-TYPING-SYNTAX

     // Rules that use specifier should be careful to use extractActualType if
     // going to be used in a typed name.
     syntax Type ::= extractActualType(Type) [function]

     rule Specifier(list(L:List)) => canonicalizeType(L)
          [structural]

     syntax KItem ::= BitFieldType(K, K) [strict]
     rule BitFieldType(t(Qs::Quals, Mods::Set, T:BitfieldFieldType), tv(N:Int, ut(SetItem(IntegerConstant) _, _)))
          => t(Qs, Mods, bitfieldType(T, N)) [structural]
     rule BitFieldType(t(Qs::Quals, Mods::Set, T:SimpleTypedefType) => extractActualType(t(Qs, Mods, T)), _)
     rule (.K => CV("CTI3", "The width of a bit field shall be an integer constant expression.", "6.7.2.1:4"))
          ~> BitFieldType(_, tv(N:CValue, T::UType))
          requires notBool fromConstantExpr(T) orBool isInt(N) =/=K true
     rule (.K => IMPL("CTI4", "Bit-field with type other than signed int, unsigned int, or _Bool.", "6.7.2.1:5, J.3.9:1 item 2"))
          ~> BitFieldType(t(_, _, T'::SimpleType), tv(N:CValue, T::UType))
          requires fromConstantExpr(T) andBool isInt(N)
               andBool notBool isBitfieldFieldType(T')
               andBool notBool isSimpleTypedefType(T')

     syntax KItem ::= makeFunctionType(List)
     syntax KItem ::= makeOldStyleFunctionType(List)
     syntax KItem ::= makePointerType(Set)
     syntax KItem ::= "makeIncompleteArrayType"

     context ArrayType(_, (HOLE:KItem => reval(HOLE)), _) [ndheat, result(RValue)]
     rule ArrayType(T:Type, tv(N:Int, T'::UType), Spec:K)
          => pushTypeDown(T, makeArrayType(tv(N, T'), Spec))
          requires N >Int 0
          [structural]
     rule ArrayType(T:Type, UnspecifiedSizeExpression(), Spec:K)
          => pushTypeDown(T, makeArrayType(UnspecifiedSizeExpression(), Spec))
          [structural]
     rule ArrayType(T:Type, N:RValue, Spec:K)
          => pushTypeDown(T, makeArrayType(N, Spec))
          requires isHold(N) // VLAs
          [structural]
     rule ArrayType(T:Type, emptyValue, _)
          => pushTypeDown(T, makeIncompleteArrayType)
          [structural]
     rule (.K => UNDEF("CTI1", "Arrays must have integer length.", "6.6:6, J.2:1 item 55"))
          ~> ArrayType(_, tv(_:Float, _), _)
          [structural]
     rule (.K => CV("CTI2", "Arrays must have positive length.", "6.7.6.2:1"))
          ~> ArrayType(_:Type, tv(Len:Int, _), _)
          requires Len <=Int 0
          [structural]

     rule PointerType(Specifier(list(Mods:List)), T:Type)
          => pushTypeDown(T, makePointerType(listToSet(Mods)))
          [structural]

     syntax Set ::= listToSet(List) [function]
     rule listToSet(ListItem(K:K) L:List) => SetItem(K) listToSet(L)
     rule listToSet(.List) => .Set

     rule FunctionType(T:Type) => T
          [structural]

     // "Prototype scope."
     rule (.K => elaborate(scope(prototypeScope, Prototype'(T, L, .List, Var))))
          ~> Prototype(T:Type, list(L:List), Var:Bool)
     rule elaborateDone(T:Type) ~> Prototype(_, _, _) => T

     // We "declare" function prototype parameters in the order they appear,
     // from left to right. This is mostly to (somewhat) handle VLA parameters.
     syntax KItem ::= "Prototype'" "(" Type "," List "," List "," Bool ")"
     rule Prototype'(T:Type, ListItem(K:K) L1:List, L2:List, Var:Bool)
          => K ~> Prototype'(T, L1, L2, Var)
     rule t(Qs::Quals, Mods::Set, ST:SimpleType)
          ~> Prototype'(T::Type, L1::List, L2::List, Var::Bool)
          => Prototype'(T, L1, L2 ListItem(adjustParam(t(Qs, Mods, ST))), Var)
     rule typedDeclaration(DT:Type, X:CId)
          ~> Prototype'(T:Type, L1:List, L2:List, Var:Bool)
          => declare(typedDeclaration(adjustParam(DT), X), NoInit())
          ~> Prototype'(T, L1, L2 ListItem(typedDeclaration(adjustParam(DT), X)), Var)
     rule <k> Prototype'(T:Type, .List, L:List, false) => .K ...</k>
          <elab> _ => pushTypeDown(T, makeFunctionType(L)) </elab>
     rule <k> Prototype'(T:Type, .List, L:List, true) => .K ...</k>
          <elab> _ => pushTypeDown(T, makeFunctionType(L ListItem(variadic))) </elab>

     rule NoPrototype(T:Type, krlist(L:List), false)
          => pushTypeDown(T, makeOldStyleFunctionType(L))

     rule pushTypeDown(T:BasicType, Lbl:K) => applyTypeFunction(Lbl, T)
     rule pushTypeDown(t(Qs::Quals, Mods::Set, arrayType(T::Type, N::Int)), Lbl:K)
          => t(Qs, Mods, arrayType(pushTypeDown(T, Lbl), N))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, unspecifiedArrayType(T::Type)), Lbl:K)
          => t(Qs, Mods, unspecifiedArrayType(pushTypeDown(T, Lbl)))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, variableLengthArrayType(T::Type, N:K)), Lbl:K)
          => t(Qs, Mods, variableLengthArrayType(pushTypeDown(T, Lbl), N))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, incompleteArrayType(T::Type)), Lbl:K)
          => t(Qs, Mods, incompleteArrayType(pushTypeDown(T, Lbl)))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, pointerType(T::Type)), Lbl:K)
          => t(Qs, Mods, pointerType(pushTypeDown(T, Lbl)))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, functionType'(T::Type, L:List)), Lbl:K)
          => t(Qs, Mods, functionType'(pushTypeDown(T, Lbl), L))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, structType(X:StructId)), Lbl:K)
          => applyTypeFunction(Lbl, t(Qs, Mods, structType(X)))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, unionType(X:StructId)), Lbl:K)
          => applyTypeFunction(Lbl, t(Qs, Mods, unionType(X)))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, typedefType(X:CId, T::Type)), Lbl:K)
          => applyTypeFunction(Lbl, t(Qs, Mods, typedefType(X, T)))

     syntax Type ::= applyTypeFunction(K, Type) [function]
     syntax SimpleType ::= "functionType'" "(" Type "," List ")"
     rule applyTypeFunction(makeFunctionType(L:List), T::Type)
          => t(noQuals, getSpecifiers(T),
               functionType'(stripSpecifiers(T), giveNamesToArgs(L)))

     rule applyTypeFunction(makeOldStyleFunctionType(L:List), T::Type)
          => t(noQuals, getSpecifiers(T) SetItem(oldStyle),
               functionType'(stripSpecifiers(T), giveNamesToArgs(L)))

     rule applyTypeFunction(makePointerType(Mods::Set), T::Type)
          => t(toQuals(Mods), (Mods -Set typeQualifiers) getSpecifiers(T), pointerType(stripSpecifiers(T)))

     rule applyTypeFunction(makeIncompleteArrayType, T::Type)
          => t(noQuals, getSpecifiers(T), incompleteArrayType(stripSpecifiers(T)))

     rule applyTypeFunction(makeArrayType(tv(N:Int, T'::UType), Specifier(list(ListItem(Static())))), T::Type)
          => t(noQuals, getSpecifiers(T) SetItem(arrayStatic(N)), arrayType(stripSpecifiers(T), N))
     // TODO(chathhorn): Other qualifiers?
     rule applyTypeFunction(makeArrayType(tv(N:Int, _), Specifier(list(.List))), T::Type)
          => t(noQuals, getSpecifiers(T), arrayType(stripSpecifiers(T), N))
     rule applyTypeFunction(makeArrayType(UnspecifiedSizeExpression(), Specifier(list(.List))), T::Type)
          => t(noQuals, getSpecifiers(T), unspecifiedArrayType(stripSpecifiers(T)))
     rule applyTypeFunction(makeArrayType(N:RValue, Specifier(list(.List))), T::Type)
          => t(noQuals, getSpecifiers(T), variableLengthArrayType(stripSpecifiers(T), N))
          requires isHold(N)

     syntax List ::= giveNamesToArgs(List) [function]
     syntax List ::= "giveNamesToArgs-aux" "(" Int "," List ")" [function]

     rule giveNamesToArgs(L:List) => giveNamesToArgs-aux(0, L)
     rule giveNamesToArgs-aux(N:Int, ListItem(K::K) L:List)
          => ListItem(nameArg(N, K)) giveNamesToArgs-aux(N +Int 1, L)
     rule giveNamesToArgs-aux(_, .List) => .List

     syntax K ::= nameArg(Int, K) [function]
     rule nameArg(N:Int, typedDeclaration(T:Type, #NoName))
          => typedDeclaration(T, #NoName(N))
     rule nameArg(_, T::K) => T [owise]

     rule <k> JustBase() => T ...</k>
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

     rule extractActualType(T::Type) => T [owise]
     rule extractActualType(t(Qs::Quals, S::Set, arrayType(T:Type, N:Int)))
          => t(Qs, S, arrayType(extractActualType(T), N))
     rule extractActualType(t(Qs::Quals, S::Set, unspecifiedArrayType(T:Type)))
          => t(Qs, S, unspecifiedArrayType(extractActualType(T)))
     rule extractActualType(t(Qs::Quals, S::Set, variableLengthArrayType(T:Type, N:K)))
          => t(Qs, S, variableLengthArrayType(extractActualType(T), N))
     rule extractActualType(t(Qs::Quals, S::Set, incompleteArrayType(T:Type)))
          => t(Qs, S, incompleteArrayType(extractActualType(T)))
     rule extractActualType(t(Qs::Quals, S::Set, functionType(T::UType, L:List)))
          => t(Qs, S, functionType(utype(extractActualType(type(T))), L))
     rule extractActualType(t(Qs::Quals, S::Set, functionType'(T::Type, L:List)))
          => t(Qs, S, functionType(utype(extractActualType(T)), L))
     rule extractActualType(t(Qs::Quals, S::Set, pointerType(T:Type)))
          => t(Qs, S, pointerType(extractActualType(T)))
     rule extractActualType(t(Qs::Quals, S::Set, typedefType(_, t(Qs'::Quals, S'::Set, T::SimpleType))))
          => extractActualType(addQualifiers(Qs, t(Qs', S S', T)))

     syntax KItem ::= NameAndType(CId, K) [strict(2)]

     rule SingleName(T:Type, Name(X:CId, K:K))
          => NameAndType(X, DeclType(T, K))
          [structural]
     rule FieldGroup(K:KResult, list(ListItem(C:K) ListItem(C':K) L:List))
          => list(ListItem(FieldGroup(K, list(ListItem(C))))
               ListItem(FieldGroup(K, list(ListItem(C') L))))
          [structural]

     rule FieldGroup(T:Type, list(ListItem(FieldName(Name(X:CId, K:K)))))
          => NameAndType(X, DeclType(T, K))
          [structural]

     rule FieldGroup(T:Type, list(ListItem(BitFieldName(Name(X:CId, K:K), Size:K))))
          => NameAndType(X, DeclType(T, BitFieldType(K, Size)))
          [structural]

     context Typedef(NameGroup(HOLE:KItem, _))

     rule Typedef(NameGroup(T:Type, list(ListItem(K:K) L:List)))
          => defineType(SingleName(T, K)) ~> Typedef(NameGroup(T, list(L)))
          [structural]
     rule Typedef(NameGroup(_:Type, list(.List))) => .K
          [structural]

     syntax KItem ::= defineType(K) [strict]
     rule defineType(typedDeclaration(T:Type, X:CId))
          => typedef(X, T)
          [structural]

     // Turn array and function types into pointers.
     syntax Type ::= adjustParam(Type) [function]
     rule adjustParam(t(Qs::Quals, Mods::Set, functionType(R::UType, Params::List)))
          => type(pointerType(t(Qs, Mods, functionType(R, Params))))
     rule adjustParam(T:ArrayType)
          => t(getQualifiers(T), getModifiers(T), pointerType(innerType(T)))
     rule adjustParam(T::Type) => T [owise]

endmodule
