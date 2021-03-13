module C-TYPING-EXPR-SYNTAX
     imports BASIC-K

     syntax KItem ::= typeof(K)
endmodule

module C-TYPING-EXPR
     imports C-CONFIGURATION
     imports C-TYPING-EXPR-SYNTAX
     imports BOOL
     imports INT
     imports K-REFLECTION
     imports STRING
     imports COMPAT-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     context typeof(- (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(+ (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(! (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(~ (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(* (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(& (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(++ (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(-- (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) ++) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) --) [result(Type)]
     context typeof(SizeofExpression(HOLE:KItem => typeof(HOLE))) [result(Type)]

     context typeof((HOLE:KItem => typeof(HOLE)) * _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) / _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) % _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) + _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) - _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) == _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) != _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) & _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) ^ _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) | _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) && _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) || _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) << _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) >> _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) *= _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) /= _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) %= _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) += _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) -= _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) <<= _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) &= _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) ^= _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) |= _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) >>= _) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) := _) [result(Type)]
     context typeof(Call((HOLE:KItem => typeof(HOLE)), _)) [result(Type)]
     context typeof((HOLE:KItem => typeof(HOLE)) . _) [result(Type)]

     context typeof(_ * (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ / (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ % (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ + (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ - (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ == (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ != (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ & (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ ^ (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ | (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ && (HOLE:KItem => typeof(HOLE))) [result(Type)]
     context typeof(_ || (HOLE:KItem => typeof(HOLE))) [result(Type)]

     // primary expressions
     rule <k> typeof(X:CId => T:Type) ...</k>
          <types>... X |-> T ...</types>
     rule <k> typeof(X:CId => t(noQuals, SetItem(IntegerConstant), int)) ...</k>
          <enums>... X |-> _ ...</enums>

     rule typeof(T:Typed => type(T))
          requires notBool isType(T)

     rule typeof(StringLiteral(S:String)
          => type(arrayType(type(char), lengthString(S) +Int 1)))
     rule typeof(WStringLiteral(list(L:List))
          => type(arrayType(type(cfg:wcharut), size(L) +Int 1)))

     // postfix expressions
     rule typeof(Call(T:Type, _) => innerType(T))
          requires isFunctionType(T)
     rule typeof(Call((T:Type => innerType(T)), _))
          requires isPointerType(T)

     rule typeof((structOrUnionType #as T::Type) . F:CId => findFieldType(F, T))

     rule typeof(T:Type ++ => T)
     rule typeof(T:Type -- => T)

     context typeof(CompoundLiteral(_, (HOLE:KItem), _, _)) [result(Type)]
     syntax KItem ::= CompoundLiteralType(K)
     rule typeof(CompoundLiteral(_, T:Type, K:KItem, _) => CompoundLiteralType(DeclType(T, K)))
     context typeof(CompoundLiteralType(HOLE:KItem))
     rule typeof(CompoundLiteralType(T:Type) => T)

     syntax Type ::= tryPromote(Type) [function]
     rule tryPromote(integerType #as T::Type) => type(promote(utype(T)))
     rule tryPromote(T::Type) => T [owise]

     // prefix expressions
     rule typeof(++ T:Type => T += type(int))
     rule typeof(-- T:Type => T -= type(int))
     rule typeof(& T:Type => type(pointerType(T)))
     rule typeof(* T:Type => stripQualifiers(innerType(T)))
     rule typeof(+ T:Type => tryPromote(T))
     rule typeof(- T:Type => tryPromote(T))
     rule typeof(~ T:Type => tryPromote(T:Type))
     rule typeof(! _:Type => type(int))

     rule typeof(SizeofExpression(T:Type) => SizeofType(T, .K))
     rule typeof(SizeofType(T:Type, _)
          => t(noQuals, SetItem(IntegerConstant), cfg:sizeut))
          requires notBool isVariablyModifiedType(T)
     rule typeof(SizeofType(T:Type, _)
          => type(cfg:sizeut))
          requires isVariablyModifiedType(T)
     context typeof(SizeofType(HOLE:KItem, _))

     rule typeof(AlignofExpression(_)
          => t(noQuals, SetItem(IntegerConstant), cfg:sizeut))
     rule typeof(AlignofType(_, _)
          => t(noQuals, SetItem(IntegerConstant), cfg:sizeut))
     rule typeof(OffsetOf(_, _, _)
          => t(noQuals, SetItem(IntegerConstant), cfg:sizeut))
     rule typeof(TypesCompat(_, _, _, _)
          => t(noQuals, SetItem(IntegerConstant), cfg:sizeut))

     // cast expression
     context typeof(Cast((HOLE:KItem), _, _)) [result(Type)]
     context typeof(#Cast((HOLE:KItem), _, _, _:Bool)) [result(Type)]
     rule typeof(Cast(T:Type, K:KItem, V:K) => Cast(DeclType(T, K), V))
     rule typeof(#Cast(T:Type, K:KItem, V:K, E::Bool) => #Cast(DeclType(T, K), V, E))
     context typeof(Cast(HOLE:KItem, _))
     context typeof(#Cast(HOLE:KItem, _, _))
     rule typeof(#Cast(T:Type, _, _) => elideDeclParams(type(rvalType(T))))
     rule typeof(Cast(K1::K, K2::K) => #Cast(K1, K2, false))
     rule typeof(cast(T:UType, _, _) => elideDeclParams(type(T)))
     rule typeof(cast(T:UType, K:K) => cast(T, K, false))

     syntax Type ::= usualArithmeticConversion(Type, Type) [klabel(usualArithmeticConversionQ), function]
     rule usualArithmeticConversion(T::Type, T'::Type)
          => type(usualArithmeticConversion(utype(T), utype(T')))

     // multiplicative expressions
     rule typeof(T:Type * T':Type => usualArithmeticConversion(T, T'))
     rule typeof(T:Type / T':Type => usualArithmeticConversion(T, T'))
     rule typeof(T:Type % T':Type => usualArithmeticConversion(T, T'))

     // additive expressions
     rule typeof((arithmeticType #as T::Type) + (arithmeticType #as T'::Type) => usualArithmeticConversion(T, T'))
     rule typeof((arithmeticType #as T::Type) - (arithmeticType #as T'::Type) => usualArithmeticConversion(T, T'))
     rule typeof((pointerOrArrayType #as T::Type) + integerType => T)
     rule typeof(integerType + (pointerOrArrayType #as T::Type) => T)
     rule typeof((pointerOrArrayType #as T::Type) - integerType => T)
     rule typeof(pointerOrArrayType - pointerOrArrayType => type(cfg:ptrdiffut))

     // shift expressions
     rule typeof(T:Type << _ => tryPromote(T))
     rule typeof(T:Type >> _ => tryPromote(T))

     // relational expressions
     rule typeof(_ < _ => type(int))
     rule typeof(_ > _ => type(int))
     rule typeof(_ <= _ => type(int))
     rule typeof(_ >= _ => type(int))

     // equality expressions
     rule typeof(_ == _ => type(int))
     rule typeof(_ != _ => type(int))

     // bitwise expressions
     rule typeof(T:Type & T':Type => usualArithmeticConversion(T, T'))
     rule typeof(T:Type ^ T':Type => usualArithmeticConversion(T, T'))
     rule typeof(T:Type | T':Type => usualArithmeticConversion(T, T'))

     // logical expressions
     rule typeof(_ && _ => type(int))
     rule typeof(_ || _ => type(int))

     // conditional expression
     rule (.K => elaboratePostponed(noEval(elabResult(E1)), noEval(elabResult(E2))))
          ~> typeof(_ ? E1:KItem : E2:KItem)

     syntax KItem ::= elabResult(K)
     context elabResult(HOLE:KItem => reval(HOLE)) [result(RValue)]

     rule <k> elabResult(V:RValue) => .K ...</k>
          <elab> .K => V ...</elab>

     rule <k> EXIT(_) => skipToScopeExit ...</k>
          <curr-eval-context> noEval </curr-eval-context>

     context elaboratePostponed(_, _) ~> typeof(_ ? (HOLE:KItem => typeof(HOLE)) : _) [result(Type)]
     context elaboratePostponed(_, _) ~> typeof(_ ? _ : (HOLE:KItem => typeof(HOLE))) [result(Type)]

     rule (elaboratePostponed(E1, E2) => elaborate(E1, E2)) ~> typeof(_ ? _::Type : _::Type) [owise]

     syntax Bool ::= isNPC(K) [function]
     rule isNPC(V:RValue) => isNullPointerConstant(V)
     rule isNPC(_) => false [owise]

     rule elaboratePostponed(_, _) ~> typeof(_ ? (arrayOrFunctionType #as T::Type => type(rvalType(T))) : _)
     rule elaboratePostponed(_, _) ~> typeof(_ ? _ : (arrayOrFunctionType #as T::Type => type(rvalType(T))))

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{5}}}{
     If both the second and third operands have arithmetic type, the result
     type that would be determined by the usual arithmetic conversions, were
     they applied to those two operands, is the type of the result. If both the
     operands have structure or union type, the result has that type. If both
     operands have void type, the result has void type.
     }*/
     rule elaboratePostponed(_, _) ~> typeof(_ ? arithmeticType #as T::Type : (arithmeticType #as T'::Type))
          => typeof(usualArithmeticConversion(T, T'))
     rule elaboratePostponed(_, _) ~> typeof(_ ? t(... st: void) #as T::Type : t(... st: void))
          => typeof(stripQualifiers(T))
     rule elaboratePostponed(_, _) ~> typeof(_ ? structOrUnionType #as T::Type : (structOrUnionType #as T'::Type))
          => typeof(stripQualifiers(T))
          requires T ==Type T'

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{6}}}{
     If both the second and third operands are pointers or one is a
     null pointer constant and the other is a pointer, the result type is a
     pointer to a type qualified with all the type qualifiers of the types
     referenced by both operands. Furthermore, if both operands are pointers to
     compatible types or to differently qualified versions of compatible types,
     the result type is a pointer to an appropriately qualified version of the
     composite type}; if one operand is a null pointer constant, the result has
     the type of the other operand; otherwise, one operand is a pointer
     to void or a qualified version of \cinline{void}, in which case the result
     type is a pointer to an appropriately qualified version of
     \cinline{void}.
     }*/
     // The result of the conditional is an rvalue, so it will be an unqualified type.
     rule (elaboratePostponed(_, _) ~> typeof(_ ? t(_, Mods::Set, pointerType(T::Type)) : t(_, Mods'::Set, pointerType(T'::Type)))
               => typeof(t(noQuals, Mods Mods', pointerType(compositeType(T, T')))))
          ~> SizeofExpression(_)
          requires stripQualifiers(T) ==Type stripQualifiers(T')
               andBool notBool (isSpecifiedVariablyModifiedType(T) orBool isSpecifiedVariablyModifiedType(T'))
     rule (elaboratePostponed(_, _) ~> typeof(_ ? t(_, Mods::Set, pointerType(T::Type)) : t(_, Mods'::Set, pointerType(T'::Type)))
               => typeof(t(noQuals, Mods Mods', pointerType(compositeType(T, T')))))
          ~> K:KItem
          requires stripQualifiers(T) ==Type stripQualifiers(T')
               andBool SizeofExpression(...) :/=K K

     rule elaborateDone(V:K, _V':K) ~> typeof(_ ? t(...) : (t(...) #as T'::Type))
          => typeof(stripQualifiers(T'))
          requires isNPC(V) andBool isPointerType(T')
     rule elaborateDone(_V:K, V':K) ~> typeof(_ ? (t(...) #as T::Type) : t(...))
          => typeof(stripQualifiers(T))
          requires isNPC(V') andBool isPointerType(T)

     rule elaborateDone(_, V:K)
          ~> typeof(_ ? t(_, Mods1::Set, pointerType(t(Qs1'::Quals, Mods1'::Set, T::SimpleType))) : t(_, Mods2::Set, pointerType(t(Qs2'::Quals, Mods2'::Set, void))))
          => typeof(t(noQuals, Mods1 Mods2, pointerType(t(Qs1' +Quals Qs2', Mods1' Mods2', void))))
          requires notBool isFunctionType(type(T))
               andBool notBool isNPC(V)
     rule elaborateDone(V:K, _)
          ~> typeof(_ ? t(_, Mods1::Set, pointerType(t(Qs1'::Quals, Mods1'::Set, void))) : t(_, Mods2::Set, pointerType(t(Qs2'::Quals, Mods2'::Set, T::SimpleType))))
          => typeof(t(noQuals, Mods1 Mods2, pointerType(t(Qs1' +Quals Qs2', Mods1' Mods2', void))))
          requires notBool isFunctionType(type(T))
               andBool notBool isNPC(V)

     rule (.K => UNDEF("TTE1",
               "Program requires the formation of a composite type from a variable length array type whose size is specified by an expression that is not evaluated (in an argument to sizeof)."))
          ~> elaborateDone(V:K, V':K) ~> typeof(_ ? T:Type : T':Type)
          ~> SizeofExpression(_)
          requires (isSpecifiedVariablyModifiedType(T) orBool isSpecifiedVariablyModifiedType(T'))
               andBool notBool (isNPC(V) orBool isNPC(V'))

     rule (.K => CV("TTE2",
               "if both of a conditional expression's branches have pointer type, they must be compatible, or one must be a pointer to an object and the"
               +String " other must be a pointer to void."))
          ~> elaborateDone(_, _) ~> typeof(_ ? t(... st: pointerType(_)) #as T::Type : (t(... st: pointerType(_)) #as T'::Type))
          requires stripQualifiers(innerType(T)) =/=Type stripQualifiers(innerType(T'))
               andBool notBool (isVoidType(innerType(T)) orBool isVoidType(innerType(T')))

     rule (.K => CV("TTE3",
               "if one of a conditional expression's branches has pointer type and the other has integer type, the integer must be a null pointer constant."))
          ~> elaborateDone(V:K, _) ~> typeof(_ ? integerType : t(... st: pointerType(_)))
          requires notBool isNPC(V)
     rule (.K => CV("TTE3",
               "if one of a conditional expression's branches has pointer type and the other has integer type, the integer must be a null pointer constant."))
          ~> elaborateDone(_, V:K) ~> typeof(_ ? t(... st: pointerType(_)) : integerType)
          requires notBool isNPC(V)

     rule (.K => CV("TTE4",
               "if one of a conditional expression's branches has void type, the other must also have void type.") )
          ~> elaborateDone(_, _) ~> typeof(_ ? t(_, _, void) : t(_, _, T:SimpleType))
          requires T =/=K void
     rule (.K => CV("TTE4",
               "if one of a conditional expression's branches has void type, the other must also have void type.") )
          ~> elaborateDone(_, _) ~> typeof(_ ? t(_, _, T:SimpleType) : t(_, _, void))
          requires T =/=K void
     rule (.K => CV("TTE5",
               "if one of a conditional expression's branches has struct or union type, the other must have the same type.") )
          ~> elaborateDone(_, _) ~> typeof(_ ? structOrUnionType #as T::Type : (structOrUnionType #as T'::Type))
          requires T =/=Type T'

     syntax KItem ::= assignmentOp(K, K)
     rule assignmentOp(L:K, R:K)
         => ((L := R)
        #Or ((L *= R)
        #Or ((L /= R)
        #Or ((L %= R)
        #Or ((L += R)
        #Or ((L -= R)
        #Or ((L <<= R)
        #Or ((L >>= R)
        #Or ((L &= R)
        #Or ((L ^= R)
        #Or ((L |= R)))))))))))) [macro]

     // assignment expression
     rule typeof(assignmentOp(t(_, Mods::Set, T::SimpleType),_) => t(noQuals, Mods, T))

     // comma expression
     rule typeof(Comma(list(_:List ListItem(K:KItem))) => K)

     syntax Bool ::= isSpecifiedVariablyModifiedType(Type) [function]
     rule isSpecifiedVariablyModifiedType(t(... st: _:SimpleFixedArrayType) #as T::Type)
          => isSpecifiedVariablyModifiedType(innerType(T))
     rule isSpecifiedVariablyModifiedType(t(... st: _:SimpleIncompleteArrayType) #as T::Type)
          => isSpecifiedVariablyModifiedType(innerType(T))
     rule isSpecifiedVariablyModifiedType(t(... st: pointerType(_)) #as T::Type)
          => isSpecifiedVariablyModifiedType(innerType(T))
     rule isSpecifiedVariablyModifiedType(t(_, _, functionType(_, ListItem(T::UType) _))) => true
          requires isSpecifiedVariablyModifiedType(type(T))
     rule isSpecifiedVariablyModifiedType(t(_, _, functionType(T::UType, .List)))
          => isSpecifiedVariablyModifiedType(type(T))
     rule isSpecifiedVariablyModifiedType(t(_, _, functionType(_, (ListItem(T::UType) => .List) _)))
          requires notBool isSpecifiedVariablyModifiedType(type(T))
     rule isSpecifiedVariablyModifiedType(t(_, _, variableLengthArrayType(_, _))) => true
     rule isSpecifiedVariablyModifiedType(_) => false [owise]

endmodule
