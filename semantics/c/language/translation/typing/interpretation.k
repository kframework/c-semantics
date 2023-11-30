module C-TYPING-INTERPRETATION-SYNTAX
     imports BASIC-K
     imports SET
     imports COMMON-SORTS
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS

     syntax KItem ::= pushTypeDown(Type, KItem)
     syntax KItem ::= makeArrayType(Set, Set, RValue)

     syntax List ::= numberUnnamed(List) [function]
endmodule

module C-TYPING-INTERPRETATION
     imports C-TYPING-INTERPRETATION-SYNTAX
     imports C-CONFIGURATION
     imports COLLECTIONS
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
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-SYNTAX

     // Rules that use specifier should be careful to use extractActualType if
     // going to be used in a typed name.
     syntax Type ::= extractActualType(Type) [function]

     rule Specifier(list(L:List)) => canonicalizeType(L)
          [structural]

     syntax KItem ::= BitFieldType(KItem, KItem) [strict]
     rule BitFieldType(t(Qs::Quals, Mods::Set, T:BitfieldFieldType), tv(N:Int, ut(SetItem(IntegerConstant) _, _)))
          => t(Qs, Mods, bitfieldType(T, N)) [structural]
     rule BitFieldType(t(Qs::Quals, Mods::Set, T:SimpleTypedefType) => extractActualType(t(Qs, Mods, T)), _)
     rule (.K => CV("CTI3", "The width of a bit field shall be an integer constant expression."))
          ~> BitFieldType(_, tv(N:CValue, T::UType))
          requires notBool fromConstantExpr(T) orBool isInt(N) =/=K true
     rule (.K => IMPL("CTI4", "Bit-field with type other than signed int, unsigned int, or _Bool."))
          ~> BitFieldType(t(_, _, T'::SimpleType), tv(N:CValue, T::UType))
          requires fromConstantExpr(T) andBool isInt(N)
               andBool notBool isBitfieldFieldType(T')
               andBool notBool isSimpleTypedefType(T')

     syntax KItem ::= makeFunctionType(Set, List)
     syntax KItem ::= makeOldStyleFunctionType(Set, List)
     syntax KItem ::= makePointerType(Set)
     syntax KItem ::= makeIncompleteArrayType(Set, Set)

     context ArrayType(_, (HOLE:KItem => reval(HOLE)), _) [ndheat, result(RValue)]
     rule ArrayType(_, (ExpLoc(V:RValue, _) => V), _)
     rule ArrayType(T:Type, tv(N:Int, T'::UType), Specifier(list(Specs::List)))
          => pushTypeDown(T, makeArrayType(.Set, staticToArrayStatic(N, listToSet(Specs)), tv(N, T')))
          requires N >Int 0 andBool notBool isFlexibleType(T)
     rule ArrayType(T:Type, UnspecifiedSizeExpression(), Specifier(list(Specs::List)))
          => pushTypeDown(T, makeArrayType(.Set, listToSet(Specs), UnspecifiedSizeExpression()))
          requires notBool isFlexibleType(T)
          [structural]
     rule ArrayType(T:Type, N:RValue, Specifier(list(Specs::List)))
          => pushTypeDown(T, makeArrayType(.Set, listToSet(Specs), N))
          requires isHold(N) andBool notBool isFlexibleType(T) // VLAs
          [structural]
     rule ArrayType(T:Type, emptyValue, Specifier(list(Specs::List)))
          => pushTypeDown(T, makeIncompleteArrayType(.Set, listToSet(Specs)))
          requires notBool isFlexibleType(T)
          [structural]
     rule (.K => UNDEF("CTI1", "Arrays must have integer length."))
          ~> ArrayType(_, tv(_:Float, _), _)
          [structural]
     rule (.K => CV("CTI2", "Arrays must have positive length."))
          ~> ArrayType(_:Type, tv(Len:Int, _), _)
          requires Len <=Int 0
          [structural]
     rule (.K => CV("CTI5", "Structs containing a flexible array member must not be array elements."))
          ~> ArrayType(T:Type, _, _)
          requires isFlexibleType(T)
          [structural]

     syntax Set ::= staticToArrayStatic(Int, Set) [function]
     rule staticToArrayStatic(N::Int, S::Set) => SetItem(arrayStatic(N)) (S -Set SetItem(Static()))
          requires Static() in S
     rule staticToArrayStatic(_, S::Set) => S [owise]

     rule PointerType(Specifier(list(Mods:List)), T:Type)
          => pushTypeDown(T, makePointerType(listToSet(Mods)))
          [structural]

     rule FunctionType(T:Type) => T
          [structural]

     // "Prototype scope."
     rule (.K => elaborate(scope(prototypeScope, Prototype'(T, L, .List, Var))))
          ~> Prototype(T:Type, list(L:List), Var:Bool)
     rule elaborateDone(T:Type) ~> Prototype(_, _, _) => T

     // We "declare" function prototype parameters in the order they appear,
     // from left to right. This is mostly to (somewhat) handle VLA parameters.
     syntax KItem ::= "Prototype'" "(" Type "," List "," List "," Bool ")"
     rule Prototype'(T:Type, ListItem(K:KItem) L1:List, L2:List, Var:Bool)
          => K ~> Prototype'(T, L1, L2, Var)
     rule t(Qs::Quals, Mods::Set, ST:SimpleType)
          ~> Prototype'(T::Type, L1::List, L2::List, Var::Bool)
          => Prototype'(T, L1, L2 ListItem(adjustParam(t(Qs, Mods, ST))), Var)
     rule typedDeclaration(DT:Type, X:CId)
          ~> Prototype'(T:Type, L1:List, L2:List, Var:Bool)
          => declare(typedDeclaration(adjustParam(DT), X), NoInit())
          ~> Prototype'(T, L1, L2 ListItem(typedDeclaration(adjustParam(DT), X)), Var)
     rule Prototype'(T:Type, .List, L:List, false)
          => setElab(pushTypeDown(T, makeFunctionType(.Set, L)))
     rule Prototype'(T:Type, .List, L:List, true)
          => setElab(pushTypeDown(T, makeFunctionType(.Set, L ListItem(variadic))))

     syntax KItem ::= setElab(KItem) [strict]
     rule <k> setElab(V:KResult) => .K ...</k>
          <elab> _ => V </elab>

     rule NoPrototype(T:Type, krlist(L:List), false)
          => pushTypeDown(T, makeOldStyleFunctionType(.Set, adjustParams'(L)))

     rule pushTypeDown(t(... st: _:SimpleBasicType) #as T::Type, Lbl::KItem) => applyTypeFunction(Lbl, T)

     rule pushTypeDown(t(quals(Qs::Set), Mods::Set, arrayType(T::Type, N::Int)), Lbl::KItem)
          => applyTypeFunction(makeArrayType(Qs Mods, .Set, tv(N, utype(int))), pushTypeDown(T, Lbl))
     rule pushTypeDown(t(quals(Qs::Set), Mods::Set, unspecifiedArrayType(T::Type)), Lbl::KItem)
          => applyTypeFunction(makeArrayType(Qs Mods, .Set, UnspecifiedSizeExpression()), pushTypeDown(T, Lbl))
     rule pushTypeDown(t(quals(Qs::Set), Mods::Set, variableLengthArrayType(T::Type, N::RValue)), Lbl::KItem)
          => applyTypeFunction(makeArrayType(Qs Mods, .Set, N), pushTypeDown(T, Lbl))

     rule pushTypeDown(t(quals(Qs::Set), Mods::Set, incompleteArrayType(T::Type)), Lbl::KItem)
          => applyTypeFunction(makeIncompleteArrayType(Qs Mods, .Set), pushTypeDown(T, Lbl))
     rule pushTypeDown(t(quals(Qs::Set), Mods::Set, pointerType(T::Type)), Lbl::KItem)
          => applyTypeFunction(makePointerType(Qs Mods), pushTypeDown(T, Lbl))

     rule pushTypeDown(t(quals(Qs::Set), Mods::Set, functionType(T::UType, L:List)), Lbl::KItem)
          => applyTypeFunction(makeFunctionType(Qs Mods, L), pushTypeDown(type(T), Lbl))
     rule pushTypeDown(t(quals(Qs::Set), Mods::Set, functionType'(T::Type, L:List)), Lbl::KItem)
          => applyTypeFunction(makeFunctionType(Qs Mods, L), pushTypeDown(T, Lbl))

     rule pushTypeDown(t(Qs::Quals, Mods::Set, structType(X::TagId)), Lbl::KItem)
          => applyTypeFunction(Lbl, t(Qs, Mods, structType(X)))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, unionType(X::TagId)), Lbl::KItem)
          => applyTypeFunction(Lbl, t(Qs, Mods, unionType(X)))
     rule pushTypeDown(t(Qs::Quals, Mods::Set, typedefType(X:CId, T::Type)), Lbl::KItem)
          => applyTypeFunction(Lbl, t(Qs, Mods, typedefType(X, T)))

     syntax KItem ::= applyTypeFunction(K, KItem) [strict(2)]
     syntax SimpleType ::= "functionType'" "(" Type "," List ")"
     rule applyTypeFunction(makeFunctionType(Mods::Set, L:List), t(...) #as T::Type)
          => addMods(Set2List(Mods getSpecifiers(T)), type(functionType'(stripSpecifiers(T), numberUnnamed(L))))
     rule applyTypeFunction(makeOldStyleFunctionType(Mods::Set, L:List), t(...) #as T::Type)
          => addMods(Set2List(Mods getSpecifiers(T) SetItem(oldStyle)), type(functionType'(stripSpecifiers(T), numberUnnamed(L))))
     rule applyTypeFunction(makePointerType(Mods::Set), t(...) #as T::Type)
          => addMods(Set2List(Mods getSpecifiers(T)), type(pointerType(stripSpecifiers(T))))

     rule applyTypeFunction(makeIncompleteArrayType(Mods::Set, ParamMods::Set), t(...) #as T::Type)
          => setQuals(ParamMods, addMods(Set2List(Mods getSpecifiers(T) (ParamMods -Set typeQualifiers)), type(incompleteArrayType(stripSpecifiers(T)))))
     rule applyTypeFunction(makeArrayType(Mods::Set, ParamMods::Set, tv(N:Int, _)), t(...) #as T::Type)
          => setQuals(ParamMods, addMods(Set2List(Mods getSpecifiers(T) (ParamMods -Set typeQualifiers)), type(arrayType(stripSpecifiers(T), N))))
     rule applyTypeFunction(makeArrayType(Mods::Set, ParamMods::Set, UnspecifiedSizeExpression()), t(...) #as T::Type)
          => setQuals(ParamMods, addMods(Set2List(Mods getSpecifiers(T) (ParamMods -Set typeQualifiers)), type(unspecifiedArrayType(stripSpecifiers(T)))))
     rule applyTypeFunction(makeArrayType(Mods::Set, ParamMods::Set, N:RValue), t(...) #as T::Type)
          => setQuals(ParamMods, addMods(Set2List(Mods getSpecifiers(T) (ParamMods -Set typeQualifiers)), type(variableLengthArrayType(stripSpecifiers(T), N))))
          requires isHold(N)

     syntax KItem ::= setQuals(Set, KItem) [strict(2)]

     rule setQuals(M::Set, t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs +Quals toQuals(M), Mods, T)

     rule <k> JustBase() => T ...</k>
          <decl-type-holder> T:Type => .K ...</decl-type-holder>
          [structural]

     rule <k> DeclType(T:Type, K:KItem) => extractActualTypeFreezer(K) ...</k>
          <decl-type-holder> (.K => T) ...</decl-type-holder>
          [structural]

     syntax KItem ::= extractActualTypeFreezer(KItem) [strict]
     rule extractActualTypeFreezer(t(...) #as T::Type) => extractActualType(T)
          [structural]

     // The K will resolve to a type, so throw it away.
     rule OnlyTypedef(K:KItem) => K ~> discard
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

     syntax KItem ::= NameAndType(CId, KItem) [strict(2)]

     rule SingleName(T:Type, Name(X:CId, K:KItem, list(Attrs::List)))
          => NameAndType(X, addMods(Attrs, DeclType(T, K)))
          [structural]
     rule FieldGroup(T:Type, list(ListItem(C:KItem) ListItem(C':KItem) L:List))
          => list(ListItem(FieldGroup(T, list(ListItem(C))))
               ListItem(FieldGroup(T, list(ListItem(C') L))))
          [structural]

     rule FieldGroup(T:Type, list(ListItem(FieldName(Name(X:CId, K:KItem, list(Attrs::List))))))
          => NameAndType(X, addMods(Attrs, DeclType(T, K)))
          [structural]

     rule FieldGroup(T:Type, list(ListItem(BitFieldName(Name(X:CId, K:KItem, list(Attrs::List)), Size:KItem))))
          => NameAndType(X, addMods(Attrs, DeclType(T, BitFieldType(K, Size))))
          [structural]

     context Typedef(NameGroup(HOLE:KItem, _))

     rule Typedef(NameGroup(T:Type, list(ListItem(K:KItem) L:List)))
          => defineType(SingleName(T, K)) ~> Typedef(NameGroup(T, list(L)))
          [structural]
     rule Typedef(NameGroup(_:Type, list(.List))) => .K
          [structural]

     syntax KItem ::= defineType(KItem) [strict]
     rule defineType(typedDeclaration(T:Type, X:CId))
          => typedef(X, T)
          [structural]

     rule numberUnnamed(ListItem(typedDeclaration(T::Type, _:NoName)) Fs::List)
          => ListItem(typedDeclaration(T, #NoName(!N:Int))) numberUnnamed(Fs)
     rule numberUnnamed(ListItem(K:KItem) Fs::List) => ListItem(K) numberUnnamed(Fs) [owise]
     rule numberUnnamed(.List) => .List

endmodule
