module C-TYPING-EXPR-SYNTAX
     imports BASIC-K

     syntax KItem ::= typeof(K)

endmodule

module C-TYPING-EXPR
     imports C-TYPING-SYNTAX
     imports C-TYPING-EXPR-SYNTAX

     imports C-ABSTRACT-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONFIGURATION
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-LITERAL-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX

     // chathhorn: hacky custom heating/cooling for type-strictness.
     syntax Set ::= "typeStrictUnaryOps" [function]
                  | "typeStrictBinaryOps" [function]
                  | "typeStrictBinaryOpsFirst" [function]
                  | "typeStrictBinaryOpsSecond" [function]
                  | "typeStrictTernaryOpsSecond" [function]
                  | "typeStrictTernaryOpsThird" [function]

     rule typeStrictUnaryOps =>
          SetItem(#klabel(`-_`))
          SetItem(#klabel(`+_`))
          SetItem(#klabel(`!_`))
          SetItem(#klabel(`~_`))
          SetItem(#klabel(`*_`))
          SetItem(#klabel(`&_`))
          SetItem(#klabel(`++_`))
          SetItem(#klabel(`--_`))
          SetItem(#klabel(`_++`))
          SetItem(#klabel(`_--`))
          SetItem(#klabel(`SizeofExpression`))

     rule typeStrictBinaryOps =>
          SetItem(#klabel(`_*_`))
          SetItem(#klabel(`_/_`))
          SetItem(#klabel(`_%_`))
          SetItem(#klabel(`_+_`))
          SetItem(#klabel(`_-_`))
          SetItem(#klabel(`_==_`))
          SetItem(#klabel(`_!=_`))
          SetItem(#klabel(`_&_`))
          SetItem(#klabel(`_^_`))
          SetItem(#klabel(`_|_`))
          SetItem(#klabel(`_&&_`))
          SetItem(#klabel(`_||_`))

     rule typeStrictBinaryOpsFirst =>
          typeStrictBinaryOps
          SetItem(#klabel(`_<<_`))
          SetItem(#klabel(`_>>_`))
          SetItem(#klabel(`_*=_`))
          SetItem(#klabel(`_/=_`))
          SetItem(#klabel(`_%=_`))
          SetItem(#klabel(`_+=_`))
          SetItem(#klabel(`_-=_`))
          SetItem(#klabel(`_<<=_`))
          SetItem(#klabel(`_&=_`))
          SetItem(#klabel(`_^=_`))
          SetItem(#klabel(`_|=_`))
          SetItem(#klabel(`_>>=_`))
          SetItem(#klabel(`_:=_`))
          SetItem(#klabel(`Call`))
          SetItem(#klabel(`_._`))

     rule typeStrictBinaryOpsSecond => typeStrictBinaryOps

     context typeof(Lbl:KLabel(HOLE:KItem => typeof(HOLE)))
          requires #klabel(Lbl) in typeStrictUnaryOps [result(Type)]

     context typeof(Lbl:KLabel((HOLE:KItem => typeof(HOLE)), _))
          requires #klabel(Lbl) in typeStrictBinaryOpsFirst [result(Type)]
     context typeof(Lbl:KLabel(_, (HOLE:KItem => typeof(HOLE))))
          requires #klabel(Lbl) in typeStrictBinaryOpsSecond [result(Type)]

     // primary expressions
     rule <k> typeof(X:CId => T:Type) ...</k>
          <types>... X |-> T ...</types>
     rule <k> typeof(X:CId => t(noQuals, SetItem(IntegerConstant), int)) ...</k>
          <enums>... X |-> _ ...</enums>

     rule typeof(T:Typed => type(T))
          requires notBool isType(T)

     rule typeof(stringLiteral(S:String)
          => type(arrayType(type(char), lengthString(S) +Int 1)))
     rule typeof(wstringLiteral(L:List)
          => type(arrayType(type(cfg:wcharut), size(L) +Int 1)))

     // postfix expressions
     rule typeof(Call(T:Type, _) => innerType(T))
          requires isFunctionType(T)
     rule typeof(Call((T:Type => innerType(T)), _))
          requires isPointerType(T)

     rule <k> typeof(t(_, _, structType(tag(X:CId, Tu:String, B:BlockRef))) . F:CId => T) ...</k>
          <structs>... Tu |-> (_:Map tag(X, Tu, B) |-> fieldInfo(_, _, (_ F |-> T:Type), _)) ...</structs>
     rule <k> typeof(t(_, _, unionType(tag(X:CId, Tu:String, B:BlockRef))) . F:CId => T) ...</k>
          <structs>... Tu |-> (_:Map tag(X, Tu, B) |-> fieldInfo(_, _, (_ F |-> T:Type), _)) ...</structs>

     rule typeof(T:Type ++ => T)
     rule typeof(T:Type -- => T)

     context typeof(CompoundLiteral(_, (HOLE:KItem), _, _)) [result(Type)]
     syntax KItem ::= CompoundLiteralType(K)
     rule typeof(CompoundLiteral(_, T:Type, K:K, _) => CompoundLiteralType(DeclType(T, K)))
     context typeof(CompoundLiteralType(HOLE:KItem))
     rule typeof(CompoundLiteralType(T:Type) => T)

     syntax Type ::= tryPromote(Type) [function]
     rule tryPromote(T:IntegerType) => type(promote(utype(T)))
     rule tryPromote(T::Type) => T [owise]

     // prefix expressions
     rule typeof(++ T:Type => T += type(int))
     rule typeof(-- T:Type => T -= type(int))
     rule typeof(& T:Type => type(pointerType(T)))
     rule typeof(* T:Type => stripQualifiers(innerType(T)))
     rule typeof(+ T:Type => tryPromote(T))
     rule typeof(- T:Type => tryPromote(T))
     rule typeof(~ T:Type => tryPromote(T:Type))
     rule typeof(! T:Type => type(int))

     rule typeof(SizeofExpression(T:Type) => SizeofType(T, .K))
     rule typeof(SizeofType(T:Type, _)
          => t(noQuals, SetItem(IntegerConstant), cfg:sizeut))
          requires notBool isVariablyModifiedType(T)
     rule typeof(SizeofType(T:Type, _)
          => type(cfg:sizeut))
          requires isVariablyModifiedType(T)
     context typeof(SizeofType(HOLE:KItem, _))

     rule typeof(AlignofExpression(_) => AlignofType(.K, .K))
     rule typeof(AlignofType(_, _)
          => t(noQuals, SetItem(IntegerConstant), cfg:sizeut))
     rule typeof(OffsetOf(_, _, _)
          => t(noQuals, SetItem(IntegerConstant), cfg:sizeut))

     // cast expression
     context typeof(Cast((HOLE:KItem), _, _)) [result(Type)]
     rule typeof(Cast(T:Type, K:K, V:K) => Cast(DeclType(T, K), V))
     context typeof(Cast(HOLE:KItem,_))
     rule typeof(Cast(T:Type, _) => elideDeclParams(T))

     syntax Type ::= usualArithmeticConversion(Type, Type) [klabel(usualArithmeticConversionQ), function]
     rule usualArithmeticConversion(T::Type, T'::Type)
          => type(usualArithmeticConversion(utype(T), utype(T')))

     // multiplicative expressions
     rule typeof(T:Type * T':Type => usualArithmeticConversion(T, T'))
     rule typeof(T:Type / T':Type => usualArithmeticConversion(T, T'))
     rule typeof(T:Type % T':Type => usualArithmeticConversion(T, T'))

     // additive expressions
     rule typeof(T:ArithmeticType + T':ArithmeticType => usualArithmeticConversion(T, T'))
     rule typeof(T:ArithmeticType - T':ArithmeticType => usualArithmeticConversion(T, T'))
     rule typeof(T:PointerOrArrayType + _:IntegerType => T)
     rule typeof(_:IntegerType + T:PointerOrArrayType => T)
     rule typeof(T:PointerOrArrayType - _:IntegerType => T)
     rule typeof(_:PointerOrArrayType - _:PointerOrArrayType => type(cfg:ptrdiffut))

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
     rule (.K => elaborate(noEval(elabResult(E1)), noEval(elabResult(E2))))
          ~> typeof(_ ? E1:KItem : E2:KItem)

     syntax KItem ::= elabResult(K)
     context elabResult(HOLE:KItem => reval(HOLE)) [result(RValue)]

     rule <k> elabResult(V:RValue) => .K ...</k>
          <elab> .K => V ...</elab>

     rule <k> EXIT(_) => recover ...</k>
          <curr-eval-context> noEval </curr-eval-context>

     context elaborateDone(_, _) ~> typeof(_ ? (HOLE:KItem => typeof(HOLE)) : _) [result(Type)]
     context elaborateDone(_, _) ~> typeof(_ ? _ : (HOLE:KItem => typeof(HOLE))) [result(Type)]

     // fixme, not handling qualifiers correctly
     syntax Type ::= retype(ArrayOrFunctionType) [function]
     rule retype(T:ArrayType) => type(pointerType(innerType(T)))
     rule retype(T:FunctionType) => type(pointerType(T))

     syntax Bool ::= isNPC(K) [function]
     rule isNPC(V:RValue) => isNullPointerConstant(V)
     rule isNPC(_) => false [owise]

     rule elaborateDone(_, _) ~> typeof(_ ? (T:ArrayOrFunctionType => retype(T)) : _)
     rule elaborateDone(_, _) ~> typeof(_ ? _ : (T:ArrayOrFunctionType => retype(T)))

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{5}}}{
     If both the second and third operands have arithmetic type, the result
     type that would be determined by the usual arithmetic conversions, were
     they applied to those two operands, is the type of the result. If both the
     operands have structure or union type, the result has that type. If both
     operands have void type, the result has void type.
     }*/
     rule elaborateDone(_, _) ~> typeof(_ ? T:ArithmeticType : T':ArithmeticType)
          => typeof(usualArithmeticConversion(T, T'))
     rule elaborateDone(_, _) ~> typeof(_ ? T:VoidType : _:VoidType)
          => typeof(T)
     rule elaborateDone(_, _) ~> typeof(_ ? T:StructOrUnionType : T':StructOrUnionType)
          => typeof(T)
          requires areCompatible(T, T')

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
     rule (elaborateDone(_, _) ~> typeof(_ ? t(Qs::Quals, Mods::Set, pointerType(T::Type)) : t(Qs'::Quals, Mods'::Set, pointerType(T'::Type)))
               => typeof(t(Qs +Quals Qs', Mods Mods', pointerType(compositeType(T, T')))))
          ~> SizeofExpression(_)
          requires areCompatible(stripQualifiers(T), stripQualifiers(T'))
               andBool notBool (isSpecifiedVariablyModifiedType(T) orBool isSpecifiedVariablyModifiedType(T'))
     rule (elaborateDone(_, _) ~> typeof(_ ? t(Qs::Quals, Mods::Set, pointerType(T::Type)) : t(Qs'::Quals, Mods'::Set, pointerType(T'::Type)))
               => typeof(t(Qs +Quals Qs', Mods Mods', pointerType(compositeType(T, T')))))
          ~> K:KItem
          requires areCompatible(stripQualifiers(T), stripQualifiers(T'))
               andBool getKLabel(K) =/=K #klabel(`SizeofExpression`)

     rule elaborateDone(V:K, _) ~> typeof(_ ? _ : T:PointerType)
          => typeof(T)
          requires isNPC(V)
     rule elaborateDone(_, V:K) ~> typeof(_ ? T:PointerType : _)
          => typeof(T)
          requires isNPC(V)

     rule elaborateDone(_, V:K)
          ~> typeof(_ ? t(Qs1::Quals, Mods1::Set, pointerType(t(Qs1'::Quals, Mods1'::Set, T::SimpleType))) : t(Qs2::Quals, Mods2::Set, pointerType(t(Qs2'::Quals, Mods2'::Set, void))))
          => typeof(t(Qs1 +Quals Qs2, Mods1 Mods2, pointerType(t(Qs1' +Quals Qs2', Mods1' Mods2', void))))
          requires notBool isFunctionType(type(T))
               andBool notBool isNPC(V)
     rule elaborateDone(V:K, _)
          ~> typeof(_ ? t(Qs1::Quals, Mods1::Set, pointerType(t(Qs1'::Quals, Mods1'::Set, void))) : t(Qs2::Quals, Mods2::Set, pointerType(t(Qs2'::Quals, Mods2'::Set, T::SimpleType))))
          => typeof(t(Qs1 +Quals Qs2, Mods1 Mods2, pointerType(t(Qs1' +Quals Qs2', Mods1' Mods2', void))))
          requires notBool isFunctionType(type(T))
               andBool notBool isNPC(V)

     rule (.K => UNDEF("TTE1",
               "Program requires the formation of a composite type from a variable length array type whose size is specified by an expression that is not evaluated (in an argument to sizeof).",
               "6.2.7:3, J.2:1 item 16"))
          ~> elaborateDone(V:K, V':K) ~> typeof(_ ? T:Type : T':Type)
          ~> SizeofExpression(_)
          requires isSpecifiedVariablyModifiedType(T) orBool isSpecifiedVariablyModifiedType(T')
               andBool notBool (isNPC(V) orBool isNPC(V'))

     rule (.K => CV("TTE2",
               "if both of a conditional expression's branches have pointer type, they must be compatible, or one must be a pointer to an object and the"
               +String " other must be a pointer to void.",
               "6.5.15:3"))
          ~> elaborateDone(_, _) ~> typeof(_ ? T:PointerType : T':PointerType)
          requires notBool areCompatible(
                    stripQualifiers(innerType(T)),
                    stripQualifiers(innerType(T')))
               andBool notBool (isVoidType(innerType(T)) orBool isVoidType(innerType(T')))

     rule (.K => CV("TTE3",
               "if one of a conditional expression's branches has pointer type and the other has integer type, the integer must be a null pointer constant.",
               "6.5.15:3"))
          ~> elaborateDone(V:K, _) ~> typeof(_ ? _:IntegerType : _:PointerType)
          requires notBool isNPC(V)
     rule (.K => CV("TTE3",
               "if one of a conditional expression's branches has pointer type and the other has integer type, the integer must be a null pointer constant.",
               "6.5.15:3"))
          ~> elaborateDone(_, V:K) ~> typeof(_ ? _:PointerType : _:IntegerType)
          requires notBool isNPC(V)

     rule (.K => CV("TTE4",
               "if one of a conditional expression's branches has void type, the other must also have void type.",
               "6.5.15:3") )
          ~> elaborateDone(_, _) ~> typeof(_ ? t(_, _, void) : t(_, _, T:SimpleType))
          requires T =/=K void
     rule (.K => CV("TTE4",
               "if one of a conditional expression's branches has void type, the other must also have void type.",
               "6.5.15:3") )
          ~> elaborateDone(_, _) ~> typeof(_ ? t(_, _, T:SimpleType) : t(_, _, void))
          requires T =/=K void
     rule (.K => CV("TTE5",
               "if one of a conditional expression's branches has struct or union type, the other must have the same type.",
               "6.5.15:3") )
          ~> elaborateDone(_, _) ~> typeof(_ ? T:StructOrUnionType : T':StructOrUnionType)
          requires T =/=Type T'

     syntax Set ::= "assignmentLabels" [function]
     rule assignmentLabels =>
          SetItem(#klabel(`_:=_`))
          SetItem(#klabel(`_*=_`))
          SetItem(#klabel(`_/=_`))
          SetItem(#klabel(`_%=_`))
          SetItem(#klabel(`_+=_`))
          SetItem(#klabel(`_-=_`))
          SetItem(#klabel(`_<<=_`))
          SetItem(#klabel(`_>>=_`))
          SetItem(#klabel(`_&=_`))
          SetItem(#klabel(`_^=_`))
          SetItem(#klabel(`_|=_`))

     // assignment expression
     rule typeof(Lbl:KLabel(t(_, Mods::Set, T::SimpleType),_) => t(noQuals, Mods, T))
          requires #klabel(Lbl) in assignmentLabels

     // comma expression
     rule typeof(Comma(list(_:List ListItem(K:K))) => K)

     syntax Bool ::= isSpecifiedVariablyModifiedType(Type) [function]
     rule isSpecifiedVariablyModifiedType(T:FixedLengthArrayType)
          => isSpecifiedVariablyModifiedType(innerType(T))
     rule isSpecifiedVariablyModifiedType(T:IncompleteArrayType)
          => isSpecifiedVariablyModifiedType(innerType(T))
     rule isSpecifiedVariablyModifiedType(T:PointerType)
          => isSpecifiedVariablyModifiedType(innerType(T))
     rule isSpecifiedVariablyModifiedType(t(_, _, functionType(T::UType, Params:List)))
          => isSpecifiedVariablyModifiedType(type(T)) orBool some(Params, #klabel(`isSpecifiedVariablyModifiedType`))
     rule isSpecifiedVariablyModifiedType(typedDeclaration(T:Type, _))
          => isSpecifiedVariablyModifiedType(T)
     rule isSpecifiedVariablyModifiedType(t(_, _, variableLengthArrayType(_, _))) => true
     rule isSpecifiedVariablyModifiedType(_) => false [owise]

endmodule
