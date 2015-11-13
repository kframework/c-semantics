module C-TYPING-EXPR-SYNTAX
  imports BASIC-K

syntax KItem ::= typeof(K)

endmodule

module C-TYPING-EXPR
     imports C-TYPING-SYNTAX
     imports C-TYPING-EXPR-SYNTAX

     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-LITERAL-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-CONFIGURATION
     imports C-ABSTRACT-SYNTAX

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

     context typeof(_ ? (HOLE:KItem => typeof(HOLE)) : _) [result(Type)]
     context typeof(_ ? _ : (HOLE:KItem => typeof(HOLE))) [result(Type)]


     // primary expressions
     rule <k> typeof(X:CId => T:Type) ...</k>
          <types>... X |-> T ...</types>
     rule <k> typeof(X:CId => t(SetItem(IntegerConstant), int)) ...</k>
          <enums>... X |-> _ ...</enums>

     rule typeof(T:Typed => type(T))
          requires notBool isType(T)

     rule typeof(stringLiteral(S:String)
          => t(.Set, arrayType(t(.Set, char), lengthString(S) +Int 1)))
     rule typeof(wstringLiteral(L:List)
          => t(.Set, arrayType(t(.Set, cfg:wcharut), size(L) +Int 1)))

     // postfix expressions
     rule typeof(Call(T:Type, _) => innerType(T))

     rule <k> typeof(t(_, structType(S:StructId)) . F:CId => T) ...</k>
          <structs>... S |-> fieldInfo(_, _, (_ F |-> T:Type), _) ...</structs>
     rule <k> typeof(t(_, unionType(S:StructId)) . F:CId => T) ...</k>
          <structs>... S |-> fieldInfo(_, _, (_ F |-> T:Type), _) ...</structs>

     rule typeof(T:Type ++ => T)
     rule typeof(T:Type -- => T)

     context typeof(CompoundLiteral(_, (HOLE:KItem), _, _)) [result(Type)]
     syntax KItem ::= CompoundLiteralType(K)
     rule typeof(CompoundLiteral(_, T:Type, K:K, _) => CompoundLiteralType(DeclType(T, K)))
     context typeof(CompoundLiteralType(HOLE:KItem))
     rule typeof(CompoundLiteralType(T:Type) => T)

     syntax Type ::= tryPromote(Type) [function]
     rule tryPromote(T:IntegerType) => promote(T)
     rule tryPromote(T::Type) => T [owise]

     // prefix expressions
     rule typeof(++ T:Type => T += t(.Set, int))
     rule typeof(-- T:Type => T -= t(.Set, int))
     rule typeof(& T:Type => t(.Set, pointerType(T)))
     rule typeof(* T:Type => innerType(T))
     rule typeof(+ T:Type => tryPromote(T))
     rule typeof(- T:Type => tryPromote(T))
     rule typeof(~ T:Type => tryPromote(T:Type))
     rule typeof(! T:Type => t(.Set, int))

     rule typeof(SizeofExpression(T:Type) => SizeofType(T, .K))
     rule typeof(SizeofType(T:Type, _)
          => t(SetItem(IntegerConstant), cfg:sizeut))
          requires notBool isVariablyModifiedType(T)
     rule typeof(SizeofType(T:Type, _)
          => t(.Set, cfg:sizeut))
          requires isVariablyModifiedType(T)
     context typeof(SizeofType(HOLE:KItem, _))

     rule typeof(AlignofExpression(_) => AlignofType(.K, .K))
     rule typeof(AlignofType(_, _)
          => t(SetItem(IntegerConstant), cfg:sizeut))
     rule typeof(OffsetOf(_, _, _)
          => t(SetItem(IntegerConstant), cfg:sizeut))

     // cast expression
     context typeof(Cast((HOLE:KItem), _, _)) [result(Type)]
     rule typeof(Cast(T:Type,K:K,V:K) => Cast(DeclType(T,K),V))
     context typeof(Cast(HOLE:KItem,_))
     rule typeof(Cast(T:Type,_) => elideDeclParams(T))

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
     rule typeof(_:PointerOrArrayType - _:PointerOrArrayType => t(.Set, cfg:ptrdiffut))

     // shift expressions
     rule typeof(T:Type << _ => tryPromote(T))
     rule typeof(T:Type >> _ => tryPromote(T))

     // relational expressions
     rule typeof(_ < _ => t(.Set, int))
     rule typeof(_ > _ => t(.Set, int))
     rule typeof(_ <= _ => t(.Set, int))
     rule typeof(_ >= _ => t(.Set, int))

     // equality expressions
     rule typeof(_ == _ => t(.Set, int))
     rule typeof(_ != _ => t(.Set, int))

     // bitwise expressions
     rule typeof(T:Type & T':Type => usualArithmeticConversion(T, T'))
     rule typeof(T:Type ^ T':Type => usualArithmeticConversion(T, T'))
     rule typeof(T:Type | T':Type => usualArithmeticConversion(T, T'))

     // logical expressions
     rule typeof(_ && _ => t(.Set, int))
     rule typeof(_ || _ => t(.Set, int))

     // conditional expression
     rule typeof(_ ? (T:ArrayOrFunctionType => retype(T)) : _)
     rule typeof(_ ? _ : (T:ArrayOrFunctionType => retype(T)))
     rule typeof(_ ? T:ArithmeticType : T':ArithmeticType => usualArithmeticConversion(T, T'))
     rule typeof(_ ? T:VoidType : _:VoidType => T)
     rule typeof(_ ? T:StructOrUnionType : T':StructOrUnionType => T)
          requires areCompatible(T, T')
     rule typeof(_ ? _:IntegerType : T:PointerType => T)
     rule typeof(_ ? T:PointerType : _:IntegerType => T)
     rule typeof(_ ? t(Mods:Set, pointerType(T:Type)) : t(Mods':Set, pointerType(T':Type)) => t(Mods Mods', pointerType(compositeType(T, T'))))
          requires areCompatible(stripQualifiers(T), stripQualifiers(T'))
     rule typeof(_ ? t(Mods1:Set, pointerType(t(Mods1':Set, S:SimpleType))) : t(Mods2:Set, pointerType(t(Mods2':Set, void))) => t(Mods1 Mods2, pointerType(t(Mods1' Mods2', void))))
          requires notBool isFunctionType(t(Mods1', S))
     rule typeof(_ ? t(Mods1:Set, pointerType(t(Mods1':Set, void))) : t(Mods2:Set, pointerType(t(Mods2':Set, S:SimpleType))) => t(Mods1 Mods2, pointerType(t(Mods1' Mods2', void))))
          requires notBool isFunctionType(t(Mods2', S))

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
     rule typeof(Lbl:KLabel(T:Type,_) => stripQualifiers(T))
          requires #klabel(Lbl) in assignmentLabels

     // comma expression
     rule typeof(Comma(list(_:List ListItem(K:K))) => K)

endmodule
